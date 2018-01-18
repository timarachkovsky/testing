% EQUIPMENTSTATEDETECTION function gets metrics data and detects the
% equipment state without history
% 
% Developer:              
% Development date:       
% Modified by:            P. Riabtsev
% Modification date:      09-10-2017
function [equipmentState, Data] = equipmentStateDetection(File, Config)
    
    % Parse metrics to detect the equipment state and write down them into
    % the structure
    Data = metrics4Detection(File);
    
    % Check the thresholds
    if isfield(Config.config.parameters.evaluation.equipmentStateDetection, 'metrics')
        % Check config thresholds
        metricsParameters = Config.config.parameters.evaluation.equipmentStateDetection.metrics;
        metricsFieldsNames = fieldnames(metricsParameters);
        if ~isempty(metricsFieldsNames)
            % Get the thresholds
            thresholds = cellfun(@(metricName) str2num(metricsParameters.(metricName).Attributes.thresholds), metricsFieldsNames, ...
                'UniformOutput', false);
            thresholdsExist = ~all(cellfun(@isempty, thresholds));
        else
            thresholdsExist = false;
        end
    else
        thresholdsExist = false;
    end
    
    if thresholdsExist
        % Detect the equipment state by the metrics thresholds
        Thresholds = Config.config.parameters.evaluation.equipmentStateDetection.metrics;
        [equipmentState, Data] = stateDetectionThreshold(Data, Thresholds);
    else
        [equipmentState, Data] = stateDetectionThreshold(Data, []);
    end
    
end

% METRICS4DETECTION function finds metrics for equipment state detection 
% (in infomativeTags.xml) and forms result structure
function [Result] = metrics4Detection(File)
    
    if ~isfield(File, 'informativeTags')
        error('There is no informativeTags for equipment state detection');
    end
    
    % Parse metric names for equipment state detection
    [type, metric] = cellfun(@(x) strtok(x, '_'), strsplit(File.informativeTags.classStruct.equipmentStateDetection.metrics.Attributes.name), 'UniformOutput', false);
    metric = cellfun(@(x) x(2 : end), metric, 'UniformOutput', false);
    weight = cellfun(@(x) str2double(x), strsplit(File.informativeTags.classStruct.equipmentStateDetection.weight.Attributes.value));
    
    % Fill in Result struct with parsed metrics
    for i = 1 : numel(metric)
        if strcmp(type{i}, 'calculate')
            Result.([type{i}, '_', metric{i}]).value = feval(metric{i}, File);
        else
            Result.([type{i}, '_', metric{i}]).value = File.(type{i}).metrics.(metric{i}).value;
        end
        Result.([type{i}, '_', metric{i}]).weight = weight(i);
    end
    
end
 
%         % SVM training
%         if str2double(config.config.parameters.evaluation.noiseDetection.svm.Attributes.enable)
%             Parameters = [];
%             if (isfield(config.config.parameters.evaluation.noiseDetection, 'svm'))
%                 Parameters = config.config.parameters.evaluation.noiseDetection.svm.Attributes;
%                 Parameters.classification = config.config.parameters.evaluation.noiseDetection.svm.classification.Attributes;
%                 Parameters.observations = config.config.parameters.evaluation.noiseDetection.svm.observations.Attributes;
%                 Parameters.secPerFrame =  config.config.parameters.evaluation.metrics.Attributes.secPerFrame;
%                 Parameters.secOverlapValue = config.config.parameters.evaluation.metrics.Attributes.secOverlapValue;
%                 Parameters.lowThresholdFrequency = config.config.parameters.evaluation.noiseDetection.Attributes.lowThresholdFrequency;
%                 Parameters.highThresholdFrequency = config.config.parameters.evaluation.noiseDetection.Attributes.highThresholdFrequency;
%                 Parameters.parpoolEnable = config.config.parameters.common.parpoolEnable.Attributes.value;
%                 Parameters.envSpectrum = config.config.parameters.evaluation.spectra.envSpectrum.Attributes;
%             end
%             path.toTrainSet = fullfile(pwd, 'In', 'train');
%             path.toTestSet = fullfile(pwd, 'In');
%             equipmentState = svmProcess(path, Parameters); 
%         end
%         
%         % Metrics evaluation
%         if str2double(config.config.parameters.evaluation.noiseDetection.svm.Attributes.enable) == 0 || strcmp(equipmentState,'UNKNOWN')
%             parameters = [];
%             if (isfield(config.config.parameters.evaluation, 'noiseDetection'))
%                 parameters = config.config.parameters.evaluation.noiseDetection.Attributes; 
%             end
%             equipmentState = noiseDetection(File, parameters);
%         end

