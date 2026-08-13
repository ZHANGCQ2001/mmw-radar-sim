function result = ompMultiCarrier( ...
    cfg, array, carrierData, maxTargets)
%OMPMULTICARRIER Multi-carrier OMP-style target reconstruction.
%
% carrierData can be either:
%
%   1. Lightweight IF observation returned by
%      mmw.signal.simulateCarrierSet
%
%   2. Full multi-carrier study returned by
%      mmw.fusion.runCarrierSet
%
% The algorithm uses:
%
%   1. Multi-carrier BP imaging to find a new target position.
%   2. Strict local complex matched-filter refinement.
%   3. Unit-reflectivity IF templates at detected positions.
%   4. Joint least-squares estimation for all detected targets.
%   5. Residual reconstruction from the ORIGINAL observed IF.
%
% No target truth is used by this function.

arguments
    cfg struct
    array struct
    carrierData struct
    maxTargets (1,1) double {mustBeInteger, mustBePositive}
end


%% Basic information

carrierHz = ...
    carrierData.carrierHz;

numCarriers = ...
    numel(carrierHz);


%% Store original observations

if isfield(carrierData, 'ifData')

    % Lightweight multi-carrier observation
    originalIF = ...
        carrierData.ifData;

elseif isfield(carrierData, 'carrierResults')

    % Backward compatibility with runCarrierSet output
    originalIF = ...
        cell(1, numCarriers);

    for k = 1:numCarriers

        originalIF{k} = ...
            carrierData.carrierResults{k}.ifData;

    end

else

    error( ...
        ['carrierData must contain either ', ...
         'ifData or carrierResults.']);

end


if numel(originalIF) ~= numCarriers

    error( ...
        'Number of IF observations does not match carrierHz.');

end


residualIF = ...
    originalIF;


%% Allocate outputs

positionsM = nan(maxTargets, 3);

templateIF = ...
    cell(maxTargets, numCarriers);

alphaHistory = ...
    cell(maxTargets, 1);

gramHistory = ...
    cell(maxTargets, 1);

detectionImages = ...
    cell(maxTargets, 1);

residualRelativeErrorHistory = ...
    nan(maxTargets, 1);


%% Template simulation must be noiseless

templateCfg = cfg;
templateCfg.simulation.noiseStd = 0.0;


%% OMP iterations

