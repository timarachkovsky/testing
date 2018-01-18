% GETLASTHISTORYFILEPATH function returns full path to the last history
% file in @In directory for current device 

function [ filePath ] = getLastHistoryFilePath( myDeviceID, config )

    if ~ischar(myDeviceID)
        myDeviceID = num2str(myDeviceID);
    end
    
    filePath = [];
    devicesNumber = numel(config.config.history.device);
    deviceIndex = [];
    for i=1:1:devicesNumber % get device index in config ctructure
       if  strcmp(config.config.history.device{1,i}.Attributes.id, myDeviceID)
           deviceIndex = i;
           break;
       end
    end
    
    % Find and return the last history file full path for found deviceId 
    if(~isempty(deviceIndex))
        fileName = [];
        % Get history files number for current deviceID
%         historyFilesNumber = numel(config.config.history.device{1,deviceIndex}.file); 
        historyFilesNumber = str2num(config.config.history.device{1,deviceIndex}.Attributes.historyFilesNumber); 
        if historyFilesNumber == 1
            fileName = config.config.history.device{1,deviceIndex}.file.Attributes.name;
        elseif historyFilesNumber > 1
            fileName = config.config.history.device{1,deviceIndex}.file{1,historyFilesNumber}.Attributes.name;
        else
            fileName = [];
        end
        
        if(~isempty(fileName))
            filePath = fullfile(pwd,'In',[fileName,'.xml']);
        end
    end

end

