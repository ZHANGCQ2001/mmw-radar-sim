function results = run_core_experiments(mode, writeArtifacts)
%RUN_CORE_EXPERIMENTS Run the four focused six-node comparison experiments.
%   RESULTS = RUN_CORE_EXPERIMENTS(MODE, WRITEARTIFACTS) runs the single-
%   target and 5 cm two-target cases for uniform and Golomb layouts.

if nargin < 1 || isempty(mode)
    mode = "full";
end
if nargin < 2 || isempty(writeArtifacts)
    writeArtifacts = true;
end

startup();
catalog = mmw.config.listCoreExperiments();
results = struct();

for idx = 1:height(catalog)
    id = catalog.Id(idx);
    fieldName = matlab.lang.makeValidName(char(id));
    results.(fieldName) = run_experiment(id, mode, writeArtifacts);
end
end
