function scene = makeScene(type, sceneConfig, separationM)
%MAKESCENE Build the single-target or two-target study scene.

arguments
    type (1,1) string
    sceneConfig struct
    separationM (1,1) double = NaN
end

if isnan(separationM)
    separationM = sceneConfig.defaultSeparationM;
end

centerM = sceneConfig.centerM;

switch lower(type)
    case {"single", "one"}
        positionsM = centerM;
        canonicalType = "single";

    case {"two", "double", "two_5cm"}
        positionsM = [centerM + [-separationM/2, 0, 0]; ...
                      centerM + [ separationM/2, 0, 0]];
        canonicalType = "two";

    otherwise
        error('Unknown scene type: %s. Use "single" or "two".', type);
end

prototype = struct('name', "", 'positionM', [0,0,0], ...
    'velocityMps', [0,0,0], 'rcsM2', 1.0, 'scatterPhaseRad', 0.0);
targets = repmat(prototype, 1, size(positionsM,1));

for k = 1:numel(targets)
    targets(k).name = "T" + k;
    targets(k).positionM = positionsM(k,:);
    targets(k).velocityMps = sceneConfig.defaultVelocityMps;
    targets(k).rcsM2 = sceneConfig.defaultRcsM2;
    targets(k).scatterPhaseRad = sceneConfig.defaultScatterPhaseRad;
end

scene.type = canonicalType;
scene.separationM = separationM;
scene.targets = targets;
end
