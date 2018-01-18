% FAN_PUMP_CAVITATION_FLOW_TURBULENCE function returns status of fan defect
% "Pump Cavitation or Flow Turbulence" (defectID = 3)
% 
% Defect requirements:
%     main:
%         1) k * bladePass;
%     additional:
% 
% Developer:              P. Riabtsev
% Development date:       22-05-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = fan_PUMP_CAVITATION_FLOW_TURBULENCE(defectStruct, ~, ~)
    
    bladePassTag = {32}; % Blade pass frequency tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    accEnvWeightsStatus = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, bladePassTag, logProminenceThreshold);
    
    % ACCELERATION SPECTRUM evaluation
    accWeightsStatus = spectrumEvaluation(defectStruct.accelerationSpectrum, bladePassTag, logProminenceThreshold);
    
    % Combine results
    results = [accEnvWeightsStatus, accWeightsStatus];
    results(results < 0) = 0;
    results(results > 1) = 1;
    % Evaluate the defect similarity
    similarity = (min(results) + rms(results)) / 2;
    
    % The level is not evaluated
    level = 'NaN';
end

% SPECTRUMEVALUATION function evaluates spectrum 
function [weightsStatus] = spectrumEvaluation(spectrumDefectStruct, bladePassTag, logProminenceThreshold)
    
    % Get blade pass frequency data
    [positions, ~, magnitudes, logProminence, weights] = getTagPositions(spectrumDefectStruct, bladePassTag);
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