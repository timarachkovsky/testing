% LOGSPECTRUM function calculates logarithmic spectrum of the input signal
% and cut noise level
% 
% INPUT:
% 
% file - structure which contain signal, spectrum, frequencies and sampling
% frequency
% 
% config - configuration file
% 
% spectrumType - type of inpute spectrum.
% spectrumType = 'displacement' | 'velocity' | 'acceleration' | 'envelope'
% 
% OUTPUT:
% 
% Result - structure which contain variables amplitude, peakTable,
% noiseLevel and noiseLevelVector
%    amplitude - cut logarithmic spectrum to the value Fs/2
%    peakTable - table of peaks whose level in dB exceeds the noise level.
%    Peaks table is calculated from the spectrum normalized by the RMS 
%    level. RMS level is calculated for each frequency window.
%    noiseLevel - overal noise level of logarithmic spectrum. Noise level
%    is calculated using RMS level of logarithmic spectrum in a specific
%    frequency band (depending on the spectrum type: displacement,
%    velocity, acceleration, envelope spectrum) and RMS level of normilize
%    logarithmic spectrum.
%    noiseLevelVector - vector of noise level of logarithmic spectrum
% 
% noiseLevelVector - vector of noise level of input signal
% 
% Developer:              
% Development date:       
% Modified by:            P. Riabtsev
% Modification date:      26-12-2016

% Modified by:            ASLM
% Modification date:      25-01-2017

% Modified by:            ASLM
% Modification date:      27-01-2017 --> Added peakTable calculation
function [Result, noiseLevelVector, peakTable] = logScalingData(file, config, spectrumType)

%% ____________________ DEFAULT PARAMETERS _____________________________ %%

% Check the input data
if nargin < 1
    error('There are not enough input arguments!');
end
if nargin < 2
   config = [];
   spectrumType = 'acceleration';
end
if nargin < 3
    spectrumType = 'acceleration';
end

% Fill empty fields
config = fill_struct(config, 'frameLength', '20');
config = fill_struct(config, 'minPeaksDistance', '0.2');
config = fill_struct(config, 'rmsFactor', '2');
config = fill_struct(config, 'cutoffLevel', '0');
config = fill_struct(config, 'plotEnable', '0');
config = fill_struct(config, 'printEnable', '0');
config = fill_struct(config, 'dataExtractionEnable', '1');

iLoger = loger.getInstance;

%% ____________________ CALCULATION ____________________________________ %%

% Get main data
data = file.spectrum;  %Oy, data
frequencies = file.frequencies';  %Ox, argument
Fs = file.Fs;
% Get the spectrum on a logarithmic scale
% baseValue = str2double(config.baseValue);
switch spectrumType 
    case 'displacement'   % displacement base value is unknown!
        baseValue = 5e-9; % [mkm] custom-calculated value
    case 'velocity'
        baseValue = 5e-8; % [m/s]
    case 'acceleration'
        baseValue = 1e-6; % [m/s^2]
    case 'correl'
        baseValue = 1e-24; % [m/s^2]
    otherwise
        baseValue = min(data); % [m/s^2]
        baseValue = max([baseValue 1e-24]);
end

logScale = abs(20 * log10(data / baseValue));
Result.amplitude = logScale;

% signalLength = length(file.signal);
% df = Fs / signalLength;
df = max(frequencies)/length(frequencies);

%-=Calculate a frame width in average width of a prominent peaks, cut off a prominent peaks before a window averaging=-
if str2double(config.dataExtractionEnable)
    %Find prominent peaks.
    [promHeights, promLocs, promWidths, prominences] = findpeaks(logScale, 'SortStr', 'descend');
    prominentIdxs = find(prominences >= ( mean(prominences) + std(prominences) ));
    highIdx = find(promHeights >= ( mean(promHeights) + std(promHeights) ));
    widthIdx = find(promWidths >= ( mean(promWidths) + std(promWidths) ));
    goodIdx = intersect(prominentIdxs, highIdx);
    if isempty(goodIdx)
        goodIdx = prominentIdxs;
    end
    if isempty(goodIdx)
        pkNum = min([numel(promLocs), 10]);
        goodIdx = 1:pkNum;
    end
    goodWidthIdx = intersect(goodIdx, widthIdx);
    if isempty(goodWidthIdx)
        goodWidthIdx = goodIdx;
    end
    promLocs = promLocs(goodIdx);
    goodWidths = promWidths(goodWidthIdx);
    %An average width.
    peakWidthSamples = mean(goodWidths);
    %Point frame length in average widths.
    peakWidth = peakWidthSamples*df;
    windWidth = str2double(config.frameLength)*peakWidth;
    if str2double(config.printEnable)
        fprintf('Average prominent peak width is %10.0f samples, %10.5f seconds.\n', peakWidthSamples, peakWidth);
        fprintf('The current window is %s peak widths, %10.5f seconds.\n', config.frameLength, windWidth);
    end
    if isnan(windWidth)
        warning('NaN window width.');
    else
        config.frameLength = num2str(windWidth);
    end
