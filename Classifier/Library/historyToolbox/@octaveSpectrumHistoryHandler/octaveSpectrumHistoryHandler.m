classdef octaveSpectrumHistoryHandler < historyHandler
    % OCTAVESPECTRUMHISTORYHANDLER
    % Discription: Class is designed to evaluate the history of the octave spectrum:
    % 1) Get data from history
    % 2) Evaluation of trend of each octave
    % 3) Result evaluation of trends, with threshold level (set by the user) 
    % Input: history data 
    % Output structure: current data of history files, trend evaluation of 
    % each octave, result status.
    
    properties (Access = protected)
        % Input properties
        parameters % configurable parameters
    end
    
    methods (Access = public)
        % Constructor function
        function [myOctaveSpectrumHistoryHandler] = octaveSpectrumHistoryHandler(myConfig, myFiles, myTranslations, myXmlToStructHistory)
            if nargin < 1
               error('There are not enough input arguments!'); 
            end
            
            myContainerTag = 'octaveSpectrum';
            myOctaveSpectrumHistoryHandler = myOctaveSpectrumHistoryHandler@historyHandler(myConfig, myFiles, myContainerTag, myTranslations, myXmlToStructHistory);
            
            % Set standard parameters
            parameters = [];
            if (isfield(myConfig.config.parameters.evaluation.spectra, 'octaveSpectrum'))
            	parameters.warningLevel = str2num(myConfig.config.parameters.evaluation.spectra.octaveSpectrum.Attributes.warningLevel);
                parameters.damageLevel = str2num(myConfig.config.parameters.evaluation.spectra.octaveSpectrum.Attributes.damageLevel);
                parameters.filterMode = myConfig.config.parameters.evaluation.spectra.octaveSpectrum.Attributes.filterMode;
            end
            if isfield(myFiles.files.history.Attributes, 'actualPeriod')
                parameters.maxPeriod = myFiles.files.history.Attributes.actualPeriod;
            end
            parameters.debugModeEnable = myConfig.config.parameters.common.debugModeEnable.Attributes.value;
            methodPlotEnable = myConfig.config.parameters.evaluation.spectra.octaveSpectrum.Attributes.plotEnable;
            historyPlotEnable = myConfig.config.parameters.evaluation.history.Attributes.plotEnable;
            if strcmp(methodPlotEnable, historyPlotEnable)
                parameters.plotEnable = methodPlotEnable;
            else
                parameters.plotEnable = '0';
            end
            parameters.plots = myConfig.config.parameters.evaluation.plots.Attributes;
            parameters.plotVisible = myConfig.config.parameters.common.printPlotsEnable.Attributes.visible;
            parameters.plotTitle = myConfig.config.parameters.common.printPlotsEnable.Attributes.title;
            parameters.printPlotsEnable = myConfig.config.parameters.common.printPlotsEnable.Attributes.value;
            
            myOctaveSpectrumHistoryHandler.parameters = parameters;
            
            % Craete decision making container to calculate result status 
            myOctaveSpectrumHistoryHandler = createFuzzyContainer(myOctaveSpectrumHistoryHandler);
            myOctaveSpectrumHistoryHandler = historyProcessing(myOctaveSpectrumHistoryHandler);
        end
        
        % FILLDOCNODE function fills docNode document with calculated
        % result data
        function [docNode] = fillDocNode(myOctaveSpectrumHistoryHandler, docNode)
            
            iLoger = loger.getInstance;
            myResultStruct = getResult(myOctaveSpectrumHistoryHandler);
            
            % Replace existing spm node with new one
            docRootNode = docNode.getDocumentElement;
            if hasChildNodes(docRootNode)
                childNodes = getChildNodes(docRootNode);
                numChildNodes = getLength(childNodes);
                for count = 1:numChildNodes
                    theChild = item(childNodes,count-1);
                    name = toCharArray(getNodeName(theChild))';
                    if strcmp(name,'octaveSpectrum')
                        docRootNode.removeChild(theChild);
                        break;
                    end
                end
            end
            
            octaveSpectrumNode = docNode.createElement('octaveSpectrum');
            docRootNode.appendChild(octaveSpectrumNode);
            
            status = docNode.createElement('status');
            status.setAttribute('value',vector2strStandardFormat(myResultStruct.result)); 
            
            informativeTagsNode = docNode.createElement('informativeTags');
            
            frequenciesNode = docNode.createElement('frequencies');
            frequenciesNode.setAttribute('value',vector2strStandardFormat(myResultStruct.frequencies));     
            
            magnitudesNode = docNode.createElement('magnitudes');
            magnitudesNode.setAttribute('value',vector2strStandardFormat(myResultStruct.magnitudes));
            
            tagsNode = docNode.createElement('tags');
            if isempty(myResultStruct.tags{1})
                tagsNode.setAttribute('value',[]);
            else
                tagsNode.setAttribute('value',vector2strStandardFormat(myResultStruct.tags));
            end
                
            trainingPeriodMeanNode = docNode.createElement('trainingPeriodMean');
            trainingPeriodMeanNode.setAttribute('value',vector2strStandardFormat(myResultStruct.trainingPeriodMean));
            trainingPeriodStdNode = docNode.createElement('trainingPeriodStd');
            trainingPeriodStdNode.setAttribute('value',vector2strStandardFormat(myResultStruct.trainingPeriodStd));
            durationStatusNode = docNode.createElement('durationStatus');
            durationStatusNode.setAttribute('value',vector2strStandardFormat(myResultStruct.durationStatus));
            percentGrowthNode = docNode.createElement('percentGrowth');
            percentGrowthNode.setAttribute('value',vector2strStandardFormat(myResultStruct.percentGrowth));
            
            informativeTagsNode.appendChild(frequenciesNode);
            informativeTagsNode.appendChild(magnitudesNode);
            informativeTagsNode.appendChild(tagsNode);
            informativeTagsNode.appendChild(trainingPeriodMeanNode);
            informativeTagsNode.appendChild(trainingPeriodStdNode);
            informativeTagsNode.appendChild(durationStatusNode);
            informativeTagsNode.appendChild(percentGrowthNode);
            
            octaveSpectrumNode.appendChild(status);
            octaveSpectrumNode.appendChild(informativeTagsNode);
            printComputeInfo(iLoger, 'octaveSpectrumHistoryHandler', 'docNode structure was successfully updated.');
        end
    end
    
    methods (Access = protected)  
        % HISTORYPROCESSING function calculate status
        function [myOctaveSpectrumHistoryHandler] = historyProcessing(myOctaveSpectrumHistoryHandler)
            % Loger initialization
            iLoger = loger.getInstance;
            
            % Get data from history files
            myHistoryContainer = getHistoryContainer(myOctaveSpectrumHistoryHandler);
            myHistoryTable = getHistoryTable(myHistoryContainer); 
            myFiles = getFiles(myOctaveSpectrumHistoryHandler);
            cntOctave = length(myHistoryTable.magnitudes(1,:));
            warningLevel = myOctaveSpectrumHistoryHandler.parameters.warningLevel;
            damageLevel = myOctaveSpectrumHistoryHandler.parameters.damageLevel;
            
            if isempty(myHistoryTable.magnitudes(:,1))
                printComputeInfo(iLoger, 'Octave spectrum history', 'There is empty history.');
                myOctaveSpectrumHistoryHandler.result = [];
                return
            end
            
            % Set config parametrs 
            myConfig = getConfig(myOctaveSpectrumHistoryHandler);
            trendParameters = [];   
            if (isfield(myConfig.config.parameters.evaluation.history, 'trend'))
                trendParameters = myConfig.config.parameters.evaluation.history.trend.Attributes;
            end
            trendParameters.maxPeriod = myOctaveSpectrumHistoryHandler.parameters.maxPeriod;
           
            result = zeros(1,cntOctave);
            durationStatus = zeros(1,cntOctave);
            tresholds = nan(3, cntOctave);
            
            if ~isempty(warningLevel) && (~isempty(damageLevel))
                if cntOctave ~= length(warningLevel) || ...
                       cntOctave ~= length(damageLevel) ||...
                       length(warningLevel) ~= length(damageLevel)

                    warningLevel = ones(1,cntOctave)*mean(warningLevel);
                    damageLevel = ones(1,cntOctave)*mean(damageLevel);
                end
            end
                
            % Calculation of trend status
            actualPeriod = length(myHistoryTable.magnitudes(:,1));
            for i=1:1:cntOctave
                myTempObjTrendHandler = trendHandler(myHistoryTable.magnitudes(:,i), trendParameters, myHistoryTable.date);
                tempTrendStatus = getResult(myTempObjTrendHandler);
                tempTrendObj = getTrend(myTempObjTrendHandler);
                signalTrend = getSignal(tempTrendObj);
                tempTrendVolatility = getSignalVolatility(getTrend(myTempObjTrendHandler));
                
                if ~isempty(warningLevel) && (~isempty(damageLevel))
                    myHistoryTable.tags{1,i} = myOctaveSpectrumHistoryHandler.thresholdsEvaluation ...
                        (warningLevel(1,i), damageLevel(1,i), signalTrend(end));
                else
                    myHistoryTable.tags{1,i} = '';
                end
                if ~isempty(tempTrendVolatility)
                    % Get training parameters and status
                    [myHistoryTable.tags{1,i}, myHistoryTable.trainingPeriodMean{1,i}, myHistoryTable.trainingPeriodStd{1,i}, tresholds(:,i)] =  ...
                        getTrainingPeriodAndStatus(myHistoryTable.trainingPeriodStd(:,i), myHistoryTable.trainingPeriodMean(:,i),  ...
                        myFiles, getDate(tempTrendObj), signalTrend, myHistoryTable.tags{1,i}, myHistoryTable.date);  
                    if ~isempty(myHistoryTable.tags{1,i})
                        [durationStatus(1,i), compressionData] = myOctaveSpectrumHistoryHandler.evaluateDurationStatus(trendParameters, ...
                            myHistoryTable.tags(:,i), myHistoryTable.date);
                        statusEvaluated = myOctaveSpectrumHistoryHandler.evaluateStatus(compressionData.data, myFiles);
                        
                        inputArgs = [actualPeriod, double(str2numStatus.(statusEvaluated{1,1})), tempTrendStatus];
                        result(1,i) = evalfis(inputArgs, myOctaveSpectrumHistoryHandler.fuzzyContainer);
                    else
                        result(1,i) = -0.01;
                        myHistoryTable.tags{1,i} = 'NaN';
                    end
                else
                    myHistoryTable.tags{1,i} = 'NaN';
                    result(1,i) = -0.01;
                end
            end
            
            if ~isnan(tresholds(1, : ))
                warningLevel  = tresholds(2, : );
                damageLevel = tresholds(3, : );
            elseif isempty(myOctaveSpectrumHistoryHandler.parameters.warningLevel) || ...
                    isempty(myOctaveSpectrumHistoryHandler.parameters.damageLevel)
                warningLevel = [];
                damageLevel = [];
            end
            
            % Record results to the final structure
            myOctaveSpectrumHistoryHandler.result.frequencies = myHistoryTable.frequencies(1,:);
            myOctaveSpectrumHistoryHandler.result.magnitudes = myHistoryTable.magnitudes(1,:);
            myOctaveSpectrumHistoryHandler.result.tags = myHistoryTable.tags(1,:);
            myOctaveSpectrumHistoryHandler.result.result = round(result*100);
            myOctaveSpectrumHistoryHandler.result.durationStatus = durationStatus;
            myOctaveSpectrumHistoryHandler.result.trainingPeriodMean = myHistoryTable.trainingPeriodMean(1,:);
            myOctaveSpectrumHistoryHandler.result.trainingPeriodStd = myHistoryTable.trainingPeriodStd(1,:);
            if ~isempty(cell2mat(myHistoryTable.trainingPeriodMean(1,:)))
                myOctaveSpectrumHistoryHandler.result.percentGrowth = (round(myHistoryTable.magnitudes(1,:)./cell2mat(myHistoryTable.trainingPeriodMean(1,:)),2) - ones(size(myHistoryTable.trainingPeriodMean(1,:))))*100;
            else
                myOctaveSpectrumHistoryHandler.result.percentGrowth = nan(size(myHistoryTable.trainingPeriodMean(1,:)));
            end
            
            if str2double(myOctaveSpectrumHistoryHandler.parameters.plotEnable)
                plotAndPrint(myOctaveSpectrumHistoryHandler, myHistoryTable, warningLevel, damageLevel);
                
                if checkImages(fullfile(pwd, 'Out'), 'history-octaveSpectrum-acc-', myOctaveSpectrumHistoryHandler.parameters.plots.imageFormat)
                    printComputeInfo(iLoger, 'octaveSpectrumHistoryHandler', 'The method images were saved.')
                end
            end
			printComputeInfo(iLoger, 'octaveSpectrumHistoryHandler', 'octaveSpectrum history processing COMPLETE.');
        end
        
        % PLOTANDPRINT function draws and saves plots
        function plotAndPrint(myOctaveSpectrumHistoryHandler, myHistoryTable, warningLevel, damageLevel)
            
            % Get parameters
            Translations = myOctaveSpectrumHistoryHandler.translations;
            
            plotVisible = myOctaveSpectrumHistoryHandler.parameters.plotVisible;
            plotTitle = myOctaveSpectrumHistoryHandler.parameters.plotTitle;
            printPlotsEnable = str2double(myOctaveSpectrumHistoryHandler.parameters.printPlotsEnable);
            sizeUnits = myOctaveSpectrumHistoryHandler.parameters.plots.sizeUnits;
            imageSize = str2num(myOctaveSpectrumHistoryHandler.parameters.plots.imageSize);
            fontSize = str2double(myOctaveSpectrumHistoryHandler.parameters.plots.fontSize);
            imageFormat = myOctaveSpectrumHistoryHandler.parameters.plots.imageFormat;
            imageQuality = myOctaveSpectrumHistoryHandler.parameters.plots.imageQuality;
            imageResolution = myOctaveSpectrumHistoryHandler.parameters.plots.imageResolution;
            
            spectrum(1, : ) = myHistoryTable.magnitudes(1, : );
            octaveMagnitude = myHistoryTable.magnitudes(1, : );
            
            if ~isempty(warningLevel)
                warningPositions = (octaveMagnitude < damageLevel) & (octaveMagnitude >= warningLevel);
                damagePositions = (octaveMagnitude >= damageLevel);
            else
                warningPositions = [];
                damagePositions = [];
            end
            
            if nnz(warningPositions) ~= 0 && nnz(damagePositions) == 0
                spectrum(1, warningPositions) = warningLevel(1, warningPositions);
                spectrum(2, warningPositions) = octaveMagnitude(1, warningPositions) - warningLevel(1, warningPositions);
            end
            if nnz(damagePositions) ~= 0
                spectrum(1, damagePositions) = warningLevel(1, damagePositions);
                spectrum(2, damagePositions) = damageLevel(1, damagePositions) - warningLevel(1, damagePositions);
                spectrum(3, damagePositions) = octaveMagnitude(1, damagePositions) - damageLevel(1, damagePositions);
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
                title(myAxes, [strtok(myOctaveSpectrumHistoryHandler.parameters.filterMode), ' ', ...
                    upperCase(Translations.octaveSpectrum.Attributes.name, 'allFirst')]);
            end
            % Figure labels
            xlabel(myAxes, [upperCase(Translations.centralFrequency.Attributes.name, 'first'), ', ', ...
                upperCase(Translations.frequency.Attributes.value, 'first')]);
            ylabel(myAxes, [upperCase(Translations.magnitude.Attributes.name, 'first'), ', ', Translations.acceleration.Attributes.value]);
            % Replace the x-axis values by the central frequencies
            xticks(myAxes, linspace(1, length(octaveMagnitude), length(octaveMagnitude)));
            xticklabels(myAxes, round(myHistoryTable.frequencies(1, : ) * 100) / 100);
            xtickangle(myAxes, 90);
            
            if printPlotsEnable
                % Save the image to the @Out directory
                imageNumber = '1';
                fileName = ['history-octaveSpectrum-acc-', imageNumber];
                fullFileName = fullfile(pwd, 'Out', fileName);
                print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
            end
            
            % Close figure with visibility off
            if strcmpi(plotVisible, 'off')
                close(myFigure)
            end
        end

        % CREATEFUZZYCONTAINER function create rules to calculate status  
        function [myOctaveSpectrumHistoryHandler] = createFuzzyContainer(myOctaveSpectrumHistoryHandler)            
            maxPeriod = str2double(myOctaveSpectrumHistoryHandler.parameters.maxPeriod);
            container = newfis('optipaper');
            
            % INPUT:
            % Init 3-state @actualPeriod variable
            container = addvar(container,'input','actualPeriod',[-0.75 (maxPeriod + 0.75)]);
            container = addmf(container,'input',1,'short','gauss2mf',[0.25 1 0.25 2]);
            container = addmf(container,'input',1,'long','gauss2mf',[0.25 3 0.25 maxPeriod]);
            container = addmf(container,'input',1,'no','gaussmf',[0.25 0]);
            
            % INPUT:
            % Init 3-state @lowThreshold variable
            container = addvar(container,'input','tags',[-0.25 1.25]);
            container = addmf(container,'input',2,'green','gauss2mf',[0.1 0 0.0625 0.5]);
            container = addmf(container, 'input',2,'orange','gaussmf',[0.0625 0.75]);
            container = addmf(container, 'input',2,'red','gaussmf',[0.0625 1]);
            
            % INPUT:
            % Init 6-state @lowLevel variable
            container = addvar(container,'input','trendStatus',[-1.375 1.875]);
            container = addmf(container,'input',3,'declining','gaussmf',[0.125 -1]);
            container = addmf(container,'input',3,'mb_declining','gaussmf',[0.125 -0.5]);
            container = addmf(container,'input',3,'stable','gaussmf',[0.125 0]);
            container = addmf(container,'input',3,'mb_growing','gaussmf',[0.125 0.5]);
            container = addmf(container,'input',3,'growing','gaussmf',[0.125 1]);
            container = addmf(container,'input',3,'unknown','gaussmf',[0.125 1.5]);
            
            % OUTPUT:
            % Init 4-state @result variable
            container = addvar(container, 'output', 'result', [0 1]);
            container = addmf(container,'output',1,'possiblyTroubling','gaussmf',[0.0625  0.375]);
            container = addmf(container,'output',1,'troubling','gaussmf',[0.0625 0.625]);
            container = addmf(container,'output',1,'critical','gauss2mf',[0.0625 0.875 0.01 1]);
            container = addmf(container,'output',1,'noDangerous','gauss2mf',[0.1 0 0.0625 0.125]);     
            
            ruleList = [ 3  0  0  4  1  1; % short or no actualPeriod
                         1  0  0  4  1  1;
                         
                         2  1  1  1  1  1;
                         2  1  2  1  1  1;  
                         2  1  3  1  1  1;
                         2  1  4  2  1  1;
                         2  1  5  3  1  1;
                         2  1  6  1  1  1;
                         
                         2  2  1  1  1  1;
                         2  2  2  1  1  1;
                         2  2  3  2  1  1;
                         2  2  4  2  1  1;
                         2  2  5  3  1  1;
                         2  2  6  2  1  1;
                         
                         2  3  0  3  1  1;
                       ];

            container = addrule(container,ruleList);        
            myOctaveSpectrumHistoryHandler.fuzzyContainer = container;
        end
        
    end
    
    methods(Static)
        % THRESHOLDSEVALUATION function is value evaluation base on 
        % warningLevel and damageLevel
        function status = thresholdsEvaluation(warningLevel, damageLevel, value)
             if value < warningLevel
%                lowThreshold.value = 0;
                status = 'GREEN';
            elseif value >= warningLevel &&  value < damageLevel
%                lowThreshold.value = 0.75;
                status = 'ORANGE';
            else 
%                lowThreshold.value = 1;
                status = 'RED';
            end
        end
    end
    
end

