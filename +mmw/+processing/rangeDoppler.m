function rd = rangeDoppler(cfg, ifData)
%RANGEDOPPLER Form the full complex range-Doppler cube.
%   Input: sample x chirp x radar.
%   Output IQ: range x Doppler x radar.

numSamples = size(ifData,1);
numChirps = size(ifData,2);
numRadars = size(ifData,3);
rangeFftSize = cfg.processing.rangeFftSize;
dopplerFftSize = cfg.processing.dopplerFftSize;

if rangeFftSize < numSamples
    error('rangeFftSize must be at least numAdcSamples.');
end
if dopplerFftSize < numChirps
    error('dopplerFftSize must be at least numChirps.');
end

rangeWindow = localWindow(cfg.processing.rangeWindow, numSamples);
dopplerWindow = localWindow(cfg.processing.dopplerWindow, numChirps).';

windowed = ifData .* reshape(rangeWindow, [], 1, 1);
rangeSpectrum = fft(windowed, rangeFftSize, 1);
numPositiveRangeBins = floor(rangeFftSize/2) + 1;
rangeSpectrum = rangeSpectrum(1:numPositiveRangeBins,:,:);

rangeSpectrum = rangeSpectrum .* reshape(dopplerWindow, 1, [], 1);
rdIq = fftshift(fft(rangeSpectrum, dopplerFftSize, 2), 2);

c = cfg.constants.cMps;
S = cfg.waveform.slopeHzPerS;
fs = cfg.waveform.sampleRateHz;
fc = cfg.waveform.fcHz;
chirpPeriodS = cfg.waveform.rampEndTimeS + cfg.waveform.idleTimeS;
lambdaM = c / fc;

beatFrequencyHz = (0:numPositiveRangeBins-1).' / rangeFftSize * fs;
rangeAxisM = beatFrequencyHz * c / (2*S);
dopplerFrequencyHz = (-dopplerFftSize/2:dopplerFftSize/2-1).' / ...
    (dopplerFftSize * chirpPeriodS);
velocityAxisMps = dopplerFrequencyHz * lambdaM / 2;

rd.iq = rdIq;
rd.power = abs(rdIq).^2;
rd.rangeAxisM = rangeAxisM;
rd.velocityAxisMps = velocityAxisMps;
rd.beatFrequencyHz = beatFrequencyHz;
rd.dopplerFrequencyHz = dopplerFrequencyHz;
rd.dataOrder = "range x Doppler x radar";
rd.numRadars = numRadars;
end

function w = localWindow(name, n)
name = lower(string(name));
if n == 1
    w = 1;
    return;
end
k = (0:n-1).';
switch name
    case {"rect", "rectangular", "none"}
        w = ones(n,1);
    case "hann"
        w = 0.5 - 0.5*cos(2*pi*k/(n-1));
    case "hamming"
        w = 0.54 - 0.46*cos(2*pi*k/(n-1));
    otherwise
        error('Unsupported window: %s.', name);
end
end
