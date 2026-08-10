function pathM = pathLength(radarPositionM, pointPositionM)
%PATHLENGTH Exact monostatic TX-target-RX path length.
%   RADARPOSITIONM is 1x3. POINTPOSITIONM may be 1x3 or Nx3.

if size(radarPositionM,2) ~= 3 || size(pointPositionM,2) ~= 3
    error('Positions must have three columns [x y z].');
end

delta = pointPositionM - radarPositionM;
oneWayM = sqrt(sum(delta.^2, 2));
pathM = 2 * oneWayM;
end
