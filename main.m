clear;
close all;
clc;

startup;


%% ============================================================
% Base configuration
% =============================================================

cfg = ...
    mmw.config.defaultConfig();

exp = ...
    mmw.config.defaultExperiment();


%% ============================================================
% USER SETTINGS
%
% Override defaultExperiment only when needed.
% =============================================================

% Examples:
%
% exp.arrayType = "uniform";
%
% exp.carrierHz = ...
%     (60:0.2:64) * 1e9;
%
% exp.reconstruction.method = ...
%     "none";
%
% exp.plot.enabled = ...
%     false;


%% ============================================================
% Scene
% =============================================================

sceneSpec.positionsM = [
    2.9300, 2.9800, 1.2000
    2.9800, 2.9800, 1.2000
    3.0400, 3.0100, 1.2000
    3.1000, 2.9500, 1.2000
];

sceneSpec.rcsM2 = ...
    1.0;

sceneSpec.scatterPhaseRad = ...
    0.0;

sceneSpec.type = ...
    "custom";

exp.sceneSpec = ...
    sceneSpec;


%% ============================================================
% Run
% =============================================================

result = ...
    mmw.runExperiment( ...
        exp, ...
        cfg);


%% ============================================================
% Summary
% =============================================================

omp = ...
    result.reconstruction;

m = ...
    result.ompMetrics;


fprintf('\n========================================\n');
fprintf('EXPERIMENT RESULT\n');
fprintf('========================================\n');


fprintf( ...
    'Number of targets : %d\n', ...
    omp.numTargets);


for k = 1:omp.numTargets

    fprintf( ...
        'Target %d : (%.4f, %.4f, %.4f) m\n', ...
        k, ...
        omp.positionsM(k,1), ...
        omp.positionsM(k,2), ...
        omp.positionsM(k,3));

end


if ~isempty(m)

    fprintf( ...
        'Support pass       : %d\n', ...
        m.supportPass);

    fprintf( ...
        'Position RMSE      : %.3f mm\n', ...
        1000 * m.positionRmseM);

    fprintf( ...
        'Maximum error      : %.3f mm\n', ...
        1000 * m.maxPositionErrorM);

    fprintf( ...
        'Final residual     : %.3e\n', ...
        m.finalResidualRelativeError);

end

%% ============================================================
% Plot
% =============================================================

if exp.plot.enabled && ...
        ~isempty(result.reconstruction)

    mmw.plotting.plotOmpSupport( ...
        result.scene, ...
        result.reconstruction);

end