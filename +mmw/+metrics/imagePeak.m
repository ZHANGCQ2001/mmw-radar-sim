function peak = imagePeak(powerImage, xGridM, yGridM, targets)
%IMAGEPEAK Locate the global image peak and optionally match target truth.

[power, linearIndex] = max(powerImage(:));
[yIndex, xIndex] = ind2sub(size(powerImage), linearIndex);
peak.positionM = [xGridM(xIndex), yGridM(yIndex)];
peak.power = power;
peak.powerDb = 10 * log10(power + eps);
peak.nearestTargetName = "";
peak.nearestTargetErrorM = NaN;
if isempty(targets)
    return;
end
targetM = reshape([targets.positionM], 3, []).';
[peak.nearestTargetErrorM, targetIndex] = min(vecnorm(targetM(:, 1:2) - peak.positionM, 2, 2));
peak.nearestTargetName = string(targets(targetIndex).name);
end
