% SMOOTHBELT_BELT_DEFECT function returns status of smooth belt defect
% "Belt Defect" (defectID = 3)
% 
% Defect requirements:
%     main:
%         1) k * beltFreq, k > 4;
%     additional:
% 
% Developer:              P. Riabtsev
% Development date:       06-06-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = smoothBelt_BELT_DEFECT(defectStruct, ~, ~)
    
    beltFreqTag = {28}; % belt frequency tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    accEnvWeightsStatus = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, beltFreqTag, logProminenceThreshold);
    
    % ACCELERATION SPECTRUM evaluation
    accWeightsStatus = spectrumEvaluation(defectStruct.accelerationSpectrum, beltFreqTag, logProminenceThreshold);
    
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
function [weightsStatus] = spectrumEvaluation(spectrumDefectStruct, beltFreqTag, logProminenceThreshold)
    
    % Get belt frequency data
    [beltFreqPositions, ~, beltFreqMagnitudes, beltFreqLogProminence, beltFreqWeights] = getTagPositions(spectrumDefectStruct, beltFreqTag);
    % Validation rule
    if ~isempty(beltFreqPositions)
        % Find odd positions index
        beltFreqOddPositionsIndex = logical(mod(beltFreqPositions, 2));
        % Get odd positions index
        beltFreqOddPositions = beltFreqPositions(beltFreqOddPositionsIndex);
        beltFreqOddMagnitudes = beltFreqMagnitudes(beltFreqOddPositionsIndex);
        % Get even positions data
        beltFreqEvenPositions = beltFreqPositions(~beltFreqOddPositionsIndex);
        beltFreqEvenMagnitudes = beltFreqMagnitudes(~beltFreqOddPositionsIndex);
        beltFreqEvenLogProminence = beltFreqLogProminence(~beltFreqOddPositionsIndex);
        beltFreqEvenWeights = beltFreqWeights(~beltFreqOddPositionsIndex);
        % Evaluate even positions
        if ~isempty(beltFreqEvenPositions)
            % Calculate previous even positions
            previousEvenPositions = beltFreqEvenPositions - 1;
            % Get magnitudes of existing odd positions which are previous the
            % enev positions
            previousEvenMagnitudes = zeros(length(previousEvenPositions), 1);
            [~, existPreviousEvenIndex, existOddIndex] = intersect(previousEvenPositions, beltFreqOddPositions, 'stable');
            previousEvenMagnitudes(existPreviousEvenIndex) = beltFreqOddMagnitudes(existOddIndex);
            % Validate even positions
            beltFreqDefectEvenIndex = beltFreqEvenMagnitudes > previousEvenMagnitudes;
            % Check the prominence threshold
            beltFreqDefectEvenProminenceIndex = beltFreqEvenLogProminence > logProminenceThreshold;
            % Validate all even positions
            beltFreqValidEvenIndex = beltFreqDefectEvenIndex & beltFreqDefectEvenProminenceIndex;
            % Get valid weights of even positions
            beltFreqDefectEvenWeights = beltFreqEvenWeights(beltFreqValidEvenIndex);
            % Evaluate weights of even positions
            beltFreqEvenWeightsStatus = sum(beltFreqDefectEvenWeights);
        else
            beltFreqEvenWeightsStatus = 0;
        end
    else
        beltFreqEvenWeightsStatus = 0;
    end
    
    % Combine weights statuses
    weightsStatus = beltFreqEvenWeightsStatus;
end