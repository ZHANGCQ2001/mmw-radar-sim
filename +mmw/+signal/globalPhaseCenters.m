function geometry = globalPhaseCenters(arrayConfig)
%GLOBALPHASECENTERS Transform local TX/RX phase centres to world coordinates.

numRadars = numel(arrayConfig.radars);
numRx = size(arrayConfig.rxLocalM, 1);
geometry.txGlobalM = zeros(numRadars, 3);
geometry.rxGlobalM = zeros(numRx, 3, numRadars);
for radarIndex = 1:numRadars
    radar = arrayConfig.radars(radarIndex);
    yaw = radar.yawRad;
    rotation = [cos(yaw), -sin(yaw), 0; sin(yaw), cos(yaw), 0; 0, 0, 1];
    geometry.txGlobalM(radarIndex, :) = radar.positionM + ...
        (rotation * arrayConfig.txLocalM(1, :).').';
    geometry.rxGlobalM(:, :, radarIndex) = radar.positionM + ...
        arrayConfig.rxLocalM * rotation.';
end
end
