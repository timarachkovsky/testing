% SYNCHRONOUSMOTOR_DEFECTS_EXCITATION_SYSTEM function returns status of
% synchronous motor defect "Defects of the Excitation System"
% (defectID = 4)
% 
% Defect requirements:
%     main:
%         1) k1 * coilFreq +(-) k2 * shaftFreq, k1 < 4;
%     additional:
% 
% Developer:              P. Riabtsev
% Development date:       11-05-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = synchronousMotor_DEFECTS_EXCITATION_SYSTEM(defectStruct, ~, initialPeakTable)
    
    modTag = {[10 1]}; % [coilFreq +(-) shaftFreq] tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    [accWeightsStatus, defectStruct.accelerationSpectrum] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, modTag, ...
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
function [modWeightsStatus, spectrumDefectStruct] = accSpectrumEvaluation(spectrumDefectStruct, modTag, logProminenceThreshold, initialPeakTable, basicFreqs)
    
    % Get modulation data
    [~, modEstimations, ~, modLogProminence, modWeights, spectrumDefectStruct] = getModulationEvaluationVector(spectrumDefectStruct, modTag, initialPeakTable, basicFreqs);
    % Get valid weights
    modDefectWeights = modWeights((modLogProminence > logProminenceThreshold) & (modEstimations == 1));
    % Evaluate weights
    modWeightsStatus = sum(modDefectWeights);
end

