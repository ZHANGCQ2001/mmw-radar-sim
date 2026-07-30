function image = timeDomainMatchedFilter(scene, arrayConfig, waveform, fusion, imaging, transmitSignal, fastTimeS, receive)
%TIMEDOMAINMATCHEDFILTER Form a near-field image from dechirped fast-time IQ.

xGridM = imaging.xLimM(1):imaging.gridStepM:imaging.xLimM(2);
yGridM = imaging.yLimM(1):imaging.gridStepM:imaging.yLimM(2);
numRx = size(arrayConfig.rxLocalM, 1);
numRadars = numel(arrayConfig.radars);
numSamples = numel(fastTimeS);
centerRadar = ceil(numRadars / 2);
window = mmw.util.window("hamming", numSamples);

dechirped = complex(zeros(numSamples, numRx, numRadars));
for radarIndex = 1:numRadars
    for rxIndex = 1:numRx
        loopMean = mean(reshape(receive.signal(:, rxIndex, radarIndex, :), numSamples, []), 2);
        dechirped(:, rxIndex, radarIndex) = transmitSignal .* conj(loopMean) .* window;
    end
end
if fusion.radarAmplitudeEqualization
    [amplitudeGains, rmsAmplitude] = mmw.fusion.radarAmplitudeGains(dechirped, 3);
else
    amplitudeGains = ones(1, numRadars);
    rmsAmplitude = ones(1, numRadars);
end

singlePower = zeros(numel(yGridM), numel(xGridM));
noncoherentPower = zeros(size(singlePower));
coherentComplex = complex(zeros(size(singlePower)));
for yIndex = 1:numel(yGridM)
    for xIndex = 1:numel(xGridM)
        pointM = [xGridM(xIndex), yGridM(yIndex), imaging.zM];
        channelValues = complex(zeros(numRx, numRadars));
        for radarIndex = 1:numRadars
            txM = receive.txGlobalM(radarIndex, :);
            for rxIndex = 1:numRx
                rxM = receive.rxGlobalM(rxIndex, :, radarIndex);
                pathM = norm(pointM - txM) + norm(pointM - rxM);
                delayS = pathM / waveform.speedOfLightMps;
                template = exp(1j * (2*pi*waveform.carrierFrequencyHz*delayS - ...
                    pi*waveform.frequencySlopeHzPerS*delayS^2 + ...
                    2*pi*waveform.frequencySlopeHzPerS*delayS*fastTimeS));
                channelValues(rxIndex, radarIndex) = sum( ...
                    dechirped(:, rxIndex, radarIndex) .* conj(template));
            end
        end
        gate = mmw.fusion.oracleAngleWeights(pointM, receive.txGlobalM, ...
            scene.targets, fusion.oracleAngleGate);
        channelValues = channelValues .* repmat(gate, numRx, 1);
        singlePower(yIndex, xIndex) = sum(abs(channelValues(:, centerRadar)).^2);
        noncoherentPower(yIndex, xIndex) = sum(abs(channelValues(:)).^2);
        equalized = channelValues .* repmat(amplitudeGains, numRx, 1);
        coherentComplex(yIndex, xIndex) = sum(equalized(:));
    end
end

image.method = "time-domain matched filter";
image.xGridM = xGridM;
image.yGridM = yGridM;
image.zM = imaging.zM;
image.singleRadarPower = singlePower;
image.noncoherentPower = noncoherentPower;
image.coherentPower = abs(coherentComplex).^2;
image.radarAmplitudeGains = amplitudeGains;
image.radarRmsAmplitude = rmsAmplitude;
image.centerRadarIndex = centerRadar;
end
