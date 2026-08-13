function study = run_compare_arrays(doPlot)
%RUN_COMPARE_ARRAYS Run the four core array-only simulations.
%
%   study = run_compare_arrays(true)
%   compares six-node uniform and Golomb arrays for one target and for two
%   targets separated by 5 cm. Every non-array parameter is identical.

arguments
    doPlot (1,1) logical = true
end

cfg = mmw.config.defaultConfig();
uniform = mmw.geometry.makeArray("uniform", cfg.array);
golomb = mmw.geometry.makeArray("golomb", cfg.array);
singleScene = mmw.geometry.makeScene("single", cfg.scene);
twoScene = mmw.geometry.makeScene("two", cfg.scene, 0.05);

study.config = cfg;
study.uniform.single = mmw.runSimulation(cfg, uniform, singleScene);
study.golomb.single = mmw.runSimulation(cfg, golomb, singleScene);
study.uniform.two = mmw.runSimulation(cfg, uniform, twoScene);
study.golomb.two = mmw.runSimulation(cfg, golomb, twoScene);
study.summary = buildSummary(study);

disp(study.summary);
if doPlot
    study.figures = mmw.plotting.plotComparison(study);
end
end

function T = buildSummary(study)
array = ["Uniform"; "Golomb"; "Uniform"; "Golomb"];
scene = ["Single"; "Single"; "Two 5 cm"; "Two 5 cm"];
r = {study.uniform.single; study.golomb.single; ...
     study.uniform.two; study.golomb.two};

localization1Mm = nan(4,1);
localization2Mm = nan(4,1);
pslrDb = nan(4,1);
valleyDepthDb = nan(4,1);
targetToFalseDb = nan(4,1);
pass = false(4,1);

for k = 1:4
    m = r{k}.metrics;
    localization1Mm(k) = m.localizationErrorM(1)*1e3;
    if numel(m.localizationErrorM) > 1
        localization2Mm(k) = m.localizationErrorM(2)*1e3;
        valleyDepthDb(k) = m.valleyDepthDb;
        targetToFalseDb(k) = m.targetToFalsePeakDb;
    else
        pslrDb(k) = m.pslrDb;
    end
    pass(k) = m.pass;
end

T = table(array, scene, localization1Mm, localization2Mm, pslrDb, ...
    valleyDepthDb, targetToFalseDb, pass);
end
