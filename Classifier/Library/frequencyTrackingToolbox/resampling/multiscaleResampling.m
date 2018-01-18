function [ File ] = multiscaleResampling( File, TrackingResult, config , signalTag)
%MULTISCALERESAMPLING Summary of this function goes here
%   Detailed explanation goes here

    if nargin == 2
        config = []; 
        signalTag = 'acc';
    elseif nargin == 3
        signalTag = 'acc';
    elseif nargin < 2
        error('Not enough input arguments!');
    end

% INPUT:
    

   
    % Default Parameters 
    config = fill_struct(config, 'plotEnable', '0');    
    config = fill_struct(config, 'debugModeEnable', '0');
    config = fill_struct(config, 'plotVisible','off');
    
    config = fill_struct(config, 'Rp', '1');
    config = fill_struct(config, 'Rs', '10');
    config = fill_struct(config, 'filterType', 'BPF');
    config = fill_struct(config, 'lowFreq', '500'); % envelopeSpectrum low Frequency [Hz]
    config = fill_struct(config, 'highFreq', '5000'); % envelopeSpectrum high Frequency [Hz]
    
    config = fill_struct(config, 'secPerFrame', '5');
    config = fill_struct(config, 'secOverlap', '4.5');
    
    plotEnable = str2double(config.plotEnable);
    debugModeEnable = str2double(config.debugModeEnable);
    plotVisible = config.plotVisible;
    secPerFrame = str2double(config.secPerFrame);
    secOverlap = str2double(config.secOverlap);
    
    % Plot parameters
    plots = config.plots;
    sizeUnits = plots.sizeUnits;
    imageSize = str2num(plots.imageSize);
    fontSize = str2double(plots.fontSize);
    imageFormat = plots.imageFormat;
    imageQuality = plots.imageQuality;
    imageResolution = plots.imageResolution;
    
    
    switch(signalTag)
        case 'acc'
            signal = File.acceleration.signal;
        case 'env'
            signal = getEnvelopeSignal(File, config);
        otherwise
            signal = File.acceleration.signal;
    end
    
    Fs = File.Fs;
    shift = TrackingResult.shift;
    shift = shift/100 + 1;
