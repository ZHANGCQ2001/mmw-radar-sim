function scene = makeCustomScene(positionsM, sceneConfig)
%MAKECUSTOMSCENE Build a custom multi-target scene.

arguments
    positionsM (:,3) double
    sceneConfig struct
end

numTargets = size(positionsM, 1);

if numTargets < 1
    error('positionsM must contain at least one target.');
end

prototype = struct( ...
    'name', "", ...
    'positionM', [0,0,0], ...
    'velocityMps', [0,0,0], ...
    'rcsM2', 1.0, ...
    'scatterPhaseRad', 0.0);

targets = repmat( ...
    prototype, ...
    1, ...
    numTargets);

for k = 1:numTargets

    targets(k).name = ...
        "T" + k;

    targets(k).positionM = ...
        positionsM(k,:);

    targets(k).velocityMps = ...
        sceneConfig.defaultVelocityMps;

    targets(k).rcsM2 = ...
        sceneConfig.defaultRcsM2;

    targets(k).scatterPhaseRad = ...
        sceneConfig.defaultScatterPhaseRad;

end

scene.type = "custom";
scene.separationM = NaN;
scene.targets = targets;

end