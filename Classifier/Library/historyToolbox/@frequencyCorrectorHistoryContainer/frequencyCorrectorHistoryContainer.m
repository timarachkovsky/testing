classdef frequencyCorrectorHistoryContainer < historyContainer
    % FREQUENCYCORRECTORHISTORYCONTAINER class gets the values of the initial and corrected frequency of the main shaft from the
    % current data and history data and fills them output data table
    
    properties (Access = protected)
        historyTable    % include initial and estimated frequency, validity
    end
    
    methods (Access = public)
        % FREQUENCYCORRECTORHISTORYCONTAINER constructor method
        function [myFrequencyCorrectorHistoryContainer] = frequencyCorrectorHistoryContainer(myFiles, myXmlToStructHistory)
            myHistoryType = 'frequencyCorrector';
            myFrequencyCorrectorHistoryContainer = myFrequencyCorrectorHistoryContainer@historyContainer(myFiles, myHistoryType, myXmlToStructHistory);
            
            myFrequencyCorrectorHistoryContainer = createFrequencyCorrectorHistoryTable(myFrequencyCorrectorHistoryContainer);
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
        % CREATEFREQUENCYCORRECTORHISTORYTABLE function forms pattern of the
        % historyTable of the frequencyCorrector from the current data (current
        % status.xml) for further filling of the frequencyCorrector from history data
        function [myFrequencyCorrectorHistoryContainer] = createFrequencyCorrectorHistoryTable(myFrequencyCorrectorHistoryContainer)
            myData.myCurrentData = getCurrentData(myFrequencyCorrectorHistoryContainer);
            myData.myHistoryData = getHistoryData(myFrequencyCorrectorHistoryContainer);
            
            myHistoryTable = data2Table(myFrequencyCorrectorHistoryContainer, myData);
            myFrequencyCorrectorHistoryContainer = setHistoryTable(myFrequencyCorrectorHistoryContainer, myHistoryTable);
        end
        
        % DATA2TABLE functoin transforms frequencyCorrector in the statusStruct format
        % to the table format. Function return the table with frequencyCorrector data
        function [myHistoryTable] = data2Table(myFrequencyCorrectorHistoryContainer, myData)
            if isempty(myData.myCurrentData)
                % Current frequencyCorrector data is empty
                myHistoryTable = [];
                return;
            end
            
            % Total number of files (history and current)
            filesNumber = length(myData.myHistoryData) + 1;
            
            % Set date to the result table
            myHistoryTable.date = getDate(myFrequencyCorrectorHistoryContainer);
            
            % Initial
            myHistoryTable.initial = cell(filesNumber,1);
            myHistoryTable.estimated = myHistoryTable.initial;
            myHistoryTable.validity = myHistoryTable.initial;
            
            % Set current values
            myHistoryTable.initial{1,1} = str2double(myData.myCurrentData.informativeTags.initialFrequency.Attributes.value);
            myHistoryTable.estimated{1,1} = str2double(myData.myCurrentData.informativeTags.estimatedFrequency.Attributes.value);
            myHistoryTable.validity{1,1} = str2double(myData.myCurrentData.informativeTags.validity.Attributes.value);
            
            % Set history values
            for i=2:1:filesNumber
                myHistoryTable.initial{i,1} = ...
                    str2double(myData.myHistoryData{i-1}.informativeTags.initialFrequency.Attributes.value);
                myHistoryTable.estimated{i,1} = ...
                    str2double(myData.myHistoryData{i-1}.informativeTags.estimatedFrequency.Attributes.value);
                myHistoryTable.validity{i,1} = ...
                    str2double(myData.myHistoryData{i-1}.informativeTags.validity.Attributes.value);
            end
        end
    end
end

