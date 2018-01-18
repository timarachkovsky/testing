% RECTIFIER_TUNING_FAULTS function returns a status of the defect
% 
% Defect requirements:
%     main:
%         1) k1 * shaftFreq, k1 * SCR +- * k2 shaftFreq
%     additional:
%         
% Developer:              Kosmach N.
% Development date:       09.10.2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = directCurrentMotor_RECTIFIER_TUNING_FAULTS(defectStruct, ~, initialPeakTable)
    
    shaftFreqTag = {1}; % shaftFreq tag
    modTag = {[9 1]}; % [SCR +(-) shaftFreq] tag
    logProminenceThreshold = 0; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    [similarity, defectStruct.accelerationSpectrum] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, ...
        shaftFreqTag, modTag, logProminenceThreshold, initialPeakTable.accelerationSpectrum, defectStruct.basicFreqs);
    
    similarity(similarity > 1) = 1;
    
    % The level is not evaluated
    level = 'NaN';
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum
function [weightsStatus, spectrumDefectStruct] = accSpectrumEvaluation(spectrumDefectStruct, ...
    shaftFreqTag, modTag, logProminenceThreshold, initialPeakTable, basicFreqs)
    
    % Get modulation data
    [modPositions, modEstimations, ~, modLogProminence, modWeights, spectrumDefectStruct] = ...
        getModulationEvaluationVector(spectrumDefectStruct, modTag, initialPeakTable, basicFreqs);
    % Validation rule
    if ~isempty(modPositions)
        % Evaluate peaks
        modDefectPeaksIndex = modEstimations == 1;
        % Check the prominence threshold
        modDefectProminenceIndex = modLogProminence > logProminenceThreshold;
        % Validate all peaks
        modValidPeaksIndex = modDefectPeaksIndex & modDefectProminenceIndex;
        % Get valid weights
        modDefectWeights = modWeights(modValidPeaksIndex);
        % Evaluate weights
        modWeightsStatus = sum(modDefectWeights);
    else
        modWeightsStatus = 0;
    end
    
    % Get shaft frequency data
    [~, ~, ~, shaftFreqLogProminence, shaftFreqWeights] = getTagPositions(spectrumDefectStruct, shaftFreqTag);
    % Get valid weights
    shaftFreqDefectWeights = shaftFreqWeights(shaftFreqLogProminence > logProminenceThreshold);
    % Evaluate weights
    shaftFreqWeightsStatus = sum(shaftFreqDefectWeights);
    
    % Combine weights statuses
    if (modWeightsStatus ~= 0) && (shaftFreqWeightsStatus ~= 0)
        weightsStatus = modWeightsStatus + shaftFreqWeightsStatus;
    else
        weightsStatus = 0;
    end
end