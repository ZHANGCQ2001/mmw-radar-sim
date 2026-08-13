clear;
close all;
clc;

startup;

%% Configuration

cfg = mmw.config.defaultConfig();

array = mmw.geometry.makeArray( ...
    "golomb", ...
    cfg.array);

carrierHz = (60:0.4:64) * 1e9;

maxTargets = 2;


%% Phase sweep
%
% First smoke test:
% phaseDegList = 0:30:330;
%
% Full experiment:
phaseDegList = 0:10:350;

numPhases = numel(phaseDegList);


%% Allocate results

supportPass = false(numPhases, 1);
exactGridPass = false(numPhases, 1);

maxPositionErrorMm = nan(numPhases, 1);

alphaAmplitudeError = nan(numPhases, 2);
alphaPhaseErrorDeg = nan(numPhases, 2);
alphaComplexError = nan(numPhases, 2);

estimatedAlpha = ...
    complex(nan(numPhases, 2));

estimatedPositionM = ...
    nan(numPhases, 2, 3);

residualError = ...
    nan(numPhases, 1);

maximumCoherence = ...
    nan(numPhases, 1);

gramConditionNumber = ...
    nan(numPhases, 1);


%% Sweep

for phaseIndex = 1:numPhases

    phaseDeg = phaseDegList(phaseIndex);

    fprintf('\n');
    fprintf('########################################\n');
    fprintf('PHASE = %.1f deg\n', phaseDeg);
    fprintf('########################################\n');


    %% Build two-target scene

    scene = mmw.geometry.makeScene( ...
        "two", ...
        cfg.scene, ...
        0.05);


    %% Target 1 is reference phase = 0 deg

    scene.targets(1).scatterPhaseRad = 0.0;


    %% Sweep Target 2 relative scattering phase

    scene.targets(2).scatterPhaseRad = ...
        deg2rad(phaseDeg);


    try

        %% Generate observation

        study = mmw.fusion.runCarrierSet( ...
            cfg, ...
            array, ...
            scene, ...
            carrierHz, ...
            "coherent-normalized");


        %% Run OMP

        ompResult = ...
            mmw.reconstruction.ompMultiCarrier( ...
                cfg, ...
                array, ...
                study, ...
                maxTargets);


        %% -----------------------------------------------
        % Build truth
        % -----------------------------------------------

        truthPositionM = ...
            vertcat(scene.targets.positionM);

        truthAlpha = ...
            complex(zeros(2,1));

        for targetIndex = 1:2

            truthAlpha(targetIndex) = ...
                sqrt(scene.targets(targetIndex).rcsM2) * ...
                exp( ...
                    1j * ...
                    scene.targets(targetIndex).scatterPhaseRad);

        end


        %% -----------------------------------------------
        % Sort truth and detection by x coordinate
        %
        % Current experiment always uses two lateral targets.
        % -----------------------------------------------

        [truthPositionSorted, truthOrder] = ...
            sortrows( ...
                truthPositionM, ...
                1);

        truthAlphaSorted = ...
            truthAlpha(truthOrder);


        [detectedPositionSorted, detectedOrder] = ...
            sortrows( ...
                ompResult.positionsM, ...
                1);

        detectedAlphaSorted = ...
            ompResult.alpha(detectedOrder);


        %% -----------------------------------------------
        % Position error
        % -----------------------------------------------

        positionErrorM = ...
            vecnorm( ...
                detectedPositionSorted - ...
                truthPositionSorted, ...
                2, ...
                2);

        maxPositionErrorMm(phaseIndex) = ...
            1000 * max(positionErrorM);


        %% Normal detection criterion

        supportPass(phaseIndex) = ...
            all( ...
                positionErrorM <= ...
                cfg.metrics.targetMatchRadiusM);


        %% Stricter criterion for current on-grid experiment

        exactGridPass(phaseIndex) = ...
            all( ...
                positionErrorM <= ...
                cfg.imaging.gridStepM / 2 + 1e-12);


        %% -----------------------------------------------
        % Alpha error
        % -----------------------------------------------

        estimatedAlpha(phaseIndex,:) = ...
            detectedAlphaSorted.';


        alphaAmplitudeError(phaseIndex,:) = ...
            abs( ...
                abs(detectedAlphaSorted) - ...
                abs(truthAlphaSorted)).';


        phaseDifference = ...
            detectedAlphaSorted .* ...
            conj(truthAlphaSorted);

        alphaPhaseErrorDeg(phaseIndex,:) = ...
            abs( ...
                rad2deg( ...
                    angle(phaseDifference))).';


        alphaComplexError(phaseIndex,:) = ...
            abs( ...
                detectedAlphaSorted - ...
                truthAlphaSorted).';


        %% -----------------------------------------------
        % Save estimated positions
        % -----------------------------------------------

        estimatedPositionM(phaseIndex,:,:) = ...
            detectedPositionSorted;


        %% -----------------------------------------------
        % OMP diagnostics
        % -----------------------------------------------

        residualError(phaseIndex) = ...
            ompResult.finalResidualRelativeError;

        maximumCoherence(phaseIndex) = ...
            ompResult.maximumTemplateCoherence;

        gramConditionNumber(phaseIndex) = ...
            ompResult.gramConditionNumber;


        %% -----------------------------------------------
        % Print one-line summary
        % -----------------------------------------------

        fprintf('\nPHASE RESULT\n');

        fprintf( ...
            'Support pass        : %d\n', ...
            supportPass(phaseIndex));

        fprintf( ...
            'Exact-grid pass     : %d\n', ...
            exactGridPass(phaseIndex));

        fprintf( ...
            'Max position error  : %.3f mm\n', ...
            maxPositionErrorMm(phaseIndex));

        fprintf( ...
            'Target 2 true phase : %.3f deg\n', ...
            phaseDeg);

        fprintf( ...
            'Target 2 est phase  : %.3f deg\n', ...
            rad2deg( ...
                angle(detectedAlphaSorted(2))));

        fprintf( ...
            'Target 2 phase error: %.3e deg\n', ...
            alphaPhaseErrorDeg(phaseIndex,2));

        fprintf( ...
            'Residual error      : %.3e\n', ...
            residualError(phaseIndex));


    catch ME

        fprintf('\nOMP FAILED AT %.1f deg\n', ...
            phaseDeg);

        fprintf('%s\n', ...
            ME.message);

    end

