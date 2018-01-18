% TOOTHEDBELT_BELT_SLIP function returns status of toothed belt defect
% "Belt Slip" (defectID = 4)
% 
% Defect requirements:
%     main:
%         1) k1 * sheaveFreq1 +(-) k2 * beltFreq;
%         2) k1 * sheaveFreq2 +(-) k2 * beltFreq;
%     additional:
% 
% Developer:              P. Riabtsev
% Development date:       06-06-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = toothedBelt_BELT_SLIP(defectStruct, ~, initialPeakTable)
    
    sheave1ModTag = {[29 28]}; % [sheaveFreq1 +(-) beltFreq] tag
    sheave2ModTag = {[30 28]}; % [sheaveFreq2 +(-) beltFreq] tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    [accWeightsStatus, defectStruct.accelerationSpectrum] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, sheave1ModTag, sheave2ModTag, ...
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
function [weightsStatus, spectrumDefectStruct] = accSpectrumEvaluation(spectrumDefectStruct, sheave1ModTag, sheave2ModTag, logProminenceThreshold, initialPeakTable, basicFreqs)
    
    % Get driving sheave modulation data
    [~, sheave1ModEstimations, ~, sheave1ModLogProminence, sheave1ModWeights, spectrumDefectStruct] = getModulationEvaluationVector(spectrumDefectStruct, sheave1ModTag, initialPeakTable, basicFreqs);
    % Get valid weights
    sheave1ModDefectWeights = sheave1ModWeights((sheave1ModLogProminence > logProminenceThreshold) & (sheave1ModEstimations == 1));
    % Evaluate weights
    sheave1ModWeightsStatus = sum(sheave1ModDefectWeights);
    
    % Get driven sheave modulation data
    [~, sheave2ModEstimations, ~, sheave2ModLogProminence, sheave2ModWeights, spectrumDefectStruct] = getModulationEvaluationVector(spectrumDefectStruct, sheave2ModTag, initialPeakTable, basicFreqs);
    % Get valid weights
    sheave2ModDefectWeights = sheave2ModWeights((sheave2ModLogProminence > logProminenceThreshold) & (sheave2ModEstimations == 1));
    % Evaluate weights
    sheave2ModWeightsStatus = sum(sheave2ModDefectWeights);
    
    % Combine weights statuses
    weightsStatus = max(sheave1ModWeightsStatus, sheave2ModWeightsStatus);
end

