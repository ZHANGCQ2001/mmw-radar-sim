function cfg = validateExperiment(cfg)
%VALIDATEEXPERIMENT Validate and normalize an ExperimentConfig.

required = {'waveform','array','scene','simulation','processing','imaging', ...
    'fusion','metrics','output'};
for idx = 1:numel(required)
    assert(isfield(cfg, required{idx}), 'mmw:config:MissingField', ...
        'Missing top-level config field: %s', required{idx});
end

w = cfg.waveform;
mustBePositiveFinite(w.speedOfLightMps, 'speedOfLightMps');
mustBePositiveFinite(w.carrierFrequenciesHz, 'carrierFrequenciesHz');
mustBePositiveInteger(w.numAdcSamples, 'numAdcSamples');
mustBePositiveInteger(w.numChirps, 'numChirps');
mustBePositiveFinite(w.sampleRateHz, 'sampleRateHz');
mustBePositiveFinite(w.frequencySlopeHzPerS, 'frequencySlopeHzPerS');
mustBePositiveFinite(w.rampEndTimeS, 'rampEndTimeS');
mustBePositiveFinite(w.idleTimeS, 'idleTimeS');
assert(numel(w.carrierFrequenciesHz) <= 2, 'mmw:config:CarrierCount', ...
    'Only one or two carrier frequencies are supported.');

mustBePositiveInteger(cfg.processing.rangeFftSize, 'rangeFftSize');
mustBePositiveInteger(cfg.processing.dopplerFftSize, 'dopplerFftSize');
assert(cfg.processing.rangeFftSize >= w.numAdcSamples, 'mmw:config:RangeFftTooShort', ...
    'rangeFftSize must be at least numAdcSamples.');
assert(cfg.processing.dopplerFftSize >= w.numChirps, 'mmw:config:DopplerFftTooShort', ...
    'dopplerFftSize must be at least numChirps.');
assert(mod(cfg.processing.rangeFftSize, 2) == 0, 'mmw:config:RangeFftParity', ...
    'rangeFftSize must be even.');
assert(mod(cfg.processing.dopplerFftSize, 2) == 0, 'mmw:config:DopplerFftParity', ...
    'dopplerFftSize must be even.');

assert(numel(cfg.imaging.xLimM) == 2 && diff(cfg.imaging.xLimM) > 0, ...
    'mmw:config:InvalidXGrid', 'xLimM must be increasing.');
assert(numel(cfg.imaging.yLimM) == 2 && diff(cfg.imaging.yLimM) > 0, ...
    'mmw:config:InvalidYGrid', 'yLimM must be increasing.');
mustBePositiveFinite(cfg.imaging.gridStepM, 'gridStepM');
assert(~isempty(cfg.array.radars), 'mmw:config:NoRadars', 'At least one radar is required.');
assert(size(cfg.array.txLocalM, 2) == 3 && size(cfg.array.rxLocalM, 2) == 3, ...
    'mmw:config:ArrayDimensions', 'Local phase-centre arrays must have three columns.');

for idx = 1:numel(cfg.scene.targets)
    target = cfg.scene.targets(idx);
    assert(numel(target.positionM) == 3 && all(isfinite(target.positionM)), ...
        'mmw:config:TargetPosition', 'Each target position must contain three finite values.');
    mustBePositiveFinite(target.rcs, 'target.rcs');
end
if cfg.fusion.oracleAngleGate.enabled
    assert(~isempty(cfg.scene.targets), 'mmw:config:OracleNeedsTruth', ...
        'Oracle angle gating requires target truth.');
    mustBePositiveFinite(cfg.fusion.oracleAngleGate.halfWidthDeg, ...
        'oracleAngleGate.halfWidthDeg');
end

if isnan(cfg.metrics.peakMinSeparationM)
    cfg.metrics.peakMinSeparationM = defaultTargetScale(cfg.scene.targets) / 2;
end
if isnan(cfg.metrics.targetMatchRadiusM)
    cfg.metrics.targetMatchRadiusM = defaultTargetScale(cfg.scene.targets) / 2;
end
cfg.output.rootDirectory = char(cfg.output.rootDirectory);
end

function value = defaultTargetScale(targets)
if numel(targets) < 2
    value = 0.05;
    return;
end
positions = reshape([targets.positionM], 3, []).';
distances = [];
for a = 1:size(positions, 1)
    for b = a+1:size(positions, 1)
        distances(end+1) = norm(positions(a, 1:2) - positions(b, 1:2)); %#ok<AGROW>
    end
end
value = min(distances);
end

function mustBePositiveFinite(value, name)
assert(isnumeric(value) && all(isfinite(value(:))) && all(value(:) > 0), ...
    'mmw:config:PositiveFinite', '%s must contain positive finite values.', name);
end

function mustBePositiveInteger(value, name)
assert(isscalar(value) && isfinite(value) && value > 0 && value == round(value), ...
    'mmw:config:PositiveInteger', '%s must be a positive integer.', name);
end
