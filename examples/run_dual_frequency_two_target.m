function result = run_dual_frequency_two_target(mode)
%RUN_DUAL_FREQUENCY_TWO_TARGET Run the 60/64 GHz two-target validation.
if nargin < 1, mode = "full"; end
result = run_experiment("dual_two_60_64", mode, true);
end
