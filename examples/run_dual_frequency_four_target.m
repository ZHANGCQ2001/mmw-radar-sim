function result = run_dual_frequency_four_target(mode)
%RUN_DUAL_FREQUENCY_FOUR_TARGET Run the 60/64 GHz four-target negative test.
if nargin < 1, mode = "full"; end
result = run_experiment("dual_four_60_64", mode, true);
end
