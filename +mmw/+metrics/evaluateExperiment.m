function metrics = evaluateExperiment(config, acquisitions, dualFrequency)
%EVALUATEEXPERIMENT Evaluate all carrier images and optional dual product.

metrics.perCarrier = struct([]);
for carrierIndex = 1:numel(acquisitions)
    if isfield(acquisitions(carrierIndex), 'rangeDopplerImage')
        metrics.perCarrier(carrierIndex).rangeDoppler = mmw.metrics.evaluateImage( ...
            acquisitions(carrierIndex).rangeDopplerImage, config.scene.targets, config.metrics);
    end
    if isfield(acquisitions(carrierIndex), 'timeDomainImage')
        metrics.perCarrier(carrierIndex).timeDomain = mmw.metrics.evaluateImage( ...
            acquisitions(carrierIndex).timeDomainImage, config.scene.targets, config.metrics);
    end
end

metrics.dualFrequency = struct([]);
if ~isempty(dualFrequency)
    image.coherentPower = dualFrequency.power;
    image.xGridM = dualFrequency.xGridM;
    image.yGridM = dualFrequency.yGridM;
    metrics.dualFrequency = mmw.metrics.evaluateImage(image, config.scene.targets, config.metrics);
    targetMask = false(size(dualFrequency.power));
    [xMeshM, yMeshM] = meshgrid(dualFrequency.xGridM, dualFrequency.yGridM);
    for targetIndex = 1:numel(config.scene.targets)
        targetXY = config.scene.targets(targetIndex).positionM(1:2);
        targetMask = targetMask | hypot(xMeshM-targetXY(1), yMeshM-targetXY(2)) <= ...
            config.metrics.targetMatchRadiusM;
    end
    side0 = dualFrequency.normalizedPower0(~targetMask);
    side1 = dualFrequency.normalizedPower1(~targetMask);
    if numel(side0) >= 2 && std(side0) > 0 && std(side1) > 0
        correlation = corrcoef(side0, side1);
        metrics.dualFrequency.sidelobeCorrelation = correlation(1, 2);
    else
        metrics.dualFrequency.sidelobeCorrelation = NaN;
    end
end
end
