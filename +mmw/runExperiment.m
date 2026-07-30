function result = runExperiment(config)
%RUNEXPERIMENT Execute a validated single- or dual-carrier experiment.

config = mmw.config.validateExperiment(config);
carriersHz = config.waveform.carrierFrequenciesHz;
acquisitionCells = cell(1, numel(carriersHz));
for carrierIndex = 1:numel(carriersHz)
    waveform = mmw.config.deriveWaveform(config.waveform, carriersHz(carrierIndex));
    [transmitSignal, fastTimeS] = mmw.signal.generateChirp(waveform);
    receive = mmw.signal.simulatePointTargets(config.scene, config.array, waveform, ...
        fastTimeS, config.simulation, config.simulation.randomSeed + carrierIndex - 1);
    processed = mmw.processing.formRangeDopplerCube(receive, transmitSignal, ...
        waveform, config.processing);

    acquisition.waveform = waveform;
    acquisition.transmitSignal = transmitSignal;
    acquisition.fastTimeS = fastTimeS;
    acquisition.receive = receive;
    acquisition.processed = processed;
    if config.imaging.enableTimeDomain
        acquisition.timeDomainImage = mmw.imaging.timeDomainMatchedFilter( ...
            config.scene, config.array, waveform, config.fusion, config.imaging, ...
            transmitSignal, fastTimeS, receive);
    end
    if config.imaging.enableRangeDoppler
        acquisition.rangeDopplerImage = mmw.imaging.fromRangeDoppler( ...
            config.scene, config.array, waveform, config.fusion, config.imaging, ...
            processed, receive);
    end
    acquisitionCells{carrierIndex} = acquisition;
end
acquisitions = [acquisitionCells{:}];

dualFrequency = struct([]);
if numel(acquisitions) == 2
    assert(isfield(acquisitions(1), 'rangeDopplerImage'), ...
        'mmw:run:DualNeedsImage', 'Dual-frequency fusion requires RD images.');
    dualFrequency = mmw.fusion.dualFrequencyProduct( ...
        acquisitions(1).rangeDopplerImage, acquisitions(2).rangeDopplerImage);
end

metrics = mmw.metrics.evaluateExperiment(config, acquisitions, dualFrequency);
manifest = makeManifest(config);
result.config = config;
result.acquisitions = acquisitions;
result.dualFrequency = dualFrequency;
result.metrics = metrics;
result.manifest = manifest;
result.outputDirectory = "";
if config.output.writeArtifacts
    result.outputDirectory = string(mmw.io.writeArtifacts(result));
end
end

function manifest = makeManifest(config)
manifest.experimentId = config.id;
manifest.mode = config.mode;
manifest.randomSeed = config.simulation.randomSeed;
manifest.createdUtc = string(datetime('now', 'TimeZone', 'UTC', ...
    'Format', 'yyyy-MM-dd''T''HH:mm:ssXXX'));
manifest.matlabRelease = string(version('-release'));
manifest.matlabVersion = string(version);
manifest.platform = string(computer);
manifest.schemaVersion = "radar-sim-v2/1";
end
