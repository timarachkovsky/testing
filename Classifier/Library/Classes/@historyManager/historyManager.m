classdef historyManager < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        config % struct containing parameters
        deviceID % device ID to look history for
        
        deviceHistory % device history 
        isHistoryValid % if history for current device exist isHistoryValid=1
        
        fullHistory % contains history for certain time period
        lastHistory % contains last (3-5) history files
    end
    
    methods (Access = public)
        %  ------------ Constructor function -------------------

        function myHistoryManager = historyManager(myDeviceID, myConfig)
            myHistoryManager.deviceID = myDeviceID;
            myHistoryManager.config = myConfig;
            % get device history files from server
            [myHistoryManager.isHistoryValid, myHistoryManager.deviceHistory] = sendHistoryRequest(myHistoryManager);
            if (myHistoryManager.isHistoryValid)
                myHistoryManager.fullHistory = createFullHistory(myHistoryManager);
                myHistoryManager.lastHistory = createLastHistory(myHistoryManager);
            else
                myHistoryManager.fullHistory = [];
                myHistoryManager.lastHistory = [];
            end
        end
        
        % -----------  getter/setter functions ----------
        function myDeviceHistory = getDeviceHistory(myHistoryManager)
            myDeviceHistory = myHistoryManager.deviceHistory;
        end
        function myDeviceID = getDeviceID(myHistoryManager)
            myDeviceID = myHistoryManager.deviceID;
        end
        
        function setDeviceHistory(myHistoryManager,newDeviceHistory )
            myHistoryManager.deviceHistory = newDeviceHistory;
        end
        function setDeviceID(myHistoryManager,newDeviceID )
            myHistoryManager.deviceID = newDeviceID;
        end
        function setIsHistoryValid(myHistoryManager,isValid)
            myHistoryManager.isHistoryValid = isValid;
        end
        
        % initialization function to reinit 
        function myHistoryManager = initWithParameters(myHistoryManager,newDeviceID, myConfig )

            myHistoryManager.deviceID = newDeviceID;
            myHistoryManager.config = myConfig;
            [myHistoryManager.isHistoryValid, myHistoryManager.deviceHistory] = sendHistoryRequest(myHistoryManager,newDeviceID);
            if (myHistoryManager.isHistoryValid)
                myHistoryManager.fullHistory = createFullHistory(myHistoryManager);
                myHistoryManager.lastHistory = createLastHistory(myHistoryManager);
            else
                myHistoryManager.fullHistory = [];
                myHistoryManager.lastHistory = [];
            end
        end
        
        % getter fuction to check hostoryManager state
        function isMyHistoryValid = isHistoryManagerValid(myHistoryManager)
            isMyHistoryValid = myHistoryManager.isHistoryValid;
        end
        
        % function to get full history for certain element of the scheme
        function myElementFullHistory = getElementFullHistory(myHistoryManager,elementName)
            if isfield(myHistoryManager.fullHistory,'elements')
                myFullHistory = myHistoryManager.fullHistory.elements;
                if isfield(myFullHistory,elementName)
                    myElementFullHistory = getfield(myFullHistory, elementName);
                else
                    myElementFullHistory = [];
                end
            else
                myElementFullHistory = [];
            end
        end
        
        % function to get last history for certain element of the scheme
        function myElementLastHistory = getElementLastHistory(myHistoryManager,elementName)
            if isfield(myHistoryManager.lastHistory,'elements')
                myLastHistory = myHistoryManager.lastHistory.elements;
                if isfield(myLastHistory,elementName)
                    myElementLastHistory = getfield(myLastHistory, elementName);
                else
                    myElementLastHistory = [];
                end
            else
                myElementLastHistory = [];
            end
        end
        
        function filePath = getLastHistoryFilePath(myHistoryManager, myDeviceID)
            if ~ischar(myDeviceID)
                myDeviceID = num2str(myDeviceID);
            end
            filePath = [];
            config = myHistoryManager.config.config; % configuration structure
            deviceCount = numel(config.history.device);
            deviceIndex = [];
            for i=1:1:deviceCount % get device index in config ctructure
               if  strcmp(config.history.device{1,i}.Attributes.id, myDeviceID)
                   deviceIndex = i;
                   break;
               end
            end
            fileName = [];
            if(~isempty(deviceIndex))
                historyFilesCount = numel(config.history.device{1,deviceIndex}.file); % get history files count for current deviceID
                if historyFilesCount == 1
                    fileName = config.history.device{1,deviceIndex}.file.Attributes.name;
                else
                    fileName = config.history.device{1,deviceIndex}.file{1,historyFilesCount}.Attributes.name;
                end
            end
            
            if(~isempty(fileName))
                filePath = fullfile(pwd,'In',[fileName,'.xml']);
            end
        end
        
        function deviceCount = getDeviceCount(myHistoryManager,config)
            deviceCount = numel(config.config.history.device);
        end    
            
    end

    methods (Access = private)
        
        function myHistory = createHistory(myHistoryManager,someHistoryStruct)
            someHistoryFiles = someHistoryStruct.history;
            filesNumber = numel(someHistoryFiles);
            elementsNumber = numel(someHistoryFiles{1,1}.equipment.elements.element);
            myHistory = struct('elements',[]);
            for i= 1:1:elementsNumber
                name = someHistoryFiles{1,1}.equipment.elements.element{1,i}.Attributes.name;
                %Get base element frequency to recalculate early obtained
                %freqs to current elements baseFreq value
                baseFreq = str2double(someHistoryFiles{1,1}.equipment.elements.element{1,i}.Attributes.baseFreq);
                myHistory.elements = setfield(myHistory.elements,name,[]);
                defectNumber = numel(someHistoryFiles{1,1}.equipment.elements.element{1,i}.defect);
                
                for j=1:1:defectNumber
