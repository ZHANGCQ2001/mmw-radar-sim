function result = pairProfiles(powerImage, xGridM, yGridM, targets, thresholdDb)
%PAIRPROFILES Evaluate every target-pair join-line profile and 3 dB valleys.

prototype = struct('targetIndices', [0, 0], 'targetNames', strings(1, 2), ...
    'spacingM', NaN, 'axisName', "", 'fixedAxisName', "", ...
    'fixedAxisValueM', NaN, 'axisGridM', [], 'profileDbNormalized', [], ...
    'targetAxisM', [NaN, NaN], 'targetPowerDbNormalized', [NaN, NaN], ...
    'valleyDbNormalized', NaN, 'dipDb', NaN, 'resolved', false);
result = repmat(prototype, 0, 1);
pairIndex = 0;
for indexA = 1:numel(targets)
    for indexB = indexA+1:numel(targets)
        pairIndex = pairIndex + 1;
        pair = prototype;
        pair.targetIndices = [indexA, indexB];
        pair.targetNames = string({targets(indexA).name, targets(indexB).name});
        positionsM = [targets(indexA).positionM(1:2); targets(indexB).positionM(1:2)];
        deltaM = positionsM(2, :) - positionsM(1, :);
        pair.spacingM = norm(deltaM);
        if abs(deltaM(1)) >= abs(deltaM(2))
            pair.axisName = "x";
            pair.fixedAxisName = "y";
            requestedFixedM = mean(positionsM(:, 2));
            [~, fixedIndex] = min(abs(yGridM - requestedFixedM));
            pair.fixedAxisValueM = yGridM(fixedIndex);
            pair.axisGridM = xGridM(:);
            profilePower = powerImage(fixedIndex, :).';
            targetAxisM = positionsM(:, 1);
        else
            pair.axisName = "y";
            pair.fixedAxisName = "x";
            requestedFixedM = mean(positionsM(:, 1));
            [~, fixedIndex] = min(abs(xGridM - requestedFixedM));
            pair.fixedAxisValueM = xGridM(fixedIndex);
            pair.axisGridM = yGridM(:);
            profilePower = powerImage(:, fixedIndex);
            targetAxisM = positionsM(:, 2);
        end
        profileDb = 10 * log10(profilePower + eps);
        pair.profileDbNormalized = profileDb - max(profileDb);
        [~, firstIndex] = min(abs(pair.axisGridM - targetAxisM(1)));
        [~, secondIndex] = min(abs(pair.axisGridM - targetAxisM(2)));
        pair.targetAxisM = [pair.axisGridM(firstIndex), pair.axisGridM(secondIndex)];
        pair.targetPowerDbNormalized = pair.profileDbNormalized([firstIndex, secondIndex]).';
        between = min(firstIndex, secondIndex):max(firstIndex, secondIndex);
        pair.valleyDbNormalized = min(pair.profileDbNormalized(between));
        pair.dipDb = min(pair.targetPowerDbNormalized) - pair.valleyDbNormalized;
        pair.resolved = pair.dipDb >= thresholdDb;
        result(pairIndex, 1) = pair;
    end
end
end
