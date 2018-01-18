% INDUCTIONMOTOR_CRACKED_BROKEN_ROTOR_BARS function returns status of
% induction motor defect "Cracked or Broken Rotor Bars" (defectID = 3)
% 
% Defect requirements:
%     main:
%         1) k1 * shaftFreq +(-) k2 * polePassFreq, k1 < 6;
%     additional:
% 
% Developer:              P. Riabtsev
% Development date:       11-05-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = inductionMotor_CRACKED_BROKEN_ROTOR_BARS(defectStruct, ~, initialPeakTable)
    
    modTag = {[1 5]}; % [shaftFreq +(-) polePassFreq] tag
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
function [weightsStatus, spectrumDefectStruct] = accSpectrumEvaluation(spectrumDefectStruct, modTag, logProminenceThreshold, initialPeakTable, basicFreqs)
    
    % Get modulation data
    [positions, estimations, magnitudes, logProminence, weights, spectrumDefectStruct] = getModulationEvaluationVector(spectrumDefectStruct, modTag, initialPeakTable, basicFreqs);
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
        % Check modulation estimations
        defectEstimationsIndex = estimations == 1;
        % Check the prominence threshold
        defectProminenceIndex = logProminence > logProminenceThreshold;
        % Validate all peaks
        validPeaksIndex = defectPeaksIndex & defectProminenceIndex & defectEstimationsIndex;
        % Get valid weights
        defectWeights = weights(validPeaksIndex);
        % Evaluate weights
        weightsStatus = sum(defectWeights);
    else
        weightsStatus = 0;
    end
end