%                     defectID = ['id_',someHistoryFiles{1,1}.equipment.elements.element{1,i}.defect{1,j}.Attributes.ID];
                    defectID = ['id_',someHistoryFiles{1,1}.equipment.elements.element{1,i}.defect{1,j}.Attributes.tag_name];
                    myHistory.elements.(name) = setfield(myHistory.elements.(name),defectID,[]);
                    main_mag{1,1} =  someHistoryFiles{1,1}.equipment.elements.element{1,i}.defect{1,j}.freq_main.Attributes.magnitude;
                    main_freq{1,1} =  num2str(str2num(someHistoryFiles{1,1}.equipment.elements.element{1,i}.defect{1,j}.freq_main.Attributes.frequency)/baseFreq);
                    second_mag{1,1} = someHistoryFiles{1,1}.equipment.elements.element{1,i}.defect{1,j}.freq_secondary.Attributes.magnitude;
                    second_freq{1,1} = num2str(str2num(someHistoryFiles{1,1}.equipment.elements.element{1,i}.defect{1,j}.freq_secondary.Attributes.frequency)/baseFreq);
                    
                    myHistory.elements.(name).(defectID).main.magnitude = main_mag{1,1};
                    myHistory.elements.(name).(defectID).main.frequency = main_freq{1,1};
                    myHistory.elements.(name).(defectID).secondary.magnitude = second_mag{1,1};
                    myHistory.elements.(name).(defectID).secondary.frequency = second_freq{1,1};
                end
            end
            
            for i=2:1:filesNumber
                elementsNumber = numel(someHistoryFiles{i,1}.equipment.elements.element);
                for j=1:1:elementsNumber
                    baseFreq = str2double(someHistoryFiles{i,1}.equipment.elements.element{1,j}.Attributes.baseFreq);
                    defectNumber = numel(someHistoryFiles{i,1}.equipment.elements.element{1,j}.defect);
                    for k=1:1:defectNumber
                        name = someHistoryFiles{i,1}.equipment.elements.element{1,j}.Attributes.name;
%                         defectID = ['id_',someHistoryFiles{i,1}.equipment.elements.element{1,j}.defect{1,k}.Attributes.ID];
                        defectID = ['id_',someHistoryFiles{i,1}.equipment.elements.element{1,j}.defect{1,k}.Attributes.tag_name];
