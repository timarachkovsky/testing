function [ signalNew ] = adaptFiltration( file, config )
%ADAPTFILTRATION Summary of this function goes here
%   Detailed explanation goes here

    % Check the input data
    if nargin < 1
        config = [];
    end

    % Fill empty fields
%     config = fill_struct(config, 'frameLength', '20000');
%     config = fill_struct(config, 'frameLength', '100');
%     config = fill_struct(config, 'cutoffLevel', '0');
    
    config = fill_struct(config, 'plotEnable', '0');
    config = fill_struct(config, 'filteringType', 'rough'); % rough/accurate
    config = fill_struct(config, 'rmsFactor', '2');
    
    switch(config.filteringType)
        case 'rough'
            config.cutoffLevel = -3;
            config.frameLength = 10000;
        case 'accurate'
            config.cutoffLevel = 0;
            config.frameLength = 100; 
    end
    %% ____________________ CALCULATION ____________________________________ %%
    
    signalLength = length(file.signal);
    if mod(signalLength,2)
        isEven = 0;
        halfPoint = (signalLength+1)/2;
    else
        isEven = 1;
        halfPoint = signalLength/2;
    end
    
    spectrum = fft(file.signal);
    spectrum = spectrum(1:halfPoint,1);
    amplSpectrum = abs(spectrum);
    phaseSpectrum = angle(spectrum);
    
    % Get main data
    Fs = file.Fs;
    df = Fs/length(file.signal);
%     frequencies = (0:df:Fs-df)';
    frequencies = (0:df:Fs/2-df)';
    
    % Get the spectrum on a logarithmic scale
    % baseValue = str2double(config.baseValue);

    baseValue = 1e-6; % [m/s^2]
    logSpectrum = abs(20 * log10(amplSpectrum / baseValue));

    % Calculate the number of samples in the frame
%     frameLength = str2double(config.frameLength);
    frameLength = config.frameLength;
    frameSamplesNumber = floor(frameLength / df);
    % Calculate the number of frames
    framesNumber = floor(length(logSpectrum) / frameSamplesNumber);
    % Cut spectrum and frequencies to the end value of the last frame
    frameLogSpectrum = logSpectrum(1 : framesNumber * frameSamplesNumber, 1);
    frameFrequencies = frequencies(1 : length(frameLogSpectrum));

    % Calculate the rms value in each frame
    levels = rms(reshape(frameLogSpectrum, [], framesNumber));
    % The first level - the rms value of the first half of the first frame
    firstLevel = rms(frameLogSpectrum(1 : floor(frameSamplesNumber / 2)));
    % The last level - the rms value of the last half of the last frame
    lastLevel = rms(frameLogSpectrum(end - floor(frameSamplesNumber / 2) : end));
    % Count the number of samples before and after the interpilation
    % The number of levels without the first level
    levelsNumber = length(levels);
    % Interpolation step for add values
    interpStep = 1 / frameSamplesNumber;
    samplePoints = [0.5 + interpStep, 1 : 1 : levelsNumber, levelsNumber + 0.5];
    queryPoints = 0.5 + interpStep : interpStep : levelsNumber + 0.5;
    
    correspondingValues = [firstLevel, levels, lastLevel];
    % Spline interpolation
    interpLevels( : , 1) = interp1(samplePoints, correspondingValues, queryPoints, 'spline');

    % Insert values cut the last frame
    rmsLevels = [interpLevels; logSpectrum(length(frameLogSpectrum) + 1 : end)];
    
    peaksSpectrum = logSpectrum - rmsLevels;

% Cut noise level
cutPeaksSpectrum = peaksSpectrum;
% Normalization level
rmsFactor = str2double(config.rmsFactor);
% cutoffLevel = str2double(config.cutoffLevel);
cutoffLevel = config.cutoffLevel;
normalizeLevel = rms(peaksSpectrum) * rmsFactor + cutoffLevel;
% Points of values less than the normalization level
cropPoints = peaksSpectrum < normalizeLevel;
% Cut values less than the normalization level
cutPeaksSpectrum(cropPoints) = normalizeLevel;
% Normalize by the normalization level
cutPeaksSpectrum = cutPeaksSpectrum - normalizeLevel;

% Calculate overall noise level of logarithmic spectrum

logNoiseLevel = rms(logSpectrum(frequencies <= 10000));

% Calculate vector of noise level of logarithmic spectrum
logNoiseLevelVector = rmsLevels + ones(size(peaksSpectrum, 1), 1) * normalizeLevel;

% Calculate vector of noise level of input signal
noiseLevelVector = baseValue * power(10, logNoiseLevelVector / 20);
    
    
    %% --------------------------------------------------------------- %%
    
%     [logNoiseLevel, pos1] = min(logNoiseLevelVector); 
    
    % Restore amplitude spectrum
   
    
%     amplSpectrumDenoise = baseValue * power(10, logSpectrumDenoise / 20)*gainFactor;
%     noiseLevel = baseValue * power(10, logNoiseLevel / 20);
%     noiseLevelVector = ones(size(amplSpectrum))*noiseLevel;

%     amplSpectrumDenoised = baseValue * power(10, logSpectrumDenoised / 20);
    amplSpectrumCutoff= amplSpectrum - noiseLevelVector;
    
    [amplOrigin, pos] = findpeaks(amplSpectrum, 'NPeaks',1,'SortStr','descend');
    amplCurrent = amplSpectrumCutoff(pos,1);
    divVector = amplOrigin./amplCurrent;
    gainFactor = mean(divVector);
    
    amplSpectrumDenoised = amplSpectrumCutoff * gainFactor;
    amplSpectrumDenoised ( amplSpectrumDenoised < 0) = 0;
    
    
    %% Time-domain signal restoring
    if isEven 
        amplSpectrumNew = [amplSpectrumDenoised;fliplr(amplSpectrumDenoised)];
        phaseSpectrumNew = [phaseSpectrum;fliplr(phaseSpectrum)];
    else
        amplSpectrumNew = [amplSpectrumDenoised;fliplr(amplSpectrumDenoised(1:halfPoint-1,1))];
        phaseSpectrumNew = [phaseSpectrum;fliplr(phaseSpectrum(1:halfPoint-1,1))];
    end
    
%     ynew(fixfreq(k))=ampnew(k)*(cos(phase(fixfreq(k)))+i*sin(phase(fixfreq(k))));
    spectrumNew = amplSpectrumNew.*(cos(phaseSpectrumNew)+1i*sin(phaseSpectrumNew));
    signalNew = ifft(spectrumNew,'symmetric');

    %% ____________________ PLOTTING _______________________________________ %% 

    if str2double(config.plotEnable)
        % Plot logarithmic spectrum and rms level
        figure;
        title('Rms frame level');
        hold on;
        grid on;
        plot(frequencies, logSpectrum, ...
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
        
        % Close figure with visibility off
        if strcmpi(config.plotVisible, 'off')
            close
        end

        % Plot normilize logarithmic spectrum and normilize level
        figure;
        title('Spectrum Denoising');
        hold on;
        grid on;
        plot(frequencies, amplSpectrum/length(spectrum), 'DisplayName', 'Original Spectrum');
        plot(frequencies,amplSpectrumDenoised/length(spectrum), 'DisplayName', 'Denoised Spectrum');
        xlabel('Frequency, Hz');
        ylabel('Amplitude, m/s^2');
        xlim([0 Fs/2 + 1]);
        hold off;
        
        % Close figure with visibility off
        if strcmpi(config.plotVisible, 'off')
            close
        end

    end




end

