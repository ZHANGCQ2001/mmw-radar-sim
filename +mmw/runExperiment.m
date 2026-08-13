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
% Multi-carrier observation
% =============================================================

study = ...
    mmw.fusion.runCarrierSet( ...
        cfg, ...
        array, ...
        scene, ...
        exp.carrierHz, ...
        exp.fusionMethod);


%% ============================================================
% Reconstruction
% =============================================================

reconstruction = [];


switch lower(exp.reconstruction.method)

    case "none"

        reconstruction = [];


    case "omp"

        maxTargets = ...
            exp.reconstruction.maxTargets;


        if isempty(maxTargets)

            maxTargets = ...
                numel(scene.targets);

        end


        reconstruction = ...
            mmw.reconstruction.ompMultiCarrier( ...
                cfg, ...
                array, ...
                study, ...
                maxTargets);


    otherwise

        error( ...
            'Unknown reconstruction method: %s', ...
            exp.reconstruction.method);

end


%% ============================================================
% OMP evaluation
% =============================================================

ompMetrics = [];


if ~isempty(reconstruction)

    if reconstruction.numTargets == numel(scene.targets)

        ompMetrics = ...
            mmw.metrics.evaluateOmp( ...
                cfg, ...
                scene, ...
                reconstruction);

    end

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

result.study = ...
    study;

result.reconstruction = ...
    reconstruction;

result.ompMetrics = ...
    ompMetrics;

end