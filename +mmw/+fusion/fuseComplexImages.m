function [fusedPower, fusedComplex, complexStackUsed] = ...
    fuseComplexImages(complexStack, mode)
%FUSECOMPLEXIMAGES Coherent fusion across carrier frequencies.
%
% mode:
%   "normalized" - normalize each carrier image before coherent sum
%   "raw"        - directly coherently sum carrier images

arguments
    complexStack
    mode (1,1) string = "normalized"
end

numCarriers = size(complexStack, 3);

switch lower(mode)

    case "normalized"

        % Normalize each carrier independently.
        complexStackUsed = ...
            complex(zeros(size(complexStack)));

        for k = 1:numCarriers

            Z = complexStack(:,:,k);

            scale = max(abs(Z), [], 'all');

            if scale <= 0
                error( ...
                    'Carrier %d has zero complex image amplitude.', ...
                    k);
            end

            complexStackUsed(:,:,k) = ...
                Z / scale;

        end

    case "raw"

        % No carrier-wise normalization.
        complexStackUsed = complexStack;

    otherwise

        error( ...
            'Unknown coherent fusion mode: %s', ...
            mode);

end

% Coherent complex summation across carriers.
fusedComplex = mean(complexStackUsed, 3);

% Convert to power only after coherent summation.
fusedPower = abs(fusedComplex).^2;

% Normalize final fused power image.
scale = max(fusedPower, [], 'all');

if scale > 0
    fusedPower = fusedPower / scale;
end

end