classdef scalogramHandler
    %SCALOGRAMHANDLER class description goes here ...
    
    properties (Access = private)
        
        % Time-domain signal
        signal
        % Time-domain samples frequency (@Fs)
        Fs
        
        % Configuration structure
        config
        plotEnable
        plotVisible
        printPlotsEnable
        
        translations
        
        iLoger
        
        waveletName
        
        % Scalogram class with @coefficients,@frequencies and @scales 
        % properties
        scalogram 
        scalogramNormalized
        
        result
        % ....
    end
    
    methods (Access = public)
        
        % Constructor class
        function [myScalogramHandler] = scalogramHandler( file, myConfig)
                        
            myScalogramHandler.Fs = file.Fs;
            myScalogramHandler.config = myConfig;
            myScalogramHandler.plotEnable = str2double(myConfig.Attributes.plotEnable);
            myScalogramHandler.plotVisible = myConfig.Attributes.plotVisible;
            myScalogramHandler.printPlotsEnable = str2double(myConfig.Attributes.printPlotsEnable);
            myScalogramHandler.translations = file.translations;
            myScalogramHandler.iLoger = loger.getInstance;
            
            % Cut-off the original signal to speed-up scalogram calculation
            % and evaluation
            if str2double(myConfig.Attributes.shortSignalEnable)
                parameters = [];
                parameters = myConfig.shortSignal.Attributes;
                parameters.mono = myConfig.shortSignal.mono.Attributes;
                parameters.multi = myConfig.shortSignal.multi.Attributes;
                file.signal = createShortSignal(file,parameters);
                myScalogramHandler.signal = file.signal;
            else
                myScalogramHandler.signal = file.signal;
            end
            
            % Scalogram creation
            parameters = [];
            parameters = myConfig.scalogram;
            parameters.Attributes.parpoolEnable = myConfig.Attributes.parpoolEnable;
            parameters.Attributes.printPlotsEnable = myConfig.Attributes.printPlotsEnable;
            parameters.Attributes.plotVisible = myConfig.Attributes.plotVisible;
            parameters.Attributes.plotTitle = myConfig.Attributes.plotTitle;
            parameters.plots = myConfig.plots;
            parameters.sensor = myConfig.sensor;
            
            myScalogramHandler.waveletName = parameters.Attributes.waveletName;
            myScalogramHandler.scalogram = scalogram(file,parameters);
            
            myScalogramHandler.scalogramNormalized = normalizeScalogram(myScalogramHandler.scalogram);
            
            % Plot Normalized Scalogram
            if myScalogramHandler.plotEnable
                
                Translations = myScalogramHandler.translations;
                
                sizeUnits = myScalogramHandler.config.plots.sizeUnits;
                imageSize = str2num(myScalogramHandler.config.plots.imageSize);
                fontSize = str2double(myScalogramHandler.config.plots.fontSize);
                imageFormat = myScalogramHandler.config.plots.imageFormat;
                imageQuality = myScalogramHandler.config.plots.imageQuality;
                imageResolution = myScalogramHandler.config.plots.imageResolution;
                
                factorVector = linspace(0.1, 1, 10);
                thresholds = rms(file.signal) * factorVector;
                frequencies = myScalogramHandler.scalogramNormalized.frequencies;
                
                myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', myScalogramHandler.plotVisible, 'Color', 'w');
                myPlot = plot(frequencies, myScalogramHandler.scalogramNormalized.coefficients, 'LineWidth', 2);
                [myFigure, myArea] = fillArea(myFigure, thresholds);
                grid on;
                
                % Get axes data
                myAxes = myFigure.CurrentAxes;
                % Set axes font size
                myAxes.FontSize = fontSize;
                
                % Figure title
                if strcmp(parameters.Attributes.plotTitle, 'on')
                    title(myAxes, [upperCase(Translations.scalogram.Attributes.name, 'first'), ' - ', ...
                        upperCase(Translations.energyContribution.Attributes.name, 'allFirst')]);
                end
                % Figure labels
                xlabel(myAxes, [upperCase(Translations.frequency.Attributes.name, 'first'), ', ', ...
                    upperCase(Translations.frequency.Attributes.value, 'first')]);
                ylabel(myAxes, [upperCase(Translations.coefficient.Attributes.name, 'first'), ', ', ...
                    Translations.acceleration.Attributes.value]);
                % Figure legend
                legendTicks = cellfun(@(factorValue) strcat('RMS x', num2str(factorValue)), num2cell(factorVector), 'UniformOutput', false);
                legend([myPlot, flip(myArea(1 : length(legendTicks)))], ...
                    [{'Scalogram'}, flip(legendTicks)]);
                
                if myScalogramHandler.printPlotsEnable
                    % Save the image to the @Out directory
                    imageNumber = '1';
                    fileName = ['scalogram-EC-acc-', imageNumber];
                    fullFileName = fullfile(pwd, 'Out', fileName);
                    print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
                    
                    if checkImages(fullfile(pwd, 'Out'), fileName, imageFormat)
                        printComputeInfo(myScalogramHandler.iLoger, 'scalogramHandler', 'The method images were saved.')
                    end
                end
                
                % Close figure with visibility off
                if strcmpi(myScalogramHandler.plotVisible, 'off')
                    close(myFigure)
                end
                
            end
        end
        
        % Getters/Setters ...
        function [mySignal] = getSignal(myScalogramHandler)
            mySignal = myScalogramHandler.signal;
        end
        function [myScalogramHandler] = setSignal(myScalogramHandler, mySignal)
           myScalogramHandler.signal = mySignal; 
        end
        
        function [myFs] = getFs(myScalogramHandler)
            myFs = myScalogramHandler.Fs;
        end
        function [myScalogramHandler] = setFs(myScalogramHandler, myFs)
           myScalogramHandler.Fs = myFs; 
        end
           
        function [myConfig] = getConfig(myScalogramHandler)
            myConfig = myScalogramHandler.config;
        end
        function [myScalogramHandler] = setConfig(myScalogramHandler, myConfig)
           myScalogramHandler.config = myConfig; 
        end
        
        function [myScalogram] = getScalogram(myScalogramHandler)
            myScalogram = myScalogramHandler.scalogram;
        end
        function [myScalogramHandler] = setScalogram(myScalogramHandler, myScalogram)
           myScalogramHandler.scalogram = myScalogram; 
        end
        function [myHistoryScalogram] = getHistoryScalogram(myScalogramHandler)
            myHistoryScalogram = myScalogramHandler.historyScalogram;
        end
        function [myWaveletName] = getWaveletName(myScalogramHandler)
            myWaveletName = myScalogramHandler.waveletName;
        end
        % ... Getters/Setters
        
        % GETMAXCOEFFICIENTS function find the max and true valid peaks on
        % the scalogram graph
        function [scalogramData, fullScalogramData, octaveScalogram] = getDecompositionCoefficients(myScalogramHandler)
            
            % SWD Scalogram
            myScalogram = myScalogramHandler.scalogram;
            [file.coefficients, file.frequencies, file.scales] = getParameters(myScalogram);
            
            file.scalogramConfig = myScalogramHandler.config.scalogram;
            file.translations = myScalogramHandler.translations;
            
            parameters = [];
