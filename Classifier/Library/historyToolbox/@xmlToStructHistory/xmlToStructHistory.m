classdef xmlToStructHistory
% XMLTOSTRUCTHISOTRY class ?onverts xml to struct and create time vector
    
    properties (Access = protected)
        files % config parameters
        parameters
        
        currentDataRaw 
        historyDataRaw
        
        date % vector of date
    end
     
    methods (Access = public)
        
        % Constructor class
        function [myXmlToStructHistory] = xmlToStructHistory(myFiles, config)
            
            myXmlToStructHistory.files = myFiles;
            myXmlToStructHistory.parameters.nameStatusFile = ...
                config.config.parameters.evaluation.statusWriter.Attributes.nameTempStatusFile;
            myXmlToStructHistory.parameters.logEnable = 1;
            
            % Create structures of the current data (from @status.xml) and
            % of the history file (for current device)
            myXmlToStructHistory = findHistoryDataRaw(myXmlToStructHistory);
            myXmlToStructHistory = findCurrentDataRaw(myXmlToStructHistory);
            
            % Create date vector
            myXmlToStructHistory = createDate(myXmlToStructHistory);
            
            % Check version and id of statuses (*.xml)
            myXmlToStructHistory = checkStatuses(myXmlToStructHistory);
        end
        
        % Getters/Setters
        function [myFiles] = getFiles(myXmlToStructHistory)
            myFiles = myXmlToStructHistory.files;
        end
        function [myXmlToStructHistory] = setFiles(myXmlToStructHistory, myFiles)
            myXmlToStructHistory.files = myFiles;
        end
        
        function [myCurrentDataRaw] = getCurrentDataRaw(myXmlToStructHistory)
            myCurrentDataRaw = myXmlToStructHistory.currentDataRaw;
        end
        function [myXmlToStructHistory] = setCurrentDataRaw(myXmlToStructHistory, myCurrentDataRaw)
            myXmlToStructHistory.currentDataRaw = myCurrentDataRaw;
        end
        
        function [myHistoryDataRaw] = getHistoryDataRaw(myXmlToStructHistory)
            myHistoryDataRaw = myXmlToStructHistory.historyDataRaw;
        end
        function [myXmlToStructHistory] = setHistoryDataRaw(myXmlToStructHistory, myHistoryDataRaw)
            myXmlToStructHistory.historyDataRaw = myHistoryDataRaw;
        end
        
        function [myDate] = getDate(myXmlToStructHistory)
            myDate = myXmlToStructHistory.date;
        end
        function [myXmlToStructHistory] = setDate(myXmlToStructHistory, myDate)
            myXmlToStructHistory.date = myDate;
        end
        
        function [myParameters] = getParameters(myXmlToStructHistory)
            myParameters = myXmlToStructHistory.parameters;
        end
        function [myXmlToStructHistory] = setParameters(myXmlToStructHistory, myParameters)
            myXmlToStructHistory.parameters = myParameters;
        end
    end
    
    methods (Access = protected)
        
        % FINDHISTORYDATARAW function find history data to folder and write
        % xml to structure.
        function [myXmlToStructHistory] = findHistoryDataRaw(myXmlToStructHistory)
            
            myFiles = getFiles(myXmlToStructHistory); % configuration structure
            dirHistory = fullfile(pwd,'In','historyFiles'); % @In directory path where all history files are stored
            iLoger = loger.getInstance;
            
			existFolder = exist(dirHistory, 'dir');
            if existFolder
				printComputeInfo(iLoger, 'xmlToStructHistory', 'There is historyFiles folder');
            else
                myXmlToStructHistory = setHistoryDataRaw(myXmlToStructHistory,[]);
				printComputeInfo(iLoger, 'xmlToStructHistory', 'There is not historyFiles folder');
                return
            end 
            
            historyFilesNumber = str2double(myFiles.files.history.Attributes.historyFilesNumber);
            historyFilesList = cell(historyFilesNumber,1);
            
            % To read files.xml and get information of history files
            if historyFilesNumber >= 1
                historyFilesOrder = myFiles.files.history.Attributes.order;
                % DESC in history means older files is the bigger index number
                if strcmp(historyFilesOrder, 'DESC')
                    if historyFilesNumber == 1
                        historyFilesList{1,1} = myFiles.files.history.file;
                    else
                        historyFilesList = myFiles.files.history.file';
                    end
                else
                    historyFilesList = flip(myFiles.files.history.file');
                end
            else
                historyFilesList = [];
            end
            
            if historyFilesNumber < 3 && existFolder
                printComputeInfo(iLoger, 'xmlToStructHistory', 'Is not enough number files in historyFiles folder');
            end
            
            if ~nnz(historyFilesNumber)
                myXmlToStructHistory = setHistoryDataRaw(myXmlToStructHistory,[]);
                return
            end
  
            dirData = dir(dirHistory);      %# Get the data for the current directory
            dirIndex = [dirData.isdir];             %# Find the index for directories
            fileList = {dirData(~dirIndex).name}';  %# Get a list of the files
            
            if strcmp(historyFilesOrder, 'DESC')
                sortVectorFolder =  sort(cellfun(@(x) str2double(x), ...
                    cellfun(@(x) x{1}, regexp(fileList,'\d*','match'), 'UniformOutput', false)), 'ascend');
            else
                sortVectorFolder =  sort(cellfun(@(x) str2double(x), ...
                    cellfun(@(x) x{1}, regexp(fileList,'\d*','match'), 'UniformOutput', false)), 'descend');
            end
            fileList = cellfun(@(x) [x '.xml'], ...
                arrayfun(@num2str, sortVectorFolder, 'unif', 0), 'UniformOutput', false);
            
            % Cheked on coincidence in folder "historyFiles" and files.xml
            % data
            dataFiles = cellfun(@(x) str2double(x), ...
                arrayfun(@(x) historyFilesList{x}.Attributes.name, (1:length(historyFilesList)), 'UniformOutput', false))';
            if nnz(ismember(sortVectorFolder, dataFiles)) ~= length(historyFilesList) && existFolder
                printComputeInfo(iLoger, 'xmlToStructHistory', 'Is not match data in historyFiles folder and files.xml');
                myXmlToStructHistory = setHistoryDataRaw(myXmlToStructHistory,[]);
                
                return
			else
				printComputeInfo(iLoger, 'xmlToStructHistory', 'Is match data in historyFiles folder and files.xml');
            end
            
            if ~isempty(fileList)
                %# Prepend path to files
                fileList = cellfun(@(x) fullfile(dirHistory,x),fileList,'UniformOutput',false);
				myHistoryDataRaw = cell(historyFilesNumber,1);
                k=0;
                for i=1:1:numel(fileList)
                    [~, name, ext] = fileparts(fileList{i,1});
                    if strcmp(ext, '.xml') % Cut file type 
                        for j=1:1:historyFilesNumber
                            if strcmp(name, historyFilesList{j,1}.Attributes.name)
                                % Parse status files
                                k=k+1;
                                myHistoryDataRaw{k,1} = (xml2struct(fileList{i,1}));
                                break
                            end
                        end
                    end
                end
            else 
                myXmlToStructHistory = setHistoryDataRaw(myXmlToStructHistory,[]);
                return
            end
            
            myXmlToStructHistory = setHistoryDataRaw(myXmlToStructHistory,myHistoryDataRaw);
        end
        
        % FINDCURRENTDATA function forms structure of the current status 
        % file
        function [myXmlToStructHistory] = findCurrentDataRaw(myXmlToStructHistory)
            
            iLoger = loger.getInstance;
            filename = [myXmlToStructHistory.parameters.nameStatusFile '.xml'];
            currentFile = fullfile(pwd, 'Out', filename);
            if exist(currentFile,'file') == 2
                myCurrentDataRaw = (xml2struct(currentFile));

                myXmlToStructHistory = setCurrentDataRaw(myXmlToStructHistory,myCurrentDataRaw);
                printComputeInfo(iLoger, 'xmlToStructHistory', 'file @status.xml succesfully readed');
            else
                myXmlToStructHistory = setCurrentDataRaw(myXmlToStructHistory,[]);
                printComputeInfo(iLoger, 'xmlToStructHistory', 'There no file @status.xml in the @Out directory!');
            end
        end
        
        % CREATEDATE function create vector of date of hisotry
        function [myXmlToStructHistory] = createDate(myXmlToStructHistory)
            
            iLoger = loger.getInstance;
            
            myFiles = getFiles(myXmlToStructHistory);
            
            numberHisotryFiles = str2double(myFiles.files.history.Attributes.historyFilesNumber);
            numberFiles = numberHisotryFiles + 1;
            
            % Write current files
            listHistoryDate = cell(numberFiles, 1);
            listHistoryDate{1,1} = myFiles.files.file.Attributes.date;
            
            % Write history files
            if numberHisotryFiles ~= 0
                if strcmp(myFiles.files.history.Attributes.order, 'DESC')
                    if ~isempty(myXmlToStructHistory.historyDataRaw)
                        if length(myFiles.files.history.file) ~= 1
                        
                            listHistoryDate(2:numberFiles) = arrayfun(@(x) ...
                                myFiles.files.history.file{1, x}.Attributes.date, ...
                                (1:numberFiles - 1), 'UniformOutput', false)';
                        else
                            listHistoryDate(2) = {myFiles.files.history.file.Attributes.date};
                        end
                    else
                        listHistoryDate = listHistoryDate(1,1);
                    end
                    
                else 
                    if ~isempty(myXmlToStructHistory.historyDataRaw)
                        if length(myFiles.files.history.file) ~= 1
                            listHistoryDate(2:numberFiles) = flip(arrayfun(@(x) ...
                                myFiles.files.history.file{1, x}.Attributes.date, ...
                                (1:numberFiles - 1), 'UniformOutput', false)');
                        else
                            listHistoryDate(2) = {myFiles.files.history.file.Attributes.date};
                        end
                    else
                        listHistoryDate = listHistoryDate(1,1);
                    end
                end
            end
            
            periodTag = myFiles.files.history.Attributes.compressionPeriodTag;
            
            statusTime = cellfun(@myXmlToStructHistory.checkDate, listHistoryDate);
            
            if nnz(statusTime) ~= length(statusTime)
                printComputeInfo(iLoger, 'XmlToStructHistory','Incorrect date format in files.xml');
                error('Incorrect date format in files.xml')
            end
            
            % Convert string in format of matlab data 
            if strcmp(periodTag, 'day')  
                timeFormat = datetime(cellfun(@(x) x(1,1:10), ...
                    listHistoryDate, 'UniformOutput', false), 'InputFormat', 'dd-MM-yyyy');
            elseif strcmp(periodTag, 'hour')
                timeFormat = datetime(cellfun(@(x) x(1,1:13),...
                    listHistoryDate, 'UniformOutput', false), 'InputFormat', 'dd-MM-yyyy HH');
            elseif  strcmp(periodTag, 'month')
                timeFormat = datetime(cellfun(@(x) x(1,4:10),...
                    listHistoryDate, 'UniformOutput', false), 'InputFormat', 'MM-yyyy');
            else
                printComputeInfo(iLoger, 'XmlToStructHistory', 'Incorrect input tag of history, it should be day/hour/month in filed compressionPeriodTag');
                error( 'Incorrect input tag of history, it should be day/hour/month in filed compressionPeriodTag' )
            end
            timeFormat = flip(timeFormat);

            % Convert "datetime" type to numeric format
            timeFormat = datenum(timeFormat);
            
            if nnz(diff(timeFormat) < 0)
                printComputeInfo(iLoger, 'XmlToStructHistory','File.xml have NOT correct order of date');
            end
            
            myXmlToStructHistory = setDate(myXmlToStructHistory, listHistoryDate);
        end
        
        % CHECKSTATUSES function check version of status.xml and id
        % equipmentProfile
        function [myXmlToStructHistory] = checkStatuses(myXmlToStructHistory)
            
            currentId = myXmlToStructHistory.currentDataRaw.equipment.Attributes.idEquipmentProfile;
            iLoger = loger.getInstance;
            
            if isempty(myXmlToStructHistory.historyDataRaw)
                
                if isempty(currentId)
                    printWarning(iLoger, 'Id equipment profil is empty in status.xml');
                end
                
                return
            end
            
            % Set current data
            currentVersion = myXmlToStructHistory.currentDataRaw.equipment.Attributes.version;
            
            % Check each previous statuses
            numberHisotyFiles = length(myXmlToStructHistory.historyDataRaw);
            
            statusVersion = false(numberHisotyFiles, 1); % 0 - no match, 1 - ok
            statusId = zeros(numberHisotyFiles, 1, 'single'); % nan - not specified, 0 - no match, 1 - ok
            
            if ~isempty(currentId)
                for i = 1:1:numberHisotyFiles

                    % Check config
                    if strcmpi(currentVersion, myXmlToStructHistory.historyDataRaw{i, 1}.equipment.Attributes.version)
                        statusVersion(i, 1) = true(1); 
                    end

                    % Check id
                    if isempty(myXmlToStructHistory.historyDataRaw{i, 1}.equipment.Attributes.idEquipmentProfile)

                        statusId(i, 1) = nan(1, 'single');
                    elseif strcmpi(currentId, myXmlToStructHistory.historyDataRaw{i, 1}.equipment.Attributes.idEquipmentProfile)
                        statusId(i, 1) = 1;
                    end
                end
                
                % Push id information to log
                emptyId = isnan(statusId);
                if any(emptyId)

                    filesNumberEmptyId = find(emptyId);
                    printWarning(iLoger, ['There are empty id equipment profile of statuses in In/historyFiles/ [' ...
                                           vector2strStandardFormat(filesNumberEmptyId') '].xml']);
                end

                notRightId = statusId == 0;
                if any(notRightId)

                    filesNumberNotRightId = find(notRightId);
                    error(['There are not match id equipment profile of statuses in In/historyFiles/ [' ...
                                           vector2strStandardFormat(filesNumberNotRightId') '].xml']);
                end
            
                % Push ok status
                if all(statusVersion) && all(statusId == 1)

                    printComputeInfo(iLoger, 'xmlToStructHistory', 'Version and id eupmentProfile was check successfully.')
                    return
                end
                
            else
                
                for i = 1:1:numberHisotyFiles

                    % Check config
                    if strcmpi(currentVersion, myXmlToStructHistory.historyDataRaw{i, 1}.equipment.Attributes.version)
                        statusVersion(i, 1) = true(1); 
                    end
                end
                
                printWarning(iLoger, 'Id equipment profil is empty in status.xml');
                                   
                % Push ok status
                if all(statusVersion)

                    printComputeInfo(iLoger, 'xmlToStructHistory', 'Version was check successfully.')
                    return
                end
            end
            
            % Push config information to log 
            notRightVersion = ~statusVersion;
            if any(notRightVersion)
                
                filesNumberNotRightVersion = find(notRightVersion);
                printWarning(iLoger, ['There are not match version of statuses in In/historyFiles/ [' ...
                                       vector2strStandardFormat(filesNumberNotRightVersion') '].xml']);
            end 
            
        end
    end
    
    methods(Static)
        
        % CHECKDATE function check if input date is 'DD-MM-YYYY hh:mm:ss' format
        function status = checkDate(strInput)
            
            if (length(strInput)~=19)
                status = false;
                return;
            end
            
            yearstr = strInput(7:10);
            year = str2double(yearstr);
            
            if (year<1 || isnan(year)==1)
                status = false;
                return;
            end
            
            monthstr = strInput(4:5);
            month = str2double(monthstr);
            if (isempty(month)==1 || isnan(month)==1)
               status = false;
               return;
            elseif (month<1||month>12)
                  status = false;
                  return;
            end  
            
            if (strInput(3)~='-'||strInput(6)~='-')
                status = false;
                return;
            end
            
            daystr = strInput(1:2);
            day = str2double(daystr);
            if (isempty(day)==1 || isnan(day)==1)
                status=false;
                return;
            end
            
            if (month==1||month==3||month==5||month==7||month==8||month==10||month==12)
                if (day<1||day>31)
                    status = false;
                    return;
                end
            end
            
            if (month==4||month==6||month==9||month==11)
                if (day<1||day>30)
                    status = false;
                    return;
                end
            end

            if (rem(year,400)==0)
                if (month==2)
                    if (day<1||day>29)
                        status = false;
                        return;
                    end
                end
            elseif (rem(year,100)==0)
                if (month==2)
                    if (day<1||day>28)
                        status = false;
                        return;
                    end
                end
            elseif (rem(year,4)==0)
                if (month==2)
                    if (day<1||day>29)
                        status = false;
                        return;
                    end
                end
            else
                if (month==2)
                    if (day<1||day>28)
                        status = false;
                        return;
                    end
                end
            end
            
            if isempty(strfind(strInput(11),' '))
                status = false;
                return;
            end
            
            hour = str2double(strInput(12:13));
            if (isnan(hour) || hour < 0 || hour > 23)
                status = false;
                return;
            end
            
            statusMinSec = regexp(strInput(14:19),':[0-5]\d:[0-5]\d', 'once');
            if isempty(statusMinSec)
                status = false;
                return;
            end
            
            status = true;
        end
    end  
end

