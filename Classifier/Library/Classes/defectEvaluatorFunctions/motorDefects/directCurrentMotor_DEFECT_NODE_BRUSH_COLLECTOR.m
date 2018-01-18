% DEFECT_NODE_BRUSH_COLLECTOR function returns a status of the defect
% 
% Defect requirements:
%     main:
%         1) k1 * collectorFrequency, brushFrequency
%     additional:
%         
% Developer:              Kosmach N.
% Development date:       06.10.2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = directCurrentMotor_DEFECT_NODE_BRUSH_COLLECTOR(defectStruct, ~, ~)
    
    collectorFrequencyTag = {6}; % collectorFrequency tag
    brushFrequencyTag = {8}; % brushFrequency tag
    logProminenceThreshold = 0; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    similarity = accSpectrumEvaluation(defectStruct.accelerationSpectrum, ...
        collectorFrequencyTag, brushFrequencyTag, logProminenceThreshold);
    
    similarity(similarity > 1) = 1;
    
    % The level is not evaluated
    level = 'NaN';
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum
function weightsStatus = accSpectrumEvaluation(spectrumDefectStruct, ...
    collectorFrequencyTag, brushFrequencyTag, logProminenceThreshold)
    
    % Get shaft collectorFrequency data
    [~, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, collectorFrequencyTag);
    % Get valid weights
    collectorFrequencyWeights = weights(logProminence > logProminenceThreshold);
    % Evaluate weights
    collectorFrequencyStatus = sum(collectorFrequencyWeights);

    % Get shaft brushFrequencyTag data
    [~, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, brushFrequencyTag);
    % Get valid weights
    brushFrequencyWeights = weights(logProminence > logProminenceThreshold);
    % Evaluate weights
    brushFrequencyStatus = sum(brushFrequencyWeights);
    
    weightsStatus = collectorFrequencyStatus + brushFrequencyStatus;
end