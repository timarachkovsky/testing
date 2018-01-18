% COUPLING_COUPLING_DEFECT function returns a status of coupling defect
% "Coupling Defect" (defectID = 1)
% 
% Defect requirements:
%     main:
%         1) k * shaftFreq, k < 6 (acceleration spectrum)
%         2) k * shaftFreq, k > 4 (acceleration envelope spectrum)
% 
% Developer:              P. Riabtsev
% Development date:       22-05-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = coupling_COUPLING_DEFECT(defectStruct, ~, ~)

    shaftFreqTag = {1}; % shaft frequency tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    accWeightsStatus = spectrumEvaluation(defectStruct.accelerationSpectrum, shaftFreqTag, logProminenceThreshold);
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    accEnvWeightsStatus = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, shaftFreqTag, logProminenceThreshold);
    
    % Combine results
    results = [accWeightsStatus, accEnvWeightsStatus];
    results(results < 0) = 0;
    results(results > 1) = 1;
    % Evaluate the defect similarity
    similarity = (min(results) + rms(results)) / 2;
    
    % The level is not evaluated
    level = 'NaN';
end

% SPECTRUMEVALUATION function evaluates spectrum
function [weightsStatus] = spectrumEvaluation(spectrumDefectStruct, shaftFreqTag, logProminenceThreshold)
    
    % Get shaft frequency data
    [positions, ~, magnitudes, logProminence, weights] = getTagPositions(spectrumDefectStruct, shaftFreqTag);
    % Validation rule
    if ~isempty(positions)
        % Preallocate defect peak index
        defectPeaksIndex = false(length(magnitudes), 1);
        % Evaluate the first peak
        % Check that the first peak is the maximum peak
        defectPeaksIndex(1) = magnitudes(1) == max(magnitudes);
        % Evaluate higher harmonics
        if defectPeaksIndex(1)
            for peakNumber = 2 : 1 : length(magnitudes)
                % Check that current peak is less than previous peaks
                isLessHigherHarmonic = all(magnitudes(peakNumber) < magnitudes(defectPeaksIndex));
                % Check that current peak is greater than 25% of previous
                % peaks
                isGreaterHigherHarmonic = any(magnitudes(peakNumber) > (0.25 * magnitudes(defectPeaksIndex)));
                % Validate current peak
                defectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
            end
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