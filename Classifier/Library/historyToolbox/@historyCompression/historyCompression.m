classdef historyCompression
    %HISTORYCOMPRESSION 
    % Discription: class compresses history for the required period of 
    % time to one element and validate compressed history
    
    properties (Access = private)
        config % configuration structure 
        date % time when formed each history status 
        data % information corresponding to the date 
        
        compressedHistory 
    end
    
    methods (Access = public)
        % Constructor function
        function [myHistoryCompression] = historyCompression(myData, myDate, myConfig, mode)
            if nargin < 3
                myConfig = [];
            end
            if nargin < 4
                mode = 'other';
            end
            
            myConfig = fill_struct(myConfig, 'compressionPeriodTag', 'day');
            myConfig = fill_struct(myConfig, 'compressionPeriodNumber', '1');
            myConfig = fill_struct(myConfig, 'compressionSkipPeriodNumber', '2');
            myConfig = fill_struct(myConfig, 'percentOfLostHistoryFiles', '20');
            myConfig = fill_struct(myConfig, 'compressionLogEnable', '1');
            
            myHistoryCompression.config = myConfig;
            myHistoryCompression.date = myDate;
            myHistoryCompression.data = myData;
            if ~strcmp(mode, 'threshold')
                myHistoryCompression = historyProcessing(myHistoryCompression, mode);
            else
                myHistoryCompression = historyProcessingStatus(myHistoryCompression);
            end
        end
        
        % Getters/Setters ...
        function [myCompressedHistory] = getCompressedHistory(myHistoryCompression)
            myCompressedHistory = myHistoryCompression.compressedHistory;
        end
        function [myHistoryCompression] = setCompressedHistory(myHistoryCompression,myCompressedHistory)
            myHistoryCompression.compressedHistory = myCompressedHistory;
        end
        % ...Getters/Setters
    end
    methods (Access = private) 
        % HISTORYPROCESSING function is compresses of date
        function [myHistoryCompression] = historyProcessing(myHistoryCompression, mode)
            
            periodTag = myHistoryCompression.config.compressionPeriodTag;
            percentOfLostHistoryFiles = str2double(myHistoryCompression.config.percentOfLostHistoryFiles);
            compressionPeriod = str2double(myHistoryCompression.config.compressionPeriodNumber);
            compressionPeriodSkip = str2double(myHistoryCompression.config.compressionSkipPeriodNumber);
            compressionEnable = str2double(myHistoryCompression.config.compressionEnable);
            compressionLogEnable = str2double(myHistoryCompression.config.compressionLogEnable);
            iLoger = loger.getInstance;
            
            % Convert string in format of matlab data 
            if strcmp(periodTag, 'day')  
                timeFormat = datetime(cellfun(@(x) x(1,1:10), ...
                    myHistoryCompression.date, 'UniformOutput', false), 'InputFormat', 'dd-MM-yyyy');
            elseif strcmp(periodTag, 'hour')
                timeFormat = datetime(cellfun(@(x) x(1,1:13),...
                    myHistoryCompression.date, 'UniformOutput', false), 'InputFormat', 'dd-MM-yyyy HH');
            elseif  strcmp(periodTag, 'month')
                timeFormat = datetime(cellfun(@(x) x(1,4:10),...
                    myHistoryCompression.date, 'UniformOutput', false), 'InputFormat', 'MM-yyyy');
            else
                if compressionLogEnable
                    printComputeInfo(iLoger, 'Training period', 'Incorrect input tag of history, it should be day/hour/month in filed compressionPeriodTag');
                end
                error( 'Incorrect input tag of history, it should be day/hour/month in filed compressionPeriodTag' )
            end
            timeFormat = flip(timeFormat);
            dataFormat = reshape(flip(myHistoryCompression.data), [], 1);
            
            if compressionEnable
                %Create basic element (One day/hour/month)
                if strcmp(periodTag, 'month') 
                    basicElement = calmonths(1);
                else
                    basicElement = feval([periodTag 's'],1);
                end

                % Find count compression cell
                if strcmp(periodTag, 'hour')
                    compressionCellCnt = ceil((hour( ... 
                        between(timeFormat(1), timeFormat(end), 'Time'))+1)/compressionPeriod);
                elseif strcmp(periodTag, 'day')
                    compressionCellCnt = ceil((day( ... 
                        between(timeFormat(1), timeFormat(end), 'day'))+1)/compressionPeriod);
                else
                    compressionCellCnt = ceil((calmonths( ... 
                        between(timeFormat(1), timeFormat(end), 'month'))+1)/compressionPeriod);
                end

                compressionVectorTime = (timeFormat(1):basicElement*compressionPeriod: ...
                    timeFormat(1)+(basicElement*compressionPeriod*(compressionCellCnt-1)))';
                compressionVectorData = NaN(compressionCellCnt, 1);

                % Convert "datetime" type to numeric format
                timeFormat = datenum(timeFormat);
                compressionVectorTime = datenum(compressionVectorTime);

                cntNanSuccessively = 0;
                skipVector = ones(compressionCellCnt,1);

                % Fill "compressionVectorData" variable to information 
                % compression and create skip default vector
                for i = 1:1:compressionCellCnt - 1
                    tempV = bsxfun(@times, timeFormat(:,1) >= compressionVectorTime(i), ...
                        timeFormat(:,1) < compressionVectorTime(i+1));
                    if nnz(tempV) ~= 0
                        
                        % For envHistoryHandler, if mode "threshold" is
                        % enable, find last date and get last status
