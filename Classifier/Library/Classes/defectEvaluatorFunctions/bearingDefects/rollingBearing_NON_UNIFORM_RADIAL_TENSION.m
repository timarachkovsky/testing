% ROLLINGBEARINGN_NON_UNIFORM_RADIAL_TENSION function returns a status of
% rolling bearing defect "Non-uniform radial tension" (defectID = 1)
% 
% Defect requirements:
%     main:
%         1) 2k * shaftFreq
% 
% Developer:              P. Riabtsev
% Development date:       17-03-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = rollingBearing_NON_UNIFORM_RADIAL_TENSION(defectStruct, ~, ~)

    shaftFreqTag = {1}; % shaft frequency tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    accWeightsStatus = accSpectrumEvaluation(defectStruct.accelerationSpectrum, shaftFreqTag, logProminenceThreshold);
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    accEnvWeightsStatus = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, shaftFreqTag, logProminenceThreshold);
    
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
function [weightsStatus] = accSpectrumEvaluation(spectrumDefectStruct, shaftFreqTag, logProminenceThreshold)
    
    % Get shaft frequency data
    [~, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, shaftFreqTag);
    % Get valid weights
    defectWeights = weights(logProminence > logProminenceThreshold);
    % Evaluate weights
    weightsStatus = sum(defectWeights);
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum
function [weightsStatus] = accEnvSpectrumEvaluation(spectrumDefectStruct, shaftFreqTag, logProminenceThreshold)
    
    % Get shaft frequency data
    [positions, ~, magnitudes, logProminence, weights] = getTagPositions(spectrumDefectStruct, shaftFreqTag);
    % Validation rule
    % Find odd positions index
    oddPositionsIndex = logical(mod(positions, 2));
    % Get odd positions data
    oddPositions = positions(oddPositionsIndex);
    oddMagnitudes = magnitudes(oddPositionsIndex);
    % Get even positions data
    evenPositions = positions(~oddPositionsIndex);
    evenMagnitudes = magnitudes(~oddPositionsIndex);
    evenLogProminence = logProminence(~oddPositionsIndex);
    evenWeights = weights(~oddPositionsIndex);
    % Evaluate even positions
    if ~isempty(evenPositions)
        % Calculate odd positions
        previousPositions = evenPositions - 1;
        % Get magnitudes of existing odd positions
        previousMagnitudes = zeros(length(previousPositions), 1);
        [~, existPreviousPositions, existOddPositions] = intersect(previousPositions, oddPositions, 'stable');
        previousMagnitudes(existPreviousPositions) = oddMagnitudes(existOddPositions);
        % Validate even positions
        defectEvenIndex = (0.5 * evenMagnitudes) > previousMagnitudes;
        % Check the prominence threshold
        defectEvenProminenceIndex = evenLogProminence > logProminenceThreshold;
        % Validate all even positions
        validEvenIndex = defectEvenIndex & defectEvenProminenceIndex;
        % Get valid weights of even positions
        defectEvenWeights = evenWeights(validEvenIndex);
        % Evaluate weights of even positions
        weightsStatus = sum(defectEvenWeights);
    else
        weightsStatus = 0;
    end
end