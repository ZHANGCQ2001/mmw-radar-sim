function waveform = deriveWaveform(waveformConfig, carrierFrequencyHz)
%DERIVEWAVEFORM Compute carrier-dependent and sampled FMCW quantities.

waveform = waveformConfig;
waveform.carrierFrequencyHz = carrierFrequencyHz;
waveform.wavelengthM = waveform.speedOfLightMps / carrierFrequencyHz;
waveform.chirpCycleTimeS = waveform.rampEndTimeS + waveform.idleTimeS;
waveform.adcDurationS = waveform.numAdcSamples / waveform.sampleRateHz;
waveform.sampledBandwidthHz = waveform.frequencySlopeHzPerS * waveform.adcDurationS;
waveform.rangeResolutionM = waveform.speedOfLightMps / (2 * waveform.sampledBandwidthHz);
waveform.maxBeatFrequencyHz = waveform.sampleRateHz / 2;
waveform.maxRangeM = waveform.maxBeatFrequencyHz * waveform.speedOfLightMps / ...
    (2 * waveform.frequencySlopeHzPerS);
end
