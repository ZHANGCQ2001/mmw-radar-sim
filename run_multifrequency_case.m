function study = run_multifrequency_case( ...
    arrayType, sceneType, carrierHz, ...
    doPlot, separationM, method)
%RUN_MULTIFREQUENCY_CASE Multi-frequency coherent imaging study.

arguments
    arrayType (1,1) string
    sceneType (1,1) string
    carrierHz (1,:) double
    doPlot (1,1) logical = true
    separationM (1,1) double = 0.05
    method (1,1) string = "geometric"
end

cfg = mmw.config.defaultConfig();

array = mmw.geometry.makeArray( ...
    arrayType, cfg.array);

scene = mmw.geometry.makeScene( ...
    sceneType, ...
    cfg.scene, ...
    separationM);

study = mmw.fusion.runCarrierSet( ...
    cfg, ...
    array, ...
    scene, ...
    carrierHz, ...
    method);

fprintf('\n=============================\n');
fprintf('MULTI-FREQUENCY RESULT\n');
fprintf('=============================\n');

fprintf('Array: %s\n', arrayType);

fprintf('Carriers / GHz: ');
fprintf('%.3f ', carrierHz/1e9);
fprintf('\n');

m = study.metrics;

if scene.type == "single"

    fprintf( ...
        'Localization error: %.2f mm\n', ...
        1000*m.localizationErrorM);

    fprintf( ...
        'PSLR: %.2f dB\n', ...
        m.pslrDb);

    fprintf( ...
        'ISLR: %.2f dB\n', ...
        m.islrDb);

else

    fprintf( ...
        'Coverage: %d/2\n', ...
        m.coverage);

    fprintf( ...
        'Valley depth: %.2f dB\n', ...
        m.valleyDepthDb);

    fprintf( ...
        'TFPR: %.2f dB\n', ...
        m.targetToFalsePeakDb);

    fprintf( ...
        'Pass: %d\n', ...
        m.pass);
end

if doPlot
    plotStudy(study);
end

end


function plotStudy(study)

numCarriers = numel(study.carrierHz);

% Total number of tiles:
% single-carrier images + fused image
numTiles = numCarriers + 1;

% Use at most 4 columns.
numCols = min(4, numTiles);
numRows = ceil(numTiles / numCols);

figure( ...
    'Name', ...
    'Multi-frequency coherent imaging', ...
    'Position', [100 100 1400 850]);

tiledlayout( ...
    numRows, ...
    numCols, ...
    'TileSpacing', 'compact', ...
    'Padding', 'compact');

x = study.fusedImage.xGridM;
y = study.fusedImage.yGridM;

dynamicRangeDb = ...
    study.config.plot.dynamicRangeDb;


%% Plot each single-carrier image

for k = 1:numCarriers

    nexttile;

    P = ...
        study.carrierResults{k}.image.coherentPower;

    P = P / max(P(:));

    imagesc( ...
        x, ...
        y, ...
        10*log10(P + eps));

    axis xy equal tight;

    clim([-dynamicRangeDb 0]);

    title(sprintf( ...
        '%.3f GHz', ...
        study.carrierHz(k) / 1e9));

    xlabel('x / m');
    ylabel('y / m');

end


%% Plot fused image

nexttile;

P = study.fusedImage.coherentPower;

P = P / max(P(:));

imagesc( ...
    x, ...
    y, ...
    10*log10(P + eps));

axis xy equal tight;

clim([-dynamicRangeDb 0]);

title(sprintf( ...
    'Fused: %s', ...
    study.fusionMethod));

xlabel('x / m');
ylabel('y / m');

colorbar;

end