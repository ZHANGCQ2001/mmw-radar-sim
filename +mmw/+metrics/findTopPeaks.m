function peaks = findTopPeaks(powerImage, xGridM, yGridM, count, minSeparationM)
%FINDTOPPEAKS Select spatially separated image maxima by greedy suppression.

searchImage = powerImage;
[xMeshM, yMeshM] = meshgrid(xGridM, yGridM);
prototype = struct('positionM', [NaN, NaN], 'power', NaN, ...
    'relativePowerDb', NaN, 'nearestTargetName', "", 'nearestTargetErrorM', NaN);
peaks = repmat(prototype, 0, 1);
referencePower = max(powerImage(:));
for peakIndex = 1:count
    [power, linearIndex] = max(searchImage(:));
    if ~isfinite(power) || power <= 0
        break;
    end
    [yIndex, xIndex] = ind2sub(size(searchImage), linearIndex);
    peak = prototype;
    peak.positionM = [xGridM(xIndex), yGridM(yIndex)];
    peak.power = power;
    peak.relativePowerDb = 10 * log10(power / max(referencePower, eps));
    peaks(end+1, 1) = peak; %#ok<AGROW>
    if minSeparationM > 0
        mask = hypot(xMeshM - peak.positionM(1), yMeshM - peak.positionM(2)) < minSeparationM;
        searchImage(mask) = -inf;
    else
        searchImage(yIndex, xIndex) = -inf;
    end
end
end
