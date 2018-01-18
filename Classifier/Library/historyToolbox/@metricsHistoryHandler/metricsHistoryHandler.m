classdef metricsHistoryHandler < historyHandler
    % METRICSHISTORYHANDLER class is used to evaluation changes in metrics
    % over time
    
    properties (Access = protected)
        parameters    % include parameters for this class from config.xml
    end
    
    methods (Access = public)
        % METRICSHISTORYHANDLER constructor method
        function [myMetricsHistoryHandler] = metricsHistoryHandler(myConfig, myFiles, myTranslations, myXmlToStructHistory)
            if nargin < 1
                error('There are not enough input arguments!');
            end
            
            myContainerTag = 'metrics';
            myMetricsHistoryHandler = myMetricsHistoryHandler@historyHandler(myConfig, myFiles, myContainerTag, myTranslations, myXmlToStructHistory);
            
            % Extract parameters from config
            Parameters = [];
            if isfield(myConfig.config.parameters.evaluation, 'metrics')
                if isfield(myConfig.config.parameters.evaluation.metrics, 'acceleration')
                    Parameters.acceleration = myConfig.config.parameters.evaluation.metrics.acceleration;
                end
                if isfield(myConfig.config.parameters.evaluation.metrics, 'velocity')
                    Parameters.velocity = myConfig.config.parameters.evaluation.metrics.velocity;
                end
                if isfield(myConfig.config.parameters.evaluation.metrics, 'displacement')
                    Parameters.displacement = myConfig.config.parameters.evaluation.metrics.displacement;
                end
            end
            if isfield(myFiles.files, 'history')
                if isfield(myFiles.files.history.Attributes, 'actualPeriod')
                    Parameters.actualPeriod = myFiles.files.history.Attributes.actualPeriod;
                end
            end
            Parameters.debugModeEnable = myConfig.config.parameters.common.debugModeEnable.Attributes.value;
            Parameters.parpoolEnable = myConfig.config.parameters.common.parpoolEnable.Attributes.value;
            Parameters.plots = myConfig.config.parameters.evaluation.plots.Attributes;
            Parameters.plotEnable = myConfig.config.parameters.evaluation.history.Attributes.plotEnable;
            Parameters.plotVisible = myConfig.config.parameters.common.printPlotsEnable.Attributes.visible;
            Parameters.plotTitle = myConfig.config.parameters.common.printPlotsEnable.Attributes.title;
            Parameters.printPlotsEnable = myConfig.config.parameters.common.printPlotsEnable.Attributes.value;
            
            myMetricsHistoryHandler.parameters = Parameters;
            
            myMetricsHistoryHandler = createFuzzyContainer(myMetricsHistoryHandler);
            myMetricsHistoryHandler = historyProcessing(myMetricsHistoryHandler);
        end
        
        % FILLDOCNODE function fills docNode document with calculated
        % result data
        function [docNode] = fillDocNode(myMetricsHistoryHandler, docNode)
            iLoger = loger.getInstance;
            myResult = getResult(myMetricsHistoryHandler);
            if isempty(myResult)
                % Metrics history is empty
                return;
            end
            
            % Replase an existing node with a new node
            docRootNode = docNode.getDocumentElement;
            if hasChildNodes(docRootNode)
                childNodes = getChildNodes(docRootNode);
                numChildNodes = getLength(childNodes);
                for i = 1 : 1 : numChildNodes
                    currentChild = item(childNodes, i - 1);
                    childName = toCharArray(getNodeName(currentChild))';
                    if strcmp(childName, 'metrics')
                        docRootNode.removeChild(currentChild);
                        break;
                    end
                end
            end
            
            % Create metrics node
            metricsNode = docNode.createElement('metrics');
            
            % Find spaces fields
            spacesFieldsNames = fieldnames(myResult);
            for spaceNumber = 1 : 1 : length(spacesFieldsNames)
                currentSpaceName = spacesFieldsNames{spaceNumber};
                % Find metrics fields in current space
                metricsFieldsNames = fieldnames(myResult.(currentSpaceName));
                
                % Create status, informativeTags and imageData nodes
                statusNode = docNode.createElement('status');
                informativeTagsNode = docNode.createElement('informativeTags');
                imageDataNode = docNode.createElement('imageData');
                
                for metricNumber = 1 : 1 : length(metricsFieldsNames)
                    currentMetricName = metricsFieldsNames{metricNumber};
                    % Create status node of current metric
                    metricStatusNode = docNode.createElement(currentMetricName);
                    % Set attributes of the node
                    metricStatusNode.setAttribute('trend', ...
                        num2str(myResult.(currentSpaceName).(currentMetricName).trendValue));
                    metricStatusNode.setAttribute('volatility', ...
                        num2str(myResult.(currentSpaceName).(currentMetricName).volatility));
                    metricStatusNode.setAttribute('volatilityLevel', ...
                        myResult.(currentSpaceName).(currentMetricName).volatilityLevel);
                    metricStatusNode.setAttribute('value', ...
                        num2str(myResult.(currentSpaceName).(currentMetricName).result));
                    
                    % Set status node of current metric to status node
                    statusNode.appendChild(metricStatusNode);
                    
                    % Create informativeTags node of current metric
                    metricInformativeTagsNode = docNode.createElement(currentMetricName);
                    % Set attributes of the node
                    metricInformativeTagsNode.setAttribute('value', ...
                        num2str(myResult.(currentSpaceName).(currentMetricName).value));
                    metricInformativeTagsNode.setAttribute('status', ...
                        myResult.(currentSpaceName).(currentMetricName).status);
                    metricInformativeTagsNode.setAttribute('trainingPeriodMean', ...
                        num2str(myResult.(currentSpaceName).(currentMetricName).trainingPeriodMean));
                    metricInformativeTagsNode.setAttribute('trainingPeriodStd', ...
                        num2str(myResult.(currentSpaceName).(currentMetricName).trainingPeriodStd));
                    metricInformativeTagsNode.setAttribute('durationStatus', ...
                        num2str(myResult.(currentSpaceName).(currentMetricName).durationStatus));
                    metricInformativeTagsNode.setAttribute('percentGrowth', ...
                        num2str(myResult.(currentSpaceName).(currentMetricName).percentGrowth));
                    
                    % Set informativeTags node of current metric to
                    % informativeTags node
                    informativeTagsNode.appendChild(metricInformativeTagsNode);
                    
                    if ~isempty(myResult.(currentSpaceName).(currentMetricName).imageStruct)
                        % Create imageStructNode of currentMetric
                        imageStructNode = createImageStructNode(myMetricsHistoryHandler, docNode, ...
                            myResult.(currentSpaceName).(currentMetricName).imageStruct, currentMetricName);

                        % Set imageStructNode of current metric to
                        % imageDataNode
                        imageDataNode.appendChild(imageStructNode);
                    end
                end
                
                % Create the node of current space
                spaceNode = docNode.createElement(currentSpaceName);
                % Set status, informativeTaga and imageData nodes to space
                % node
                spaceNode.appendChild(statusNode);
                spaceNode.appendChild(informativeTagsNode);
                if hasChildNodes(imageDataNode)
                    spaceNode.appendChild(imageDataNode);
                end
                % Set space node to metrics node
                metricsNode.appendChild(spaceNode);
            end
            
            % Set metrics node to root node
            docRootNode.appendChild(metricsNode);
            printComputeInfo(iLoger, 'metricsHistoryHandler', 'docNode structure was successfully updated.');
        end
    end
    
    methods (Access = protected)
        
        % HISTORYPROCESSING function calculates the trends of metrics from
        % current data and history data and print them into @Out directory
        function [myMetricsHistoryHandler] = historyProcessing(myMetricsHistoryHandler)
            % Loger initialization
            iLoger = loger.getInstance;
            
            % Get input data
            myHistoryContainer = getHistoryContainer(myMetricsHistoryHandler);
            myHistoryTable = getHistoryTable(myHistoryContainer);
            myConfig = getConfig(myMetricsHistoryHandler);
            myFiles = getFiles(myMetricsHistoryHandler);
            
            if isempty(myHistoryTable) || (length(myHistoryTable.date) < 4)
                printComputeInfo(iLoger, 'Metrics history', 'There is empty history.');
                myMetricsHistoryHandler.result = [];
                return;
            end
            
            % Get parameters for trendHandler class
            trendParameters = [];
            if isfield(myConfig.config.parameters.evaluation.history, 'trend')
                trendParameters = myConfig.config.parameters.evaluation.history.trend.Attributes;
            end
            trendParameters.actualPeriod = myMetricsHistoryHandler.parameters.actualPeriod;
            
            statuses = cell(length(myHistoryTable.date),1);
                        
            % Get fields names of historyTable
            historyTableFieldsNames = fieldnames(myHistoryTable);
            % Find date fields
            dateFieldsPositions = cellfun(@(x) strcmp(x, 'date'), historyTableFieldsNames);
            % Find spaces fields
            spacesNames = historyTableFieldsNames(~dateFieldsPositions);
            % Get date of files
            filesDate = myHistoryTable.date;
            
            plotStructLength = 0;
            for spaceNumber = 1 : 1 : length(spacesNames)
                currentSpaceName = spacesNames{spaceNumber};
                % Get fields names of metrics
                metricsNames = fieldnames(myHistoryTable.(currentSpaceName));
                for metricNumber = 1 : 1 : length(metricsNames)
                    currentMetricName = metricsNames{metricNumber};
                    currentMetricValues = myHistoryTable.(currentSpaceName).(currentMetricName).value;
                    % Get trend of the current metric
                    metricTrendHandler = trendHandler(currentMetricValues, trendParameters, filesDate);
                    % Get resulting data of trend of the current metric
                    metricTrend = getTrend(metricTrendHandler);
                    metricTrendValue = getResult(metricTrendHandler);
                    metricTrendSignal = getSignal(metricTrend);
                    metricVolatility = getSignalVolatility(metricTrend);
                    metricVolatilityLevel = getRelativeVolatilityLevel(metricTrend);
                    metricImageStruct = getImageStruct(metricTrend);
                    % Evaluate resulting data of trend of the current
                    % metric
                    if contains(currentMetricName, 'iso10816')
                        strMetricStatus = iso10816(metricTrendSignal(end), myHistoryTable.velocity.iso10816.equipmentClass);
                    else
                        thresholdMetrics = myMetricsHistoryHandler.parameters.(currentSpaceName).(currentMetricName).Attributes.thresholds;
                        if isempty(thresholdMetrics)
                            strMetricStatus = '';
                        else
                            strMetricStatus = myMetricsHistoryHandler.evaluationMetricsThresholds(metricTrendSignal(end), thresholdMetrics);
                        end
                    end
                    trainingPeriodStd =  myHistoryTable.(currentSpaceName).(currentMetricName).trainingPeriodStd;
                    trainingPeriodMean = myHistoryTable.(currentSpaceName).(currentMetricName).trainingPeriodMean;
                    % Get threshold with training period
                    [strMetricStatus, trainingPeriodMean, trainingPeriodStd, thresholds] = ...
                        getTrainingPeriodAndStatus(trainingPeriodStd, trainingPeriodMean, myFiles, getDate(metricTrend), metricTrendSignal, strMetricStatus, filesDate);  
                    
                    if isnan(thresholds)
                        if ~contains(currentMetricName, 'iso10816')
                            % Get thresholds from config
                            % Split thresholds into cells
                            thresholds = str2double(strsplit(myMetricsHistoryHandler.parameters.(currentSpaceName).(currentMetricName).Attributes.thresholds, ':')'); 
                        else
                            % Get thresholds of iso10816 method
                            [~, thresholds] = iso10816(metricTrendSignal(end), myHistoryTable.velocity.iso10816.equipmentClass);
                        end
                    end
                    
                    if ~isempty(strfind(currentMetricName, 'unidentifiedPeaksNumbers'))
                        thresholds = nan(3,1);
                    end
                    
                    if isempty(strMetricStatus) || isempty(metricVolatility)
                        % Metric status unknown
                        metricResult = -0.01;
                        trainingPeriodMean = [];
                        trainingPeriodStd = [];
                        durationStatus = 0;
                    else
                        % Evaluation period
                        metricTrendDuration = length(metricTrendSignal);
                        
                        statuses{1,1} = strMetricStatus;
                        statuses(2:end,1) = myHistoryTable.(currentSpaceName).(currentMetricName).status(2:end,1);
                        [durationStatus, compressionData] = myMetricsHistoryHandler.evaluateDurationStatus(trendParameters, ...
                            statuses, myHistoryTable.date);
                        statusEvaluated = myMetricsHistoryHandler.evaluateStatus(compressionData.data, myFiles);
                        
                        % Convert metric status in the number format
                        numMetricStatus = double(str2numStatus.(statusEvaluated{1,1}));
                        % Prepare data to evaluation
                        metricInputArgs = [metricTrendDuration, numMetricStatus, metricTrendValue];
                        % Get result status of metric
                        metricResult = evalfis(metricInputArgs, myMetricsHistoryHandler.fuzzyContainer);
                    end
                    
                    % Set results to the result property
                    Results.value = myHistoryTable.(currentSpaceName).(currentMetricName).value(1, 1);
                    Results.status = strMetricStatus;
                    Results.volatility = metricVolatility;
                    Results.durationStatus = durationStatus;
                    Results.volatilityLevel = metricVolatilityLevel;
                    Results.trendValue = round(metricTrendValue * 100) / 100;
                    Results.result = round(metricResult * 100); % [%]
                    Results.imageStruct = metricImageStruct;
                    Results.trainingPeriodMean = trainingPeriodMean;
                    Results.trainingPeriodStd = trainingPeriodStd;
                    if ~isempty(Results.trainingPeriodMean)  
                        Results.percentGrowth = round(Results.value/Results.trainingPeriodMean,2)*100 - 100;
                    else
                        Results.percentGrowth = [];
                    end
                    myMetricsHistoryHandler.result.(currentSpaceName).(currentMetricName) = Results;
                    
                    plotStructLength = plotStructLength + 1;
                    plotStruct(plotStructLength).metricName = currentMetricName;
                    plotStruct(plotStructLength).signalType = currentSpaceName;
                    plotStruct(plotStructLength).imageStruct = Results.imageStruct;
                    plotStruct(plotStructLength).thresholds = thresholds;
                    plotStruct(plotStructLength).volatility = num2str(round(Results.volatility));
                    plotStruct(plotStructLength).volatilityLevel = Results.volatilityLevel;
                    plotStruct(plotStructLength).strTrendValue = metricsHistoryHandler.num2strTrend(metricTrendValue);
                    plotStruct(plotStructLength).strResult = metricsHistoryHandler.num2strResult(metricResult);
                end
            end
            
            myMetricsHistoryHandler.result = myMetricsHistoryHandler.evaluateNonValidPeaksNumbers(myMetricsHistoryHandler.result);
            
            if str2double(myMetricsHistoryHandler.parameters.plotEnable)
                if str2double(myMetricsHistoryHandler.parameters.parpoolEnable)
                    parfor metricNumber = 1 : 1 : length(plotStruct)
                        if ~isempty(plotStruct(metricNumber).imageStruct)
                            plotAndPrint(myMetricsHistoryHandler, plotStruct(metricNumber));
                        end
                    end
                else
                    for metricNumber = 1 : 1 : length(plotStruct)
                        if ~isempty(plotStruct(metricNumber).imageStruct)
                            plotAndPrint(myMetricsHistoryHandler, plotStruct(metricNumber));
                        end
                    end
                end
                
                imagesTags = cellfun(@(metricName) ['history-metrics-', metricName], ...
                    {plotStruct.metricName}, 'UniformOutput', false);
                if checkImages(fullfile(pwd, 'Out'), imagesTags, myMetricsHistoryHandler.parameters.plots.imageFormat)
                    printComputeInfo(iLoger, 'metricsHistoryHandler', 'The method images were saved.')
                end
            end
            
			printComputeInfo(iLoger, 'metricsHistoryHandler', 'Metrics history processing COMPLETE.');
        end
        
        % PLOTANDPRINT function plots figure of some input data and trend 
        % and prints them into @Out directory
        function plotAndPrint(myMetricsHistoryHandler, plotStruct)
            
            % Get parameters
            Translations = myMetricsHistoryHandler.translations;
            
            plotVisible = myMetricsHistoryHandler.parameters.plotVisible;
            plotTitle = myMetricsHistoryHandler.parameters.plotTitle;
            printPlotsEnable = str2double(myMetricsHistoryHandler.parameters.printPlotsEnable);
            sizeUnits = myMetricsHistoryHandler.parameters.plots.sizeUnits;
            imageSize = str2num(myMetricsHistoryHandler.parameters.plots.imageSize);
            fontSize = str2double(myMetricsHistoryHandler.parameters.plots.fontSize);
            imageFormat = myMetricsHistoryHandler.parameters.plots.imageFormat;
            imageQuality = myMetricsHistoryHandler.parameters.plots.imageQuality;
            imageResolution = myMetricsHistoryHandler.parameters.plots.imageResolution;
            
            % Get imageStruct
            imageStruct = plotStruct.imageStruct;
            % Get thresholds
            thresholdsValues = plotStruct.thresholds;
            if (length(thresholdsValues) == 3)
                thresholdsLabels = {'Damage level', 'Warning level', 'Caution level', 'Normal level'};
            elseif (length(thresholdsValues) == 2)
                thresholdsLabels = {'Damage level', 'Warning level', 'Normal level'};
            else
                thresholdsLabels = [];
            end
            
            % Get the short signal type and the signal type translation
            switch plotStruct.signalType
                case 'acceleration'
                    shortSignalType = 'acc';
                    signalTypeTranslation = Translations.acceleration.Attributes.name;
                case 'velocity'
                    shortSignalType = 'vel';
                    signalTypeTranslation = Translations.velocity.Attributes.name;
                case 'displacement'
                    shortSignalType = 'disp';
                    signalTypeTranslation = Translations.displacement.Attributes.name;
                otherwise
                    shortSignalType = 'acc';
                    signalTypeTranslation = Translations.acceleration.Attributes.name;
            end
            
            % Plot
            myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
            hold on;
            % Plot the signal and the approximation
            myPlot(1) = plot(imageStruct.signal( : , 1), imageStruct.signal( : , 2), ...
                'Color', [0, 1, 1], 'LineWidth', 2);
            myPlot(2) = plot(imageStruct.approx( : , 1), imageStruct.approx( : , 2), ...
                '--', 'Color', [0, 0, 1], 'LineWidth', 2);
            % Plot thresholds
            if ~isnan(thresholdsValues)
                [myFigure, myArea] = fillArea(myFigure, thresholdsValues);
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
                title(myAxes, [upperCase(Translations.metrics.Attributes.name, 'first'), ' ', Translations.method.Attributes.name, ' - ', ...
                    upperCase(plotStruct.metricName, 'all'), ' ', Translations.trend.Attributes.name, ' : ', ...
                    upperCase(Translations.signal.Attributes.name, 'first'), ' - ', ...
                    upperCase(signalTypeTranslation, 'first')]);
            end
            % Figure labels
            xlabel(myAxes, upperCase(Translations.actualPeriod.Attributes.name, 'first'));
            ylabel(myAxes, upperCase(Translations.value.Attributes.name, 'first'));
            % Replace the x-axis values by the date
            xticks(myAxes, imageStruct.signal( : , 1));
            xticklabels(myAxes, imageStruct.date);
            xtickangle(myAxes, 90);
            
            % Display legend
            if ~isempty(myArea) 
                legend([myPlot, flip(myArea)], ...
                    [{'Values', 'Trend'}, thresholdsLabels], ...
                    'Location', 'northwest');
            else
                legend(myPlot, {'Values', 'Trend'}, 'Location', 'northwest');
            end
                
            if str2double(myMetricsHistoryHandler.parameters.debugModeEnable)
                % Debug mode
                % Get the limits of axis
                xLimits = xlim;
                yLimits = ylim;
                % The bottom left point of the figure for the text
                % Calculate the position of the text on x-axis
                xTextPosition = 0.020 * abs(diff(xLimits)) + xLimits(1);
                % Calculate the position of the text on y-axis
                yTextPosition = 0.025 * abs(diff(yLimits)) + yLimits(1);
                
                textContent = {
                    ['Volatility: ', plotStruct.volatility, '%'];
                    ['Relative volatility level: ', plotStruct.volatilityLevel];
                    ['Trend: ', plotStruct.strTrendValue];
                    ['Status: ', plotStruct.strResult];
                    };
                
                % Write the values of the status in the figure
                text(xTextPosition, yTextPosition, textContent, ...
                    'FontSize', fontSize, 'Interpreter', 'none', ...
                    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
                    'BackgroundColor', 'w', 'EdgeColor', 'k');
            end
            
            if printPlotsEnable
                % Save the image to the @Out directory
                imageNumber = '1';
                fileName = ['history-metrics-', plotStruct.metricName, '-', shortSignalType, '-', imageNumber];
                fullFileName = fullfile(pwd, 'Out', fileName);
                print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
            end
            
            % Close figure with visibility off
            if strcmpi(plotVisible, 'off')
                close(myFigure)
            end
        end
        
        % CREATEFUZZYCONTAINER function creates empty fuzzy container and
        % overwrite fuzzyContainer property
        function [myMetricsHistoryHandler] = createFuzzyContainer(myMetricsHistoryHandler)
            maxPeriod = str2double(myMetricsHistoryHandler.parameters.actualPeriod);
            container = newfis('optipaper');
            
            % INPUT:
            % Init states @actualPeriod variable
            container = addvar(container, 'input', 'actualPeriod', [-0.75 (maxPeriod + 0.75)]);
            container = addmf(container, 'input', 1, 'short', 'gauss2mf', [0.25 1 0.25 2]);
            container = addmf(container, 'input', 1, 'long', 'gauss2mf', [0.25 3 0.25 maxPeriod]);
            container = addmf(container, 'input', 1, 'no', 'gaussmf', [0.25 0]);
            
            % Init states @metricStatus variable
            container = addvar(container, 'input', 'metricStatus', [-0.1875 1.1875]);
            container = addmf(container, 'input', 2, 'green', 'gaussmf', [0.0625 0.25]);
            container = addmf(container, 'input', 2, 'yellow', 'gaussmf', [0.0625 0.50]);
            container = addmf(container, 'input', 2, 'orange', 'gaussmf', [0.0625 0.75]);
            container = addmf(container, 'input', 2, 'red', 'gaussmf', [0.0625 1]);
            container = addmf(container, 'input', 2, 'no', 'gaussmf', [0.0625 0]);
            
            % Init states @metricTrend variable
            container = addvar(container, 'input', 'metricTrend', [-1.375 1.875]);
            container = addmf(container, 'input', 3, 'declining', 'gaussmf', [0.125 -1]);
            container = addmf(container, 'input', 3, 'mb_declining', 'gaussmf', [0.125 -0.5]);
            container = addmf(container, 'input', 3, 'stable', 'gaussmf', [0.125 0]);
            container = addmf(container, 'input', 3, 'mb_growing', 'gaussmf', [0.125 0.5]);
            container = addmf(container, 'input', 3, 'growing', 'gaussmf', [0.125 1]);
            container = addmf(container, 'input', 3, 'unknown', 'gaussmf', [0.125 1.5]);
            
            % OUTPUT:
            % Init states @result variable
            container = addvar(container, 'output', 'result', [0 1]);
            container = addmf(container,'output',1,'possiblyTroubling','gaussmf',[0.0625  0.375]);
            container = addmf(container,'output',1,'troubling','gaussmf',[0.0625 0.625]);
            container = addmf(container,'output',1,'critical','gauss2mf',[0.0625 0.875 0.01 1]);
            container = addmf(container,'output',1,'noDangerous','gauss2mf',[0.1 0 0.0625 0.125]);            
            % RULES:
            % actualPeriod, metricStatus, metricTrend, result and etc
            ruleList = [
                        % actualPeriod = short
                        1  1  0  1  1  1;
                        1  2  0  1  1  1;
                        1  3  0  2  1  1;
                        1  4  0  3  1  1;

                        % actualPeriod = long
                        % status = green
                        2  1  0  1  1  1;

                        % status = yellow
                        2  2 -5  1  1  1;
                        2  2  5  2  1  1;

                        % status = orange
                        2  3 -5  2  1  1;
                        2  3  5  3  1  1;

                        % status = red
                        2  4  0  3  1  1;

                        % status = no
                       -3  5  0  4  1  1;
                        
                        % actualPeriod = no
                        3 -5  0  4  1  1;
                       ];
            
            container = addrule(container, ruleList);
            myMetricsHistoryHandler.fuzzyContainer = container;
        end
    end
    
    methods (Static)
        
        % NUM2STRTREND function converts the value of the trend of the
        % number format in the string format
        function [strTrend] = num2strTrend(numTrend)
            if numTrend <= -0.75
                strTrend = 'declining';
            elseif (numTrend > -0.75) && (numTrend <= -0.25)
                strTrend = 'maybe declining';
            elseif (numTrend > -0.25) && (numTrend < 0.25)
                strTrend = 'stable';
            elseif (numTrend >= 0.25) && (numTrend < 0.75)
                strTrend = 'maybe growing';
            elseif (numTrend >= 0.75) && (numTrend < 1.25)
                strTrend = 'growing';
            else
                strTrend = 'unknown';
            end
        end
        
        % NUM2STRRESULT function converts the value of the result of the
        % number format in the string format
        function [strResult] = num2strResult(numResult)
            if numResult < 0.01
                strResult = 'unknown';
            elseif (numResult >= 0.01) && (numResult < 0.25)
                strResult = 'normal';
            elseif (numResult >= 0.25) && (numResult < 0.75)
                strResult = 'troubling';
            else
                strResult = 'critical';
            end
        end
        
        %EVALUATIONMETRICSTHRESHOLDS function evaluate current 
        % value metrics with thresholds set user
        function [status] = evaluationMetricsThresholds(value, thresholds)
            thresholds = str2double(split(thresholds, ':'));
            if length(thresholds) == 2
                if value <= thresholds(1)
                    status = 'GREEN'; 
                elseif value > thresholds(1) && value <= thresholds(2)
                    status = 'ORANGE'; 
                elseif value > thresholds(2)
                    status = 'RED';
                else
                    status = '';
                end
            else
                if value <= thresholds(1)
                    status = 'GREEN';
                elseif value > thresholds(1) && value <= thresholds(2)
                    status = 'YELLOW'; 
                elseif value > thresholds(2) && value <= thresholds(3)
                    status = 'ORANGE';
                elseif value > thresholds(3)
                    status = 'RED';
                else
                    status = '';
                end
            end
        end
        
        % EVALUATENONVALIDPEAKSNUMBER function evaluate metrics
        % nonValidPeaksNumbers with only trend
        function [result] = evaluateNonValidPeaksNumbers(result)
            
            if isfield(result.acceleration, 'unidentifiedPeaksNumbers')
                result.acceleration.unidentifiedPeaksNumbers = ...
                    metricsHistoryHandler.evaluateNonValidPeaksNumbersOneMetrics(result.acceleration.unidentifiedPeaksNumbers);
            end
            
            if isfield(result.acceleration, 'unidentifiedPeaksNumbersEnvelope')
                result.acceleration.unidentifiedPeaksNumbersEnvelope = ...
                    metricsHistoryHandler.evaluateNonValidPeaksNumbersOneMetrics(result.acceleration.unidentifiedPeaksNumbersEnvelope);
            end
            
            if isfield(result.velocity, 'unidentifiedPeaksNumbers')
                result.velocity.unidentifiedPeaksNumbers = ...
                    metricsHistoryHandler.evaluateNonValidPeaksNumbersOneMetrics(result.velocity.unidentifiedPeaksNumbers);
            end
            
            if isfield(result.displacement, 'unidentifiedPeaksNumbers')
                result.displacement.unidentifiedPeaksNumbers = ...
                    metricsHistoryHandler.evaluateNonValidPeaksNumbersOneMetrics(result.displacement.unidentifiedPeaksNumbers);
            end
            
        end
        
        % EVALUATENONVALIDPEAKSNUMBERSONEMETRICS function evaluate each nonValidPeaksNumbers metric with trend
        function [result] = evaluateNonValidPeaksNumbersOneMetrics(result)
            
            if result.trendValue <= 0 
                
                result.result = 0;
            elseif result.trendValue > 0 && result.trendValue < 0.75
                
                result.result = 30;
            elseif result.trendValue > 0.75 && result.trendValue < 1.25
                
                result.result = 60;
            else
                result.result = 0;
            end
            
        end
    end
end

