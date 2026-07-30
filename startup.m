function root = startup()
%STARTUP Add Radar Simulation v2 to the MATLAB path and return its root.

root = fileparts(mfilename('fullpath'));
addpath(root);
addpath(fullfile(root, 'examples'));
end
