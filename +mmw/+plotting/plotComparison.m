function handles = plotComparison(study)
%PLOTCOMPARISON Compare uniform and Golomb results on the same scales.

cases = {study.uniform.single, study.golomb.single, ...
         study.uniform.two, study.golomb.two};
titles = {'Uniform - single', 'Golomb - single', ...
          'Uniform - two targets', 'Golomb - two targets'};

handles.imageFigure = figure('Name','Uniform vs Golomb coherent images');
tiledlayout(2,2,'Padding','compact','TileSpacing','compact');
for k = 1:4
    nexttile;
    r = cases{k};
    P = double(r.image.coherentPower);
    P = P / max(max(P(:)), eps);
    imagesc(r.image.xGridM, r.image.yGridM, 10*log10(P+eps));
    axis xy equal tight;
    clim([-r.config.plot.dynamicRangeDb,0]);
    title(titles{k});
    xlabel('x / m'); ylabel('y / m');
    hold on;
    truth = r.metrics.truthXYM;
    plot(truth(:,1),truth(:,2),'x','LineWidth',1.5,'MarkerSize',8);
end
colorbar;

handles.profileFigure = figure('Name','Uniform vs Golomb cross-range profiles');
tiledlayout(1,2,'Padding','compact','TileSpacing','compact');

nexttile;
plotPair(study.uniform.single, study.golomb.single, 'Single target');
nexttile;
plotPair(study.uniform.two, study.golomb.two, 'Two targets, 5 cm');
end

function plotPair(uniformResult, golombResult, plotTitle)
x = uniformResult.image.xGridM;
y = uniformResult.image.yGridM;
truth = uniformResult.metrics.truthXYM;
[~,iy] = min(abs(y-mean(truth(:,2))));

Pu = uniformResult.image.coherentPower;
Pg = golombResult.image.coherentPower;
pu = Pu(iy,:) / max(Pu(iy,:));
pg = Pg(iy,:) / max(Pg(iy,:));

plot(x,10*log10(pu+eps),'LineWidth',1.3); hold on;
plot(x,10*log10(pg+eps),'LineWidth',1.3);
grid on;
ylim([-uniformResult.config.plot.dynamicRangeDb,1]);
xlabel('x / m'); ylabel('Normalized power / dB');
title(plotTitle);
legend('Uniform','Golomb','Location','best');
for k = 1:size(truth,1)
    xline(truth(k,1),'--','HandleVisibility','off');
end
end
