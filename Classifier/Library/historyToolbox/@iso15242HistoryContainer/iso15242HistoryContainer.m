classdef iso15242HistoryContainer < historyContainer
    % ISO15242HISTORYCONTAINER
    % Discription: Class is designed to storage data parsed from history
    
    properties (Access = protected)
        historyTable % structure of data from history
    end
    
     methods (Access = public)
        % Constructor function
        function myIso15242HistoryContainer = iso15242HistoryContainer(myFiles, myXmlToStructHistory)
            myHistoryType = 'iso15242';
            myIso15242HistoryContainer = ...
                myIso15242HistoryContainer@historyContainer(myFiles, myHistoryType, myXmlToStructHistory);
            
            [myIso15242HistoryContainer] = createIso15242HistoryTable(myIso15242HistoryContainer);
        end
        % Getters/Setters ...
        function [myIso15242HistoryContainer] = getHistoryTable(myIso15242HistoryContainer)
            myIso15242HistoryContainer = myIso15242HistoryContainer.historyTable;
        end
        function [myIso15242HistoryContainer] = setHistoryTable(myIso15242HistoryContainer,myHistoryTable)
            myIso15242HistoryContainer.historyTable = myHistoryTable;
        end    
        % ...Getters/Setters
     end
    
     methods (Access = protected)
        % CREATEHISTORYTABLE forms pattern of the historyTable from the
        % currentData (current status.xml) for further filling with history
        % data
        function [myIso15242HistoryContainer] = createIso15242HistoryTable(myIso15242HistoryContainer) 
            myData.myCurrentData = getCurrentData(myIso15242HistoryContainer);
            myData.myHistoryData = getHistoryData(myIso15242HistoryContainer);
            
            myHistoryTable = data2Table(myIso15242HistoryContainer,myData);

            myIso15242HistoryContainer = setHistoryTable(myIso15242HistoryContainer,myHistoryTable);
        end
        
        % DATA2TABLE function transforms some inputData (in the
        % statusStruct format) to the table format
        function [myTable] = data2Table(myIso15242HistoryContainer,myData)
            % initialization
            cntHistoryFiles = length(myData.myHistoryData)+1;
            vRms1Log = zeros(cntHistoryFiles,1);
            vRms2Log = vRms1Log;
            vRms3Log = vRms1Log;
            
            trainingPeriodMeanRms1 = cell(cntHistoryFiles, 1);
            trainingPeriodStdRms1 = trainingPeriodMeanRms1;
            statusRms1 = trainingPeriodMeanRms1;
            
            trainingPeriodMeanRms2 = trainingPeriodMeanRms1;
            trainingPeriodStdRms2 = trainingPeriodMeanRms1;
            statusRms2 = trainingPeriodMeanRms1;
            
            trainingPeriodMeanRms3 = trainingPeriodMeanRms1;
            trainingPeriodStdRms3 = trainingPeriodMeanRms1;
            statusRms3 = trainingPeriodMeanRms1;
            % Obtained from the history file for each range and record it into a vector
            for i = 1:1:cntHistoryFiles
                if i == 1
                    vRms1Log(i,1) = str2double(myData.myCurrentData.informativeTags.vRms1Log.Attributes.value);
                    trainingPeriodMeanRms1{i, :} = ... 
                        str2double(myData.myCurrentData.informativeTags.vRms1Log.Attributes.trainingPeriodMean);
                    trainingPeriodStdRms1{i, :} = ... 
                        str2double(myData.myCurrentData.informativeTags.vRms1Log.Attributes.trainingPeriodStd);
                    statusRms1{i,:} = myData.myCurrentData.informativeTags.vRms1Log.Attributes.status;

                    vRms2Log(i,1) = str2double(myData.myCurrentData.informativeTags.vRms2Log.Attributes.value);
                    trainingPeriodMeanRms2{i, :} = ... 
                        str2double(myData.myCurrentData.informativeTags.vRms2Log.Attributes.trainingPeriodMean);
                    trainingPeriodStdRms2{i, :} = ... 
                        str2double(myData.myCurrentData.informativeTags.vRms2Log.Attributes.trainingPeriodStd);
                    statusRms2{i,:} = myData.myCurrentData.informativeTags.vRms2Log.Attributes.status;

                    vRms3Log(i,1) = str2double(myData.myCurrentData.informativeTags.vRms3Log.Attributes.value);
                    trainingPeriodMeanRms3{i, :} = ... 
                        str2double(myData.myCurrentData.informativeTags.vRms3Log.Attributes.trainingPeriodMean);
                    trainingPeriodStdRms3{i, :} = ... 
                        str2double(myData.myCurrentData.informativeTags.vRms3Log.Attributes.trainingPeriodStd);
                    statusRms3{i,:} = myData.myCurrentData.informativeTags.vRms3Log.Attributes.status;
                else
                    vRms1Log(i,1) = str2double(myData.myHistoryData{i-1}.informativeTags.vRms1Log.Attributes.value);
                    trainingPeriodMeanRms1{i, :} = ... 
                        str2double(myData.myHistoryData{i-1}.informativeTags.vRms1Log.Attributes.trainingPeriodMean);
                    trainingPeriodStdRms1{i, :} = ... 
                        str2double(myData.myHistoryData{i-1}.informativeTags.vRms1Log.Attributes.trainingPeriodStd);
                    statusRms1{i,:} = myData.myHistoryData{i-1}.informativeTags.vRms1Log.Attributes.status;

                    vRms2Log(i,1) = str2double(myData.myHistoryData{i-1}.informativeTags.vRms2Log.Attributes.value);
                    trainingPeriodMeanRms2{i, :} = ... 
                        str2double(myData.myHistoryData{i-1}.informativeTags.vRms2Log.Attributes.trainingPeriodMean);
                    trainingPeriodStdRms2{i, :} = ... 
                        str2double(myData.myHistoryData{i-1}.informativeTags.vRms2Log.Attributes.trainingPeriodStd);
                    statusRms2{i,:} = myData.myHistoryData{i-1}.informativeTags.vRms2Log.Attributes.status;

                    vRms3Log(i,1) = str2double(myData.myHistoryData{i-1}.informativeTags.vRms3Log.Attributes.value);
                    trainingPeriodMeanRms3{i, :} = ... 
                        str2double(myData.myHistoryData{i-1}.informativeTags.vRms3Log.Attributes.trainingPeriodMean);
                    trainingPeriodStdRms3{i, :} = ... 
                        str2double(myData.myHistoryData{i-1}.informativeTags.vRms3Log.Attributes.trainingPeriodStd);
                    statusRms3{i,:} = myData.myHistoryData{i-1}.informativeTags.vRms3Log.Attributes.status;
                end
            end
            
            myTable.vRms1Log = vRms1Log;
            myTable.trainingPeriodMeanRms1 = trainingPeriodMeanRms1;
            myTable.trainingPeriodStdRms1 = trainingPeriodStdRms1;
            myTable.statusRms1 = statusRms1;
            
            myTable.vRms2Log = vRms2Log;
            myTable.trainingPeriodMeanRms2 = trainingPeriodMeanRms2;
            myTable.trainingPeriodStdRms2 = trainingPeriodStdRms2;
            myTable.statusRms2 = statusRms2;
            
            myTable.vRms3Log = vRms3Log;
            myTable.trainingPeriodMeanRms3 = trainingPeriodMeanRms3;
            myTable.trainingPeriodStdRms3 = trainingPeriodStdRms3;
            myTable.statusRms3 = statusRms3;
            
            myTable.result = 0;
            myTable.date = getDate(myIso15242HistoryContainer);
        end
        
    end
    
    
end

