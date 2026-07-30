function coverage = targetCoverage(peaks, targets, matchRadiusM)
%TARGETCOVERAGE Match detected peaks to truth and report unique coverage.

numTargets = numel(targets);
detected = false(1, numTargets);
if isempty(targets)
    coverage.numDetectedTargets = 0;
    coverage.numTargets = 0;
    coverage.detectedTargetNames = strings(1, 0);
    coverage.missingTargetNames = strings(1, 0);
    coverage.allTargetsDetected = true;
    coverage.peaks = peaks;
    return;
end
targetM = reshape([targets.positionM], 3, []).';
for peakIndex = 1:numel(peaks)
    distancesM = vecnorm(targetM(:, 1:2) - peaks(peakIndex).positionM, 2, 2);
    [errorM, targetIndex] = min(distancesM);
    peaks(peakIndex).nearestTargetName = string(targets(targetIndex).name);
    peaks(peakIndex).nearestTargetErrorM = errorM;
    if errorM <= matchRadiusM
        detected(targetIndex) = true;
    end
end
coverage.numDetectedTargets = sum(detected);
coverage.numTargets = numTargets;
coverage.detectedTargetNames = string({targets(detected).name});
coverage.missingTargetNames = string({targets(~detected).name});
coverage.allTargetsDetected = all(detected);
coverage.matchRadiusM = matchRadiusM;
coverage.peaks = peaks;
end
