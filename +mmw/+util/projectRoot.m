function root = projectRoot()
%PROJECTROOT Return the absolute radar_sim_v2 project root.

pathHere = mfilename('fullpath');
root = fileparts(fileparts(fileparts(pathHere)));
end
