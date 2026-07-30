classdef TestEndToEnd < matlab.unittest.TestCase
    methods (Test)
        function sceneBFocusesAndIsRepeatable(testCase)
            cfg = mmw.config.loadExperiment("scene_b_calibration", "smoke");
            first = mmw.runExperiment(cfg);
            second = mmw.runExperiment(cfg);
            peak = first.metrics.perCarrier(1).rangeDoppler.globalPeak;
            testCase.verifyLessThanOrEqual(peak.nearestTargetErrorM, ...
                sqrt(2)*cfg.imaging.gridStepM + 1e-12);
            methodPeaks = first.metrics.perCarrier(1).rangeDoppler.methodPeaks;
            testCase.verifyLessThanOrEqual(methodPeaks.coherent.nearestTargetErrorM, ...
                methodPeaks.noncoherent.nearestTargetErrorM + cfg.imaging.gridStepM);
            testCase.verifyEqual(first.acquisitions(1).receive.signal, ...
                second.acquisitions(1).receive.signal);
            testCase.verifyEqual(first.acquisitions(1).rangeDopplerImage.coherentPower, ...
                second.acquisitions(1).rangeDopplerImage.coherentPower);
        end

        function dualCarrierSmokeRunsCompleteChain(testCase)
            cfg = mmw.config.loadExperiment("dual_two_60_64", "smoke");
            result = mmw.runExperiment(cfg);
            testCase.verifyEqual(numel(result.acquisitions), 2);
            testCase.verifyNotEmpty(result.dualFrequency);
            testCase.verifyEqual(result.metrics.dualFrequency.coverage.numTargets, 2);
            testCase.verifyTrue(all(isfinite(result.dualFrequency.power(:))));
        end

        function sceneAHasNoTruthDependency(testCase)
            cfg = mmw.config.loadExperiment("scene_a_layout", "smoke");
            result = mmw.runExperiment(cfg);
            testCase.verifyEmpty(cfg.scene.targets);
            testCase.verifyFalse(isfield(result.acquisitions, 'rangeDopplerImage'));
        end
    end
end
