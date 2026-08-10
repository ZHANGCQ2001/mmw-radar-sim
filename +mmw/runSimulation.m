function result = runSimulation(cfg, array, scene)
%RUNSIMULATION Execute the minimal FMCW coherent-imaging chain.

validateInputs(cfg, array, scene);
[ifData, signalMeta] = mmw.signal.simulateIF(cfg, array, scene);
rd = mmw.processing.rangeDoppler(cfg, ifData);
image = mmw.imaging.coherentImage(cfg, array, rd);
metrics = mmw.metrics.evaluateImage(cfg, scene, image);

result.config = cfg;
result.array = array;
result.scene = scene;
result.ifData = ifData;
result.signal = signalMeta;
result.rd = rd;
result.image = image;
result.metrics = metrics;
end

function validateInputs(cfg, array, scene)
if array.numNodes ~= cfg.array.numNodes
    error('Array node count does not match cfg.array.numNodes.');
end
if size(array.positionsM,2) ~= 3
    error('array.positionsM must be N x 3.');
end
if isempty(scene.targets)
    error('Scene must contain at least one target.');
end
if cfg.imaging.gridStepM <= 0
    error('cfg.imaging.gridStepM must be positive.');
end
end
