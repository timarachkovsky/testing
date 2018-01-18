% FAN_BLADE_FAULTS function returns status of fan defect "Blade Faults"
% (defectID = 2)
% 
% Defect requirements:
%     main:
%         1) k1 * bladePass +(-) k2 * shaftFreq;
%         2) k * shaftFreq;
%     additional:
% 
% Developer:              P. Riabtsev
% Development date:       22-05-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = fan_BLADE_FAULTS(defectStruct, ~, initialPeakTable)
    
    modTag = {[32 1]}; % [bladePass +(-) shaftFreq] tag
    shaftFreqTag = {1}; % shaft frequency tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    [accEnvWeightsStatus, defectStruct.accelerationEnvelopeSpectrum] = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, modTag, shaftFreqTag, ...
        logProminenceThreshold, initialPeakTable.accelerationEnvelopeSpectrum, defectStruct.basicFreqs);
    
    % ACCELERATION SPECTRUM evaluation
    [accWeightsStatus, defectStruct.accelerationSpectrum] = spectrumEvaluation(defectStruct.accelerationSpectrum, modTag, shaftFreqTag, ...
        logProminenceThreshold, initialPeakTable.accelerationSpectrum, defectStruct.basicFreqs);
    
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
function [weightsStatus, spectrumDefectStruct] = spectrumEvaluation(spectrumDefectStruct, modTag, shaftFreqTag, logProminenceThreshold, initialPeakTable, basicFreqs)
    
    % Get modulation data
    [~, modEstimations, ~, modLogProminence, modWeights, spectrumDefectStruct] = getModulationEvaluationVector(spectrumDefectStruct, modTag, initialPeakTable, basicFreqs);
    % Get valid weights
    modDefectWeights = modWeights((modLogProminence > logProminenceThreshold) & (modEstimations == 1));
    % Evaluate weights
    modWeightsStatus = sum(modDefectWeights);
    
    % Get shaft frequency data
    [shaftFreqPositions, ~, shaftFreqMagnitudes, shaftFreqLogProminence, shaftFreqWeights] = getTagPositions(spectrumDefectStruct, shaftFreqTag);
    % Validation rule
    if ~isempty(shaftFreqPositions)
        % Preallocate defect peak index
        shaftFreqDefectPeaksIndex = false(length(shaftFreqMagnitudes), 1);
        % Evaluate the first peak
        % Check that the first peak is the maximum peak
        shaftFreqDefectPeaksIndex(1) = shaftFreqMagnitudes(1) == max(shaftFreqMagnitudes);
        % Evaluate higher harmonics
        if shaftFreqDefectPeaksIndex(1)
            for peakNumber = 2 : 1 : length(shaftFreqMagnitudes)
                % Check that current peak is less than previous peaks
                isLessHigherHarmonic = all(shaftFreqMagnitudes(peakNumber) < shaftFreqMagnitudes(shaftFreqDefectPeaksIndex));
                % Check that current peak is greater than 25% of previous
                % peaks
                isGreaterHigherHarmonic = any(shaftFreqMagnitudes(peakNumber) > (0.25 * shaftFreqMagnitudes(shaftFreqDefectPeaksIndex)));
                % Validate current peak
                shaftFreqDefectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
            end
        end
        % Check the prominence threshold
        shaftFreqDefectProminenceIndex = shaftFreqLogProminence > logProminenceThreshold;
        % Validate all peaks
        shaftFreqValidPeaksIndex = shaftFreqDefectPeaksIndex & shaftFreqDefectProminenceIndex;
        % Get valid weights
        shaftFreqDefectWeights = shaftFreqWeights(shaftFreqValidPeaksIndex);
        % Evaluate weights
        shaftFreqWeightsStatus = sum(shaftFreqDefectWeights);
    else
        shaftFreqWeightsStatus = 0;
    end
    
    % Combine weights statuses
    if (modWeightsStatus ~= 0)
        weightsStatus = (modWeightsStatus + shaftFreqWeightsStatus) / 2;
    else
        weightsStatus = 0;
    end
end

