% SHAFT_SHAFT_RUN_OUT function returns a status of shaft defect "Shaft
% run-out" (defectID = 1)
% 
% Defect requirements:
%     main:
%         1) k * shaftFreq, k < 10;
%         2) k * shaftFreq < (k - 1) * shaftFreq
% 
% Developer:              P. Riabtsev
% Development date:       09-03-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = shaft_SHAFT_RUN_OUT(defectStruct, equipmentClass, ~)

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
    velDefectMagnitudes = velMagnitudes(velPositions(velDefectIndex) < 10);
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
    [~, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, shaftFreqTag);
    % Get valid weights
    defectWeights = weights(logProminence > logProminenceThreshold);
    % Evaluate weights
    weightsStatus = sum(defectWeights);
end

% DISPSPECTRUMEVALUATION function evaluates displacement spectrum
function [weightsStatus, defectPositions] = dispSpectrumEvaluation(spectrumDefectStruct, shaftFreqTag, logProminenceThreshold)
    
    % Get shaft frequency data
    [positions, ~, magnitudes, logProminence, weights] = getTagPositions(spectrumDefectStruct, shaftFreqTag);
    % Preallocate defect peak positions
    defectPositions = [];
    % Validation rule
    if ~isempty(positions)
        % Preallocate defect peak index
        defectPeaksIndex = false(length(magnitudes), 1);
        % Evaluate the first harmonic
        firstHarmonicIndex = find(positions == 1);
        if ~isempty(firstHarmonicIndex)
            % Validate the first hatmonic
            defectPeaksIndex(firstHarmonicIndex) = magnitudes(firstHarmonicIndex) == max(magnitudes(positions ~= 2));
            % Evaluate higher harmonics
            for peakNumber = firstHarmonicIndex + 1 : 1 : length(magnitudes)
                % Check that current peak is less than 75% of previous peaks
                isLessHigherHarmonic = all(magnitudes(peakNumber) < (0.75 * magnitudes(defectPeaksIndex)));
                % Check that current peak is greater than 25% of previous peaks
                isGreaterHigherHarmonic = any(magnitudes(peakNumber) > (0.25 * magnitudes(defectPeaksIndex)));
                % Validate current peak
                defectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
            end
        end
        % Check the prominence threshold
        defectProminenceIndex = logProminence > logProminenceThreshold;
        % Validate all peaks
        validPeaksIndex = defectPeaksIndex & defectProminenceIndex;
        % Get valid data
        defectWeights = weights(validPeaksIndex);
        defectPositions = positions(validPeaksIndex);
        % Evaluate weights
        weightsStatus = sum(defectWeights);
    else
        weightsStatus = 0;
    end
end