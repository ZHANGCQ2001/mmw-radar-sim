clear;
close all;
clc;

startup;


%% ============================================================
% Configuration
% =============================================================

cfg = ...
    mmw.config.defaultConfig();


array = ...
    mmw.geometry.makeArray( ...
        "golomb", ...
        cfg.array);


carrierHz = ...
    (60:0.4:64) * 1e9;


maxTargets = 2;


%% ============================================================
% Build test scene
% =============================================================

sceneTwo = ...
    mmw.geometry.makeScene( ...
        "two", ...
        cfg.scene, ...
        0.05);


%% ============================================================
% Generate observed multi-target data
% =============================================================

fprintf('\n========================================\n');
fprintf('GENERATING TWO-TARGET OBSERVATION\n');
fprintf('========================================\n');


twoResult = ...
    mmw.fusion.runCarrierSet( ...
        cfg, ...
        array, ...
        sceneTwo, ...
        carrierHz, ...
        "coherent-normalized");


%% ============================================================
% Run OMP
% =============================================================

fprintf('\n========================================\n');
fprintf('RUNNING MULTI-CARRIER OMP\n');
fprintf('========================================\n');


ompResult = ...
    mmw.reconstruction.ompMultiCarrier( ...
        cfg, ...
        array, ...
        twoResult, ...
        maxTargets);


%% ============================================================
% Print OMP result
% =============================================================

fprintf('\n========================================\n');
fprintf('OMP RESULT\n');
fprintf('========================================\n');


for m = 1:ompResult.numTargets

    fprintf( ...
        '\nTarget %d\n', ...
        m);

    fprintf( ...
        'Position : (%.4f, %.4f, %.4f) m\n', ...
        ompResult.positionsM(m,1), ...
        ompResult.positionsM(m,2), ...
        ompResult.positionsM(m,3));

    fprintf( ...
        '|alpha|  : %.9f\n', ...
        abs(ompResult.alpha(m)));

    fprintf( ...
        'phase    : %.6f deg\n', ...
        rad2deg(angle(ompResult.alpha(m))));

end


fprintf('\n');

fprintf( ...
    'Maximum template coherence : %.6f\n', ...
    ompResult.maximumTemplateCoherence);

fprintf( ...
    'Gram condition number       : %.6f\n', ...
    ompResult.gramConditionNumber);

fprintf( ...
    'Final residual error        : %.3e\n', ...
    ompResult.finalResidualRelativeError);


%% ============================================================
% Show coefficient evolution
% =============================================================

fprintf('\n========================================\n');
fprintf('COEFFICIENT EVOLUTION\n');
fprintf('========================================\n');


for iteration = 1:maxTargets

    alphaIteration = ...
        ompResult.alphaHistory{iteration};

    fprintf( ...
        '\nAfter iteration %d:\n', ...
        iteration);

    for m = 1:numel(alphaIteration)

        fprintf( ...
            'Target %d: |alpha| = %.9f, phase = %.6f deg\n', ...
            m, ...
            abs(alphaIteration(m)), ...
            rad2deg(angle(alphaIteration(m))));

    end

end


%% ============================================================
% Truth comparison
%
% Truth is used ONLY here for evaluation.
% OMP itself does not use sceneTwo.
% =============================================================

truthPositionM = ...
    vertcat(sceneTwo.targets.positionM);


truthAlpha = ...
    complex(zeros(maxTargets,1));


for m = 1:maxTargets

    truthAlpha(m) = ...
        sqrt(sceneTwo.targets(m).rcsM2) * ...
        exp( ...
            1j * ...
            sceneTwo.targets(m).scatterPhaseRad);

end


%% Sort truth and detections by x coordinate

[truthPositionSorted, truthOrder] = ...
    sortrows( ...
        truthPositionM, ...
        1);

truthAlphaSorted = ...
    truthAlpha(truthOrder);


[detectedPositionSorted, detectedOrder] = ...
    sortrows( ...
        ompResult.positionsM, ...
        1);

detectedAlphaSorted = ...
    ompResult.alpha(detectedOrder);


%% Position errors

positionErrorM = ...
    vecnorm( ...
        detectedPositionSorted - ...
        truthPositionSorted, ...
        2, ...
        2);


%% Alpha errors

alphaError = ...
    detectedAlphaSorted - ...
    truthAlphaSorted;


fprintf('\n========================================\n');
fprintf('TRUTH COMPARISON\n');
fprintf('========================================\n');


for m = 1:maxTargets

    fprintf( ...
        '\nTarget %d\n', ...
        m);

    fprintf( ...
        'Position error : %.6f mm\n', ...
        1000 * positionErrorM(m));

    fprintf( ...
        'True alpha     : %.9f %+.9fj\n', ...
        real(truthAlphaSorted(m)), ...
        imag(truthAlphaSorted(m)));

    fprintf( ...
        'Estimated alpha: %.9f %+.9fj\n', ...
        real(detectedAlphaSorted(m)), ...
        imag(detectedAlphaSorted(m)));

    fprintf( ...
        'Alpha error    : %.3e\n', ...
        abs(alphaError(m)));

