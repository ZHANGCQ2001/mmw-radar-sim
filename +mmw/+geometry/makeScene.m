function scene = makeScene(spec, sceneConfig, separationM)
%MAKESCENE Build preset or custom target scenes.
%
% Preset examples:
%   scene = mmw.geometry.makeScene("single", cfg.scene);
%   scene = mmw.geometry.makeScene("two", cfg.scene, 0.05);
%
% Custom example:
%   spec.positionsM = [
%       2.93 2.98 1.20
%       2.98 2.98 1.20
%       3.04 3.01 1.20
%       3.10 2.95 1.20
%   ];
%
%   spec.rcsM2 = 1;
%   spec.scatterPhaseRad = 0;
%
%   scene = mmw.geometry.makeScene(spec, cfg.scene);

arguments
    spec
    sceneConfig struct
    separationM (1,1) double = NaN
end


%% ============================================================
% Convert preset to generic scene specification
% =============================================================

if ischar(spec)
    spec = string(spec);
end


if isstring(spec)

    if ~isscalar(spec)
        error('Scene preset must be a scalar string.');
    end

    if isnan(separationM)
        separationM = ...
            sceneConfig.defaultSeparationM;
    end

    centerM = ...
        sceneConfig.centerM;


    switch lower(spec)

        case {"single", "one"}

            positionsM = ...
                centerM;

            sceneType = ...
                "single";


        case {"two", "double", "two_5cm"}

            positionsM = [
                centerM + [-separationM/2, 0, 0]
                centerM + [ separationM/2, 0, 0]
            ];

            sceneType = ...
                "two";


        otherwise

            error( ...
                'Unknown scene preset: %s.', ...
                spec);

    end


    customSpec.positionsM = ...
        positionsM;

    customSpec.type = ...
        sceneType;

    customSpec.separationM = ...
        separationM;

    spec = ...
        customSpec;

end


%% ============================================================
% Validate custom specification
% =============================================================

if ~isstruct(spec)
    error( ...
        'Scene specification must be a preset string or struct.');
end


if ~isfield(spec, 'positionsM')
    error( ...
        'Custom scene must contain spec.positionsM.');
end


positionsM = ...
    double(spec.positionsM);


if size(positionsM,2) ~= 3
    error( ...
        'spec.positionsM must be N x 3.');
end


numTargets = ...
    size(positionsM,1);


if numTargets < 1
    error( ...
        'Scene must contain at least one target.');
end


%% ============================================================
% Target parameters
% =============================================================

rcsM2 = ...
    expandScalarParameter( ...
        spec, ...
        'rcsM2', ...
        sceneConfig.defaultRcsM2, ...
        numTargets);


scatterPhaseRad = ...
    expandScalarParameter( ...
        spec, ...
        'scatterPhaseRad', ...
        sceneConfig.defaultScatterPhaseRad, ...
        numTargets);


velocityMps = ...
    expandVelocity( ...
        spec, ...
        sceneConfig.defaultVelocityMps, ...
        numTargets);


%% ============================================================
% Construct targets
% =============================================================

prototype = struct( ...
    'name', "", ...
    'positionM', [0,0,0], ...
    'velocityMps', [0,0,0], ...
    'rcsM2', 1.0, ...
    'scatterPhaseRad', 0.0);


targets = ...
    repmat( ...
        prototype, ...
        1, ...
        numTargets);


for k = 1:numTargets

    targets(k).name = ...
        "T" + k;

    targets(k).positionM = ...
        positionsM(k,:);

    targets(k).velocityMps = ...
        velocityMps(k,:);

    targets(k).rcsM2 = ...
        rcsM2(k);

    targets(k).scatterPhaseRad = ...
        scatterPhaseRad(k);

end


%% ============================================================
% Scene metadata
% =============================================================

if isfield(spec, 'type')

    scene.type = ...
        string(spec.type);

else

    scene.type = ...
        "custom";

end


if isfield(spec, 'separationM')

    scene.separationM = ...
        spec.separationM;

else

    scene.separationM = ...
        NaN;

end


scene.targets = ...
    targets;

end


%% ============================================================
% Local helpers
% =============================================================

function value = expandScalarParameter( ...
    spec, fieldName, defaultValue, numTargets)

if isfield(spec, fieldName)

    value = ...
        spec.(fieldName);

else

    value = ...
        defaultValue;

end


value = ...
    value(:);


if isscalar(value)

    value = ...
        repmat( ...
            value, ...
            numTargets, ...
            1);

elseif numel(value) ~= numTargets

    error( ...
        '%s must be scalar or contain one value per target.', ...
        fieldName);

end

end


function velocityMps = expandVelocity( ...
    spec, defaultVelocityMps, numTargets)

if isfield(spec, 'velocityMps')

    velocityMps = ...
        double(spec.velocityMps);

else

    velocityMps = ...
        defaultVelocityMps;

end


if isequal(size(velocityMps), [1,3])

    velocityMps = ...
        repmat( ...
            velocityMps, ...
            numTargets, ...
            1);

elseif ~isequal(size(velocityMps), [numTargets,3])

    error( ...
        'velocityMps must be 1x3 or N x 3.');

end

end