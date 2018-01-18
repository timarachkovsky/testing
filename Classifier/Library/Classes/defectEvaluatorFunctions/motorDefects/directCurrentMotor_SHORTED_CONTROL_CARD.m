% SHORTED_CONTROL_CARD function returns a status of the defect
% 
% Defect requirements:
%     main:
%         1) k1 * shaftFreq, k2 * LF, SCR
%     additional:
%         
% Developer:              Kosmach N.
% Development date:       09.10.2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = directCurrentMotor_SHORTED_CONTROL_CARD(defectStruct, ~, ~)
    
    SCR = {9}; % SCR tag
    shaftFreq = {1}; % shaftFreq tag
    lineFreq = {3}; % twiceLineFreq tag
    logProminenceThreshold = 0; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    similarity = accSpectrumEvaluation(defectStruct.accelerationSpectrum, ...
        SCR, shaftFreq, lineFreq, logProminenceThreshold);
    
    similarity(similarity > 1) = 1;
    
    % The level is not evaluated
    level = 'NaN';
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum
function weightsStatus = accSpectrumEvaluation(spectrumDefectStruct, ...
    SCR, shaftFreq, lineFreq, logProminenceThreshold)
    
    % Get SCR data
    [~, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, SCR);
    % Get valid weights
    SCRWeights = weights(logProminence > logProminenceThreshold);
    % Evaluate weights
    SCRStatus = sum(SCRWeights);

    % Get shaftFreq data
    [~, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, shaftFreq);
    % Get valid weights
    shaftFreqWeights = weights(logProminence > logProminenceThreshold);
    % Evaluate weights
    shaftFreqStatus = sum(shaftFreqWeights);
    
    % Get lineFreq data
    [~, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, lineFreq);
    % Get valid weights
    lineFreqWeights = weights(logProminence > logProminenceThreshold);
    % Evaluate weights
    lineFreqStatus = sum(lineFreqWeights);
    
    weightsStatus = SCRStatus + shaftFreqStatus + lineFreqStatus;
end