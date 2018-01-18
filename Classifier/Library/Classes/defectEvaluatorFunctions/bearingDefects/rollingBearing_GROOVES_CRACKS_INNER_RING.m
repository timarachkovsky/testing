% ROLLINGBEARINGN_GROOVES_CRACKS_INNER_RING function returns a status of
% rolling bearing defect "Grooves, Cracks on the Inner Ring" (defectID = 6)
% 
% Defect requirements:
%     main:
%         1) k1 * BPFI +(-) k2 * shaftFreq (in acceleration envelope
%         spectrum);
%         2) k * BPFI (in acceleration spectrum);
%     additional:
%         1) k * shaftFreq
% 
% Developer:              P. Riabtsev
% Development date:       06-04-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = rollingBearing_GROOVES_CRACKS_INNER_RING(defectStruct, ~, initialPeakTable)
    
    BPFITag = {14}; % BPFI tag
    modTag = {[14 1]}; % [BPFI +(-) shaftFreq] tag
    shaftFreqTag = {1}; % shaftFreq tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    accWeightsStatus = accSpectrumEvaluation(defectStruct.accelerationSpectrum, BPFITag, shaftFreqTag, logProminenceThreshold);
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    [accEnvWeightsStatus, defectStruct.accelerationEnvelopeSpectrum] = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, modTag, shaftFreqTag, ...
        logProminenceThreshold, initialPeakTable.accelerationEnvelopeSpectrum, defectStruct.basicFreqs);
    
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
function [weightsStatus] = accSpectrumEvaluation(spectrumDefectStruct, BPFITag, shaftFreqTag, logProminenceThreshold)
    
    % Get BPFI data
    [~, ~, ~, BPFILogProminence, BPFIWeights] = getTagPositions(spectrumDefectStruct, BPFITag);
    % Get valid weights
    BPFIDefectWeights = BPFIWeights(BPFILogProminence > logProminenceThreshold);
    % Evaluate weights
    BPFIWeightsStatus = sum(BPFIDefectWeights);
    
    % Get shaft frequency data
    [~, ~, ~, shaftFreqLogProminence, shaftFreqWeights] = getTagPositions(spectrumDefectStruct, shaftFreqTag);
    % Get valid weights
    shaftFreqDefectWeights = shaftFreqWeights(shaftFreqLogProminence > logProminenceThreshold);
    % Evaluate weights
    shaftFreqWeightsStatus = sum(shaftFreqDefectWeights);
    
    % Combine weights statuses
    if (BPFIWeightsStatus ~= 0)
        weightsStatus = (0.9 * BPFIWeightsStatus) + (0.1 * shaftFreqWeightsStatus);
    else
        weightsStatus = 0;
    end
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum
function [weightsStatus, spectrumDefectStruct] = accEnvSpectrumEvaluation(spectrumDefectStruct, modTag, shaftFreqTag, logProminenceThreshold, initialPeakTable, basicFreqs)
    
    % Get modulation data
    [modPositions, modEstimations, ~, modLogProminence, modWeights, spectrumDefectStruct] = getModulationEvaluationVector(spectrumDefectStruct, modTag, initialPeakTable, basicFreqs);
    % Validation rule
    if ~isempty(modPositions)
        % Evaluate peaks
        modDefectPeaksIndex = modEstimations == 1;
        % Check the prominence threshold
        modDefectProminenceIndex = modLogProminence > logProminenceThreshold;
        % Validate all peaks
        modValidPeaksIndex = modDefectPeaksIndex & modDefectProminenceIndex;
        % Get valid weights
        modDefectWeights = modWeights(modValidPeaksIndex);
        % Evaluate weights
        modWeightsStatus = sum(modDefectWeights);
    else
        modWeightsStatus = 0;
    end
    
    % Get shaft frequency data
    [~, ~, ~, shaftFreqLogProminence, shaftFreqWeights] = getTagPositions(spectrumDefectStruct, shaftFreqTag);
    % Get valid weights
    shaftFreqDefectWeights = shaftFreqWeights(shaftFreqLogProminence > logProminenceThreshold);
    % Evaluate weights
    shaftFreqWeightsStatus = sum(shaftFreqDefectWeights);
    
    % Combine weights statuses
    if (modWeightsStatus ~= 0)
        weightsStatus = (0.9 * modWeightsStatus) + (0.1 * shaftFreqWeightsStatus);
    else
        weightsStatus = 0;
    end
end