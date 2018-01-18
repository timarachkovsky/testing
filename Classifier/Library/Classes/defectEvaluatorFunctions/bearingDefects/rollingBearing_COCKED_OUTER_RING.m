% ROLLINGBEARINGN_COCKED_OUTER_RING function returns a status of
% rolling bearing defect "Misalignment of the Outer Ring" (defectID = 2)
% 
% Defect requirements:
%     main:
%         1) 2 * BPFO;
%     additional:
%         1) 2k * BPFO
% 
% Developer:              P. Riabtsev
% Development date:       04-04-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = rollingBearing_COCKED_OUTER_RING(defectStruct, ~, ~)
    
    BPFOTag = {13}; % BPFO tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    accWeightsStatus = accSpectrumEvaluation(defectStruct.accelerationSpectrum, BPFOTag, logProminenceThreshold);
        
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    accEnvWeightsStatus = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, BPFOTag, logProminenceThreshold);
    
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
function [weightsStatus] = accSpectrumEvaluation(spectrumDefectStruct, BPFOTag, logProminenceThreshold)
    
    % Get BPFO data
    [~, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, BPFOTag);
    % Get valid weights
    defectWeights = weights(logProminence > logProminenceThreshold);
    % Evaluate weights
    weightsStatus = sum(defectWeights);
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum
function [evenWeightsStatus] = accEnvSpectrumEvaluation(spectrumDefectStruct, BPFOTag, logProminenceThreshold)
    
    % Get BPFO data
    [positions, ~, magnitudes, logProminence, weights] = getTagPositions(spectrumDefectStruct, BPFOTag);
    % Validation rule
    if ~isempty(positions)
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
            % Calculate previous even positions
            previousEvenPositions = evenPositions - 1;
            % Get magnitudes of existing odd positions which are previous
            % the even positions
            previousEvenMagnitudes = zeros(length(previousEvenPositions), 1);
            [~, existPreviousEvenIndex, existOddIndex] = intersect(previousEvenPositions, oddPositions, 'stable');
            previousEvenMagnitudes(existPreviousEvenIndex) = oddMagnitudes(existOddIndex);
            % Validate even positions
            defectEvenIndex = (0.5 * evenMagnitudes) > previousEvenMagnitudes;
            % Check the prominence threshold
            defectEvenProminenceIndex = evenLogProminence > logProminenceThreshold;
            % Validate all even positions
            validEvenIndex = defectEvenIndex & defectEvenProminenceIndex;
            % Get valid weights of even positions
            defectEvenWeights = evenWeights(validEvenIndex);
            % Evaluate weights of even positions
            evenWeightsStatus = sum(defectEvenWeights);
        else
            evenWeightsStatus = 0;
        end
    else
        evenWeightsStatus = 0;
    end
end