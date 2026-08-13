function metrics = evaluateImage(cfg, scene, image)
%EVALUATEIMAGE Evaluate localization, separation and false-peak behaviour.
%   This evaluator supports the current single-target and two-target study.

P = double(image.coherentPower);
P = P / max(max(P(:)), eps);
x = image.xGridM(:).';
y = image.yGridM(:);
[X,Y] = meshgrid(x,y);
truthXY = vertcat(scene.targets.positionM);
truthXY = truthXY(:,1:2);
numTargets = size(truthXY,1);

metrics.truthXYM = truthXY;
metrics.globalPeakPower = max(P(:));

switch numTargets
    case 1
        metrics = evaluateSingle(metrics, cfg, truthXY, P, x, y, X, Y);
    case 2
        metrics = evaluateTwo(metrics, cfg, truthXY, P, x, y, X, Y);
    otherwise
        metrics = evaluateMulti(metrics, cfg, truthXY, P, x, y, X, Y);
end
end

function metrics = evaluateSingle(metrics, cfg, truthXY, P, x, y, X, Y)
[peakPower, linearIndex] = max(P(:));
[iy, ix] = ind2sub(size(P), linearIndex);
estimatedXY = [x(ix), y(iy)];
errorM = norm(estimatedXY - truthXY);

profileX = P(iy,:);
profileY = P(:,ix).';
widthX = width3dB(x, profileX, ix);
widthY = width3dB(y.', profileY, iy);

mainMask = abs(X-truthXY(1)) <= cfg.metrics.targetExclusionXM & ...
           abs(Y-truthXY(2)) <= cfg.metrics.targetExclusionYM;
falseMask = ~mainMask;

Pfalse = P;
Pfalse(~falseMask) = -Inf;

[falsePeak, falseLinearIndex] = ...
    max(Pfalse(:));

[iyFalse, ixFalse] = ...
    ind2sub(size(Pfalse), falseLinearIndex);

falsePeakXY = ...
    [x(ixFalse), y(iyFalse)];
pslrDb = 10*log10((peakPower+eps)/(falsePeak+eps));
mainEnergy = sum(P(mainMask), 'all');
sideEnergy = sum(P(~mainMask), 'all');
islrDb = 10*log10((sideEnergy+eps)/(mainEnergy+eps));

metrics.estimatedXYM = estimatedXY;
metrics.localizationErrorM = errorM;
metrics.localized = errorM <= cfg.metrics.targetMatchRadiusM;
metrics.width3dBXM = widthX;
metrics.width3dBYM = widthY;
metrics.pslrDb = pslrDb;
metrics.islrDb = islrDb;
metrics.strongestFalsePeakPower = ...
    falsePeak;

metrics.strongestFalsePeakDb = ...
    10*log10(falsePeak + eps);

metrics.strongestFalsePeakXYM = ...
    falsePeakXY;
metrics.pass = metrics.localized;
end

function metrics = evaluateTwo(metrics, cfg, truthXY, P, x, y, X, Y)
[truthXY, order] = sortrows(truthXY,1); %#ok<ASGLU>
numTargets = 2;
estimatedXY = nan(numTargets,2);
peakPower = zeros(numTargets,1);
errorsM = inf(numTargets,1);

localMax = localMaximumMask(P);
for targetIndex = 1:numTargets
    dx = X - truthXY(targetIndex,1);
    dy = Y - truthXY(targetIndex,2);
    matchMask = hypot(dx,dy) <= cfg.metrics.targetMatchRadiusM & localMax;
    candidateIndices = find(matchMask);
    if ~isempty(candidateIndices)
        [peakPower(targetIndex), bestOffset] = max(P(candidateIndices));
        linearIndex = candidateIndices(bestOffset);
        [iy,ix] = ind2sub(size(P),linearIndex);
        estimatedXY(targetIndex,:) = [x(ix), y(iy)];
        errorsM(targetIndex) = norm(estimatedXY(targetIndex,:) - truthXY(targetIndex,:));
    end
end

matched = isfinite(errorsM) & errorsM <= cfg.metrics.targetMatchRadiusM;
coverage = sum(matched);

% Use the truth y-slice to evaluate the valley between the two target-related peaks.
truthY = mean(truthXY(:,2));
[~, profileYIndex] = min(abs(y-truthY));
profile = P(profileYIndex,:);
profilePeakIndices = zeros(1,2);
profilePeakPower = zeros(1,2);
for targetIndex = 1:2
    localMask = abs(x-truthXY(targetIndex,1)) <= cfg.metrics.targetMatchRadiusM;
    localIndices = find(localMask);
    [profilePeakPower(targetIndex), localOffset] = max(profile(localIndices));
    profilePeakIndices(targetIndex) = localIndices(localOffset);
end

profilePeakIndices = sort(profilePeakIndices);
leftIndex = profilePeakIndices(1);
rightIndex = profilePeakIndices(2);
valleyPower = min(profile(leftIndex:rightIndex));
valleyDepthDb = 10*log10((min(profilePeakPower)+eps)/(valleyPower+eps));

falseMask = true(size(P));
for targetIndex = 1:2
    targetRegion = abs(X-truthXY(targetIndex,1)) <= cfg.metrics.targetExclusionXM & ...
                   abs(Y-truthXY(targetIndex,2)) <= cfg.metrics.targetExclusionYM;
    falseMask(targetRegion) = false;
end
Pfalse = P;
Pfalse(~falseMask) = -Inf;

[strongestFalse, falseLinearIndex] = ...
    max(Pfalse(:));

[iyFalse, ixFalse] = ...
    ind2sub(size(Pfalse), falseLinearIndex);

strongestFalseXY = ...
    [x(ixFalse), y(iyFalse)];
targetToFalsePeakDb = 10*log10((min(peakPower)+eps)/(strongestFalse+eps));

separated = coverage == 2 && valleyDepthDb >= cfg.metrics.valleyThresholdDb;
falsePeakControlled = coverage == 2 && ...
    targetToFalsePeakDb >= cfg.metrics.falsePeakThresholdDb;

metrics.estimatedXYM = estimatedXY;
metrics.localizationErrorM = errorsM;
metrics.matched = matched;
metrics.coverage = coverage;
metrics.coverageFraction = coverage/2;
metrics.profileYIndex = profileYIndex;
metrics.profilePeakXM = x(profilePeakIndices).';
metrics.valleyDepthDb = valleyDepthDb;

metrics.targetPeakPower = peakPower;
metrics.targetPeakDb = ...
    10*log10(peakPower + eps);

metrics.strongestFalsePeakPower = ...
    strongestFalse;

metrics.strongestFalsePeakDb = ...
    10*log10(strongestFalse + eps);

metrics.strongestFalsePeakXYM = ...
    strongestFalseXY;

metrics.targetToFalsePeakDb = ...
    targetToFalsePeakDb;
metrics.separated = separated;
metrics.falsePeakControlled = falsePeakControlled;
metrics.pass = separated && falsePeakControlled;
end
function metrics = evaluateMulti( ...
    metrics, cfg, truthXY, P, x, y, X, Y)
%EVALUATEMULTI Generic evaluation for three or more targets.

numTargets = ...
    size(truthXY, 1);

estimatedXY = ...
    nan(numTargets, 2);

peakPower = ...
    zeros(numTargets, 1);

errorsM = ...
    inf(numTargets, 1);


%% Find spatial local maxima

localMax = ...
    localMaximumMask(P);


%% Match one local peak around each truth position

for targetIndex = 1:numTargets

    dx = ...
        X - truthXY(targetIndex,1);

    dy = ...
        Y - truthXY(targetIndex,2);


    matchMask = ...
        hypot(dx,dy) <= ...
        cfg.metrics.targetMatchRadiusM & ...
        localMax;


    candidateIndices = ...
        find(matchMask);


    if ~isempty(candidateIndices)

        [peakPower(targetIndex), bestOffset] = ...
            max(P(candidateIndices));

        linearIndex = ...
            candidateIndices(bestOffset);

        [iy, ix] = ...
            ind2sub( ...
                size(P), ...
                linearIndex);


        estimatedXY(targetIndex,:) = ...
            [x(ix), y(iy)];


        errorsM(targetIndex) = ...
            norm( ...
                estimatedXY(targetIndex,:) - ...
                truthXY(targetIndex,:));

    end

end


%% Coverage

matched = ...
    isfinite(errorsM) & ...
    errorsM <= cfg.metrics.targetMatchRadiusM;

coverage = ...
    sum(matched);


%% Exclude all true-target regions when finding false peaks

falseMask = ...
    true(size(P));


for targetIndex = 1:numTargets

    targetRegion = ...
        abs(X-truthXY(targetIndex,1)) <= ...
            cfg.metrics.targetExclusionXM & ...
        abs(Y-truthXY(targetIndex,2)) <= ...
            cfg.metrics.targetExclusionYM;

    falseMask(targetRegion) = false;

end


if any(falseMask(:))

    strongestFalse = ...
        max(P(falseMask), [], 'all');

else

    strongestFalse = 0;

end


%% Weakest detected target relative to strongest false peak

if coverage > 0

    weakestDetectedPeak = ...
        min(peakPower(matched));

    targetToFalsePeakDb = ...
        10*log10( ...
            (weakestDetectedPeak + eps) / ...
            (strongestFalse + eps));

else

    targetToFalsePeakDb = -Inf;

end


%% Output

metrics.estimatedXYM = ...
    estimatedXY;

metrics.localizationErrorM = ...
    errorsM;

metrics.matched = ...
    matched;

metrics.coverage = ...
    coverage;

metrics.coverageFraction = ...
    coverage / numTargets;

metrics.strongestFalsePeakDb = ...
    10*log10(strongestFalse + eps);

metrics.targetToFalsePeakDb = ...
    targetToFalsePeakDb;

metrics.pass = ...
    coverage == numTargets;

end
function mask = localMaximumMask(P)
[numY,numX] = size(P);
mask = false(numY,numX);
for iy = 2:numY-1
    for ix = 2:numX-1
        neighborhood = P(iy-1:iy+1,ix-1:ix+1);
        center = neighborhood(2,2);
        neighbors = neighborhood(:);
        neighbors(5) = [];
        mask(iy,ix) = all(center >= neighbors) && any(center > neighbors);
    end
end
end

function widthM = width3dB(axisM, profile, peakIndex)
threshold = profile(peakIndex) / 2;
left = peakIndex;
right = peakIndex;
while left > 1 && profile(left-1) >= threshold
    left = left - 1;
end
while right < numel(profile) && profile(right+1) >= threshold
    right = right + 1;
end
if left == right
    if numel(axisM) > 1
        widthM = median(diff(axisM));
    else
        widthM = 0;
    end
else
    widthM = axisM(right) - axisM(left);
end
end