%             parameters = myScalogramHandler.config.peaksFinder;
            parameters = myScalogramHandler.config.peaksFinder.swdScalogram;
            parameters.Attributes.printPlotsEnable = myScalogramHandler.config.Attributes.printPlotsEnable;
            parameters.Attributes.plotVisible = myScalogramHandler.config.Attributes.plotVisible;
            parameters.Attributes.plotTitle = myScalogramHandler.config.Attributes.plotTitle;
            parameters.plots = myScalogramHandler.config.plots;
            
            myPeaksFinder = peaksFinder(file, parameters, 'SWD');
            [myPeaksFinder] = findPeaks(myPeaksFinder);
            fullScalogramData1 = getFullScalogramData(myPeaksFinder);
            fullScalogramData1 = myScalogramHandler.defineFilterParameters(fullScalogramData1);
            for i = 1 : 1 : length(fullScalogramData1.validPeaks)
                fullScalogramData1.validPeaks(i).energyContribution = 0;
            end
            
            % Normalized Scalogram
            myPeaksFinder = [];
            
            file = [];
            file.coefficients = myScalogramHandler.scalogramNormalized.coefficients;
            file.frequencies = myScalogramHandler.scalogramNormalized.frequencies;
            file.scales = myScalogramHandler.scalogramNormalized.scales;
            file.scalogramConfig = myScalogramHandler.config.scalogram;
            file.translations = myScalogramHandler.translations;
            
            parameters = [];
            parameters = myScalogramHandler.config.peaksFinder.normalizedScalogram;
            parameters.Attributes.printPlotsEnable = myScalogramHandler.config.Attributes.printPlotsEnable;
            parameters.Attributes.plotVisible = myScalogramHandler.config.Attributes.plotVisible;
            parameters.Attributes.plotTitle = myScalogramHandler.config.Attributes.plotTitle;
            parameters.plots = myScalogramHandler.config.plots;
            
            myPeaksFinder = peaksFinder(file, parameters, 'normalized');
            [myPeaksFinder] = findPeaks(myPeaksFinder);
            fullScalogramData2 = getFullScalogramData(myPeaksFinder);
            fullScalogramData2 = myScalogramHandler.defineFilterParameters(fullScalogramData2);
            
            signalRms = rms(myScalogramHandler.signal);
            for i = 1 : 1 : length(fullScalogramData2.validPeaks)
                fullScalogramData2.validPeaks(i).energyContribution = fullScalogramData2.validPeaks(i).coefficients / signalRms;
            end
            
            [scalogramData, fullScalogramData] = myScalogramHandler.mergeResults(fullScalogramData1, fullScalogramData2, signalRms, myScalogramHandler.config);
            
            % Scalogram was divided into banks (for history analysed)
            parameters = myScalogramHandler.config.octaveScalogram.Attributes;
            octaveScalogram = myScalogramHandler.createOctaveScalogram(fullScalogramData, parameters);
        end % function getDecompositionCoefficients
    end
        
    methods (Static = true, Access = private)

        % MERGERESULTS function merges the 2 result from scalogramSWD (with
        % LF-rising) and from scalogrmaNormalized (without any rising) 
        function [ScalogramData, fullScalogramData] = mergeResults(fullSwdScalogramData, fullNormScalogramData, signalRms, myConfig)
            
            switch myConfig.Attributes.scalogramType
                case 'swd'
                    fullScalogramData = fullSwdScalogramData; 
                case 'norm'
                    fullScalogramData = fullNormScalogramData;
                case 'swd+norm'
                    fullScalogramData = fullNormScalogramData;
                    
                    field4merge = {
                                    'scales';
                                    'coefficients';
                                    'height';
                                    'width';
                                    'prominence';
                                    'globality';
                                    'energy';
                                    'energyLabel';
                                    'label';
                                    'validity';
                                    'lowFrequency';
                                    'highFrequency';
                                    };
                    
                    if ~isempty(fullSwdScalogramData.validPeaks)
                        for i = 1:length(fullSwdScalogramData.validPeaks)
                            validSwdFreq(i) = fullSwdScalogramData.validPeaks(i).frequencies;
                        end
                    else
                        validSwdFreq = [];
                    end

                    if ~isempty(fullNormScalogramData.validPeaks)
                        for i = 1:length(fullNormScalogramData.validPeaks)
                            validNormFreq(i) = fullNormScalogramData.validPeaks(i).frequencies;
                        end
                    else
                        validNormFreq = [];
                    end
            

                    % Find common point both in the swd and in the normalized scalogram
                    percentRange = 10;

                    swdFreq = fullSwdScalogramData.frequencies;
                    swdMaskVector = zeros(size(swdFreq));

                    normFreq = fullNormScalogramData.frequencies;
                    normMaskVector = zeros(size(normFreq));
                    
                    fullScalogramData.validPeaks = [];
                    for i = 1:1:length(fullSwdScalogramData.validPeaks)
                        
                        % Looking for the similar frequencies in normFreq & 
                        % validSwdFreq(i). Difference should be less then percentRange
                        normMaskVector((normFreq <= (validSwdFreq(i)*(1+percentRange/100))) & (normFreq>=(validSwdFreq(i)*(1-percentRange/100)))) = i;
                        positionsOfSimilarFrequencies = find(normMaskVector);
                        
                        % We choose the closest frequency and its coefficient
                        [maxRms,maxPosition] = max(fullNormScalogramData.coefficients(positionsOfSimilarFrequencies));
                        refinedFreq = normFreq(positionsOfSimilarFrequencies(maxPosition));
                        
                        if ~isempty(fullNormScalogramData.validPeaks)
                            for j = 1:1:length (fullNormScalogramData.validPeaks)
                                if      fullNormScalogramData.validPeaks(j).frequencies <= refinedFreq*(1+percentRange/100)...
                                     && fullNormScalogramData.validPeaks(j).frequencies >= refinedFreq*(1-percentRange/100)                               

                                    fullScalogramData.validPeaks(i).frequencies = fullNormScalogramData.validPeaks(j).frequencies;

                                    for fi = 1:numel(field4merge)
                                        fullScalogramData.validPeaks(i).(field4merge{fi}) = fullNormScalogramData.validPeaks(j).(field4merge{fi});
                                    end
                                else
                                    fullScalogramData.validPeaks(i).frequencies = refinedFreq;
                                    for fi = 1:numel(field4merge)
                                        fullScalogramData.validPeaks(i).(field4merge{fi}) = fullSwdScalogramData.validPeaks(i).(field4merge{fi});
                                    end   
                                end
                            end
                        else    % if there is no peaks in normolized scalogram
                                fullScalogramData.validPeaks(i).frequencies = refinedFreq;
                                for fi = 1:numel(field4merge)
                                    fullScalogramData.validPeaks(i).(field4merge{fi}) = fullSwdScalogramData.validPeaks(i).(field4merge{fi});
                                end   
                        end
                            
                        % Calculation of the energyContribution for every peak. We
                        % divide the peak coefficient by the signalRms and write the
                        % result into the structure of this valid peak
                            fullScalogramData.validPeaks(i).energyContribution = maxRms / signalRms; 
                            normMaskVector = [];
                    end
                    
                    % Check @fullNormScalogramData to define unique
                    % frequencies,that haven't any similars in the 
                    % @fullSwdScalogramData and add them to the @fullScalogramData
                    for i = 1:1:length(fullNormScalogramData.validPeaks)

                        similarityVector = zeros(size(fullScalogramData.validPeaks));
                        for j =1:1:length(fullScalogramData.validPeaks)
