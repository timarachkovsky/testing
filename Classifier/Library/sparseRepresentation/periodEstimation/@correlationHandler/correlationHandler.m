classdef correlationHandler
    %CORRELATIONHANDLER class implements time-domain period estimation
    %based on the correlation function analysis
    
    properties (Access = protected)

        config  % configuration structure
        translations % translations for plots
        correlationFunction % Structure, containing correlation coefficients
                            % of the original signal
        %Signal averaging handler for adaptive peaksfinding, saving PT.
        handlerAve
        compStageString
        result %Validated periods tables only.
        
        picNmStr  %Add it to saving pics names 4 the curr scal point.
        %Pre-processed ACF: gotten one-side ACF, deleted runout - coeffs, positions, Fs.
        signal
        signalProcessed
        
        FullData  %All periods tables, validated and not.
        peaksTable  %Peaks found by all thresholds.
        %Output data.
        w %Original warnings.
        c %Destructor restoring warnings.
    end
    
    methods (Access = public)
        
        % Constructor function
        function [myHandler] = correlationHandler(file, myConfig, myTranslations)
           myHandler.config = myConfig;
           if ~exist('myTranslations', 'var')
               myTranslations = [];
           end
           myHandler.translations = myTranslations;
            myHandler.compStageString = 'Time-domain correlation periods finding';
          %==Output settings.==
          %Enable output if there is the common enabling and correlation handler's. %If the local enabling eq. 2, forbidd loger; if 3 - loger output only.
          myHandler.config.printEnable = num2str( str2double(myHandler.config.Attributes.logEnable)*str2double(myHandler.config.loger.Attributes.consoleEnable) );
          outLog(myHandler, 'Starting...');
          myHandler.w = warning; myHandler.c = onCleanup(@() warning(myHandler.w));
          if (str2double(myHandler.config.printEnable) == 3) || (str2double(myHandler.config.printEnable) == 0), warning('off'); end %Don't let out to command window.
          if ( nnz(strfind(myHandler.config.Attributes.plotVisible, 'off')) ) && (~str2double(myHandler.config.Attributes.printPlotsEnable))
              myHandler.config.Attributes.fullSavingEnable = '0';  %If the common parameters forbid output - turn it off.
          end
           myConfig.Attributes.fullSavingEnable = num2str(str2double(myConfig.debugModeEnable) * str2double(myConfig.Attributes.fullSavingEnable));
           
           if isa(file, 'signalAveragingHandler') %If signal assigned by averaging handler with ready PT, save it and make file struct.
               myHandler.handlerAve = file; file = []; file.signal = myHandler.handlerAve.signal; file.Fs = str2double(myHandler.handlerAve.config.Fs);
           end
           if isfield(myConfig, 'correlation')
               parameters = myConfig.correlation;
               parameters.Attributes.minFreq = myConfig.Attributes.minFrequency;
               myHandler.correlationFunction = correlation(file, parameters);
           else
               file.signal = reshape(file.signal, max(size(file.signal)), []);
               myHandler.correlationFunction = file; %Add raw data if it's necessary.
           end
           myPicNmStr = [];
           if isfield(myConfig, 'pointNumber')
               myPicNmStr = sprintf('PointNo_%d_', myConfig.pointNumber);
           end
           if isfield(myConfig, 'pointFreq')
               myPicNmStr = [myPicNmStr sprintf('PointFreq_%10.1f_', myConfig.pointFreq)];
           end
           if isfield(myConfig, 'Label')
               myPicNmStr = [myPicNmStr myConfig.Label];
           end
           myHandler.picNmStr = myPicNmStr;
           myHandler.signal.cuttedZeroTimeRunout = 0; myHandler.signal.smooth = 0;
           myHandler.signal.detrended = 0; myHandler.signal.cutNoiseLevel = 0;
           myHandler.signal.slowNoiseRemoved = 0; myHandler.signal.windowWidth = 0;
           myHandler.signal.scale = 'ThresholdLin';
           if str2double(myHandler.config.Attributes.preProcessingEnable)
               myHandler = acfPreProcess(myHandler, str2double(myHandler.config.Attributes.fullSavingEnable));
           else
               [myHandler.signal.myCoefficients, myHandler.signal.myPositions, myHandler.signal.Fs] = getOrigCoeffs(myHandler); myHandler.signalProcessed = myHandler.signal;
           end
        end
        
        function str2out = outResultTable(myHandler, table, str, mode)
            if ~str2double(myHandler.config.printEnable), str2out = []; return; end
            if ~exist('table', 'var')
                table = [];
            end
            if ~exist('mode', 'var')
                mode = '';
            end
            if isempty(table) && ~nnz(strfind(mode, 'fullForbid'))
                table = myHandler.FullData;
            end
            if ~exist('str', 'var')
                str = [];
            end
            thresholdStrings = {'Low' 'Average' 'High'};
            validityBorders = {[-1 0.495] [0.495 0.7495] [0.7495 2]};
            str2out = sprintf([str '\n']);
            if isempty(table)
                str2out = [str2out sprintf('There is no any data for output!\n')];
                outLog(myHandler, str2out, mode);
                return;
            end
            for j = 1:numel(thresholdStrings)
                border = validityBorders{j};  %Choose periodicies with the current validation level.
                idxs = [table.validity] < border(2);  %Lower the high border.
                idxs = ( [table.validity] >= border(1) ).*(idxs);  %More then low, exclude high.
                if ~nnz(idxs)
                    str2out = [str2out sprintf('\n\nThere is no %s validated periodicies.\n', thresholdStrings{j})];
                    continue;
                end
                idxs = find(idxs);
                currTable = table(idxs);
                str2out = [str2out sprintf('\n\n%s validated periodicies:\n', thresholdStrings{j})];
                for i = 1:numel(currTable)
                    str2out = [str2out outOneResult(myHandler, currTable(i), [thresholdStrings{j} ' validated periodicy: '], 'outForbidd')];
                end
            end
            outLog(myHandler, str2out, mode);
        end
        
        function str2out = outOneResult(myHandler, table, str, mode)
            if ~str2double(myHandler.config.printEnable), str2out = []; return; end
            if ~exist('str', 'var')
                str = '\n';
            end
            if ~exist('mode', 'var')
                mode = '';
            end
            str2out = sprintf(str);
            str2out = [str2out sprintf('%10.5f sec, %10.2f Hz with validities %10.5f', table.period, table.frequency, table.validity)];
            str2out = [str2out sprintf(' with periods number %d, %s threshold kind.\n', numel(table.PeriodicyData.PeaksPositions), table.ThresholdKind)];
            outLog(myHandler, str2out, mode);
        end
        
        function outLog(myHandler, str2out, mode)
            if ~exist('mode', 'var')
                mode = '';
            end
            if ~str2double(myHandler.config.printEnable), return; end
            if str2double(myHandler.config.printEnable) == 2, mode = strrep(mode, 'Loger', ''); end %If enabling eq. 2, forbidd loger;
            if (str2double(myHandler.config.printEnable) == 3) && ~nnz(strfind(mode, 'Loger')), return; end %if 3 - loger output only.
            
            try
                iLoger = loger.getInstance;
            catch
                iLoger = [];
            end
            if nnz(strfind(mode, 'outForbidd'))
                return;
            end
            if isstruct(str2out), disp(str2out); return; end %It's possible display structures into command window.
            if ~nnz(strfind(mode, 'Loger'))
                if nnz(strfind(mode, 'warn'))
                    fprintf(['\n' myHandler.compStageString ': WARNING:\n']);
                end
                fprintf(str2out);
            else
                try
                    if ~nnz(strfind(mode, 'warn'))
                        printComputeInfo(iLoger, myHandler.compStageString, str2out);
                    else
                        printWarning(iLoger, myMessage);
                    end
                catch
                    mode = strrep(mode, 'Loger', ''); outLog(myHandler, str2out, mode);
                end
            end
        end
        
        function plotPeriodicy(myHandler, myPeriodsTable, mode, myFigure)
            if ~exist('mode', 'var')
                mode = '';
            end
            
            % Get parameters
            Translations = myHandler.translations;
            
            plotVisible = myHandler.config.Attributes.plotVisible;
            plotTitle = myHandler.config.Attributes.plotTitle;
            printPlotsEnable = str2double(myHandler.config.Attributes.printPlotsEnable);
            sizeUnits = myHandler.config.plots.sizeUnits;
            imageSize = str2num(myHandler.config.plots.imageSize);
            fontSize = str2double(myHandler.config.plots.fontSize);
            imageFormat = myHandler.config.plots.imageFormat;
            imageQuality = myHandler.config.plots.imageQuality;
            imageResolution = myHandler.config.plots.imageResolution;
            
            if ~exist('myPeriodsTable', 'var')
               myPeriodsTable = 'all';
            end
            if ischar(myPeriodsTable)
               myPeriodsTable = getResult(myHandler, myPeriodsTable);
            end
            myCoefficients = myHandler.signalProcessed.myCoefficients;
            myPositions = myHandler.signalProcessed.myPositions;
            if nnz(strfind(mode, 'normalize')), myCoefficients = myCoefficients/max(myCoefficients); end
            
            % Plot
            closef = 0;
            if ~exist('myFigure', 'var')
                closef = 1;
                myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
            end
            hold on;
            signalLegend = {'Correlogram'};
            if nnz(strfind(mode, 'signOrig'))
                signOrig = getOrigSignal(myHandler);
                signOrig = signOrig / max(signOrig) * max(myCoefficients);
                mySignalPlot = plot(myPositions(2 : end), signOrig);
                signalLegend = [{'Signal (normalized)'} signalLegend];
                % Set axes limits
                axis([0 max(myPositions) 0.9 * min(signOrig) 1.1 * max(myCoefficients)]);
            end
            myCoeffPlot = plot(myPositions, myCoefficients);
            stemMarkers = {'or', '+g', 'sk', '<r', 'dk', '>r', 'pb', 'xg', 'hb', 'xc', '^c', 'vm', '+m'};
            while numel(stemMarkers) < numel(myPeriodsTable)
                stemMarkers = [stemMarkers stemMarkers];
            end
            if ~isempty(myPeriodsTable)
                cellfun(@(x, y) stem(myPositions(x.PeriodicyData.PeaksPositions), myCoefficients(x.PeriodicyData.PeaksPositions), y), ...
                    arrayfun(@(x) x, myPeriodsTable, 'UniformOutput', false), stemMarkers(1 : numel(myPeriodsTable)));
            end
            hold off;
            grid on;
            
            % Get axes data
            myAxes = myFigure.CurrentAxes;
            % Set axes font size
            myAxes.FontSize = fontSize;
            
            % Figure title
            if strcmp(plotTitle, 'on')
                title(myAxes, [upperCase(Translations.periodicity.Attributes.name, 'first'), ' - ', ...
                    upperCase(Translations.correlogram.Attributes.name, 'allFirst')]);
            end
            % Figure labels
            xlabel(myAxes, [upperCase(Translations.time.Attributes.name, 'first'), ', ', ...
                upperCase(Translations.time.Attributes.value, 'first')]);
            ylabel(myAxes, [upperCase(Translations.magnitude.Attributes.name, 'first'), ', ', ...
                Translations.correlogram.Attributes.value]);
            % Figure legend
            stemLegend = arrayfun(@(x) sprintf('Period: %4.3f Hz; Validity: %1.5f', x.frequency, x.validity), myPeriodsTable, 'UniformOutput', false);
            legend([signalLegend stemLegend]);
            
            if printPlotsEnable
                if nnz(strfind(mode, 'fig'))
                    Root = fullfile(fileparts(mfilename('fullpath')), '..', '..', '..', '..');
                    saveas(myFigure, fullfile(Root, 'Out', [myHandler.picNmStr 'allPeriods.fig']), 'fig');
                end
                
                % Save the image to the @Out directory
                imageNumber = num2str(myHandler.config.pointNumber);
                fileName = ['periodicity-correlogram-acc-', imageNumber];
                fullFileName = fullfile(pwd, 'Out', fileName);
                print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
                
                if checkImages(fullfile(pwd, 'Out'), fileName, imageFormat)
                    outLog(myHandler, 'The method images were saved.\n', 'Loger')
                end
            end 
            
            if closef && strcmpi(plotVisible, 'off')
                close(myFigure)
            end 
        end
        
        % Getters / Setters ...
        
        function [myConfig] = getConfig(myHandler)
            myConfig = myHandler.config;
        end
        function [myHandler] = setConfig(myHandler, myConfig)
            myHandler.config = myConfig;
        end
        
        function [myCorrelationFunction] = getCorrelationFunction(myHandler)
           myCorrelationFunction = myHandler.correlationFunction; 
        end
        
        function [mySignal] = getSignal(myHandler)
           mySignal = myHandler.signal; 
        end
        function [myHandler] = setSignal(myHandler, mySignal)
            myHandler.signal.myCoefficients = mySignal; 
        end
        function [mySignal] = getOrigSignal(myHandler)
            if isstruct(myHandler.correlationFunction)
                mySignal = myHandler.correlationFunction.signal; return;
            end
           mySignal = myHandler.correlationFunction.getOrigSignal;
        end
        function [myHandler] = setOrigSignal(myHandler, mySignal)
            myHandler.correlationFunction = mySignal;
        end
        
        function [myResult] = getResult(myHandler, resultKind)
            %resultKind points which result it's need to return:
            %'good' - result with validity over good threshold.
            %'average' - result with validity over average threshold, but lower then good.
            %'all' - result with validity over average threshold with good result - all valid data - default.
            %'full' - all results (FullData).
            if ~exist('resultKind', 'var')
               resultKind = 'all'; 
            end
            if strfind(resultKind, 'full')
                myResult = myHandler.FullData;
                return;
            end
            goodThreshold = 0.7495;
            averageThreshold = 0.495;
            myResult = myHandler.result;
            if strfind(resultKind, 'all')
                return;
            end
            idxs = [myResult.validity] >= goodThreshold;
            if strfind(resultKind, 'average')
                idxs = ([myResult.validity] >= averageThreshold).*(~idxs);  %More then average exclude good.
            end
            myResult = myResult(idxs);
        end
        
        function [myHandler] = addResult(myHandler, myResult, reset)
            if isempty(myResult)
                return;
            end
            if ~exist('reset', 'var')
                reset = false;
            end
            if reset
                myHandler.FullData = [];
                myHandler.result = [];
            end
            if ~isempty(myHandler.FullData)
                myResult = [myResult myHandler.FullData];
            end
            myHandler.FullData = myResult;
            idxsNonEmpties = arrayfun(@(x) ~isempty(x.PeriodicyData), myResult);
            myResult = myResult(find(idxsNonEmpties));
            if isempty(myResult)
                return;
            end
            myHandler.result = myResult([myResult.validity] >= 0.495);  %Add to result period tables validated like average/good.
        end
        % ... Getters / Setters
        
        % periodEstimation function find all possible correlation function
        % periods on the 3 threshold levels (low, average and high); form
        % summary periods table and return the true one through validation
        % process.
        function [myHandler] = periodEstimation(myHandler)
            Threshold = myHandler.signal.scale;
            outLog(myHandler, ['\n\n===' Threshold ' periods finding by three threshold levels.===\n\n']);
            outLog(myHandler, [Threshold ' periods finding by three threshold levels'], 'Loger');
            
            % Find all possible periods
            [baseTableLow, mainCoefficients] = createPeriodTable(myHandler, Threshold, 'low');
            [baseTableAverage, ~ ] = createPeriodTable(myHandler, Threshold, 'average');
            [baseTableHigh, ~ ] = createPeriodTable(myHandler, Threshold, 'high');

            %If there are some close periodicies, we guess, that it's one
            %periodicy on ACF, where there are side peaks of the ACF around the main.
            [baseTable] = compareBaseTables(myHandler,baseTableLow,baseTableAverage,baseTableHigh);
            
            [baseTable] = validateBaseTable(myHandler,baseTable,mainCoefficients);
            cutNoiseLevel = num2str(double(myHandler.signal.cutNoiseLevel));
            %ThresholdKind in base (period) table characterises the way
            %which the table was gotten, in PeriodicyData field (peaks
            %table) - which way(s) validated each peak.
            baseTable = arrayfun( @(x) setfield(x, 'ThresholdKind', [Threshold '_cutNoise_' cutNoiseLevel '_windWidth_' num2str(myHandler.signal.windowWidth)]), baseTable );
            outResultTable(myHandler, baseTable, ['\n\n' Threshold ' threshold base table validation.']);
            
            [myHandler] = addResult(myHandler, baseTable);
        end
        
        
    end
      
    methods (Access = protected)
        
        % CREATEPERIODTABLE function fill table with validated period and
        % their infomation (periodsNumber, validity) for further validation
        function [ myTable, mainCoefficients ] = createPeriodTable(myHandler, threshold, thresholdLevel) %, PeriodicyData
            Root=fullfile(fileparts(mfilename('fullpath')),'..','..','..','..');
            cutNoiseLevel = num2str(double(myHandler.signal.cutNoiseLevel));
            outLog( myHandler, sprintf('The %s threshold periodicy estimation.\n', thresholdLevel) );
            
            myTable = [];
            myCoefficients = myHandler.signal.myCoefficients;
            myPositions = myHandler.signal.myPositions;
            Fs = myHandler.signal.Fs;
                
            %=====Make a high*prom peak vector, that will show positions of correlogramms peaks responding on great periodicy.=====
            % Find global peaks and check their average distance. Form
            % vector of possible distancies and their count in the
            % correlation function
            maxFrequency = str2double(myHandler.config.Attributes.maxFrequency);
            minPeaksDictance = Fs/maxFrequency;
            if strcmp(threshold, 'ThresholdLog')
                thrType = 'abs';
            else
                thrType = 'rel';
            end
            [ globalPeaks, globalHeights ] = myHandler.findGlobalPeaks(minPeaksDictance, threshold, thresholdLevel, thrType);
            
            if str2double(myHandler.config.Attributes.fullSavingEnable)
                figure('units','points','Position',[0, 0, 800, 600]);
                hold on
                plot(myPositions, myCoefficients);
                plot(myPositions(globalPeaks), myCoefficients(globalPeaks), 'r*');
                hold off
                axis( [ 0, ceil(0.05*max(myPositions)), 0, max(myCoefficients) ] );
            end
            
            if isempty(globalPeaks)
                mainCoefficients = [];
                PeriodicyData = [];
                return;
            end
            
            myPeaksTable.PeaksPositions = globalPeaks;
            myPeaksTable.heights = globalHeights(globalPeaks);
            myPeaksTable.thresholdLevel = repmat( {thresholdLevel}, size(globalPeaks) );
            thresholdKind = [threshold '_cutNoiseLevel' cutNoiseLevel '_windWidth' num2str(myHandler.signal.windowWidth)];
            myPeaksTable.thresholdKind = repmat( {thresholdKind}, size(globalPeaks) );
            
            [ myTable, mainCoefficients ] = findPeriods4PeaksTable(myHandler, myPeaksTable);
            
            if str2double(myHandler.config.Attributes.fullSavingEnable)
                hold on
                for i = 1:numel(myTable)
                    perPos = myTable(i).PeriodicyData.PeaksPositions;
                    stem( myPositions(perPos), myCoefficients(perPos) )
                end
                hold off
                saveas(gcf,fullfile(Root, 'Out', [myHandler.picNmStr 'globalPeaks_' thresholdKind '_' upper(thresholdLevel) 'level.jpg']),'jpg');
            end
            
            if strcmpi(myHandler.config.Attributes.plotVisible, 'off')
                close
            end
        end
        
        
        function [ myTable, mainCoefficients ] = findPeriods4PeaksTable(myHandler, myPeaksTable)
            myTable = [];
            
            globalPeaks = myPeaksTable.PeaksPositions;
            myCoefficients = double(myHandler.signal.myCoefficients);
            myPositions = myHandler.signal.myPositions;
            [ mainCoefficients ] = myCoefficients(1:max(globalPeaks),1);
            parameters = myHandler.config.peaksDistanceEstimation; parameters.printEnable = myHandler.config.printEnable;
            [ peaksDistance, periodsNumber, PeriodicyData ] = myHandler.peaksDistanceEstimation(globalPeaks,parameters);
            
            if isnan(peaksDistance)
                outLog(myHandler, 'Periodicy table creation: periodicy was not estimated!\n');
                myTable = [];
                return;
            else
                % If some distancies were found, validate (if they are true
                % distancies) and fill table with information about them
                dt = myPositions(3) - myPositions(2);
                outLog( myHandler, sprintf('Found periodicies: %s sec, %s Hz with periods number %s.\n', num2str(peaksDistance'*dt), num2str(1./(peaksDistance'*dt)), num2str(periodsNumber')) );
                
                container = myHandler.createValidationContainer;
                status = zeros(length(peaksDistance),1);
                for i = 1:1:length(peaksDistance)
                    status(i) = myHandler.validationProcessing(container, periodsNumber, i);
                end
                
                validPositions = find(bsxfun(@ge,status,0.1));
                for i = 1:1:length(validPositions)
                   myTable(i).distance = peaksDistance(validPositions(i,1));
                   myTable(i).periodsNumber = periodsNumber(validPositions(i,1));
                   myTable(i).validity = status(validPositions(i,1));
                   PD = PeriodicyData(validPositions(i));
                   periodicyPeaksTable = PD.PeaksPositions;
                   for j = 1:numel(periodicyPeaksTable)
                       %Find the current element of periodicy's peaks table in the common table and take it's params.
                       labelsIdx = find(periodicyPeaksTable(j) == myPeaksTable.PeaksPositions);
                       PD.thresholdLevel(j) = myPeaksTable.thresholdLevel(labelsIdx);
                       PD.thresholdKind(j) = myPeaksTable.thresholdKind(labelsIdx);
                   end
                   myTable(i).PeriodicyData = PD;
                   myTable(i).ThresholdKind = myPeaksTable.thresholdKind{1};
                end
                if ~isempty(myTable)
                    outLog( myHandler, sprintf('Validated periodicies: %s sec, %s Hz with periods number %s.\n', num2str([myTable.distance].*dt), num2str(1./([myTable.distance].*dt)), num2str([myTable.periodsNumber])) );
                else
                    outLog(myHandler, 'There are no validated periodicies!');
                end
            end
            
        end
        
        % COMPAREBASETABLES function compare found periods of the low,
        % average and high thresholds, finds the similars and forms a table
        % with their validity for further fuzzy-analysis
        function [baseTable] = compareBaseTables(myHandler,baseTableLow,baseTableAverage,baseTableHigh)
            
            baseTable = [];
            % Parse tables and set parameters
            compareRange = str2double(myHandler.config.Attributes.comparePercentRange)/100;
%             compareRange = 0.05;
            
            %Form distance vectors for period tables with different "globality" thresholds.
            lowNumber = length(baseTableLow);
            if lowNumber >= 1
               lowVector = zeros(lowNumber,1);
               for i = 1:1:lowNumber
                  lowVector(i,1)  =  baseTableLow(i).distance;
               end
            end
            
            averageNumber = length(baseTableAverage);
            if averageNumber >= 1
               averageVector = zeros(averageNumber,1);
               for i = 1:1:averageNumber
                  averageVector(i,1)  =  baseTableAverage(i).distance;
               end
            end
            
            highNumber = length(baseTableHigh);
            if highNumber >= 1
               highVector = zeros(highNumber,1);
               for i = 1:1:highNumber
                  highVector(i,1)  =  baseTableHigh(i).distance;
               end
            end
            
            if lowNumber==0 && averageNumber==0 && highNumber==0
                return;
            end
            
            % Find similarity in 3 tables and fill the baseTable
            %Exclude elements from higher tables from vectors for lower
            %tables and put validity in fields accord to the origin tables
            %(if origin table is Low, put in "validityLow" field, etc.
            k = 0;
            if highNumber >=1
                for i = 1:1:highNumber
                    k = k+1;
                    %Put in info from higher table. It's basic info, from the rest tables is additional.
                    baseTable(k).distance = highVector(i,1);
                    baseTable(k).validityHigh = baseTableHigh(i).validity;
                    baseTable(k).IndexHigh = i; %Write the current element number for matching other data.
                    
                    if averageNumber >= 1
                        %Find matching in some range elements from the different tables.
                        idxAverage = find(bsxfun(@times,...
                                    bsxfun(@ge,averageVector,highVector(i,1)*(1-compareRange)),...
                                    bsxfun(@le,averageVector,highVector(i,1)*(1+compareRange))),1); 
                        if ~isempty(idxAverage)
                            %If match - add info to Lower_Table (average) field,
                            %exclude from Lower_distance vector.
                            baseTable(k).validityAverage = baseTableAverage(idxAverage).validity;
                            baseTable(k).distanceAverage = baseTableAverage(idxAverage).distance; %Test.
                            baseTable(k).IndexAverage = idxAverage; %For matching other data.
                            averageVector(idxAverage,1) = 0;
                        else
                            %There are no similar elements in the average table.
                            baseTable(k).validityAverage = 0;
                            baseTable(k).distanceAverage = -1; %Test.
                            baseTable(k).IndexAverage = 0; %For matching other data.
                        end  
                    else
                        baseTable(k).validityAverage = 0;
                        baseTable(k).distanceAverage = -1; %Test.
                        baseTable(k).IndexAverage = 0; %For matching other data.
                    end
                    
                    if lowNumber >= 1
                        idxLow = find(bsxfun(@times,...
                                    bsxfun(@ge,lowVector,highVector(i,1)*(1-compareRange)),...
                                    bsxfun(@le,lowVector,highVector(i,1)*(1+compareRange))),1); 
                        if ~isempty(idxLow)
                            baseTable(k).validityLow = baseTableLow(idxLow).validity;
                            baseTable(k).distanceLow = baseTableLow(idxLow).distance; %Test.
                            baseTable(k).IndexLow = idxLow; %For matching other data.
                            lowVector(idxLow,1) = 0;
                        else
                            baseTable(k).validityLow = 0;
                            baseTable(k).distanceLow = -1; %Test.
                            baseTable(k).IndexLow = 0; %For matching other data.
                        end 
                    else
                        baseTable(k).validityLow = 0;
                        baseTable(k).distanceLow = -1; %Test.
                        baseTable(k).IndexLow = 0; %For matching other data.
                    end
                    
                end
            end
            
            if averageNumber >=1
                for i = 1:1:averageNumber
                    if averageVector(i,1) > 0
                        k = k+1;
                        baseTable(k).distance = averageVector(i,1);
                        %Set values of higher tables to zero, because elements, that are a parts of both tables, were
                        %processed earlier, like higher, and excluded from lower distance vector.
                        baseTable(k).validityHigh = 0;
                        baseTable(k).IndexHigh = 0;
                        baseTable(k).validityAverage = baseTableAverage(i).validity;
                        baseTable(k).IndexAverage = i;

                        if lowNumber >= 1
                            idxLow = find(bsxfun(@times,...
                                        bsxfun(@ge,lowVector,averageVector(i,1)*(1-compareRange)),...
                                        bsxfun(@le,lowVector,averageVector(i,1)*(1+compareRange))),1); 
                            if ~isempty(idxLow)
                                baseTable(k).validityLow = baseTableLow(idxLow).validity;
                                baseTable(k).distanceLow = baseTableLow(idxLow).distance; %Test.
                                baseTable(k).IndexLow = idxLow; %For matching other data.
                                lowVector(i,1) = 0;
                            else
                                baseTable(k).validityLow = 0;
                                baseTable(k).distanceLow = -1; %Test.
                                baseTable(k).IndexLow = 0; %For matching other data.
                            end
                        else
                            baseTable(k).validityLow = 0;
                            baseTable(k).distanceLow = -1; %Test.
                            baseTable(k).IndexLow = 0; %For matching other data.
                        end
                    end   
                end
            end
                         
            if lowNumber >=1
                for i = 1:1:lowNumber
                    if lowVector(i,1) > 0
                        k = k+1;
                        baseTable(k).distance = lowVector(i,1);
                        baseTable(k).validityHigh = 0;
                        baseTable(k).validityAverage = 0;
                        baseTable(k).validityLow = baseTableLow(i).validity;
                        baseTable(k).distanceLow = baseTableLow(i).distance; %Test.
                        baseTable(k).IndexLow = i; %For matching other data.
                        %Filling higher table data to zero
                        baseTable(k).IndexHigh = 0;
                        baseTable(k).IndexAverage = 0;
                        baseTable(k).distanceAverage = -1;
                        baseTable(k).distanceHigh = -1;
                    end   
                end   
            end
            
            baseTable = arrayfun(@(x) fill_struct(x, 'validationData', []), baseTable);
            %setfield(x, 'validationData', fill_struct(...))
            baseTable = arrayfun(@(x) fill_struct(x, 'IndexLow', [], 'distanceLow', [], 'validityLow', [], ...
                'IndexAverage', [], 'distanceAverage', [], 'validityAverage', [], 'IndexHigh', [], 'distanceHigh', [], 'validityHigh', []), baseTable);
            %For each found periodicy put together all peaks, according peaks distances, threshold table label.
            for i = 1:1:numel(baseTable)
                myHandler.peaksTable = []; PeriodicyData = []; lowerTables = cell(1, 3);
                if baseTable(i).IndexLow
                    myHandler.peaksTable = [baseTableLow(baseTable(i).IndexLow).PeriodicyData];
                    if ~isempty(baseTableLow)
                       PeriodicyData = baseTableLow.PeriodicyData; lowerTables{1} = baseTableLow;
                    end
                end
                if baseTable(i).IndexAverage
                    myHandler.peaksTable = [myHandler.peaksTable baseTableAverage(baseTable(i).IndexAverage).PeriodicyData];
                    if (~isempty(baseTableAverage)) && isempty(PeriodicyData)
                       PeriodicyData = baseTableAverage.PeriodicyData; lowerTables{2} = baseTableAverage;
                    end
                end
                if baseTable(i).IndexHigh
                    myHandler.peaksTable = [myHandler.peaksTable baseTableHigh(baseTable(i).IndexHigh).PeriodicyData];
                    if (~isempty(baseTableHigh)) && isempty(PeriodicyData)
                       PeriodicyData = baseTableHigh.PeriodicyData; lowerTables{3} = baseTableHigh;
                    end
                end
                if nnz(arrayfun(@(x) ~isempty(x), [myHandler.peaksTable.PeaksPositions])), myHandler = myHandler.peakTableComparison; end
                baseTable(i).PeriodicyData = myHandler.peaksTable;
                baseTable(i).validationData.thresholdTables = lowerTables;
                if ~isempty(PeriodicyData)
                    baseTable(i).PeriodicyData.PeaksDistSTD = PeriodicyData.PeaksDistSTD;
                    baseTable(i).PeriodicyData.validFrames = PeriodicyData.validFrames;
                end
            end
            
        end
        
        % VALIDATEBASETABLE function validates period values in the 
        % baseTable based on fuzzy-logic. Function found period with strong
        % validity (more then mbValid) and stable emergence on the
        % different threshold levels.
        function [baseTable] = validateBaseTable(myHandler, baseTable, mainCoefficients)
            
           if isempty(baseTable)
              return
           end
           [ ~, ~, myFs] = getOrigCoeffs(myHandler);
           container = myHandler.createTableValidationContainer;
           
           for i = 1:1: length(baseTable)
               inputArgs = [baseTable(i).validityHigh,...
                            baseTable(i).validityAverage,...
                            baseTable(i).validityLow      ];
               
               baseTable(i).validity = evalfis(inputArgs, container);
               baseTable(i).frequency = myFs/baseTable(i).distance;
               baseTable(i).period = baseTable(i).distance/myFs;
               validityVector = baseTable(i).validity;
           end
            
           % If some nonvalid (trash) periods are passed to baseTable use
           % correlogram validation method below this line
           

%            validPositions = find(bsxfun(@ge, validityVector, 0.75),1);
%            if ~isempty(validPositions)
%                for i = 1:1:length(validPositions)
%                     [status(i), trueValue(i)] = myHandler.peaksDistanceValidation(mainCoefficients, myFs, baseTable(i).distance)
%                end
%            end
        end
        
        function [ myCoefficients, myPositions, Fs] = getOrigCoeffs(myHandler)
            [ myCF ] = myHandler.correlationFunction;
            if isstruct(myCF) %Raw data was added - generate time (myPositions) and take back signal and Fs.
                Fs = myCF.Fs; dt = 1/Fs; myCoefficients = myCF.signal;
                myPositions = reshape(-dt:dt:length(myCoefficients)*dt-2*dt, size(myCoefficients));
                return;
            end
            [ myCoefficients, myPositions, Fs] = getOneSideParameters(myCF);
        end
        
        function myHandler = acfPreProcess(myHandler, plotEnable, mode)
            if ~exist('mode', 'var')
                mode = '';
            end
            renewPermit = ~logical(nnz( strfind(mode, 'renewForbidd') ));
            if strcmp(myHandler.signal.scale, 'ThresholdLin') && myHandler.signal.cuttedZeroTimeRunout && (~myHandler.signal.windowWidth) && renewPermit
                outLog(myHandler, 'Signal pre-processed already.\n');
                return;
            end
            if (~isempty(myHandler.signalProcessed)) && renewPermit
                myHandler.signal = myHandler.signalProcessed;
                outLog(myHandler, 'Renew signal.\n');
                return;
            end
            Root=fullfile(fileparts(mfilename('fullpath')),'..','..','..','..');
            if ~exist('plotEnable', 'var')
                plotEnable = [];
            end
            if isempty(plotEnable)
                plotEnable = 0;
            end
            detrendEnable = str2double(myHandler.config.Attributes.detrendEnable);
            if strfind(mode, 'detrendEnable')
                modeStrs = strsplit(mode, 'detrendEnable:');
                detrendEnableStr = modeStrs{2}(1);
                detrendEnable = str2double(detrendEnableStr);
            end
%             checkingEnable = 0;
%             if detrendEnable == 2
%                 checkingEnable = 1;
%             end
            if (detrendEnable == 2) && (~nnz( strfind(mode, 'checkingEnable') ))
                mode = strjoin({mode, 'checkingEnable'}, ',');
            end
            [ myCoefficients, myPositions, Fs] = getOrigCoeffs(myHandler);
            cutThreshold = ( rms(myCoefficients) + std(myCoefficients) )*2; zeroTime = myCoefficients(1);
            outLog(myHandler, sprintf('Zero time runout cutting make decision: the 1st sample is %1.4f, threshold is %1.4f.\n', zeroTime, cutThreshold));
            myCoefficients = double(myCoefficients);
            myHandler.signal.myCoefficients = myCoefficients;
            myHandler.signal.Fs = Fs;
            
            %=====Build a smooth signal and delete a delta and near runouts in the beginning.=====
            %Find average peak distance and average trash peaks.
            myConfAve.span = '1width'; myConfAve.theBextPeaksNum = 'glob';
            myConfAve.windowAveraging.saveSampling = '1';
            myConfAve.Fs = num2str(Fs);
            if isempty(myHandler.handlerAve)
                myHandler.handlerAve = signalAveragingHandler(myCoefficients, myConfAve);
            end
            myHandlerAver = myHandler.handlerAve;
            [myHandlerAver, myDraftCoefficients] = windowAveraging(myHandlerAver); myHandler.handlerAve = myHandlerAver;
            
            if plotEnable
                figure('units','points','Position',[0, 0, 800, 600], 'visible', myHandler.config.Attributes.plotVisible);
                plot(myPositions, myCoefficients);
                axis( [ 0, ceil(0.01*max(myPositions)), 0, max(myCoefficients) ] );
                saveas(gcf,fullfile(Root, 'Out', [myHandler.picNmStr 'CorrelogrammOrig.jpg']),'jpg');
                if strcmpi(myHandler.config.Attributes.plotVisible, 'off')
                    close
                end
            end
            if myCoefficients(1) < cutThreshold
                myHandler.signal = struct('myCoefficients', myCoefficients, 'myPositions', myPositions, 'Fs', Fs, 'cuttedZeroTimeRunout', 0);
               myHandler.signal.scale = 'ThresholdLin';
               myHandler.signal.cutNoiseLevel = false;
               myHandler.signal.windowWidth = 0;
               myHandler.signal.smooth = 0;
               myHandler.signal.detrended = 0;
               myHandler.signal.slowNoiseRemoved = 0;
                if detrendEnable
                    myHandler = detrendACF(myHandler, [], mode);
                    myHandler.signal.detrended = 1;
                end
                if str2double(myHandler.config.Attributes.slowNoiseRemoveEnable)
                    [myHandler, ~] = slowNoiseRemove(myHandler, myCoefficients, myHandlerAver, plotEnable);
                end
                if ~nnz(strfind(mode, 'lowTrend'))
                    myHandler.signalProcessed = myHandler.signal;
                end
                return;
            end
            
            %Find the first global minimum - overturn graphic, find the first prominent maximum, i.e. minimun of ACF.
            [~, ~, ~, minProms] = findpeaks(double(1-myDraftCoefficients));
            if plotEnable
                figure('units','points','Position',[0, 0, 800, 600], 'visible', myHandler.config.Attributes.plotVisible);
				plot(myPositions, double((myDraftCoefficients)));
                %should there be a saving for the figure above? (From T.Rach)
                figure('units','points','Position',[0, 0, 800, 600], 'visible', myHandler.config.Attributes.plotVisible);
				findpeaks(1-myDraftCoefficients, 'Annotate','extents');
                axis( [ 0, ceil(0.01*length(myPositions)), min(1-myDraftCoefficients), max(1-myDraftCoefficients)*1.1 ] );
                saveas(gcf,fullfile(Root, 'Out', [myHandler.picNmStr 'draftMins.jpg']),'jpg');
                if strcmpi(myHandler.config.Attributes.plotVisible, 'off')
                    close
                    close
                end
            end
            minPeakProm = max(minProms)*0.3;
            if isempty(minProms)
                minPeakProm = 0; warning('Can''t find peaks for minimum prominence estimation.');
            end
            [~, minLocs] = findpeaks(double(1-myDraftCoefficients), 'MinPeakHeight', 0.90, 'MinPeakProminence', minPeakProm);
            if plotEnable
                figure('units','points','Position',[0, 0, 800, 600], 'visible', myHandler.config.Attributes.plotVisible);
				findpeaks(1-myDraftCoefficients, 'MinPeakHeight', 0.90, 'MinPeakProminence', minPeakProm, 'Annotate','extents');
                axis( [ 0, ceil(0.01*length(myPositions)), min(1-myDraftCoefficients), max(1-myDraftCoefficients)*1.1 ] );
                saveas(gcf,fullfile(Root, 'Out', [myHandler.picNmStr 'draftGlobalMins.jpg']),'jpg');
                if strcmpi(myHandler.config.Attributes.plotVisible, 'off')
                    close
                end
            end
            if numel(minLocs)
                myCoefficients(1:minLocs(1), 1) = min(myCoefficients( minLocs(1)+1 ));  %Height is equal to first informative sample.
            else
               outLog(myHandler, 'ACF preProcessing: can''t find a global minimum for cutting zero-time ACF runout.');
            end
            myHandler.signal.myPositions = myPositions;
            if str2double(myHandler.config.Attributes.slowNoiseRemoveEnable)
                [myHandler, myCoefficients] = slowNoiseRemove(myHandler, myCoefficients, myHandlerAver, plotEnable);
            end
            myHandler.signal.myCoefficients = myCoefficients;
            myHandler.signal.Fs = Fs;
           myHandler.signal.scale = 'ThresholdLin';
           myHandler.signal.cutNoiseLevel = false;
           myHandler.signal.windowWidth = 0;
           myHandler.signal.smooth = 0;
           myHandler.signal.cuttedZeroTimeRunout = 1;
           myHandler.signal.detrended = 0;
           myHandler.signal.slowNoiseRemoved = 0;
            if detrendEnable
                myHandler = detrendACF(myHandler, [], mode);
                myHandler.signal.detrended = 1;
            end
            %If it's not lower signal envelope mode.
            if ~nnz(strfind(mode, 'lowTrend'))
                myHandler.signalProcessed = myHandler.signal;
            end
        end
        
        function [myHandler, myCoefficients] = slowNoiseRemove(myHandler, myCoefficients, myHandlerAver, plotEnable)
            Root=fullfile(fileparts(mfilename('fullpath')),'..','..','..','..');
            %Make decision about removing slowly great non-info pulsations.
            myPositions = myHandler.signal.myPositions;
            
            [~, myHandlerAver] = getTheBestPeaksNum(myHandlerAver, 10);
            [~, ~, ~, signWidths, ~] = getTable(myHandlerAver);
            %Averaging to get slow pulsations.
            myConfAve = myHandlerAver.config; myConfAve.span = '2width';
            myHandlerAver = setConfig(myHandlerAver, myConfAve);
            [myHandlerAver, myDraftCoefficients] = windowAveraging(myHandlerAver);
            myHandlerAver = setSignal(myHandlerAver, myDraftCoefficients);
            [~, myHandlerAver] = getTheBestPeaksNum(myHandlerAver, 10);
            [~, ~, ~, smoothedWidths, ~] = getTable(myHandlerAver);
            diffCoeff = myCoefficients - double(myDraftCoefficients); myCoefficientsOrig = myCoefficients;
            mn = min(diffCoeff); if mn <= 0, diffCoeff = diffCoeff - mn + 1e-24; end
            outLog( myHandler, sprintf('Signal widths: %s; mean: %1.4f.\n', num2str(signWidths'), mean(signWidths)) );
            outLog( myHandler, sprintf('Smoothed widths: %s; mean: %1.4f.\n', num2str(smoothedWidths'), mean(smoothedWidths)) );
            
            rmsC = rms(myCoefficients); rmsD = rms(myDraftCoefficients);
            stdC = std(myCoefficients); stdD = std(myDraftCoefficients);
            outLog( myHandler, sprintf('\n Make decision about removing slowly great non-info pulsations.\n') );
            outLog( myHandler, sprintf('Signal RMS: %1.4f; smoothed signal RMS: %1.4f; threshold: %1.4f.\n', rmsC, rmsD, 0.75*rmsC) );
            outLog( myHandler, sprintf('Signal STD: %1.4f; smoothed signal STD: %1.4f; threshold: %1.4f.\n', stdC, stdD, 0.75*stdC) );
            widthFactor = mean(smoothedWidths)/mean(signWidths); outLog( myHandler, sprintf('Width factor: %1.5f.\n', widthFactor) );
%             if rmsD >= 0.75*rmsC
%                 %myCoefficients = diffCoeff; 
%                 outLog(myHandler, 'Slowly great non-info pulsations were removed.\n');
%                 myHandler.signal.myCoefficients = myCoefficients; %myHandler.signal.slowNoiseRemoved = 1;
%             end
                %Remove possible negative runout appearing during averaging.
                myConfigTemp = myHandler.config; myConfigTemp.Attributes.slowNoiseRemoveEnable='0';
                myConfigTemp.Attributes.fullSavingEnable='0'; %myHandler1 = myHandler.setConfig(myConfigTemp);
                myConfigTemp.Attributes.preProcessingEnable = '1';
                if isfield(myConfigTemp, 'correlation'),  myConfigTemp = rmfield(myConfigTemp, 'correlation'); end
                file.signal = -diffCoeff; file.Fs = myHandler.signal.Fs; mn = min(file.signal);
                        if mn <= 0, file.signal = file.signal - mn + 1e-24; end
                %Create temp object to cut runouts.
                myHandler1 = correlationHandler(file, myConfigTemp, myHandler.translations);
                %myHandler1 = myHandler1.setSignal(-diffCoeff); myHandler1 = myHandler1.acfPreProcess;
                mySignal = myHandler1.getSignal; diffCoeff = -mySignal.myCoefficients;
                %Remove negative parts of pulses. Think again.
                diffCoeff(diffCoeff < mean(diffCoeff)) = mean(diffCoeff); diffCoeff = diffCoeff - min(diffCoeff) + 1e-24;
                
            if widthFactor > 10
                outLog(myHandler, 'Slowly great non-info pulsations were removed.\n');
                %Get signal upper to remove negative samples and avoid bad sequences validation by low signal rms.
                myCoefficients = diffCoeff; mn = min(myCoefficients);
                if mn <= 0, myCoefficients = myCoefficients - mn + 1e-24; end
                myHandler.signal.myCoefficients = myCoefficients; myHandler.signal.slowNoiseRemoved = 1;
            end
                
            if plotEnable
                figure('units','points','Position',[0, 0, 800, 600], 'visible', myHandler.config.Attributes.plotVisible);
                plot(myPositions, myCoefficients); hold on; plot(myPositions, double((myDraftCoefficients)));
                plot(myPositions, repmat(rmsC, size(myDraftCoefficients)), 'r:'); plot(myPositions, repmat(rmsD, size(myDraftCoefficients)), 'g:');
                saveas(gcf, fullfile(Root, 'Out', [myHandler.picNmStr 'correlAver.jpg']),'jpg');
                if strcmpi(myHandler.config.Attributes.plotVisible, 'off')
                    close
                end
                figure('units','points','Position',[0, 0, 800, 600], 'visible', myHandler.config.Attributes.plotVisible);
                plot(myPositions, myCoefficientsOrig); hold on; plot(myPositions, diffCoeff);
                saveas(gcf, fullfile(Root, 'Out', [myHandler.picNmStr 'diffCoeff.jpg']),'jpg');
                if strcmpi(myHandler.config.Attributes.plotVisible, 'off')
                    close
                end
            end
        end
        
        function [myHandler, myCoefficients] = detrendACF(myHandler, myCoefficients, mode)
            if ~exist('myCoefficients', 'var')
                myCoefficients = [];
            end
            if isempty(myCoefficients)
                myCoefficients = myHandler.signal.myCoefficients;
            end
            checkingEnable = 0; lowerTrend = 0;
            if ~exist('mode', 'var')
                mode = '';
            end
            if strfind(mode, 'checkingEnable')
                checkingEnable = 1;
            end
            myCoefficientsDt = detrend(myCoefficients, 'linear');
            myCoefficientsTrend = myCoefficients - myCoefficientsDt;
            if checkingEnable
                outLog(myHandler, 'Need 2 detrend checking.\n');
                trendAmpl = abs(myCoefficientsTrend(1) - myCoefficientsTrend(end));
                outLog( myHandler, sprintf('Trends amplitude: %2.4f; signal RMS: %2.4f.\n', trendAmpl, rms(myCoefficients)) );
                if trendAmpl < rms(myCoefficients)
                    outLog(myHandler, 'The trend is low, detrend is unnecessary.\n');
                    return; %Don't process a signals with low trends.
                end
                outLog(myHandler, 'The trend is high, detrending...\n');
            end
            if strfind(mode, 'lowTrend')
                myConfigAver.span = '3';
                myConfigAver.Attributes.detrend4peaksFinding = '1';
                myConfigAver.theBextPeaksNum = 'glob';
                myHandlerAve = signalAveragingHandler(-double(myHandler.signal.myCoefficients), myConfigAver);
                [~, myResultSignalLo] = highPeaksTopsSmoothing(myHandlerAve);
                myCoefficientsTrend = -myResultSignalLo - detrend(-myResultSignalLo, 'linear');
                myCoefficientsDt = myCoefficients - reshape(myCoefficientsTrend, size(myCoefficients));
            end
            myCoefficients = myCoefficientsDt;
            coeffsMin = min(myCoefficients);
            if coeffsMin < 0
                myCoefficients = myCoefficients - coeffsMin;
            end
            if nnz(myCoefficients == 0)
                myCoefficients = myCoefficients + 1e-24;  %Min - base val.
            end
            myHandler.signal.myCoefficients = myCoefficients;
        end
        
        
        % FINDGLOBALPEAKS function returns only global peaks of correlation
        % function (myCF) for further period checking
        function [globalLocs,globalPeaks] = findGlobalPeaks(myHandler, minPeaksDictance, varargin)
            Root=fullfile(fileparts(mfilename('fullpath')),'..','..','..','..');
            globalLocs = []; globalPeaks = [];
            myConfig = myHandler.config.peaksDistanceEstimation;
            plotEnable = myHandler.config.Attributes.fullSavingEnable;
             myCF = double(myHandler.signal.myCoefficients);
             cutNoiseLevel = num2str(double(myHandler.signal.cutNoiseLevel));
               
            switch nargin
                case 1
                    minPeaksDictance = 100; % maxFrequency ~= 1kHz
                    threshold = 0.05; %
                case 2
                    threshold = 0.05; %
                otherwise
                    threshold = str2double( myConfig.(varargin{1}).Attributes.(varargin{2}) );
            end
            
            [height,locs,~,proms] = findpeaks(myCF);
            if numel(locs) <=1
               locs = [];
               return;
            end
            heightSignal = zeros(size(myCF));
            prominenceSignal = zeros(size(myCF));
            for i = 1:1:length(locs)
                heightSignal(locs(i),1) = height(i);
                prominenceSignal(locs(i),1) = proms(i);
            end
            
            if myHandler.signal.cutNoiseLevel
                globalPeaks = heightSignal;
            else
                %"Globality" - hei*prom - makes good peaks higher, low -
                %lower. It's square measure, for good peaks approx. hei^2.
                globalPeaks = bsxfun(@times,heightSignal, prominenceSignal);
            end
%             myPosit = myHandler.signal.myPositions;
            %gag...
            if numel(varargin) < 3
                varargin{3} = '';
            end
            %..gag
            switch varargin{3}
                case 'abs'

                case 'rel'
                    [globals] = findpeaks(globalPeaks, 'SortStr', 'descend');
                    %Get necessary the best peaks
                    myHandlerAver = signalAveragingHandler(globalPeaks, struct('span', '2'));
%                     myHandlerAver = windowAveraging(myHandlerAver);
                    %Peaks table of 1/10 the best peaks of peaks number.
                    [~, globalsPT] = getSpanAuto(myHandlerAver);
                    peaksNum = min([50 numel(globals)]);
                    if numel(globalsPT) < peaksNum
                       globalsPT = globals(1:peaksNum);
                    else
                        globalsPT = globalsPT(1:peaksNum);
                    end
                    threshold = (mean(globalsPT) + std(globalsPT))*threshold;
                otherwise
                     threshold = max(globalPeaks)*threshold;
            end
            [~, globalLocs] = findpeaks(globalPeaks, 'MinPeakProminence', threshold, 'MinPeakDistance', minPeaksDictance);
            if str2double(plotEnable)
                figure('units','points','Position',[0 ,0 ,800,600]);
                findpeaks(globalPeaks, 'MinPeakProminence', threshold, 'MinPeakDistance', minPeaksDictance, 'Annotate', 'extents');
                saveas(gcf,fullfile(Root, 'Out', [myHandler.picNmStr varargin{1} '_' varargin{2} '_commPict_cutNoiseLevel' cutNoiseLevel '.jpg']),'jpg');
                if strcmpi(myHandler.config.Attributes.plotVisible, 'off')
                    close
                end
            end
        end
        
        %Make a common peaks table from periodicy data computed different methods.
        function myHandler = peakTableComparison(myHandler)
            thresholdStrings = {'low' 'average' 'high'};
            btNum = [myHandler.peaksTable.PeaksPositions];  %Numbers - peaks positions.
            btLb = arrayfun(@(x) reshape(x.thresholdLevel, 1, []), myHandler.peaksTable, 'UniformOutput', false);  %According threshold labels.
            btLb = [btLb{:}];
            btKnd = arrayfun(@(x) reshape(x.thresholdKind, 1, []), myHandler.peaksTable, 'UniformOutput', false);  %According threshold types.
            btKnd = [btKnd{:}];
            [PeaksPositions, ia, ic] = unique(btNum);
            %similarValue - indexes of orig's elems in unique; matches have a similar idxs.
            %accordLabelsIdxs is set of idxs of orig's simil elem's idxs.
            [ similarValue, ~, accordLabelsIdxs] = getSimilars( ic, struct('range', '0') );
            btResLb = cell(size(ia));
            btResKnd = cell(size(ia));
            aloneIdxs = 1:numel(btLb);
            for j = 1:numel(accordLabelsIdxs)
                if ~iscell(accordLabelsIdxs)
                    break;  %If there are no similar elements.
                end
                thresholdLevel = btLb(accordLabelsIdxs{j});
                theHigherThrNum = [];
                %Find all threshold levels of the similar peaks and choose the higher.
                for i = 1:numel(thresholdLevel)
                    k = strfind(thresholdStrings, thresholdLevel(i));
                    threshNum = cellfun(@(x) ~isempty(x), k); %Number of the current threshold level.
                    theHigherThrNum = [theHigherThrNum find(threshNum)];
                end
                theHigherThrNum  = max(theHigherThrNum);
                btResLb(similarValue(j)) = thresholdStrings(theHigherThrNum);
                ThrKind = btKnd(accordLabelsIdxs{j});  %Remember all threshold kinds.
                if iscell([ThrKind{:}])
                    ThrKind = [ThrKind{:}];
                end
                btResKnd{similarValue(j)} = unique(ThrKind);
                aloneIdxs(accordLabelsIdxs{j}) = 0;  %Exclude idxs of non-alone elems in orig's idxs vector.
                %ic(similarValue(j)) = 0; %Also clear unique idxs.
                ic(ic == similarValue(j)) = zeros( size(ic( ic == similarValue(j) )) ); %Also clear unique idxs.
            end
            aloneIdxs = nonzeros(aloneIdxs);
            ic = unique(nonzeros(ic));
            aloneLabels = btLb(aloneIdxs);
            %Find threshold levels of alone peaks.
            aloneThrStrsNums = [];
            for i = 1:numel(aloneLabels)
                k = strfind(thresholdStrings, aloneLabels(i));
                threshNum = cellfun(@(x) ~isempty(x), k); %Number of the current threshold level.
                aloneThrStrsNums = [aloneThrStrsNums find(threshNum)];
            end
            btResLb(ic) = thresholdStrings(aloneThrStrsNums);
            btResKnd(ic) = btKnd(aloneIdxs);
            myPeaksTable.PeaksPositions = PeaksPositions;
            myPeaksTable.thresholdLevel = btResLb;
            myPeaksTable.thresholdKind = btResKnd;
            myHandler.peaksTable = myPeaksTable;
        end
        
        
    end %end protected methods.
    
    methods (Static = true, Access = protected)
        
        % PEAKDISTANCEESTIMATION function 
        function [peakDistance, periodsNumber, PeriodicyData] = peaksDistanceEstimation(peaks, config)
            
            % default parameters
            peaksPerFrame = str2double(config.Attributes.peaksPerFrame);
            peaksOverlap = str2double(config.Attributes.peaksOverlap);
            validationThreshold = str2double(config.Attributes.validationThreshold);
            
            DistanceData = [];
            PeriodicyData.peaksIdxs = [];

            % Create matrix containing found peaks 
            peaksNumber = numel ( peaks );
            framesNumber = floor((peaksNumber-peaksPerFrame)/(peaksPerFrame-peaksOverlap));
            diffDistanceMatrix = zeros(framesNumber,peaksPerFrame);
            increment = peaksPerFrame - peaksOverlap;
            startPosition = 1;
            
            if framesNumber<=2
                peakDistance = nan;
                periodsNumber = 0;
                return;
            end
            
            peaks = reshape(peaks, [], 1);
            for i=1:1:framesNumber
               diffDistanceMatrix(i,:) = peaks(startPosition:startPosition+peaksPerFrame-1,1);
               startPosition = startPosition + increment;
            end
            %peaks is a vector of peaks positions in correlogram. diffDistanceMatrix is
            %positions of peaks with division on frames with overlap.
            %It's elements accord to elements of other matricies with peak data.
            PeaksCorrelPositionMatrix = diffDistanceMatrix;
            
            % Create table of distances between peaks and find the similar
            % ones
            diffDistanceMatrix = diff(diffDistanceMatrix,1,2);
            meanDistanceVector = mean(diffDistanceMatrix,2);
            stdDistanceVector = std(diffDistanceMatrix,0,2);
            %Elements where relation STD/mean < threshold, i.e. variance is low
            %level in comparacy to average distance.
            validationVector = (bsxfun(@rdivide,stdDistanceVector,meanDistanceVector)<=validationThreshold);
            validFrames = find(validationVector);
            
            if isempty(validFrames)
                peakDistance = nan;
                periodsNumber = 0;
                return;
            end
            
             distanceVector = meanDistanceVector(validFrames,1);

            % Find similar distances in distanceVector to detect true peaks period
%             file.signal = distanceVector;
            %peakDistance is mean on distancies in similar frames.
            %periodsNumber is a sum of periods (ACF's peaks) in the similar periodicies.
            printEnable = double(strcmp(config.printEnable, '1') || strcmp(config.printEnable, '2'));
            [ peakDistance, periodsNumber, ValidIndexSimilars ] = getSimilars( distanceVector );
            if printEnable && (~nnz(periodsNumber)), disp('There is no stable period in the signal.'); end
            %Elements of peakDistance, periodsNumber accord to valid periodicies,
            %ValidIndexSimilars are vectors with the similar frames indicies, that put together periodicy.

                %Matricies with data for each peak: positions, distance;
                %Frames data: mean (i.e. distance), STD, validationVector for choosing valid frames.
                DitsanceData = struct('PeaksCorrelPositionMatrix', PeaksCorrelPositionMatrix, 'diffDistanceMatrix', diffDistanceMatrix, 'meanDistanceVector', meanDistanceVector, 'stdDistanceVector', stdDistanceVector, 'validationVector', validationVector);
                DitsanceData.ValidIndexSimilars = ValidIndexSimilars;
                PeriodicyData = PeriodicyDataFormStruct(DitsanceData, peaksOverlap);

            if isempty(peakDistance)
                if printEnable, fprintf('Correlation peaks finding: there no valid period in the signal.'); end
                peakDistance = nan;
                periodsNumber = 0;
            end
                 
            % check found periods
%             [ peakDistance1, periodsNumber1 ] = getSimilars( [peakDistance;distance] );
            
        end
        
        % PEAKSDISTANCEVALIDATION function 
        function [status, trueValue] = peaksDistanceValidation(myCoefficients, myFs, peakDistanceNominal)
           
            file.signal = myCoefficients;
            file.Fs = myFs;
            file.frequencyNominal = myFs/peakDistanceNominal;
            
            parameters.envelopeEnable = '0';
            [ result ] = correlogram( file, parameters );
            
            myCorrelogram = result.correlogram;
            myFrequency = result.frequency;
            
            [heights,locs,~,proms] = findpeaks(myCorrelogram);
            
            heightSignal = zeros(size(myCorrelogram));
            prominenceSignal = zeros(size(myCorrelogram));
            for i = 1:1:length(heights)
                heightSignal(locs(i)) = heights(i);
                prominenceSignal(locs(i)) = proms(i);
            end
            
            interf = bsxfun(@times,heightSignal, prominenceSignal);
            findpeaks(interf);
            
            status = [];
            trueValue = frequency;
        end
        
        
        
        function thresholdLevNum = thresholdLevels2Nums(thresholdLevels)
            thresholdStrings = {'low' 'average' 'high'};
                for j = 1:numel(thresholdStrings)
                    levPositions = strfind(thresholdLevels, thresholdStrings(j));  %Find the current threshold level.
                    threshNum = cellfun(@(x) ~isempty(x), levPositions); %Number of the current threshold level.
                    threshNum = find(threshNum);
                    thresholdLevNum(threshNum) = repmat( j, size(thresholdLevels(threshNum)) );  %Instesd strings - numbers; higher num - higher thresh.
                end
        end
        
        
        % CREATEVALIDATIONCONTAINER function ... 
        function [container] = createValidationContainer()
           
            container = newfis('optipaper'); 
            
            % INPUT:
            % Init 3-state @height variable
            container = addvar(container,'input','height',[-0.5 5000]);
            container = addmf(container,'input',1,'low','dsigmf',[5000 -0.5 5000 5]);
            container = addmf(container,'input',1,'average','dsigmf',[5000 5 5000 10]);
            container = addmf(container,'input',1,'high','dsigmf',[5000 10 5000 5000]);
            
            % Init 4-state @globalNumber  variable
            container = addvar(container,'input','globalPeaksNumber',[-0.5 10.5]);
            container = addmf(container,'input',2,'one','dsigmf',[20.5 0.5 20.5 1.5]);
            container = addmf(container,'input',2,'two','dsigmf',[20.5 1.5 20.5 2.5]);
            container = addmf(container,'input',2,'many','dsigmf',[20.5 2.5 20.5 10.5]);
            container = addmf(container,'input',2,'no','dsigmf',[20.5 -0.5 20.5 0.5]);
            
            % Init 2-state @isGlobal variable
            container = addvar(container,'input','isGlobal',[-0.5 1.5]);
            container = addmf(container,'input',3,'false','dsigmf',[20.5 -0.5 20.5 0.5]);
            container = addmf(container,'input',3,'true','dsigmf',[20.5 0.5 20.5 1.5]);
            
            % Init 3-state @globalOrder variable
            container = addvar(container,'input','globalOrder',[-0.5 10.5]);
            container = addmf(container,'input',4,'first','dsigmf',[20.5 0.5 20.5 1.5]);
            container = addmf(container,'input',4,'second','dsigmf',[20.5 1.5 20.5 2.5]);
            container = addmf(container,'input',4,'other','dsigmf',[20.5 2.5 20.5 10.5]);
            container = addmf(container,'input',4,'no','dsigmf',[20.5 -0.5 20.5 0.5]);
            
            % Init 3-state @heightPercentDelta variable
            container = addvar(container,'input','heightPercentDelta',[-0.5 100.5]);
            container = addmf(container,'input',5,'low','dsigmf',[100.5 -0.5 100.5 10.5]);
            container = addmf(container,'input',5,'average','dsigmf',[100.5 10.5 100.5 25.5]);
            container = addmf(container,'input',5,'high','dsigmf',[100.5 25.5 100.5 100.5]);
            
            % OUTPUT:
            % Init 3-state @result variable
            container = addvar(container,'output','validity',[-0.375 1.375]);
            container = addmf(container,'output',1,'none','gaussmf', [0.125 0]);
            container = addmf(container,'output',1,'mbValid','gaussmf', [0.125 0.5]);
            container = addmf(container,'output',1,'valid','gaussmf', [0.125 1]);
            
            %%RULEs:
            % height, globalPeaksNumber, isGlobal, globalOrder, heightPercentDelta    result and etc]

            
            ruleList = [
                
                % hight peaks
                        3  1  2  1  0    3  1  1; 
                        3  2  2  1  0    3  1  1; 
                        3  2  2  2  1    3  1  1;
                        3  2  2  2  2    2  1  1;
                        3  2  2  2  3    1  1  1;
                        3  2  2  3  0    1  1  1;
                        3  3  2  1  0    2  1  1;
                        3  3  2  2  0    1  1  1;
                        
                % average peaks    
                        2  1  2  1  0    3  1  1; 
                        2  1  2  2  1    2  1  1; 
                        2  1  2  2 -1    1  1  1;
                        2  1  2  3  0    1  1  1;
                        
                % average peaks          
                        1  1  2  1  0    2  1  1;
                        1  1  2  2  0    1  1  1;
                        1 -1  0  0  0    1  1  1;

                % nonvalid                         
                        0  0  1  0  0    1  1  1;  
                        0  4  0  0  0    1  1  1;  
                        0  0  0  3  0    1  1  1; 
                        0  0  0  0  3    1  1  1; 
                        0  0  0  4  0    1  1  1;
                        ];
            
                    
            container=addrule(container,ruleList);
                    
        end
        
        % VALIDATIONPROCESSING function ...
        function [status] = validationProcessing(container, periodsNumber, i)
            
            maxValue = max(periodsNumber);
            height = periodsNumber(i);
            
            globalThreshold = 0.5 * maxValue;
            
            globalVector = bsxfun(@ge,periodsNumber, globalThreshold);
            isGlobal = globalVector(i,1);
            globalPeaksNumber = nnz(globalVector);
            
            if isGlobal
                periodsNumberSorted = sort(periodsNumber, 'descend');
                globalOrder = find(periodsNumberSorted == height,1);
                heightPercentDelta = 100 - height/ maxValue*100;
            else
                globalOrder = 0;
                heightPercentDelta = 100;
            end
             
            inputArgs = [height,globalPeaksNumber,isGlobal,globalOrder,heightPercentDelta];
            status = evalfis(inputArgs,container);
            
        end
        
        % CREATETABLEVALIDATIONCONTAINER function ...
        function [container] = createTableValidationContainer()
            
            container = newfis('optipaper'); 
            
            % Input:
            % Init 3-state @validityHigh variable
            container = addvar(container,'input','validityHigh',[-0.25 1.25]);
            container = addmf(container,'input',1,'nonvalid','dsigmf', [40.5 -0.25 40.5 0.25]);
            container = addmf(container,'input',1,'mbValid','dsigmf', [40.5 0.25 40.5 0.75]);
            container = addmf(container,'input',1,'valid','dsigmf', [40.5 0.75 40.5 1.25]);
            
            % Init 3-state @validityAverage variable
            container = addvar(container,'input','validityAverage',[-0.25 1.25]);
            container = addmf(container,'input',2,'nonvalid','dsigmf', [40.5 -0.25 40.5 0.25]);
            container = addmf(container,'input',2,'mbValid','dsigmf', [40.5 0.25 40.5 0.75]);
            container = addmf(container,'input',2,'valid','dsigmf', [40.5 0.75 40.5 1.25]);
            
            % Init 3-state @validityLow variable
            container = addvar(container,'input','validityLow',[-0.25 1.25]);
            container = addmf(container,'input',3,'nonvalid','dsigmf', [40.5 -0.25 40.5 0.25]);
            container = addmf(container,'input',3,'mbValid','dsigmf', [40.5 0.25 40.5 0.75]);
            container = addmf(container,'input',3,'valid','dsigmf', [40.5 0.75 40.5 1.25]);
            
            % OUTPUT:
            % Init 3-state @result variable
            container = addvar(container,'output','validity',[-0.375 1.375]);
            container = addmf(container,'output',1,'nonvalid','gaussmf', [0.125 0]);
            container = addmf(container,'output',1,'mbValid','gaussmf', [0.125 0.5]);
            container = addmf(container,'output',1,'valid','gaussmf', [0.125 1]);
            
            %%RULEs:
            % validityHigh, validityAverage, validityLow,   result and etc]

            
            ruleList = [
                
                        3  3  3    3  1  1; 
                        3  3  2    3  1  1; 
                        3  3  1    3  1  1;
                        3  2  3    3  1  1;
                        3  2  2    3  1  1;
                        3  2  1    3  1  1;
                        3  1  1    2  1  1;
                        3  1  3    2  1  1;
                        3  1  2    2  1  1;
                        
                        2  3  3    3  1  1;
                        2  3  2    3  1  1;
                        2  3  1    3  1  1;
                        2  2  3    3  1  1;
                        2  2  2    2  1  1;
                        2  2  1    2  1  1;
                        2  1  3    2  1  1;
                        2  1  2    2  1  1;
                        2  1  1    1  1  1;
                        
                        1  3  3    3  1  1;
                        1  3  2    3  1  1;
                        1  3  1    3  1  1;
                        1  2  3    3  1  1;
                        1  2  2    2  1  1;
                        1  2  1    2  1  1;
                        1  1  3    3  1  1;
                        1  1  2    2  1  1;
                        1  1  1    1  1  1;
                        
                        ];
            
                    
            container=addrule(container,ruleList);
        end
        
    end %end of the static methods.
end


