function cfg = defaultConfig()
%DEFAULTCONFIG Common settings for the six-node FMCW array study.

cfg.constants.cMps = 299792458;

cfg.waveform.fcHz = 62e9;
cfg.waveform.numAdcSamples = 256;
cfg.waveform.sampleRateHz = 5e6;
cfg.waveform.slopeHzPerS = 60e12;
cfg.waveform.rampEndTimeS = 60e-6;
cfg.waveform.idleTimeS = 7e-6;
cfg.waveform.numChirps = 64;

cfg.array.numNodes = 6;
cfg.array.apertureM = 3.0;
cfg.array.centerXM = 3.0;
cfg.array.yM = 0.0;
cfg.array.zM = 1.2;
cfg.array.golombMarks = [0, 1, 4, 10, 12, 17];

cfg.scene.centerM = [3.0, 3.0, 1.2];
cfg.scene.defaultSeparationM = 0.05;
cfg.scene.defaultRcsM2 = 1.0;
cfg.scene.defaultScatterPhaseRad = 0.0;
cfg.scene.defaultVelocityMps = [0, 0, 0];

% Array-only baseline: deterministic, equal-amplitude target returns.
cfg.simulation.randomSeed = 7;
cfg.simulation.noiseStd = 0.0;
cfg.simulation.rxGain = 1.0;
cfg.simulation.usePathLoss = false;
cfg.simulation.pathLossExponent = 2.0;

cfg.processing.rangeWindow = "hamming";
cfg.processing.dopplerWindow = "hamming";
cfg.processing.rangeFftSize = 512;
cfg.processing.dopplerFftSize = 128;

cfg.imaging.xLimM = [2.7, 3.3];
cfg.imaging.yLimM = [2.8, 3.2];
cfg.imaging.zM = 1.2;
cfg.imaging.gridStepM = 0.0025;
cfg.imaging.velocityMps = 0.0;

cfg.metrics.targetMatchRadiusM = 0.020;
cfg.metrics.valleyThresholdDb = 3.0;
cfg.metrics.falsePeakThresholdDb = 0.0;
cfg.metrics.targetExclusionXM = 0.020;
cfg.metrics.targetExclusionYM = 0.080;

cfg.plot.dynamicRangeDb = 40;
end
