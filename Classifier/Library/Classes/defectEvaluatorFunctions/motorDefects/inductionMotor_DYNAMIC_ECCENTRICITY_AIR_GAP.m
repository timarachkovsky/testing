% INDUCTIONMOTOR_DYNAMIC_ECCENTRICITY_AIR_GAP function returns status of
% induction motor defect "Dynamic Eccentricity of the Air Gap" (defectID =
% 2)
% 
% Defect requirements:
%     main:
%         1) k1 * barFreq +(-) k2 * shaftFreq, k1 = [1, 2];
%     additional:
%         1) 1 * shaftFreq;
% 
% Developer:              P. Riabtsev
% Development date:       10-05-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = inductionMotor_DYNAMIC_ECCENTRICITY_AIR_GAP(defectStruct, ~, initialPeakTable)
    
    modTag = {[4 1]}; % [barFreq +(-) shaftFreq] tag
    shaftFreqTag = {1}; % shaft frequency tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    [accWeightsStatus, defectStruct.accelerationSpectrum] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, modTag, shaftFreqTag, ...
        logProminenceThreshold, initialPeakTable.accelerationSpectrum, defectStruct.basicFreqs);
    
    % Combine results
    results = accWeightsStatus;
    results(results < 0) = 0;
    results(results > 1) = 1;
    % Evaluate the defect similarity
    similarity = (min(results) + rms(results)) / 2;
    
    % The level is not evaluated
    level = 'NaN';
end

% ACCSPECTRUMEVALUATION function evaluates acceleration spectrum
function [weightsStatus, spectrumDefectStruct] = accSpectrumEvaluation(spectrumDefectStruct, modTag, shaftFreqTag, logProminenceThreshold, initialPeakTable, basicFreqs)
    
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
        weightsStatus = modWeightsStatus + (0.1 * shaftFreqWeightsStatus);
    else
        weightsStatus = 0;
    end
end

