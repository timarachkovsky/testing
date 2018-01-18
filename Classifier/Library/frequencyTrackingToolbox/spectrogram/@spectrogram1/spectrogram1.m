classdef spectrogram1
    %SPECTROGRAM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        config % Configuration structure
        
    % Plot Parameters:
        parpoolEnable
        plotEnable
        plotVisible
        plotTitle
        printPlotsEnable
        debugModeEnable
        
    % Spectrogram Parameters:
        secPerFrame
        secOverlap
        lowFrequency
        highFrequency
        
        interpolationFactor
        
        tag
    % Output:
        coefficients
        time
        frequencies
    end
    
    methods
        
        % Constuctor method
        function [mySpectrogram] = spectrogram1( config )
            
            if nargin == 0
               warning('There is no config structure for spectrogram initialization!')
               config = [];
            end
            
            config = fill_struct(config, 'parpoolEnable', '0');
            config = fill_struct(config, 'plotEnable', '0');
            config = fill_struct(config, 'plotVisible', 'off');
            config = fill_struct(config, 'plotTitle', 'on');
            config = fill_struct(config, 'printPlotsEnable', '0');
            config = fill_struct(config, 'debugModeEnable', '0');
            
            config = fill_struct(config, 'secPerFrame', '0');
            config = fill_struct(config, 'secOverlap', '0');
            config = fill_struct(config, 'lowFrequency', '0');
            config = fill_struct(config, 'highFrequency', '0');
            
            config = fill_struct(config, 'interpolationFactor', '1000');
            
            mySpectrogram.config = config;
            mySpectrogram.parpoolEnable = str2double(config.parpoolEnable);
            mySpectrogram.plotEnable = str2double(config.plotEnable);
            mySpectrogram.plotVisible = config.plotVisible;
            mySpectrogram.plotTitle = config.plotTitle;
            mySpectrogram.printPlotsEnable = str2double(config.printPlotsEnable);
            mySpectrogram.debugModeEnable = str2double(config.debugModeEnable);
        
            % 
            mySpectrogram.secPerFrame = str2double(config.secPerFrame);
            mySpectrogram.secOverlap = str2double(config.secOverlap);
            mySpectrogram.lowFrequency = str2double(config.lowFrequency);
            mySpectrogram.highFrequency = str2double(config.highFrequency);
            
            mySpectrogram.interpolationFactor = str2double(config.interpolationFactor);
            
            mySpectrogram.tag = 'NORM-acc';
            
        end
        
        
        function [mySpectrogram] = create(mySpectrogram, file)
            
            if nargin == 1
               error('There is no signal for spectrogram calculation'); 
            end
            % INPUT:
            Fs = file.Fs;
            timeWindow = Fs*mySpectrogram.secPerFrame;
            timeOverlap = Fs*mySpectrogram.secOverlap;
            
            % CALCULATION:

            [signal] = prepareSignal(mySpectrogram, file);
            [myFrequencies] = prepareFrequencies(mySpectrogram, file);
            [myCoefficients,~,myTime] = spectrogram(signal,kaiser(timeWindow,5),timeOverlap,myFrequencies, Fs);
            myCoefficients = abs(myCoefficients);
            
            % OUTPUT:
            mySpectrogram.coefficients = myCoefficients;
            mySpectrogram.time = myTime;
            mySpectrogram.frequencies = myFrequencies;
            
        end
        
        function [signal] = prepareSignal(mySpectrogram, file)
            
            signal = file.signal;
            
        end
        
        function [myFrequencies] = prepareFrequencies(mySpectrogram, file)
            
            Fs = file.Fs;
            signal = file.signal;
            myLowFrequency = mySpectrogram.lowFrequency;
            myHighFrequency = mySpectrogram.highFrequency;
            
            df = Fs/size(signal,1);
            myFrequencies = myLowFrequency:df:myHighFrequency;
            
        end
        
        % Interpolate frequencies and coefficients
        function [mySpectrogram] = interpolate(mySpectrogram)
            
            % INPUT:
            coefficientsOrigin = mySpectrogram.coefficients;
            frequenciesOrigin = mySpectrogram.frequencies;
            myInterpolationFactor = mySpectrogram.interpolationFactor;

            
            % CALCULATION:
            arrayLength = length(frequenciesOrigin);
            arrayOrigin = 1:arrayLength;
            arrayInterp = 1:1/myInterpolationFactor:arrayLength;

            % Main properties spline interpolation
            frequenciesInterp = interp1( arrayOrigin, frequenciesOrigin, arrayInterp, 'spline')';

            coefficientsInterp = cell(size(coefficientsOrigin,2),1);
            for i = 1:size(coefficientsOrigin,2)
                coefficientsInterp{i} = interp1( arrayOrigin, coefficientsOrigin(:,i), arrayInterp, 'spline');
            end
            coefficientsInterp = cell2mat(coefficientsInterp)';
            
            
            % OUTPUT:
            mySpectrogram.frequencies = frequenciesInterp;
            mySpectrogram.coefficients = coefficientsInterp;
            
        end
       
        
        function plotAndPrint(mySpectrogram)
            
            % INPUT:
                Config = mySpectrogram.config;
                sizeUnits = Config.plots.sizeUnits;
                imageSize = str2num(Config.plots.imageSize);
                fontSize = str2double(Config.plots.fontSize);
                imageFormat = Config.plots.imageFormat;
                imageQuality = Config.plots.imageQuality;
                imageResolution = Config.plots.imageResolution;

                Translations = Config.translations;
            
                myTime = mySpectrogram.time;
                myFrequencies = mySpectrogram.frequencies;
                myCoefficients = mySpectrogram.coefficients;
            % PLOT:

                myFigure = figure(  'Units', sizeUnits, 'Position', imageSize,...
                                    'Visible', mySpectrogram.plotVisible,....
                                    'Color', 'w');
                                
                imagesc(myTime,myFrequencies,myCoefficients);

                myAxes = myFigure.CurrentAxes;
                myAxes.FontSize = fontSize;

                if strcmp(mySpectrogram.plotTitle, 'on')
                    title(myAxes, [upperCase(Translations.spectrogram.Attributes.name,'first'),' ', mySpectrogram.tag]);
                end

                xlabel(myAxes, [upperCase(Translations.time.Attributes.name, 'first'), ', ', ...
                                upperCase(Translations.time.Attributes.value, 'first')]);
                
                switch(mySpectrogram.tag)
                    case {'LOG-acc','LOG-env'}
                        ylabel(myAxes, [upperCase(Translations.logarithm.Attributes.shortName, 'first'),' ',...
                                        upperCase(Translations.frequency.Attributes.name, 'first'), ', ',...
                                                  Translations.logarithm.Attributes.shortName, '(',...
                                        upperCase(Translations.frequency.Attributes.value,'first'), ')']);
                    otherwise
                        ylabel(myAxes, [upperCase(Translations.frequency.Attributes.name, 'first'), ', ',...
                                        upperCase(Translations.frequency.Attributes.value,'first')]);
                end

                
                % Calibrate colorbar 
                caxis(caxis.*0.5);

                if mySpectrogram.printPlotsEnable
                    % Save the image to the @Out directory
                    imageNumber = '1';
                    fileName = ['spectrogram-',mySpectrogram.tag, '-', imageNumber];
                    fullFileName = fullfile(pwd, 'Out', fileName);
                    print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
                end
                
                % Close figure with visibility off
                if strcmpi(mySpectrogram.plotVisible, 'off')
                    close(myFigure)
                end
            
        end
   
    end
    

end

