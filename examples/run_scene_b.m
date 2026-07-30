function result = run_scene_b(mode)
%RUN_SCENE_B Run the single-target coherent-focusing calibration.
if nargin < 1, mode = "full"; end
result = run_experiment("scene_b_calibration", mode, true);
end
