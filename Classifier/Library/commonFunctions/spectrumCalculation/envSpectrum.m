% ENVSPECTRUM function calculate direct and envelope spectrum of the signal
% Oprional: spectrum averaging and interpolation
% 
% Developer : ASLM
% Date      : 01/07/2017
function [ SpectrumStruct, EnvSpectrumStruct, frequencyVector, df, imageName ] = ...
    envSpectrum( File, Config, Translations, signalType, modeTimeFrequency )
if nargin < 5
    modeTimeFrequency = 0;
end

if nargin < 3
    Config = [];
    Translations = [];
end

%% _______________________ DEFAULT_PARAMETERS  ________________________ %%

Config = fill_struct(Config, 'Rp', '1');
Config = fill_struct(Config, 'Rs', '10');
Config = fill_struct(Config, 'filterType', 'BPF');
Config = fill_struct(Config, 'lowFreq', '500'); % envelopeSpectrum low Frequency [Hz]
Config = fill_struct(Config, 'highFreq', '5000'); % envelopeSpectrum high Frequency [Hz]
Config = fill_struct(Config, 'spectrumRange', '0:5000'); % direct spectrum frequency range [Hz]

Config = fill_struct(Config, 'averagingEnable', '1');
Config = fill_struct(Config, 'secPerFrame', '10');
Config = fill_struct(Config, 'interpolationEnable', '1');

Config = fill_struct(Config, 'plotEnable', '0');
Config = fill_struct(Config, 'printPlotsEnable', '0');
Config = fill_struct(Config, 'plotVisible', 'off');
Config = fill_struct(Config, 'plotTitle', 'on');
Config = fill_struct(Config, 'parpoolEnable', '0');

Config = fill_struct(Config, 'highFrequencyDevice', '22000'); % device high frequency

plotEnable = str2double(Config.plotEnable);
plotVisible = Config.plotVisible;
plotTitle = Config.plotTitle;
printPlotsEnable = str2double(Config.printPlotsEnable);
parpoolEnable = str2double(Config.parpoolEnable);

%% ___________________ MAIN_CALCULATIONS ______________________________ %%

% Direct Spectrum paramters
[ ~, highFrequency ] = strtok(Config.spectrumRange,':');
highFrequency = str2double(highFrequency(2:end));

% Envelope Spectrum parameters
lowFrequencyEnvelope = str2double(Config.lowFreq);
highFrequencyEnvelope = str2double(Config.highFreq);
Rp = str2double(Config.Rp);
Rs = str2double(Config.Rs);

filterType = Config.filterType;

%% ___________________________ Read signal ___________________________ %%

signal = File.signal;
Fs = File.Fs;

[signalLength,~]=size(signal);
dt=1/Fs;
df=Fs/signalLength;
tmax=dt*(signalLength-1);
time=0:dt:tmax;

%% ____________________ Filtration ____________________________________ %%
if modeTimeFrequency == 0
    switch(filterType)
        case 'BPF' % Band-Pass Filter
            Wp = [lowFrequencyEnvelope*2/Fs highFrequencyEnvelope*2/Fs];
            Ws=[(lowFrequencyEnvelope-0.1*lowFrequencyEnvelope)*2/Fs (highFrequencyEnvelope+0.1*highFrequencyEnvelope)*2/Fs]; 
        case 'LPF'
            % Low-Pass Filter
            Wp = highFrequencyEnvelope*2/Fs;
            Ws = (highFrequencyEnvelope+100)*2/Fs; 
        case 'HPF'
            Ws = lowFrequencyEnvelope*2/Fs;
            Wp = (lowFrequencyEnvelope*2)*2/Fs; 
    end

    [~,Wn1] = buttord(Wp,Ws,Rp,Rs);   
    [b1,a1] = butter(2 ,Wn1);
    
    filteredSignal = filtfilt(b1,a1,signal);
else
    filteredSignal = File.filteredSignal;
end



