function [ File ] = envFiltering( File, Config )
%ENVFILTERING Summary of this function goes here


% INPUT:
    Config = fill_struct(Config, 'Rp', '1');
    Config = fill_struct(Config, 'Rs', '10');
    Config = fill_struct(Config, 'filterType', 'BPF');
    Config = fill_struct(Config, 'lowFrequencyEnvelope', '500'); % envelopeSpectrum low Frequency [Hz]
    Config = fill_struct(Config, 'highFrequencyEnvelope', '5000'); % envelopeSpectrum high Frequency [Hz]

    % Envelope Signal Parameters
    lowFrequencyEnvelope = str2double(Config.lowFrequencyEnvelope);
    highFrequencyEnvelope = str2double(Config.highFrequencyEnvelope);
    Rp = str2double(Config.Rp);
    Rs = str2double(Config.Rs);

    filterType = Config.filterType;
    
    signal = File.acceleration.signal;
    Fs = File.Fs;
    
% CALCULATION:

switch(filterType)
    case 'BPF' % Band-Pass Filter
        Wp = [lowFrequencyEnvelope*2/Fs highFrequencyEnvelope*2/Fs];
        Ws=[(lowFrequencyEnvelope-0.1*lowFrequencyEnvelope)*2/Fs (highFrequencyEnvelope+0.1*highFrequencyEnvelope)*2/Fs]; 
    case 'LPF'
        % Low-Pass Filter
        Wp = highFrequencyEnvelope*2/Fs;
        Ws = (highFrequencyEnvelope+100)*2/Fs; 
    case 'HPF'
        Ws = lowFrequencyEnvelope*2/Fs;
        Wp = (lowFrequencyEnvelope*2)*2/Fs; 
end

[~,Wn1] = buttord(Wp,Ws,Rp,Rs);   
[b1,a1] = butter(2 ,Wn1);

filteredSignal = filtfilt(b1,a1,signal);
filteredSignal = abs(hilbert(filteredSignal));

% END:

    File.acceleration.signal = filteredSignal;

