function fused = dualFrequencyProduct(image0, image1)
%DUALFREQUENCYPRODUCT Multiply two independently normalized coherent power maps.

if ~isequal(image0.xGridM, image1.xGridM) || ~isequal(image0.yGridM, image1.yGridM)
    error('mmw:fusion:GridMismatch', 'Dual-frequency images require identical x-y grids.');
end
scale0 = max(image0.coherentPower(:));
scale1 = max(image1.coherentPower(:));
normalized0 = image0.coherentPower / max(scale0, eps);
normalized1 = image1.coherentPower / max(scale1, eps);
fused.method = "normalized dual-frequency coherent-power product";
fused.xGridM = image0.xGridM;
fused.yGridM = image0.yGridM;
fused.normalizedPower0 = normalized0;
fused.normalizedPower1 = normalized1;
fused.power = normalized0 .* normalized1;
fused.normalizationScales = [scale0, scale1];
end