%% _________________ Calculate envelope spectrum ______________________ %%
% Calculating average or regural spectrum
if str2double(Config.averagingEnable)
    
    % Calcule the number of frames for averaging
    frameLength = floor(str2double(Config.secPerFrame)/dt);
    if frameLength > signalLength       
        frameLength = signalLength;
    end
    framesNumber = floor(signalLength/frameLength);
    df = Fs/frameLength;
    frequency = 0:df:Fs-df;
    dfOriginal = df;
    fVectorOriginal = frequency;
    
    % Direct Spectrum Calculation
    signal = signal(1:frameLength*framesNumber,1);
    time = time(1,1:frameLength*framesNumber);
    signalFrames = reshape(signal,[],framesNumber);
    spectrumFrames = abs(fft(signalFrames))/frameLength;
    spectrum = sum(spectrumFrames,2)/framesNumber;

    % Envelope Spectrum Calculation
    filteredSignal = filteredSignal(1:frameLength*framesNumber,1);
    filteredSignalFrames = reshape(filteredSignal,[],framesNumber);
    
    if modeTimeFrequency == 0
        envelopeSignalFrames = abs(hilbert(filteredSignalFrames));
    else
        envelopeSignalFrames = envelope(filteredSignalFrames);
    end
    envelopeSpectrumFrames = abs(fft(envelopeSignalFrames))/frameLength;
    envelopeSpectrum = sum(envelopeSpectrumFrames,2)/framesNumber;
    envelopeSpectrumOrigin = envelopeSpectrum;
    
    if str2double(Config.interpolationEnable) == 1
        % Spectra spline interpolation
        interpolationFactor = framesNumber;
        if interpolationFactor > 1

            % Original data vectors
            spectrumOrigin = spectrum;
            frequenciesOrigin = frequency;
            lengthOrigin = length(spectrumOrigin);
            arrayOrigin = 1:lengthOrigin;
            arrayInterp = 1:1/interpolationFactor:lengthOrigin;

            % Spline interpolation
            spectrum = interp1( arrayOrigin, spectrumOrigin, arrayInterp, 'spline')';
            envelopeSpectrum = interp1( arrayOrigin, envelopeSpectrumOrigin, arrayInterp, 'spline')';
            frequency = interp1( arrayOrigin, frequenciesOrigin, arrayInterp, 'spline');
            df = df/interpolationFactor;
        end
    end
else % Averaging is not used
    dfOriginal = df;
    frequency=0:df:Fs-df;
    fVectorOriginal = frequency;
    spectrum = abs(fft(signal))/signalLength';
    if modeTimeFrequency == 0
        envelopeSignal = hilbert(abs(filteredSignal));
    else
        envelopeSignal = envelope(filteredSignal);
    end
    envelopeSpectrum = abs(fft(envelopeSignal))/signalLength;
    envelopeSpectrum(1:3, 1) = rms(envelopeSpectrum(4:ceil(highFrequencyEnvelope/df), 1));
    envelopeSpectrumOrigin = envelopeSpectrum;
end

% Cut spectrum to the highFrequency
oneSideFactor = 2;
maxFrequency = min([str2double(Config.highFrequencyDevice),highFrequency]);
maxFrequencyPosition = round(maxFrequency/df);
spectrum = spectrum(1 : maxFrequencyPosition)*oneSideFactor;
envelopeSpectrum = envelopeSpectrum(1 : maxFrequencyPosition)*oneSideFactor;
frequency = frequency(1 : maxFrequencyPosition)';

highFrequencyPositionOrigin = round(maxFrequency/dfOriginal);
SpectrumStruct.amplitude = spectrum;
EnvSpectrumStruct.amplitude = envelopeSpectrum;
EnvSpectrumStruct.amplitudeOrigin = envelopeSpectrumOrigin(1 : highFrequencyPositionOrigin)*oneSideFactor;
EnvSpectrumStruct.frequencyVectorOriginal = fVectorOriginal(1 : highFrequencyPositionOrigin)';
frequencyVector = frequency;


coefType = upperCase(signalType,'first');

% Find all peaks in spectrum and fill table
Data = [];
Data.Fs = Fs;
Data.signal = spectrum;

% Find all peaks in spectrum envelope and fill table
Data = [];
Data.Fs = Fs;
Data.signal = envelopeSpectrum;

%% _______________________ PLOT_RESULTS ______________________________ %%

switch(signalType)
    case 'acceleration'
        shortSignalType = 'acc';
        units = Translations.acceleration.Attributes.value;
        signalTypeTranslation = Translations.acceleration.Attributes.name;
    case 'velocity'
        shortSignalType = 'vel';
        units = Translations.velocity.Attributes.value;
        signalTypeTranslation = Translations.velocity.Attributes.name;
    case 'displacement'
        shortSignalType = 'disp';
        units = Translations.displacement.Attributes.value;
        signalTypeTranslation = Translations.displacement.Attributes.name;
    otherwise
        shortSignalType = 'acc';
        units = Translations.acceleration.Attributes.value;
        signalTypeTranslation = Translations.acceleration.Attributes.name;
end

