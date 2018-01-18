classdef equipmentStateHistoryHandler < historyHandler
    % EQUIPMENTSTATEHISTORYHANDLER class
    % 
    % Developer:              P. Riabtsev
    % Development date:       09-10-2017
    % Modified by:            
    % Modification date:      
    
    properties (Access = protected)
        parameters
    end
    
    methods (Access = public)
        % EQUIPMENTSTATEHISTORYHANDLER constructor function
        function [myEquipmentStateHistoryHandler] = equipmentStateHistoryHandler(myConfig, myFiles, myTranslations, myXmlToStructHistory)
            myContainerTag = 'equipmentState';
            myEquipmentStateHistoryHandler = myEquipmentStateHistoryHandler@historyHandler(myConfig, myFiles, myContainerTag, myTranslations, myXmlToStructHistory);
            
            Parameters = myConfig.config.parameters.evaluation.equipmentStateDetection;
            Parameters.debugModeEnable = myConfig.config.parameters.common.debugModeEnable.Attributes.value;
            Parameters.plots = myConfig.config.parameters.evaluation.plots.Attributes;
            Parameters.plotEnable = myConfig.config.parameters.evaluation.history.Attributes.plotEnable;
            Parameters.plotVisible = myConfig.config.parameters.common.printPlotsEnable.Attributes.visible;
            myEquipmentStateHistoryHandler.parameters = Parameters;
            
            myEquipmentStateHistoryHandler = createFuzzyContainer(myEquipmentStateHistoryHandler);
            myEquipmentStateHistoryHandler = historyProcessing(myEquipmentStateHistoryHandler);
            
        end
        
        % FILLDOCNODE function
        function [docNode] = fillDocNode(myEquipmentStateHistoryHandler, docNode)
            
            myResult = getResult(myEquipmentStateHistoryHandler);
            
            if isempty(myResult)
                printWarning(myEquipmentStateHistoryHandler.iLoger, 'Equipment state history is empty!');
                return;
            end
            
            % Remove the existing node
            docRootNode = docNode.getDocumentElement;
            if hasChildNodes(docRootNode)
                childNodes = getChildNodes(docRootNode);
                childNodesNumber = getLength(childNodes);
                for nodeNumber = 1 : 1 : childNodesNumber
                    currentChild = item(childNodes, nodeNumber - 1);
                    childName = toCharArray(getNodeName(currentChild))';
                    if strcmp(childName, 'equipmentState')
                        docRootNode.removeChild(currentChild);
                        break;
                    end
                end
            end
            
            % Update the equipmentState attribute
            docRootNode.setAttribute('equipmentState', myResult.state);
            
            % Create the equipmentState node
            equipmentStateNode = docNode.createElement('equipmentState');
            
            % Get fields names of historyTable
            historyTableFieldsNames = fieldnames(myResult.historyTable);
            % Find the date field
            dateFieldIndex = strcmp(historyTableFieldsNames, 'date');
            % Get fields names of metrics
            metricsFieldsNames = historyTableFieldsNames(~dateFieldIndex);
            
            % Create the status node
            statusNode = docNode.createElement('status');
            % Create the informativeTags node
            informativeTagsNode = docNode.createElement('informativeTags');
            
            for metricNumber = 1 : 1 : length(metricsFieldsNames)
                
                % Get metric data
                metricName = metricsFieldsNames{metricNumber};
                metricHistoryTable = myResult.historyTable.(metricName);
                
                % Create the status node of the metric
                metricStatusNode = docNode.createElement(metricName);
                % Set attributes of the node
                metricStatusNode.setAttribute('value', ...
                    metricHistoryTable.status{1});
                % Set the node to the status node
                statusNode.appendChild(metricStatusNode);
                
                % Create the informativeTags node of the metric
                metricInformativeTagsNode = docNode.createElement(metricName);
                % Set attributes of the node
                metricInformativeTagsNode.setAttribute('value', ...
                    num2str(metricHistoryTable.value(1)));
                metricInformativeTagsNode.setAttribute('weight', ...
                    num2str(metricHistoryTable.weight(1)));
                metricInformativeTagsNode.setAttribute('onBoundaries', ...
                    num2str(metricHistoryTable.onBoundaries{1}));
                metricInformativeTagsNode.setAttribute('idleBoundaries', ...
                    num2str(metricHistoryTable.idleBoundaries{1}));
                metricInformativeTagsNode.setAttribute('offBoundaries', ...
                    num2str(metricHistoryTable.offBoundaries{1}));
                % Set the node to the informativeTags node
                informativeTagsNode.appendChild(metricInformativeTagsNode);
            end
            
            % Set the status and informativeTags nodes to the
            % equipmentState node
            if hasChildNodes(statusNode) && hasChildNodes(informativeTagsNode)
                equipmentStateNode.appendChild(statusNode);
                equipmentStateNode.appendChild(informativeTagsNode);
            end
            
            % Set the equipmentState node to the docRoot node
            docRootNode.appendChild(equipmentStateNode);
            
        end
    end
    
    methods (Access = protected)
        % CREATEFUZZYCONTAINER function (is unused)
        function [myEquipmentStateHistoryHandler] = createFuzzyContainer(myEquipmentStateHistoryHandler)
            myEquipmentStateHistoryHandler.fuzzyContainer = [];
        end
        
        % HISTORYPROCESSING function
        function [myEquipmentStateHistoryHandler] = historyProcessing(myEquipmentStateHistoryHandler)
            
            % Check config thresholds
            metricsParameters = myEquipmentStateHistoryHandler.parameters.metrics;
            metricsFieldsNames = fieldnames(metricsParameters);
            if ~isempty(metricsFieldsNames)
                % Get the thresholds
                thresholds = cellfun(@(metricName) str2num(metricsParameters.(metricName).Attributes.thresholds), metricsFieldsNames, ...
                    'UniformOutput', false);
                thresholdsExist = ~all(cellfun(@isempty, thresholds));
                if thresholdsExist
                    % One of the thresholds isn't empty
                    printComputeInfo(myEquipmentStateHistoryHandler.iLoger, 'equipmetnStateHistoryHandler', ...
                        'The thresholds are specified in the file config.xml.');
                    myEquipmentStateHistoryHandler.result = [];
                    return;
                end
            end
            
            % Get input data
            myHistoryContainer = getHistoryContainer(myEquipmentStateHistoryHandler);
            myHistoryTable = getHistoryTable(myHistoryContainer);
            
            if isempty(myHistoryTable)
                printWarning(myEquipmentStateHistoryHandler.iLoger, 'Equipment state history is empty!');
                myEquipmentStateHistoryHandler.result = [];
                return;
            end
            
            % Get fields names of historyTable
            historyTableFieldsNames = fieldnames(myHistoryTable);
            % Find the date field
            dateFieldIndex = strcmp(historyTableFieldsNames, 'date');
            % Get metrics fields names
            metricsFieldsNames = historyTableFieldsNames(~dateFieldIndex);
            
            for metricNumber = 1 : 1 : length(metricsFieldsNames)
                
                % Get metric data
                metricName = metricsFieldsNames{metricNumber};
                metricHistoryTable = myHistoryTable.(metricName);
                metricHistoryTable.date = myHistoryTable.date;
                metricValue = metricHistoryTable.value(1);
                
                % Calculate the state boundaries of the metric
                [metricOnBoundaries, metricIdleBoundaries, metricOffBoundaries] = ...
                    trainingPeriodProcessing(myEquipmentStateHistoryHandler, metricHistoryTable);
                
                % Detect the metric state
                if myEquipmentStateHistoryHandler.checkState(metricValue, metricOnBoundaries, 'on')
                    metricState = 'on';
                elseif myEquipmentStateHistoryHandler.checkState(metricValue, metricIdleBoundaries, 'idle')
                    metricState = 'idle';
                elseif myEquipmentStateHistoryHandler.checkState(metricValue, metricOffBoundaries, 'off')
                    metricState = 'off';
                else
                    metricState = 'unknown';
                end
                
                % Set metric data
                myHistoryTable.(metricName).status{1} = metricState;
                myHistoryTable.(metricName).onBoundaries{1} = metricOnBoundaries;
                myHistoryTable.(metricName).idleBoundaries{1} = metricIdleBoundaries;
                myHistoryTable.(metricName).offBoundaries{1} = metricOffBoundaries;
                
                if str2double(myEquipmentStateHistoryHandler.parameters.plotEnable) && ...
                        str2double(myEquipmentStateHistoryHandler.parameters.debugModeEnable)
                    
                    % Plot result images (can be processed in parallel)
                    plotStruct = myHistoryTable.(metricName);
                    plotStruct.metricName = metricName;
                    plotStruct.date = myHistoryTable.date;
                    plotAndPrint(myEquipmentStateHistoryHandler, plotStruct);
                end
            end
            
            % Detect the equipment state
            equipmentState = detectEquipmentState(myEquipmentStateHistoryHandler, myHistoryTable);
            
            % Set result data
            myEquipmentStateHistoryHandler.result.state = equipmentState;
            myEquipmentStateHistoryHandler.result.historyTable = myHistoryTable;
            
        end
        
        % TRAININGPERIODPROCESSING function
        function [onBoundaries, idleBoundaries, offBoundaries] = trainingPeriodProcessing(myEquipmentStateHistoryHandler, metricHistoryTable)
            
            % Get trainig parameters
            trainingEnable = str2double(myEquipmentStateHistoryHandler.parameters.trainingPeriod.Attributes.enable);
            trainingMode = myEquipmentStateHistoryHandler.parameters.trainingPeriod.Attributes.mode;
            trainingPeriod = str2double(myEquipmentStateHistoryHandler.parameters.trainingPeriod.Attributes.period);
            trainingLastDate = myEquipmentStateHistoryHandler.parameters.trainingPeriod.Attributes.lastDate;
            trainingStdFactor = str2double(myEquipmentStateHistoryHandler.parameters.trainingPeriod.Attributes.stdFactor);
            
            % Get metric data
            metricValues = metricHistoryTable.value;
            
            % Convert date to serial date number for comparison
            dateFormat = 'dd-mm-yyyy HH:MM:SS';
            dateSerialNumbers = datenum(metricHistoryTable.date, dateFormat);
            lastDateSerialNumber = datenum(trainingLastDate, dateFormat);
            % Check completion of training
            trainingCompleted = (dateSerialNumbers(1) - lastDateSerialNumber) >= 0;
            % The number of the files before the last date of training
            trainingDuration = nnz(dateSerialNumbers <= lastDateSerialNumber);
            
            if trainingEnable && trainingCompleted && (trainingDuration >= trainingPeriod)
                
                % The positions of the files before the last date of training
                trainingDatePositions = find(dateSerialNumbers <= lastDateSerialNumber, trainingPeriod);
                
                % Get the training values
                trainingValues = metricValues(trainingDatePositions);
                
                if length(trainingValues) < 4
                    % Training values number is not enough
                    onBoundaries = [];
                    idleBoundaries = [];
                    offBoundaries = [];
                    return;
                end
                
                if strcmp(trainingMode, 'on')
                    
                    if str2double(myEquipmentStateHistoryHandler.parameters.trainingPeriod.Attributes.trimmingEnable)
                        % Bottom trimming
                        [trainingValues] = trimData(myEquipmentStateHistoryHandler, trainingValues, 'bottom');
                    end
                    
                    % Calculate ON state boundaries
                    onBoundaries = myEquipmentStateHistoryHandler.stdBoundaries(trainingValues, trainingStdFactor);
                    onBoundaries = onBoundaries(1);
                    % Set boundaries of IDLE and OFF states
                    idleBoundaries = [];
                    offBoundaries = min(onBoundaries);
                elseif strcmp(trainingMode, 'off')
                    
                    if str2double(myEquipmentStateHistoryHandler.parameters.trainingPeriod.Attributes.trimmingEnable)
                        % Top trimming
                        [trainingValues] = trimData(myEquipmentStateHistoryHandler, trainingValues, 'top');
                    end
                    
                    % Calculate OFF state boundaries
                    offBoundaries = myEquipmentStateHistoryHandler.stdBoundaries(trainingValues, trainingStdFactor);
                    offBoundaries = offBoundaries(2);
                    % Set boundaries of ON and IDLE states
                    onBoundaries = max(offBoundaries);
                    idleBoundaries = [];
                else
                    
                    % The training mode is unknown
                    onBoundaries = [];
                    idleBoundaries = [];
                    offBoundaries = [];
                end
            else
                
                % The training is disabled
                onBoundaries = [];
                idleBoundaries = [];
                offBoundaries = [];
            end
            
        end
        
        % TRIMDATA function replaces outliers with a mean value
        function [values, outliers, outliersIndex] = trimData(myEquipmentStateHistoryHandler, values, trimmingMode)
            
            % Get training parameters
            trainingStdFactor = str2double(myEquipmentStateHistoryHandler.parameters.trainingPeriod.Attributes.stdFactor);
            
            % Calculate the metric rough range
            [roughBoundaries] = myEquipmentStateHistoryHandler.stdBoundaries(values, trainingStdFactor / 2);
            
            % Find invalid values
            switch trimmingMode
                case 'bottom'
                    invalidIndex = values < roughBoundaries(1);
                case 'top'
                    invalidIndex = values >= roughBoundaries(2);
                otherwise
                    invalidIndex = (values < roughBoundaries(1)) | (values >= roughBoundaries(2));
            end
            invalidValues = values(invalidIndex);
            validValues = values(~invalidIndex);
            
            if ~isempty(invalidValues)
                % Calculate the metric accurate range
                [accurateBoundaries] = myEquipmentStateHistoryHandler.stdBoundaries(validValues, trainingStdFactor);
                
                % Find outliers
                switch trimmingMode
                    case 'bottom'
                        outliersIndex = values < accurateBoundaries(1);
                    case 'top'
                        outliersIndex = values >= accurateBoundaries(2);
                    otherwise
                        outliersIndex = (values < accurateBoundaries(1)) | (values >= accurateBoundaries(2));
                end
                outliers = values(outliersIndex);
                allowableValues = values(~outliersIndex);
                
                % Replace the outliers
                meanValue = mean(allowableValues);
                values(outliersIndex) = meanValue;
            else
                outliersIndex = [];
                outliers = [];
            end
            
            % Plot results
            if str2double(myEquipmentStateHistoryHandler.parameters.plotEnable) && ...
                    str2double(myEquipmentStateHistoryHandler.parameters.debugModeEnable)
                
                % Get parameters
                plotVisible = myEquipmentStateHistoryHandler.parameters.plotVisible;
                sizeUnits = myEquipmentStateHistoryHandler.parameters.plots.sizeUnits;
                imageSize = str2num(myEquipmentStateHistoryHandler.parameters.plots.imageSize);
                fontSize = str2double(myEquipmentStateHistoryHandler.parameters.plots.fontSize);
                
                % Plot
                myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
                hold on;
                plot(flip(values), ...
                    'Color', [0 0 1], ...
                    'DisplayName', 'Values');
                if ~isempty(invalidValues)
                    plot(find(flip(invalidIndex)), flip(invalidValues), ...
                        'LineStyle', 'none', 'Marker', 'o', 'Color', [0 0 1], ...
                        'DisplayName', 'Invalid values');
                    plot(ones(size(values)) * roughBoundaries, ...
                        'LineStyle', ':', 'Color', [1 0 0], ...
                        'DisplayName', 'Rough boundary');
                end
                if ~isempty(outliers)
                    plot(find(flip(outliersIndex)), flip(outliers), ...
                        'LineStyle', 'none', 'Marker', 'x', 'Color', [0 0 1], ...
                        'DisplayName', 'Outliers');
                    plot(ones(size(values)) * accurateBoundaries, ...
                        'LineStyle', '--', 'Color', [1 0 0], ...
                        'DisplayName', 'Accurate boundary');
                end
                hold off;
                grid on;
                
                % Get axes data
                myAxes = myFigure.CurrentAxes;
                % Set axes font size
                myAxes.FontSize = fontSize;
                
                % Figure title
                title(myAxes, 'History equipment state detection - Data trimming', ...
                    'Interpreter', 'none');
                % Figure labels
                xlabel(myAxes, 'Counts');
                ylabel(myAxes, 'Value');
                % Display legend
                legend('show', 'Location', 'best');
                
                % Close figure with visibility off
                if strcmpi(plotVisible, 'off')
                    close(myFigure)
                end
            end
            
        end
        
        % DETECTEQUIPMENTSTATE function
        function [equipmentState] = detectEquipmentState(myEquipmentStateHistoryHandler, myHistoryTable)
            
            % Possible states
            decisionMakerStates = myEquipmentStateHistoryHandler.parameters.decisionMaker.Attributes.states;
            
            % Get fields names of historyTable
            historyTableFieldsNames = fieldnames(myHistoryTable);
            % Find the date field
            dateFieldIndex = strcmp(historyTableFieldsNames, 'date');
            % Get fields names of metrics
            metricsFieldsNames = historyTableFieldsNames(~dateFieldIndex);
            % Get states data
            states = cellfun(@(metricName) myHistoryTable.(metricName).status{1}, metricsFieldsNames, 'UniformOutput', false);
            weights = cell2num(cellfun(@(metricName) myHistoryTable.(metricName).weight(1), metricsFieldsNames, 'UniformOutput', false));
            
            % Find metrics states
            onStateIndex = strcmp(states, 'on');
            idleStateIndex = strcmp(states, 'idle');
            offStateIndex = strcmp(states, 'off');
            % Evaluate metrics states
            onStateWeight = sum(weights(onStateIndex));
            idleStateWeight = sum(weights(idleStateIndex));
            offStateWeight = sum(weights(offStateIndex));
            % Detect the equipment state
            if strfind(decisionMakerStates, 'idle')
                stateNames = {'on', 'idle', 'off'};
            else
                stateNames = {'on', 'unknown', 'off'};
            end
            stateWeights = [onStateWeight, idleStateWeight, offStateWeight];
            [maxStateWeight, maxStateIndex] = max(stateWeights);
            if maxStateWeight > 0
                equipmentState = stateNames{maxStateIndex};
            else
                equipmentState = 'unknown';
            end
            
        end
        
        % PLOTANDPRINT function
        function plotAndPrint(myEquipmentStateHistoryHandler, plotStruct)
            
            % Get parameters
            plotVisible = myEquipmentStateHistoryHandler.parameters.plotVisible;
            sizeUnits = myEquipmentStateHistoryHandler.parameters.plots.sizeUnits;
            imageSize = str2num(myEquipmentStateHistoryHandler.parameters.plots.imageSize);
            fontSize = str2double(myEquipmentStateHistoryHandler.parameters.plots.fontSize);
            
            % Plot
            myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
            hold on;
            plot(flip(plotStruct.value), ...
                'Color', [0 0 1], ...
                'DisplayName', 'Values');
            hold off;
            grid on;
            
            % Get axes data
            myAxes = myFigure.CurrentAxes;
            yLimits = ylim(myAxes);
            diffYLimits = diff(yLimits);
            % Set axes font size
            myAxes.FontSize = fontSize;
            
            % Plot the ON zone
            onBoundaries = plotStruct.onBoundaries{1};
            if ~isempty(onBoundaries)
                if length(onBoundaries) == 1
                    if onBoundaries < yLimits(2)
                        onBoundaries = [onBoundaries, yLimits(2)];
                    else
                        onBoundaries = [onBoundaries, onBoundaries + 0.1 * diffYLimits];
                        yLimits(2) = onBoundaries(2);
                    end
                end
                myEquipmentStateHistoryHandler.fillZone(myFigure, onBoundaries, ...
                    [0 1 0], 'ON zone');
            end
            % Plot the IDLE zone
            idleBoundaries = plotStruct.idleBoundaries{1};
            if ~isempty(idleBoundaries)
                myEquipmentStateHistoryHandler.fillZone(myFigure, idleBoundaries, ...
                    [1 1 0], 'IDLE zone');
            end
            % Plot the OFF zone
            offBoundaries = plotStruct.offBoundaries{1};
            if ~isempty(offBoundaries)
                if length(offBoundaries) == 1
                    if offBoundaries > yLimits(1)
                        offBoundaries = [yLimits(1), offBoundaries];
                    else
                        offBoundaries = [offBoundaries - 0.1 * diffYLimits, offBoundaries];
                        yLimits(1) = offBoundaries(1);
                    end
                end
                myEquipmentStateHistoryHandler.fillZone(myFigure, offBoundaries, ...
                    [0.5 0.5 0.5], 'OFF zone');
            end
            % Set axes limits
            ylim(myAxes, yLimits);
            
            % Figure title
            title(myAxes, ['History equipment state detection - ', upper(plotStruct.metricName)], ...
                'Interpreter', 'none');
            % Figure labels
            xlabel(myAxes, 'Actual period');
            ylabel(myAxes, 'Value');
            % Replace the x-axis values by the date
            xticks(myAxes, 1 : 1 : length(plotStruct.value));
            xticklabels(myAxes, flip(plotStruct.date));
            xtickangle(myAxes, 90);
            % Display legend
            legend('show', 'Location', 'best');
            
            % Close figure with visibility off
            if strcmpi(plotVisible, 'off')
                close(myFigure)
            end
        end
    end
    
    methods (Static)
        % STDBOUNDARIES function calculates the lower and upper
        % boundaries using the mean value and the std value, which is
        % multiplied with the std factor
        function [boundaries] = stdBoundaries(values, stdFactor)
            
            % Calculate mean and std values
            meanValue = mean(values);
            stdValue = std(values);
            
            % Calculate boundaries
            upperBoundary = meanValue + stdValue * stdFactor;
            lowerBoundary = meanValue - stdValue * stdFactor;      
            boundaries = [lowerBoundary, upperBoundary];
            
        end
        
        % CHECKSTATE function checks that the value is in the range
        % specified by the boundaries
        function [inRange] = checkState(value, boundaries, stateMode)
            
            if isempty(boundaries)
                % The state boundaries are empty
                inRange = false;
                return;
            end
            
            % Get the state boundaries
            if length(boundaries) == 2
                lowerBoundary = boundaries(1);
                upperBoundary = boundaries(2);
            else
                switch stateMode
                    case 'on'
                        % The upper boundary don't exist
                        lowerBoundary = boundaries(1);
                        upperBoundary = Inf;
                    case 'off'
                        % The lower boundary don't exist
                        lowerBoundary = -Inf;
                        upperBoundary = boundaries(1);
                    otherwise
                        % The state mode is not specified
                        lowerBoundary = boundaries(1);
                        upperBoundary = Inf;
                end
            end
            
            % Check that the value is in the range
            if (value >= lowerBoundary) && (value < upperBoundary)
                inRange = true;
            else
                inRange = false;
            end
            
        end
        
        % FILLZONE function fills the status zone specified in the
        % boundaries
        function [myArea] = fillZone(myFigure, boundaries, zoneColor, displayName)
            
            % Get axes data
            myAxes = myFigure.CurrentAxes;
            xLimits = xlim(myAxes);
            
            durations = [boundaries(1), diff(boundaries)];
            durationsMatrix = repmat(durations, length(xLimits), 1);
            
            % Fill areas
            hold on;
            myArea = area(xLimits', durationsMatrix, ...
                'ShowBaseLine', 'off', 'LineStyle', 'none', 'FaceColor', zoneColor, 'FaceAlpha', 0.15);
            if length(myArea) == 2
                % Set the first area transtparent
                myArea(1).FaceAlpha = 0;
                myArea(1).Annotation.LegendInformation.IconDisplayStyle = 'off';
            end
            hold off;
            set(myArea, 'DisplayName', displayName);
            
        end
    end
    
end

