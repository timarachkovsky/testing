% Developer:              Kosmach N.
% Development date:       19-12-2017
% Modified by:            
% Modification date:  

% Function parser hisotry history for plotting in @decisionMakerHistory
function statusesDecisionMaker = parserDecisionMakerHistory(myXmlToStructHistory, config)

    historyData = getHistoryDataRaw(myXmlToStructHistory);
    timeVector = getDate(myXmlToStructHistory);
    parameters = config.config.parameters.evaluation.history.trend.Attributes;
    
    cntData = length(historyData);
    
    historyDateDMRaw = cell(cntData, 1);
    
    statusesDecisionMaker.tableStatuses = [];
    statusesDecisionMaker.vectorDate = [];
    if ~isempty(historyData)
        
        % Get data of decision maker from history files
        numberAllDefects = 0;
        for i = 1:1:cntData
            
            if isfield(historyData{i, 1}.equipment, 'decisionMaker')
            
                historyDateDMRaw{i, 1} = historyData{i, 1}.equipment.decisionMaker;
                
                numberElement = length(historyDateDMRaw{i, 1}.element);
                
                if length(historyDateDMRaw{i, 1}.element) == 1
                    
                    historyDateDMRaw{i, 1}.element = {historyDateDMRaw{i, 1}.element};
                end
                
                for j = 1:1:numberElement
                    
                    
                    numberDefectsTemp = length(historyDateDMRaw{i}.element{1, j}.defect);
                    if numberDefectsTemp == 1
                        
                        historyDateDMRaw{i}.element{1, j}.defect = {historyDateDMRaw{i}.element{1, j}.defect};
                    end
                    
                    numberAllDefects = numberAllDefects + numberDefectsTemp;
                end
                
            end
        end
        
        % Check empty history
        statusHistoryParser = cellfun(@isempty, historyDateDMRaw);
        if any(statusHistoryParser)
            
            historyDateDMRaw = historyDateDMRaw(~statusHistoryParser);
            statusTimeVector = true(cntData + 1, 1);
            statusTimeVector(2:end) = ~statusHistoryParser;
            timeVector = timeVector(statusTimeVector);
        end
        
        if ~isempty(historyDateDMRaw)
            
            numberAllDefects = numberAllDefects / cntData;

            % Create empty table and fill name defects
            tableStatuses(numberAllDefects).name = [];
            tableStatuses(numberAllDefects).nameDefect = [];
            tableStatuses(numberAllDefects).tagName = [];
            tableStatuses(numberAllDefects).compressedStatuses = [];
            tableStatuses(numberAllDefects).statuses = [];
            
            emptyData = cell(cntData+1, 1);
            emptyData(:) = {'Nan'};
            emptyDataAllDefect = cell(numberAllDefects, 1);
            emptyDataAllDefect(:) = {emptyData};
            [tableStatuses.statuses] = emptyDataAllDefect{:};
            
            cntDefect = 1;
            for i = 1:1:length(historyDateDMRaw{1, 1}.element) 
                
                for j = 1:1:length(historyDateDMRaw{1, 1}.element{i}.defect)  
                    
                    tableStatuses(cntDefect).name = historyDateDMRaw{1, 1}.element{i}.Attributes.schemeName;
                    tableStatuses(cntDefect).nameDefect = historyDateDMRaw{1, 1}.element{i}.defect{j}.Attributes.tagName;
                    tableStatuses(cntDefect).tagName = historyDateDMRaw{1, 1}.element{i}.Attributes.tagName;
                    tableStatuses(cntDefect).statuses{2} = historyDateDMRaw{1, 1}.element{i}.defect{j}.Attributes.status;
                    cntDefect = cntDefect + 1;
                end
                
            end
            
            % Fill table with raw data
            for k = 2:1:cntData
                cntDefect = 1;
                for i = 1:1:length(historyDateDMRaw{k, 1}.element) 
                
                    for j = 1:1:length(historyDateDMRaw{k, 1}.element{i}.defect)  

                        tableStatuses(cntDefect).statuses{k+1} = historyDateDMRaw{k, 1}.element{i}.defect{j}.Attributes.status;
                        cntDefect = cntDefect + 1;
                    end
                end
            end
            
            % Create compressed data and fill table
            for i = 1:1:numberAllDefects
                
                myHistoryCompression = historyCompression(tableStatuses(i).statuses, timeVector, parameters, 'threshold');
                compression = getCompressedHistory(myHistoryCompression);    
                tableStatuses(i).compressedStatuses = compression.data;
            end
            
            tableStatuses = rmfield(tableStatuses, 'statuses');
            
            statusesDecisionMaker.tableStatuses = tableStatuses;
            statusesDecisionMaker.vectorDate = compression.date;
            
        end
    end
    
end

