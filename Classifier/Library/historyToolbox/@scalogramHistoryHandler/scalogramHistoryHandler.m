classdef scalogramHistoryHandler < historyHandler
% SCALOGRAMHISTORYHANDLER class evaluate 
% scalogram in time
    
    properties (Access = protected)
        % Input properties
        parameters % configurable parameters
    end
    
    methods (Access = public)
        % Constructor function
        function [myScalogramHistoryHandler] = scalogramHistoryHandler(myConfig, myFiles, myTranslations, myXmlToStructHistory)
            if nargin < 1
               error('There are not enough input arguments!'); 
            end
            
            myContainerTag = 'scalogram';
            myScalogramHistoryHandler = myScalogramHistoryHandler@historyHandler(myConfig, myFiles, myContainerTag, myTranslations, myXmlToStructHistory);
            
            % Set standard parameters
            if isfield(myFiles.files.history.Attributes, 'actualPeriod')
                parameters.maxPeriod = myFiles.files.history.Attributes.actualPeriod;
            end
            parameters.debugModeEnable = myConfig.config.parameters.common.debugModeEnable.Attributes.value;
            parameters.parpoolEnable = myConfig.config.parameters.common.parpoolEnable.Attributes.value;
            methodPlotEnable = myConfig.config.parameters.evaluation.scalogramHandler.Attributes.plotEnable;
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
            
            myScalogramHistoryHandler.parameters = parameters;
            
            % Craete decision making container to calculate result status 
            myScalogramHistoryHandler = createFuzzyContainer(myScalogramHistoryHandler);
            myScalogramHistoryHandler = historyProcessing(myScalogramHistoryHandler);
        end
        
        % FILLDOCNODE function fills docNode document with calculated
        % result data
        function [docNode] = fillDocNode(myScalogramHistoryHandler, docNode)
            
            iLoger = loger.getInstance;
            myResultStruct = getResult(myScalogramHistoryHandler);
            
            % Replace existing spm node with new one
            docRootNode = docNode.getDocumentElement;
            if hasChildNodes(docRootNode)
                childNodes = getChildNodes(docRootNode);
                numChildNodes = getLength(childNodes);
                for count = 1:numChildNodes
                    theChild = item(childNodes,count-1);
                    name = toCharArray(getNodeName(theChild))';
                    if strcmp(name,'scalogram')
                        docRootNode.removeChild(theChild);
                        break;
                    end
                end
            end
            
            octaveSpectrumNode = docNode.createElement('scalogram');
            docRootNode.appendChild(octaveSpectrumNode);
            
            status = docNode.createElement('status');
            status.setAttribute('value',vector2strStandardFormat(myResultStruct.result)); 
            
            informativeTagsNode = docNode.createElement('informativeTags');
            
            frequenciesNode = docNode.createElement('frequencies');
            frequenciesNode.setAttribute('value',vector2strStandardFormat(myResultStruct.frequencies));     
            
            magnitudesNode = docNode.createElement('coefficients');
            magnitudesNode.setAttribute('value',vector2strStandardFormat(myResultStruct.coefficients));
            
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
            printComputeInfo(iLoger, 'scalogramHistoryHandler', 'docNode structure was successfully updated.');
        end
    end
    
    methods (Access = protected)  
        % HISTORYPROCESSING function calculate status
        function [myScalogramHistoryHandler] = historyProcessing(myScalogramHistoryHandler)
            % Loger initialization
            iLoger = loger.getInstance;
            
            % Get data from history files
            myHistoryContainer = getHistoryContainer(myScalogramHistoryHandler);
            myHistoryTable = getHistoryTable(myHistoryContainer); 
            myFiles = getFiles(myScalogramHistoryHandler);
            cntOctave = length(myHistoryTable.coefficients(1,:));
            
            if isempty(myHistoryTable.coefficients(:,1))
                printComputeInfo(iLoger, 'Scalogram history', 'There is empty history.');
                myScalogramHistoryHandler.result = [];
                return
            end
            
            % Set config parametrs 
            myConfig = getConfig(myScalogramHistoryHandler);
            trendParameters = [];   
            if (isfield(myConfig.config.parameters.evaluation.history, 'trend'))
                trendParameters = myConfig.config.parameters.evaluation.history.trend.Attributes;
            end
            trendParameters.maxPeriod = myScalogramHistoryHandler.parameters.maxPeriod;
            
            result = zeros(1,cntOctave);
            durationStatus = zeros(1,cntOctave);
            treshold = nan(3, cntOctave);
            
            % Calculation of trend status
            actualPeriod = length(myHistoryTable.coefficients(:,1));
            for i=1:1:cntOctave
                myTempObjTrendHandler = trendHandler(myHistoryTable.coefficients(:,i), trendParameters, myHistoryTable.date);
                tempTrendStatus = getResult(myTempObjTrendHandler);
                tempTrendObj = getTrend(myTempObjTrendHandler);
                signalTrend = getSignal(tempTrendObj);
                tempTrendVolatility = getSignalVolatility(getTrend(myTempObjTrendHandler));

                if ~isempty(tempTrendVolatility)
                    % Get training parameters and status
                    [myHistoryTable.tags{1,i}, myHistoryTable.trainingPeriodMean{1,i}, myHistoryTable.trainingPeriodStd{1,i}, treshold(:,i)] =  ...
                        getTrainingPeriodAndStatus(myHistoryTable.trainingPeriodStd(:,i), myHistoryTable.trainingPeriodMean(:,i),  ...
                        myFiles, getDate(tempTrendObj), signalTrend, [], myHistoryTable.date);  
                    if ~isempty(myHistoryTable.tags{1,i})
                        [durationStatus(1,i), compressionData] = myScalogramHistoryHandler.evaluateDurationStatus(trendParameters, ...
                            myHistoryTable.tags(:,i), myHistoryTable.date);
                        statusEvaluated = myScalogramHistoryHandler.evaluateStatus(compressionData.data, myFiles);
                        
                        inputArgs = [actualPeriod, double(str2numStatus.(statusEvaluated{1,1})), tempTrendStatus];
                        result(1,i) = evalfis(inputArgs, myScalogramHistoryHandler.fuzzyContainer);
                    else
                        myHistoryTable.tags{1,i} = 'NaN';
                        result(1,i) = -0.01;
                    end
                else
                    myHistoryTable.tags{1,i} = 'NaN';
                    result(1,i) = -0.01;
                end
            end
            
            if ~isnan(treshold(1, : ))
                warningLevel = treshold(2, : );
                damageLevel = treshold(3, : );
            else
                warningLevel = [];
                damageLevel = [];
            end
            
            % Record results to the final structure
            myScalogramHistoryHandler.result.frequencies = myHistoryTable.frequencies(1,:);
            myScalogramHistoryHandler.result.coefficients = myHistoryTable.coefficients(1,:);
            myScalogramHistoryHandler.result.tags = myHistoryTable.tags(1,:);
            myScalogramHistoryHandler.result.result = round(result*100);
            myScalogramHistoryHandler.result.durationStatus = durationStatus;
            
            myScalogramHistoryHandler.result.trainingPeriodMean = myHistoryTable.trainingPeriodMean(1,:);
            myScalogramHistoryHandler.result.trainingPeriodStd = myHistoryTable.trainingPeriodStd(1,:);
            if ~isempty(cell2mat(myHistoryTable.trainingPeriodMean(1,:)))
                myScalogramHistoryHandler.result.percentGrowth = (round(myHistoryTable.coefficients(1,:)./cell2mat(myHistoryTable.trainingPeriodMean(1,:)),2) - ones(size(myHistoryTable.trainingPeriodMean(1,:))))*100;
            else
                myScalogramHistoryHandler.result.percentGrowth = nan(size(myHistoryTable.trainingPeriodMean(1,:)));
            end
            
            if str2double(myScalogramHistoryHandler.parameters.plotEnable)
                plotAndPrint(myScalogramHistoryHandler, myHistoryTable, warningLevel, damageLevel);
                
                if checkImages(fullfile(pwd, 'Out'), 'history-scalogram-acc-', myScalogramHistoryHandler.parameters.plots.imageFormat)
                    printComputeInfo(iLoger, 'scalogramHistoryHandler', 'The method images were saved.')
                end
            end
			printComputeInfo(iLoger, 'scalogramHistoryHandler', 'Scalogram history processing COMPLETE.');
        end
        
        % PLOTANDPRINT function draws and saves plots
        function plotAndPrint(myScalogramHistoryHandler, myHistoryTable, warningLevel, damageLevel)
            
            % Get parameters
            Translations = myScalogramHistoryHandler.translations;
            
            plotVisible = myScalogramHistoryHandler.parameters.plotVisible;
            plotTitle = myScalogramHistoryHandler.parameters.plotTitle;
            printPlotsEnable = str2double(myScalogramHistoryHandler.parameters.printPlotsEnable);
            sizeUnits = myScalogramHistoryHandler.parameters.plots.sizeUnits;
            imageSize = str2num(myScalogramHistoryHandler.parameters.plots.imageSize);
            fontSize = str2double(myScalogramHistoryHandler.parameters.plots.fontSize);
            imageFormat = myScalogramHistoryHandler.parameters.plots.imageFormat;
            imageQuality = myScalogramHistoryHandler.parameters.plots.imageQuality;
            imageResolution = myScalogramHistoryHandler.parameters.plots.imageResolution;
            
            spectrum(1, : ) = myHistoryTable.coefficients(1, : );
            octaveCoefficients = myHistoryTable.coefficients(1, : );
            
            if ~isempty(warningLevel)
                warningPositions = (octaveCoefficients < damageLevel) & (octaveCoefficients >= warningLevel);
                damagePositions = (octaveCoefficients >= damageLevel);
            else
                warningPositions = [];
                damagePositions = [];
            end
            
            if nnz(warningPositions) ~= 0 && nnz(damagePositions) == 0
                spectrum(1, warningPositions) = warningLevel(1, warningPositions);
                spectrum(2, warningPositions) = octaveCoefficients(1, warningPositions) - warningLevel(1, warningPositions);
            end
            if nnz(damagePositions) ~= 0
                spectrum(1, damagePositions) = warningLevel(1, damagePositions);
                spectrum(2, damagePositions) = damageLevel(1, damagePositions) - warningLevel(1, damagePositions);
                spectrum(3, damagePositions) = octaveCoefficients(1, damagePositions) - damageLevel(1, damagePositions);
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
            	title(myAxes, upperCase(Translations.scalogram.Attributes.name, 'first'));
            end 
            % Figure labels
            xlabel(myAxes, [upperCase(Translations.centralFrequency.Attributes.name, 'first'), ', ', ...
                upperCase(Translations.frequency.Attributes.value, 'first')]);
            ylabel(myAxes, upperCase(Translations.coefficient.Attributes.name, 'first'));
            % Replace the x-axis values by the central frequencies
            xticks(myAxes, linspace(1, length(octaveCoefficients), length(octaveCoefficients)));
            xticklabels(myAxes, round(myHistoryTable.frequencies(1, : ) * 100) / 100);
            xtickangle(myAxes, 90);
            
            % Set axes limits
            yScale = 1.2;
            yLimits = ylim;
            ylim(myAxes, [yLimits(1), yLimits(2) * yScale]);
            
            if printPlotsEnable
                % Save the image to the @Out directory
                imageNumber = '1';
                fileName = ['history-scalogram-acc-', imageNumber];
                fullFileName = fullfile(pwd, 'Out', fileName);
                print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
            end
            
            % Close figure with visibility off
            if strcmpi(plotVisible, 'off')
                close(myFigure)
            end
        end
        
        % CREATEFUZZYCONTAINER function create rules to calculate status  
        function [myScalogramHistoryHandler] = createFuzzyContainer(myScalogramHistoryHandler)            
            maxPeriod = str2double(myScalogramHistoryHandler.parameters.maxPeriod);
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
            container = addmf(container,'output',1,'possiblyTroubling','gaussmf',[0.0625 0.375]);
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
            myScalogramHistoryHandler.fuzzyContainer = container;
        end

    end
end