end


%% ============================================================
% Build Target-2-only reference
% =============================================================

scene2 = sceneTwo;

scene2.type = "single";

scene2.targets = ...
    sceneTwo.targets(2);


fprintf('\n========================================\n');
fprintf('GENERATING TARGET-2 REFERENCE\n');
fprintf('========================================\n');


target2Reference = ...
    mmw.fusion.runCarrierSet( ...
        cfg, ...
        array, ...
        scene2, ...
        carrierHz, ...
        "coherent-normalized");


%% ============================================================
% Compare recovered OMP component 2 with reference
% =============================================================

component2Image = ...
    ompResult.componentImages{2};


component2Error = ...
    norm( ...
        component2Image.coherentComplex(:) - ...
        target2Reference.fusedImage.coherentComplex(:)) / ...
    max( ...
        norm( ...
            target2Reference.fusedImage.coherentComplex(:)), ...
        eps);


fprintf('\n========================================\n');
fprintf('COMPONENT-2 COMPARISON\n');
fprintf('========================================\n');


fprintf( ...
    'OMP Target-2 image error : %.3e\n', ...
    component2Error);


%% ============================================================
% Plot
% =============================================================

x = ...
    twoResult.fusedImage.xGridM;

y = ...
    twoResult.fusedImage.yGridM;


Poriginal = ...
    twoResult.fusedImage.coherentPower;


Presidual1 = ...
    ompResult.detectionImages{2}.coherentPower;


Pcomponent2 = ...
    component2Image.coherentPower;


Preference2 = ...
    target2Reference.fusedImage.coherentPower;


%% Normalize independently

Poriginal = ...
    Poriginal / max(Poriginal(:));

Presidual1 = ...
    Presidual1 / max(Presidual1(:));

Pcomponent2 = ...
    Pcomponent2 / max(Pcomponent2(:));

Preference2 = ...
    Preference2 / max(Preference2(:));


dynamicRangeDb = ...
    cfg.plot.dynamicRangeDb;


figure( ...
    'Name', ...
    'Multi-carrier OMP validation', ...
    'Position', ...
    [50 150 1800 500]);


tiledlayout( ...
    1, ...
    4, ...
    'TileSpacing', ...
    'compact', ...
    'Padding', ...
    'compact');


%% Original image

nexttile;

imagesc( ...
    x, ...
    y, ...
    10*log10(Poriginal + eps));

axis xy equal tight;

clim([-dynamicRangeDb 0]);

xlabel('x / m');
ylabel('y / m');

title('Original two-target image');


%% Residual after first OMP iteration

nexttile;

imagesc( ...
    x, ...
    y, ...
    10*log10(Presidual1 + eps));

axis xy equal tight;

clim([-dynamicRangeDb 0]);

xlabel('x / m');
ylabel('y / m');

title('Residual after Target 1');


%% OMP reconstructed Target 2

nexttile;

imagesc( ...
    x, ...
    y, ...
    10*log10(Pcomponent2 + eps));

axis xy equal tight;

clim([-dynamicRangeDb 0]);

xlabel('x / m');
ylabel('y / m');

title('OMP reconstructed Target 2');


%% True Target 2

nexttile;

imagesc( ...
    x, ...
    y, ...
    10*log10(Preference2 + eps));

axis xy equal tight;

clim([-dynamicRangeDb 0]);

xlabel('x / m');
ylabel('y / m');

title('Target 2 only');

colorbar;


%% ============================================================
% Residual convergence
% =============================================================

figure( ...
    'Name', ...
    'OMP residual convergence');


semilogy( ...
    1:maxTargets, ...
    ompResult.residualRelativeErrorHistory, ...
    '-o', ...
    'LineWidth', ...
    1.5);


grid on;

xlabel('OMP iteration');

ylabel('Relative residual error');

title('OMP residual convergence');


%% ============================================================
% Final summary
% =============================================================

fprintf('\n========================================\n');
fprintf('OMP FINAL SUMMARY\n');
fprintf('========================================\n');


fprintf( ...
    'Target 1 detected : (%.4f, %.4f) m\n', ...
    ompResult.positionsM(1,1), ...
    ompResult.positionsM(1,2));

fprintf( ...
    'Target 2 detected : (%.4f, %.4f) m\n', ...
    ompResult.positionsM(2,1), ...
    ompResult.positionsM(2,2));


fprintf('\nFinal coefficients:\n');


for m = 1:maxTargets

    fprintf( ...
        'Target %d: |alpha| = %.9f, phase = %.6f deg\n', ...
        m, ...
        abs(ompResult.alpha(m)), ...
        rad2deg(angle(ompResult.alpha(m))));

end


fprintf('\n');

fprintf( ...
    'Maximum coherence  : %.6f\n', ...
    ompResult.maximumTemplateCoherence);

fprintf( ...
    'cond(G)            : %.6f\n', ...
    ompResult.gramConditionNumber);

fprintf( ...
    'Final residual     : %.3e\n', ...
    ompResult.finalResidualRelativeError);

fprintf( ...
    'Target-2 image err : %.3e\n', ...
    component2Error);