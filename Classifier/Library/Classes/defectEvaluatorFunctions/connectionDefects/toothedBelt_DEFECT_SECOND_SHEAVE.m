% TOOTHEDBELT_DEFECT_SECOND_SHEAVE function returns status of toothed belt
% defect "Defect of the Second Sheave" (defectID = 2)
% 
% Defect requirements:
%     main:
%         1) k * sheaveFreq2, k > 4;
%         2) k1 * meshingFreq +(-) k2 * sheaveFreq2;
%     additional:
% 
% Developer:              P. Riabtsev
% Development date:       06-06-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = toothedBelt_DEFECT_SECOND_SHEAVE(defectStruct, ~, initialPeakTable)
    
    sheaveFreq2Tag = {30}; % driven sheave frequency tag
    modTag = {[31 30]}; % [meshingFreq +(-) sheaveFreq2] tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    [accEnvWeightsStatus, defectStruct.accelerationEnvelopeSpectrum] = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, sheaveFreq2Tag, modTag, ...
        logProminenceThreshold, initialPeakTable.accelerationEnvelopeSpectrum, defectStruct.basicFreqs);
    
    % ACCELERATION SPECTRUM evaluation
    [accWeightsStatus, defectStruct.accelerationSpectrum] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, sheaveFreq2Tag, modTag, ...
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

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum 
function [weightsStatus, spectrumDefectStruct] = accEnvSpectrumEvaluation(spectrumDefectStruct, sheaveFreq2Tag, modTag, logProminenceThreshold, initialPeakTable, basicFreqs)
    
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
    
    % Get modulation data
    [~, modEstimations, ~, modLogProminence, modWeights, spectrumDefectStruct] = getModulationEvaluationVector(spectrumDefectStruct, modTag, initialPeakTable, basicFreqs);
    % Get valid modulation weights
    modDefectWeights = modWeights((modLogProminence > logProminenceThreshold) & (modEstimations == 1));
    % Evaluate modulation weights
    modWeightsStatus = sum(modDefectWeights);
    
    % Combine weights statuses
    if (modWeightsStatus ~= 0)
        weightsStatus = (sheaveFreq2WeightsStatus + modWeightsStatus) / 2;
    else
        weightsStatus = 0;
    end
end

% ACCSPECTRUMEVALUATION function evaluates acceleration spectrum
function [weightsStatus, spectrumDefectStruct] = accSpectrumEvaluation(spectrumDefectStruct, sheaveFreq2Tag, modTag, logProminenceThreshold, initialPeakTable, basicFreqs)
    
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
    
    % Get modulation data
    [~, modEstimations, ~, modLogProminence, modWeights, spectrumDefectStruct] = getModulationEvaluationVector(spectrumDefectStruct, modTag, initialPeakTable, basicFreqs);
    % Get valid weights
    modDefectWeights = modWeights((modLogProminence > logProminenceThreshold) & (modEstimations == 1));
    % Evaluate weights
    modWeightsStatus = sum(modDefectWeights);
    
    % Combine weights statuses
    if (modWeightsStatus ~= 0)
        weightsStatus = (sheaveFreq2WeightsStatus + modWeightsStatus) / 2;
    else
        weightsStatus = 0;
    end
end

