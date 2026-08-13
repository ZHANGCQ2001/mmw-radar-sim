function startup()
%STARTUP Add project folders to the MATLAB path.

root = ...
    fileparts(mfilename('fullpath'));

addpath(root);

addpath( ...
    fullfile(root, 'studies'));

addpath( ...
    fullfile(root, 'tests'));

addpath( ...
    fullfile(root, 'tests', 'validation'));

fprintf( ...
    'mmw-radar-sim ready: %s\n', ...
    root);

end