end


%% ============================================================
% Summary table
% =============================================================

maxAmplitudeError = ...
    max(alphaAmplitudeError, [], 2);

maxPhaseErrorDeg = ...
    max(alphaPhaseErrorDeg, [], 2);

phaseSweepTable = table( ...
    phaseDegList.', ...
    supportPass, ...
    exactGridPass, ...
    maxPositionErrorMm, ...
    maxAmplitudeError, ...
    maxPhaseErrorDeg, ...
    residualError, ...
    maximumCoherence, ...
    gramConditionNumber, ...
    'VariableNames', { ...
        'PhaseDeg', ...
        'SupportPass', ...
        'ExactGridPass', ...
        'MaxPositionErrorMm', ...
        'MaxAmplitudeError', ...
        'MaxPhaseErrorDeg', ...
        'ResidualError', ...
        'MaximumCoherence', ...
        'GramConditionNumber'});


fprintf('\n');
fprintf('========================================\n');
fprintf('OMP PHASE-SWEEP SUMMARY\n');
fprintf('========================================\n');


fprintf( ...
    'Support success rate    : %.2f %%\n', ...
    100 * mean(supportPass));

fprintf( ...
    'Exact-grid success rate : %.2f %%\n', ...
    100 * mean(exactGridPass));

fprintf( ...
    'Worst position error    : %.3f mm\n', ...
    max(maxPositionErrorMm, [], 'omitnan'));

fprintf( ...
    'Worst amplitude error   : %.3e\n', ...
    max(maxAmplitudeError, [], 'omitnan'));

fprintf( ...
    'Worst phase error       : %.3e deg\n', ...
    max(maxPhaseErrorDeg, [], 'omitnan'));

fprintf( ...
    'Worst residual error    : %.3e\n', ...
    max(residualError, [], 'omitnan'));

fprintf( ...
    'Maximum coherence       : %.6f\n', ...
    max(maximumCoherence, [], 'omitnan'));

fprintf( ...
    'Maximum cond(G)         : %.6f\n', ...
    max(gramConditionNumber, [], 'omitnan'));


disp(phaseSweepTable);


%% ============================================================
% Plot
% =============================================================

figure( ...
    'Name', ...
    'OMP phase sweep', ...
    'Position', ...
    [100 80 1500 850]);


tiledlayout( ...
    2, ...
    3, ...
    'TileSpacing', ...
    'compact', ...
    'Padding', ...
    'compact');


%% Position error

nexttile;

plot( ...
    phaseDegList, ...
    maxPositionErrorMm, ...
    '-o');

hold on;

yline( ...
    1000 * cfg.metrics.targetMatchRadiusM, ...
    '--');

grid on;

xlabel('Relative scattering phase / deg');
ylabel('Maximum position error / mm');

title('OMP localization');


%% Support recovery

nexttile;

stairs( ...
    phaseDegList, ...
    double(supportPass), ...
    '-o');

ylim([-0.1 1.1]);

yticks([0 1]);
yticklabels({'Fail', 'Pass'});

grid on;

xlabel('Relative scattering phase / deg');
ylabel('Support recovery');

title('OMP support detection');


%% Amplitude error

nexttile;

plot( ...
    phaseDegList, ...
    maxAmplitudeError, ...
    '-o');

grid on;

xlabel('Relative scattering phase / deg');
ylabel('Maximum amplitude error');

title('Scattering amplitude estimation');


%% Phase error

nexttile;

plot( ...
    phaseDegList, ...
    maxPhaseErrorDeg, ...
    '-o');

grid on;

xlabel('Relative scattering phase / deg');
ylabel('Maximum phase error / deg');

title('Scattering phase estimation');


%% Residual

nexttile;

semilogy( ...
    phaseDegList, ...
    residualError, ...
    '-o');

grid on;

xlabel('Relative scattering phase / deg');
ylabel('Relative residual error');

title('OMP residual');


%% Gram condition number

nexttile;

plot( ...
    phaseDegList, ...
    gramConditionNumber, ...
    '-o');

grid on;

xlabel('Relative scattering phase / deg');
ylabel('cond(G)');

title('Joint LS conditioning');