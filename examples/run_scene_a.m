function result = run_scene_a(mode)
%RUN_SCENE_A Run the wall-layout and noise-only chain check.
if nargin < 1, mode = "full"; end
result = run_experiment("scene_a_layout", mode, true);
end