end

% Calculate the number of samples in the frame
frameLength = str2double(config.frameLength);
frameSamplesNumber = floor(frameLength / df);
if frameSamplesNumber > length(logScale)
    frameSamplesNumber = length(logScale);
end
if frameSamplesNumber < 3 
    frameSamplesNumber = 3;
end
% Calculate the number of frames
framesNumber = floor(length(logScale) / frameSamplesNumber);
% Cut spectrum and frequencies to the end value of the last frame
frameLogScale = logScale(1 : framesNumber * frameSamplesNumber, 1);
frameFrequencies = frequencies(1 : length(frameLogScale));
%Cut off prominent peaks to detect a noise level right.
if str2double(config.dataExtractionEnable)
    promLocs = promLocs(promLocs < numel(frameLogScale));   %Limit by cutted by frames data.
    promWidths = promWidths(goodIdx);   %Rest only widths of a good peaks.
    for i = 1:numel(promLocs)
        %Peak's centre +- peak's width half.
        cutSamplesLow = promLocs(i) - floor(promWidths(i)/2);
        cutSamplesLow = max([1, cutSamplesLow]);
        cutSamplesHigh = promLocs(i) + ceil(promWidths(i)/2);
        cutSamplesHigh = min([ cutSamplesHigh, length(frameLogScale) ]);
        cutSamples = cutSamplesLow:cutSamplesHigh;  %samples of a peak.
        %Delta height per sample for a filling vector - diff between peak's
        %borders divide on it's length in samples.
        ds = (frameLogScale(cutSamplesHigh) - frameLogScale(cutSamplesLow))/length(cutSamples);
        if ds == 0
           continue; 
        end
        %Line that joins a peak's borders.
        fillingVector = frameLogScale(cutSamplesLow):ds:frameLogScale(cutSamplesHigh)-ds;
%         %Cuttind by a horizontal reference line - cut a prominence.
%         frameLogScale(cutSamples) = promHeights(i) - prominences(i);
        frameLogScale(cutSamples) = fillingVector;
    end
end

% Calculate the rms value in each frame
levels = rms(reshape(frameLogScale, [], framesNumber));
% The first level - the rms value of the first half of the first frame
firstLevel = rms(frameLogScale(1 : floor(frameSamplesNumber / 2)));
% The last level - the rms value of the last half of the last frame
lastLevel = rms(frameLogScale(end - floor(frameSamplesNumber / 2) : end));
% Count the number of samples before and after the interpilation
% The number of levels without the first level
levelsNumber = length(levels);
% Interpolation step for add values
interpStep = 1 / frameSamplesNumber;
% Sample points
samplePoints = [0.5 + interpStep, 1 : 1 : levelsNumber, levelsNumber + 0.5];
% Query points
queryPoints = 0.5 + interpStep : interpStep : levelsNumber + 0.5;
% Corresponding values
correspondingValues = [firstLevel, levels, lastLevel];
% Spline interpolation
interpLevels( : , 1) = interp1(samplePoints, correspondingValues, queryPoints, 'pchip');  %'spline'

% Insert values cut the last frame
rmsLevels = [interpLevels; logScale(length(frameLogScale) + 1 : end)];
% Normalize by the rms level
peaksData = logScale - rmsLevels;

