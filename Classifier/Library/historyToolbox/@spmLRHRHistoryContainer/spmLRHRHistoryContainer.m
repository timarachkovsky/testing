classdef spmLRHRHistoryContainer < historyContainer
    % SPMHISTORYCONTAINER
    % Discription: Class is designed to storage data parsed from history
    
    properties (Access = protected)
        historyTable % structure of data from history
    end
    
     methods (Access = public)
        % Constructor function
        function mySpmHistoryContainer = spmLRHRHistoryContainer(myFiles, myXmlToStructHistory)
            myHistoryType = 'spmLRHR';
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
        function [myTable] = data2Table(mySpmHistoryContainer, myData)
            % initialization
            cntFiles = length(myData.myHistoryData)+1;
            lowLevel = zeros(cntFiles,1);
            highLevel = lowLevel;
            delta = lowLevel;
            
            trainingPeriodMeanLowLevel = nan(cntFiles,1);
            trainingPeriodStdLowLevel = trainingPeriodMeanLowLevel;
            trainingPeriodMeanHighLevel = trainingPeriodMeanLowLevel;
            trainingPeriodStdHighLevel = trainingPeriodMeanLowLevel;
            trainingPeriodMeanDelta = trainingPeriodMeanLowLevel;
            trainingPeriodStdDelta = trainingPeriodMeanLowLevel;
            
            statusLowLevel = cell(cntFiles,1);
            statusHighLevel = statusLowLevel;
            statusDelta = statusLowLevel;
            
            % Obtained from the history file for each range and record it into a vector
            elementsFile = 1+length(myData.myHistoryData);
            for i = 1:1:elementsFile
                if i == 1
                    lowLevel(i,1) = str2double(myData.myCurrentData.informativeTags.hR.Attributes.value);
                    trainingPeriodMeanLowLevel(i,1) = str2double(myData.myCurrentData.informativeTags.hR.Attributes.trainingPeriodMean);
                    trainingPeriodStdLowLevel(i,1) = str2double(myData.myCurrentData.informativeTags.hR.Attributes.trainingPeriodStd);
                    statusLowLevel{i,1} = myData.myCurrentData.informativeTags.hR.Attributes.status;

                    highLevel(i,1) = str2double(myData.myCurrentData.informativeTags.lR.Attributes.value);
                    trainingPeriodMeanHighLevel(i,1) = str2double(myData.myCurrentData.informativeTags.lR.Attributes.trainingPeriodMean);
                    trainingPeriodStdHighLevel(i,1) = str2double(myData.myCurrentData.informativeTags.lR.Attributes.trainingPeriodStd);
                    statusHighLevel{i,1} = myData.myCurrentData.informativeTags.lR.Attributes.status;

                    delta(i,1) = str2double(myData.myCurrentData.informativeTags.delta.Attributes.value);
                    trainingPeriodMeanDelta(i,1) = str2double(myData.myCurrentData.informativeTags.delta.Attributes.trainingPeriodMean);
                    trainingPeriodStdDelta(i,1) = str2double(myData.myCurrentData.informativeTags.delta.Attributes.trainingPeriodStd);
                    statusDelta{i,1} = myData.myCurrentData.informativeTags.delta.Attributes.status;
                else
                    lowLevel(i,1) = str2double(myData.myHistoryData{i-1}.informativeTags.hR.Attributes.value);
                    trainingPeriodMeanLowLevel(i,1) = str2double(myData.myHistoryData{i-1}.informativeTags.hR.Attributes.trainingPeriodMean);
                    trainingPeriodStdLowLevel(i,1) = str2double(myData.myHistoryData{i-1}.informativeTags.hR.Attributes.trainingPeriodStd);
                    statusLowLevel{i,1} = myData.myHistoryData{i-1}.informativeTags.hR.Attributes.status;

                    highLevel(i,1) = str2double(myData.myHistoryData{i-1}.informativeTags.lR.Attributes.value);
                    trainingPeriodMeanHighLevel(i,1) = str2double(myData.myHistoryData{i-1}.informativeTags.lR.Attributes.trainingPeriodMean);
                    trainingPeriodStdHighLevel(i,1) = str2double(myData.myHistoryData{i-1}.informativeTags.lR.Attributes.trainingPeriodStd);
                    statusHighLevel{i,1} = myData.myHistoryData{i-1}.informativeTags.lR.Attributes.status;

                    delta(i,1) = str2double(myData.myHistoryData{i-1}.informativeTags.delta.Attributes.value);
                    trainingPeriodMeanDelta(i,1) = str2double(myData.myHistoryData{i-1}.informativeTags.delta.Attributes.trainingPeriodMean);
                    trainingPeriodStdDelta(i,1) = str2double(myData.myHistoryData{i-1}.informativeTags.delta.Attributes.trainingPeriodStd);
                    statusDelta{i,1} = myData.myHistoryData{i-1}.informativeTags.delta.Attributes.status;
                end
            end
            myTable.lowLevel = lowLevel;
            myTable.highLevel = highLevel;
            myTable.delta = delta;
            myTable.result = 0;
            myTable.date = getDate(mySpmHistoryContainer);
            myTable.trainingPeriodMeanHighLevel = trainingPeriodMeanHighLevel;
            myTable.trainingPeriodStdHighLevel = trainingPeriodStdHighLevel;
            myTable.statusHighLevel = statusHighLevel;
            myTable.trainingPeriodMeanLowLevel = trainingPeriodMeanLowLevel;
            myTable.trainingPeriodStdLowLevel = trainingPeriodStdLowLevel;
            myTable.statusLowLevel = statusLowLevel;
            myTable.trainingPeriodMeanDelta = trainingPeriodMeanDelta;
            myTable.trainingPeriodStdDelta = trainingPeriodStdDelta;
            myTable.statusDelta = statusDelta;
        end
        
    end
    
    
end

