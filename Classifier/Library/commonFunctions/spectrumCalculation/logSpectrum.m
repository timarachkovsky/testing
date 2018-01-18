% LOGSPECTRUM function calculates logarithmic spectrum of the input signal
% and cut noise level
% 
% INPUT:
% 
% file - structure which contain signal, spectrum, frequencies and
% sampling frequency
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
%      amplitude - cut logarithmic spectrum to the value Fs/2.
%      peakTable - table of peaks whose level in dB exceeds the noise
%      level. Peaks table is calculated from the spectrum normalized by
%      the RMS level. RMS level is calculated for each frequency window.
%      noiseLevel - overal noise level of logarithmic spectrum. Noise
%      level is calculated using RMS level of logarithmic spectrum in a
%      specific frequency band (depending on the spectrum type:
%      displacement, velocity, acceleration, envelope spectrum) and RMS
%      level of normilize logarithmic spectrum.
%      noiseLevelVector - vector of noise level of logarithmic spectrum.
% 
% noiseLevelVector - vector of noise level of input signal
% 
% Developer:              
% Development date:       
% 
% Modified by:            P. Riabtsev
% Modification date:      26-12-2016
% 
% Modified by:            ASLM
% Modification date:      25-01-2017
% 
% Modified by:            ASLM
% Modification date:      27-01-2017
%     Added peakTable calculation
% 
% Modified by:            P. Riabtsev
% Modification date:      23-10-2017
%     Added energy peak finding. Added window overlapping in the spectrum
%     calculation
function [Result, noiseLevelVector, peakTable] = logSpectrum(file, config, spectrumType)
    
    %% _________________ DEFAULT PARAMETERS ___________________________ %%
    
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
    config = fill_struct(config, 'stepLength', '10');
    config = fill_struct(config, 'minPeaksDistance', '0.2');
    config = fill_struct(config, 'rmsFactor', '2');
    config = fill_struct(config, 'cutoffLevel', '0');
    config = fill_struct(config, 'plotEnable', '0');
    
    %% _________________________ CALCULATION __________________________ %%
    
    % Get main data
    signal = file.signal;
    spectrum = file.spectrum;  %Oy, data
    frequencies = file.frequencies;  %Ox, argument
    Fs = file.Fs;
    % Get the spectrum on a logarithmic scale
    switch spectrumType 
        case 'displacement'   % displacement base value is unknown!
            baseValue = 5e-9; % [mkm] custom-calculated value
        case 'velocity'
            baseValue = 5e-8; % [mm/s]
        case 'acceleration'
            baseValue = 1e-6; % [m/s^2]
        case 'correl'
            baseValue = 1e-24; % [m/s^2]
        otherwise
            baseValue = 1e-6; % [m/s^2]
    end
    
    logSpectrum = abs(20 * log10(spectrum / baseValue));
    Result.amplitude = logSpectrum;
    
    % Caluclate the frequency increment
    df = max(frequencies) / length(frequencies);
    % Get the frame length and the step length
    frameLength = str2double(config.frameLength);
    stepLength = str2double(config.stepLength);
    % Calculate the frame samples number and the step samples number
    frameSamplesNumber = floor(frameLength / df);
    stepSamplesNumber = floor(stepLength / df);
    % Calculate the number of the complete frames
    framesNumber = floor((length(logSpectrum) - frameSamplesNumber) / stepSamplesNumber + 1);
    
    % Calculate RMS levels in the complete frames
    framesLevels = zeros(framesNumber, 1);
    for frameNumber = 1 : 1 : framesNumber
        frameStart = (frameNumber - 1) * stepSamplesNumber + 1;
        frameEnd = frameStart + frameSamplesNumber - 1;
        framesLevels(frameNumber) = rms(logSpectrum(frameStart : frameEnd));
    end
    % Calculate points of the RMS levels
    firstFrameCenter = ceil(frameSamplesNumber / 2);
    framesCenters = firstFrameCenter : stepSamplesNumber : framesNumber * stepSamplesNumber + firstFrameCenter - 1;
    
    % Check the last incomplete frame
    lastFrameStart = framesNumber * stepSamplesNumber + 1;
    lastFrameSamplesNumber = length(logSpectrum) - lastFrameStart + 1;
    if lastFrameSamplesNumber >= ceil(frameSamplesNumber / 2)
        framesLevels(framesNumber + 1) = rms(logSpectrum(lastFrameStart : end));
        lastFrameCenter = lastFrameStart - 1 + ceil(lastFrameSamplesNumber / 2);
        framesCenters(framesNumber + 1) = lastFrameCenter;
    end
    
    % Calculate the first RMS level (the first half of the starting frame)
    firstRmsLevel = rms(logSpectrum(1 : ceil(frameSamplesNumber / 4)));
    % Calculate the final RMS level (the second half of the final frame)
    finalRmsLevel = rms(logSpectrum(end - ceil(frameSamplesNumber / 4) + 1 : end));
    
    % Get query points for RMS levels interpolation
    queryPoints = 1 : 1 : length(logSpectrum);
    % Get the sample potins of the RMS levels
    samplePoints = [1, framesCenters, length(logSpectrum)];
    % Get the corresponding RMS levels
    correspondingLevels = [firstRmsLevel; framesLevels; finalRmsLevel];
    % Interpolate the RMS levels
    rmsLevels( : , 1) = interp1(samplePoints, correspondingLevels, queryPoints, 'spline');
    
    % Normalize the logarithmic spectrum by the rms levels
    peaksSpectrum = logSpectrum - rmsLevels;
    
    % Cut noise level
    cutPeaksSpectrum = peaksSpectrum;
    % Get the normalization parameters
    rmsFactor = str2double(config.rmsFactor);
    cutoffLevel = str2double(config.cutoffLevel);
    levelWithLengthSignal = 1.5 * log10((length(signal) / Fs) / 5);
    % Calculate the normalizing level
    normalizingLevel = rms(peaksSpectrum) * rmsFactor + cutoffLevel + levelWithLengthSignal;
    % Points of values less than the normalizing level
    cutPoints = peaksSpectrum < normalizingLevel;
    % Cut values less than the normalizing level
    cutPeaksSpectrum(cutPoints) = normalizingLevel;
    % Normalize by the normalizing level
    cutPeaksSpectrum = cutPeaksSpectrum - normalizingLevel;
    
    % Create a table with peaks whose values are greater than the
    % normalizing level
    minPeakDistance = round(str2double(config.minPeakDistance) / df);
    [~, logPositions] = findpeaks(cutPeaksSpectrum, 'MinPeakDistance', minPeakDistance);
    Result.peakTable( : , 1) = frequencies(logPositions);
    Result.peakTable( : , 2) = cutPeaksSpectrum(logPositions);
    Result.cutPeaksSpectrum = cutPeaksSpectrum;
    
    % Calculate overall noise level of the logarithmic spectrum
    spectrumRange = strsplit(config.spectrumRange, ':');
    if length(spectrumRange) == 2
        lowFrequency = str2double(spectrumRange{1});
        highFrequency = str2double(spectrumRange{2});
    elseif length(spectrumRange) == 1
        lowFrequency = 0;
        highFrequency = str2double(spectrumRange{1});
    else
        lowFrequency = 0;
        highFrequency = 5000;
    end
    logNoiseLevel = rms(logSpectrum((frequencies >= lowFrequency) & (frequencies <= highFrequency)));
    Result.noiseLevelLog = logNoiseLevel + normalizingLevel;
    Result.noiseLevelLinear = baseValue * power(10, Result.noiseLevelLog / 20);
    
    % Calculate vector of noise levels of logarithmic spectrum
    logNoiseLevelVector = rmsLevels + normalizingLevel;
    Result.noiseLevelVector = logNoiseLevelVector;
    
    %% _________________________ PEAKS_TABLE __________________________ %%
    % Forming the table of found peaks with format
    % | frequency | amplitude | prominence | logProminence | tag |
    
    [dirAmplitude, dirPositions, ~, dirProminence] = findpeaks(spectrum, 'MinPeakDistance', minPeakDistance);
    dirFrequencies = frequencies(dirPositions);
    [~, commonDirPositions, commonLogPosition] = intersect(dirPositions, logPositions);
    
    % Calculate vector of noise level of input signal
    noiseLevelVector = baseValue * power(10, logNoiseLevelVector / 20);
    
    peakTable( : , 1) = dirFrequencies(commonDirPositions);
    peakTable( : , 2) = dirAmplitude(commonDirPositions);
    peakTable( : , 3) = dirProminence(commonDirPositions) ./ noiseLevelVector(dirPositions(commonDirPositions));
    peakTable( : , 4) = cutPeaksSpectrum(logPositions(commonLogPosition));
    peakTable( : , 5) = zeros(size(commonDirPositions));
    
    %% _________________________ ENERGY_PEAKS _________________________ %%
    
    % Find the energy bumps and int bands
    [energyLogAmplitudes, energyFrequencies, energyPositions, energyLogProminences, ~, energyBands] = ...
        energyPeakFinder(logSpectrum, logNoiseLevelVector, frequencies, config);
    
    % Find peaks in the energy bump bands or undefined energy bump bands
    bandPeakIndex = false(size(peakTable( : , 1), 1), size(energyBands, 1));
    for bandNumber = 1 : 1 : size(energyBands, 1)
        bandPeakIndex( : , bandNumber) = (peakTable( : , 1) >= energyBands(bandNumber , 1)) & (peakTable( : , 1) < energyBands(bandNumber , 2));
    end
    [energyPeakNumbers, correspondingBandNumbers] = find(bandPeakIndex);
    undefEnergyIndex = ~any(bandPeakIndex, 1);
    
    % Mark peaks in the peak table
    % Energy peak tag: 2
    energyPeakTag = 2;
    peakTable(energyPeakNumbers, 5) = energyPeakTag;
    
    % Increase peak prominences by energy bump prominences
    peakTable(energyPeakNumbers, 3) = peakTable(energyPeakNumbers, 3) .* power(10, energyLogProminences(correspondingBandNumbers) / 20);
    peakTable(energyPeakNumbers, 4) = peakTable(energyPeakNumbers, 4) + energyLogProminences(correspondingBandNumbers);
    
    if nnz(undefEnergyIndex)
        
        % Add undefined energy bump bands to the peak table
        undefEnergyFrequencies = energyFrequencies(undefEnergyIndex);
