% ROLLINGBEARINGN_COCKED_INNER_RING_DEFECT_ROLLING_ELEMENT
% function returns a status of rolling bearing defect "Misalignment of the
% inner ring and the rolling elements defects" (defectID = 10)
% 
% Defect requirements:
%     main:
%         1) k1 * BSF +(-) k2 * shaftFreq (in acceleration envelope
%         spectrum)
% 
% Developer:              P. Riabtsev
% Development date:       30-03-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = rollingBearing_COCKED_INNER_RING_DEFECT_ROLLING_ELEMENT(defectStruct, ~, initialPeakTable)

    modTag = {[12 1]}; % [BSF +(-) shaftFreq] tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    % Get modulations data
    [accEnvWeightsStatus, defectStruct.accelerationEnvelopeSpectrum] = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, modTag, ...
        logProminenceThreshold, initialPeakTable.accelerationEnvelopeSpectrum, defectStruct.basicFreqs);
    
    % Combine results
    results = accEnvWeightsStatus;
    results(results < 0) = 0;
    results(results > 1) = 1;
    % Evaluate the defect similarity
    similarity = results;
    
    % The level is not evaluated
    level = 'NaN';
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum
function [weightsStatus, spectrumDefectStruct] = accEnvSpectrumEvaluation(spectrumDefectStruct, modTag, logProminenceThreshold, initialPeakTable, basicFreqs)
    
    [modPositions, modEstimations, ~, modLogProminence, modWeights, spectrumDefectStruct] = getModulationEvaluationVector(spectrumDefectStruct, modTag, initialPeakTable, basicFreqs);
    % Validation rule
    if ~isempty(modPositions)
        % Evaluate modulations
        defectPeaksIndex = modEstimations == 1;
        % Check the priminence threshold
        defectProminenceIndex = modLogProminence > logProminenceThreshold;
        % Validate all peaks
        validPeaksIndex = defectPeaksIndex & defectProminenceIndex;
        % Get valid weights
        defectWeights = modWeights(validPeaksIndex);
        % Evaluate weights
        weightsStatus = sum(defectWeights);
    else
        weightsStatus = 0;
    end
end