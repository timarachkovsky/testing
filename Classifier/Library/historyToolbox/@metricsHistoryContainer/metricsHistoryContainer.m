classdef metricsHistoryContainer < historyContainer
    % METRICSHISTORYCONTAINER class gets the values of the metrics from the
    % current data and history data and fills them output data table
    
    properties (Access = protected)
        historyTable    % include rms, excess, peak factor and crest factor values
    end
    
    methods (Access = public)
        % METRICSHISTORYCONTAINER constructor method
        function [myMetricsHistoryContainer] = metricsHistoryContainer(myFiles, myXmlToStructHistory)
            myHistoryType = 'metrics';
            myMetricsHistoryContainer = myMetricsHistoryContainer@historyContainer(myFiles, myHistoryType, myXmlToStructHistory);
            
            myMetricsHistoryContainer = createMetricsHistoryTable(myMetricsHistoryContainer);
        end
        
        % Getters / Setters ...
        function [myMetricsHistoryTable] = getHistoryTable(myHistoryContainer)
            myMetricsHistoryTable = myHistoryContainer.historyTable;
        end
        
        function [myHistoryContainer] = setHistoryTable(myHistoryContainer, myHistoryTable)
            myHistoryContainer.historyTable = myHistoryTable;
        end
        % ... Getters / Setters
    end
    
    methods (Access = protected)
        % CREATEMETRICSHISTORYTABLE function forms pattern of the
        % historyTable of the metrics from the current data (current
        % status.xml) for further filling of the metrics from history data
        function [myMetricsHistoryContainer] = createMetricsHistoryTable(myMetricsHistoryContainer)
            myData.myCurrentData = getCurrentData(myMetricsHistoryContainer);
            myData.myHistoryData = getHistoryData(myMetricsHistoryContainer);
            
            myHistoryTable = data2Table(myMetricsHistoryContainer, myData);
            myMetricsHistoryContainer = setHistoryTable(myMetricsHistoryContainer, myHistoryTable);
        end
        
        % DATA2TABLE functoin transforms metrics in the statusStruct format
        % to the table format. Function return the table with metrics data
        function [myHistoryTable] = data2Table(myMetricsHistoryContainer, myData)
            if isempty(myData.myCurrentData)
                % Current metrics data is empty
                myHistoryTable = [];
                return;
            end
            
            % Total number of files (history and current)
            filesNumber = length(myData.myHistoryData) + 1;
            
            % Names of spaces included in current data
            spacesNames = fieldnames(myData.myCurrentData);
            for spaceNumber = 1 : 1 : length(spacesNames)
                currentSpaceName = spacesNames{spaceNumber};
                % Names of metrics included in current data
                metricsNames = fieldnames(myData.myCurrentData.(currentSpaceName).informativeTags);
                for metricNumber = 1 : 1 : length(metricsNames)
                    currentMetricName = metricsNames{metricNumber};
                    % Create empty array of current metric
                    currentMetricData.value = NaN(filesNumber, 1);
                    currentMetricData.status = cell(filesNumber, 1);
                    % Get metric value from current data
                    currentMetricData.value(1, 1) = str2double(myData.myCurrentData.(currentSpaceName).informativeTags.(currentMetricName).Attributes.value);
                    currentMetricData.status{1, 1} = myData.myCurrentData.(currentSpaceName).informativeTags.(currentMetricName).Attributes.status;
                    currentMetricData.trainingPeriodMean{1, 1} = str2double(myData.myCurrentData.(currentSpaceName).informativeTags.(currentMetricName).Attributes.trainingPeriodMean);
                    currentMetricData.trainingPeriodStd{1, 1} = str2double(myData.myCurrentData.(currentSpaceName).informativeTags.(currentMetricName).Attributes.trainingPeriodStd);
                    for fileNumber = 2 : 1 : filesNumber
                        if isfield(myData.myHistoryData{fileNumber - 1}, currentSpaceName)
                            if isfield(myData.myHistoryData{fileNumber - 1}.(currentSpaceName).informativeTags, currentMetricName)
                                % Get metric values from history data
                                currentMetricData.value(fileNumber, 1) = str2double(myData.myHistoryData{fileNumber - 1}.(currentSpaceName).informativeTags.(currentMetricName).Attributes.value);
                                currentMetricData.status{fileNumber, 1} = myData.myHistoryData{fileNumber - 1}.(currentSpaceName).informativeTags.(currentMetricName).Attributes.status;
                                currentMetricData.trainingPeriodMean{fileNumber, 1} = str2double(myData.myHistoryData{fileNumber - 1}.(currentSpaceName).informativeTags.(currentMetricName).Attributes.trainingPeriodMean);
                                currentMetricData.trainingPeriodStd{fileNumber, 1} = str2double(myData.myHistoryData{fileNumber - 1}.(currentSpaceName).informativeTags.(currentMetricName).Attributes.trainingPeriodStd);                                
                            end
                        end
                    end
                    
                    if contains(currentMetricName, 'iso10816')
                        currentMetricData.equipmentClass = myData.myCurrentData.(currentSpaceName).informativeTags.(currentMetricName).Attributes.equipmentClass;
                    end
                    % Set current metric data to the result table
                    myHistoryTable.(currentSpaceName).(currentMetricName) = currentMetricData;
                end
            end
            
            % Set date to the result table
            myHistoryTable.date = getDate(myMetricsHistoryContainer);
        end
    end
end