%                             if ~(fullNormScalogramData.validPeaks(i).frequencies == fullScalogramData.validPeaks(j).frequencies)

                           if        fullNormScalogramData.validPeaks(i).frequencies <= fullScalogramData.validPeaks(j).frequencies*(1+percentRange/100)...
                                  && fullNormScalogramData.validPeaks(i).frequencies >= fullScalogramData.validPeaks(j).frequencies*(1-percentRange/100)

                                similarityVector(j) = 1;
                           end   

                        end
                        if ~any(similarityVector)
                            fullScalogramData.validPeaks(end+1).frequencies = fullNormScalogramData.validPeaks(i).frequencies;
                            for fi = 1:numel(field4merge)
                                fullScalogramData.validPeaks(end).(field4merge{fi}) = fullNormScalogramData.validPeaks(i).(field4merge{fi});
                            end
                            fullScalogramData.validPeaks(end).energyContribution = fullNormScalogramData.coefficients(fullNormScalogramData.frequencies(:) == validNormFreq(i)) / signalRms;
                        end
                    end 
            end
            ScalogramData = fullScalogramData.validPeaks;
        end        
    end
    
    methods(Static)
        % CREATEHISTORYSCALOGRAM function divided scalogram into banks and
        % forms octaveScalogram for further history evaluation
        function [historyScalogram] = createOctaveScalogram(fullScalogramData, config)
            
            if nargin < 2
               config = []; 
            end
            
            config = fill_struct(config, 'lowFrequency','16'); % low frequency range margin
            config = fill_struct(config, 'highFrequency','16000'); % high frequency range margin
            config = fill_struct(config, 'filterMode','1/3 octave'); 
            config = fill_struct(config, 'roundingEnable','1'); % Enable rounding to the nearest 2^i value

            switch(config.filterMode)
                case '1 octave'
                    pointsPerOctave = 1;
                case '1/3 octave'
                    pointsPerOctave = 3;
                case '1/6 octave'
                    pointsPerOctave = 6;
                case '1/12 octave'
                    pointsPerOctave = 6;
                otherwise
                    pointsPerOctave = 1;
            end
            
            % Form frequencies array with several points per octave and recalculate it
            % to the position format.
            roundingEnable = str2double(config.roundingEnable);
            
            lowFrequency = str2double(config.lowFrequency);
            highFrequency = str2double(config.highFrequency);

            df = (highFrequency - lowFrequency)/length(fullScalogramData.frequencies);

            [scalePositions] = quadraspace(lowFrequency, highFrequency, pointsPerOctave, roundingEnable, 'pointsPerOctave');
            positions = round(scalePositions/df);
            lowPosition = positions(1,1:end-1);
            highPosition = positions(1,2:end);
            centralFrequencies = scalePositions(1,1:end-1) + diff(scalePositions)/2;

            frameLength = highPosition-lowPosition;
            banksNumber = length(highPosition);
            
            lengthCoefficients = length(fullScalogramData.frequencies);
            if lengthCoefficients < banksNumber
                banksNumber = length(fullScalogramData.frequencies);
            end
            
            coefficients = zeros(1,banksNumber);
            
            for i=1:1:banksNumber
                 coefficients(1,i) = sum(fullScalogramData.coefficients(lowPosition(1,i):highPosition(1,i),1))/frameLength(1,i);                                      
            end
            historyScalogram.coefficients = coefficients;
            historyScalogram.frequencies = centralFrequencies;
        end
        
        
        % Define low and high frequency of the digital filter
        function [scalogramDataNew] = defineFilterParameters(scalogramData)
            
            scalogramDataNew = scalogramData;
            validPeaks = scalogramData.validPeaks;
            if ~isempty(validPeaks)
                for i = 1:numel(validPeaks)
                    
                    threshold = 0.7071;
                    thresholdVector = ones(size(scalogramData.coefficients))*(validPeaks(i).prominence)*threshold + (validPeaks(i).height - validPeaks(i).prominence);
                    coefficients = scalogramData.coefficients /max(scalogramData.coefficients);
                    coefficients = coefficients - thresholdVector;
                    
                    frequencies = scalogramData.frequencies;
                    frequencies(coefficients<0) = NaN;

                    validPeaks(i).lowFrequency = scalogramData.frequencies(find(diff([frequencies<validPeaks(i).frequencies;NaN])>0,1,'last'));
                    validPeaks(i).highFrequency = scalogramData.frequencies(find(diff([frequencies>validPeaks(i).frequencies;NaN])<0,1,'first'));
                end
                scalogramDataNew.validPeaks = validPeaks;
            else
%                 warning('There is an empty scalogramData!');
            end
            
        end
    end
end

