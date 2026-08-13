function exp = defaultExperiment()
%DEFAULTEXPERIMENT Default high-level experiment settings.

exp.arrayType = ...
    "golomb";


exp.carrierHz = ...
    (60:0.4:64) * 1e9;

% Fusion method for the full imaging path
% (reconstruction.method = "none").
exp.fusionMethod = ...
    "coherent-normalized";


exp.sceneSpec = ...
    "two";


exp.separationM = ...
    0.05;


exp.reconstruction.method = ...
    "omp";


% Empty means use the number of simulated targets.
exp.reconstruction.maxTargets = ...
    [];


exp.plot.enabled = ...
    true;

end