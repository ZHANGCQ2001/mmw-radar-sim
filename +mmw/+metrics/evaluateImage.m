function metrics = evaluateImage(image, targets, metricConfig)
%EVALUATEIMAGE Compute global peak, Top-N coverage, pairs, and single-target PSLR.

metrics.globalPeak = mmw.metrics.imagePeak(image.coherentPower, ...
    image.xGridM, image.yGridM, targets);
metrics.methodPeaks.coherent = metrics.globalPeak;
if isfield(image, 'singleRadarPower')
    metrics.methodPeaks.singleRadar = mmw.metrics.imagePeak(image.singleRadarPower, ...
        image.xGridM, image.yGridM, targets);
end
if isfield(image, 'noncoherentPower')
    metrics.methodPeaks.noncoherent = mmw.metrics.imagePeak(image.noncoherentPower, ...
        image.xGridM, image.yGridM, targets);
end
if isfield(image, 'coherentCfPower')
    metrics.methodPeaks.coherentCf = mmw.metrics.imagePeak(image.coherentCfPower, ...
        image.xGridM, image.yGridM, targets);
end
peakCount = max(1, numel(targets));
peaks = mmw.metrics.findTopPeaks(image.coherentPower, image.xGridM, ...
    image.yGridM, peakCount, metricConfig.peakMinSeparationM);
metrics.coverage = mmw.metrics.targetCoverage(peaks, targets, ...
    metricConfig.targetMatchRadiusM);
metrics.pairs = mmw.metrics.pairProfiles(image.coherentPower, image.xGridM, ...
    image.yGridM, targets, metricConfig.valleyThresholdDb);
metrics.methodPairs.coherent = metrics.pairs;
if isfield(image, 'singleRadarPower')
    metrics.methodPairs.singleRadar = mmw.metrics.pairProfiles(image.singleRadarPower, ...
        image.xGridM, image.yGridM, targets, metricConfig.valleyThresholdDb);
end
if isfield(image, 'noncoherentPower')
    metrics.methodPairs.noncoherent = mmw.metrics.pairProfiles(image.noncoherentPower, ...
        image.xGridM, image.yGridM, targets, metricConfig.valleyThresholdDb);
end
if isfield(image, 'coherentCfPower')
    metrics.methodPairs.coherentCf = mmw.metrics.pairProfiles(image.coherentCfPower, ...
        image.xGridM, image.yGridM, targets, metricConfig.valleyThresholdDb);
end

metrics.pslrDb = NaN;
if numel(targets) == 1
    targetXY = targets(1).positionM(1:2);
    [xMeshM, yMeshM] = meshgrid(image.xGridM, image.yGridM);
    exclusion = hypot(xMeshM-targetXY(1), yMeshM-targetXY(2)) <= ...
        metricConfig.singleTargetExclusionRadiusM;
    [~, targetX] = min(abs(image.xGridM - targetXY(1)));
    [~, targetY] = min(abs(image.yGridM - targetXY(2)));
    targetPower = image.coherentPower(targetY, targetX);
    falseImage = image.coherentPower;
    falseImage(exclusion) = -inf;
    falsePeak = max(falseImage(:));
    metrics.pslrDb = 10 * log10(falsePeak / max(targetPower, eps));
end
end
