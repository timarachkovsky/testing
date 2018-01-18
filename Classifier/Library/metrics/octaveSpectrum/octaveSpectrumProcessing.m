% Developer : ASLM
% Date      : 21/12/2016
% Version   : v1.0
% 

% OCTAVESPECTRUMPROCESSING function build octave-based spectrum and sets
% the thresholds for each frequency band
function [ result ] = octaveSpectrumProcessing( file, config, Translations )

if nargin < 2
   config = [];
end

iLoger = loger.getInstance;

%% __________________ Default Parameters ______________________________ %%

config = fill_struct(config, 'filterMode', '1/3 octave');
config = fill_struct(config, 'warningLevel', '');
config = fill_struct(config, 'damageLevel', '');

config = fill_struct(config, 'plotEnable', '0');
config = fill_struct(config, 'printPlotsEnable', '0');
config = fill_struct(config, 'plotVisible', 'off');
config = fill_struct(config, 'plotTitle', 'on');

% Vector of threshold for octave spectrum band magnitudes
warningLevel = str2num(config.warningLevel);
damageLevel = str2num(config.damageLevel);

plotEnable = str2double(config.plotEnable);
printPlotsEnable = str2double(config.printPlotsEnable);
plotVisible = config.plotVisible;
plotTitle = config.plotTitle;
historyEnable = str2double(config.historyEnable);

sizeUnits = config.plots.sizeUnits;
imageSize = str2num(config.plots.imageSize);
fontSize = str2double(config.plots.fontSize);
imageFormat = config.plots.imageFormat;
imageQuality = config.plots.imageQuality;
imageResolution = config.plots.imageResolution;

%% ____________________ Main Calculations _____________________________ %%

[myOctaveSpectrum] = octaveSpectrum(file, config);

% Calculate status for each octave (normal, warning, damage) 
if ~isempty(damageLevel) && ~isempty(warningLevel)
    if length(myOctaveSpectrum.amplitude) ~= length(warningLevel) || ...
            length(myOctaveSpectrum.amplitude) ~= length(damageLevel) ||...
            length(warningLevel) ~= length(damageLevel)
        warningLevel = ones(1,length(myOctaveSpectrum.amplitude))*mean(warningLevel);
        damageLevel = ones(1,length(myOctaveSpectrum.amplitude))*mean(damageLevel);

        iLoger = loger.getInstance;
        printComputeInfo(iLoger, 'Octave spectrum method', 'Wrong exhibited thresholds!!!');
    end
    warningPositions = (myOctaveSpectrum.amplitude < damageLevel) & (myOctaveSpectrum.amplitude >= warningLevel);
    damagePositions = (myOctaveSpectrum.amplitude >= damageLevel);

    status(1,1:length(myOctaveSpectrum.amplitude)) = {'GREEN'};
    status(1,warningPositions) = {'ORANGE'}; 
    status(1,damagePositions) = {'RED'};
else
    status = [];
    warningPositions = [];
    damagePositions = [];
end
result = myOctaveSpectrum;
result.status = status;

% Print Results
if str2double(config.octaveSpectrumEnable)
    if plotEnable
        
        spectrum(1, : ) = myOctaveSpectrum.amplitude;
        
        if nnz(warningPositions) ~= 0
            spectrum(1, warningPositions) = warningLevel(1, warningPositions);
            spectrum(2, warningPositions) = myOctaveSpectrum.amplitude(1, warningPositions) - warningLevel(1, warningPositions);
        end
        if nnz(damagePositions) ~= 0
            spectrum(1, damagePositions) = warningLevel(1, damagePositions);
            spectrum(2, damagePositions) = damageLevel(1, damagePositions) - warningLevel(1, damagePositions);
            spectrum(3, damagePositions) = myOctaveSpectrum.amplitude(1, damagePositions) - damageLevel(1, damagePositions);
        end
        
        % Plot
        myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
        myBar = bar(spectrum', 'stacked');
        if length(myBar) == 1
            myBar(1).FaceColor = [0 1 0];
        elseif length(myBar) == 2
            myBar(1).FaceColor = [0 1 0];
            myBar(2).FaceColor = [1 1 0];
        elseif length(myBar) == 3
            myBar(1).FaceColor = [0 1 0];
            myBar(2).FaceColor = [1 1 0];
            myBar(3).FaceColor = [1 0 0];
        end
        grid on;
        
        % Get axes data
        myAxes = myFigure.CurrentAxes;
        % Set axes font size
        myAxes.FontSize = fontSize;
        
        % Figure title
        if strcmp(plotTitle, 'on')
            title(myAxes, [strtok(config.filterMode), ' ', upperCase(Translations.octaveSpectrum.Attributes.name, 'allFirst')]);
        end
        % Figure labels
        xlabel(myAxes, [upperCase(Translations.centralFrequency.Attributes.name, 'first'), ', ', upperCase(Translations.frequency.Attributes.value, 'first')]);
        ylabel(myAxes, [upperCase(Translations.magnitude.Attributes.name, 'first'), ', ', Translations.acceleration.Attributes.value]);
        % Replace the x-axis values by the central frequencies
        xticks(myAxes, linspace(1, length(myOctaveSpectrum.amplitude), length(myOctaveSpectrum.amplitude)));
        xticklabels(myAxes, round(myOctaveSpectrum.frequencies * 100) / 100);
        xtickangle(myAxes, 90);
        
        if printPlotsEnable && ~historyEnable
            % Save the image to the @Out directory
            imageNumber = '1';
            fileName = ['octaveSpectrum-acc-', imageNumber];
            fullFileName = fullfile(pwd, 'Out', fileName);
            print(myFigure, fullFileName,['-d', imageFormat, imageQuality], ['-r', imageResolution]);
            
            if ~config.parpoolEnable
                if checkImages(fullfile(pwd, 'Out'), fileName, imageFormat)
                    printComputeInfo(iLoger, 'octaveSpectrum', 'The method images were saved.')
                end
            end
        end
        
        % Close figure with visibility off
        if strcmpi(plotVisible, 'off')
            close(myFigure)
        end
    end
end
end