%                         if length(dataFormat) ~= length(tempV)
%                         end
                        tempData = dataFormat(logical(tempV),1);
                        % If raw data history is empty
                        if nnz(isnan(tempData)) == length(tempData)  
                            tempData = mean(tempData, 'omitnan');
                        else
                            % For envHistoryHandler, there is data 0, then ignore 
                            if strcmp(mode, 'env')
                                tempData = tempData(~isnan(tempData));
                                if nnz(tempData == 0) ~= length(tempData)
                                    tempData = tempData(tempData ~= 0);
                                end
                                tempData = mean(tempData);
                            else
                                tempData = mean(tempData(~isnan(tempData)));
                            end
                        end    
                        compressionVectorData(i,1) = mean(tempData);
                        cntNanSuccessively = 0;
                    else
                        cntNanSuccessively = cntNanSuccessively + 1;
                        if cntNanSuccessively <= compressionPeriodSkip
                            skipVector(i) = 0;
                        end
                    end
                end
                compressionVectorData(end,1) = mean(dataFormat(timeFormat(:,1) >= compressionVectorTime(end)), 'omitnan');

                % Skip default time and data
                compressionVectorData = compressionVectorData(logical(skipVector),1);
                compressionVectorTime = compressionVectorTime(logical(skipVector),1);

                % If have great of lost history (percentOfLostHistoryFiles - config parameters)
                if nnz(isnan(compressionVectorData))/ ...
                        length(compressionVectorData)*100 > percentOfLostHistoryFiles

                    while nnz(isnan(compressionVectorData))/ ...
                        length(compressionVectorData)*100 > percentOfLostHistoryFiles

                        pos = find(isnan(compressionVectorData), 1);
                        compressionVectorData = compressionVectorData(pos+1:end);
                        compressionVectorTime = compressionVectorTime(pos+1:end);
                    end

                    if nnz(isnan(compressionVectorData))
                       pos = find(~isnan(compressionVectorData),1);
                       compressionVectorData = compressionVectorData(pos:end);
                       compressionVectorTime = compressionVectorTime(pos:end);
                    end
                end
                
                % History approximation 
                if nnz(isnan(compressionVectorData)) && length(compressionVectorData) > 1 
                   compressionVectorData = inpaint_nans(compressionVectorData);
                end 
                if compressionLogEnable
                    if ~strcmp(mode, 'env')
                        if length(compressionVectorData) < 3                    
                            printComputeInfo(iLoger, 'History compression', 'Warning, after compression is number of history files less 3 !!!');
                        else
                            printComputeInfo(iLoger, 'History compression', 'Successful compression.');
                        end
                    end
                end
            else
                compressionVectorData = dataFormat;
                compressionVectorTime = datenum(timeFormat);
            end
            
            % Convert "double" type of vector time to "string" type
            if strcmp(periodTag, 'day') 
                compressionVectorTime = cellstr(datestr(compressionVectorTime,'dd-mm-yyyy'));
            elseif strcmp(periodTag, 'hour')
                compressionVectorTime = cellstr(datestr(compressionVectorTime,'dd-mm-yyyy HH'));
            else % periodTag == 'month'
                compressionVectorTime = cellstr(datestr(compressionVectorTime,'mm-yyyy'));
            end
            
            myHistoryCompression.compressedHistory.date = compressionVectorTime;
            myHistoryCompression.compressedHistory.data = compressionVectorData;
        end 
        
        % HISTORYPROCESSING function is compresses of status
        function [myHistoryCompression] = historyProcessingStatus(myHistoryCompression)
            
            periodTag = myHistoryCompression.config.compressionPeriodTag;
            percentOfLostHistoryFiles = str2double(myHistoryCompression.config.percentOfLostHistoryFiles);
            compressionPeriod = str2double(myHistoryCompression.config.compressionPeriodNumber);
            compressionPeriodSkip = str2double(myHistoryCompression.config.compressionSkipPeriodNumber);
            compressionEnable = str2double(myHistoryCompression.config.compressionEnable);
            iLoger = loger.getInstance;
            
            % Convert string in format of matlab data 
            if strcmp(periodTag, 'day')  
                timeFormat = datetime(cellfun(@(x) x(1,1:10), ...
                    myHistoryCompression.date, 'UniformOutput', false), 'InputFormat', 'dd-MM-yyyy');
            elseif strcmp(periodTag, 'hour')
                timeFormat = datetime(cellfun(@(x) x(1,1:13),...
                    myHistoryCompression.date, 'UniformOutput', false), 'InputFormat', 'dd-MM-yyyy HH');
            elseif strcmp(periodTag, 'month')
                timeFormat = datetime(cellfun(@(x) x(1,4:10),...
                    myHistoryCompression.date, 'UniformOutput', false), 'InputFormat', 'MM-yyyy');
            else
                printComputeInfo(iLoger, 'Training period', 'Incorrect input tag of history, it should be day/hour/month in filed compressionPeriodTag');
                error( 'Incorrect input tag of history, it should be day/hour/month in filed compressionPeriodTag' )
            end
            timeFormat = flip(timeFormat);
            dataFormat = flip(myHistoryCompression.data);
            
            if compressionEnable
                %Create basic element (One day/hour/month)
                if strcmp(periodTag, 'month') 
                    basicElement = calmonths(1);
                else
                    basicElement = feval([periodTag 's'],1);
                end

                % Find count compression cell
                if strcmp(periodTag, 'hour')
                    compressionCellCnt = ceil((hour( ... 
                        between(timeFormat(1), timeFormat(end), 'Time'))+1)/compressionPeriod);
                elseif strcmp(periodTag, 'day')
                    compressionCellCnt = ceil((day( ... 
                        between(timeFormat(1), timeFormat(end), 'day'))+1)/compressionPeriod);
                else
                    compressionCellCnt = ceil((calmonths( ... 
                        between(timeFormat(1), timeFormat(end), 'month'))+1)/compressionPeriod);
                end

                compressionVectorTime = (timeFormat(1):basicElement*compressionPeriod: ...
                    timeFormat(1)+(basicElement*compressionPeriod*(compressionCellCnt-1)))';
                compressionVectorData = cell(compressionCellCnt, 1);
                compressionVectorData(:) = {0};
                
                % Convert "datetime" type to numeric format
                timeFormat = datenum(timeFormat);
                compressionVectorTime = datenum(compressionVectorTime);

                cntNanSuccessively = 0;
                skipVector = ones(compressionCellCnt,1);

                % Fill "compressionVectorData" variable to information 
                % compression and create skip default vector
                for i = 1:1:compressionCellCnt - 1
                    tempV = bsxfun(@times, timeFormat(:,1) >= compressionVectorTime(i), ...
                        timeFormat(:,1) < compressionVectorTime(i+1));
                    if nnz(tempV) ~= 0
                        
                        % For envHistoryHandler, if mode "threshold" is
                        % enable, find last date and get last status
                        tempData = dataFormat(logical(tempV),1);
                         
                        compressionVectorData(i,1) = tempData(end);
                        cntNanSuccessively = 0;
                    else
                        cntNanSuccessively = cntNanSuccessively + 1;
                        if cntNanSuccessively <= compressionPeriodSkip
                            skipVector(i) = 0;
                        end
                    end
                end
                compressionVectorData(end,1) = dataFormat(end);

                % Skip default time and data
                compressionVectorData = compressionVectorData(logical(skipVector),1);
                compressionVectorTime = compressionVectorTime(logical(skipVector),1);

                % If have great of lost history (percentOfLostHistoryFiles - config parameters)
                if nnz(bsxfun(@times, cellfun(@isnumeric, compressionVectorData),   ...
                        ~cellfun(@isempty, compressionVectorData)))/ ...
                        length(compressionVectorData)*100 > percentOfLostHistoryFiles

                    while nnz(bsxfun(@times, cellfun(@isnumeric, compressionVectorData), ...
                            ~cellfun(@isempty, compressionVectorData)))/ ...
                        length(compressionVectorData)*100 > percentOfLostHistoryFiles

                        pos = find(bsxfun(@times, cellfun(@isnumeric, compressionVectorData), ...
                            ~cellfun(@isempty, compressionVectorData)), 1);
                        compressionVectorData = compressionVectorData(pos+1:end);
                        compressionVectorTime = compressionVectorTime(pos+1:end);
                    end

                    if nnz(bsxfun(@times, cellfun(@isnumeric, compressionVectorData), ...
                            ~cellfun(@isempty, compressionVectorData)))
                       pos = find(~isnan(compressionVectorData),1);
                       compressionVectorData = compressionVectorData(pos:end);
                       compressionVectorTime = compressionVectorTime(pos:end);
                    end
                end

%                 if length(compressionVectorData) < 3                    
%                     printComputeInfo(iLoger, 'History compression', 'Warning, after compression is number of history files less 3 !!!');
%                 end
                
            else
                compressionVectorData = dataFormat;
                compressionVectorTime = datenum(timeFormat);
            end
            
            % Convert "double" type of vector time to "string" type
            if strcmp(periodTag, 'day') 
                compressionVectorTime = cellstr(datestr(compressionVectorTime,'dd-mm-yyyy'));
            elseif strcmp(periodTag, 'hour')
                compressionVectorTime = cellstr(datestr(compressionVectorTime,'dd-mm-yyyy HH'));
            else % periodTag == 'month'
                compressionVectorTime = cellstr(datestr(compressionVectorTime,'mm-yyyy'));
            end
            
            myHistoryCompression.compressedHistory.date = compressionVectorTime;
            myHistoryCompression.compressedHistory.data = compressionVectorData;
        end 
    end
end


