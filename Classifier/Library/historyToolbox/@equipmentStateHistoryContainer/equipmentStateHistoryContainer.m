classdef equipmentStateHistoryContainer < historyContainer
    % EQUIPMENTSTATEHISTORYCONTAINER class
    % 
    % Developer:              P. Riabtsev
    % Development date:       09-10-2017
    % Modified by:            
    % Modification date:      
    
    properties (Access = protected)
        % The metric table to detect the equipment state
        historyTable
    end
    
    methods (Access = public)
        % METRICSHISTORYCONTAINER constructor method
        function [myEquipmentStateHistoryContainer] = equipmentStateHistoryContainer(myFiles, myXmlToStructHistory)
            
            myHistoryType = 'equipmentState';
            myEquipmentStateHistoryContainer = myEquipmentStateHistoryContainer@historyContainer(myFiles, myHistoryType, myXmlToStructHistory);
            
            myEquipmentStateHistoryContainer = createEquipmentStateHistoryTable(myEquipmentStateHistoryContainer);
            
        end
        
        % Setters/Getters ...
        function [myHistoryContainer] = setHistoryTable(myHistoryContainer, myHistoryTable)
            myHistoryContainer.historyTable = myHistoryTable;
        end
        function [myEquipmentStateHistoryTable] = getHistoryTable(myHistoryContainer)
            myEquipmentStateHistoryTable = myHistoryContainer.historyTable;
        end
        % ... Setters/Getters
    end
    
    methods (Access = protected)
        % CREATEMETRICSHISTORYTABLE function forms pattern of the
        % historyTable of the metrics from the current data (current
        % status.xml) for further filling of the metrics from history data
        function [myEquipmentStateHistoryContainer] = createEquipmentStateHistoryTable(myEquipmentStateHistoryContainer)
            
            myData.myCurrentData = getCurrentData(myEquipmentStateHistoryContainer);
            myData.myHistoryData = getHistoryData(myEquipmentStateHistoryContainer);
            
            myHistoryTable = data2Table(myEquipmentStateHistoryContainer, myData);
            myEquipmentStateHistoryContainer = setHistoryTable(myEquipmentStateHistoryContainer, myHistoryTable);
            
        end
        
        % DATA2TABLE functoin converts the metrics from the statusStruct
        % format into the table format. Function return a table with
        % metrics data
        function [myHistoryTable] = data2Table(myEquipmentStateHistoryContainer, myData)
            
            if isempty(myData.myCurrentData)
                % Current metrics data is empty
                myHistoryTable = [];
                return;
            end
            
            % Total number of files (history and current)
            filesNumber = length(myData.myHistoryData) + 1;
            
            % Get metrics names of current data
            metricsFieldsNames = fieldnames(myData.myCurrentData.informativeTags);
            for metricNumber = 1 : 1 : length(metricsFieldsNames)
                metricName = metricsFieldsNames{metricNumber};
                
                % Create an empty struct of the metric
                metricData.value = NaN(filesNumber, 1);
                metricData.weight = NaN(filesNumber, 1);
                metricData.status = cell(filesNumber, 1);
                metricData.onBoundaries = cell(filesNumber, 1);
                metricData.idleBoundaries = cell(filesNumber, 1);
                metricData.offBoundaries = cell(filesNumber, 1);
                % Get metric data from current data
                metricData.value(1, 1) = str2double(myData.myCurrentData.informativeTags.(metricName).Attributes.value);
                metricData.weight(1, 1) = str2double(myData.myCurrentData.informativeTags.(metricName).Attributes.weight);
                metricData.status{1, 1} = myData.myCurrentData.status.(metricName).Attributes.value;
                metricData.onBoundaries{1, 1} = myData.myCurrentData.informativeTags.(metricName).Attributes.onBoundaries;
                metricData.idleBoundaries{1, 1} = myData.myCurrentData.informativeTags.(metricName).Attributes.idleBoundaries;
                metricData.offBoundaries{1, 1} = myData.myCurrentData.informativeTags.(metricName).Attributes.offBoundaries;
                
                for fileNumber = 2 : 1 : filesNumber
                    if isfield(myData.myHistoryData{fileNumber - 1}.informativeTags, metricName)
                        % Get metric data from history data
                        metricData.value(fileNumber, 1) = str2double(myData.myHistoryData{fileNumber - 1}.informativeTags.(metricName).Attributes.value);
                        metricData.weight(fileNumber, 1) = str2double(myData.myHistoryData{fileNumber - 1}.informativeTags.(metricName).Attributes.weight);
                        metricData.status{fileNumber, 1} = myData.myHistoryData{fileNumber - 1}.status.(metricName).Attributes.value;
                        metricData.onBoundaries{fileNumber, 1} = myData.myHistoryData{fileNumber - 1}.informativeTags.(metricName).Attributes.onBoundaries;
                        metricData.idleBoundaries{fileNumber, 1} = myData.myHistoryData{fileNumber - 1}.informativeTags.(metricName).Attributes.idleBoundaries;
                        metricData.offBoundaries{fileNumber, 1} = myData.myHistoryData{fileNumber - 1}.informativeTags.(metricName).Attributes.offBoundaries;
                    end
                end
                
                % Set metric data to the result table
                myHistoryTable.(metricName) = metricData;
            end
            
            % Set date to the result table
            myHistoryTable.date = getDate(myEquipmentStateHistoryContainer);
            
        end
    end
    
end

