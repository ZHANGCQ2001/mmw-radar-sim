function receive = simulatePointTargets(scene, arrayConfig, waveform, fastTimeS, simulation, seed)
%SIMULATEPOINTTARGETS Generate complex FMCW returns from exact bistatic paths.
%   Positions are metres, target velocities m/s, and SEED makes noise repeatable.

if nargin < 6
    seed = simulation.randomSeed;
end
rng(seed, 'twister');
geometry = mmw.signal.globalPhaseCenters(arrayConfig);
numSamples = numel(fastTimeS);
numRx = size(arrayConfig.rxLocalM, 1);
numRadars = numel(arrayConfig.radars);
numChirps = waveform.numChirps;
numTargets = numel(scene.targets);

receive.signal = complex(zeros(numSamples, numRx, numRadars, numChirps));
receive.txGlobalM = geometry.txGlobalM;
receive.rxGlobalM = geometry.rxGlobalM;
receive.slowTimeS = (0:numChirps-1).' * waveform.chirpCycleTimeS;
receive.firstChirpPathM = zeros(numTargets, numRx, numRadars);

for radarIndex = 1:numRadars
    txM = geometry.txGlobalM(radarIndex, :);
    for rxIndex = 1:numRx
        rxM = geometry.rxGlobalM(rxIndex, :, radarIndex);
        for chirpIndex = 1:numChirps
            channel = complex(zeros(numSamples, 1));
            slowTimeS = receive.slowTimeS(chirpIndex);
            for targetIndex = 1:numTargets
                target = scene.targets(targetIndex);
                targetM = target.positionM + target.velocityMps * slowTimeS;
                pathM = norm(targetM - txM) + norm(targetM - rxM);
                delayS = pathM / waveform.speedOfLightMps;
                if chirpIndex == 1
                    receive.firstChirpPathM(targetIndex, rxIndex, radarIndex) = pathM;
                end
                delayedTimeS = fastTimeS - delayS;
                carrierPhase = exp(-1j * 2 * pi * waveform.carrierFrequencyHz * delayS);
                delayedChirp = exp(1j * pi * waveform.frequencySlopeHzPerS * delayedTimeS.^2);
                amplitude = simulation.rxGain * sqrt(target.rcs) / ...
                    max(pathM^simulation.pathLossExponent, eps);
                channel = channel + amplitude * carrierPhase .* delayedChirp;
            end
            noise = simulation.noiseStd / sqrt(2) * ...
                (randn(numSamples, 1) + 1j * randn(numSamples, 1));
            receive.signal(:, rxIndex, radarIndex, chirpIndex) = channel + noise;
        end
    end
end
end
