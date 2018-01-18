% DEFECTS_EXCITATION_SYSTEM function returns a status of the defect
% 
% Defect requirements:
%     main:
%         1) k1 * teethFreq, without modulation on shaft
%     additional:
%         
% Developer:              Kosmach N.
% Development date:       06.10.2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = directCurrentMotor_DEFECTS_EXCITATION_SYSTEM(defectStruct, ~, initialPeakTable)
    
    modTag = {[7 1]}; % [teethFreq +(-) shaftFreq] tag
    logProminenceThreshold = 0; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    [similarity, defectStruct.accelerationSpectrum] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, ...
        modTag, logProminenceThreshold, initialPeakTable.accelerationSpectrum, defectStruct.basicFreqs);
    
    similarity(similarity > 1) = 1;
    
    % The level is not evaluated
    level = 'NaN';
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum
function [weightsStatus, spectrumDefectStruct] = accSpectrumEvaluation(spectrumDefectStruct, ...
    modTag, logProminenceThreshold, initialPeakTable, basicFreqs)
    
    % Get modulation data
    [modPositions, modEstimations, ~, modLogProminence, modWeights, spectrumDefectStruct] = getModulationEvaluationVector(spectrumDefectStruct, modTag, initialPeakTable, basicFreqs);
    % Validation rule
    if ~isempty(modPositions)
        % Evaluate peaks
        modDefectPeaksIndex = modEstimations == 0;
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
    weightsStatus = modWeightsStatus;
end