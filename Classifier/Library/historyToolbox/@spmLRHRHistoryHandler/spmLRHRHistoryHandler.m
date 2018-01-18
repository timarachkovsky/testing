classdef spmLRHRHistoryHandler < historyHandler
    % SPMHISTORYHANDLER
    % Discription: Class is designed to evaluate the history of the "spm: LR/HR":
    % 1) Get data from history
    % 2) Evaluation of trend of low, high level, delta between them
    % 3) Result evaluation of trends, with threshold level (set by the user) 
    % Input: history data 
    % Output structure: current data of history files, trend evaluation of 
    % low, high level, delta between them, result status.
    
    properties (Access = protected)
        % Input properties
        % Configurable parameters
        parameters
    end
    
    methods (Access = public)
        % Constructor function
        function [mySpmHistoryHandler] = spmLRHRHistoryHandler(myConfig, myFiles, myTranslations, myXmlToStructHistory)
            if nargin < 1
               error('There are not enough input arguments!'); 
            end
            
            myContainerTag = 'spmLRHR';
            mySpmHistoryHandler = mySpmHistoryHandler@historyHandler(myConfig, myFiles, myContainerTag, myTranslations, myXmlToStructHistory);
            
            % Set standard parameters
            parameters = [];
            if (isfield(myConfig.config.parameters.evaluation, 'spm'))
            	parameters.warningLevel = str2double(myConfig.config.parameters.evaluation.spm.spmLRHR.Attributes.warningLevel);
                parameters.damageLevel = str2double(myConfig.config.parameters.evaluation.spm.spmLRHR.Attributes.damageLevel);
            end
            if isfield(myFiles.files.history.Attributes, 'actualPeriod')
                parameters.maxPeriod = myFiles.files.history.Attributes.actualPeriod;
            end
            parameters.debugModeEnable = myConfig.config.parameters.common.debugModeEnable.Attributes.value;
            methodPlotEnable = myConfig.config.parameters.evaluation.spm.spmLRHR.Attributes.plotEnable;
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
                    if strcmp(name,'spmLRHR')
                        docRootNode.removeChild(theChild);
                        break;
                    end
                end
            end
            
            SPMNode = docNode.createElement('spmLRHR');
            docRootNode.appendChild(SPMNode);
            
            status = docNode.createElement('status');
            
            lowLevelNodeStatus = docNode.createElement('hR');
            lowLevelNodeStatus.setAttribute('volatility', num2str(myResultStruct.lowLevelVolatility));
            lowLevelNodeStatus.setAttribute('volatilityLevel', myResultStruct.lowLevelVolatilityLevel);
            lowLevelNodeStatus.setAttribute('trend', num2str(myResultStruct.lowLevel));
            lowLevelNodeStatus.setAttribute('statusOfHistory', num2str(myResultStruct.statusOfHistoryLowLevel));
            
            highLevelNodeStatus = docNode.createElement('lR');
            highLevelNodeStatus.setAttribute('volatility', num2str(myResultStruct.highLevelVolatility));
            highLevelNodeStatus.setAttribute('volatilityLevel', myResultStruct.highLevelVolatilityLevel);
            highLevelNodeStatus.setAttribute('trend', num2str(myResultStruct.highLevel));
            highLevelNodeStatus.setAttribute('statusOfHistory', num2str(myResultStruct.statusOfHistoryHighLevel));
            
            deltaLevelNodeStatus = docNode.createElement('delta');
            deltaLevelNodeStatus.setAttribute('volatility', num2str(myResultStruct.deltaVolatility));
            deltaLevelNodeStatus.setAttribute('volatilityLevel', myResultStruct.deltaVolatilityLevel);
            deltaLevelNodeStatus.setAttribute('trend', num2str(myResultStruct.delta));
            deltaLevelNodeStatus.setAttribute('statusOfHistory', num2str(myResultStruct.statusOfHistoryDelta));
            
            status.appendChild(lowLevelNodeStatus);
            status.appendChild(highLevelNodeStatus);
            status.appendChild(deltaLevelNodeStatus);
            
            status.setAttribute('value', num2str(myResultStruct.result));
            
            informativeTagsNode = docNode.createElement('informativeTags');
            
            lowLevelNode = docNode.createElement('hR');
            lowLevelNode.setAttribute('value',num2str(myResultStruct.lowLevelValue));         
            lowLevelNode.setAttribute('status',myResultStruct.lowThresholdStatus);   % state level to the specified level      
            lowLevelNode.setAttribute('trainingPeriodMean',num2str(myResultStruct.trainingPeriodMeanLowLevel)); 
            lowLevelNode.setAttribute('trainingPeriodStd',num2str(myResultStruct.trainingPeriodStdLowLevel)); 
            lowLevelNode.setAttribute('durationStatus',num2str(myResultStruct.durationLowLevel)); 
            
            highLevelNode = docNode.createElement('lR');
            highLevelNode.setAttribute('value',num2str(myResultStruct.highLevelValue));
            highLevelNode.setAttribute('status',myResultStruct.highThresholdStatus); % state level to the specified level
            highLevelNode.setAttribute('trainingPeriodMean',num2str(myResultStruct.trainingPeriodMeanHighLevel)); 
            highLevelNode.setAttribute('trainingPeriodStd',num2str(myResultStruct.trainingPeriodStdHighLevel)); 
            highLevelNode.setAttribute('durationStatus',num2str(myResultStruct.durationHighLevel)); 
            
            differenceNode = docNode.createElement('delta');
            differenceNode.setAttribute('value',num2str(myResultStruct.deltaValue));
            differenceNode.setAttribute('status',myResultStruct.deltaThresholdStatus); 
            differenceNode.setAttribute('trainingPeriodMean',num2str(myResultStruct.trainingPeriodMeanDelta)); 
            differenceNode.setAttribute('trainingPeriodStd',num2str(myResultStruct.trainingPeriodStdDelta)); 
            differenceNode.setAttribute('durationStatus',num2str(myResultStruct.durationDelta)); 
            
            informativeTagsNode.appendChild(lowLevelNode);
            informativeTagsNode.appendChild(highLevelNode);
            informativeTagsNode.appendChild(differenceNode);
            
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
            printComputeInfo(iLoger, 'spmLRHRHistoryHandler', 'docNode structure was successfully updated.');
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
            
            warningLevel = mySpmHistoryHandler.parameters.warningLevel;
            damageLevel = mySpmHistoryHandler.parameters.damageLevel;
            
            if isempty(myHistoryTable.lowLevel)
                printComputeInfo(iLoger, 'SPM history', 'There is empty history.');
                mySpmHistoryHandler.result = [];
                return
            end
            
            % Set config parametrs
            myConfig = getConfig(mySpmHistoryHandler);
            trendParameters = [];
            if (isfield(myConfig.config.parameters.evaluation.history, 'trend'))
                trendParameters = myConfig.config.parameters.evaluation.history.trend.Attributes;
            end
            trendParameters.maxPeriod = mySpmHistoryHandler.parameters.maxPeriod;
            
            % Calculation of trend status
            % lowLevel
            myLowLevelTrendHandler = trendHandler(myHistoryTable.lowLevel, trendParameters, myHistoryTable.date);
            lowLevelTrendStatus = getResult(myLowLevelTrendHandler);
            myLowLevelTrend = getTrend(myLowLevelTrendHandler);
            lowLevelVolatility = getSignalVolatility(myLowLevelTrend);
            lowLevelVolatilityLevel = getRelativeVolatilityLevel(myLowLevelTrend);
            lowLevelImageStruct = getImageStruct(myLowLevelTrend);
            
            lowLevel = getSignal(myLowLevelTrend);
            if ~isnan(warningLevel) && ~isnan(damageLevel)
                % Evaluation of set users threshold 
                lowThresholdStatus = mySpmHistoryHandler.thresholdsEvaluation ...
                    (warningLevel, damageLevel, lowLevel(1,1));
            else
                lowThresholdStatus = '';
                warningLevel = '';
                damageLevel = '';
            end
            
            % highLevel
            myHighLevelTrendHandler = trendHandler(myHistoryTable.highLevel, trendParameters, myHistoryTable.date);
            highLevelTrendStatus = getResult(myHighLevelTrendHandler);
            myHighLevelTrend = getTrend(myHighLevelTrendHandler);
            highLevelVolatility = getSignalVolatility(myHighLevelTrend);
            highLevelVolatilityLevel = getRelativeVolatilityLevel(myHighLevelTrend);
            highLevelImageStruct = getImageStruct(myHighLevelTrend);
            
            highLevel = getSignal(myHighLevelTrend);
            if ~isnan(mySpmHistoryHandler.parameters.warningLevel) && ~isnan(mySpmHistoryHandler.parameters.damageLevel)
                % Evaluation of set users threshold, if use to training period
                highThresholdStatus = mySpmHistoryHandler.thresholdsEvaluation ...
                (mySpmHistoryHandler.parameters.warningLevel, mySpmHistoryHandler.parameters.damageLevel, highLevel(1,1));
            else
                highThresholdStatus = '';
            end
            
            % delta
            myDeltaTrendHandler = trendHandler(myHistoryTable.highLevel - myHistoryTable.lowLevel, trendParameters, myHistoryTable.date);
            deltaTrendStatus = getResult(myDeltaTrendHandler);
            myDeltaTrend = getTrend(myDeltaTrendHandler);
            deltaVolatility = getSignalVolatility(myDeltaTrend);
            deltaVolatilityLevel = getRelativeVolatilityLevel(myDeltaTrend);
            
            if ~isempty(lowLevelVolatility)
                %Evaluation thresholds carpet level
                [lowThresholdStatus, trainingPeriodMeanLowLevel, trainingPeriodStdLowLevel, thresholdsLow] = ...
                            getTrainingPeriodAndStatus(myHistoryTable.trainingPeriodStdLowLevel, myHistoryTable.trainingPeriodMeanLowLevel, ...
                            myFiles, getDate(myLowLevelTrend), getSignal(myLowLevelTrend), lowThresholdStatus, myHistoryTable.date);  
                
                %Evaluation thresholds max level
                [highThresholdStatus, trainingPeriodMeanHighLevel, trainingPeriodStdHighLevel, thresholdsHigh] = ...
                            getTrainingPeriodAndStatus(myHistoryTable.trainingPeriodStdHighLevel, myHistoryTable.trainingPeriodMeanHighLevel, ...
                            myFiles, getDate(myHighLevelTrend), getSignal(myHighLevelTrend), highThresholdStatus, myHistoryTable.date); 
                
                %Evaluation thresholds delta
                [deltaThresholdStatus, trainingPeriodMeanDelta, trainingPeriodStdDelta, tresholdDelta] = ...
                            getTrainingPeriodAndStatus(myHistoryTable.trainingPeriodStdDelta, myHistoryTable.trainingPeriodMeanDelta, ...
                            myFiles, getDate(myDeltaTrend), getSignal(myDeltaTrend), '', myHistoryTable.date); 
                        
                if ~isnan(thresholdsLow(1,1)) && ~isnan(thresholdsHigh(1,1))    
                    % For print and plots
                    warningLevel = thresholdsLow(3);
                    damageLevel = thresholdsHigh(3);
                end
                
                % Get parameters to calculate status
                actualPeriod = length(getSignal(getTrend(myDeltaTrendHandler)));
                if isempty(highThresholdStatus) && isempty(lowThresholdStatus) && isempty(deltaThresholdStatus)
                    result = -0.01;
                    durationStatusHighLevel = 0;
                    durationStatusLowLevel = 0;
                    durationStatusDelta = 0;
                    deltaStatusEvaluated = [];
                    
                    lowStatusEvaluated = 0;
                    highStatusEvaluated = 0;
                else
                    
                    % To evaluate delta decreasing
                    if contains(deltaThresholdStatus,'GREEN')
                        deltaThresholdStatus = ...
                            mySpmHistoryHandler.evaluateDeltaDecrease(tresholdDelta, trainingPeriodMeanDelta, getSignal(myDeltaTrend));
                    end
                    
                    % Low level evaluate status 
                    myHistoryTable.statusLowLevel{1,1} = lowThresholdStatus;
                    [durationStatusLowLevel, dataLowLevel] = mySpmHistoryHandler.evaluateDurationStatus(trendParameters, ...
                        myHistoryTable.statusLowLevel, myHistoryTable.date);
                    lowStatusEvaluatedTag = mySpmHistoryHandler.evaluateStatus(dataLowLevel.data, myFiles);
                    inputArgs = [actualPeriod double(str2numStatus.(lowStatusEvaluatedTag{1,1})) lowLevelTrendStatus];
                    lowStatusEvaluated = evalfis(inputArgs, mySpmHistoryHandler.fuzzyContainer.lRorHR);
                    
                    % High level evaluate status 
                    myHistoryTable.statusHighLevel{1,1} = highThresholdStatus;
                    [durationStatusHighLevel, dataHighLevel] = mySpmHistoryHandler.evaluateDurationStatus(trendParameters, ...
                        myHistoryTable.statusHighLevel, myHistoryTable.date);
                    highStatusEvaluatedTag = mySpmHistoryHandler.evaluateStatus(dataHighLevel.data, myFiles);
                    inputArgs = [actualPeriod double(str2numStatus.(highStatusEvaluatedTag{1,1})) highLevelTrendStatus];
                    highStatusEvaluated = evalfis(inputArgs, mySpmHistoryHandler.fuzzyContainer.lRorHR);
                    
                    % delta evaluate status 
                    myHistoryTable.statusDelta{1,1} = deltaThresholdStatus;
                    [durationStatusDelta, dataDelta] = mySpmHistoryHandler.evaluateDurationStatus(trendParameters, ...
                        myHistoryTable.statusDelta, myHistoryTable.date);
                    deltaStatusEvaluatedTag = mySpmHistoryHandler.evaluateStatus(dataDelta.data, myFiles);
                    inputArgs = [actualPeriod double(str2numStatus.(deltaStatusEvaluatedTag{1,1})) deltaTrendStatus];
                    deltaStatusEvaluated = evalfis(inputArgs, mySpmHistoryHandler.fuzzyContainer.delta);
                    
                    inputArgs = [lowStatusEvaluated, highStatusEvaluated, deltaStatusEvaluated];
                    result = evalfis(inputArgs,mySpmHistoryHandler.fuzzyContainer.common);
                end
                
                mySpmHistoryHandler.result.lowLevelImageStruct = getImageStruct(myLowLevelTrend);
                mySpmHistoryHandler.result.highLevelImageStruct = getImageStruct(myHighLevelTrend);
            else
                result = -0.01;
                trainingPeriodMeanLowLevel = [];
                trainingPeriodStdLowLevel = [];
                trainingPeriodMeanHighLevel = [];
                trainingPeriodStdHighLevel = [];
                trainingPeriodMeanDelta = [];
                trainingPeriodStdDelta = [];
                durationStatusHighLevel = 0;
                durationStatusLowLevel = 0;
                durationStatusDelta = 0;
                
                deltaThresholdStatus = [];
                deltaStatusEvaluated = [];
                
                lowStatusEvaluated = -0.01;
                highStatusEvaluated = -0.01;
            end
            
            % Record results to the final structure
            % lowLevel
            mySpmHistoryHandler.result.lowLevel = round(lowLevelTrendStatus*100)/100;
            mySpmHistoryHandler.result.lowLevelValue = myHistoryTable.lowLevel(1,1);
            mySpmHistoryHandler.result.lowLevelVolatility = lowLevelVolatility;
            mySpmHistoryHandler.result.lowLevelVolatilityLevel = lowLevelVolatilityLevel;
            mySpmHistoryHandler.result.lowLevelImageStruct = lowLevelImageStruct;
            mySpmHistoryHandler.result.trainingPeriodMeanLowLevel = trainingPeriodMeanLowLevel;
            mySpmHistoryHandler.result.trainingPeriodStdLowLevel = trainingPeriodStdLowLevel;
            mySpmHistoryHandler.result.lowThresholdStatus = lowThresholdStatus;
            mySpmHistoryHandler.result.durationLowLevel = durationStatusLowLevel;
            mySpmHistoryHandler.result.statusOfHistoryLowLevel = round(lowStatusEvaluated*100);
            % highLevel
            mySpmHistoryHandler.result.highLevel = round(highLevelTrendStatus*100)/100;
            mySpmHistoryHandler.result.highLevelValue = myHistoryTable.highLevel(1,1);
            mySpmHistoryHandler.result.highLevelVolatility = highLevelVolatility;
            mySpmHistoryHandler.result.highLevelVolatilityLevel = highLevelVolatilityLevel;
            mySpmHistoryHandler.result.highLevelImageStruct = highLevelImageStruct;
            mySpmHistoryHandler.result.trainingPeriodMeanHighLevel = trainingPeriodMeanHighLevel;
            mySpmHistoryHandler.result.trainingPeriodStdHighLevel = trainingPeriodStdHighLevel;
            mySpmHistoryHandler.result.highThresholdStatus = highThresholdStatus;
            mySpmHistoryHandler.result.durationHighLevel = durationStatusHighLevel;
            mySpmHistoryHandler.result.statusOfHistoryHighLevel = round(highStatusEvaluated*100);
            % delta
            mySpmHistoryHandler.result.delta = round(deltaTrendStatus*100)/100;
            mySpmHistoryHandler.result.deltaValue = myHistoryTable.delta(1,1);
            mySpmHistoryHandler.result.deltaVolatility = deltaVolatility;
            mySpmHistoryHandler.result.deltaVolatilityLevel = deltaVolatilityLevel;
            mySpmHistoryHandler.result.trainingPeriodMeanDelta = trainingPeriodMeanDelta;
            mySpmHistoryHandler.result.trainingPeriodStdDelta = trainingPeriodStdDelta;
            mySpmHistoryHandler.result.deltaThresholdStatus = deltaThresholdStatus;
            mySpmHistoryHandler.result.durationDelta = durationStatusDelta;
            mySpmHistoryHandler.result.statusOfHistoryDelta = round(deltaStatusEvaluated*100);
            
            mySpmHistoryHandler.result.result = round(result*100);
            
            % Ploting images with the result data
            if str2double(mySpmHistoryHandler.parameters.plotEnable)
                if ~isempty(lowLevelImageStruct)
                    plotAndPrint(mySpmHistoryHandler, myLowLevelTrendHandler, myHighLevelTrendHandler, myDeltaTrendHandler, warningLevel, damageLevel);
                    
                    if checkImages(fullfile(pwd, 'Out'), 'history-spm-LRHR-acc-', mySpmHistoryHandler.parameters.plots.imageFormat)
                        printComputeInfo(iLoger, 'spmLRHRHistoryHandler', 'The method images were saved.')
                    end
                end
            end
			printComputeInfo(iLoger, 'spmLRHRHistoryHandler', 'spmLRHR history processing COMPLETE.');
        end
        
        % PLOTANDPRINT function draws and saves plots to jpeg format
        function [status] = plotAndPrint(mySpmHistoryHandler, myLowLevelTrendHandler, myHighLevelTrendHandler, myDeltaTrendHandler, warningLevel, damageLevel)
            
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
            myDeltaTrend = getTrend(myDeltaTrendHandler);
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
                title(myAxes, ['SPM - LR/HR ', Translations.method.Attributes.name]);
            end
            % Figure labels
            xlabel(myAxes, upperCase(Translations.actualPeriod.Attributes.name, 'first'));
            ylabel(myAxes, [upperCase(Translations.level.Attributes.name, 'first'), ', ', Translations.acceleration.Attributes.value]);
            % Replace the x-axis values by the date
            xticks(myAxes, lowLevelImageStruct.signal( : , 1));
            xticklabels(myAxes, lowLevelImageStruct.date);
            xtickangle(myAxes, 90);
            if ~isempty(myArea)
                % Display legend
                legend([myPlot, flip(myArea)], ...
                    {'Low Rate of occurrence of signal', 'Low Rate of occurrence of trend', ...
                    'High Rate of occurrence of signal', 'High Rate of occurrence of trend', ...
                    'Damage Level', 'Warning level', 'Normal level'}, ...
                    'Location', 'northwest');
            else
                % Display legend
                legend(myPlot, ...
                    {'Low Rate of occurrence of signal', 'Low Rate of occurrence of trend', ...
                    'High Rate of occurrence of signal', 'High Rate of occurrence of trend'}, ...
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
                    ['Volatility: ', num2str(round(getSignalVolatility(myDeltaTrend))), '%'];
                    ['Relative volatility level: ', getRelativeVolatilityLevel(myDeltaTrend)];
                    ['Trend: ',  writeResultTrend(mySpmHistoryHandler, mySpmHistoryHandler.result.delta)];
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
                fileName = ['history-spm-LRHR-acc-', imageNumber];
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
            mySpmHistoryHandler.fuzzyContainer.lRorHR = mySpmHistoryHandler.createFuzzyContainerForLROrHR(maxPeriod);
            mySpmHistoryHandler.fuzzyContainer.common = mySpmHistoryHandler.createFuzzyContainerCommon();
            mySpmHistoryHandler.fuzzyContainer.delta = mySpmHistoryHandler.createFuzzyContainerForDelta(maxPeriod);
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
        
        % EVALUATEDELTADECREASE function evaluate delta of the threshold, 
        % if it is decreasing
        function status = ...
                evaluateDeltaDecrease(thresholds, mean, dataVector)
            % To create thresholds for decrease of value
            thresholdLow = 2*mean - thresholds(1);
            thresholdAverage = 2*mean - thresholds(2);
            thresholdHigh = 2*mean - thresholds(3);
            
            % Initialization of parameters
            currentValue = dataVector(end);
            
            if currentValue > thresholdLow 
                status = 'GREEN';
            elseif currentValue < thresholdLow && currentValue >= thresholdAverage
                status = 'YELLOWDecrease';
            elseif currentValue < thresholdAverage && currentValue >= thresholdHigh
                status = 'ORANGEDecrease';
            else
                status = 'REDDecrease';
            end
        end
        
        % CREATEFUZZYCONTAINERFORLRORHR function create rules to calculate status  
        function [container] = createFuzzyContainerForLROrHR(maxPeriod)            
            container = newfis('optipaper');
            
            % INPUT:
            % Init 3-state @actualPeriod variable
            container = addvar(container,'input','actualPeriod',[-0.75 (maxPeriod + 0.75)]);
            container = addmf(container,'input',1,'short','gauss2mf',[0.25 1 0.25 2]);
            container = addmf(container,'input',1,'long','gauss2mf',[0.25 3 0.25 maxPeriod]);
            container = addmf(container,'input',1,'no','gaussmf',[0.25 0]);
            
            % INPUT:
            % Init 3-state @tags variable
            container = addvar(container,'input','tags',[-0.25 1.25]);
            container = addmf(container,'input',2,'green','gauss2mf',[0.1 0 0.0625 0.5]);
            container = addmf(container, 'input',2,'orange','gaussmf',[0.0625 0.75]);
            container = addmf(container, 'input',2,'red','gaussmf',[0.0625 1]);
            
            % INPUT:
            % Init 6-state @trendStatus variable
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
                         
                         2  1  1  4  1  1;
                         2  1  2  4  1  1;  
                         2  1  3  4  1  1;
                         2  1  4  1  1  1;
                         2  1  5  1  1  1;
                         2  1  6  1  1  1;
                         
                         2  2  1  1  1  1;
                         2  2  2  2  1  1;
                         2  2  3  2  1  1;
                         2  2  4  2  1  1;
                         2  2  5  3  1  1;
                         2  2  6  2  1  1;
                         
                         2  3  1  2  1  1;
                         2  3 -1  3  1  1;
                       ];

            container = addrule(container,ruleList);        
        end
        
        % CREATEFUZZYCONTAINERFORDELTA function create rules to calculate
        % status of delta level
        function [container] = createFuzzyContainerForDelta(maxPeriod)            
            container = newfis('optipaper');
            
            % INPUT:
            % Init 3-state @actualPeriod variable
            container = addvar(container,'input','actualPeriod',[-0.75 (maxPeriod + 0.75)]);
            container = addmf(container,'input',1,'short','gauss2mf',[0.25 1 0.25 2]);
            container = addmf(container,'input',1,'long','gauss2mf',[0.25 3 0.25 maxPeriod]);
            container = addmf(container,'input',1,'no','gaussmf',[0.25 0]);
            
            % INPUT:
            % Init 5-state @levelDelta variable
            container = addvar(container,'input','levelDelta',[-1.25 1.25]);
            container = addmf(container,'input',2,'redDecrease','gaussmf',[0.0625 -1]);
            container = addmf(container,'input',2,'orangeDecrease','gauss2mf',[0.0625 -0.75 0.0625 -0.5]);
            container = addmf(container,'input',2,'green','gauss2mf',[0.0625 -0.25 0.0625 0.25]);
            container = addmf(container,'input',2,'orange','gauss2mf',[0.0625 0.5 0.0625 0.75]);
            container = addmf(container,'input',2,'red','gaussmf',[0.0625 1]);
            
            % INPUT:
            % Init 6-state @trendDelta variable
            container = addvar(container,'input','trendDelta',[-1.375 1.875]);
            container = addmf(container,'input',3,'declining','gaussmf',[0.125 -1]);
            container = addmf(container,'input',3,'mb_declining','gaussmf',[0.125 -0.5]);
            container = addmf(container,'input',3,'stable','gaussmf',[0.125 0]);
            container = addmf(container,'input',3,'mb_growing','gaussmf',[0.125 0.5]);
            container = addmf(container,'input',3,'growing','gaussmf',[0.125 1]);
            container = addmf(container,'input',3,'unknown','gaussmf',[0.125 1.5]);
            
            % OUTPUT:
            % Init 4-state @result variable
            container = addvar(container, 'output','result', [-1.25 1.25]);
            container = addmf(container,'output',1,'redDecrease','gaussmf',[0.0625 -1]);
            container = addmf(container,'output',1,'orangeDecrease','gauss2mf',[0.0625 -0.75 0.0625 -0.5]);
            container = addmf(container,'output',1,'green','gauss2mf',[0.0625 -0.25 0.0625 0.25]);
            container = addmf(container,'output',1,'orangeIncrease','gauss2mf',[0.0625 0.5 0.0625 0.75]);
            container = addmf(container,'output',1,'redIncrease','gaussmf',[0.0625 1]);   
            
            ruleList = [ 3  0  0  4  1  1; % short or no actualPeriod
                         1  0  0  4  1  1;
                         
                         2  1 -5  1  1  1; % red decrease
                         2  1  5  2  1  1;
                         
                         2  2  1  1  1  1; % orange decrease
                         2  2  2  2  1  1; 
                         2  2  3  2  1  1; 
                         2  2  4  2  1  1; 
                         2  2  5  3  1  1; 
                         2  2  6  2  1  1; 
                         
                         2  3  1  2  1  1; % green
                         2  3  2  3  1  1;
                         2  3  3  3  1  1;
                         2  3  4  3  1  1;
                         2  3  5  4  1  1;
                         2  3  6  3  1  1;
                         
                         2  4  1  3  1  1; % orange
                         2  4  2  4  1  1;
                         2  4  3  4  1  1;
                         2  4  4  4  1  1;
                         2  4  5  5  1  1;
                         2  4  6  4  1  1;
                         
                         2  5  1  4  1  1; % red
                         2  5 -1  5  1  1;
                       ];

            container = addrule(container,ruleList);        
        end
        
        % CREATEFUZZYCONTAINERCOMMON function create rules to calculate status  
        function [container] = createFuzzyContainerCommon()            
            container = newfis('optipaper');
            
            % INPUT:
            % Init 4-state @LR variable
            container = addvar(container,'input','LR',[0 1]);
            container = addmf(container,'input',1,'possiblyTroubling','gaussmf',[0.0625  0.375]);
            container = addmf(container,'input',1,'troubling','gaussmf',[0.0625 0.625]);
            container = addmf(container,'input',1,'critical','gauss2mf',[0.0625 0.875 0.01 1]);
            container = addmf(container,'input',1,'noDangerous','gauss2mf',[0.1 0 0.0625 0.125]);   
            
            % INPUT:
            % Init 4-state @HR variable
            container = addvar(container,'input','HR',[0 1]);
            container = addmf(container,'input',2,'possiblyTroubling','gaussmf',[0.0625  0.375]);
            container = addmf(container,'input',2,'troubling','gaussmf',[0.0625 0.625]);
            container = addmf(container,'input',2,'critical','gauss2mf',[0.0625 0.875 0.01 1]);
            container = addmf(container,'input',2,'noDangerous','gauss2mf',[0.1 0 0.0625 0.125]);
            
            % INPUT:
            % Init 5-state @HR delta
            container = addvar(container, 'input','delta', [-1.25 1.25]);
            container = addmf(container,'input',3,'redDecrease','gaussmf',[0.0625 -1]);
            container = addmf(container,'input',3,'orangeDecrease','gauss2mf',[0.0625 -0.75 0.0625 -0.5]);
            container = addmf(container,'input',3,'green','gauss2mf',[0.0625 -0.25 0.0625 0.25]);
            container = addmf(container,'input',3,'orangeIncrease','gauss2mf',[0.0625 0.5 0.0625 0.75]);
            container = addmf(container,'input',3,'redIncrease','gaussmf',[0.0625 1]);   
            
            % OUTPUT:
            % Init 4-state @result variable
            container = addvar(container,'output', 'result', [0 1]);
            container = addmf(container,'output',1,'possiblyTroubling','gaussmf',[0.0625  0.375]);
            container = addmf(container,'output',1,'troubling','gaussmf',[0.0625 0.625]);
            container = addmf(container,'output',1,'critical','gauss2mf',[0.0625 0.875 0.01 1]);
            container = addmf(container,'output',1,'noDangerous','gauss2mf',[0.1 0 0.0625 0.125]);     
            
            ruleList = [ 4  4  0  4  1  1; % no dangerous
                         
                        -4 -4  1  3  1  1; % lubrication defect
                        -4 -4  5  3  1  1; % empty lubrication or startet defect of bearing
                         
                         % orangeDecrease
                         1  1  2  1  1  1; 
                         1  2  2  2  1  1;
                         1  3  2  3  1  1;
                         1  4  2  1  1  1;
                         
                         2  1  2  1  1  1;   
                         2  2  2  2  1  1;
                         2  3  2  3  1  1;
                         2  4  2  2  1  1; % lubrication defect
                         
                         3  1  2  1  1  1; % lubrication defect
                         3  2  2  2  1  1;
                         3  3  2  3  1  1;
                         3  4  2  1  1  1;
                         
                         4  1  2  1  1  1; 
                         4  2  2  2  1  1; % lubrication defect
                         4  3  2  3  1  1;
                         
                         % green
                         1  1  3  1  1  1; 
                         1  2  3  2  1  1;
                         1  3  3  3  1  1;
                         1  4  3  1  1  1;
                         
                         2  1  3  1  1  1;   
                         2  2  3  2  1  1;
                         2  3  3  3  1  1;
                         2  4  3  1  1  1; 
                         
                         3  1  3  1  1  1; 
                         3  2  3  2  1  1;
                         3  3  3  3  1  1;
                         3  4  3  1  1  1;
                         
                         4  1  3  4  1  1; 
                         4  2  3  1  1  1; 
                         4  3  3  2  1  1;
                         
                         % orangeIncrease
                         1  1  4  1  1  1; 
                         1  2  4  2  1  1;
                         1  3  4  3  1  1;
                         1  4  4  1  1  1;
                         
                         2  1  4  1  1  1;   
                         2  2  4  2  1  1;
                         2  3  4  3  1  1; % empty lubrication or startet defect of bearing
                         2  4  4  1  1  1; 
                         
                         3  1  4  2  1  1; 
                         3  2  4  3  1  1;
                         3  3  4  3  1  1; % empty lubrication or startet defect of bearing
                         3  4  4  2  1  1;
                         
                         4  1  4  4  1  1; 
                         4  2  4  1  1  1; 
                         4  3  4  2  1  1;
                       ];

            container = addrule(container,ruleList);        
        end
    end
end

