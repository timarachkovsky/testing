classdef spectrogramEnv < spectrogram1
    %SPECTROGRAMENV Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        lowFrequencyEnvelope
        highFrequencyEnvelope
        Rp
        Rs
        filterType
        
    end
    
    methods
        
        function [mySpectrogram] = spectrogramEnv( config )
            
            if nargin == 0
               warning('There is no config structure for spectrogram initialization!')
               config = [];
            end
            
            mySpectrogram = mySpectrogram@spectrogram1( config );
            mySpectrogram.tag = 'NORM-env';
            
            
            config = fill_struct(config, 'Rp', '1');
            config = fill_struct(config, 'Rs', '10');
            config = fill_struct(config, 'filterType', 'BPF');
            config = fill_struct(config, 'lowFrequencyEnvelope', '500'); % envelopeSpectrum low Frequency [Hz]
            config = fill_struct(config, 'highFrequencyEnvelope', '5000'); % envelopeSpectrum high Frequency [Hz]
            
            % Envelope Signal Parameters
            mySpectrogram.lowFrequencyEnvelope = str2double(config.lowFrequencyEnvelope);
            mySpectrogram.highFrequencyEnvelope = str2double(config.highFrequencyEnvelope);
            mySpectrogram.Rp = str2double(config.Rp);
            mySpectrogram.Rs = str2double(config.Rs);
            mySpectrogram.filterType = config.filterType;

        end
        
        function [signalEnv] = prepareSignal(mySpectrogram, file)

            % INPUT:
            signal = file.signal;
            Fs = file.Fs;
            lowFrequency = mySpectrogram.lowFrequencyEnvelope;
            highFrequency = mySpectrogram.highFrequencyEnvelope;
            myRp = mySpectrogram.Rp;
            myRs = mySpectrogram.Rs;
            
            
            % CALCULATION:

            switch(mySpectrogram.filterType)
                case 'BPF' % Band-Pass Filter
                    Wp = [lowFrequency*2/Fs highFrequency*2/Fs];
                    Ws=[(lowFrequency-0.1*lowFrequency)*2/Fs (highFrequency+0.1*highFrequency)*2/Fs]; 
                case 'LPF'
                    % Low-Pass Filter
                    Wp = highFrequency*2/Fs;
                    Ws = (highFrequency+100)*2/Fs; 
                case 'HPF'
                    Ws = lowFrequency*2/Fs;
                    Wp = (lowFrequency*2)*2/Fs; 
            end

            [~,Wn1] = buttord(Wp,Ws,myRp,myRs);   
            [b1,a1] = butter(2 ,Wn1);
            
            % OUTPUT:
            signalEnv = filtfilt(b1,a1,signal);
            signalEnv = abs(hilbert(signalEnv));

        end
        
    end
    
end

