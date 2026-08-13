function sweep = run_omp_phase_sweep(phaseStepDeg, doPlot)
%RUN_OMP_PHASE_SWEEP
% Evaluate multi-carrier OMP over relative target scattering phase.

arguments
    phaseStepDeg (1,1) double {mustBePositive} = 10
    doPlot (1,1) logical = true
end


%% ============================================================
% Base configuration
% =============================================================

cfg = ...
    mmw.config.defaultConfig();

baseExp = ...
    mmw.config.defaultExperiment();


baseExp.arrayType = ...
    "golomb";

baseExp.carrierHz = ...
    (60:0.4:64) * 1e9;

baseExp.fusionMethod = ...
    "coherent-normalized";

baseExp.reconstruction.method = ...
    "omp";

baseExp.reconstruction.maxTargets = ...
    2;


%% ============================================================
% Base two-target geometry
% =============================================================

separationM = ...
    0.05;

centerM = ...
    cfg.scene.centerM;


baseSceneSpec.positionsM = [
    centerM + [-separationM/2, 0, 0]
    centerM + [ separationM/2, 0, 0]
];

baseSceneSpec.rcsM2 = ...
    [1; 1];

baseSceneSpec.scatterPhaseRad = ...
    [0; 0];

baseSceneSpec.type = ...
    "two-target-phase-sweep";


%% ============================================================
% Sweep settings
% =============================================================

phaseDegList = ...
    0:phaseStepDeg:(360-phaseStepDeg);

numPhases = ...
    numel(phaseDegList);


%% ============================================================
% Allocate
% =============================================================

supportPass = ...
    false(numPhases,1);

positionRmseMm = ...
    nan(numPhases,1);

maxPositionErrorMm = ...
    nan(numPhases,1);

maxAmplitudeError = ...
    nan(numPhases,1);

maxPhaseErrorDeg = ...
    nan(numPhases,1);

maxComplexError = ...
    nan(numPhases,1);

target2EstimatedPhaseDeg = ...
    nan(numPhases,1);

residualError = ...
    nan(numPhases,1);

maximumCoherence = ...
    nan(numPhases,1);

gramConditionNumber = ...
    nan(numPhases,1);


%% ============================================================
% Sweep
% =============================================================

for phaseIndex = 1:numPhases

    phaseDeg = ...
        phaseDegList(phaseIndex);


    fprintf('\n');
    fprintf('########################################\n');
    fprintf('PHASE = %.1f deg\n', phaseDeg);
    fprintf('########################################\n');


    %% Build experiment

    exp = ...
        baseExp;

    sceneSpec = ...
        baseSceneSpec;

    sceneSpec.scatterPhaseRad = [
        0
        deg2rad(phaseDeg)
    ];

    exp.sceneSpec = ...
        sceneSpec;


    try

        %% Unified experiment

        result = ...
            mmw.runExperiment( ...
                exp, ...
                cfg);


        %% Unified OMP metrics

        m = ...
            result.ompMetrics;


        %% Save metrics

        supportPass(phaseIndex) = ...
            m.supportPass;


        positionRmseMm(phaseIndex) = ...
            1000 * m.positionRmseM;


        maxPositionErrorMm(phaseIndex) = ...
            1000 * m.maxPositionErrorM;


        maxAmplitudeError(phaseIndex) = ...
            max(m.alphaAmplitudeError);


        maxPhaseErrorDeg(phaseIndex) = ...
            max(m.alphaPhaseErrorDeg);


        maxComplexError(phaseIndex) = ...
            max(m.alphaComplexError);


        target2EstimatedPhaseDeg(phaseIndex) = ...
            rad2deg( ...
                angle( ...
                    m.estimatedAlpha(2)));


        residualError(phaseIndex) = ...
            m.finalResidualRelativeError;


        maximumCoherence(phaseIndex) = ...
            m.maximumTemplateCoherence;


        gramConditionNumber(phaseIndex) = ...
            m.gramConditionNumber;


        %% Print

        fprintf('\nPHASE RESULT\n');

        fprintf( ...
            'Support pass        : %d\n', ...
            m.supportPass);

        fprintf( ...
            'Position RMSE       : %.3f mm\n', ...
            positionRmseMm(phaseIndex));

        fprintf( ...
            'Max position error  : %.3f mm\n', ...
            maxPositionErrorMm(phaseIndex));

        fprintf( ...
            'Target 2 true phase : %.3f deg\n', ...
            phaseDeg);

        fprintf( ...
            'Target 2 est phase  : %.3f deg\n', ...
            target2EstimatedPhaseDeg(phaseIndex));

        fprintf( ...
            'Max phase error     : %.3e deg\n', ...
            maxPhaseErrorDeg(phaseIndex));

        fprintf( ...
            'Residual error      : %.3e\n', ...
            residualError(phaseIndex));


    catch ME

        fprintf( ...
            '\nOMP FAILED AT %.1f deg\n', ...
            phaseDeg);

        fprintf( ...
            '%s\n', ...
            ME.message);

    end

