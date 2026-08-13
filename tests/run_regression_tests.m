function run_regression_tests()
%RUN_REGRESSION_TESTS Run core project regression tests.

fprintf('\n');
fprintf('========================================\n');
fprintf('MMW-RADAR-SIM REGRESSION TESTS\n');
fprintf('========================================\n');


run_smoke_tests;

test_omp_two_target();

test_omp_four_target();


fprintf('\n');
fprintf('All regression tests passed.\n');

end