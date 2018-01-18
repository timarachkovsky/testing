% TOOTHEDBELT_BELT_DEFECT function returns status of toothed belt defect
% "Belt Defect" (defectID = 3)
% 
% Defect requirements:
%     main:
%         1) k * beltFreq, k > 4;
%         2) k1 * meshingFreq +(-) k2 * beltFreq;
%     additional:
% 
% Developer:              P. Riabtsev
% Development date:       06-06-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = toothedBelt_BELT_DEFECT(defectStruct, ~, initialPeakTable)
    
    beltFreqTag = {28}; % belt frequency tag
    modTag = {[31 28]}; % [meshingFreq +(-) beltFreq] tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    [accEnvWeightsStatus, defectStruct.accelerationEnvelopeSpectrum] = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, beltFreqTag, modTag, ...
        logProminenceThreshold, initialPeakTable.accelerationEnvelopeSpectrum, defectStruct.basicFreqs);
    
    % ACCELERATION SPECTRUM evaluation
    [accWeightsStatus, defectStruct.accelerationSpectrum] = spectrumEvaluation(defectStruct.accelerationSpectrum, beltFreqTag, modTag, ...
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

% SPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum 
function [weightsStatus, spectrumDefectStruct] = spectrumEvaluation(spectrumDefectStruct, beltFreqTag, modTag, logProminenceThreshold, initialPeakTable, basicFreqs)
    
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
    
    % Get modulation data
    [~, modEstimations, ~, modLogProminence, modWeights, spectrumDefectStruct] = getModulationEvaluationVector(spectrumDefectStruct, modTag, initialPeakTable, basicFreqs);
    % Get valid modulation weights
    modDefectWeights = modWeights((modLogProminence > logProminenceThreshold) & (modEstimations == 1));
    % Evaluate modulation weights
    modWeightsStatus = sum(modDefectWeights);
    
    % Combine weights statuses
    if (modWeightsStatus ~= 0)
        weightsStatus = (beltFreqEvenWeightsStatus + modWeightsStatus) / 2;
    else
        weightsStatus = 0;
    end
end