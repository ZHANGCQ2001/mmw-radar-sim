function results = run_all_smoke_tests()
%RUN_ALL_SMOKE_TESTS Run unit tests and compact end-to-end validations.

root = startup();
suite = testsuite(fullfile(root, 'tests'), 'IncludeSubfolders', true);
results = run(suite);
assertSuccess(results);
fprintf('All %d v2 tests passed.\n', numel(results));
end
