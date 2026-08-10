function image = coherentImage(cfg, array, rd)
%COHERENTIMAGE Near-field RD-IQ backprojection and coherent fusion.

xGridM = cfg.imaging.xLimM(1):cfg.imaging.gridStepM:cfg.imaging.xLimM(2);
yGridM = cfg.imaging.yLimM(1):cfg.imaging.gridStepM:cfg.imaging.yLimM(2);
numX = numel(xGridM);
numY = numel(yGridM);
numRadars = array.numNodes;

nodeComplex = complex(zeros(numY, numX, numRadars));
coherentComplex = complex(zeros(numY, numX));
noncoherentPower = zeros(numY, numX);

c = cfg.constants.cMps;
fc = cfg.waveform.fcHz;
S = cfg.waveform.slopeHzPerS;
velocityMps = cfg.imaging.velocityMps;

for yIndex = 1:numY
    for xIndex = 1:numX
        pointM = [xGridM(xIndex), yGridM(yIndex), cfg.imaging.zM];
        values = complex(zeros(1, numRadars));

        for radarIndex = 1:numRadars
            pathM = mmw.geometry.pathLength(array.positionsM(radarIndex,:), pointM);
            tauS = pathM / c;
            rangeM = pathM / 2;
            rdSlice = rd.iq(:,:,radarIndex);

            rdValue = interp2(rd.velocityAxisMps, rd.rangeAxisM, rdSlice, ...
                velocityMps, rangeM, 'linear', 0);

            constantPhaseRad = 2*pi*fc*tauS - pi*S*tauS^2;
            values(radarIndex) = rdValue * exp(-1j*constantPhaseRad);
            nodeComplex(yIndex, xIndex, radarIndex) = values(radarIndex);
        end

        coherentComplex(yIndex, xIndex) = sum(values);
        noncoherentPower(yIndex, xIndex) = sum(abs(values).^2);
    end
end

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
