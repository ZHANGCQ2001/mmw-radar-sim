classdef TestConfiguration < matlab.unittest.TestCase
    methods (Test)
        function derivesCarrierQuantities(testCase)
            cfg = mmw.config.baseExperiment();
            waveform = mmw.config.deriveWaveform(cfg.waveform, 60e9);
            testCase.verifyEqual(waveform.wavelengthM, 299792458/60e9, ...
                'RelTol', 1e-14);
            testCase.verifyEqual(waveform.sampledBandwidthHz, 3.072e9, ...
                'RelTol', 1e-14);
            testCase.verifyEqual(waveform.rangeResolutionM, ...
                waveform.speedOfLightMps/(2*3.072e9), 'RelTol', 1e-14);
        end

        function rejectsInvalidCarrier(testCase)
            cfg = mmw.config.baseExperiment();
            cfg.waveform.carrierFrequenciesHz = -1;
            testCase.verifyError(@() mmw.config.validateExperiment(cfg), ...
                'mmw:config:PositiveFinite');
        end

        function catalogHasRequiredExperiments(testCase)
            ids = mmw.config.listExperiments().Id;
            testCase.verifyTrue(any(ids == "scene_b_calibration"));
            testCase.verifyTrue(any(ids == "dual_two_60_64"));
            testCase.verifyTrue(any(ids == "dual_four_60_64"));
            testCase.verifyGreaterThanOrEqual(numel(ids), 17);
        end
    end
end
