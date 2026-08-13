function result = runExperiment(exp, cfg)
%RUNEXPERIMENT Execute one complete simulation experiment.

arguments
    exp struct
    cfg struct = mmw.config.defaultConfig()
end


%% ============================================================
% Array
% =============================================================

array = ...
    mmw.geometry.makeArray( ...
        exp.arrayType, ...
        cfg.array);


%% ============================================================
% Scene
% =============================================================

scene = ...
    mmw.geometry.makeScene( ...
        exp.sceneSpec, ...
        cfg.scene, ...
        exp.separationM);


%% ============================================================
% Initialize outputs
% =============================================================

observation = [];
study = [];
reconstruction = [];
ompMetrics = [];


%% ============================================================
% Processing path
% =============================================================

switch lower(exp.reconstruction.method)

    case "none"

        %% Full multi-carrier imaging study

        study = ...
            mmw.fusion.runCarrierSet( ...
                cfg, ...
                array, ...
                scene, ...
                exp.carrierHz, ...
                exp.fusionMethod);


    case "omp"

        %% Lightweight multi-carrier IF observation

        observation = ...
            mmw.signal.simulateCarrierSet( ...
                cfg, ...
                array, ...
                scene, ...
                exp.carrierHz);


        %% Number of OMP targets

        maxTargets = ...
            exp.reconstruction.maxTargets;


        if isempty(maxTargets)

            maxTargets = ...
                numel(scene.targets);

        end


        %% OMP reconstruction

        reconstruction = ...
            mmw.reconstruction.ompMultiCarrier( ...
                cfg, ...
                array, ...
                observation, ...
                maxTargets);


        %% OMP evaluation

        if reconstruction.numTargets == numel(scene.targets)

            ompMetrics = ...
                mmw.metrics.evaluateOmp( ...
                    cfg, ...
                    scene, ...
                    reconstruction);

        end


    otherwise

        error( ...
            'Unknown reconstruction method: %s', ...
            exp.reconstruction.method);

end


%% ============================================================
% Output
% =============================================================

result.config = ...
    cfg;

result.experiment = ...
    exp;

result.array = ...
    array;

result.scene = ...
    scene;

result.observation = ...
    observation;

result.study = ...
    study;

result.reconstruction = ...
    reconstruction;

result.ompMetrics = ...
    ompMetrics;

end