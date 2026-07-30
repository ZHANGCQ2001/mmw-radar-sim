function result = run_experiment(experimentId, mode, writeArtifacts)
%RUN_EXPERIMENT Run a named v2 experiment.
%   RESULT = RUN_EXPERIMENT(ID, MODE, WRITEARTIFACTS) loads ID, where MODE is
%   "full" or "smoke". Artifact writing defaults to the config policy.

if nargin < 2 || isempty(mode)
    mode = "full";
end
startup();
cfg = mmw.config.loadExperiment(experimentId, mode);
if nargin >= 3
    cfg.output.writeArtifacts = logical(writeArtifacts);
end
result = mmw.runExperiment(cfg);
end
