classdef scalogramHistoryContainer < historyContainer
    % SCALOGRAMHISTORYCONTAINER
    % Discription: Class is designed to storage data parsed from history
    
    properties (Access = protected)
        historyTable % structure of data from history
    end
    
     methods (Access = public)
        % Constructor function
        function myScalogramHistoryContainer = scalogramHistoryContainer(myFiles, myXmlToStructHistory)
            myHistoryType = 'scalogram';
            myScalogramHistoryContainer = myScalogramHistoryContainer@historyContainer(myFiles, myHistoryType, myXmlToStructHistory);
            
            [myScalogramHistoryContainer] = createScalogramHistoryTable(myScalogramHistoryContainer);
        end
        
        function [myScalogramHistoryTable] = getHistoryTable(myHistoryContainer)
            myScalogramHistoryTable = myHistoryContainer.historyTable;
        end
        function [myHistoryContainer] = setHistoryTable(myHistoryContainer,myHistoryTable)
            myHistoryContainer.historyTable = myHistoryTable;
        end    
     end
    
    methods (Access = protected)
        % CREATEHISTORYTABLE forms pattern of the historyTable from the
        % currentData (current status.xml) for further filling with history
        % data
        function [myScalogramHistoryContainer] = createScalogramHistoryTable(myScalogramHistoryContainer)
            myData.myCurrentData = getCurrentData(myScalogramHistoryContainer);
            myData.myHistoryData = getHistoryData(myScalogramHistoryContainer);
            
            myHistoryTable = data2Table(myScalogramHistoryContainer, myData);
            
            myScalogramHistoryContainer = setHistoryTable(myScalogramHistoryContainer,myHistoryTable);
        end

        % DATA2TABLE function transforms some inputData (in the
        % statusStruct format) to the table format
        function [myTable] = data2Table(myScalogramHistoryContainer, myData)
            % Initialization
            myTable.date = getDate(myScalogramHistoryContainer);
            
            % Obtained from the history file for each range and record it into a vector
            myTable.frequencies = ... 
                str2num(myData.myCurrentData.informativeTags.frequencies.Attributes.value);
            myTable.coefficients = ... 
                str2num(myData.myCurrentData.informativeTags.coefficients.Attributes.value);
            
            numberFilters = length(myTable.coefficients);
                        
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
             
%              if ~isempty(myData.myCurrentData.informativeTags.tags.Attributes.value)
%                  myTable.tags(1,:) = ... 
%                     strsplit(myData.myCurrentData.informativeTags.tags.Attributes.value);
%              end
            
            for i = 1:1:length(myData.myHistoryData)
                myTable.frequencies(i+1,:) = ... 
                    str2num(myData.myHistoryData{i}.informativeTags.frequencies.Attributes.value);
                myTable.coefficients(i+1,:) = ... 
                    str2num(myData.myHistoryData{i}.informativeTags.coefficients.Attributes.value);
                
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
        end
    end
end
