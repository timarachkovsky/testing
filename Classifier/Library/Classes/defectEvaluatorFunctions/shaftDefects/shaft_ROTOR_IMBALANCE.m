% SHAFT_ROTOR_IMBALANCE function returns status of shaft defect "Rotor 
% imbalance" (defectID = 2)
% 
% Defect requirements:
%     main:
%         1) k * shaftFreq, k = 1;
%         2) There are no k * shaftFreq, k > 2;
%            1 * shaftFreq >> k * shaftFreq (k > 1)
% 
% Developer:              P. Riabtsev
% Development date:       09-03-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = shaft_ROTOR_IMBALANCE(defectStruct, equipmentClass, ~)

    shaftFreqTag = {1}; % shaft frequency tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    accWeightsStatus = accSpectrumEvaluation(defectStruct.accelerationSpectrum, shaftFreqTag, logProminenceThreshold);
    
    % DISPLACEMENT SPECTRUM evaluation
    [dispWeightsStatus, dispDefectPositions] = dispSpectrumEvaluation(defectStruct.displacementSpectrum, shaftFreqTag, logProminenceThreshold);
    
    % Combine results
    results = [accWeightsStatus, dispWeightsStatus];
    results(results < 0) = 0;
    results(results > 1) = 1;
    % Evaluate the defect similarity
    similarity = (min(results) + rms(results)) / 2;
    
    % VELOCITY SPECTRUM evaluation
    % Get shaft frequency data
    [velPositions, ~, velMagnitudes] = getTagPositions(defectStruct.velocitySpectrum, shaftFreqTag);
    % Validate peaks by displacement
    velDefectIndex = ismember(velPositions, dispDefectPositions);
    % Get valid magnitudes
    velDefectMagnitudes = velMagnitudes(velPositions(velDefectIndex) < 5);
    % Calculate rms magnitudes
    velRmsValue = rms(velDefectMagnitudes);
    % Evaluate magnitudes
    velRmsStatus = iso10816(velRmsValue, equipmentClass);
%     velMaxValue = max(velDefectMagnitudes);
%     velMaxStatus = iso10816(velMaxValue, equipmentClass);
    level = velRmsStatus;
end

% ACCSPECTRUMEVALUATION function evaluates acceleration spectrum
function [weightsStatus] = accSpectrumEvaluation(spectrumDefectStruct, shaftFreqTag, logProminenceThreshold)
    
    % Get shaft frequency data
    [positions, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, shaftFreqTag);
    if ~isempty(positions)
        if (positions(1) == 1)
            % Get valid weights
            defectWeights = weights(logProminence > logProminenceThreshold);
            % Evaluate weights
            weightsStatus = sum(defectWeights);
        else
            weightsStatus = 0;
        end
    else
        weightsStatus = 0;
    end
end

% DISPSPECTRUMEVALUATION function evaluates displacement spectrum
function [weightsStatus, defectPositions] = dispSpectrumEvaluation(spectrumDefectStruct, shaftFreqTag, logProminenceThreshold)
    
    % Get shaft frequency data
    [positions, ~, magnitudes, logProminence, weights] = getTagPositions(spectrumDefectStruct, shaftFreqTag);
    % Preallocate defect peak positions
    defectPositions = [];
    % Validation rule
    if ~isempty(positions)
        % Find the first harmonic index
        firstHarmonicIndex = find(positions == 1);
        if ~isempty(firstHarmonicIndex)
            % Preallocate defect peak index
            defectPeaksIndex = false(length(magnitudes), 1);
            % Find the first higher harmonic index
            firstHigherHarmonicIndex = firstHarmonicIndex + 1;
            % Evaluate higher harmonics
            defectPeaksIndex(firstHigherHarmonicIndex : end) = magnitudes(firstHigherHarmonicIndex : end) < (0.25 * magnitudes(firstHarmonicIndex));
            % Evaluate the first harmonic
            if length(magnitudes) > 1
                defectPeaksIndex(firstHarmonicIndex) = defectPeaksIndex(firstHigherHarmonicIndex);
            else
                defectPeaksIndex(firstHarmonicIndex) = true;
            end
            % Check the prominence threshold
            defectProminenceIndex = logProminence > logProminenceThreshold;
            % Valid all peaks
            validPeaksIndex = defectPeaksIndex & defectProminenceIndex;
            % Get valid data
            defectWeights = weights(validPeaksIndex);
            defectPositions = positions(validPeaksIndex);
            % Evaluate weights
            weightsStatus = sum(defectWeights);
        else
            weightsStatus = 0;
        end
    else
        weightsStatus = 0;
    end
end