%         undefEnergyPositions = energyPositions(undefEnergyIndex);
        undefEnergyLogAmplitudes = energyLogAmplitudes(undefEnergyIndex);
        undefEnergyDirAmplitudes = baseValue * power(10, undefEnergyLogAmplitudes / 20);
        undefEnergyLogProminences = energyLogProminences(undefEnergyIndex);
        undefEnergyDirProminences = baseValue * power(10, undefEnergyLogAmplitudes / 20) - ...
            baseValue * power(10, (undefEnergyLogAmplitudes - undefEnergyLogProminences) / 20);
        undefEnergyTags = ones(size(undefEnergyFrequencies)) * energyPeakTag;
        
        fullPeakTable( : , 1) = [peakTable( : , 1); undefEnergyFrequencies];
        fullPeakTable( : , 2) = [peakTable( : , 2); undefEnergyDirAmplitudes];
        fullPeakTable( : , 3) = [peakTable( : , 3); undefEnergyDirProminences];
        fullPeakTable( : , 4) = [peakTable( : , 4); undefEnergyLogProminences];
        fullPeakTable( : , 5) = [peakTable( : , 5); undefEnergyTags];
        peakTable = fullPeakTable;
    end
    
    %% ___________________________ PLOTTING ___________________________ %% 
    
    if str2double(config.plotEnable)
        
        % Get parameters
        plotVisible = config.plotVisible;
        sizeUnits = config.plots.sizeUnits;
        imageSize = str2num(config.plots.imageSize);
        
        % __________ Plot the logarithmic spectrum and levels __________ %
        figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
        hold on;
        plot(frequencies, logSpectrum, ...
            'DisplayName', 'Log spectrum');
        plot(frequencies, rmsLevels, ...
            'DisplayName', 'Log RMS level');
        stem(frequencies(samplePoints), correspondingLevels, ...
            'LineStyle', 'none', 'LineWidth', 1, ...
            'Marker', '.', 'MarkerSize', 10, 'MarkerEdgeColor', [1 0 0],...
            'DisplayName', 'Frame RMS values');
        hold off;
        grid on;
        % Figure title, labels, legend
        title('Frames levels');
        xlabel('Frequency, Hz');
        ylabel('Amplitude, dB');
        legend('show', 'Location', 'northwest');
        % Close figure with visibility off
        if strcmpi(plotVisible, 'off')
            close
        end
        
        % ____ Plot the normilized logarithmic spectrum and levels _____ %
        figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
        hold on;
        plot(frequencies, peaksSpectrum, ...
            'DisplayName', 'Peaks levels');
        plot(frequencies, ones(size(peaksSpectrum)) * normalizingLevel, ...
            'DisplayName', ['Normalizing level: ', num2str(rmsFactor), ' * rmsLevel + ', num2str(cutoffLevel), ' dB']);
        hold off;
        grid on;
        % Figure title, labels, legend
        title('Peaks levels');
        xlabel('Frequency, Hz');
        ylabel('Amplitude, dB');
        legend('show', 'Location', 'northwest');
        % Close figure with visibility off
        if strcmpi(plotVisible, 'off')
            close
        end
        
        % _____________ Plot the cut logarithmic spectrum ______________ %
        figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
        hold on;
        stem(peakTable( : , 1), peakTable( : , 4), ...
            'LineStyle', '-', 'Marker', 'x', ...
            'DisplayName', 'Peaks');
        stem(peakTable((peakTable( : , 5) == 2), 1), peakTable((peakTable( : , 5) == 2), 4), ...
            'LineStyle', 'none', 'Marker', 'o', ...
            'DisplayName', 'Energy peaks');
        plot(frequencies, cutPeaksSpectrum, ...
            'DisplayName', 'Normalized peaks levels');
        hold off;
        grid on;
        % Figure title, labels, legend
        title('Normalized peaks levels');
        xlabel('Frequency, Hz');
        ylabel('Amplitude, dB');
        legend('show', 'Location', 'northwest');
        % Close figure with visibility off
        if strcmpi(plotVisible, 'off')
            close
        end
    end
    
end