for iteration = 1:maxTargets

    fprintf('\n========================================\n');
    fprintf('OMP ITERATION %d / %d\n', ...
        iteration, maxTargets);
    fprintf('========================================\n');


    %% --------------------------------------------------------
    % 1. Image the current residual
    % ---------------------------------------------------------

    [detectionImage, ~] = ...
        buildFusedImageFromIF( ...
            cfg, ...
            array, ...
            carrierHz, ...
            residualIF);

    detectionImages{iteration} = ...
        detectionImage;


    %% --------------------------------------------------------
    % 2. Find strongest new spatial peak
    % ---------------------------------------------------------

    P = detectionImage.coherentPower;

    x = detectionImage.xGridM;
    y = detectionImage.yGridM;

    [X, Y] = meshgrid(x, y);

    searchPower = P;


    % Prevent selecting an already detected target again.
    if iteration > 1

        exclusionRadiusM = ...
            cfg.metrics.targetMatchRadiusM;

        for m = 1:iteration-1

            dx = X - positionsM(m,1);
            dy = Y - positionsM(m,2);

            exclusionMask = ...
                hypot(dx, dy) <= exclusionRadiusM;

            searchPower(exclusionMask) = -Inf;

        end

    end


    %% --------------------------------------------------------
    % 2. BP coarse search
    % ---------------------------------------------------------
    
    [peakPower, linearIndex] = ...
        max(searchPower(:));
    
    if ~isfinite(peakPower)
        error( ...
            'No valid OMP search point remains.');
    end
    
    [iy, ix] = ...
        ind2sub( ...
            size(searchPower), ...
            linearIndex);
    
    coarsePositionM = [ ...
        x(ix), ...
        y(iy), ...
        cfg.imaging.zM];
    
    
    %% --------------------------------------------------------
    % 3. Local strict OMP refinement
    %
    % BP is used only for coarse localization.
    % The final support position is selected by the strict
    % multi-carrier matched-filter score:
    %
    %       |s^H r| / ||s||
    %
    % over a small neighborhood.
    % ---------------------------------------------------------
    
    refineHalfWidth = 2;
    
    [detectedPositionM, strictScore] = ...
        refinePositionStrictScore( ...
            cfg, ...
            array, ...
            carrierHz, ...
            residualIF, ...
            coarsePositionM, ...
            positionsM(1:iteration-1,:), ...
            refineHalfWidth);
    
    
    positionsM(iteration,:) = ...
        detectedPositionM;
    
    
    fprintf( ...
        'BP coarse position : (%.4f, %.4f, %.4f) m\n', ...
        coarsePositionM(1), ...
        coarsePositionM(2), ...
        coarsePositionM(3));
    
    fprintf( ...
        'Refined position   : (%.4f, %.4f, %.4f) m\n', ...
        detectedPositionM(1), ...
        detectedPositionM(2), ...
        detectedPositionM(3));
    
    fprintf( ...
        'Strict OMP score   : %.6e\n', ...
        strictScore);


    %% --------------------------------------------------------
    % 3. Build unit-reflectivity target template
    % ---------------------------------------------------------

    templateTarget = struct();

    templateTarget.name = ...
        "OMP_Target_" + iteration;

    templateTarget.positionM = ...
        detectedPositionM;

    templateTarget.velocityMps = ...
        cfg.scene.defaultVelocityMps;

    templateTarget.rcsM2 = 1.0;

    templateTarget.scatterPhaseRad = 0.0;


    templateScene = struct();

    templateScene.type = "single";
    templateScene.separationM = NaN;
    templateScene.targets = templateTarget;


    %% Generate one IF template at every carrier

    for k = 1:numCarriers

        cfgK = templateCfg;
        cfgK.waveform.fcHz = carrierHz(k);

        [s, ~] = ...
            mmw.signal.simulateIF( ...
                cfgK, ...
                array, ...
                templateScene);

        templateIF{iteration,k} = s;

    end


    %% --------------------------------------------------------
    % 4. Joint LS over ALL selected targets
    %
    % y = S * alpha
    %
    % Accumulate:
    %
    % G = S^H S
    % b = S^H y
    %
    % across all carrier frequencies.
    % ---------------------------------------------------------

    numSelected = iteration;

    G = complex( ...
        zeros(numSelected, numSelected));

    b = complex( ...
        zeros(numSelected, 1));


    for k = 1:numCarriers

        yObserved = ...
            originalIF{k};

        numMeasurements = ...
            numel(yObserved);

        Sk = complex( ...
            zeros( ...
                numMeasurements, ...
                numSelected));


        for m = 1:numSelected

            s = templateIF{m,k};

            Sk(:,m) = s(:);

        end


        G = ...
            G + Sk' * Sk;

        b = ...
            b + Sk' * yObserved(:);

    end


    %% Joint least-squares coefficients

    alphaHat = G \ b;


    alphaHistory{iteration} = ...
        alphaHat;

    gramHistory{iteration} = ...
        G;


    fprintf('\nJoint LS coefficients:\n');

    for m = 1:numSelected

        fprintf( ...
            'Target %d: |alpha| = %.9f, phase = %.6f deg\n', ...
            m, ...
            abs(alphaHat(m)), ...
            rad2deg(angle(alphaHat(m))));

    end


    %% --------------------------------------------------------
    % 5. Rebuild residual from ORIGINAL observation
    %
    % IMPORTANT:
    %
    % Do not perform:
    %
    % residual_new = residual_old - alpha*s
    %
    % Instead always use:
    %
    % residual = y_original - S*alpha
    %
    % because all previously selected coefficients have just
    % been updated by joint LS.
    % ---------------------------------------------------------

    residualEnergy = 0;
    originalEnergy = 0;


    for k = 1:numCarriers

        yObserved = ...
            originalIF{k};

        yReconstructed = ...
            complex(zeros(size(yObserved)));


        for m = 1:numSelected

            yReconstructed = ...
                yReconstructed + ...
                alphaHat(m) * templateIF{m,k};

        end


        residualIF{k} = ...
            yObserved - yReconstructed;


        residualEnergy = ...
            residualEnergy + ...
            sum(abs(residualIF{k}(:)).^2);

        originalEnergy = ...
            originalEnergy + ...
            sum(abs(yObserved(:)).^2);

    end


    residualRelativeError = ...
        sqrt( ...
            residualEnergy / ...
            max(originalEnergy, eps));


    residualRelativeErrorHistory(iteration) = ...
        residualRelativeError;


    fprintf( ...
        'Relative residual error: %.3e\n', ...
        residualRelativeError);

