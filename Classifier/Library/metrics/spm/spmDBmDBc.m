function [c, m, zeroLvl] = spmDBmDBc(File, config)
% algorithm: implementation is the amount specified in the signal peak, 
% and outputs the level at which the number of peaks to be necessary.

% Method returns "carpet" level (lowLevel), max level (highLevel) 
% and zero-level of the input signal.
%% _____________________ Default Parametrs ____________________________ %%
config = fill_struct(config, 'plotEnable', '0');
config = fill_struct(config, 'peakCntPerSecondRequired', '200'); % it should be 200 
% peaks per one-second-frame (or 6000 per 30-second)
config = fill_struct(config, 'accurate', '0.05'); % max and min 
% values of nnz with 5%-accuracy
config = fill_struct(config, 'distance', '20'); % this parameter may be
% specified to ignore smaller peaks that may occur in close proximity to
% a large local peak
config = fill_struct(config, 'numberThresh', '10'); % number of samples in a 
%grid search threshold

accurate = str2double(config.accurate);
numberThresh = str2double(config.numberThresh);
peakCntPerSecondRequired = str2double(config.peakCntPerSecondRequired);
plotEnable = str2double(config.plotEnable);
debugModeEnable = str2double(config.debugModeEnable);
plotVisible = config.plotVisible;
distance = str2double(config.distance);

iLoger = loger.getInstance;

%% _____________________________ Calculation ____________________________%%
peakCntRequired = floor(length(File.acceleration.signal)/File.Fs)*peakCntPerSecondRequired;  
    
zeroLvl = rms(File.acceleration.signal); 

threshMin = 0; %% the threshold above which is the required number of peaks
peaksMaxVector = findpeaks(File.acceleration.signal, 'MinPeakHeight', zeroLvl,'MinPeakDistance', distance);
if isempty(peaksMaxVector)
    threshMax = max(File.acceleration.signal);
else
    sortSignal = sort(peaksMaxVector, 'descend');
    threshMax = sortSignal(2);  
end

% dBm = 20*log(threshMax/zeroLvl); % the maximum threshold with respect to the zero level
m = threshMax;

threshVector = linspace(threshMin,threshMax,numberThresh); % forming grid threshold vector

config.peakCntRequired = num2str(peakCntRequired);
File.thresh = threshVector;
[threshMinPos,peakCntCurrent,peakMaxCnt] = searchMinPosThreshold(File, config);
   
if peakMaxCnt > peakCntRequired   
    % check the accuracy of the desired value
    Y1 = bsxfun(@times,peakCntRequired*(1+accurate)>peakCntCurrent,peakCntRequired*(1-accurate)<peakCntCurrent);
   
    if peakCntCurrent < peakCntRequired
        threshMinNumberPeaks = threshVector(threshMinPos);
        threshMaxNumberPeaks = threshVector(threshMinPos-1);
    else
        threshMinNumberPeaks = threshVector(threshMinPos+1);
        threshMaxNumberPeaks = threshVector(threshMinPos);
    end
   
    if logical(Y1) == false % if not exactly reached the desired
        while logical(Y1) == false %reduce the required range, until we find the required accuracy

            threshVector = linspace(threshMaxNumberPeaks,threshMinNumberPeaks,numberThresh); % forming grid threshold vector   
            File.thresh = threshVector;  

            [threshMinPos,peakCntCurrent] = searchMinPosThreshold( File, config );

            % check the accuracy of the desired value
            Y1 = bsxfun(@times,peakCntRequired*(1+accurate)>peakCntCurrent,peakCntRequired*(1-accurate)<peakCntCurrent);  

            if peakCntCurrent < peakCntRequired
                threshMinNumberPeaks = threshVector(threshMinPos);
                threshMaxNumberPeaks = threshVector(threshMinPos-1);
            else
                threshMinNumberPeaks = threshVector(threshMinPos+1);
                threshMaxNumberPeaks = threshVector(threshMinPos);
            end
        end  
    end

    c = threshMinNumberPeaks;

    if isempty(c)
        c = -1;
    end
%% ___________________________ Plot Results ___________________________ %%
    if plotEnable && debugModeEnable   

        signalLength = length(File.acceleration.signal);   
        dt = 1/File.Fs; 
        tmax = dt*signalLength;
        t = 0:dt:tmax-dt;
        low = ones(1, signalLength)*c; % Low level threshold 
        high = ones(1, signalLength)*m; % High level threshold 

        [maxMag, maxLoc] = findpeaks(File.acceleration.signal,'MinPeakHeight',...
                        threshMinNumberPeaks,'MinPeakDistance',distance);
        %      maxMag = 20*log(maxMag/zeroLvl);
        peak_vector = zeros(1,signalLength);   
        peak_vector(maxLoc) = maxMag;

        % Plot original signal and 
        figure('Color','w','Visible', plotVisible)
        subplot(2,1,1)
        plot(t, File.acceleration.signal, 'b');
        ylabel('Original signal, m/s^2');
        xlabel('Time, s');
        title('dBm/dBc levels calculation');
        
        % Plot obtained peaks exceeding low level
        subplot(2,1,2)
        hold on
        plot(t, peak_vector, 'b');
        plot(t, low, 'g');
        plot(t, high, 'r');
        ylabel('Signal after SPM: dBm/dBc, m/s^2');
        xlabel('Time, s');
        
        % Close figure with visibility off
        if strcmpi(plotVisible, 'off')
            close
        end
    end

 else
    c = NaN(1);
    m = NaN(1);
    printWarning(iLoger, 'Obtained peaks number does not rich threshold level of 200/sec!'); 
 end
end

