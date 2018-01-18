% PHASE_LOSS function returns a status of the defect
% 
% Defect requirements:
%     main:
%         1) k1 * shaftFreq, 1/3 * SCR, 2/3 * SCR, SCR
%     additional:
%         
% Developer:              Kosmach N.
% Development date:       09.10.2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = directCurrentMotor_PHASE_LOSS(defectStruct, ~, ~)
    
    SCR = {9}; % SCR tag
    shaftFreq = {1}; % shaftFreq tag
    logProminenceThreshold = 0; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    similarity = accSpectrumEvaluation(defectStruct.accelerationSpectrum, ...
        SCR, shaftFreq, logProminenceThreshold);
    
    similarity(similarity > 1) = 1;
    
    % The level is not evaluated
    level = 'NaN';
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum
function weightsStatus = accSpectrumEvaluation(spectrumDefectStruct, ...
    SCR, shaftFreq, logProminenceThreshold)
    
    % Get shaft SCR data
    [~, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, SCR);
    % Get valid weights
    SCRWeights = weights(logProminence > logProminenceThreshold);
    % Evaluate weights
    SCRStatus = sum(SCRWeights);

    % Get shaft shaftFreq data
    [~, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, shaftFreq);
    % Get valid weights
    shaftFreqWeights = weights(logProminence > logProminenceThreshold);
    % Evaluate weights
    shaftFreqStatus = sum(shaftFreqWeights);
    if shaftFreqStatus > 0.5
        shaftFreqStatus = 0.5;
    end
    
    weightsStatus = SCRStatus + shaftFreqStatus;
end