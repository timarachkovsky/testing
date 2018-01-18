% ISO7919PROCESSING function prepares the data and runs the calculation of
% ISO 7919 method
function [resultShaftStruct] = iso7919Processing(shaftStruct, peak2peakValue, standardPart)
    
    iLoger = loger.getInstance;
    
    if isempty(standardPart)
        standardPart = '2';
    end
    
    % Find priority shafts
    priorityIndex = logical(cell2num({shaftStruct.priority}));
    resultShaftStruct = shaftStruct(priorityIndex);
    
    if isempty(resultShaftStruct)
        printComputeInfo(iLoger, 'ISO7919 method', 'There is no priority shafts.');
        return;
    else
        % Convert shaft rotational frequency into shaft rotational speed
        shaftFrequencyVector = cell2num({resultShaftStruct.freq});
        shaftSpeedVector = shaftFrequencyVector * 60;
        % ISO 7919
        [status, thresholds] = iso7919(shaftSpeedVector, peak2peakValue, standardPart);
        
        for shaftNumber = 1 : 1 : length(status)
            resultShaftStruct(shaftNumber).value = peak2peakValue;
            resultShaftStruct(shaftNumber).status = status{shaftNumber};
            resultShaftStruct(shaftNumber).thresholds = thresholds{shaftNumber};
        end
    end
    
end

