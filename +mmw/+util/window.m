function w = window(kind, count)
%WINDOW Return a dependency-free column window of COUNT samples.

arguments
    kind (1,1) string
    count (1,1) double {mustBeInteger, mustBePositive}
end
if count == 1
    w = 1;
    return;
end
n = (0:count-1).';
switch lower(kind)
    case "hamming"
        w = 0.54 - 0.46 * cos(2 * pi * n / (count - 1));
    case "hann"
        w = 0.5 - 0.5 * cos(2 * pi * n / (count - 1));
    case {"rectangular", "rect"}
        w = ones(count, 1);
    otherwise
        error('mmw:util:UnknownWindow', 'Unsupported window: %s', kind);
end
end
