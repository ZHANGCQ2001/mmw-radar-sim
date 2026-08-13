function sweep = run_phase_sweep(doPlot, phaseStepDeg)
%RUN_PHASE_SWEEP
% Compare six-node Uniform and Golomb arrays under different
% relative scattering phases of two coherent targets.

arguments
    doPlot (1,1) logical = true
    phaseStepDeg (1,1) double {mustBePositive} = 10
end

cfg = mmw.config.defaultConfig();

arrayTypes = ["uniform", "golomb"];

phaseDeg = 0:phaseStepDeg:(360-phaseStepDeg);
phaseRad = deg2rad(phaseDeg);

numPhase = numel(phaseDeg);

sweep.phaseDeg = phaseDeg;

for a = 1:numel(arrayTypes)

    arrayType = arrayTypes(a);

    array = mmw.geometry.makeArray( ...
        arrayType, cfg.array);

    tfprDb = nan(1, numPhase);
    valleyDepthDb = nan(1, numPhase);

    error1Mm = nan(1, numPhase);
    error2Mm = nan(1, numPhase);

    coverage = zeros(1, numPhase);
    separated = false(1, numPhase);
    falsePeakControlled = false(1, numPhase);
    pass = false(1, numPhase);

    fprintf('\n=============================\n');
    fprintf('%s array phase sweep\n', upper(arrayType));
    fprintf('=============================\n');

    for k = 1:numPhase

        % Two targets separated by 5 cm
        scene = mmw.geometry.makeScene( ...
            "two", cfg.scene, 0.05);

        % Target 1 is the phase reference
        scene.targets(1).scatterPhaseRad = 0;

        % Sweep relative scattering phase of target 2
        scene.targets(2).scatterPhaseRad = phaseRad(k);

        result = mmw.runSimulation( ...
            cfg, array, scene);

        m = result.metrics;

        tfprDb(k) = m.targetToFalsePeakDb;
        valleyDepthDb(k) = m.valleyDepthDb;

        coverage(k) = m.coverage;
        separated(k) = m.separated;
        falsePeakControlled(k) = m.falsePeakControlled;
        pass(k) = m.pass;

        if numel(m.localizationErrorM) >= 2
            error1Mm(k) = 1000 * m.localizationErrorM(1);
            error2Mm(k) = 1000 * m.localizationErrorM(2);
        end

        fprintf( ...
            ['Phase = %6.1f deg | ' ...
             'Coverage = %d/2 | ' ...
             'Valley = %7.2f dB | ' ...
             'TFPR = %7.2f dB | ' ...
             'Pass = %d\n'], ...
            phaseDeg(k), ...
            coverage(k), ...
            valleyDepthDb(k), ...
            tfprDb(k), ...
            pass(k));
    end

    fieldName = char(arrayType);

    sweep.(fieldName).tfprDb = tfprDb;
    sweep.(fieldName).valleyDepthDb = valleyDepthDb;

    sweep.(fieldName).error1Mm = error1Mm;
    sweep.(fieldName).error2Mm = error2Mm;

    sweep.(fieldName).coverage = coverage;
    sweep.(fieldName).separated = separated;
    sweep.(fieldName).falsePeakControlled = falsePeakControlled;
    sweep.(fieldName).pass = pass;

    sweep.(fieldName).successRate = mean(pass);
    sweep.(fieldName).successRate0dB = ...
        mean(tfprDb > 0);
    sweep.(fieldName).successRate1dB = ...
        mean(tfprDb > 1);
    sweep.(fieldName).successRate3dB = ...
        mean(tfprDb > 3);
end

%% Summary

fprintf('\n========================================\n');
fprintf('PHASE-SWEEP SUMMARY\n');
fprintf('========================================\n');

fprintf('Uniform success rate : %.2f %%\n', ...
    100 * sweep.uniform.successRate);

fprintf('Golomb success rate  : %.2f %%\n', ...
    100 * sweep.golomb.successRate);

fprintf('\nUniform TFPR range : %.2f ~ %.2f dB\n', ...
    min(sweep.uniform.tfprDb), ...
    max(sweep.uniform.tfprDb));

