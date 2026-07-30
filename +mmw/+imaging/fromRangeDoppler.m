function image = fromRangeDoppler(scene, arrayConfig, waveform, fusion, imaging, processed, receive)
%FROMRANGEDOPPLER Form x-y near-field images from interpolated complex RD-IQ.
%   Ordinary operation is truth-independent. Truth is read only by the
%   explicitly enabled oracle angle gate.

xGridM = imaging.xLimM(1):imaging.gridStepM:imaging.xLimM(2);
yGridM = imaging.yLimM(1):imaging.gridStepM:imaging.yLimM(2);
numX = numel(xGridM);
numY = numel(yGridM);
numRx = size(arrayConfig.rxLocalM, 1);
numRadars = numel(arrayConfig.radars);
centerRadar = ceil(numRadars / 2);

if fusion.radarAmplitudeEqualization
    [amplitudeGains, rmsAmplitude] = mmw.fusion.radarAmplitudeGains( ...
        processed.rangeDopplerIq, 3);
else
    amplitudeGains = ones(1, numRadars);
    rmsAmplitude = ones(1, numRadars);
end

rdCubes = cell(numRx, numRadars);
for radarIndex = 1:numRadars
    for rxIndex = 1:numRx
        rdCubes{rxIndex, radarIndex} = squeeze( ...
            processed.rangeDopplerIq(:, rxIndex, radarIndex, :));
    end
end

singlePower = zeros(numY, numX);
noncoherentPower = zeros(numY, numX);
coherentComplex = complex(zeros(numY, numX));
coherenceFactor = zeros(numY, numX);
coherentCfPower = zeros(numY, numX);

for yIndex = 1:numY
    for xIndex = 1:numX
        pointM = [xGridM(xIndex), yGridM(yIndex), imaging.zM];
        channelValues = complex(zeros(numRx, numRadars));
        for radarIndex = 1:numRadars
            txM = receive.txGlobalM(radarIndex, :);
            for rxIndex = 1:numRx
                rxM = receive.rxGlobalM(rxIndex, :, radarIndex);
                pathM = norm(pointM - txM) + norm(pointM - rxM);
                delayS = pathM / waveform.speedOfLightMps;
                rangeM = pathM / 2;
                rdValue = interp2(processed.velocityAxisMps, processed.rangeAxisM, ...
                    rdCubes{rxIndex, radarIndex}, imaging.velocityMps, rangeM, 'linear', 0);
                dechirpPhaseRad = 2*pi*waveform.carrierFrequencyHz*delayS - ...
                    pi*waveform.frequencySlopeHzPerS*delayS^2;
                channelValues(rxIndex, radarIndex) = rdValue * exp(-1j * dechirpPhaseRad);
            end
        end
        gate = mmw.fusion.oracleAngleWeights(pointM, receive.txGlobalM, ...
            scene.targets, fusion.oracleAngleGate);
        channelValues = channelValues .* repmat(gate, numRx, 1);
        singlePower(yIndex, xIndex) = sum(abs(channelValues(:, centerRadar)).^2);
        noncoherentPower(yIndex, xIndex) = sum(abs(channelValues(:)).^2);
        equalized = channelValues .* repmat(amplitudeGains, numRx, 1);
        coherentValue = sum(equalized(:));
        coherentPower = abs(coherentValue)^2;
        cf = coherentPower / (numel(equalized) * sum(abs(equalized(:)).^2) + eps);
        cf = min(max(real(cf), 0), 1);
        coherentComplex(yIndex, xIndex) = coherentValue;
        coherenceFactor(yIndex, xIndex) = cf;
        if fusion.coherenceFactor.enabled
            coherentCfPower(yIndex, xIndex) = coherentPower * ...
                max(cf, fusion.coherenceFactor.floor)^fusion.coherenceFactor.power;
        else
            coherentCfPower(yIndex, xIndex) = coherentPower;
        end
    end
end

image.method = "complex range-Doppler interpolation";
image.xGridM = xGridM;
image.yGridM = yGridM;
image.zM = imaging.zM;
image.singleRadarPower = singlePower;
image.noncoherentPower = noncoherentPower;
image.coherentPower = abs(coherentComplex).^2;
image.coherentCfPower = coherentCfPower;
image.coherenceFactor = coherenceFactor;
image.radarAmplitudeGains = amplitudeGains;
image.radarRmsAmplitude = rmsAmplitude;
image.centerRadarIndex = centerRadar;
end