if plotEnable == 1
    
    % Get plot parameters
    sizeUnits = Config.plots.sizeUnits;
    imageSize = str2num(Config.plots.imageSize);
    fontSize = str2double(Config.plots.fontSize);
    imageFormat = Config.plots.imageFormat;
    imageQuality = Config.plots.imageQuality;
    imageResolution = Config.plots.imageResolution;
    
    % Form data to print
    yData = { signal; spectrum; envelopeSpectrum; };
    xData = { time; frequency; frequency };
    
    xLabel = {
        [upperCase(Translations.time.Attributes.name, 'first'), ', ', upperCase(Translations.time.Attributes.value, 'first')];
        [upperCase(Translations.frequency.Attributes.name, 'first'), ', ', upperCase(Translations.frequency.Attributes.value, 'first')];
        [upperCase(Translations.frequency.Attributes.name, 'first'), ', ', upperCase(Translations.frequency.Attributes.value, 'first')];
        };
    
    yLabel = [upperCase(Translations.magnitude.Attributes.name, 'first'), ', ', units];
    
    max_frequency = {
        0;
        highFrequency;
        highFrequency
        };
    
    imageType = {
        'signal';
        'spectrum';
        'envelopeSpectrum';
        };
    
    imageTitle = {
        [upperCase(Translations.signal.Attributes.name, 'first'), ' - ', upperCase(signalTypeTranslation, 'first')];
        [upperCase(Translations.spectrum.Attributes.name, 'first'), ' - ', upperCase(signalTypeTranslation, 'first')];
        [upperCase(Translations.envelopeSpectrum.Attributes.name, 'allFirst'), ' - ', upperCase(signalTypeTranslation, 'first')];
        };
    
	imageName = cellfun(@(x) strcat(x, '-', shortSignalType, '-1'), imageType, 'UniformOutput', false);
    
    xMargin = repmat({floor(highFrequency/df)}, size(imageType));
    scale = 1.2;
    yMargin = cellfun(@(x,y) max(abs(x(100 : y, 1)) * scale), yData, xMargin);
    yMargin(1,1) =  max(abs(yData{1,1}))* scale;
    
    switch(shortSignalType)
        case {'vel', 'disp'}
            imagesNumber = 2;
        otherwise
            imagesNumber = 3;
    end
    
    imageName = imageName(1 : 1 : imagesNumber);
    
    % Plot and (or) print images of the signal and it spectum
    if parpoolEnable
        parfor i = 1 : 1 : imagesNumber
            
            % Plot
            myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
            plot(xData{i}, yData{i});
            grid on;
            
            % Get axes data
            myAxes = myFigure.CurrentAxes;
            % Set axes font size
            myAxes.FontSize = fontSize;
            
            % Axes title
            if strcmp(plotTitle, 'on')
                title(myAxes, imageTitle{i});
            end
            % Axes labels
            xlabel(myAxes, xLabel{i});
            ylabel(myAxes, yLabel);
            
            % Set axes limits
            switch(imageType{i})
                case 'signal'
                    ylim(myAxes, [-yMargin(i) yMargin(i)]);
                otherwise
                    xlim(myAxes, [0 max_frequency{i}]);
                    ylim(myAxes, [0 yMargin(i)]);
            end
            
            if printPlotsEnable == 1
                % Save the image to the @Out directory
                fullFileName = fullfile(pwd, 'Out', imageName{i});
                print(fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
            end
            
            % Close figure with visibility off
            if strcmpi(plotVisible, 'off')
                close(myFigure)
            end
        end
    else
        for i = 1 : 1 : imagesNumber
            
            % Plot
            myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
            plot(xData{i}, yData{i});
            grid on;
            
            % Get axes data
            myAxes = myFigure.CurrentAxes;
            % Set axes font size
            myAxes.FontSize = fontSize;
            
            % Axes title
            if strcmp(plotTitle, 'on')
                title(myAxes, imageTitle{i});
            end
            % Axes labels
            xlabel(myAxes, xLabel{i});
            ylabel(myAxes, yLabel);
            
            % Set axes limits
            switch(imageType{i})
                case 'signal'
                    ylim(myAxes, [-yMargin(i) yMargin(i)]);
                otherwise
                    xlim(myAxes, [0 max_frequency{i}]);
                    ylim(myAxes, [0 yMargin(i)]);
            end
            
            if printPlotsEnable == 1
                % Save the image to the @Out directory
                fullFileName = fullfile(pwd, 'Out', imageName{i});
                print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
            end
            
            % Close figure with visibility off
            if strcmpi(plotVisible, 'off')
                close(myFigure)
            end
        end
    end
else
    imageName = [];
end