end


%% Final solution

alpha = ...
    alphaHistory{maxTargets};

Gfinal = ...
    gramHistory{maxTargets};


%% Template coherence matrix

gramDiagonal = ...
    real(diag(Gfinal));

normalizer = ...
    sqrt( ...
        gramDiagonal * ...
        gramDiagonal.');

templateCoherenceMatrix = ...
    abs(Gfinal) ./ ...
    max(normalizer, eps);

templateCoherenceMatrix( ...
    1:size(templateCoherenceMatrix,1)+1:end) = 0;

if maxTargets > 1

    maximumTemplateCoherence = ...
        max(templateCoherenceMatrix(:));

else

    maximumTemplateCoherence = 0;

end


gramConditionNumber = ...
    cond(Gfinal);


%% Build reconstructed component images

componentImages = ...
    cell(maxTargets, 1);

for m = 1:maxTargets

    componentIF = ...
        cell(1, numCarriers);

    for k = 1:numCarriers

        componentIF{k} = ...
            alpha(m) * ...
            templateIF{m,k};

    end


    componentImages{m} = ...
        buildFusedImageFromIF( ...
            cfg, ...
            array, ...
            carrierHz, ...
            componentIF);

end


%% Output

result.positionsM = ...
    positionsM;

result.alpha = ...
    alpha;

result.alphaHistory = ...
    alphaHistory;

result.residualRelativeErrorHistory = ...
    residualRelativeErrorHistory;

result.finalResidualRelativeError = ...
    residualRelativeErrorHistory(end);

result.originalIF = ...
    originalIF;

result.residualIF = ...
    residualIF;

result.templateIF = ...
    templateIF;

result.detectionImages = ...
    detectionImages;

result.componentImages = ...
    componentImages;

result.gramMatrix = ...
    Gfinal;

result.templateCoherenceMatrix = ...
    templateCoherenceMatrix;

result.maximumTemplateCoherence = ...
    maximumTemplateCoherence;

result.gramConditionNumber = ...
    gramConditionNumber;

result.numTargets = ...
    maxTargets;

result.carrierHz = ...
    carrierHz;

result.method = ...
    "multi-carrier OMP with joint LS";

end


%% ============================================================
% Local helper
% =============================================================

function [fusedImage, complexStack] = ...
    buildFusedImageFromIF( ...
        cfg, array, carrierHz, ifCell)
%BUILDFUSEDIMAGEFROMIF Process multi-carrier IF observations.

numCarriers = numel(carrierHz);

complexStack = [];

baseImage = [];


for k = 1:numCarriers

    cfgK = cfg;
    cfgK.waveform.fcHz = carrierHz(k);


    rd = ...
        mmw.processing.rangeDoppler( ...
            cfgK, ...
            ifCell{k});


    image = ...
        mmw.imaging.coherentImage( ...
            cfgK, ...
            array, ...
            rd);


    if isempty(complexStack)

        [numY, numX] = ...
            size(image.coherentComplex);

        complexStack = ...
            complex(zeros( ...
                numY, ...
                numX, ...
                numCarriers));

        baseImage = image;

    end


    complexStack(:,:,k) = ...
        image.coherentComplex;

end


[fusedPower, ...
 fusedComplex, ...
 ~] = ...
    mmw.fusion.fuseComplexImages( ...
        complexStack, ...
        "normalized");


fusedImage = baseImage;

fusedImage.coherentPower = ...
    fusedPower;

fusedImage.coherentComplex = ...
    fusedComplex;

fusedImage.nodeComplex = [];
fusedImage.nodePower = [];
fusedImage.noncoherentPower = [];

fusedImage.method = ...
    "OMP residual multi-carrier coherent image";

end

function [bestPositionM, bestScore] = ...
    refinePositionStrictScore( ...
        cfg, ...
        array, ...
        carrierHz, ...
        residualIF, ...
        coarsePositionM, ...
        previousPositionsM, ...
        halfWidth)
%REFINEPOSITIONSTRICTSCORE Refine BP peak using strict OMP score.

gridStepM = ...
    cfg.imaging.gridStepM;

offsetIndex = ...
    -halfWidth:halfWidth;

bestScore = -Inf;

bestPositionM = ...
    coarsePositionM;


for iy = 1:numel(offsetIndex)

    for ix = 1:numel(offsetIndex)

        candidatePositionM = [ ...
            coarsePositionM(1) + ...
                offsetIndex(ix) * gridStepM, ...
            coarsePositionM(2) + ...
                offsetIndex(iy) * gridStepM, ...
            cfg.imaging.zM];


        %% Keep candidate inside imaging region

        if candidatePositionM(1) < cfg.imaging.xLimM(1) || ...
           candidatePositionM(1) > cfg.imaging.xLimM(2) || ...
           candidatePositionM(2) < cfg.imaging.yLimM(1) || ...
           candidatePositionM(2) > cfg.imaging.yLimM(2)

            continue;

        end


        %% Do not select an already detected target

        duplicateCandidate = false;

        for m = 1:size(previousPositionsM,1)

            if any(isnan(previousPositionsM(m,:)))
                continue;
            end

            distanceM = ...
                norm( ...
                    candidatePositionM(1:2) - ...
                    previousPositionsM(m,1:2));

            if distanceM <= ...
                    cfg.metrics.targetMatchRadiusM

                duplicateCandidate = true;
                break;

            end

        end


        if duplicateCandidate
            continue;
        end


        %% Strict OMP matched-filter score

        score = ...
            calculateStrictScore( ...
                cfg, ...
                array, ...
                carrierHz, ...
                residualIF, ...
                candidatePositionM);


        if score > bestScore

            bestScore = score;

            bestPositionM = ...
                candidatePositionM;

        end

    end

end


if ~isfinite(bestScore)

    error( ...
        'No valid candidate found in local OMP refinement.');

end

end

function score = ...
    calculateStrictScore( ...
        cfg, ...
        array, ...
        carrierHz, ...
        residualIF, ...
        positionM)
%CALCULATESTRICTSCORE Multi-carrier normalized matched-filter score.

numCarriers = ...
    numel(carrierHz);


%% Unit target at candidate position

target = struct();

target.name = ...
    "OMP_Candidate";

target.positionM = ...
    positionM;

target.velocityMps = ...
    cfg.scene.defaultVelocityMps;

target.rcsM2 = ...
    1.0;

target.scatterPhaseRad = ...
    0.0;


scene = struct();

scene.type = ...
    "single";

scene.separationM = ...
    NaN;

scene.targets = ...
    target;


%% Use noiseless physical template

templateCfg = cfg;

templateCfg.simulation.noiseStd = ...
    0.0;


%% Multi-carrier matched-filter score

numerator = ...
    0;

denominator = ...
    0;


for k = 1:numCarriers

    cfgK = ...
        templateCfg;

    cfgK.waveform.fcHz = ...
        carrierHz(k);


    [s, ~] = ...
        mmw.signal.simulateIF( ...
            cfgK, ...
            array, ...
            scene);


    r = ...
        residualIF{k};


    numerator = ...
        numerator + ...
        sum( ...
            conj(s(:)) .* ...
            r(:));


    denominator = ...
        denominator + ...
        sum(abs(s(:)).^2);

end


score = ...
    abs(numerator) / ...
    sqrt(max(denominator, eps));

end