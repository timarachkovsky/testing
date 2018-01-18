classdef timeDomainHistoryContainer < historyContainer
    % TIMEDOMAINHISTORYCONTAINER class containing data 
    %of timeDomain and prepare struct for further evaluation
    
    properties (Access = protected)
        historyTable
    end
    
    methods (Access = public)
        
        % Class constructor 
        function myTimeDomainHistoryContainer = timeDomainHistoryContainer(myFiles, myXmlToStructHistory)
            myHistoryType = 'timeDomainClassifier';
            myTimeDomainHistoryContainer = myTimeDomainHistoryContainer@historyContainer(myFiles, myHistoryType, myXmlToStructHistory);
            
            [myTimeDomainHistoryContainer] = createHistoryTable(myTimeDomainHistoryContainer);
        end
        
        function [myHistoryTable] = getHistoryTable(myFrequencyDomainHistoryContainer)
            myHistoryTable = myFrequencyDomainHistoryContainer.historyTable;
        end
        function [myFrequencyDomainHistoryContainer] = setHistoryTable(myFrequencyDomainHistoryContainer,myHistoryTable)
            myFrequencyDomainHistoryContainer.historyTable = myHistoryTable;
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
        function [myTable] = data2Table(myTimeDomainHistoryContainer, myData)
            
            cntHistoryFiles = length(myData.myHistoryData)+1;
            myTable.similarity = zeros(cntHistoryFiles,1);
            myTable.elements = cell(cntHistoryFiles,1);
            
            myTable.rawCurrentData = myData.myCurrentData;
            
            % To fill current data
            myTable.similarity(1,1) = str2double(myData.myCurrentData.status.Attributes.similarity);
            myTable.elements{1,1} = myData.myCurrentData.status.Attributes.elementType;
            
            % To fill history data
            for i = 1:1:cntHistoryFiles - 1
                myTable.similarity(i+1,1) = str2double(myData.myHistoryData{i}.status.Attributes.similarity);
                myTable.elements{i+1,1} = myData.myHistoryData{i}.status.Attributes.elementType;
            end
        end
    end
end

