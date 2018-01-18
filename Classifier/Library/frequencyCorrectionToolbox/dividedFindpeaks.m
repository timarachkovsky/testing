%DIVIDEDFINDPEAKS Summary of this function goes here
%   Detailed explanation goes here
% PeakTable structure -> ( peakFrequency, peakMagnitude, peakProminance ) 

% Function version : v1.0
% Last change : 02.07.2016
% Developer : ASLM

function [ peakTableUnique ] = dividedFindpeaks( file, config )

if nargin < 2
   config = []; 
end

%% ________________________ Default Parameters ________________________ %%

config = fill_struct(config, 'plotEnable','0');
config = fill_struct(config, 'lowFrequency','5'); % [Hz]
config = fill_struct(config, 'framesNumber','10');
config = fill_struct(config, 'frameOverlapValue','5'); % [Hz]

config = fill_struct(config, 'minPeakProminenceCoef','2.5');
config = fill_struct(config, 'minPeaksDistance','0.2');

config = fill_struct(config, 'NPeaks','');
config = fill_struct(config, 'SortStr','no');
config = fill_struct(config, 'precision','3');

config.plotEnable = str2double(config.plotEnable);
config.lowFrequency = str2double(config.lowFrequency);
config.framesNumber = str2double(config.framesNumber);
config.frameOverlapValue = str2double(config.frameOverlapValue);
config.minPeakProminenceCoef = str2double(config.minPeakProminenceCoef);
config.minPeaksDistance = str2double(config.minPeaksDistance);

if ~isempty(config.NPeaks)
    config.NPeaks = str2double(config.NPeaks);
end
config.precision = str2double(config.precision);
% signal = file.signal;
signal = file.signal;
[m,n] = size(signal);
if m>n
    signal = signal';
end
signalLength = length(signal);
Fs = file.Fs;
df = Fs/signalLength;
peakTable = [];
config.minPeaksDistance = round(config.minPeaksDistance/df);
%% _______________________ FreqFrames Creation ________________________ %%

% Calculate low & high frames frequencies and rms level for each frame;
% also peak positions, magnitudes and prominances are estimated over the 
% obtained frames
[lowFreqs, highFreqs] = getFramesFreqs( config );
lowFreqs(1,1) = df;
rmsLevel = zeros(config.framesNumber,1); 
%% _______________________ Find Frame Peaks ___________________________ %% 
for i=1:1:config.framesNumber
    % frame rounded frequency vector
    f = round(lowFreqs(i,1)/df-1)*df:df:round(highFreqs(i,1)/df-1)*df;
    signalFrame = signal(1,round(lowFreqs(i,1)/df):round(highFreqs(i,1)/df));
    rmsLevel(i,1) = rms(signalFrame);
    [mag,locs,~,prms] = findpeaks(signalFrame,...
     'MinPeakProminence',config.minPeakProminenceCoef*rmsLevel(i,1),...
     'MinPeakDistance',config.minPeaksDistance,'NPeaks',config.NPeaks,...
     'SortStr',config.SortStr);
    prms = prms/rmsLevel(i,1);
 if config.plotEnable
         findpeaks(signalFrame,...
     'MinPeakProminence',config.minPeakProminenceCoef*rmsLevel(i,1),...
     'MinPeakDistance',config.minPeaksDistance,'NPeaks',config.NPeaks,...
     'SortStr',config.SortStr);
 end
    
    % Fill peakTable with obtained peaks
    if ~isempty(locs)
       if ~isempty(peakTable)
           peakTable = [peakTable; [f(1,locs)',mag',prms']];
       else
           peakTable = [f(1,locs)',mag',prms'];
       end
    end
end
if ~isempty(peakTable)
%     peakTable = unique(round(peakTable(:,1:2).*10^config.precision)/10^config.precision,'rows');
    [peakTableUnique,x,~] = unique(round(peakTable(:,1:2).*10^config.precision)/10^config.precision,'rows');
    
    peakTableUnique(:,3) = peakTable(x,3);
else
    peakTableUnique = [];
end
end