% ROLLINGBEARING_WEAR_INNER_RING function returns status of rolling bearing
% defect "Wear of the inner ring" (defectID = 5)
% 
% Defect requirements:
%     main:
%         1) k * shaftFreq;
%     additional:
%         1) BPFI;
% 
% Developer:              P. Riabtsev
% Development date:       05-04-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = rollingBearing_WEAR_INNER_RING(defectStruct, ~, ~)
    
    shaftFreqTag = {1}; % shaft frequency tag
    BPFITag = {14}; % BPFI tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    accWeightsStatus = accSpectrumEvaluation(defectStruct.accelerationSpectrum, shaftFreqTag, BPFITag, logProminenceThreshold);
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    accEnvWeightsStatus = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, shaftFreqTag, BPFITag, logProminenceThreshold);
    
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
function [weightsStatus] = accSpectrumEvaluation(spectrumDefectStruct, shaftFreqTag, BPFITag, logProminenceThreshold)
    
    % Get shaft frequency data
    [~, ~, ~, shaftFreqLogProminence, shaftFreqWeights] = getTagPositions(spectrumDefectStruct, shaftFreqTag);
    % Get valid weights
    shaftFreqDefectWeights = shaftFreqWeights(shaftFreqLogProminence > logProminenceThreshold);
    % Evaluate weights
    shaftFreqWeightsStatus = sum(shaftFreqDefectWeights);
    
    % Get BPFI data
    [~, ~, ~, BPFILogProminence, BPFIWeights] = getTagPositions(spectrumDefectStruct, BPFITag);
    % Get valid weights
    BPFIDefectWeights = BPFIWeights(BPFILogProminence > logProminenceThreshold);
    % Evaluate weights
    BPFIWeightsStatus = sum(BPFIDefectWeights);
    
    % Combine weights statuses
    if (BPFIWeightsStatus ~= 0)
        weightsStatus = (shaftFreqWeightsStatus + BPFIWeightsStatus) / 2;
    else
        weightsStatus = 0;
    end
end

% ACCENVSPECTRUMEVALUATION functuin evaluates acceleration envelope
% spectrum
function [weightsStatus] = accEnvSpectrumEvaluation(spectrumDefectStruct, shaftFreqTag, BPFITag, logProminenceThreshold)
    
    % Get shaft frequency data
    [shaftFreqPositions, ~, shaftFreqMagnitudes, shaftFreqLogProminence, shaftFreqWeights] = getTagPositions(spectrumDefectStruct, shaftFreqTag);
    % Validation rule
    if ~isempty(shaftFreqPositions)
        % Preallocate defect peaks index
        shaftFreqDefectPeaksIndex = false(length(shaftFreqMagnitudes), 1);
        % Evalaute the first peak
        shaftFreqDefectPeaksIndex(1) = shaftFreqMagnitudes(1) == max(shaftFreqMagnitudes);
        % Evaluate the higher harmonics
        for peakNumber = 2 : 1 : length(shaftFreqMagnitudes)
            % Check that current peak is less than of previous defect peaks
            isLessHigherHarmonic = all(shaftFreqMagnitudes(peakNumber) < shaftFreqMagnitudes(shaftFreqDefectPeaksIndex));
            % Check that current peak is greater than 75% of previous peak
            isGreaterHigherHarmonic = any(shaftFreqMagnitudes(peakNumber) > (0.75 * shaftFreqMagnitudes(shaftFreqDefectPeaksIndex)));
            % Validate current peak
            shaftFreqDefectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
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
    
    % Get BPFI data
    [BPFIPositions, ~, ~, BPFILogProminence, BPFIWeights] = getTagPositions(spectrumDefectStruct, BPFITag);
    % Validation rule
    if ~isempty(BPFIPositions)
        % Get valid weights
        BPFIDefectWeights = BPFIWeights(BPFILogProminence > logProminenceThreshold);
        % Evaluate weights
        BPFIWeightsStatus = sum(BPFIDefectWeights);
    else
        BPFIWeightsStatus = 0;
    end
    
    % Combine weights statuses
    if (BPFIWeightsStatus ~= 0)
        weightsStatus = (shaftFreqWeightsStatus + BPFIWeightsStatus) / 2;
    else
        weightsStatus = 0;
    end
end