%                     
                        data = myHistory.elements.(name).(defectID).main.magnitude;
                        newData{1,1} = someHistoryFiles{i,1}.equipment.elements.element{1,j}.defect{1,k}.freq_main.Attributes.magnitude;
                        data = [data; newData];
                        myHistory.elements.(name).(defectID).main.magnitude = data; data = cell(0);newData = cell(0);

                        data = myHistory.elements.(name).(defectID).main.frequency;
                        newData{1,1} = num2str(str2num(someHistoryFiles{i,1}.equipment.elements.element{1,j}.defect{1,k}.freq_main.Attributes.frequency)/baseFreq);
                        data = [data; newData];
                        myHistory.elements.(name).(defectID).main.frequency = data;  data = cell(0);newData = cell(0);

                        data = myHistory.elements.(name).(defectID).secondary.magnitude;
                        newData{1,1} = someHistoryFiles{i,1}.equipment.elements.element{1,j}.defect{1,k}.freq_secondary.Attributes.magnitude;
                        data = [data; newData];
                        myHistory.elements.(name).(defectID).secondary.magnitude = data;  data = cell(0);newData = cell(0);

                        data = myHistory.elements.(name).(defectID).secondary.frequency;
                        newData{1,1} = num2str(str2num(someHistoryFiles{i,1}.equipment.elements.element{1,j}.defect{1,k}.freq_secondary.Attributes.frequency)/baseFreq);
                        data = [data; newData];
                        myHistory.elements.(name).(defectID).secondary.frequency = data;  data = cell(0);newData = cell(0);                     
                    end
                end
            end
        end
        
        function myFullHistory = createFullHistory(myHistoryManager)
            someHistoryFiles = myHistoryManager.deviceHistory;
            someStruct.history = someHistoryFiles;
            myFullHistory = createHistory(myHistoryManager,someStruct);
        end
        
        function myLastHistory = createLastHistory(myHistoryManager)
            lastFilesCnt = str2num(myHistoryManager.config.config.parameters.evaluation.historyValidator.Attributes.lastHistoryFilesCount);
            someHistoryFiles = myHistoryManager.deviceHistory;
            filesNumber = numel(someHistoryFiles);
            elementsNumber = numel(someHistoryFiles{1,1}.equipment.elements.element);
            myLastHistory = struct('elements',[]);
            % get date of each history file
            for i=1:1:filesNumber
                historyDate(i,1) = datetime(someHistoryFiles{i,1}.equipment.parameters.date.Attributes.value,'Format','dd-MM-yyyy');
            end
            % sort dates to find N last
            [lastDate,lastDateIndex] = sort(historyDate(:,1),'descend');
            lastFiles = [];
            if length(lastDate)>= lastFilesCnt
                for i=1:1:lastFilesCnt
                    lastFiles{i,1} = someHistoryFiles{lastDateIndex(i),1};
                end
                someStruct.history = lastFiles;
                myLastHistory = createHistory(myHistoryManager,someStruct);
            else
                myLastHistory = [];
            end
        end
        
        function [isHistoryValid, someHistory] = sendHistoryRequest(myHistoryManager)
            iLoger = loger.getInstance;
            printComputeInfo(iLoger, 'History manager', 'Proceed to checkout history.');
            
            myDeviceID = num2str(myHistoryManager.deviceID);
            isHistoryValid = 0;
            someHistory = [];
            lastFilesCnt = str2num(myHistoryManager.config.config.parameters.evaluation.historyValidator.Attributes.lastHistoryFilesCount);
            dirIn = fullfile(pwd,'In'); % /In folder path to look for
            
            config = myHistoryManager.config.config; % configuration structure
            
            historyFileStruct = [];
            historyFilesCnt = [];
            % get list of history files for current device in @in directory
            for i=1:1:numel(config.history.device)
                if numel(config.history.device) > 1
                    if strcmp(config.history.device{1,i}.Attributes.id, myDeviceID)
                        historyFilesCnt = str2num(config.history.device{1,i}.Attributes.historyFilesCount);
                        historyFileStruct = cell(historyFilesCnt,1);
                        if historyFilesCnt == 1
                            historyFileStruct{1,1} = config.history.device{1,i}.file;
                        else
                            for j=1:1:historyFilesCnt
                                historyFileStruct{j,1} = config.history.device{1,i}.file{1,j};
                            end
                        end
                        break;
                    end
                else
                    if strcmp(config.history.device.Attributes.id, myDeviceID)
                        historyFilesCnt = str2num(config.history.device.Attributes.historyFilesCount);
                        historyFileStruct = cell(historyFilesCnt,1);
                        if historyFilesCnt == 1
                            historyFileStruct{1,1} = config.history.device.file;
                        else
                            for j=1:1:historyFilesCnt
                                historyFileStruct{j,1} = config.history.device.file{1,j};
                            end
                        end
                        break;
                    end
                end
            end
            
            dirData = dir(dirIn);          %# Get the data for the current directory
            dirIndex = [dirData.isdir];             %# Find the index for directories
            fileList = {dirData(~dirIndex).name}';  %# Get a list of the files
            
            if ~isempty(fileList)
                fileList = cellfun(@(x) fullfile(dirIn,x),...  %# Prepend path to files
                               fileList,'UniformOutput',false);
                k=1;
                for i=1:1:numel(fileList)
                    [pathstr,name,ext] = fileparts(fileList{i,1}) ;
                    if strcmp(ext, '.xml') % Cut file type 
                        for j=1:1:historyFilesCnt
                            if strcmp(name, historyFileStruct{j,1}.Attributes.name)
                                someHistory{k,1} = xml2struct(fileList{i,1});
                                k=k+1;
                            end
                        end
                    end
                end
            end
            if (~isempty(someHistory) && numel(someHistory)>=lastFilesCnt)
                isHistoryValid = 1;
            else
                isHistoryValid = 0;
            end
            
            printComputeInfo(iLoger, 'History manager', 'History enabled.');
        end
   end    
    
    methods(Static)
%         function singleObj = getInstance
%             persistent localObj
%             if isempty(localObj) || ~isvalid(localObj)
%                 localObj = historyManager;
%             end
%             singleObj = localObj;
%         end
    end
    
end

