classdef spmDBmDBcHistoryHandler < historyHandler
    % SPMHISTORYHANDLER
    % Discription: Class is designed to evaluate the history of the "spm: dBm/dBc" :
    % 1) Get data from history
    % 2) Evaluation of trend of low, high level, difference between them
    % 3) Result evaluation of trends, with threshold level (set by the user) 
    % Input: history data 
    % Output structure: current data of history files, trend evaluation of 
    % low, high level, difference between them, result status.
    
    properties (Access = protected)
        % Input properties
        % Configurable parameters
        parameters
    end
    
    methods (Access = public)
        % Constructor function
        function [mySpmHistoryHandler] = spmDBmDBcHistoryHandler(myConfig, myFiles, myTranslations, myXmlToStructHistory)
            if nargin < 1
               error('There are not enough input arguments!');
            end
            
            myContainerTag = 'spmDBmDBc';
            mySpmHistoryHandler = mySpmHistoryHandler@historyHandler(myConfig, myFiles, myContainerTag, myTranslations, myXmlToStructHistory);
            
            % Set standard parameters
            parameters = [];
            if (isfield(myConfig.config.parameters.evaluation, 'spm'))
            	parameters.warningLevel = myConfig.config.parameters.evaluation.spm.spmDBmDBc.Attributes.warningLevel;
                parameters.damageLevel = myConfig.config.parameters.evaluation.spm.spmDBmDBc.Attributes.damageLevel;
            end
            if isfield(myFiles.files.history.Attributes, 'actualPeriod')
                parameters.maxPeriod = myFiles.files.history.Attributes.actualPeriod;
            end
            parameters.debugModeEnable = myConfig.config.parameters.common.debugModeEnable.Attributes.value;
            methodPlotEnable = myConfig.config.parameters.evaluation.spm.spmDBmDBc.Attributes.plotEnable;
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
            
            mySpmHistoryHandler.parameters = parameters;
            
            % Craete decision making container to calculate result status
            mySpmHistoryHandler = createFuzzyContainer(mySpmHistoryHandler);
            mySpmHistoryHandler = historyProcessing(mySpmHistoryHandler);
        end
        
        % FILLDOCNODE function fills docNode document with calculated
        % result data
        function [docNode] = fillDocNode(mySpmHistoryHandler, docNode)
            
            iLoger = loger.getInstance;
            myResultStruct = getResult(mySpmHistoryHandler);
            
            % Replace existing spm node with new one
            docRootNode = docNode.getDocumentElement;
            if hasChildNodes(docRootNode)
                childNodes = getChildNodes(docRootNode);
                numChildNodes = getLength(childNodes);
                for count = 1:numChildNodes
                    theChild = item(childNodes,count-1);
                    name = toCharArray(getNodeName(theChild))';
                    if strcmp(name,'spmDBmDBc')
                        docRootNode.removeChild(theChild);
                        break;
                    end
                end
            end
            
            SPMNode = docNode.createElement('spmDBmDBc');
            docRootNode.appendChild(SPMNode);
            
            status = docNode.createElement('status');
            
            
            lowLevelNodeStatus = docNode.createElement('dBc');
            lowLevelNodeStatus.setAttribute('volatility', num2str(myResultStruct.lowLevelVolatility));
            lowLevelNodeStatus.setAttribute('volatilityLevel', myResultStruct.lowLevelVolatilityLevel);
            lowLevelNodeStatus.setAttribute('trend', num2str(myResultStruct.lowLevel));
            
            highLevelNodeStatus = docNode.createElement('dBm');
            highLevelNodeStatus.setAttribute('volatility', num2str(myResultStruct.highLevelVolatility));
            highLevelNodeStatus.setAttribute('volatilityLevel', myResultStruct.highLevelVolatilityLevel);
            highLevelNodeStatus.setAttribute('trend', num2str(myResultStruct.highLevel));
            
            status.appendChild(lowLevelNodeStatus);
            status.appendChild(highLevelNodeStatus);
            
            status.setAttribute('value', num2str(myResultStruct.result));
            
            informativeTagsNode = docNode.createElement('informativeTags');
            
            lowLevelNode = docNode.createElement('dBc');
            lowLevelNode.setAttribute('value',num2str(myResultStruct.lowLevelValue));    
            lowLevelNode.setAttribute('status',myResultStruct.lowThreshold);   % state level to the specified level      
            lowLevelNode.setAttribute('trainingPeriodMean',num2str(myResultStruct.trainingPeriodMeanLowLevel)); 
            lowLevelNode.setAttribute('trainingPeriodStd',num2str(myResultStruct.trainingPeriodStdLowLevel)); 
            lowLevelNode.setAttribute('durationStatus',num2str(myResultStruct.durationLowLevel)); 
            
            highLevelNode = docNode.createElement('dBm');
            highLevelNode.setAttribute('value',num2str(myResultStruct.highLevelValue));
            highLevelNode.setAttribute('status',myResultStruct.highThreshold); % state level to the specified level
            highLevelNode.setAttribute('trainingPeriodMean',num2str(myResultStruct.trainingPeriodMeanHighLevel)); 
            highLevelNode.setAttribute('trainingPeriodStd',num2str(myResultStruct.trainingPeriodStdHighLevel)); 
            highLevelNode.setAttribute('durationStatus',num2str(myResultStruct.durationHighLevel)); 
            
            zeroLevelNode = docNode.createElement('zeroLevel');
            zeroLevelNode.setAttribute('value',num2str(myResultStruct.zeroLevel));
            
            informativeTagsNode.appendChild(lowLevelNode);
            informativeTagsNode.appendChild(highLevelNode);
            informativeTagsNode.appendChild(zeroLevelNode);
            
            % Create imageData node
            imageDataNode = docNode.createElement('imageData');
            
            % Find imageStruct fields in the struct myResult
            myResultFields = fieldnames(myResultStruct);
            nonImageStruct = cellfun(@isempty, strfind(myResultFields, 'ImageStruct'));
            imageStructFields = myResultFields(~nonImageStruct);
            imageStructNodeNames = cellfun(@(x, y) x(1 : (y - 1)), ...
                imageStructFields, strfind(imageStructFields, 'ImageStruct'), ...
                'UniformOutput', false);
            
            % Create imageStruct nodes and set them to the node imageData
            for i = 1 : 1 : length(imageStructFields)
                if ~isempty(myResultStruct.(imageStructFields{i, 1}))
                    imageStructNode = createImageStructNode(mySpmHistoryHandler, docNode, myResultStruct.(imageStructFields{i, 1}), imageStructNodeNames{i, 1});
                    imageDataNode.appendChild(imageStructNode);
                end
            end
            
            SPMNode.appendChild(status);
            SPMNode.appendChild(informativeTagsNode);
            if hasChildNodes(imageDataNode)
                SPMNode.appendChild(imageDataNode);
            end
            printComputeInfo(iLoger, 'spmDBmDBcHistoryHandler', 'docNode structure was successfully updated.');
        end
    end
    
    methods (Access = protected)  
        % HISTORYPROCESSING function calculate status
        function [mySpmHistoryHandler] = historyProcessing(mySpmHistoryHandler)
            
            iLoger = loger.getInstance;
            
            % Get data from history files
            myHistoryContainer = getHistoryContainer(mySpmHistoryHandler);
            myHistoryTable = getHistoryTable(myHistoryContainer); 
            myFiles = getFiles(myHistoryContainer);
            
            warningLevel = str2double(mySpmHistoryHandler.parameters.warningLevel);
            damageLevel = str2double(mySpmHistoryHandler.parameters.damageLevel);
            
            if isempty(myHistoryTable.lowLevel)
                printComputeInfo(iLoger, 'SPM dBm/dBc history', 'There is empty history.');
                mySpmHistoryHandler.result = [];
                return
            end
            
            % Convert to dB
            lowLevelOriginal = 20*log(myHistoryTable.lowLevel/myHistoryTable.zeroLevel);
            highLevelOriginal = 20*log(myHistoryTable.highLevel/myHistoryTable.zeroLevel);
            
            % Set config parametrs 
            myConfig = getConfig(mySpmHistoryHandler);
            trendParameters = [];   
            if (isfield(myConfig.config.parameters.evaluation.history, 'trend'))
                trendParameters = myConfig.config.parameters.evaluation.history.trend.Attributes;
            end
            trendParameters.maxPeriod = mySpmHistoryHandler.parameters.maxPeriod;
            
            % Calculation of trend status
            % lowLevel
            myLowLevelTrendHandler = trendHandler(lowLevelOriginal, trendParameters, myHistoryTable.date);
            lowLevelTrendStatus = getResult(myLowLevelTrendHandler);
            myLowLevelTrend = getTrend(myLowLevelTrendHandler);
            lowLevelVolatility = getSignalVolatility(myLowLevelTrend);
            lowLevelVolatilityLevel = getRelativeVolatilityLevel(myLowLevelTrend);
            lowLevel = getSignal(myLowLevelTrend);
            lowLevelImageStruct = getImageStruct(myLowLevelTrend);
            
            % highLevel
            myHighLevelTrendHandler = trendHandler(highLevelOriginal, trendParameters, myHistoryTable.date);
            highLevelTrendStatus = getResult(myHighLevelTrendHandler);
            myHighLevelTrend = getTrend(myHighLevelTrendHandler);
            highLevelVolatility = getSignalVolatility(myHighLevelTrend);
            highLevelVolatilityLevel = getRelativeVolatilityLevel(myHighLevelTrend);
            highLevel = getSignal(myHighLevelTrend);
            highLevelImageStruct = getImageStruct(myHighLevelTrend);
            
            % difference
            myDifferenceTrendHandler = trendHandler(highLevelOriginal - lowLevelOriginal, trendParameters, myHistoryTable.date);
            differenceTrendStatus = getResult(myDifferenceTrendHandler);
            myDifferenceTrend = getTrend(myDifferenceTrendHandler);
            differenceVolatility = getSignalVolatility(myDifferenceTrend);
            differenceVolatilityLevel = getRelativeVolatilityLevel(myDifferenceTrend);
            
            if ~isnan(warningLevel) && ~isnan(damageLevel)
                % Evaluation of set users threshold 
                lowThresholdStatus = mySpmHistoryHandler.thresholdsEvaluation ...
                    (warningLevel, damageLevel, lowLevel(1,1));
            else
                lowThresholdStatus = '';
            end    
                    
            if ~isnan(warningLevel) && ~isnan(damageLevel)
                % Evaluation of set users threshold, if use to training period 
                highThresholdStatus = mySpmHistoryHandler.thresholdsEvaluation ...
                (warningLevel, damageLevel, highLevel(1,1));
            else
                highThresholdStatus = '';
            end

            if ~isempty(lowLevelVolatility)
                %Evaluation thresholds carpet level
                [~, trainingPeriodMeanLowLevel, trainingPeriodStdLowLevel, thresholdsLow] = ...
                    getTrainingPeriodAndStatus(myHistoryTable.trainingPeriodStdLowLevel, myHistoryTable.trainingPeriodMeanLowLevel, ...
                    myFiles, getDate(myLowLevelTrend), lowLevel, lowThresholdStatus, myHistoryTable.date); 
                
                %Evaluation thresholds max level
                [~, trainingPeriodMeanHighLevel, trainingPeriodStdHighLevel, thresholdsHigh] = ...
                    getTrainingPeriodAndStatus(myHistoryTable.trainingPeriodStdHighLevel, myHistoryTable.trainingPeriodMeanHighLevel, ...
                    myFiles, getDate(myHighLevelTrend), getSignal(myHighLevelTrend), highThresholdStatus, myHistoryTable.date);  
                    
                if ~isnan(thresholdsLow(1,1)) && ~isnan(thresholdsHigh(1,1))
                    %Evaluation thresholds both levels, if use to training period       
                    lowThresholdStatus = mySpmHistoryHandler.thresholdsEvaluation ...
                        (thresholdsLow(3), thresholdsHigh(3), lowLevel(1,1));

                    highThresholdStatus = mySpmHistoryHandler.thresholdsEvaluation ...
                        (thresholdsLow(3), thresholdsHigh(3), highLevel(1,1));

                    % For print and plots
                    warningLevel = thresholdsLow(3);
                    damageLevel = thresholdsHigh(3);
                end
                
                % Low level evaluate status 
                myHistoryTable.statusLowLevel{1,1} = lowThresholdStatus;
                [durationStatusLowLevel, dataLowLevel] = mySpmHistoryHandler.evaluateDurationStatus(trendParameters, ...
                    myHistoryTable.statusLowLevel, myHistoryTable.date);
                lowStatusEvaluated = mySpmHistoryHandler.evaluateStatus(dataLowLevel.data, myFiles);
                
                % High level evaluate status 
                myHistoryTable.statusHighLevel{1,1} = highThresholdStatus;
                [durationStatusHighLevel, dataHighLevel] = mySpmHistoryHandler.evaluateDurationStatus(trendParameters, ...
                    myHistoryTable.statusHighLevel, myHistoryTable.date);
                highStatusEvaluated = mySpmHistoryHandler.evaluateStatus(dataHighLevel.data, myFiles);
                
                % Get parameters to calculate status
                actualPeriod = length(getSignal(getTrend(myDifferenceTrendHandler)));
                inputArgs = [actualPeriod, double(str2numStatus.(lowStatusEvaluated{1,1})), lowLevelTrendStatus, double(str2numStatus.(highStatusEvaluated{1,1})), highLevelTrendStatus, differenceTrendStatus];
                result = evalfis(inputArgs,mySpmHistoryHandler.fuzzyContainer);
            else    
                result = -0.01;
                trainingPeriodMeanLowLevel = [];
                trainingPeriodStdLowLevel = [];
                trainingPeriodMeanHighLevel = [];
                trainingPeriodStdHighLevel = [];
                durationStatusLowLevel = 0;
                durationStatusHighLevel = 0;
            end
            
            % Record results to the final structure
            % lowLevel
            mySpmHistoryHandler.result.lowThreshold = lowThresholdStatus;
            mySpmHistoryHandler.result.lowLevel = round(lowLevelTrendStatus*100)/100;
            mySpmHistoryHandler.result.lowLevelValue = myHistoryTable.lowLevel(1,1);
            mySpmHistoryHandler.result.lowLevelVolatility = lowLevelVolatility;
            mySpmHistoryHandler.result.lowLevelVolatilityLevel = lowLevelVolatilityLevel;
            mySpmHistoryHandler.result.lowLevelImageStruct = lowLevelImageStruct;
            mySpmHistoryHandler.result.trainingPeriodMeanLowLevel = trainingPeriodMeanLowLevel;
            mySpmHistoryHandler.result.trainingPeriodStdLowLevel = trainingPeriodStdLowLevel;
            mySpmHistoryHandler.result.durationLowLevel = durationStatusLowLevel;
            
            % highLevel
            mySpmHistoryHandler.result.highThreshold = highThresholdStatus;
            mySpmHistoryHandler.result.highLevel = round(highLevelTrendStatus*100)/100;
            mySpmHistoryHandler.result.highLevelValue = myHistoryTable.highLevel(1,1);
            mySpmHistoryHandler.result.highLevelVolatility = highLevelVolatility;
            mySpmHistoryHandler.result.highLevelVolatilityLevel = highLevelVolatilityLevel;
            mySpmHistoryHandler.result.highLevelImageStruct = highLevelImageStruct;
            mySpmHistoryHandler.result.trainingPeriodMeanHighLevel = trainingPeriodMeanHighLevel;
            mySpmHistoryHandler.result.trainingPeriodStdHighLevel = trainingPeriodStdHighLevel;
            mySpmHistoryHandler.result.durationHighLevel = durationStatusHighLevel;
            
            % difference
            mySpmHistoryHandler.result.difference = round(differenceTrendStatus*100)/100;
            mySpmHistoryHandler.result.differenceVolatility = differenceVolatility;
            mySpmHistoryHandler.result.differenceVolatilityLevel = differenceVolatilityLevel;
            mySpmHistoryHandler.result.zeroLevel = myHistoryTable.zeroLevel;
            mySpmHistoryHandler.result.result = round(result*100);
            
            % Ploting images with the result data
            if str2double(mySpmHistoryHandler.parameters.plotEnable)
                if ~isempty(lowLevelImageStruct)
                    plotAndPrint(mySpmHistoryHandler, myLowLevelTrendHandler, myHighLevelTrendHandler, myDifferenceTrendHandler, warningLevel, damageLevel);
                    
                    if checkImages(fullfile(pwd, 'Out'), 'history-spm-dBmdBc-acc-', mySpmHistoryHandler.parameters.plots.imageFormat)
                        printComputeInfo(iLoger, 'spmDBmDBcHistoryHandler', 'The method images were saved.')
                    end
                end
            end
            printComputeInfo(iLoger, 'spmDBmDBcHistoryHandler', 'spmDBmDBc history processing COMPLETE.');
        end
        
        % PLOTANDPRINT function draws and saves plots to jpeg format
        function [status] = plotAndPrint(mySpmHistoryHandler, myLowLevelTrendHandler, myHighLevelTrendHandler, myDifferenceTrendHandler, warningLevel, damageLevel)
            
            % Get parameters
            Translations = mySpmHistoryHandler.translations;
            
            debugModeEnable = str2double(mySpmHistoryHandler.parameters.debugModeEnable);
            plotVisible = mySpmHistoryHandler.parameters.plotVisible;
            plotTitle = mySpmHistoryHandler.parameters.plotTitle;
            printPlotsEnable = str2double(mySpmHistoryHandler.parameters.printPlotsEnable);
            sizeUnits = mySpmHistoryHandler.parameters.plots.sizeUnits;
            imageSize = str2num(mySpmHistoryHandler.parameters.plots.imageSize);
            fontSize = str2double(mySpmHistoryHandler.parameters.plots.fontSize);
            imageFormat = mySpmHistoryHandler.parameters.plots.imageFormat;
            imageQuality = mySpmHistoryHandler.parameters.plots.imageQuality;
            imageResolution = mySpmHistoryHandler.parameters.plots.imageResolution;
            
            % Get data for plot images
            myLowLevelTrend = getTrend(myLowLevelTrendHandler);
            myHighLevelTrend = getTrend(myHighLevelTrendHandler);
            myDifferenceTrend = getTrend(myDifferenceTrendHandler);
            lowLevelImageStruct = getImageStruct(myLowLevelTrend);
            highLevelImageStruct = getImageStruct(myHighLevelTrend);
            
            % Plot
            myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
            hold on;
            % Plot signals and their approximations
            myPlot(1) = plot(highLevelImageStruct.signal( : , 1), highLevelImageStruct.signal( : , 2), ...
                'Color', [0, 1, 0], 'LineWidth', 2);
            myPlot(2) = plot(highLevelImageStruct.approx( : , 1), highLevelImageStruct.approx( : , 2), ...
                '--', 'Color', [0, 0, 0], 'LineWidth', 2);
            myPlot(3) = plot(lowLevelImageStruct.signal( : , 1), lowLevelImageStruct.signal( : , 2), ...
                'Color', [0, 1, 1], 'LineWidth', 2);
            myPlot(4) = plot(lowLevelImageStruct.approx( : , 1), lowLevelImageStruct.approx( : , 2), ...
                '--', 'Color', [0, 0, 1], 'LineWidth', 2);
            % Plot thresholds
            if ~isempty(damageLevel) && ~isempty(warningLevel)
                [myFigure, myArea] = fillArea(myFigure, [warningLevel, damageLevel]);
            else
                myArea = [];
            end
            hold off;
            grid on;
            
            % Get axes data
            myAxes = myFigure.CurrentAxes;
            % Set axes font size
            myAxes.FontSize = fontSize;
            
            % Figure title
            if strcmp(plotTitle, 'on')
                title(myAxes, ['SPM - dBm/dBc ', Translations.method.Attributes.name]);
            end
            % Figure labels
            xlabel(myAxes, upperCase(Translations.actualPeriod.Attributes.name, 'first'));
            ylabel(myAxes, [upperCase(Translations.level.Attributes.name, 'first'), ', ', Translations.value.Attributes.value]);
            % Replace the x-axis values by the date
            xticks(myAxes, lowLevelImageStruct.signal( : , 1));
            xticklabels(myAxes, lowLevelImageStruct.date);
            xtickangle(myAxes, 90);
            if ~isempty(myArea)
                % Display legend
                legend([myPlot, flip(myArea)], ...
                    {'High level signal', 'High level trend', ...
                    'Low level signal', 'Low level trend', ...
                    'Damage Level', 'Warning level', 'Normal level'}, ...
                    'Location', 'northwest');
            else
                % Display legend
                legend(myPlot, ...
                    {'High level signal', 'High level trend', ...
                    'Low level signal', 'Low level trend'}, ...
                    'Location', 'northwest');
            end
            
            if debugModeEnable
                % Debug mode
                if mySpmHistoryHandler.result.result <= 1
                    status = 'unkwon';
                elseif mySpmHistoryHandler.result.result > 1 && mySpmHistoryHandler.result.result <= 25
                    status = 'normal';
                elseif mySpmHistoryHandler.result.result > 25 && mySpmHistoryHandler.result.result <= 75
                    status = 'troubling';
                else
                    status = 'critical';
                end
                % Get the limits of axis
                xLimits = xlim;
                yLimits = ylim;
                % The bottom left point of the figure for the text
                % Calculate the position of the text on x-axis
                xTextPosition = 0.020 * abs(diff(xLimits)) + xLimits(1);
                % Calculate the position of the text on y-axis
                yTextPosition = 0.025 * abs(diff(yLimits)) + yLimits(1);
                % Prepare the text for display
                textContent = {
                    '<< High level >>';
                    ['Volatility: ', num2str(round(getSignalVolatility(myHighLevelTrend))), '%'];
                    ['Relative volatility level: ', getRelativeVolatilityLevel(myHighLevelTrend)];
                    ['Trend: ',  writeResultTrend(mySpmHistoryHandler, mySpmHistoryHandler.result.highLevel)];
                    '<< Low level >>';
                    ['Volatility: ', num2str(round(getSignalVolatility(myLowLevelTrend))), '%'];
                    ['Relative volatility level: ', getRelativeVolatilityLevel(myLowLevelTrend)];
                    ['Trend: ', writeResultTrend(mySpmHistoryHandler, mySpmHistoryHandler.result.lowLevel)];
                    '<< Delta >>';
                    ['Volatility: ', num2str(round(getSignalVolatility(myDifferenceTrend))), '%'];
                    ['Relative volatility level: ', getRelativeVolatilityLevel(myDifferenceTrend)];
                    ['Trend: ',  writeResultTrend(mySpmHistoryHandler, mySpmHistoryHandler.result.difference)];
                    ['Status: ', status];
                    };
                % Print status of trends in charecter format
                text(xTextPosition, yTextPosition, textContent, ...
                    'FontSize', fontSize, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
                    'BackgroundColor', 'w', 'EdgeColor', 'k');
            end
            
            if printPlotsEnable
                % Save the image to the @Out directory
                imageNumber = '1';
                fileName = ['history-spm-dBmdBc-acc-', imageNumber];
                fullFileName = fullfile(pwd, 'Out', fileName);
                print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
            end
            
            % Close figure with visibility off
            if strcmpi(plotVisible, 'off')
                close(myFigure)
            end
        end
        
        % CREATEFUZZYCONTAINER function create rules to calculate status  
        function [mySpmHistoryHandler] = createFuzzyContainer(mySpmHistoryHandler)            
            maxPeriod = str2double(mySpmHistoryHandler.parameters.maxPeriod);
            container = newfis('optipaper');
            
            % INPUT:
            % Init 3-state @actualPeriod variable
            container = addvar(container,'input','actualPeriod',[-0.75 (maxPeriod + 0.75)]);
            container = addmf(container,'input',1,'short','gauss2mf',[0.25 1 0.25 2]);
            container = addmf(container,'input',1,'long','gauss2mf',[0.25 3 0.25 maxPeriod]);
            container = addmf(container,'input',1,'no','gaussmf',[0.25 0]);
            
            % INPUT:
            % Init 3-state @lowThreshold variable
            container = addvar(container,'input','lowThreshold',[-0.25 1.25]);
            container = addmf(container,'input',2,'green','gaussmf',[0.1 0 0.0625 0.5]);
            container = addmf(container,'input',2,'yellow','gaussmf',[0.0625 0.75]);
            container = addmf(container,'input',2,'red','gaussmf',[0.0625 1]);
            
            % INPUT:
            % Init 6-state @lowLevel variable
            container = addvar(container,'input','lowLevel',[-1.375 1.875]);
            container = addmf(container,'input',3,'declining','gaussmf',[0.125 -1]);
            container = addmf(container,'input',3,'mb_declining','gaussmf',[0.125 -0.5]);
            container = addmf(container,'input',3,'stable','gaussmf',[0.125 0]);
            container = addmf(container,'input',3,'mb_growing','gaussmf',[0.125 0.5]);
            container = addmf(container,'input',3,'growing','gaussmf',[0.125 1]);
            container = addmf(container,'input',3,'unknown','gaussmf',[0.125 1.5]);
            
            % INPUT:
            % Init 3-state @highThreshold variable
            container = addvar(container,'input','highThreshold',[-0.25 1.25]);
            container = addmf(container,'input',4,'green','gaussmf',[0.1 0 0.0625 0.5]);
            container = addmf(container,'input',4,'yellow','gaussmf',[0.0625 0.75]);
            container = addmf(container,'input',4,'red','gaussmf',[0.0625 1]);
            
            % INPUT:
            % Init 6-state @highLevel variable
            container = addvar(container,'input','highLevel',[-1.375 1.875]);
            container = addmf(container,'input',5,'declining','gaussmf',[0.125 -1]);
            container = addmf(container,'input',5,'mb_declining','gaussmf',[0.125 -0.5]);
            container = addmf(container,'input',5,'stable','gaussmf',[0.125 0]);
            container = addmf(container,'input',5,'mb_growing','gaussmf',[0.125 0.5]);
            container = addmf(container,'input',5,'growing','gaussmf',[0.125 1]);
            container = addmf(container,'input',5,'unknown','gaussmf',[0.125 1.5]);
            
            % INPUT:
            % Init 6-state @difference variable
            container = addvar(container,'input','difference',[-1.375 1.875]);
            container = addmf(container,'input',6,'declining','gaussmf',[0.125 -1]);
            container = addmf(container,'input',6,'mb_declining','gaussmf',[0.125 -0.5]);
            container = addmf(container,'input',6,'stable','gaussmf',[0.125 0]);
            container = addmf(container,'input',6,'mb_growing','gaussmf',[0.125 0.5]);
            container = addmf(container,'input',6,'growing','gaussmf',[0.125 1]);
            container = addmf(container,'input',6,'unknown','gaussmf',[0.125 1.5]);
            
            % OUTPUT:
            % Init 4-state @result variable
            container = addvar(container, 'output', 'result', [0 1]);
            container = addmf(container,'output',1,'possiblyTroubling','gaussmf',[0.0625 0.375]);
            container = addmf(container,'output',1,'troubling','gaussmf',[0.0625 0.625]);
            container = addmf(container,'output',1,'critical','gauss2mf',[0.0625 0.875 0.01 1]);
            container = addmf(container,'output',1,'noDangerous','gauss2mf',[0.1 0 0.0625 0.125]);     

            %start position
            
            ruleList = [ 3  0  0  0  0  0  4  1  1; % short or no actualPeriod
                         1  0  0  0  0  0  4  1  1;
                         
                        -3  1  0  1  0  0  1  1  1; % do not cross the threshold
                        
                         2  3  0  3  0  0  3  1  1; % if both levels cross the threshold 
                         
                         2  1  0  2  1  0  1  1  1; 
                         
                         2  1  0  2  2  1  0  1  1; 
                         
                         2  1  0  2  3 -5  1  1  1;
                         2  1  0  2  3  5  2  1  1;
                         
                         2  1  0  2  4  0  2  1  1;
                         
                         2  1  0  2  5  1  2  1  1; % whith difference
                         2  1  0  2  5  2  2  1  1;
                         2  1  0  2  5  3  2  1  1;
                         2  1  0  2  5  4  3  1  1;
                         2  1  0  2  5  5  3  1  1;
                         2  1  0  2  5  6  2  1  1;
                         
                         2  1  0  2  6  0  2  1  1;
                         
                         2  1  0  3  0  1  3  1  1; % whith difference
                         2  1  0  3  0  2  3  1  1;
                         2  1  0  3  0  3  2  1  1;
                         2  1  0  3  0  4  3  1  1;
                         2  1  0  3  0  5  3  1  1;
                         2  1  0  3  0  6  2  1  1;
                         
                         2  2  1  2  1 -5  1  1  1;
                         2  2  1  2  1  5  2  1  1;
                         
                         2  2  1  2  2 -5  1  1  1;
                         2  2  1  2  2  5  2  1  1;
                         
                         2  2  1  2  3 -5  1  1  1;
                         2  2  1  2  3  5  2  1  1;
                         
                         2  2  1  2  4  0  2  1  1;
                         
                         2  2  1  2  5  0  3  1  1;
                         
                         2  2  1  2  6  1  3  1  1; % whith difference
                         2  2  1  2  6  2  2  1  1;
                         2  2  1  2  6  3  2  1  1;
                         2  2  1  2  6  4  2  1  1;
                         2  2  1  2  6  5  3  1  1;
                         2  2  1  2  6  6  2  1  1;
                         
                         2  2  2  2  1 -5  1  1  1; 
                         2  2  2  2  1  5  2  1  1; 
                         
                         2  2  2  2  2 -5  1  1  1;
                         2  2  2  2  2  5  2  1  1;
                         
                         2  2  2  2  3 -5  1  1  1;
                         2  2  2  2  3  5  2  1  1;
                          
                         2  2  2  2  4  0  2  1  1;
                         
                         2  2  2  2  5 -5  2  1  1;
                         2  2  2  2  5  5  3  1  1;
                         
                         2  2  2  2  6 -5  1  1  1;
                         2  2  2  2  6  5  2  1  1;
                         
                         2  2  3  2  1 -5  1  1  1;
                         2  2  3  2  1  5  2  1  1;
                         
                         2  2  3  2  2 -5  1  1  1;
                         2  2  3  2  2  5  1  1  1;
                         
                         2  2  3  2  3  1  2  1  1;
                         2  2  3  2  3  2  2  1  1;
                         2  2  3  2  3  3  2  1  1;
                         2  2  3  2  3  4  2  1  1;
                         2  2  3  2  3  5  3  1  1;
                         2  2  3  2  3  6  2  1  1;
                         
                         2  2  3  2  4 -5  2  1  1;
                         2  2  3  2  4  5  2  1  1;
                         
                         2  2  3  2  5  0  3  1  1;
                         
                         2  2  3  2  6 -5  2  1  1;
                         2  2  3  2  6  5  2  1  1
                         
                         2  2  4  2  1 -5  2  1  1;
                         2  2  4  2  1  5  3  1  1;
                         
                         2  2  4  2  2 -5  2  1  1;
                         2  2  4  2  2  5  3  1  1;
                         
                         2  2  4  2  3 -5  2  1  1;
                         2  2  4  2  3  5  3  1  1;
                        
                         2  2  4  2  4 -5  2  1  1;
                         2  2  4  2  4  5  3  1  1;
                         
                         2  2  4  2  5  0  3  1  1;
                         
                         2  2  4  2  6 -5  2  1  1;
                         2  2  4  2  6  5  3  1  1;
                         
                         
                         2  2  5  2  1 -5  2  1  1;
                         2  2  5  2  1  5  3  1  1;
                         
                         2  2  5  2  2 -5  2  1  1;
                         2  2  5  2  2  5  3  1  1;
                         
                         2  2  5  2  3 -5  2  1  1;
                         2  2  5  2  3  5  3  1  1;
                         
                         2  2  5  2  4  0  3  1  1;
                         2  2  5  2  5  0  3  1  1;
                         
                         2  2  5  2  6 -5  2  1  1;
                         2  2  5  2  6  5  3  1  1;
                         
                         
                         2  2  6  2  1 -5  2  1  1;
                         2  2  6  2  1  5  3  1  1;
                         
                         2  2  6  2  2 -5  2  1  1;
                         2  2  6  2  2  5  3  1  1;
                         
                         2  2  6  2  3 -5  2  1  1;
                         2  2  6  2  3  5  2  1  1;
                         
                         
                         2  2  6  2  4 -5  2  1  1;
                         2  2  6  2  4  5  3  1  1;
                         
                         2  2  6  2  5  0  3  1  1;
                         
                         2  2  6  2  6 -5  2  1  1;
                         2  2  6  2  6  5  3  1  1;
                         
                         2  2  1  3  0  0  3  1  1;
                         
                       ];

            container = addrule(container,ruleList);        
            mySpmHistoryHandler.fuzzyContainer = container;
        end
        
        % WRTTERESULTTREND function transforms result from number to charecters format
        function writeTrend = writeResultTrend(mySpmHistoryHandler, result)
            if result <= -0.75
                writeTrend = 'declining';
            elseif result > -0.75 && result <= -0.25
                writeTrend = 'maybe declining';   
            elseif result > -0.25 && result <= 0.25
                writeTrend = 'stable';
            elseif result > 0.25 && result <= 0.75
                writeTrend = 'maybe growing';    
            elseif result > 0.75 && result <= 1.25
                writeTrend = 'growing';     
            else
                writeTrend = 'unknown';
            end
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

