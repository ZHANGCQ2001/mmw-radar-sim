classdef TestFusionAndMetrics < matlab.unittest.TestCase
    methods (Test)
        function multipliesNormalizedPower(testCase)
            image0.xGridM = [0, 1]; image0.yGridM = [0, 1];
            image1.xGridM = image0.xGridM; image1.yGridM = image0.yGridM;
            image0.coherentPower = [1, 2; 4, 8];
            image1.coherentPower = [8, 4; 2, 1];
            fused = mmw.fusion.dualFrequencyProduct(image0, image1);
            testCase.verifyEqual(max(fused.normalizedPower0(:)), 1);
            testCase.verifyEqual(max(fused.normalizedPower1(:)), 1);
            testCase.verifyEqual(fused.power, [1/8, 1/8; 1/8, 1/8], ...
                'AbsTol', 1e-14);
        end

        function rejectsMismatchedGrids(testCase)
            image0.xGridM = [0,1]; image0.yGridM = [0,1]; image0.coherentPower = ones(2);
            image1 = image0; image1.xGridM = [0,2];
            testCase.verifyError(@() mmw.fusion.dualFrequencyProduct(image0,image1), ...
                'mmw:fusion:GridMismatch');
        end

        function reportsUniqueCoverage(testCase)
            targets(1) = struct('name', "T1", 'positionM', [0,0,0], ...
                'velocityMps', [0,0,0], 'rcs', 1);
            targets(2) = struct('name', "T2", 'positionM', [1,0,0], ...
                'velocityMps', [0,0,0], 'rcs', 1);
            prototype = struct('positionM', [0,0], 'power', 1, ...
                'relativePowerDb', 0, 'nearestTargetName', "", 'nearestTargetErrorM', NaN);
            peaks = repmat(prototype, 2, 1);
            peaks(2).positionM = [0.05, 0];
            coverage = mmw.metrics.targetCoverage(peaks, targets, 0.1);
            testCase.verifyEqual(coverage.numDetectedTargets, 1);
            testCase.verifyFalse(coverage.allTargetsDetected);
            testCase.verifyEqual(coverage.missingTargetNames, "T2");
        end

        function computesValleyCriterion(testCase)
            targets(1) = struct('name', "T1", 'positionM', [0,0,0], ...
                'velocityMps', [0,0,0], 'rcs', 1);
            targets(2) = struct('name', "T2", 'positionM', [1,0,0], ...
                'velocityMps', [0,0,0], 'rcs', 1);
            x = 0:0.25:1; y = 0;
            power = [1, 0.1, 0.01, 0.1, 1];
            pairs = mmw.metrics.pairProfiles(power, x, y, targets, 3);
            testCase.verifyEqual(pairs.dipDb, 20, 'AbsTol', 1e-12);
            testCase.verifyTrue(pairs.resolved);
        end
    end
end
