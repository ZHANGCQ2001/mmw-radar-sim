function cfg = baseExperiment()
%BASEEXPERIMENT Return the canonical single-carrier experiment configuration.
%   All distances are metres, frequencies hertz, times seconds, and angles
%   radians unless a field name explicitly states otherwise.

cfg.id = "base";
cfg.description = "Base distributed FMCW near-field experiment";

cfg.waveform.speedOfLightMps = 299792458;
cfg.waveform.carrierFrequenciesHz = 62e9;
cfg.waveform.numAdcSamples = 256;
cfg.waveform.sampleRateHz = 5e6;
cfg.waveform.frequencySlopeHzPerS = 60e12;
cfg.waveform.rampEndTimeS = 60e-6;
cfg.waveform.idleTimeS = 7e-6;
cfg.waveform.numChirps = 64;

cfg.array.radars = makeRadars([1.5, 3.0, 4.5]);
cfg.array.txLocalM = [0, 0, 0];
cfg.array.rxLocalM = [0, 0, 0];

cfg.scene.roomSizeM = [6.0, 5.0, 2.8];
cfg.scene.targets = makeTargets([3.0, 3.0, 1.2]);

cfg.simulation.randomSeed = 7;
cfg.simulation.noiseStd = 1e-5;
cfg.simulation.rxGain = 1.0;
cfg.simulation.pathLossExponent = 2.0;

cfg.processing.rangeWindow = "hamming";
cfg.processing.dopplerWindow = "hamming";
cfg.processing.rangeFftSize = 512;
cfg.processing.dopplerFftSize = 128;

cfg.imaging.xLimM = [2.7, 3.3];
cfg.imaging.yLimM = [2.8, 3.2];
cfg.imaging.zM = 1.2;
cfg.imaging.gridStepM = 0.025;
cfg.imaging.velocityMps = 0.0;
cfg.imaging.enableTimeDomain = true;
cfg.imaging.enableRangeDoppler = true;

cfg.fusion.radarAmplitudeEqualization = true;
cfg.fusion.coherenceFactor.enabled = false;
cfg.fusion.coherenceFactor.floor = 0.2;
cfg.fusion.coherenceFactor.power = 1.0;
cfg.fusion.oracleAngleGate.enabled = false;
cfg.fusion.oracleAngleGate.halfWidthDeg = 1.0;

cfg.metrics.valleyThresholdDb = 3.0;
cfg.metrics.peakMinSeparationM = NaN;
cfg.metrics.targetMatchRadiusM = NaN;
cfg.metrics.singleTargetExclusionRadiusM = 0.075;

cfg.output.writeArtifacts = true;
cfg.output.saveMat = false;
cfg.output.exportFigures = true;
cfg.output.rootDirectory = fullfile(mmw.util.projectRoot(), 'artifacts');
end

function radars = makeRadars(xM)
prototype = struct('name', "", 'positionM', [0, 0, 0], 'yawRad', 0.0);
radars = repmat(prototype, 1, numel(xM));
for idx = 1:numel(xM)
    radars(idx).name = "R" + idx;
    radars(idx).positionM = [xM(idx), 0.0, 1.2];
end
end

function targets = makeTargets(positionM)
if isempty(positionM)
    targets = struct('name', {}, 'positionM', {}, 'velocityMps', {}, 'rcs', {});
    return;
end
if isvector(positionM)
    positionM = reshape(positionM, 1, 3);
end
prototype = struct('name', "", 'positionM', [0, 0, 0], ...
    'velocityMps', [0, 0, 0], 'rcs', 1.0);
targets = repmat(prototype, 1, size(positionM, 1));
for idx = 1:size(positionM, 1)
    targets(idx).name = "T" + idx;
    targets(idx).positionM = positionM(idx, :);
end
end
