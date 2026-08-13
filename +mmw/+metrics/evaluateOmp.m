function metrics = evaluateOmp(cfg, scene, ompResult)
%EVALUATEOMP Evaluate OMP target recovery against simulation truth.

truthPositionM = ...
    vertcat(scene.targets.positionM);


detectedPositionM = ...
    ompResult.positionsM;


numTruth = ...
    size(truthPositionM,1);

numDetected = ...
    size(detectedPositionM,1);


if numTruth ~= numDetected

    error( ...
        ['Current evaluateOmp expects the same number of ', ...
         'truth and detected targets.']);

end


numTargets = ...
    numTruth;


%% ============================================================
% Match detected targets to truth
% =============================================================

truthXY = ...
    truthPositionM(:,1:2);

detectedXY = ...
    detectedPositionM(:,1:2);


assignment = ...
    findBestAssignment( ...
        truthXY, ...
        detectedXY);


matchedPositionM = ...
    detectedPositionM(assignment,:);

matchedAlpha = ...
    ompResult.alpha(assignment);


%% ============================================================
% Position error
% =============================================================

positionErrorM = ...
    vecnorm( ...
        matchedPositionM(:,1:2) - ...
        truthPositionM(:,1:2), ...
        2, ...
        2);


metrics.positionErrorM = ...
    positionErrorM;

metrics.maxPositionErrorM = ...
    max(positionErrorM);

metrics.positionRmseM = ...
    sqrt(mean(positionErrorM.^2));


metrics.supportPass = ...
    all( ...
        positionErrorM <= ...
        cfg.metrics.targetMatchRadiusM);


%% ============================================================
% True complex scattering coefficients
% =============================================================

truthAlpha = ...
    complex(zeros(numTargets,1));


for m = 1:numTargets

    truthAlpha(m) = ...
        sqrt(scene.targets(m).rcsM2) * ...
        exp( ...
            1j * ...
            scene.targets(m).scatterPhaseRad);

end


metrics.truthAlpha = ...
    truthAlpha;

metrics.estimatedAlpha = ...
    matchedAlpha;


metrics.alphaComplexError = ...
    abs( ...
        matchedAlpha - ...
        truthAlpha);


metrics.alphaAmplitudeError = ...
    abs( ...
        abs(matchedAlpha) - ...
        abs(truthAlpha));


metrics.alphaPhaseErrorDeg = ...
    abs( ...
        rad2deg( ...
            angle( ...
                matchedAlpha .* ...
                conj(truthAlpha))));


%% ============================================================
% Reconstruction diagnostics
% =============================================================

metrics.finalResidualRelativeError = ...
    ompResult.finalResidualRelativeError;


metrics.maximumTemplateCoherence = ...
    ompResult.maximumTemplateCoherence;


metrics.gramConditionNumber = ...
    ompResult.gramConditionNumber;


%% ============================================================
% Matched outputs
% =============================================================

metrics.assignment = ...
    assignment;

metrics.truthPositionM = ...
    truthPositionM;

metrics.estimatedPositionM = ...
    matchedPositionM;

end


function bestAssignment = ...
    findBestAssignment(truthXY, detectedXY)

numTargets = ...
    size(truthXY,1);


if numTargets > 8

    error( ...
        ['Current exhaustive assignment is intended for ', ...
         'small target counts (N <= 8).']);

end


assignments = ...
    perms(1:numTargets);


bestCost = ...
    Inf;

bestAssignment = ...
    1:numTargets;


for k = 1:size(assignments,1)

    assignment = ...
        assignments(k,:);


    candidate = ...
        detectedXY(assignment,:);


    distanceM = ...
        vecnorm( ...
            candidate - truthXY, ...
            2, ...
            2);


    cost = ...
        sum(distanceM);


    if cost < bestCost

        bestCost = ...
            cost;

        bestAssignment = ...
            assignment;

    end

end

end