fprintf('Golomb TFPR range  : %.2f ~ %.2f dB\n', ...
    min(sweep.golomb.tfprDb), ...
    max(sweep.golomb.tfprDb));
fprintf('\nTFPR threshold statistics\n');

fprintf('\nUniform:\n');
fprintf('TFPR >= 0 dB : %.1f %%\n', ...
    100*mean(sweep.uniform.tfprDb >= 0));
fprintf('TFPR >= 1 dB : %.1f %%\n', ...
    100*mean(sweep.uniform.tfprDb >= 1));
fprintf('TFPR >= 3 dB : %.1f %%\n', ...
    100*mean(sweep.uniform.tfprDb >= 3));

fprintf('\nGolomb:\n');
fprintf('TFPR >= 0 dB : %.1f %%\n', ...
    100*mean(sweep.golomb.tfprDb >= 0));
fprintf('TFPR >= 1 dB : %.1f %%\n', ...
    100*mean(sweep.golomb.tfprDb >= 1));
fprintf('TFPR >= 3 dB : %.1f %%\n', ...
    100*mean(sweep.golomb.tfprDb >= 3));

if doPlot
    plotPhaseSweep(sweep);
end

end


function plotPhaseSweep(sweep)

phaseDeg = sweep.phaseDeg;

figure( ...
    'Name', ...
    'Uniform vs Golomb - scattering phase sweep');

tiledlayout(2, 2, ...
    'TileSpacing', 'compact', ...
    'Padding', 'compact');


%% TFPR

nexttile;

plot(phaseDeg, ...
    sweep.uniform.tfprDb, ...
    '-o', ...
    'LineWidth', 1.2, ...
    'MarkerSize', 4);

hold on;

plot(phaseDeg, ...
    sweep.golomb.tfprDb, ...
    '-o', ...
    'LineWidth', 1.2, ...
    'MarkerSize', 4);

yline(0, '--');

grid on;

xlabel('Relative scattering phase / deg');
ylabel('TFPR / dB');

title('True-to-false peak ratio');

legend( ...
    'Uniform', ...
    'Golomb', ...
    '0 dB threshold', ...
    'Location', 'best');


%% Valley depth

nexttile;

plot(phaseDeg, ...
    sweep.uniform.valleyDepthDb, ...
    '-o', ...
    'LineWidth', 1.2, ...
    'MarkerSize', 4);

hold on;

plot(phaseDeg, ...
    sweep.golomb.valleyDepthDb, ...
    '-o', ...
    'LineWidth', 1.2, ...
    'MarkerSize', 4);

yline(3, '--');

grid on;

xlabel('Relative scattering phase / deg');
ylabel('Valley depth / dB');

title('True-target valley depth');

legend( ...
    'Uniform', ...
    'Golomb', ...
    '3 dB threshold', ...
    'Location', 'best');


%% Localization error

nexttile;

plot(phaseDeg, ...
    max( ...
        sweep.uniform.error1Mm, ...
        sweep.uniform.error2Mm), ...
    '-o', ...
    'LineWidth', 1.2, ...
    'MarkerSize', 4);

hold on;

plot(phaseDeg, ...
    max( ...
        sweep.golomb.error1Mm, ...
        sweep.golomb.error2Mm), ...
    '-o', ...
    'LineWidth', 1.2, ...
    'MarkerSize', 4);

grid on;

xlabel('Relative scattering phase / deg');
ylabel('Maximum localization error / mm');

title('Worst target localization error');

legend( ...
    'Uniform', ...
    'Golomb', ...
    'Location', 'best');


%% Pass / fail

nexttile;

stairs(phaseDeg, ...
    double(sweep.uniform.pass), ...
    'LineWidth', 1.4);

hold on;

stairs(phaseDeg, ...
    double(sweep.golomb.pass), ...
    'LineWidth', 1.4);

ylim([-0.1, 1.1]);
yticks([0 1]);
yticklabels({'Fail', 'Pass'});

grid on;

xlabel('Relative scattering phase / deg');
ylabel('Detection result');

title('Overall two-target detection');

legend( ...
    'Uniform', ...
    'Golomb', ...
    'Location', 'best');

end