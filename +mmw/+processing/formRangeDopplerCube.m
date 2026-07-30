function processed = formRangeDopplerCube(receive, transmitSignal, waveform, processing)
%FORMRANGEDOPPLERCUBE Dechirp and form the full complex range-Doppler IQ cube.

numSamples = size(receive.signal, 1);
numRx = size(receive.signal, 2);
numRadars = size(receive.signal, 3);
numChirps = size(receive.signal, 4);
rangeFftSize = processing.rangeFftSize;
dopplerFftSize = processing.dopplerFftSize;
rangeWindow = mmw.util.window(processing.rangeWindow, numSamples);
dopplerWindow = mmw.util.window(processing.dopplerWindow, numChirps);

dechirped = complex(zeros(numSamples, numRx, numRadars, numChirps));
rangeFft = complex(zeros(rangeFftSize/2 + 1, numRx, numRadars, numChirps));
for radarIndex = 1:numRadars
    for rxIndex = 1:numRx
        for chirpIndex = 1:numChirps
            signal = transmitSignal .* conj(receive.signal(:, rxIndex, radarIndex, chirpIndex));
            dechirped(:, rxIndex, radarIndex, chirpIndex) = signal;
            spectrum = fft(signal .* rangeWindow, rangeFftSize);
            rangeFft(:, rxIndex, radarIndex, chirpIndex) = spectrum(1:rangeFftSize/2+1);
        end
    end
end

dopplerShape = reshape(dopplerWindow, 1, 1, 1, []);
rangeDopplerIq = fftshift(fft(rangeFft .* dopplerShape, dopplerFftSize, 4), 4);
beatFrequencyHz = (0:rangeFftSize/2).' / rangeFftSize * waveform.sampleRateHz;
rangeAxisM = beatFrequencyHz * waveform.speedOfLightMps / ...
    (2 * waveform.frequencySlopeHzPerS);
dopplerFrequencyHz = (-dopplerFftSize/2:dopplerFftSize/2-1).' / ...
    (dopplerFftSize * waveform.chirpCycleTimeS);
velocityAxisMps = dopplerFrequencyHz * waveform.wavelengthM / 2;

processed.dechirped = dechirped;
processed.rangeFftIq = rangeFft;
processed.rangeDopplerIq = rangeDopplerIq;
processed.rangeAxisM = rangeAxisM;
processed.beatFrequencyHz = beatFrequencyHz;
processed.dopplerFrequencyHz = dopplerFrequencyHz;
processed.velocityAxisMps = velocityAxisMps;
processed.rangePower = squeeze(mean(mean(abs(rangeFft).^2, 2), 4));
processed.rangeDopplerPower = squeeze(mean(abs(rangeDopplerIq).^2, 2));
end
