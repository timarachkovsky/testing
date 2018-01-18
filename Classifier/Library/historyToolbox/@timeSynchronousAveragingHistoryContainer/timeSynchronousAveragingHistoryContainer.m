classdef timeSynchronousAveragingHistoryContainer < historyContainer
    % TIMESYNCHRONOUSAVERAGINGHISTORYCONTAINER
    % Discription: Class is designed to storage data parsed from history
    
    properties (Access = protected)
        historyTable % structure of data from history
    end
    
     methods (Access = public)
        % Constructor function
        function myTsaHistoryContainer = timeSynchronousAveragingHistoryContainer(myFiles, myXmlToStructHistory)
            myHistoryType = 'timeSynchronousAveraging';
            myTsaHistoryContainer = myTsaHistoryContainer@historyContainer(myFiles, myHistoryType, myXmlToStructHistory);
            
            [myTsaHistoryContainer] = createTsaHistoryTable(myTsaHistoryContainer);
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
        function [myTsaHistoryContainer] = createTsaHistoryTable(myTsaHistoryContainer)
            myData.myCurrentData = getCurrentData(myTsaHistoryContainer);
            myData.myHistoryData = getHistoryData(myTsaHistoryContainer);
            
            myHistoryTable = data2Table(myTsaHistoryContainer, myData);
            
            myTsaHistoryContainer = setHistoryTable(myTsaHistoryContainer,myHistoryTable);
        end

        % DATA2TABLE function transforms some inputData (in the
        % statusStruct format) to the table format
        function [myTable] = data2Table(myTsaHistoryContainer, myData)
            
            % Obtained from the history file for each range and record it into a vector
            myTable.currentStatus = myData.myCurrentData;
            myTable.tables = [];
            
            if ~isempty(myData.myHistoryData) && isfield(myData.myCurrentData.informativeTags, 'gearing')

                numberFiles = length(myData.myHistoryData) + 1;

                numberCurrentRanges = length(myData.myCurrentData.informativeTags.gearing);
                
                allHistory = cell(numberFiles, 1);
                allHistory{1, 1} = myData.myCurrentData;
                allHistory(2:1:numberFiles, 1) = myData.myHistoryData;

                % Find max number of ranges
                vectorRangesNumber = nan(numberFiles, 1, 'single');
                for i = 1:1:numberFiles
                    if isfield(allHistory{i}.informativeTags, 'gearing') 
                        vectorRangesNumber(i) = int16(length(allHistory{i}.informativeTags.gearing));
                    end
                end
                
                if numberCurrentRanges == 1
                    myData.myCurrentData.informativeTags.gearing = {myData.myCurrentData.informativeTags.gearing};
                end
                
                myTable.tables = myTsaHistoryContainer.createEmptyTable(numberCurrentRanges, numberFiles);
                
                % Fill table current data
                for i = 1:1:numberCurrentRanges
                    
                    myTable.tables(i).name = myData.myCurrentData.informativeTags.gearing{i}.Attributes.name;
                    myTable.tables(i).modulationsCoef(1) = single(str2double(myData.myCurrentData.informativeTags.gearing{i}.Attributes.modulationCoef));
                    myTable.tables(i).rangesStatuses(1) = logical(str2double(myData.myCurrentData.informativeTags.gearing{i}.Attributes.validGM) * ...
                                                         str2double(myData.myCurrentData.informativeTags.gearing{i}.Attributes.validShaftFreq));
                end

                allNames = {myTable.tables(:).name};
                
                % Fill tables
                for i = 2:1:numberFiles

                    if ~isnan(vectorRangesNumber(i))

                        if vectorRangesNumber(i) == 1
                            tempHistoryData = allHistory{i}.informativeTags.gearing;
                        else
                            tempHistoryData = allHistory{i}.informativeTags.gearing;
                        end
                        
                        for j = 1:1:vectorRangesNumber(i)
                            
                            posName = strcmpi(allNames, tempHistoryData{j}.Attributes.name);
                            
                            if any(posName)
                                
                                myTable.tables(posName).modulationsCoef(i) = single(str2double(tempHistoryData{j}.Attributes.modulationCoef));
                                myTable.tables(posName).rangesStatuses(i) = logical(str2double(tempHistoryData{j}.Attributes.validGM) * ...
                                                                            str2double(tempHistoryData{j}.Attributes.validShaftFreq));
                                myTable.tables(posName).statusTag{i} = tempHistoryData{j}.Attributes.statusTag;
                            end
                        end
                    end
                end
                
            end
            
            % Set date informations
            myTable.date = getDate(myTsaHistoryContainer);
        end
        
    end
   
    methods(Static)
        
        % CREATEEMPTYTABLE functino create empty table
        function resultTable = createEmptyTable(numberFields, numberFiles)
            
            resultTable(numberFields).name = [];
            resultTable(numberFields).modulationsCoef = [];
            resultTable(numberFields).rangesStatuses = [];
            resultTable(numberFields).statusHistory = [];
            resultTable(numberFields).statusTag = [];
            
            emptyTag = cell(1, numberFiles);
            emptyTag(:) = {''};
            emptyTag = {emptyTag};
            
            modulationsCoefEmp = mat2cell(nan(numberFields, numberFiles, 'single'), ones(1, numberFields), numberFiles);
            rangesStatusesEmp = mat2cell(false(numberFields, numberFiles), ones(1, numberFields), numberFiles);
            statusHistoryEmp = repmat(emptyTag, [numberFields 1]);
            
            [resultTable(1:1:numberFields).modulationsCoef] = modulationsCoefEmp{1:1:numberFields, :};
            [resultTable(1:1:numberFields).rangesStatuses] = rangesStatusesEmp{1:1:numberFields, :};
            [resultTable(1:1:numberFields).statusTag] = statusHistoryEmp{1:1:numberFields, :};
            
        end
        
    end
    
end
