classdef historyContainer
    %HISTORYCONTAINER class is finding some fields in history 
    % and current structures
    
    properties (Access = protected)
        files
        historyType % HISTORYTYPE is a flag of the DSP-method which is in use
      
        xmlToStructHistoryObj
        
        currentData
        historyData
      
        date % time vector 
        historyValidity
    end
     
    methods (Access = public)
        
        % Constructor class
        function [myHistoryContainer] = historyContainer(myFiles, myHistoryType, myXmlToStructHistory)
            
            myHistoryContainer.files = myFiles;
            myHistoryContainer.historyType = myHistoryType;
            myHistoryContainer.xmlToStructHistoryObj = myXmlToStructHistory;
            
            % Create structures of the current data (from @status.xml) and
            % of the history file (for current device)
            [myHistoryContainer, myXmlToStructHistory] = findHistoryData(myHistoryContainer, myXmlToStructHistory);
            [myHistoryContainer] = findCurrentData(myHistoryContainer, myXmlToStructHistory);
            [myHistoryContainer.date] = getDate(myXmlToStructHistory);
        end
        
        % Getters/Setters
        function [myFiles] = getFiles(myHistoryContainer)
            myFiles = myHistoryContainer.files;
        end
        function [myHistoryContainer] = setFiles(myHistoryContainer,myFiles)
            myHistoryContainer.files = myFiles;
        end
        
        function [myHistoryType] = getHistoryType(myHistoryContainer)
            myHistoryType = myHistoryContainer.historyType;
        end
        function [myHistoryContainer] = setHistoryType(myHistoryContainer,myHistoryType)
            myHistoryContainer.historyType = myHistoryType;
        end
        
        function [myCurrentData] = getCurrentData(myHistoryContainer)
            myCurrentData = myHistoryContainer.currentData;
        end
        function [myHistoryContainer] = setCurrentData(myHistoryContainer,myCurrentData)
            myHistoryContainer.currentData = myCurrentData;
        end
        
        function [myHistoryData] = getHistoryData(myHistoryContainer)
            myHistoryData = myHistoryContainer.historyData;
        end
        function [myHistoryContainer] = setHistoryData(myHistoryContainer,myHistoryData)
            myHistoryContainer.historyData = myHistoryData;
        end
        
        function [myCurrentDate] = getDate(myHistoryContainer)
            myCurrentDate = myHistoryContainer.date;
        end
        function [myHistoryContainer] = setDate(myHistoryContainer,date)
            myHistoryContainer.date = date;
        end
        
        function [myHistoryValidity] = getHistoryValidity(myHistoryContainer)
            myHistoryValidity = myHistoryContainer.historyValidity;
        end
        function [myHistoryContainer] = setHistoryValidity(myHistoryContainer,myHistoryValidity)
            myHistoryContainer.historyValidity = myHistoryValidity;
        end
        
        function [myXmlToStructHistoryObj] = getXmlToStructHistoryObj(myHistoryContainer)
            myXmlToStructHistoryObj = myHistoryContainer.xmlToStructHistoryObj;
        end
        function [myHistoryContainer] = setXmlToStructHistoryObj(myHistoryContainer, myXmlToStructHistoryObj)
            myHistoryContainer.xmlToStructHistoryObj = myXmlToStructHistoryObj;
        end
        
    end
    
    methods (Access = protected)
        
        % CREATEDEVICEHISTORY fuction forms history struct for specific
        % device and method type, consisting of separate parsed status files 
        function [myHistoryContainer, myXmlToStructHistory] = findHistoryData(myHistoryContainer, myXmlToStructHistory)
            
            myDate = getDate(myXmlToStructHistory);
            myHistoryRaw = getHistoryDataRaw(myXmlToStructHistory);
            myHistoryType = getHistoryType(myHistoryContainer);
            myParametersXmlToStructHistory = getParameters(myXmlToStructHistory);
            iLoger = loger.getInstance;
                        
            if isempty(myHistoryRaw)
                myHistoryContainer = setHistoryValidity(myHistoryContainer,0);
                myHistoryContainer = setHistoryData(myHistoryContainer,[]);
                return
            else
                numberHistoryFiles = length(myHistoryRaw);
                myHistoryData = cell(numberHistoryFiles,1); 
                flagOfMatchFields = 1; % flag, that the fields of current status.xml and files of history is match
                for i=1:1:numberHistoryFiles
                    if isfield(myHistoryRaw{i,1}.equipment, myHistoryType)
                        myHistoryData{i,1} = myHistoryRaw{i,1}.equipment.(myHistoryType);
                        if strcmp(myHistoryType, 'frequencyDomainClassifier')
                            myHistoryData{i,1} = myHistoryContainer.checkCellArrayDefects(myHistoryData{i,1});
                        end
                        
                        if strcmp(myHistoryType, 'timeFrequencyDomainClassifier')
                            numberResonans = length(myHistoryData{i, 1}.resonantFrequency);
                            if numberResonans == 1
                                currentResonans = myHistoryData{i, 1}.resonantFrequency;
                                myHistoryData{i, 1}.resonantFrequency = [];
                                myHistoryData{i, 1}.resonantFrequency{1,1} = currentResonans;
                            end
                            
                            for j = 1:1:numberResonans
                                if isfield(myHistoryData{i, 1}.resonantFrequency{1,j}, 'frequencyDomainClassifier')
                                    myHistoryData{i, 1}.resonantFrequency{1,j}.frequencyDomainClassifier = ...
                                        myHistoryContainer.checkCellArrayDefects(myHistoryData{i, 1}.resonantFrequency{1,j}.frequencyDomainClassifier);
                                end
                            end
                        end
                    else
                        flagOfMatchFields = 0;
                        if myParametersXmlToStructHistory.logEnable
                            printComputeInfo(iLoger, ...
                                [myHistoryType 'HistoryContainer'], ...
                                'Is not match fields between history files or current status and history files.');
                        end
                    end
                            
                
                end
				
                if flagOfMatchFields
                    if myParametersXmlToStructHistory.logEnable
                        printComputeInfo(iLoger, ...
                                                [myHistoryType 'HistoryContainer'], ...
                                                'Is match fields between history files or current status and history files.');
                    end
                else
                    % To find empty fields of data in history files 
                    % and to delete date in time vector with empty data 
                    emptyFields = cellfun(@isempty, myHistoryData);
                    myHistoryData = myHistoryData(~emptyFields);
                    historyDate = myDate(2:end);
                    historyDate = historyDate(~emptyFields);
                    myDate(2:end) = [];
                    
                    if ~isempty(historyDate)
                        numberNewDate = length(historyDate)+1; 
                        newDate = cell(numberNewDate,1);
                        newDate(1,1) = myDate;
                        newDate(2:numberNewDate,1) = historyDate;
                        myDate = newDate;
                    end
                end
            end
            
            myXmlToStructHistory = setDate(myXmlToStructHistory,myDate);
            myHistoryContainer = setHistoryData(myHistoryContainer,myHistoryData);
            if ~isempty(myHistoryData) && numel(myHistoryData)>=3
                myHistoryContainer = setHistoryValidity(myHistoryContainer,1);
            else
                myHistoryContainer = setHistoryValidity(myHistoryContainer,0);
            end
        end
        
        % FINDCURRENTDATA function forms structure of the current status 
        % file for specific historyType
        function [myHistoryContainer] = findCurrentData(myHistoryContainer, myXmlToStructHistory)
            
            myHistoryType = getHistoryType(myHistoryContainer);
            myParametersXmlToStructHistory = getParameters(myXmlToStructHistory);
            iLoger = loger.getInstance;
            
            currentDataRaw = getCurrentDataRaw(myXmlToStructHistory);
            
            myCurrentData = currentDataRaw.equipment.(myHistoryType);
            if strcmp(myHistoryType, 'frequencyDomainClassifier')
                myCurrentData = myHistoryContainer.checkCellArrayDefects(myCurrentData);
            end
            
            if strcmp(myHistoryType, 'timeFrequencyDomainClassifier')
                numberResonans = length(myCurrentData.resonantFrequency);
                if numberResonans == 1
                    currentResonans = myCurrentData.resonantFrequency;
                    myCurrentData.resonantFrequency = [];
                    myCurrentData.resonantFrequency{1,1} = currentResonans;
                end

                for j = 1:1:numberResonans
                    if isfield(myCurrentData.resonantFrequency{1,j}, 'frequencyDomainClassifier')
                        myCurrentData.resonantFrequency{1,j}.frequencyDomainClassifier = ...
                            myHistoryContainer.checkCellArrayDefects(myCurrentData.resonantFrequency{1,j}.frequencyDomainClassifier);
                    end
                end
            end
            
            myHistoryContainer = setCurrentData(myHistoryContainer,myCurrentData);
            if myParametersXmlToStructHistory.logEnable
                printComputeInfo(iLoger, [myHistoryType 'HistoryContainer'], 'file @status.xml succesfully readed');
            end
        end
    end
    
    methods (Static)
        
        % Checking the number of defects for current type of element
        % Write one defect in a cell as well as several defects
        function myCurrentData = checkCellArrayDefects(myCurrentData)
            % Checking the number of defects for current type of element
                if isstruct(myCurrentData.element)
                    currentElement = myCurrentData.element;
                    myCurrentData.element = [];
                    myCurrentData.element{1,1} = currentElement;
                end
                % Write one defect in a cell as well as several defects
                for elementNum = 1 : 1 : length(myCurrentData.element)
                    if isstruct(myCurrentData.element{1, elementNum}.defect)
                        currentDefects = myCurrentData.element{1, elementNum}.defect;
                        myCurrentData.element{1, elementNum}.defect = [];
                        myCurrentData.element{1, elementNum}.defect{1, 1} = currentDefects;
                    end
                end
        end
    end
    
    methods (Abstract = true, Access = protected)
        [myTable] = data2Table(myHistoryContainer,myData)
    end
    
end

