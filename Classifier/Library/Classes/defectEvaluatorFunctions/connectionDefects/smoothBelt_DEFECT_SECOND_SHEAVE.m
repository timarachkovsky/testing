% SMOOTHBELT_DEFECT_SECOND_SHEAVE function returns status of smooth belt
% defect "Defect of the Second Sheave" (defectID = 2)
% 
% Defect requirements:
%     main:
%         1) k * sheaveFreq2, k > 4;
%     additional:
% 
% Developer:              P. Riabtsev
% Development date:       06-06-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = smoothBelt_DEFECT_SECOND_SHEAVE(defectStruct, ~, ~)
    
    sheaveFreq2Tag = {30}; % driven sheave frequency tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    accEnvWeightsStatus = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, sheaveFreq2Tag, logProminenceThreshold);
    
    % ACCELERATION SPECTRUM evaluation
    accWeightsStatus = accSpectrumEvaluation(defectStruct.accelerationSpectrum, sheaveFreq2Tag, logProminenceThreshold);
    
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
function [weightsStatus] = accEnvSpectrumEvaluation(spectrumDefectStruct, sheaveFreq2Tag, logProminenceThreshold)
    
    % Get driven sheave frequency data
    [sheaveFreq2Positions, ~, sheaveFreq2Magnitudes, sheaveFreq2LogProminence, sheaveFreq2Weights] = getTagPositions(spectrumDefectStruct, sheaveFreq2Tag);
    % Validation rule
    if ~isempty(sheaveFreq2Positions)
        % Preallocate defect peak index
        sheaveFreq2DefectPeaksIndex = false(length(sheaveFreq2Magnitudes), 1);
        % Evaluate the first peak
        % Check that the first peak is the maximum peak
        sheaveFreq2DefectPeaksIndex(1) = sheaveFreq2Magnitudes(1) == max(sheaveFreq2Magnitudes);
        % Evaluate higher harmonics
        if sheaveFreq2DefectPeaksIndex(1)
            for peakNumber = 2 : 1 : length(sheaveFreq2Magnitudes)
                % Check that current peak is less than previous peaks
                isLessHigherHarmonic = all(sheaveFreq2Magnitudes(peakNumber) < sheaveFreq2Magnitudes(sheaveFreq2DefectPeaksIndex));
                % Check that current peak is greater than 25% of previous
                % peaks
                isGreaterHigherHarmonic = any(sheaveFreq2Magnitudes(peakNumber) > (0.25 * sheaveFreq2Magnitudes(sheaveFreq2DefectPeaksIndex)));
                % Validate current peak
                sheaveFreq2DefectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
            end
        end
        % Check the prominence threshold
        sheaveFreq2DefectProminenceIndex = sheaveFreq2LogProminence > logProminenceThreshold;
        % Validate all peaks
        sheaveFreq2ValidPeaksIndex = sheaveFreq2DefectPeaksIndex & sheaveFreq2DefectProminenceIndex;
        % Get valid weights
        sheaveFreq2DefectWeights = sheaveFreq2Weights(sheaveFreq2ValidPeaksIndex);
        % Evaluate weights
        sheaveFreq2WeightsStatus = sum(sheaveFreq2DefectWeights);
    else
        sheaveFreq2WeightsStatus = 0;
    end
    
    % Combine weights statuses
    weightsStatus = sheaveFreq2WeightsStatus;
end

% ACCSPECTRUMEVALUATION function evaluates acceleration spectrum
function [weightsStatus] = accSpectrumEvaluation(spectrumDefectStruct, sheaveFreq2Tag, logProminenceThreshold)
    
    % Get driven sheave frequency data
    [sheaveFreq2Positions, ~, sheaveFreq2Magnitudes, sheaveFreq2LogProminence, sheaveFreq2Weights] = getTagPositions(spectrumDefectStruct, sheaveFreq2Tag);
    % Validation rule
    if ~isempty(sheaveFreq2Positions)
        % Preallocate defect peak index
        sheaveFreq2DefectPeaksIndex = false(length(sheaveFreq2Magnitudes), 1);
        % Evaluate the first harmonic
        sheaveFreq2DefectPeaksIndex(1) = true;
        % Evaluate higher harmonic
        sheaveFreq2DefectPeaksIndex(2 : end) = sheaveFreq2Magnitudes(2 : end) < sheaveFreq2Magnitudes(1);
        % Check the prominence threshold
        sheaveFreq2DefectProminenceThreshold = sheaveFreq2LogProminence > logProminenceThreshold;
        % Validate all peaks
        sheaveFreq2ValidPeaksIndex = sheaveFreq2DefectPeaksIndex & sheaveFreq2DefectProminenceThreshold;
        % Get valid weigths
        sheaveFreq2DefectWeights = sheaveFreq2Weights(sheaveFreq2ValidPeaksIndex);
        % Evaluate weights
        sheaveFreq2WeightsStatus = sum(sheaveFreq2DefectWeights);
    else
        sheaveFreq2WeightsStatus = 0;
    end
    
    % Combine weights statuses
    weightsStatus = sheaveFreq2WeightsStatus;
end

