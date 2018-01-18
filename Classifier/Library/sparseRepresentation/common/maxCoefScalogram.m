function [maxCoefValue, freqVector] = maxCoefScalogram(file, config)
    %maxCoefWavelet Summary of this function goes here
% Developer: ASLM
% version 1.0

% Correct: Kosmach
% data 07.07.2016
%   Detailed explanation goes here
    % Input arguments: FILENAME path of file *.wav; if plotEnable == 1 -
    % draw imagers, lengthFrame - number of freq points, left and right
    % from max coefficients
    % Output arguments: maxCoefNumber - the maximum values of coefficients
    % in scalogramm, vectorFreq-corresponding frequency.


if nargin < 2
   config = [];
end
%% _____________________ DEFAULT_PARAMETERS ___________________________ %%

   config = fill_struct(config, 'plotEnable','0');
   config = fill_struct(config, 'cutCoef','1');
   config = fill_struct(config, 'logScaleEnable','1');
   config = fill_struct(config, 'lowFreq','500');
   config = fill_struct(config, 'highFreq','33000');
   config = fill_struct(config, 'freqStep','200');
   config = fill_struct(config, 'freqPerOctaveCnt','8');
   config = fill_struct(config, 'scaleStep','-0.05');
   config = fill_struct(config, 'sideFreqCount','2');
   config = fill_struct(config, 'minFreqDistance','0');
   config = fill_struct(config, 'maxFreqCount','1');
   config = fill_struct(config, 'sortFreqs','descend'); %can be 'descend',
                                                    % 'ascend' or 'none'
   config = fill_struct(config, 'varianceEnable', '1');  % Use variance to
                                                    %find scalogram coeffs
   config.shortSignal = fill_struct(config.shortSignal, 'processingEnable','1');
                                                    
   config.plotEnable = str2double(config.plotEnable);
   config.cutCoef = str2double(config.cutCoef);
   
   config.logScaleEnable = str2double(config.logScaleEnable);
   config.lowFreq = str2double(config.lowFreq);
   config.highFreq = str2double(config.highFreq);
   config.roundingEnable = str2double(config.roundingEnable);
   
   config.freqStep = str2double(config.freqStep);
   config.freqPerOctaveCnt = str2double(config.freqPerOctaveCnt);
   config.scaleStep = str2double(config.scaleStep);
   config.sideFreqCount = str2double(config.sideFreqCount);
   config.minFreqDistance = str2double(config.minFreqDistance);
   config.maxFreqCount = str2double(config.maxFreqCount);
   config.varianceEnable = str2double(config.varianceEnable);
   config.shortSignal.processingEnable = str2double(config.shortSignal.processingEnable);
                                                           
%% _________________________ MAIN_CALCULATIONs _______________________ %%
                                                    
    if config.shortSignal.processingEnable
        % Creation of shortened signal to speed up scalogram and
        % sparseProcessing parameters calculation
        parameters = []; parameters = config.shortSignal;
        file.signal = createShortSignal(file,parameters);
    else
        file.signal = file.signal(1:length(file.signal)/config.cutCoef,1);  
    end 
    Fs = file.Fs;
    
    if config.logScaleEnable == 1
        % Form frequency list with N freq per octave
        freqSpace = quadraspace(config.lowFreq,config.highFreq,config.freqPerOctaveCnt, config.roundingEnable);
%         freqSpace = quadraspace(config.lowFreq,config.highFreq,config.freqPerOctaveCnt);
    else
        freqNumber = floor((config.highFreq - config.lowFreq)/config.freqStep);
        freqSpace = linspace(config.lowFreq,config.highFreq,freqNumber);
    end
    scales = round(20*Fs./freqSpace);

    scaleStep = config.scaleStep;                    % step for smooth
    smoothCoef = scaleStep/1.5;
    
%% ________________________ Scalogram ________________________________ %%
    % Get continuous wavelet transform coefficients matrix
    coef = dividedCWT(file,scales);
 
    if config.varianceEnable == 1
%         maxScaleCoef = var(coef,[],2);
        maxScaleCoef = std(coef,[],2);
    else
        maxScaleCoef = max(coef,[],2);
    end
    freqVec = (scales.^(-1))*20*Fs; 
   
    % --------- Find & validate main frequencies ---------
    maxScaleCoefNonSmooth = maxScaleCoef;
    maxScaleCoef = smooth(maxScaleCoef,10*smoothCoef/scaleStep);        % rough smooth
    maxScaleCoef = smooth(maxScaleCoef,10*smoothCoef/2/scaleStep);
    maxScaleCoef = smooth(maxScaleCoef,10*smoothCoef/4/scaleStep);      % delicate smooth
    
    % Find all peaks on the smoothed scalogram and check the max value
%     [peaksValueCoef,locs] = findpeaks(maxScaleCoef);
    [peaksValueCoef,locs] = findpeaks(maxScaleCoef,...
                                            'MinPeakDistance',config.minFreqDistance,...
                                            'NPeaks',config.maxFreqCount,...
                                            'SortStr',config.sortFreqs);
    
    % Get freqs around max values
    [maxCoefLocs,~,maxCoefValue] = find(peaksValueCoef);
    
    for i = 1:1:numel(maxCoefLocs)
        trueFreqs(i,1:2*config.sideFreqCount+1) = freqVec(1,locs(maxCoefLocs(i))-config.sideFreqCount:1:locs(maxCoefLocs(i))+config.sideFreqCount);
    end
    
    tureMaxScaleCoef = zeros(size(maxScaleCoef));
    tureMaxScaleCoef(locs,1)= maxScaleCoef(locs,1);
    
%% ___________________________ PLOT_RESULTs ___________________________ %%
    
    if config.plotEnable
        figure('Color', 'w')
        hold on;
        plot(freqVec, maxScaleCoefNonSmooth, 'g'), title('Scalogram');
        plot(freqVec, maxScaleCoef, 'b'), title('Scalogram');
        stem(freqVec, tureMaxScaleCoef, 'r');  
        xlabel('Frequency, Hz');
        ylabel('CWT-coeff Dispersion');
        legend('original','smoothed');
    end 
    
    freqVector = trueFreqs;
end