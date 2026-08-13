function result = runCarrierSet( ...
    cfgBase, array, scene, carrierHz, method)
%RUNCARRIERSET Run independent coherent images at multiple carriers.

arguments
    cfgBase struct
    array struct
    scene struct
    carrierHz (1,:) double {mustBePositive}
    method (1,1) string = "geometric"
end

numCarriers = numel(carrierHz);

carrierResults = cell(1, numCarriers);

powerStack = [];
complexStack = [];

%% Run each carrier independently

for k = 1:numCarriers

    cfg = cfgBase;

    % Only change carrier frequency.
    cfg.waveform.fcHz = carrierHz(k);

    fprintf( ...
        'Carrier %d/%d: %.3f GHz\n', ...
        k, ...
        numCarriers, ...
        carrierHz(k)/1e9);

    r = mmw.runSimulation( ...
        cfg, array, scene);

    carrierResults{k} = r;

    % Allocate stacks after first simulation.
    if isempty(powerStack)

        [numY, numX] = ...
            size(r.image.coherentPower);

        powerStack = zeros( ...
            numY, numX, numCarriers);

        complexStack = complex(zeros( ...
            numY, numX, numCarriers));

    end

    powerStack(:,:,k) = ...
        r.image.coherentPower;

    complexStack(:,:,k) = ...
        r.image.coherentComplex;

end


%% Multi-frequency fusion

switch lower(method)

    case {"geometric", "minimum", "mean"}

        [fusedPower, normalizedPowerStack] = ...
            mmw.fusion.fusePowerImages( ...
                powerStack, method);

        % Power-domain fusion has no fused complex image.
        fusedComplex = [];
        normalizedComplexStack = [];

    case {"coherent", "coherent-normalized"}
    
        [fusedPower, ...
         fusedComplex, ...
         normalizedComplexStack] = ...
            mmw.fusion.fuseComplexImages( ...
                complexStack, ...
                "normalized");
    
        normalizedPowerStack = [];
    
    case "coherent-raw"
    
        [fusedPower, ...
         fusedComplex, ...
         normalizedComplexStack] = ...
            mmw.fusion.fuseComplexImages( ...
                complexStack, ...
                "raw");
    
        normalizedPowerStack = [];

    otherwise

        error( ...
            'Unknown multi-frequency fusion method: %s', ...
            method);

end


%% Build fused image

% Reuse grid information from first carrier.
fusedImage = carrierResults{1}.image;

fusedImage.coherentPower = fusedPower;
fusedImage.coherentComplex = fusedComplex;

% Node-level quantities no longer correspond
% to a single carrier after frequency fusion.
fusedImage.nodeComplex = [];
fusedImage.nodePower = [];
fusedImage.noncoherentPower = [];

fusedImage.method = ...
    "multi-frequency " + method + " fusion";


%% Evaluate fused image

fusedMetrics = mmw.metrics.evaluateImage( ...
    cfgBase, ...
    scene, ...
    fusedImage);


%% Output

result.config = cfgBase;
result.array = array;
result.scene = scene;

result.carrierHz = carrierHz;
result.carrierResults = carrierResults;

result.powerStack = powerStack;
result.complexStack = complexStack;

result.normalizedPowerStack = ...
    normalizedPowerStack;

result.normalizedComplexStack = ...
    normalizedComplexStack;

result.fusedImage = fusedImage;
result.metrics = fusedMetrics;

result.fusionMethod = method;

end