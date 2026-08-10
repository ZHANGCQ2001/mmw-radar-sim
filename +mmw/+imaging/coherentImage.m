function image = coherentImage(cfg, array, rd)
%COHERENTIMAGE Near-field RD-IQ backprojection and coherent fusion.
%   The imaging grid is processed in vectorized form. Each radar performs
%   one batched interp2 call for the entire image instead of one interp2
%   call per image pixel.

xGridM = cfg.imaging.xLimM(1):cfg.imaging.gridStepM:cfg.imaging.xLimM(2);
yGridM = cfg.imaging.yLimM(1):cfg.imaging.gridStepM:cfg.imaging.yLimM(2);
numX = numel(xGridM);
numY = numel(yGridM);
numRadars = array.numNodes;

nodeComplex = complex(zeros(numY, numX, numRadars));

c = cfg.constants.cMps;
fc = cfg.waveform.fcHz;
S = cfg.waveform.slopeHzPerS;
velocityMps = cfg.imaging.velocityMps;

% Build the complete imaging grid once. pathLength already supports Nx3
% point inputs, so the propagation path can also be evaluated in one batch.
[xMeshM, yMeshM] = meshgrid(xGridM, yGridM);
numPixels = numel(xMeshM);
pointPositionsM = [xMeshM(:), yMeshM(:), ...
    repmat(cfg.imaging.zM, numPixels, 1)];

% The current imaging model uses one hypothesized velocity for the whole
% image. interp2 requires query arrays with matching dimensions, so create
% this matrix once and reuse it for all radar nodes.
velocityQueryMps = repmat(velocityMps, numY, numX);

for radarIndex = 1:numRadars
    % Exact monostatic near-field path for every image pixel at once.
    pathM = mmw.geometry.pathLength( ...
        array.positionsM(radarIndex,:), pointPositionsM);
    pathM = reshape(pathM, numY, numX);

    tauS = pathM / c;
    rangeM = pathM / 2;
    rdSlice = rd.iq(:,:,radarIndex);

    % One interpolation call per radar node instead of one per pixel.
    rdValue = interp2(rd.velocityAxisMps, rd.rangeAxisM, rdSlice, ...
        velocityQueryMps, rangeM, 'linear', 0);

    constantPhaseRad = 2*pi*fc*tauS - pi*S*tauS.^2;
    nodeComplex(:,:,radarIndex) = ...
        rdValue .* exp(-1j*constantPhaseRad);
end

coherentComplex = sum(nodeComplex, 3);
noncoherentPower = sum(abs(nodeComplex).^2, 3);

image.xGridM = xGridM;
image.yGridM = yGridM;
image.zM = cfg.imaging.zM;
image.nodeComplex = nodeComplex;
image.nodePower = abs(nodeComplex).^2;
image.coherentComplex = coherentComplex;
image.coherentPower = abs(coherentComplex).^2;
image.noncoherentPower = noncoherentPower;
image.method = "near-field complex RD-IQ backprojection";
end
