% ROLLINGBEARING_ROTATING_LOOSENESS function returns a status of rolling
% bearing defect "Rotating looseness" (defectID = 11)
% 
% Defect requirements:
%     main:
%         1) k * shaftFreq, k < 10;
%         2) [2, 4, 6, 8] * shaftFreq > [3, 5, 7, 9] * shaftFreq
%         (in acceleration envelope spectrum)
%     additional:
%         1) k * 0.5 * shaftFreq, k < 10
% 
% Developer:              P. Riabtsev
% Development date:       30-03-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = rollingBearing_ROTATING_LOOSENESS(defectStruct, ~, ~)

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
    [positions, ~, magnitudes, logProminence, weights] = getTagPositions(spectrumDefectStruct, shaftFreqTag);
    % Validation rule
    if ~isempty(positions)
        % Find subharmonics index
        subharmonicIndex = logical(mod(positions / 0.5, 2));
        % Get main harmonics data
        mainPositions = positions(~subharmonicIndex);
        mainMagnitudes = magnitudes(~subharmonicIndex);
        mainLogProminence = logProminence(~subharmonicIndex);
        mainWeights = weights(~subharmonicIndex);
        % Get subharmonics data
        subPositions = positions(subharmonicIndex);
        subMagnitudes = magnitudes(subharmonicIndex);
        subLogProminence = logProminence(subharmonicIndex);
        subWeights = weights(subharmonicIndex);
        % Find odd positions index (without the first harmonic)
        oddPositionsIndex = logical(mod(mainPositions, 2));
        % Get odd positions data
        oddPositions = mainPositions(oddPositionsIndex);
        oddMagnitudes = mainMagnitudes(oddPositionsIndex);
        oddWeights = mainWeights(oddPositionsIndex);
        % Find even positions index (without the first harmonic)
        evenPositionsIndex = ~logical(mod(mainPositions, 2));
        % Get even positions data
        evenPositions = mainPositions(evenPositionsIndex);
        evenMagnitudes = mainMagnitudes(evenPositionsIndex);
        evenWeights = mainWeights(evenPositionsIndex);
        % Evaluate main harmonics
        if ~isempty(mainPositions)
            % Preallocate defect peak index
            defectMainIndex1 = false(length(mainMagnitudes), 1);
            % Calculate previos odd positions
            previousOddPositions = oddPositions - 1;
            % Get magnitudes of existing even positions which are previous
            % the odd positions
            previousOddMagnitudes = zeros(length(previousOddPositions), 1);
            [~, existPreviousOddPositions, existEvenPositions] = intersect(previousOddPositions, evenPositions);
            previousOddMagnitudes(existPreviousOddPositions) = evenMagnitudes(existEvenPositions);
            % Compare the first harmonic with the second harmonic
            if ~isempty(evenMagnitudes(evenPositions == 2))
                previousOddMagnitudes(previousOddPositions == 0) = evenMagnitudes(evenPositions == 2);
            end
            % Validate odd positions
            defectOddIndex = oddMagnitudes > previousOddMagnitudes;
            % Get valid weights of odd positions
            defectOddWeights = oddWeights(defectOddIndex);
            % Evaluate weights of odd positions
            oddWeightsStatus = sum(defectOddWeights);
            % Calculate previous even positions
            previousEvenPositions = evenPositions - 1;
            % Get magnitudes of existing odd positions which are previous
            % the even positions
            previousEvenMagnitudes = zeros(length(previousEvenPositions), 1);
            [~, existPreviousEvenPositions, existOddPositions] = intersect(previousEvenPositions, oddPositions);
            previousEvenMagnitudes(existPreviousEvenPositions) = oddMagnitudes(existOddPositions);
            % Validate even positions
            defectEvenIndex = evenMagnitudes > previousEvenMagnitudes;
            % Get valid weights of even positions
            defectEvenWeights = evenWeights(defectEvenIndex);
            % Evaluate weights of even positions
            evenWeightsStatus = sum(defectEvenWeights);
            % Combine valid odd and even index
            if oddWeightsStatus > evenWeightsStatus
                % Combine valid odd and inverted even index
                defectMainIndex1(oddPositionsIndex) = defectOddIndex;
                defectMainIndex1(evenPositionsIndex) = ~defectEvenIndex;
            else
                % Combine valid inverted odd and even index
                defectMainIndex1(oddPositionsIndex) = ~defectOddIndex;
                defectMainIndex1(evenPositionsIndex) = defectEvenIndex;
            end
            % Check the prominence threshold
            defectMainProminenceIndex = mainLogProminence > logProminenceThreshold;
            % Validate all main harmonics
            validMainIndex = defectMainIndex1 & defectMainProminenceIndex;
            % Get valid weights of main harmonics
            defectMainWeights = mainWeights(validMainIndex);
            % Evaluate weights of main harmonics
            mainWeightsStatus = sum(defectMainWeights);
        else
            mainWeightsStatus = 0;
        end
        % Evaluate subharmonics
        if ~isempty(subPositions)
            % Calculate positions of main harmonics
            nextPositions = subPositions + 0.5;
            % Get magnitude of existing main harmonics
            nextMagnitudes = zeros(length(nextPositions), 1);
            [~, existNextPositions, existMainPositions] = intersect(nextPositions, mainPositions);
            nextMagnitudes(existNextPositions) = mainMagnitudes(existMainPositions);
            % Validate peaks
            defectSubIndex = subMagnitudes < (0.5 * nextMagnitudes);
            % Check the prominence threshold
            defectSubProminenceIndex = subLogProminence > logProminenceThreshold;
            % Validate all subharmonics
            validSubIndex = and(defectSubIndex, defectSubProminenceIndex);
            % Get valid weights of subharmonics
            defectSubWeights = subWeights(validSubIndex);
            % Evaluate weights of subharmonics
            subWeightsStatus = sum(defectSubWeights);
        else
            subWeightsStatus = 0;
        end
        
        % Combine acceleration statuses
        weightsStatus = mainWeightsStatus + (0.2 * subWeightsStatus);
    else
        weightsStatus = 0;
    end
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleraiont envelope
% spectrum
function [weightsStatus] = accEnvSpectrumEvaluation(spectrumDefectStruct, shaftFreqTag, logProminenceThreshold)
    
    % Get shaft frequency data
    [positions, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, shaftFreqTag);
    subharmonicIndex = logical(mod(positions / 0.5, 2));
    % Get main harmonics data
    mainLogProminence = logProminence(~subharmonicIndex);
    mainWeights = weights(~subharmonicIndex);
    % Get subharmonics data
    subLogProminence = logProminence(subharmonicIndex);
    subWeights = weights(subharmonicIndex);
    % Get valid weights of main harmonics
    mainDefectWeights = mainWeights(mainLogProminence > logProminenceThreshold);
    % Evaluate weights of main harmonics
    mainWeightsStatus = sum(mainDefectWeights);
    % Get valid weights of subharmonics
    subDefectWeights = subWeights(subLogProminence > logProminenceThreshold);
    % Evaluate weights of subharmonics
    subWeightsStatus = sum(subDefectWeights);
    
    % Combine weights statuses
    weightsStatus = mainWeightsStatus + (0.2 * subWeightsStatus);
end