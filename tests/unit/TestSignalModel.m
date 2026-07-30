classdef TestSignalModel < matlab.unittest.TestCase
    methods (Test)
        function exactFirstChirpPath(testCase)
            cfg = mmw.config.loadExperiment("scene_b_calibration", "smoke");
            cfg.array.radars = cfg.array.radars(2);
            waveform = mmw.config.deriveWaveform(cfg.waveform, 62e9);
            [~, fastTimeS] = mmw.signal.generateChirp(waveform);
            receive = mmw.signal.simulatePointTargets(cfg.scene, cfg.array, ...
                waveform, fastTimeS, cfg.simulation, 3);
            expectedM = 2 * norm([3,3,1.2] - [3,0,1.2]);
            testCase.verifyEqual(receive.firstChirpPathM(1,1,1), expectedM, ...
                'AbsTol', 1e-12);
        end

        function rangeAxisMatchesBeatMapping(testCase)
            cfg = mmw.config.loadExperiment("scene_b_calibration", "smoke");
            waveform = mmw.config.deriveWaveform(cfg.waveform, 62e9);
            [tx, fastTimeS] = mmw.signal.generateChirp(waveform);
            receive = mmw.signal.simulatePointTargets(cfg.scene, cfg.array, ...
                waveform, fastTimeS, cfg.simulation, 3);
            processed = mmw.processing.formRangeDopplerCube(receive, tx, ...
                waveform, cfg.processing);
            expected = processed.beatFrequencyHz * waveform.speedOfLightMps / ...
                (2*waveform.frequencySlopeHzPerS);
            testCase.verifyEqual(processed.rangeAxisM, expected, 'AbsTol', 1e-14);
            testCase.verifySize(processed.rangeDopplerIq, ...
                [cfg.processing.rangeFftSize/2+1, 1, 3, cfg.processing.dopplerFftSize]);
        end
    end
end