% CALCULATION:    
    % Decimal to fraction conversion
    shift = round(shift,4);
    [P,Q] = rat(shift);
   
    frameLength = Fs*(secPerFrame - secOverlap);
    
    startPos = TrackingResult.time(1)*Fs-floor(frameLength/2);
    endPos = TrackingResult.time(end)*Fs+floor(frameLength/2)-1;
    signal = signal(startPos:endPos,1);
    
    signalLength = length(signal);
    frameNumber = floor(signalLength/frameLength);
    
    residueLength = signalLength - frameLength*frameNumber;
    if residueLength > 0 
        residue = signal(frameLength*frameNumber+1:end,1);
    else
        residue = [];
    end
    
    % Resampling of signal parts
    signal = signal(1:frameLength*frameNumber,1);
    frameTable = reshape(signal, frameLength, [])';
    frameTable = frameTable(1:length(shift),:);
    frameCellTable = mat2cell(frameTable, ones(size(frameTable,1),1), size(frameTable,2));
    
    frameTableResampled = arrayfun(@(x,y,z) resample(x{:},y,z), frameCellTable, P, Q, 'UniformOutput', false);
    signalResampled = cell2mat(frameTableResampled')';
      
% OUTPUT :
        
    switch(signalTag)
        case 'acc'
            File.acceleration.signalResampled = signalResampled;   
        case 'env'
            File.envelope.signalResampled = signalResampled;   
        otherwise
            File.acceleration.signalResampled = signalResampled;  
    end
     
    
    
    % Secondary Channel ... for devices with 2 and more channels
    if isfield(File.acceleration, 'secondarySignal') && strcmp(signalTag, 'acc')
        if ~isempty(File.acceleration.secondarySignal)
            secondarySignal = File.acceleration.secondarySignal;
            
            secondarySignal = secondarySignal(startPos:endPos,1);
            secondarySignal = secondarySignal(1:frameLength*frameNumber,1);
            
            frameTable = reshape(secondarySignal, frameLength, [])';
            frameTable = frameTable(1:length(shift),:);
            frameCellTable = mat2cell(frameTable, ones(size(frameTable,1),1), size(frameTable,2));

            frameTableResampled = arrayfun(@(x,y,z) resample(x{:},y,z), frameCellTable, P, Q, 'UniformOutput', false);
            secondarySignalResampled = cell2mat(frameTableResampled')';
            
        % OUTPUT :
            File.acceleration.secondarySignalResampled = secondarySignalResampled;  
       end
    end

    
%     save('before.mat');
    
    %% _______________________ Plot Results ___________________________ %%
    
    if plotEnable && debugModeEnable
        
    % Time domain    
        dt = 1/Fs;
        t = 0:dt:dt*(length(signal)-1);
        tResampled = 0:dt:dt*(length(signalResampled)-1);

%         figure('Color','w','Visible', plotVisible);
        myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
        plot(t,signal);
        hold on, plot(tResampled, signalResampled);
        xlabel('Time, sec');
        ylabel('Amplitude, m/s^2');
        title([signalTag,' Waveform. Signal Resampling']);
        grid on;
        legend('original','resampled');
        myAxes = myFigure.CurrentAxes;
        myAxes.FontSize = fontSize;
        % Close figure with visibility off
        if strcmpi(plotVisible, 'off')
            close(myFigure)
        end
        
    % Frequency domain
        df = Fs/length(signal);
        dfResampled = Fs/length(signalResampled);
        f = 0:df:Fs-df;
        fResampled = 0:dfResampled:Fs-dfResampled;
        spectrum = abs(fft(signal));
        spectrum = spectrum/length(signal);
        spectrumResampled = abs(fft(signalResampled));
        spectrumResampled = spectrumResampled/length(signalResampled);

%         figure('Color','w','Visible', plotVisible);
        myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
        plot(f, spectrum);
        hold on, plot(fResampled, spectrumResampled);
        xlabel('Frequency, Hz');
        ylabel('Amplitude, m/s^2');
        title([signalTag, ' Spectrum. Signal Resampling']);
        grid on;
        legend('original','resampled');
        myAxes = myFigure.CurrentAxes;
        myAxes.FontSize = fontSize;
        % Close figure with visibility off
        if strcmpi(plotVisible, 'off')
            close(myFigure)
        end
        
    end
    
    
    
function [signalEnvelope] = getEnvelopeSignal(file, config)

        if nargin < 2
           error('Not enough input arguments'); 
        end

    % INPUT:
        signal = file.acceleration.signal;
        Fs = file.Fs;

        config = fill_struct(config, 'Rp', '1');
        config = fill_struct(config, 'Rs', '10');
        config = fill_struct(config, 'filterType', 'BPF');
        config = fill_struct(config, 'lowFreq', '500'); % envelopeSpectrum low Frequency [Hz]
        config = fill_struct(config, 'highFreq', '5000'); % envelopeSpectrum high Frequency [Hz]

        % Envelope Signal Parameters
        myLowFrequency = str2double(config.lowFreq);
        myHighFrequency = str2double(config.highFreq);
        myRp = str2double(config.Rp);
        myRs = str2double(config.Rs);
        filterType = config.filterType;

    % CALCULATION:
        switch(filterType)
            case 'BPF' % Band-Pass Filter
                Wp = [myLowFrequency*2/Fs myHighFrequency*2/Fs];
                Ws=[(myLowFrequency-0.1*myLowFrequency)*2/Fs (myHighFrequency+0.1*myHighFrequency)*2/Fs]; 
            case 'LPF'
                % Low-Pass Filter
                Wp = myHighFrequency*2/Fs;
                Ws = (myHighFrequency+100)*2/Fs; 
            case 'HPF'
                Ws = myLowFrequency*2/Fs;
                Wp = (myLowFrequency*2)*2/Fs; 
        end

        [~,Wn1] = buttord(Wp,Ws,myRp,myRs);   
        [b1,a1] = butter(2 ,Wn1);

    % OUT:
        signalEnvelope = filtfilt(b1,a1,signal);
        signalEnvelope = abs(hilbert(signalEnvelope));
