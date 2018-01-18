classdef octaveSpectrumHistoryContainer < historyContainer
    % OCTAVESPECTRUMHISTORYCONTAINER
    % Discription: Class is designed to storage data parsed from history
    
    properties (Access = protected)
        historyTable % structure of data from history
    end
    
     methods (Access = public)
        % Constructor function
        function myOctaveSpectrumHistoryContainer = octaveSpectrumHistoryContainer(myFiles, myXmlToStructHistory)
            myHistoryType = 'octaveSpectrum';
            myOctaveSpectrumHistoryContainer = myOctaveSpectrumHistoryContainer@historyContainer(myFiles, myHistoryType, myXmlToStructHistory);
            
            [myOctaveSpectrumHistoryContainer] = createOctaveSpectrumHistoryTable(myOctaveSpectrumHistoryContainer);
        end
        
        function [myOctaveSpectrumHistoryTable] = getHistoryTable(myHistoryContainer)
            myOctaveSpectrumHistoryTable = myHistoryContainer.historyTable;
        end
        function [myHistoryContainer] = setHistoryTable(myHistoryContainer,myHistoryTable)
            myHistoryContainer.historyTable = myHistoryTable;
        end    
        
     end
    
    methods (Access = protected)
        % CREATEHISTORYTABLE forms pattern of the historyTable from the
        % currentData (current status.xml) for further filling with history
        % data
        function [myOctaveSpectrumHistoryContainer] = createOctaveSpectrumHistoryTable(myOctaveSpectrumHistoryContainer)
            myData.myCurrentData = getCurrentData(myOctaveSpectrumHistoryContainer);
            myData.myHistoryData = getHistoryData(myOctaveSpectrumHistoryContainer);
            
            myHistoryTable = data2Table(myOctaveSpectrumHistoryContainer, myData);
            
            myOctaveSpectrumHistoryContainer = setHistoryTable(myOctaveSpectrumHistoryContainer,myHistoryTable);
        end

        % DATA2TABLE function transforms some inputData (in the
        % statusStruct format) to the table format
        function [myTable] = data2Table(myOctaveSpectrumHistoryContainer, myData)
            
            % Obtained from the history file for each range and record it into a vector
            myTable.frequencies = ... 
                str2num(myData.myCurrentData.informativeTags.frequencies.Attributes.value);
            myTable.magnitudes = ... 
                str2num(myData.myCurrentData.informativeTags.magnitudes.Attributes.value);
            
            numberFilters = length(myTable.magnitudes);
                        
            myTable.trainingPeriodMean = cell(length(myData.myHistoryData)+1, numberFilters);
            myTable.trainingPeriodStd = myTable.trainingPeriodMean;
            myTable.tags = myTable.trainingPeriodMean;
            
             if ~isempty(str2num(myData.myCurrentData.informativeTags.trainingPeriodMean.Attributes.value)) && ...
                        ~isempty(str2num(myData.myCurrentData.informativeTags.trainingPeriodStd.Attributes.value))
                myTable.trainingPeriodMean{1, :} = ... 
                    str2num(myData.myCurrentData.informativeTags.trainingPeriodMean.Attributes.value);
                myTable.trainingPeriodStd{1, :} = ... 
                    str2num(myData.myCurrentData.informativeTags.trainingPeriodStd.Attributes.value);
             end
            
            for i = 1:1:length(myData.myHistoryData)
                myTable.frequencies(i+1,:) = ... 
                    str2num(myData.myHistoryData{i}.informativeTags.frequencies.Attributes.value);
                myTable.magnitudes(i+1,:) = ... 
                    str2num(myData.myHistoryData{i}.informativeTags.magnitudes.Attributes.value);
                
                myTable.tags(i+1,:) = ... 
                    strsplit(myData.myHistoryData{i}.informativeTags.tags.Attributes.value, ',');
                                
                if ~isempty(str2num(myData.myHistoryData{i}.informativeTags.trainingPeriodMean.Attributes.value)) && ...
                        ~isempty(str2num(myData.myHistoryData{i}.informativeTags.trainingPeriodStd.Attributes.value))
                    myTable.trainingPeriodMean(i+1,:) = ... 
                        num2cell(str2num(myData.myHistoryData{i}.informativeTags.trainingPeriodMean.Attributes.value));
                    myTable.trainingPeriodStd(i+1,:) = ... 
                        num2cell(str2num(myData.myHistoryData{i}.informativeTags.trainingPeriodStd.Attributes.value));
                end
            end
            
            % Set date informations
            myTable.date = getDate(myOctaveSpectrumHistoryContainer);
        end
    end
end
