% STATEDETECTIONTHRESHOLD function detects the equipment state by the
% metrics thresholds
% 
% Developer:              P. Riabtsev
% Development date:       13-09-2017
% Modified by:            
% Modification date:      
function [equipmentState, Data] = stateDetectionThreshold(Data, Thresholds)
    
    % Evaluate each metric
    metricsFieldsNames = fieldnames(Data);
    for metricNumber = 1 : 1 : length(metricsFieldsNames)
        metricName = metricsFieldsNames{metricNumber};
        % Get metric data
        metricValue = Data.(metricName).value;
        if isfield(Thresholds, metricName)
            metricThresholds = str2num(Thresholds.(metricName).Attributes.thresholds);
        else
            metricThresholds = [];
        end
        
        if isempty(metricThresholds)
            % The metric thresholds are empty
            Data.(metricName).state = 'unknown';
        else
            % Get the metric thresholds
            lowerThreshold = min(metricThresholds);
            upperThreshold = max(metricThresholds);
            % Detect the equipment state by the metric
            if metricValue >= upperThreshold
                Data.(metricName).state = 'on';
            elseif (metricValue >= lowerThreshold) && (metricValue < upperThreshold)
                Data.(metricName).state = 'idle';
            elseif metricValue < lowerThreshold
                Data.(metricName).state = 'off';
            else
                Data.(metricName).state = 'unknonw';
            end
        end
    end
    
    if isempty(Thresholds)
        % The thresholds struct is empty
        equipmentState = 'unknown';
        return;
    end
    
    % Get states data
    states = cellfun(@(metricName) Data.(metricName).state, metricsFieldsNames, 'UniformOutput', false);
    weights = cell2num(cellfun(@(metricName) Data.(metricName).weight, metricsFieldsNames, 'UniformOutput', false));
    % Find metrics states
    onStateIndex = strcmp(states, 'on');
    idleStateIndex = strcmp(states, 'idle');
    offStateIndex = strcmp(states, 'off');
    % Evaluate metrics states
    onStateWeight = sum(weights(onStateIndex));
    idleStateWeight = sum(weights(idleStateIndex));
    offStateWeight = sum(weights(offStateIndex));
    % Detect the equipment state
    stateNames = {'on', 'idle', 'off'};
    stateWeights = [onStateWeight, idleStateWeight, offStateWeight];
    [maxStateWetight, maxStateIndex] = max(stateWeights);
    if maxStateWetight > 0
        equipmentState = stateNames{maxStateIndex};
    else
        equipmentState = 'unknown';
    end
    
end