% Cut noise level
cutPeaksData = peaksData;
% Normalization level
rmsFactor = str2double(config.rmsFactor);
cutoffLevel = str2double(config.cutoffLevel);
normalizeLevel = rms(peaksData) * rmsFactor + cutoffLevel;
% Points of values less than the normalization level
cropPoints = peaksData < normalizeLevel;
% Cut values less than the normalization level
cutPeaksData(cropPoints) = normalizeLevel;
% Normalize by the normalization level
cutPeaksData = cutPeaksData - normalizeLevel;

% Create a table with peaks whose values are greater than the normalization
% level
MinPeakDistance = round(str2double(config.minPeaksDistance)/df);
[~,positions] = findpeaks(cutPeaksData,'MinPeakDistance',MinPeakDistance);
% peakPoints = find(cutPeaksSpectrum > 0);
Result.peakTable( : , 1) = frequencies(positions);
Result.peakTable( : , 2) = cutPeaksData(positions);
Result.cutPeaksData = cutPeaksData;

% Calculate overall noise level of logarithmic spectrum
switch spectrumType
    case 'displacement'
        logNoiseLevel = rms(logScale(frequencies <= 500));
    case 'velocity'
        logNoiseLevel = rms(logScale((frequencies >= 10) & (frequencies <= 3000)));
    case 'acceleration'
        logNoiseLevel = rms(logScale(frequencies <= 5000));
    otherwise
        logNoiseLevel = rms(logScale(frequencies <= 5000));
end
Result.noiseLevel = logNoiseLevel + normalizeLevel;

% Calculate vector of noise level of logarithmic spectrum
logNoiseLevelVector = rmsLevels + ones(size(peaksData, 1), 1) * normalizeLevel;
Result.noiseLevelVector = logNoiseLevelVector;

% Calculate vector of noise level of input signal
noiseLevelVector = baseValue * power(10, logNoiseLevelVector / 20);


% Forming the table of found peaks with format
% | frequency | amplitude | prominence | logProminence |

[iAmplitude,iPositions,~,iProminence] = findpeaks(data,'MinPeakDistance',MinPeakDistance);
iFrequencies = frequencies(iPositions);
[~,positionCommon1,positionCommon2] = intersect(iPositions,positions);

peakTable( : , 1) = iFrequencies(positionCommon1);
peakTable( : , 2) = iAmplitude(positionCommon1);
peakTable( : , 3) = iProminence(positionCommon1)./noiseLevelVector(iPositions(positionCommon1));
peakTable( : , 4) = cutPeaksData(positions(positionCommon2));


%% ____________________ PLOTTING _______________________________________ %% 

if str2double(config.plotEnable)
    % Plot logarithmic spectrum and rms level
    figure;
    title('Rms frame level');
    hold on;
    grid on;
    plot(frequencies, logScale, ...
        'DisplayName', 'Log spectrum');
    plot(frequencies, rmsLevels, ...
        'DisplayName', 'Rms frame level');
    plot(frequencies, logNoiseLevelVector, ...
        'DisplayName', 'Noise level vector');
    xlabel('Frequency, Hz');
    ylabel('Amplitude, dB');
    legend('show', 'Location', 'best');
    xlim([0 Fs/2 + 1]);
    hold off;
    
    % Plot normilize logarithmic spectrum and normilize level
    figure;
    title('Peaks levels');
    hold on;
    grid on;
    plot(frequencies(1 : size(peaksData, 1)), peaksData, ...
        'DisplayName', 'Peaks levels');
    plot(frequencies(1 : size(peaksData, 1)), ones(1, size(peaksData, 1)) * normalizeLevel, ...
        'DisplayName', ['Normailization level: ', num2str(rmsFactor), '*rmsLevel +', num2str(cutoffLevel), ' dB']);
    xlabel('Frequency, Hz');
    ylabel('Amplitude, dB');
    legend('show', 'Location', 'best');
    xlim([0 Fs/2 + 1]);
    hold off;
    
    % Plot cut logarithmic spectrum
    figure;
    title('Normalize peaks levels');
    hold on;
    grid on;
    plot(frequencies(1 : size(cutPeaksData, 1)), cutPeaksData, ...
        'DisplayName', 'Normalize peaks levels');
    xlabel('Frequency, Hz');
    ylabel('Amplitude, dB');
    legend('show', 'Location', 'best');
    xlim([0 Fs/2 + 1]);
    hold off;
end

end
