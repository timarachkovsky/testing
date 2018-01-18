classdef timeFrequencyDomainHistoryContainer < historyContainer
    % TIMEFREQUNCYDOMAINHISTORYCONTAINER class containing data 
    % of timeFrequencyDomain and prepare struct for further evaluation
    
    properties (Access = protected)
        historyTable
    end
    
    methods (Access = public)
        
        % Class constructor 
        function myTimeFrequencyDomainHistoryContainer = timeFrequencyDomainHistoryContainer(myFiles, myXmlToStructHistory)
            myHistoryType = 'timeFrequencyDomainClassifier';
            myTimeFrequencyDomainHistoryContainer = myTimeFrequencyDomainHistoryContainer@historyContainer(myFiles, myHistoryType, myXmlToStructHistory);
            
            [myTimeFrequencyDomainHistoryContainer] = createHistoryTable(myTimeFrequencyDomainHistoryContainer);
        end
        
        function [myHistoryTable] = getHistoryTable(myTimeFrequencyDomainHistoryContainer)
            myHistoryTable = myTimeFrequencyDomainHistoryContainer.historyTable;
        end
        function [myTimeFrequencyDomainHistoryContainer] = setHistoryTable(myTimeFrequencyDomainHistoryContainer,myHistoryTable)
            myTimeFrequencyDomainHistoryContainer.historyTable = myHistoryTable;
        end
    end
    
    methods (Access = protected)
        % CREATEHISTORYTABLE forms pattern of the historyTable from the
        % currentData (current status.xml) for further filling with history
        % data
        function [myTimeDomainHistoryContainer] = createHistoryTable(myTimeDomainHistoryContainer)
            myData.myCurrentData = getCurrentData(myTimeDomainHistoryContainer);
            myData.myHistoryData = getHistoryData(myTimeDomainHistoryContainer);
            
            myHistoryTable = data2Table(myTimeDomainHistoryContainer, myData);
            
            myTimeDomainHistoryContainer = setHistoryTable(myTimeDomainHistoryContainer,myHistoryTable);
        end
        
        % DATA2TABLE function transforms some inputData (in the
        % statusStruct format) to the table format
        function [myTable] = data2Table(myTimeFrequencyDomainHistoryContainer, myData)
            
            % To get size of history and resonant data
            cntHistoryFiles = length(myData.myHistoryData)+1;
            
            numbersResonantData = zeros(cntHistoryFiles,1);
            numbersResonantData(1,1) = length(myData.myCurrentData.resonantFrequency);
            
            for i = 1:1:cntHistoryFiles - 1
                numbersResonantData(i+1,1) = length(myData.myHistoryData{i,1}.resonantFrequency);
            end
            
            % To create empty table
            myTable = cell(max(numbersResonantData), cntHistoryFiles);
            
            % To fill empty table through current date
            for i = 1:1:numbersResonantData(1,1)
                myTable{i, 1} = myData.myCurrentData.resonantFrequency{1,i};
            end
           
            % To fill empty table through hisotry date
            for i = 1:1:cntHistoryFiles - 1
                for j = 1:1:numbersResonantData(i+1,1)
                    myTable{j, i+1} = myData.myHistoryData{i,1}.resonantFrequency{1,j};
                end
            end
        end
    end
end

