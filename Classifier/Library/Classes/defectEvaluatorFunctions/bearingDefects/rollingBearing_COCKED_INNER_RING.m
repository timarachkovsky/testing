% ROLLINGBEARING_COCKED_INNER_RING function returns status of rolling
% bearing defect "Misalignment of the inner ring" (defectID = 9)
% 
% Defect requirements:
%     main:
%         1) k * (shaftFreq - FTF);
% 
% Developer:              P. Riabtsev
% Development date:       05-04-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = rollingBearing_COCKED_INNER_RING(defectStruct, ~, ~)
    
    difTag = {33}; % [shaftFreq - FTF] tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    accWeightsStatus = accSpectrumEvaluation(defectStruct.accelerationSpectrum, difTag, logProminenceThreshold);
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    accEnvWeightsStatus = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, difTag, logProminenceThreshold);
    
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
function [weightsStatus] = accSpectrumEvaluation(spectrumDefectStruct, difTag, logProminenceThreshold)
    
    % Get data of frequency difference harmonic
    [~, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, difTag);
    % Get valid weights
    defectWeights = weights(logProminence > logProminenceThreshold);
    % Evaluate weights
    weightsStatus = sum(defectWeights);
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum
function [weightsStatus] = accEnvSpectrumEvaluation(spectrumDefectStruct, difTag, logProminenceThreshold)
    
    % Get data of frequency difference harmonics
    [positions, ~, magnitudes, logProminence, weights] = getTagPositions(spectrumDefectStruct, difTag);
    % Validation rule
    if ~isempty(positions)
        % Preallocate defect peaks index
        defectPeaksIndex = false(length(magnitudes), 1);
        % Evaluate the first harmonic
        firstHarmonicIndex = find(positions == 1);
        if ~isempty(firstHarmonicIndex)
            % Validate the first harmonic
            defectPeaksIndex(firstHarmonicIndex) = magnitudes(firstHarmonicIndex) == max(magnitudes(positions ~= 2));
        end
        % Evaluate the second harmonic
        secondHarmonicIndex = find(positions == 2);
        if ~isempty(secondHarmonicIndex)
            % Check that the second harmonic is the maximum
            isMaxSecondHarmonic = magnitudes(secondHarmonicIndex) == max(magnitudes(positions ~= 1));
            if ~isempty(firstHarmonicIndex)
                % Check that the second harmonic is greater than 120% of
                % the first harmonic
                isGreaterSecondHarmonic = magnitudes(secondHarmonicIndex) > (1.20 * magnitudes(firstHarmonicIndex));
                % Validate the second harmonic
                defectPeaksIndex(secondHarmonicIndex) = isMaxSecondHarmonic & isGreaterSecondHarmonic;
            else
                % Validate the second harmonic
                defectPeaksIndex(secondHarmonicIndex) = isMaxSecondHarmonic;
            end
        end
        % Find the first higher harmonic index
        if ~isempty(secondHarmonicIndex)
            firstHigherHarmonicIndex = secondHarmonicIndex + 1;
        else
            firstHigherHarmonicIndex = firstHarmonicIndex + 1;
        end
        if (firstHigherHarmonicIndex > 1)
            % Evaluate higher harmonics
            for peakNumber = firstHigherHarmonicIndex : 1 : length(magnitudes)
                % Check that current peak less than previous peaks
                isLessHigherHarmonic = all(magnitudes(peakNumber) < magnitudes(defectPeaksIndex));
                % Check that current peak greater than 25% of previous peaks
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