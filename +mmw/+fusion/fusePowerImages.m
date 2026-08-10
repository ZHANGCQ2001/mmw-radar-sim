function [fusedPower, normalizedStack] = ...
    fusePowerImages(powerStack, method)
%FUSEPOWERIMAGES Fuse independently formed carrier power images.
%
% powerStack:
%   Ny x Nx x K
%
% method:
%   "geometric"  recommended baseline
%   "minimum"    strict cross-frequency consensus
%   "mean"       arithmetic-mean reference

arguments
    powerStack double
    method (1,1) string = "geometric"
end

powerStack = max(powerStack, 0);

numCarriers = size(powerStack, 3);

normalizedStack = zeros(size(powerStack));

for k = 1:numCarriers

    P = powerStack(:,:,k);

    scale = max(P, [], 'all');

    if scale <= 0
        error('Carrier %d has zero image power.', k);
    end

    normalizedStack(:,:,k) = P / scale;
end

switch lower(method)

    case "geometric"

        fusedPower = exp( ...
            mean(log(normalizedStack + eps), 3));

    case "minimum"

        fusedPower = min(normalizedStack, [], 3);

    case "mean"

        fusedPower = mean(normalizedStack, 3);

    otherwise

        error( ...
            'Unknown fusion method: %s', ...
            method);
end

fusedPower = fusedPower / ...
    max(fusedPower, [], 'all');

end