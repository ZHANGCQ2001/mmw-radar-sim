classdef TestCoreExperiments < matlab.unittest.TestCase
    methods (Test)
        function catalogContainsFourFocusedCases(testCase)
            catalog = mmw.config.listCoreExperiments();
            expected = [
                "single_6uniform";
                "single_6golomb";
                "two_5cm_6uniform";
                "two_5cm_6golomb"
                ];
            testCase.verifyEqual(catalog.Id, expected);
        end

        function layoutsUseSixNodesAndEqualAperture(testCase)
            uniformCfg = mmw.config.loadExperiment("single_6uniform", "smoke");
            golombCfg = mmw.config.loadExperiment("single_6golomb", "smoke");

            uniformX = arrayfun(@(r) r.positionM(1), uniformCfg.array.radars);
            golombX = arrayfun(@(r) r.positionM(1), golombCfg.array.radars);

            testCase.verifyNumElements(uniformX, 6);
            testCase.verifyNumElements(golombX, 6);
            testCase.verifyEqual(max(uniformX) - min(uniformX), 3.0, 'AbsTol', 1e-12);
            testCase.verifyEqual(max(golombX) - min(golombX), 3.0, 'AbsTol', 1e-12);
        end

        function twoTargetSpacingIsFiveCentimetres(testCase)
            ids = ["two_5cm_6uniform", "two_5cm_6golomb"];
            for id = ids
                cfg = mmw.config.loadExperiment(id, "smoke");
                targetX = arrayfun(@(t) t.positionM(1), cfg.scene.targets);
                testCase.verifyEqual(diff(sort(targetX)), 0.05, 'AbsTol', 1e-12);
            end
        end

        function allCoreCasesRunInSmokeMode(testCase)
            catalog = mmw.config.listCoreExperiments();
            for idx = 1:height(catalog)
                result = run_experiment(catalog.Id(idx), "smoke", false);
                testCase.verifyNumElements(result.acquisitions, 1);
                testCase.verifyTrue(isfield(result.acquisitions, 'rangeDopplerImage'));
            end
        end
    end
end
