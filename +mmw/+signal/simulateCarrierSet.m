function observation = simulateCarrierSet( ...
    cfgBase, array, scene, carrierHz)
%SIMULATECARRIERSET Generate multi-carrier FMCW IF observations.
%
% This function only simulates IF data.
% It does not perform RD processing, imaging, fusion, or evaluation.

arguments
    cfgBase struct
    array struct
    scene struct
    carrierHz (1,:) double {mustBePositive}
end


numCarriers = ...
    numel(carrierHz);


ifData = ...
    cell(1, numCarriers);

signalMeta = ...
    cell(1, numCarriers);


for k = 1:numCarriers

    cfgK = ...
        cfgBase;

    cfgK.waveform.fcHz = ...
        carrierHz(k);


    fprintf( ...
        'Carrier %d/%d: %.3f GHz\n', ...
        k, ...
        numCarriers, ...
        carrierHz(k) / 1e9);


    [ifData{k}, signalMeta{k}] = ...
        mmw.signal.simulateIF( ...
            cfgK, ...
            array, ...
            scene);

end


observation.config = ...
    cfgBase;

observation.array = ...
    array;

observation.scene = ...
    scene;

observation.carrierHz = ...
    carrierHz;

observation.ifData = ...
    ifData;

observation.signalMeta = ...
    signalMeta;

observation.dataOrder = ...
    "carrier cell of sample x chirp x radar";

end