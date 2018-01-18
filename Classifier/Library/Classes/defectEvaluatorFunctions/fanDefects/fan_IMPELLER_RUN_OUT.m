% FAN_IMPELLER_RUN_OUT function returns status of fan defect
% "Impeller Run-Out" (defectID = 1)
% 
% Defect requirements:
%     main:
%         1) k1 * bladePass +(-) k2 * shaftFreq (acceleration envelope
%         spectrum)
%         2) k * shaftFreq, k = [1, 2];
%     additional:
% 
% Developer:              P. Riabtsev
% Development date:       22-05-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = fan_IMPELLER_RUN_OUT(defectStruct, ~, initialPeakTable)
    
    modTag = {[32 1]}; % [bladePass +(-) shaftFreq] tag
    shaftFreqTag = {1}; % shaft frequency tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    [accEnvWeightsStatus, defectStruct.accelerationEnvelopeSpectrum] = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, modTag, shaftFreqTag, ...
        logProminenceThreshold, initialPeakTable.accelerationEnvelopeSpectrum, defectStruct.basicFreqs);
    
    % ACCELERATION SPECTRUM evaluation
    [accWeightsStatus] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, shaftFreqTag, logProminenceThreshold);
    
    % Combine results
    results = [accEnvWeightsStatus, accWeightsStatus];
    results(results < 0) = 0;
    results(results > 1) = 1;
    % Evaluate the defect similarity
    similarity = (min(results) + rms(results)) / 2;
    
    % The level is not evaluated
    level = 'NaN';
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum 
function [weightsStatus, spectrumDefectStruct] = accEnvSpectrumEvaluation(spectrumDefectStruct, modTag, shaftFreqTag, logProminenceThreshold, initialPeakTable, basicFreqs)
    
    % Get modulation data
    [~, modEstimations, ~, modLogProminence, modWeights, spectrumDefectStruct] = getModulationEvaluationVector(spectrumDefectStruct, modTag, initialPeakTable, basicFreqs);
    % Get valid weights
    modDefectWeights = modWeights((modLogProminence > logProminenceThreshold) & (modEstimations == 1));
    % Evaluate weights
    modWeightsStatus = sum(modDefectWeights);
    
    % Get shaft frequency data
    [~, ~, ~, shaftFreqLogProminence, shaftFreqWeights] = getTagPositions(spectrumDefectStruct, shaftFreqTag);
    % Get valid weights
    shaftFreqDefectWeights = shaftFreqWeights(shaftFreqLogProminence > logProminenceThreshold);
    % Evaluate weights
    shaftFreqWeightsStatus = sum(shaftFreqDefectWeights);
    
    % Combine weights statuses
    if (modWeightsStatus ~= 0)
        weightsStatus = (modWeightsStatus + shaftFreqWeightsStatus) / 2;
    else
        weightsStatus = 0;
    end
end

% ACCSPECTRUMEVALUATION function evaluates acceleration spectrum
function [weightsStatus] = accSpectrumEvaluation(spectrumDefectStruct, shaftFreqTag, logProminenceThreshold)
    
    % Get shaft frequency data
    [~, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, shaftFreqTag);
    % Get valid weights
    defectWeights = weights(logProminence > logProminenceThreshold);
    % Evaluate weights
    weightsStatus = sum(defectWeights);
end

