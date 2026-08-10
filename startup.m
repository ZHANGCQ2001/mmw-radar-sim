function startup()
%STARTUP Add the project root to the MATLAB path.
root = fileparts(mfilename('fullpath'));
addpath(root);
addpath(fullfile(root,'tests'));
fprintf('mmw-radar-sim ready: %s\n', root);
end
