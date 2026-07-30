function weights = oracleAngleWeights(pointM, radarTxM, targets, oracleConfig)
%ORACLEANGLEWEIGHTS Apply an explicitly truth-derived per-radar azimuth gate.
%   This ideal prior is for stress testing and is not a sensor angle estimate.

numRadars = size(radarTxM, 1);
weights = ones(1, numRadars);
if ~oracleConfig.enabled
    return;
end
targetM = reshape([targets.positionM], 3, []).';
for radarIndex = 1:numRadars
    radarM = radarTxM(radarIndex, :);
    pointAzimuthDeg = atan2d(pointM(1) - radarM(1), pointM(2) - radarM(2));
    targetAzimuthDeg = atan2d(targetM(:, 1) - radarM(1), targetM(:, 2) - radarM(2));
    differenceDeg = mod(pointAzimuthDeg - targetAzimuthDeg + 180, 360) - 180;
    if min(abs(differenceDeg)) > oracleConfig.halfWidthDeg
        weights(radarIndex) = 0.0;
    end
end
end
