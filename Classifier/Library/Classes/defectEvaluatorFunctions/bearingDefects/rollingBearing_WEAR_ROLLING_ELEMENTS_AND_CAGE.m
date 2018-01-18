% ROLLINGBEARINGN_WEAR_ROLLING_ELEMENTS_AND_CAGE function returns a status
% of rolling bearing defect "Wear the rolling elements and cage" (defectID
% = 7)
% 
% Defect requirements:
%     main:
%         1) FTF;
%         2) shaftFreq - FTF
%     additional:
%         1) k * FTF;
%         2) k * (shaftFreq - FTF)
% 
% Developer:              P. Riabtsev
% Development date:       30-03-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = rollingBearing_WEAR_ROLLING_ELEMENTS_AND_CAGE(defectStruct, ~, ~)

    FTFTag = {11}; % FTF tag
    difTag = {33}; % (shaftFTF) tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    [accEnvWeightsStatus] = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, FTFTag, difTag, logProminenceThreshold);
    
    % Combine results
    results = accEnvWeightsStatus;
    results(results < 0) = 0;
    results(results > 1) = 1;
    % Evaluate the defect similarity
    similarity = (min(results) + rms(results)) / 2;
    
    % The level is not evaluated
    level = 'NaN';
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration spectrum
function [weightsStatus] = accEnvSpectrumEvaluation(spectrumDefectStruct, FTFTag, difTag, logProminenceThreshold)
    
    % Get FTF data
    [FTFPositions, ~, ~, FTFLogProminence, FTFWeights] = getTagPositions(spectrumDefectStruct, FTFTag);
    % Validation rule
    if ~isempty(FTFPositions)
        % Check the prominence threshold
        defectFTFProminenceIndex = FTFLogProminence > logProminenceThreshold;
        % Get valid weights
        defectFTFWeights = FTFWeights(defectFTFProminenceIndex);
        % Evaluate weights
        FTFWeightsStatus = sum(defectFTFWeights);
    else
        FTFWeightsStatus = 0;
    end
    
    % Get data of harmonics of frequency difference
    [difPositions, ~, ~, difLogProminence, difWeights] = getTagPositions(spectrumDefectStruct, difTag);
    % Validation rule
    if ~isempty(difPositions)
        % Check the prominence threshold
        defectDifProminenceIndex = difLogProminence > logProminenceThreshold;
        % Get valid weights
        defectDifWeights = difWeights(defectDifProminenceIndex);
        % Evaluate weights
        difWeightsStatus = sum(defectDifWeights);
    else
        difWeightsStatus = 0;
    end
    
    % Combine weights statuses
    weightsStatus = FTFWeightsStatus + (0.25 * difWeightsStatus);
end