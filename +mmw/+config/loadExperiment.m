function cfg = loadExperiment(experimentId, mode)
%LOADEXPERIMENT Build and validate a named ExperimentConfig.
%   CFG = LOADEXPERIMENT(ID, MODE), with MODE "full" or "smoke".

if nargin < 2 || isempty(mode)
    mode = "full";
end
id = lower(string(experimentId));
mode = lower(string(mode));
cfg = mmw.config.baseExperiment();
cfg.id = id;

switch id
    case "single_6uniform"
        cfg = coreArrayCase(cfg, uniformXM(6), 1, "uniform");
    case "single_6golomb"
        cfg = coreArrayCase(cfg, golombXM([0, 1, 4, 10, 12, 17]), 1, "Golomb");
    case "two_5cm_6uniform"
        cfg = coreArrayCase(cfg, uniformXM(6), 2, "uniform");
    case "two_5cm_6golomb"
        cfg = coreArrayCase(cfg, golombXM([0, 1, 4, 10, 12, 17]), 2, "Golomb");
    case "scene_a_layout"
        cfg.description = "Scene A: wall-mounted layout, no targets";
        cfg.scene.targets = emptyTargets();
        lambda62 = cfg.waveform.speedOfLightMps / 62e9;
        cfg.array.rxLocalM = [(-1.5:1:1.5).' * 0.5 * lambda62, zeros(4, 2)];
        cfg.imaging.enableTimeDomain = false;
        cfg.imaging.enableRangeDoppler = false;
    case "scene_b_calibration"
        cfg.description = "Scene B: single-target coherent focusing";
    case {"range_1m", "range_10cm", "range_5cm"}
        spacingM = spacingForId(id);
        cfg.description = "Two-target range-resolution experiment";
        cfg.scene.targets = makeLateralOrRangeTargets([3.0, 3.0], 2, spacingM, "y");
        cfg.imaging.xLimM = [2.5, 3.5];
        marginM = max(0.2, spacingM / 2);
        cfg.imaging.yLimM = [3.0 - marginM, 3.0 + spacingM + marginM];
    case "lateral_2target_10cm_3radar"
        cfg.description = "Two lateral targets separated by 10 cm";
        cfg.scene.targets = makeLateralOrRangeTargets([3.0, 3.0], 2, 0.10, "x");
    case "lateral_3target_10cm_cross"
        cfg.description = "Three-target 10 cm cross experiment";
        cfg.scene.targets = makeTargets([3.0, 3.0, 1.2; 3.0, 3.1, 1.2; 3.1, 3.0, 1.2]);
        cfg.imaging.xLimM = [2.8, 3.3];
        cfg.imaging.yLimM = [2.8, 3.3];
    case "lateral_4target_5cm_5uniform"
        cfg = fourTargetCase(cfg, uniformXM(5));
    case "lateral_4target_5cm_5golomb"
        cfg = fourTargetCase(cfg, golombXM([0, 1, 4, 9, 11]));
    case "lateral_4target_5cm_6uniform"
        cfg = fourTargetCase(cfg, uniformXM(6));
    case "lateral_4target_5cm_6golomb"
        cfg = fourTargetCase(cfg, golombXM([0, 1, 4, 10, 12, 17]));
    case "oracle_4target_5cm_1deg"
        cfg = fourTargetCase(cfg, golombXM([0, 1, 4, 10, 12, 17]));
        cfg.fusion.oracleAngleGate.enabled = true;
        cfg.fusion.oracleAngleGate.halfWidthDeg = 1.0;
        cfg.description = "Ideal-truth four-target oracle angle gate, +/-1 degree";
    case "oracle_4target_5cm_0p25deg"
        cfg = fourTargetCase(cfg, golombXM([0, 1, 4, 10, 12, 17]));
        cfg.fusion.oracleAngleGate.enabled = true;
        cfg.fusion.oracleAngleGate.halfWidthDeg = 0.25;
        cfg.description = "Ideal-truth four-target oracle angle gate, +/-0.25 degree";
    case "dual_single_61p8_62p2"
        cfg = dualCase(cfg, [61.8e9, 62.2e9], 1);
    case "dual_two_61p8_62p2"
        cfg = dualCase(cfg, [61.8e9, 62.2e9], 2);
    case "dual_two_60_64"
        cfg = dualCase(cfg, [60e9, 64e9], 2);
    case "dual_four_60_64"
        cfg = dualCase(cfg, [60e9, 64e9], 4);
    otherwise
        available = strjoin(cellstr(mmw.config.listExperiments().Id), ', ');
        error('mmw:config:UnknownExperiment', ...
            'Unknown experiment "%s". Available: %s', id, available);
end

if mode == "smoke"
    cfg = applySmokeMode(cfg);
elseif mode ~= "full"
    error('mmw:config:InvalidMode', 'Mode must be "full" or "smoke".');
end
cfg.mode = mode;
cfg = mmw.config.validateExperiment(cfg);
end

function cfg = coreArrayCase(cfg, radarXM, numTargets, layoutName)
%COREARRAYCASE Configure the four focused six-node comparison experiments.
cfg.waveform.carrierFrequenciesHz = 62e9;
cfg.array.radars = makeRadars(radarXM);
cfg.scene.targets = makeLateralOrRangeTargets([3.0, 3.0], numTargets, 0.05, "x");
cfg.imaging.xLimM = [2.7, 3.3];
cfg.imaging.yLimM = [2.8, 3.2];
cfg.imaging.gridStepM = 0.0025;
cfg.imaging.enableTimeDomain = false;
cfg.imaging.enableRangeDoppler = true;
cfg.fusion.coherenceFactor.enabled = false;
cfg.fusion.oracleAngleGate.enabled = false;
cfg.simulation.noiseStd = 0.0;

if numTargets == 1
    targetText = "single target";
else
    targetText = "two lateral targets separated by 5 cm";
end
cfg.description = sprintf('Six-node %s array, %s, 62 GHz coherent imaging', ...
    char(layoutName), char(targetText));
end

function cfg = fourTargetCase(cfg, radarXM)
cfg.description = "Four lateral targets separated by 5 cm";
cfg.array.radars = makeRadars(radarXM);
cfg.scene.targets = makeLateralOrRangeTargets([3.0, 3.0], 4, 0.05, "x");
cfg.imaging.xLimM = [2.7, 3.3];
cfg.imaging.yLimM = [2.8, 3.2];
cfg.fusion.coherenceFactor.enabled = true;
end

function cfg = dualCase(cfg, carriersHz, numTargets)
cfg.waveform.carrierFrequenciesHz = carriersHz;
cfg.array.radars = makeRadars(golombXM([0, 1, 4, 10, 12, 17]));
cfg.scene.targets = makeLateralOrRangeTargets([3.0, 3.0], numTargets, 0.05, "x");
cfg.imaging.xLimM = [2.7, 3.3];
cfg.imaging.yLimM = [2.8, 3.2];
cfg.imaging.gridStepM = 0.0025;
cfg.imaging.enableTimeDomain = false;
cfg.fusion.coherenceFactor.enabled = false;
cfg.simulation.noiseStd = 0.0;
cfg.description = sprintf('%d-target dual-frequency experiment at %.1f/%.1f GHz', ...
    numTargets, carriersHz(1) / 1e9, carriersHz(2) / 1e9);
end

function cfg = applySmokeMode(cfg)
cfg.waveform.numAdcSamples = 64;
cfg.waveform.numChirps = 8;
cfg.processing.rangeFftSize = 128;
cfg.processing.dopplerFftSize = 16;
cfg.imaging.gridStepM = max(cfg.imaging.gridStepM, 0.025);
cfg.imaging.enableTimeDomain = false;
cfg.output.writeArtifacts = false;
cfg.output.exportFigures = false;
end

function spacingM = spacingForId(id)
switch id
    case "range_1m", spacingM = 1.0;
    case "range_10cm", spacingM = 0.10;
    otherwise, spacingM = 0.05;
end
end

function xM = uniformXM(count)
xM = linspace(1.5, 4.5, count);
end

function xM = golombXM(marks)
xM = 1.5 + marks / max(marks) * 3.0;
end

function radars = makeRadars(xM)
prototype = struct('name', "", 'positionM', [0, 0, 0], 'yawRad', 0.0);
radars = repmat(prototype, 1, numel(xM));
for idx = 1:numel(xM)
    radars(idx).name = "R" + idx;
    radars(idx).positionM = [xM(idx), 0.0, 1.2];
end
end

function targets = makeLateralOrRangeTargets(centerXY, count, spacingM, axisName)
offsets = ((0:count-1) - (count-1)/2) * spacingM;
positions = repmat([centerXY, 1.2], count, 1);
if axisName == "x"
    positions(:, 1) = centerXY(1) + offsets(:);
else
    positions(:, 2) = centerXY(2) + (0:count-1).' * spacingM;
end
targets = makeTargets(positions);
end

function targets = makeTargets(positions)
prototype = struct('name', "", 'positionM', [0, 0, 0], ...
    'velocityMps', [0, 0, 0], 'rcs', 1.0);
targets = repmat(prototype, 1, size(positions, 1));
for idx = 1:size(positions, 1)
    targets(idx).name = "T" + idx;
    targets(idx).positionM = positions(idx, :);
end
end

function targets = emptyTargets()
targets = struct('name', {}, 'positionM', {}, 'velocityMps', {}, 'rcs', {});
end
