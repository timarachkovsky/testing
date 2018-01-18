function [ period ] = periodEstimation(file, config)
%PERIODESTIMATION Summary of this function goes here
%   Detailed explanation goes here

if nargin < 2
   config = []; 
end

%% ______________________ Default Parameter ____________________________ %%

config = fill_struct(config,'plotEnable','0');
config = fill_struct(config,'maxFrequency','150');

if ischar(config.plotEnable)
    config.plotEnable = str2num(config.plotEnable);
end
config.maxFrequency = str2num(config.maxFrequency);

%% _________________________ Calculation _______________________________ %%

signal = file.signal;
Fs = file.Fs;

% CF = envelope(xcorr(signal));
CF = envelope(xcorr(signal));
onesideCF = CF((length(CF)-1)/2:end,1)/max(CF);

[~,df]=findpeaks(onesideCF);
% meanPeakDistance = rms(diff(df));
meanPeakDistance = rms(diff(df));

smoothOnesideCF = detrend(smooth(onesideCF,meanPeakDistance),'linear');

% % ----- test -- %%
% smoothOnesideCF1 = xcorr(detrend(smooth(onesideCF,meanPeakDistance),'linear'));
% smoothOnesideCF =  smoothOnesideCF1((length(smoothOnesideCF1)-1)/2:end,1)/max(smoothOnesideCF1);
% % ------------- %%

MPD = round(file.Fs/config.maxFrequency); % min peaks distance
[locs,df] = findpeaks(smoothOnesideCF,'MinPeakProminence',rms(smoothOnesideCF(1:round(length(smoothOnesideCF/10)),1)),...
                                    'MinPeakDistance',MPD);

file.signal = [];
file.signal = df;
[ peakDistance ] = peakDistanceEstrimation( file, config);                           
period = peakDistance./file.Fs;                        
 
%% __________________________ Plot Results ____________________________ %%

    if config.plotEnable
    % find peaks on the nonsmoothed signal
        figure
        findpeaks(smoothOnesideCF,'MinPeakProminence',rms(smoothOnesideCF(1:round(length(smoothOnesideCF/10)),1)),...
                                    'Annotate','extents',...
                                    'MinPeakDistance',MPD);

 %% ________________________Calculations ______________________________ %%                               
                                
if isnan(period)
    meanPeakDistance = mean(diff(df))/4;
    smoothOnesideCF2 = smooth(smoothOnesideCF,meanPeakDistance);

    [~, locs] = findpeaks(smoothOnesideCF2,'MinPeakProminence',rms(smoothOnesideCF2(1:round(length(smoothOnesideCF2/10)),1))/2,...
                        'MinPeakDistance',MPD);
                  
%     peakDistanceVector = smooth(diff(locs));
    file.signal = [];
    file.signal = locs;
    [ peakDistance ] = peakDistanceEstrimation( file, config );
    period = peakDistance./file.Fs;

     
%% __________________________ Plot Results ____________________________ %% 
    % find peaks on the smoothed signal   
        figure
        findpeaks(smoothOnesideCF2,'MinPeakProminence',rms(smoothOnesideCF2(1:round(length(smoothOnesideCF2/10)),1))/2,...
                                        'Annotate','extents',...
                                        'MinPeakDistance',MPD);
    end   
end 


