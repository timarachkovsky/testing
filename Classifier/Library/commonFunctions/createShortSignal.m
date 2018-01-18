%CREATESHORTSIGNAL function extracts from original signal several parts and
% forms @shortSignal by merging to speed up scalogram calculation and 
% sparse decomposition optimal iteration number find process

function [ shortSignal ] = createShortSignal( file, config )

%% _______________________ DEFAULT_PARAMETERs _________________________ %%
    if nargin < 2
        config = [];
    end
    
    config = fill_struct(config, 'type', 'none');
    type = config.type;
    
    iLoger = loger.getInstance;
    
%% _______________________ MAIN_CALCULATIONs __________________________ %%

    signal = file.signal;
    [m,n] = size(signal);
    if m < n 
       signal = signal';
    end
    file.signal = signal;
    
    switch (type)
        case 'multi'
            shortSignal = multiSignal(file,config);
        case 'mono'
            shortSignal = monoSignal(file,config);
        otherwise
            printWarning(iLoger, ['There no such mode: ', type, ' for createShortSignal method!']);
            shortSignal = signal;
    end

    
end

function [shortSignal] = multiSignal(file, config)
    
    iLoger = loger.getInstance;
    
    %%   ...................  Default parameters  ................
    config = fill_struct(config, 'plotEnable','0');
    config = fill_struct(config, 'multi', []);
    config.multi = fill_struct(config.multi, 'framesNumber','4');
    config.multi = fill_struct(config.multi, 'secondsPerFrame','4');

    if ischar(config.plotEnable)
        plotEnable = str2double(config.plotEnable);
    end

    framesNumber = str2double(config.multi.framesNumber);
    secondsPerFrame = str2double(config.multi.secondsPerFrame);
    signal = file.signal;
    Fs = file.Fs;

    %%  ..................... Main Calculations ...................%% 
    
    % Recalculate @secondPerFrame to saples number (frameLength)
    signalLength = length(signal); 
    frameLength = secondsPerFrame*Fs; 
    
    % Checking signal length to be long enough to form @shortSingal from it
    % parts
    maxFramesNumber = floor(signalLength/frameLength);
    if maxFramesNumber <= framesNumber
       printWarning(iLoger, 'Too short input signal to create the shorter one!');
       shortSignal = signal;
       return
    end

    % Select signal parts from different parts of the original signal and
    % merge they to form @shortSignal
    greatFrameLength = floor(signalLength/framesNumber);
    signal = signal(1:greatFrameLength*framesNumber,1);
    baseTable = reshape(signal,[],framesNumber);
    baseTable = baseTable(1:frameLength,:);
    shortSignal = reshape(baseTable,[],1);


    %%  ....................Plot Results ............................ %%

    if plotEnable == 1
        
        dt = 1/Fs;
        t = (0:dt:dt*(length(signal)-1))';
        tShort = reshape(t,[],framesNumber);
        tShort = tShort(1:frameLength,:);
        tShort = reshape(tShort,[],1);

        figure('Color', 'w')
        hold on;
        plot(t, signal, 'b');
        plot(tShort, shortSignal, 'r');
        title('Original / Shortened Signal');
        xlabel('Time, Sec');
        ylabel('Signal');
        legend('Original','Shortened');
        
        % Close figure with visibility off
        if strcmpi(config.plotVisible, 'off')
            close
        end
    end


end

function [shortSignal] = monoSignal(file, config)

    %%  .............  Default parameters  .................... %%
    config = fill_struct(config, 'plotEnable','0');
    config = fill_struct(config, 'mono', []);
    config.mono = fill_struct(config.mono, 'startSecond','0');
    config.mono = fill_struct(config.mono, 'lengthSeconds','10');

    if ischar(config.plotEnable)
        plotEnable = str2double(config.plotEnable);
    end

    startSecond = str2double(config.mono.startSecond);
    lengthSeconds = str2double(config.mono.lengthSeconds);
    signal = file.signal;
    Fs = file.Fs;

    %%  ..................... Main Calculations ...................%%
    
    % Recalculate @startSecond and @lengthSeconds from seconds to saples
    % and find the end position of the shortSignal
    
    if startSecond < 0
        startSecond = 0;
    end
    
    if lengthSeconds < 0
        lengthSeconds = 1;
    end
    
    signalLength = length(signal); 
    startPosition = startSecond*Fs; 
    frameLength = lengthSeconds*Fs;
    endPosition = startPosition + frameLength;
    
    if startPosition>signalLength || startPosition==0
       startPosition = 1;
    end
    
    if endPosition > signalLength
        endPosition = signalLength;
    end
    
    shortSignal = signal(startPosition:endPosition, 1);
    
    %%  ....................Plot Results ............................ %%

    if plotEnable == 1
        
        dt = 1/Fs;
        t = (0:dt:dt*(length(signal)-1))';
        tShort = t(startPosition:endPosition);

        figure('Color', 'w')
        hold on;
        plot(t, signal, 'b');
        plot(tShort, shortSignal, 'r');
        title('Original / Shortened Signal');
        xlabel('Time, Sec');
        ylabel('Signal');
        legend('Original','Shortened');
        
        % Close figure with visibility off
        if strcmpi(config.plotVisible, 'off')
            close
        end
    end
    
    
end

