classdef spmDBmDBcHistoryContainer < historyContainer
    % SPMHISTORYCONTAINER
    % Discription: Class is designed to storage data parsed from history
    
    properties (Access = protected)
        historyTable % structure of data from history
    end
    
     methods (Access = public)
        % Constructor function
        function mySpmHistoryContainer = spmDBmDBcHistoryContainer(myFiles, myXmlToStructHistory)
            myHistoryType = 'spmDBmDBc';
            mySpmHistoryContainer = mySpmHistoryContainer@historyContainer(myFiles, myHistoryType, myXmlToStructHistory);
            
            [mySpmHistoryContainer] = createSpmHistoryTable(mySpmHistoryContainer);
        end
        
        function [mySpmHistoryTable] = getHistoryTable(myHistoryContainer)
            mySpmHistoryTable = myHistoryContainer.historyTable;
        end
        function [myHistoryContainer] = setHistoryTable(myHistoryContainer,myHistoryTable)
            myHistoryContainer.historyTable = myHistoryTable;
        end    
        
     end
    
     methods (Access = protected)
        % CREATEHISTORYTABLE forms pattern of the historyTable from the
        % currentData (current status.xml) for further filling with history
        % data
        function [mySpmHistoryContainer] = createSpmHistoryTable(mySpmHistoryContainer)
            myData.myCurrentData = getCurrentData(mySpmHistoryContainer);
            myData.myHistoryData = getHistoryData(mySpmHistoryContainer);
            
            myHistoryTable = data2Table(mySpmHistoryContainer,myData);
            
            mySpmHistoryContainer = setHistoryTable(mySpmHistoryContainer,myHistoryTable);
        end
        
        % DATA2TABLE function transforms some inputData (in the
        % statusStruct format) to the table format
        function [myTable] = data2Table(mySpmHistoryContainer,myData)
            % initialization
            cntFiles = length(myData.myHistoryData)+1;
            lowLevel = zeros(cntFiles,1);
            highLevel = lowLevel;
            trainingPeriodMeanLowLevel = nan(cntFiles,1);
            trainingPeriodStdLowLevel = trainingPeriodMeanLowLevel;
            trainingPeriodMeanHighLevel = trainingPeriodMeanLowLevel;
            trainingPeriodStdHighLevel = trainingPeriodMeanLowLevel;
            statusLowLevel = cell(cntFiles,1);
            statusHighLevel = statusLowLevel;
            
            if cntFiles > 2
                zeroLevel = str2double(myData.myHistoryData{1,1}.informativeTags.zeroLevel.Attributes.value);
            else
                zeroLevel = str2double(myData.myCurrentData.informativeTags.zeroLevel.Attributes.value);
            end
            
            % Obtained from the history file for each range and record it into a vector
            for i = 1:1:cntFiles
                if i == 1
                    lowLevel(i,1) = str2double(myData.myCurrentData.informativeTags.dBc.Attributes.value);
                    trainingPeriodMeanLowLevel(i,1) = str2double(myData.myCurrentData.informativeTags.dBc.Attributes.trainingPeriodMean);
                    trainingPeriodStdLowLevel(i,1) = str2double(myData.myCurrentData.informativeTags.dBc.Attributes.trainingPeriodStd);
                    statusLowLevel{i,1} = myData.myCurrentData.informativeTags.dBc.Attributes.status;

                    highLevel(i,1) = str2double(myData.myCurrentData.informativeTags.dBm.Attributes.value);
                    trainingPeriodMeanHighLevel(i,1) = str2double(myData.myCurrentData.informativeTags.dBm.Attributes.trainingPeriodMean);
                    trainingPeriodStdHighLevel(i,1) = str2double(myData.myCurrentData.informativeTags.dBm.Attributes.trainingPeriodStd);
                    statusHighLevel{i,1} = myData.myCurrentData.informativeTags.dBm.Attributes.status; 
                else
                    lowLevel(i,1) = str2double(myData.myHistoryData{i-1}.informativeTags.dBc.Attributes.value);
                    trainingPeriodMeanLowLevel(i,1) = str2double(myData.myHistoryData{i-1}.informativeTags.dBc.Attributes.trainingPeriodMean);
                    trainingPeriodStdLowLevel(i,1) = str2double(myData.myHistoryData{i-1}.informativeTags.dBc.Attributes.trainingPeriodStd);
                    statusLowLevel{i,1} = myData.myHistoryData{i-1}.informativeTags.dBc.Attributes.status;

                    highLevel(i,1) = str2double(myData.myHistoryData{i-1}.informativeTags.dBm.Attributes.value);
                    trainingPeriodMeanHighLevel(i,1) = str2double(myData.myHistoryData{i-1}.informativeTags.dBm.Attributes.trainingPeriodMean);
                    trainingPeriodStdHighLevel(i,1) = str2double(myData.myHistoryData{i-1}.informativeTags.dBm.Attributes.trainingPeriodStd);
                    statusHighLevel{i,1} = myData.myHistoryData{i-1}.informativeTags.dBm.Attributes.status;  
                end
            end
            myTable.lowLevel = lowLevel;
            myTable.trainingPeriodMeanLowLevel = trainingPeriodMeanLowLevel;
            myTable.trainingPeriodStdLowLevel = trainingPeriodStdLowLevel;
            myTable.highLevel = highLevel;
            myTable.statusHighLevel = statusHighLevel;
            myTable.trainingPeriodMeanHighLevel = trainingPeriodMeanHighLevel;
            myTable.trainingPeriodStdHighLevel = trainingPeriodStdHighLevel;
            myTable.statusLowLevel = statusLowLevel;
            myTable.zeroLevel = zeroLevel;
            myTable.result = 0;
            myTable.date = getDate(mySpmHistoryContainer);
        end
        
    end
    
    
end

