function result = run_case(arrayType, sceneType, doPlot, separationM)
%RUN_CASE Convenience entry point for one array/scene combination.
%
% Examples:
%   result = run_case("uniform", "single", true);
%   result = run_case("golomb", "two", true, 0.05);

arguments
    arrayType (1,1) string
    sceneType (1,1) string
    doPlot (1,1) logical = true
    separationM (1,1) double = NaN
end

cfg = mmw.config.defaultConfig();
array = mmw.geometry.makeArray(arrayType, cfg.array);
scene = mmw.geometry.makeScene(sceneType, cfg.scene, separationM);
result = mmw.runSimulation(cfg, array, scene);

if doPlot
    mmw.plotting.plotResult(result);
end

printSummary(result);
end

function printSummary(result)
fprintf('\nArray: %s | Scene: %s\n', result.array.type, result.scene.type);
if numel(result.scene.targets) == 1
    fprintf('Localization error: %.2f mm\n', result.metrics.localizationErrorM*1e3);
    fprintf('3 dB width x/y: %.2f / %.2f mm\n', ...
        result.metrics.width3dBXM*1e3, result.metrics.width3dBYM*1e3);
    fprintf('PSLR: %.2f dB\n', result.metrics.pslrDb);
    fprintf('ISLR: %.2f dB\n', result.metrics.islrDb);
else
    fprintf('Target errors: %.2f / %.2f mm\n', result.metrics.localizationErrorM*1e3);
    fprintf('Coverage: %d/2\n', result.metrics.coverage);
    fprintf('Valley depth: %.2f dB\n', result.metrics.valleyDepthDb);
    fprintf('Target-to-strongest-false-peak: %.2f dB\n', ...
        result.metrics.targetToFalsePeakDb);
    fprintf('Separated: %d | False peak controlled: %d | Pass: %d\n', ...
        result.metrics.separated, result.metrics.falsePeakControlled, result.metrics.pass);
end
end
