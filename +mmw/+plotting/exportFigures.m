function exportFigures(outputDirectory, result)
%EXPORTFIGURES Export reproducible geometry, image, and pair-profile PNG files.

plotLayout(fullfile(outputDirectory, 'layout.png'), result.config);
for carrierIndex = 1:numel(result.acquisitions)
    if isfield(result.acquisitions(carrierIndex), 'rangeDopplerImage')
        path = fullfile(outputDirectory, sprintf('carrier_%d_images.png', carrierIndex));
        plotImageTriplet(path, result.config, ...
            result.acquisitions(carrierIndex).rangeDopplerImage, ...
            result.acquisitions(carrierIndex).waveform.carrierFrequencyHz);
    end
end
if ~isempty(result.dualFrequency)
    plotDual(fullfile(outputDirectory, 'dual_frequency_images.png'), ...
        result.config, result.dualFrequency);
    plotPairs(fullfile(outputDirectory, 'dual_frequency_pair_profiles.png'), ...
        result.metrics.dualFrequency.pairs);
elseif ~isempty(result.metrics.perCarrier) && ...
        isfield(result.metrics.perCarrier(1), 'rangeDoppler')
    plotPairs(fullfile(outputDirectory, 'pair_profiles.png'), ...
        result.metrics.perCarrier(1).rangeDoppler.pairs);
end
end

function plotLayout(path, cfg)
figureHandle = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 850 620]);
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>
hold on;
radarM = reshape([cfg.array.radars.positionM], 3, []).';
plot(radarM(:,1), radarM(:,2), 'b^', 'MarkerFaceColor', 'b', 'DisplayName', 'Radars');
if ~isempty(cfg.scene.targets)
    targetM = reshape([cfg.scene.targets.positionM], 3, []).';
    plot(targetM(:,1), targetM(:,2), 'rx', 'LineWidth', 2, 'MarkerSize', 10, ...
        'DisplayName', 'Targets');
end
rectangle('Position', [0, 0, cfg.scene.roomSizeM(1), cfg.scene.roomSizeM(2)], ...
    'EdgeColor', [0.3 0.3 0.3]);
xlabel('x (m)'); ylabel('y (m)'); title(cfg.description, 'Interpreter', 'none');
axis equal; xlim([0 cfg.scene.roomSizeM(1)]); ylim([0 cfg.scene.roomSizeM(2)]);
grid on; legend('Location', 'best');
exportgraphics(figureHandle, path, 'Resolution', 160);
end

function plotImageTriplet(path, cfg, imageData, carrierHz)
figureHandle = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1450 450]);
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>
layout = tiledlayout(1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
powers = {imageData.singleRadarPower, imageData.noncoherentPower, imageData.coherentPower};
titles = {'Single radar', 'Non-coherent', 'Coherent'};
maxPower = max(cellfun(@(p) max(p(:)), powers));
for panel = 1:3
    nexttile;
    imagesc(imageData.xGridM, imageData.yGridM, 10*log10(powers{panel}/max(maxPower,eps)+eps));
    axis xy equal tight; clim([-40 0]); colorbar; hold on;
    plotTruth(cfg.scene.targets);
    title(titles{panel}); xlabel('x (m)'); ylabel('y (m)');
end
title(layout, sprintf('RD-IQ near-field images, %.1f GHz', carrierHz/1e9));
exportgraphics(figureHandle, path, 'Resolution', 160);
end

function plotDual(path, cfg, dual)
figureHandle = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1450 450]);
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>
layout = tiledlayout(1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
powers = {dual.normalizedPower0, dual.normalizedPower1, dual.power};
titles = {'Carrier 1', 'Carrier 2', 'Normalized product'};
for panel = 1:3
    nexttile;
    imagesc(dual.xGridM, dual.yGridM, 10*log10(powers{panel}+eps));
    axis xy equal tight; clim([-40 0]); colorbar; hold on; plotTruth(cfg.scene.targets);
    title(titles{panel}); xlabel('x (m)'); ylabel('y (m)');
end
title(layout, 'Independent-carrier coherent-power fusion');
exportgraphics(figureHandle, path, 'Resolution', 160);
end

function plotPairs(path, pairs)
if isempty(pairs)
    return;
end
figureHandle = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 900 280*max(1,numel(pairs))]);
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>
layout = tiledlayout(numel(pairs), 1, 'Padding', 'compact', 'TileSpacing', 'compact');
for pairIndex = 1:numel(pairs)
    pair = pairs(pairIndex);
    nexttile;
    plot(pair.axisGridM, pair.profileDbNormalized, 'LineWidth', 1.4); hold on;
    xline(pair.targetAxisM(1), '--'); xline(pair.targetAxisM(2), '--');
    yline(-3, ':'); grid on; ylim([-60 3]);
    xlabel(pair.axisName + " (m)"); ylabel('Normalized power (dB)');
    title(sprintf('%s-%s: dip %.2f dB, resolved=%d', ...
        pair.targetNames(1), pair.targetNames(2), pair.dipDb, pair.resolved));
end
title(layout, 'Target-pair profiles');
exportgraphics(figureHandle, path, 'Resolution', 160);
end

function plotTruth(targets)
if isempty(targets)
    return;
end
targetM = reshape([targets.positionM], 3, []).';
plot(targetM(:,1), targetM(:,2), 'wx', 'LineWidth', 1.5, 'MarkerSize', 8);
end