end


%% ============================================================
% Result table
% =============================================================

phaseSweepTable = ...
    table( ...
        phaseDegList.', ...
        supportPass, ...
        positionRmseMm, ...
        maxPositionErrorMm, ...
        maxAmplitudeError, ...
        maxPhaseErrorDeg, ...
        maxComplexError, ...
        residualError, ...
        maximumCoherence, ...
        gramConditionNumber, ...
        'VariableNames', { ...
            'PhaseDeg', ...
            'SupportPass', ...
            'PositionRmseMm', ...
            'MaxPositionErrorMm', ...
            'MaxAmplitudeError', ...
            'MaxPhaseErrorDeg', ...
            'MaxComplexError', ...
            'ResidualError', ...
            'MaximumCoherence', ...
            'GramConditionNumber'});


%% ============================================================
% Summary
% =============================================================

fprintf('\n');
fprintf('========================================\n');
fprintf('OMP PHASE-SWEEP SUMMARY\n');
fprintf('========================================\n');


fprintf( ...
    'Support success rate : %.2f %%\n', ...
    100 * mean(supportPass));


fprintf( ...
    'Worst position RMSE  : %.3f mm\n', ...
    max(positionRmseMm, [], 'omitnan'));


fprintf( ...
    'Worst position error : %.3f mm\n', ...
    max(maxPositionErrorMm, [], 'omitnan'));


fprintf( ...
    'Worst amplitude error: %.3e\n', ...
    max(maxAmplitudeError, [], 'omitnan'));


fprintf( ...
    'Worst phase error    : %.3e deg\n', ...
    max(maxPhaseErrorDeg, [], 'omitnan'));


fprintf( ...
    'Worst residual error : %.3e\n', ...
    max(residualError, [], 'omitnan'));


fprintf( ...
    'Maximum coherence    : %.6f\n', ...
    max(maximumCoherence, [], 'omitnan'));


fprintf( ...
    'Maximum cond(G)      : %.6f\n', ...
    max(gramConditionNumber, [], 'omitnan'));


disp(phaseSweepTable);


%% ============================================================
% Output
% =============================================================

sweep.phaseDeg = ...
    phaseDegList;

sweep.table = ...
    phaseSweepTable;

sweep.supportSuccessRate = ...
    mean(supportPass);

sweep.worstPositionRmseMm = ...
    max(positionRmseMm, [], 'omitnan');

sweep.worstPositionErrorMm = ...
    max(maxPositionErrorMm, [], 'omitnan');

sweep.worstAmplitudeError = ...
    max(maxAmplitudeError, [], 'omitnan');

sweep.worstPhaseErrorDeg = ...
    max(maxPhaseErrorDeg, [], 'omitnan');

sweep.worstResidualError = ...
    max(residualError, [], 'omitnan');


%% ============================================================
% Plot
% =============================================================

if doPlot

    plotSweep( ...
        phaseDegList, ...
        supportPass, ...
        positionRmseMm, ...
        maxAmplitudeError, ...
        maxPhaseErrorDeg, ...
        residualError, ...
        gramConditionNumber);

end

end


%% ============================================================
% Local plotting helper
% =============================================================

function plotSweep( ...
    phaseDegList, ...
    supportPass, ...
    positionRmseMm, ...
    maxAmplitudeError, ...
    maxPhaseErrorDeg, ...
    residualError, ...
    gramConditionNumber)


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


%% Position RMSE

nexttile;

plot( ...
    phaseDegList, ...
    positionRmseMm, ...
    '-o');

grid on;

xlabel('Relative scattering phase / deg');
ylabel('Position RMSE / mm');
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

end