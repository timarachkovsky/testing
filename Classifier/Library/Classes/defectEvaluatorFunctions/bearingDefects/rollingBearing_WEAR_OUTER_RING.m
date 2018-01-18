% ROLLINGBEARINGN_WEAR_OUTER_RING function returns a status of
% rolling bearing defect "Wear of the Outer Ring" (defectID = 3)
% 
% Defect requirements:
%     main:
%         1) BPFO;
%     additional:
%         1) k * BPFO, k < 4
% 
% Developer:              P. Riabtsev
% Development date:       05-04-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = rollingBearing_WEAR_OUTER_RING(defectStruct, ~, ~)
    
    BPFOTag = {13}; % BPFO tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    accWeightsStatus = accSpectrumEvaluation(defectStruct.accelerationSpectrum, BPFOTag, logProminenceThreshold);
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    accEnvWeightsStatus = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, BPFOTag, logProminenceThreshold);
    
    % Combine results
    results = [accWeightsStatus, accEnvWeightsStatus];
    results(results < 0) = 0;
    results(results > 1) = 1;
    % Evaluate the defect similarity
    similarity = (min(results) + rms(results)) / 2;
    
    % The level is not evaluated
    level = 'NaN';
end

% ACCSPECTRUMEVALUATION function evaluates acceleration spectrum
function [weightsStatus] = accSpectrumEvaluation(spectrumDefectStruct, BPFOTag, logProminenceThreshold)
    
    % Get BPFO data
    [~, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, BPFOTag);
    % Get valid weights
    defectWeights = weights(logProminence > logProminenceThreshold);
    % Evaluate weights
    weightsStatus = sum(defectWeights);
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum
function [weightsStatus] = accEnvSpectrumEvaluation(spectrumDefectStruct, BPFOTag, logProminenceThreshold)
    
    % Get BPFO data
    [positions, ~, magnitudes, logProminence, weights] = getTagPositions(spectrumDefectStruct, BPFOTag);
    % Validation rule
    if ~isempty(positions)
        % Preallocate defect peaks index
        defectPeaksIndex = false(length(magnitudes), 1);
        % Evaluate the first peak
        defectPeaksIndex(1) = magnitudes(1) == max(magnitudes);
        % Evaluate higher harmonics
        for peakNumber = 2 : 1 : length(magnitudes)
            % Check that current peak less than 75% of previous defect peaks
            isLessHigherHarmonic = all(magnitudes(peakNumber) < (0.75 * magnitudes(defectPeaksIndex)));
            % Check that current peak is greater than 25% of previous peaks
            isGreaterHigherHarmonic = any(magnitudes(peakNumber) > (0.25 * magnitudes(defectPeaksIndex)));
            % Validate current peak
            defectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
        end
        % Check the prominence threshold
        defectProminenceIndex = logProminence > logProminenceThreshold;
        % Validate all peaks
        validPeaksIndex = defectPeaksIndex & defectProminenceIndex;
        % Get valid weights
        defectWeights = weights(validPeaksIndex);
        % Evaluate weights
        weightsStatus = sum(defectWeights);
    else
        weightsStatus = 0;
    end
end