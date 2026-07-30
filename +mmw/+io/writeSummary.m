function writeSummary(path, result)
%WRITESUMMARY Write a compact human-readable experiment and metric summary.

fileId = fopen(path, 'w', 'n', 'UTF-8');
assert(fileId >= 0, 'mmw:io:OpenFailed', 'Unable to open %s.', path);
cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>
cfg = result.config;
fprintf(fileId, '%s\n', cfg.description);
fprintf(fileId, '%s\n\n', repmat('=', 1, strlength(cfg.description)));
fprintf(fileId, 'Experiment ID: %s\n', cfg.id);
fprintf(fileId, 'Mode: %s\n', cfg.mode);
fprintf(fileId, 'Carriers GHz: %s\n', strjoin(string(cfg.waveform.carrierFrequenciesHz/1e9), ', '));
fprintf(fileId, 'Radars: %d, RX per radar: %d, targets: %d\n', ...
    numel(cfg.array.radars), size(cfg.array.rxLocalM, 1), numel(cfg.scene.targets));
fprintf(fileId, 'Noise std: %.6g, grid step: %.4f m\n', ...
    cfg.simulation.noiseStd, cfg.imaging.gridStepM);
fprintf(fileId, 'Oracle angle gate: %d', cfg.fusion.oracleAngleGate.enabled);
if cfg.fusion.oracleAngleGate.enabled
    fprintf(fileId, ', half width %.3f deg (ideal truth prior)', ...
        cfg.fusion.oracleAngleGate.halfWidthDeg);
end
fprintf(fileId, '\n\n');

for carrierIndex = 1:numel(result.metrics.perCarrier)
    if isfield(result.metrics.perCarrier(carrierIndex), 'rangeDoppler')
        metric = result.metrics.perCarrier(carrierIndex).rangeDoppler;
        fprintf(fileId, 'Carrier %d RD coherent peak: (%.4f, %.4f) m', carrierIndex, ...
            metric.globalPeak.positionM);
        if strlength(metric.globalPeak.nearestTargetName) > 0
            fprintf(fileId, ', nearest %s, error %.4f m', ...
                metric.globalPeak.nearestTargetName, metric.globalPeak.nearestTargetErrorM);
        end
        fprintf(fileId, '\n');
    end
end

if ~isempty(result.metrics.dualFrequency)
    metric = result.metrics.dualFrequency;
    fprintf(fileId, '\nDual-frequency peak: (%.4f, %.4f) m, nearest %s, error %.4f m\n', ...
        metric.globalPeak.positionM, metric.globalPeak.nearestTargetName, ...
        metric.globalPeak.nearestTargetErrorM);
    fprintf(fileId, 'Sidelobe-map correlation: %.4f\n', metric.sidelobeCorrelation);
    fprintf(fileId, 'Target coverage: %d/%d, all detected: %d\n', ...
        metric.coverage.numDetectedTargets, metric.coverage.numTargets, ...
        metric.coverage.allTargetsDetected);
    if ~metric.coverage.allTargetsDetected
        fprintf(fileId, 'Missing targets: %s\n', ...
            strjoin(metric.coverage.missingTargetNames, ', '));
    end
    for pairIndex = 1:numel(metric.pairs)
        pair = metric.pairs(pairIndex);
        fprintf(fileId, '%s-%s spacing %.4f m: dip %.2f dB, resolved=%d\n', ...
            pair.targetNames(1), pair.targetNames(2), pair.spacingM, ...
            pair.dipDb, pair.resolved);
    end
end
end
