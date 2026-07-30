function results = run_core_smoke_tests()
%RUN_CORE_SMOKE_TESTS Run fast checks for the four focused experiments.

startup();
projectRoot = mmw.util.projectRoot();
results = runtests(fullfile(projectRoot, 'tests', 'core'));
disp(results);

if any([results.Failed])
    error('mmw:test:CoreSmokeFailed', 'One or more core smoke tests failed.');
end
end
