function handles = plotResult(result)
%PLOTRESULT Plot coherent image and the target-y cross-range profile.

P = double(result.image.coherentPower);
P = P / max(max(P(:)), eps);
Pdb = 10*log10(P + eps);
x = result.image.xGridM;
y = result.image.yGridM;
truthXY = result.metrics.truthXYM;

handles.imageFigure = figure('Name', result.array.type + " - " + result.scene.type);
imagesc(x, y, Pdb);
axis xy equal tight;
colorbar;
clim([-result.config.plot.dynamicRangeDb, 0]);
xlabel('x / m');
ylabel('y / m');
title(sprintf('%s array - %s target scene', result.array.type, result.scene.type));
hold on;
plot(truthXY(:,1), truthXY(:,2), 'x', 'LineWidth', 2, 'MarkerSize', 10);
if isfield(result.metrics,'estimatedXYM')
    estimate = result.metrics.estimatedXYM;
    valid = all(isfinite(estimate),2);
    plot(estimate(valid,1), estimate(valid,2), 'o', 'LineWidth', 1.5, 'MarkerSize', 9);
end

truthY = mean(truthXY(:,2));
[~,iy] = min(abs(y-truthY));
profile = P(iy,:);
profileDb = 10*log10(profile/max(profile) + eps);

handles.profileFigure = figure('Name', result.array.type + " profile");
plot(x, profileDb, 'LineWidth', 1.3);
grid on;
ylim([-result.config.plot.dynamicRangeDb, 1]);
xlabel('x / m');
ylabel('Normalized power / dB');
title(sprintf('%s array, y = %.3f m', result.array.type, y(iy)));
hold on;
for k = 1:size(truthXY,1)
    xline(truthXY(k,1), '--');
end
end
