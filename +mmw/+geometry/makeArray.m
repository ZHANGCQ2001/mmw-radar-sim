function array = makeArray(type, arrayConfig)
%MAKEARRAY Build a six-node uniform or Golomb array with equal aperture.

arguments
    type (1,1) string
    arrayConfig struct
end

type = lower(type);
numNodes = arrayConfig.numNodes;
apertureM = arrayConfig.apertureM;
xMinM = arrayConfig.centerXM - apertureM/2;
xMaxM = arrayConfig.centerXM + apertureM/2;

switch type
    case {"uniform", "uniform6"}
        xM = linspace(xMinM, xMaxM, numNodes);
        marks = linspace(0, 1, numNodes);
        canonicalType = "uniform";

    case {"golomb", "golomb6"}
        rawMarks = arrayConfig.golombMarks(:).';
        if numel(rawMarks) ~= numNodes
            error('Golomb mark count must equal cfg.array.numNodes.');
        end
        marks = (rawMarks - rawMarks(1)) / (rawMarks(end) - rawMarks(1));
        xM = xMinM + apertureM * marks;
        canonicalType = "golomb";

    otherwise
        error('Unknown array type: %s. Use "uniform" or "golomb".', type);
end

array.type = canonicalType;
array.numNodes = numNodes;
array.apertureM = apertureM;
array.xM = xM;
array.positionsM = [xM(:), ...
    repmat(arrayConfig.yM, numNodes, 1), ...
    repmat(arrayConfig.zM, numNodes, 1)];
array.normalizedMarks = marks;
array.baselinesM = positiveBaselines(xM);
array.numUniquePositiveBaselines = numel(unique(round(array.baselinesM, 12)));
end

function baselines = positiveBaselines(xM)
numNodes = numel(xM);
baselines = zeros(1, numNodes*(numNodes-1)/2);
index = 1;
for i = 1:numNodes-1
    for j = i+1:numNodes
        baselines(index) = xM(j) - xM(i);
        index = index + 1;
    end
end
end
