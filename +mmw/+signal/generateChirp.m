function [transmitSignal, fastTimeS] = generateChirp(waveform)
%GENERATECHIRP Generate one complex baseband linear-FM ADC interval.
%   WAVEFORM uses Hz, Hz/s, and samples/s. FASTTIMES is relative to ADC start.

sampleIndex = (0:waveform.numAdcSamples-1).';
fastTimeS = sampleIndex / waveform.sampleRateHz;
transmitSignal = exp(1j * pi * waveform.frequencySlopeHzPerS * fastTimeS.^2);
end
