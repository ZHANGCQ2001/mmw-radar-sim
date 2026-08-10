function run_smoke_tests()
%RUN_SMOKE_TESTS Fast structural and numerical checks.

cfg = mmw.config.defaultConfig();
uniform = mmw.geometry.makeArray("uniform", cfg.array);
golomb = mmw.geometry.makeArray("golomb", cfg.array);

assert(uniform.numNodes == 6);
assert(golomb.numNodes == 6);
assert(abs(uniform.apertureM - golomb.apertureM) < 1e-12);
assert(max(abs(diff(diff(uniform.xM)))) < 1e-12);
assert(golomb.numUniquePositiveBaselines == 15);

scene = mmw.geometry.makeScene("two", cfg.scene, 0.05);
truth = vertcat(scene.targets.positionM);
assert(abs(norm(truth(2,:) - truth(1,:)) - 0.05) < 1e-12);

% Coarse grid only checks that the full numerical chain runs.
cfg.imaging.xLimM = [2.9, 3.1];
cfg.imaging.yLimM = [2.9, 3.1];
cfg.imaging.gridStepM = 0.025;
cfg.waveform.numChirps = 16;
cfg.processing.dopplerFftSize = 32;

single = mmw.geometry.makeScene("single", cfg.scene);
result = mmw.runSimulation(cfg, uniform, single);
assert(all(isfinite(result.image.coherentPower(:))));
assert(max(result.image.coherentPower(:)) > 0);
assert(size(result.ifData,3) == 6);

fprintf('All smoke tests passed.\n');
end
