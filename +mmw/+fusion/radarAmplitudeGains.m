function [gains, rmsAmplitude] = radarAmplitudeGains(channelData, radarDimension)
%RADARAMPLITUDEGAINS Compute constant median-referenced RMS gain per radar.

numRadars = size(channelData, radarDimension);
rmsAmplitude = zeros(1, numRadars);
for radarIndex = 1:numRadars
    subscripts = repmat({':'}, 1, ndims(channelData));
    subscripts{radarDimension} = radarIndex;
    values = channelData(subscripts{:});
    rmsAmplitude(radarIndex) = sqrt(mean(abs(values(:)).^2));
end
reference = median(rmsAmplitude);
if reference <= eps
    gains = ones(1, numRadars);
else
    gains = reference ./ max(rmsAmplitude, eps);
end
end
