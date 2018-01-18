% SMOOTHBELT_DEFECT_FIRST_SHEAVE function returns status of smooth belt
% defect "Defect of the First Sheave" (defectID = 1)
% 
% Defect requirements:
%     main:
%         1) k * sheaveFreq1, k > 4;
%     additional:
% 
% Developer:              P. Riabtsev
% Development date:       06-06-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = smoothBelt_DEFECT_FIRST_SHEAVE(defectStruct, ~, ~)
    
    sheaveFreq1Tag = {29}; % driving sheave frequency tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    accEnvWeightsStatus = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, sheaveFreq1Tag, logProminenceThreshold);
    
    % ACCELERATION SPECTRUM evaluation
    accWeightsStatus = accSpectrumEvaluation(defectStruct.accelerationSpectrum, sheaveFreq1Tag, logProminenceThreshold);
    
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
function [weightsStatus] = accEnvSpectrumEvaluation(spectrumDefectStruct, sheaveFreq1Tag, logProminenceThreshold)
    
    % Get driving sheave frequency data
    [sheaveFreq1Positions, ~, sheaveFreq1Magnitudes, sheaveFreq1LogProminence, sheaveFreq1Weights] = getTagPositions(spectrumDefectStruct, sheaveFreq1Tag);
    % Validation rule
    if ~isempty(sheaveFreq1Positions)
        % Preallocate defect peak index
        sheaveFreq1DefectPeaksIndex = false(length(sheaveFreq1Magnitudes), 1);
        % Evaluate the first peak
        % Check that the first peak is the maximum peak
        sheaveFreq1DefectPeaksIndex(1) = sheaveFreq1Magnitudes(1) == max(sheaveFreq1Magnitudes);
        % Evaluate higher harmonics
        if sheaveFreq1DefectPeaksIndex(1)
            for peakNumber = 2 : 1 : length(sheaveFreq1Magnitudes)
                % Check that current peak is less than previous peaks
                isLessHigherHarmonic = all(sheaveFreq1Magnitudes(peakNumber) < sheaveFreq1Magnitudes(sheaveFreq1DefectPeaksIndex));
                % Check that current peak is greater than 25% of previous
                % peaks
                isGreaterHigherHarmonic = any(sheaveFreq1Magnitudes(peakNumber) > (0.25 * sheaveFreq1Magnitudes(sheaveFreq1DefectPeaksIndex)));
                % Validate current peak
                sheaveFreq1DefectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
            end
        end
        % Check the prominence threshold
        sheaveFreq1DefectProminenceIndex = sheaveFreq1LogProminence > logProminenceThreshold;
        % Validate all peaks
        sheaveFreq1ValidPeaksIndex = sheaveFreq1DefectPeaksIndex & sheaveFreq1DefectProminenceIndex;
        % Get valid weights
        sheaveFreq1DefectWeights = sheaveFreq1Weights(sheaveFreq1ValidPeaksIndex);
        % Evaluate weights
        sheaveFreq1WeightsStatus = sum(sheaveFreq1DefectWeights);
    else
        sheaveFreq1WeightsStatus = 0;
    end
    
    % Combine weights statuses
    weightsStatus = sheaveFreq1WeightsStatus;
end

% ACCSPECTRUMEVALUATION function evaluates acceleration spectrum
function [weightsStatus] = accSpectrumEvaluation(spectrumDefectStruct, sheaveFreq1Tag, logProminenceThreshold)
    
    % Get driving sheave frequency data
    [sheaveFreq1Positions, ~, sheaveFreq1Magnitudes, sheaveFreq1LogProminence, sheaveFreq1Weights] = getTagPositions(spectrumDefectStruct, sheaveFreq1Tag);
    % Validation rule
    if ~isempty(sheaveFreq1Positions)
        % Preallocate defect peak index
        sheaveFreq1DefectPeaksIndex = false(length(sheaveFreq1Magnitudes), 1);
        % Evaluate the first harmonic
        sheaveFreq1DefectPeaksIndex(1) = true;
        % Evaluate higher harmonic
        sheaveFreq1DefectPeaksIndex(2 : end) = sheaveFreq1Magnitudes(2 : end) < sheaveFreq1Magnitudes(1);
        % Check the prominence threshold
        sheaveFreq1DefectProminenceThreshold = sheaveFreq1LogProminence > logProminenceThreshold;
        % Validate all peaks
        sheaveFreq1ValidPeaksIndex = sheaveFreq1DefectPeaksIndex & sheaveFreq1DefectProminenceThreshold;
        % Get valid weigths
        sheaveFreq1DefectWeights = sheaveFreq1Weights(sheaveFreq1ValidPeaksIndex);
        % Evaluate weights
        sheaveFreq1WeightsStatus = sum(sheaveFreq1DefectWeights);
    else
        sheaveFreq1WeightsStatus = 0;
    end
    
    % Combine weights statuses
    weightsStatus = sheaveFreq1WeightsStatus;
end

