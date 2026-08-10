function [ifData, meta] = simulateIF(cfg, array, scene)
%SIMULATEIF Generate dechirped complex FMCW IF data.
%   Output dimensions are sample x chirp x radar.

c = cfg.constants.cMps;
fc = cfg.waveform.fcHz;
S = cfg.waveform.slopeHzPerS;
fs = cfg.waveform.sampleRateHz;
numSamples = cfg.waveform.numAdcSamples;
numChirps = cfg.waveform.numChirps;
numRadars = array.numNodes;
chirpPeriodS = cfg.waveform.rampEndTimeS + cfg.waveform.idleTimeS;

fastTimeS = (0:numSamples-1).' / fs;
slowTimeS = (0:numChirps-1).' * chirpPeriodS;
ifData = complex(zeros(numSamples, numChirps, numRadars));
firstChirpPathM = zeros(numel(scene.targets), numRadars);

for radarIndex = 1:numRadars
    radarM = array.positionsM(radarIndex,:);
    for chirpIndex = 1:numChirps
        tSlow = slowTimeS(chirpIndex);
        channel = complex(zeros(numSamples,1));

        for targetIndex = 1:numel(scene.targets)
            target = scene.targets(targetIndex);
            targetM = target.positionM + target.velocityMps * tSlow;
            pathM = mmw.geometry.pathLength(radarM, targetM);
            tauS = pathM / c;

            if chirpIndex == 1
                firstChirpPathM(targetIndex, radarIndex) = pathM;
            end

            reflectivity = sqrt(target.rcsM2) * exp(1j*target.scatterPhaseRad);
            amplitude = cfg.simulation.rxGain * reflectivity;
            if cfg.simulation.usePathLoss
                amplitude = amplitude / max(pathM^cfg.simulation.pathLossExponent, eps);
            end

            beatHz = S * tauS;
            constantPhaseRad = 2*pi*fc*tauS - pi*S*tauS^2;
            channel = channel + amplitude .* ...
                exp(1j*(2*pi*beatHz*fastTimeS + constantPhaseRad));
        end

        ifData(:, chirpIndex, radarIndex) = channel;
    end
end

if cfg.simulation.noiseStd > 0
    rng(cfg.simulation.randomSeed, 'twister');
    noise = cfg.simulation.noiseStd/sqrt(2) * ...
        (randn(size(ifData)) + 1j*randn(size(ifData)));
    ifData = ifData + noise;
end

meta.fastTimeS = fastTimeS;
meta.slowTimeS = slowTimeS;
meta.firstChirpPathM = firstChirpPathM;
meta.dataOrder = "sample x chirp x radar";
end
