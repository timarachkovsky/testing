% Inner control/SPM.m  v1.3
% 05-02-2016 
% Aslamov
% modified Kosmach
% 21-07-2016

function [dBc, dBm, zeroLvl, hR, lR] = SPM(File, config)
%% --------------------- Description --------------------
% algorithm: implementation is the amount specified in the signal peak, 
% and outputs the level at which the number of peaks to be necessary.

% SPM() method returns for first method "carpet" level (lowLevel), max level (highLevel) 
% and zero-level of the input signal and for second method low Rate of
% occurrence(LR), high Rate of occurrence(HR).
%% _____________________ Default Parametrs ____________________________ %%   
    if nargin < 2
        config = [];
        config.Attributes = [];
        config.spmDbmDdc = [];
        config.spmLrHr = [];
    end

    % filtration config
    config.Attributes = fill_struct(config.Attributes, 'Rp', '1');
    config.Attributes = fill_struct(config.Attributes, 'Rs', '10');
    config.Attributes = fill_struct(config.Attributes, 'highFreq', '20000');
    config.Attributes = fill_struct(config.Attributes, 'lowFreq', '500');
    config.Attributes = fill_struct(config.Attributes, 'filterType', 'HPF');

    config.Attributes = fill_struct(config.Attributes, 'spmLRHREnable', '1');
    config.Attributes = fill_struct(config.Attributes, 'spmDBcDBmEnable', '1');

    config.Attributes = fill_struct(config.Attributes, 'debugModeEnable','0');

    lowFrequency = str2double(config.Attributes.lowFreq);
    highFrequency = str2double(config.Attributes.highFreq);
    Rp = str2double(config.Attributes.Rp);
    Rs = str2double(config.Attributes.Rs);

    filterType = config.Attributes.filterType;
    %% ___________________________ Filtration_______________________________ %%
    switch(filterType)
        case 'BPF' % Band-Pass Filter
            Wp = [lowFrequency*2/File.Fs highFrequency*2/File.Fs];
            Ws=[(lowFrequency-0.1*lowFrequency)*2/File.Fs (highFrequency+0.1*highFrequency)*2/File.Fs]; 
        case 'LPF' % Low-Pass Filter
            Wp = highFrequency*2/File.Fs;
            Ws = (highFrequency+100)*2/File.Fs; 
        case 'HPF'
            Ws = highFrequency*2/File.Fs;
            Wp = (highFrequency*2)*2/File.Fs; 
    end

    [~,Wn1] = buttord(Wp,Ws,Rp,Rs);   
    [b1,a1] = butter(2 ,Wn1); 

    File.acceleration.signal = filtfilt(b1,a1,File.acceleration.signal');
    %% _____________________________ Calculation ____________________________%%
    File.acceleration.signal = abs(File.acceleration.signal);

    if(size(File.acceleration.signal,2)>size(File.acceleration.signal,1))
        File.acceleration.signal = File.acceleration.signal';
    end

    file.signal = File.acceleration.signal;
    file.Fs = File.Fs;
    configShortSignal.type = config.shortSignal.Attributes.type;
    configShortSignal.plotEnable = config.shortSignal.Attributes.plotEnable;
    configShortSignal.plotVisible = config.plotVisible;
    configShortSignal.multi = config.shortSignal.multi.Attributes;
    configShortSignal.mono = config.shortSignal.mono.Attributes;
    
    File.acceleration.signal = createShortSignal(file, configShortSignal)';

    if str2double(config.spmDBmDBcEnable)     
        parameters = config.spmDBmDBc.Attributes;
        parameters.plotVisible = config.plotVisible;
        parameters.debugModeEnable = config.debugModeEnable;
        parameters.parpoolEnable = config.parpoolEnable;
        [dBc, dBm, zeroLvl] = spmDBmDBc(File, parameters); 
    else
        dBc = [];
        dBm = [];
        zeroLvl = [];
    end

    if str2double(config.spmLRHREnable) 
        parameters = config.spmLRHR.Attributes;
        parameters.plotVisible = config.plotVisible;
        parameters.debugModeEnable = config.debugModeEnable;
        parameters.parpoolEnable = config.parpoolEnable;
        [hR, lR] = spmLRHR(File, parameters);
    else
        hR = [];
        lR = [];
    end
end