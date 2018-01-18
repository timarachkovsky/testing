% HISTORY_ROLLINGBEARING_ROTATING_LOOSENESS function returns a status of rolling
% bearing defect "Rotating looseness" with history(defectID = 11)
% 
% Defect requirements:
%     main:
%         1) k * shaftFreq, k < 10;
%         2) [2, 4, 6, 8] * shaftFreq > [3, 5, 7, 9] * shaftFreq
%         (in acceleration envelope spectrum)
%     additional:
%         1) k * 0.5 * shaftFreq, k < 10
% 
% Developer:              Kosmach N.
% Development date:       12-05-2017
% Modified by:            Kosmach N.
% Modification date:      14-09-2017 

function [similarityHistory, historyDangerous] = history_rollingBearing_ROTATING_LOOSENESS(defectStruct,~)

    shaftFreqTag = 1; % shaftFreq tag

    % To evaluate acceleration spectrum
    [statusAcc, dangerAcc] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, shaftFreqTag);
    
    % To evaluate envelope acceleration spectrum
    [statusEnv, dangerEnv] = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, shaftFreqTag);
    
    results = [statusAcc statusEnv];
    results(results < 0) = 0;
    results(results > 1) = 1;
    if statusAcc > statusEnv
        similarityHistory = (min(results) + rms(results)) / 2;
    else
        similarityHistory = statusEnv;
    end
    
    historyDangerous = max([dangerAcc dangerEnv]);
end

% ACCSPECTRUMEVALUATION function calculate status to acceleration domain
function [weightsStatus, dangerAcc] = accSpectrumEvaluation(domain, shaftFreqTag)

    % Get shaft frequency data
    [positions, ~, magnitudes, weights, validPositions] = getTagPositionsHistory(domain, shaftFreqTag);
    
    % To get peaks evaluated of history 
    statusThresholdAndTrend = ...
        evaluatorThresholdTrend(domain.trendResult(validPositions), domain.statusCurrentThreshold(validPositions));
    
    % Validation rule
    if ~isempty(positions)
        % Find subharmonics index
        subharmonicIndex = logical(mod(positions / 0.5, 2));
        % Get main harmonics data
        mainPositions = positions(~subharmonicIndex);
        mainMagnitudes = magnitudes(~subharmonicIndex);
        mainWeights = weights(~subharmonicIndex);
        mainStatusHistory = statusThresholdAndTrend(~subharmonicIndex);
        % Get subharmonics data
        subPositions = positions(subharmonicIndex);
        subMagnitudes = magnitudes(subharmonicIndex);
        subWeights = weights(subharmonicIndex);
        subStatusHistory = statusThresholdAndTrend(subharmonicIndex);
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
            % Get valid weights of main harmonics
            defectMainWeights = mainWeights(defectMainIndex1);
            % Get valid history dangerous of main harmonics
            defectMainHistory = mainStatusHistory(defectMainIndex1);
            % Evaluate weights of main harmonics
            mainWeightsStatus = sum(bsxfun(@times, defectMainHistory, defectMainWeights'));
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
            % Get valid weights of subharmonics
            defectSubWeights = subWeights(defectSubIndex);
            % Get valid history dangerous of main harmonics
            defectSubHistory = subStatusHistory(defectSubIndex);
            % Evaluate weights of subharmonics
            subWeightsStatus = sum(bsxfun(@times, defectSubHistory, defectSubWeights'));
        else
            subWeightsStatus = 0;
        end
        
        % Combine acceleration statuses
        weightsStatus = mainWeightsStatus + (0.2 * subWeightsStatus);
        
        dangerAcc = sum(bsxfun(@times, weights', statusThresholdAndTrend));
    else
        dangerAcc = 0;
        weightsStatus = 0;
    end
end

% ACCENVSPECTRUMEVALUATION function calculate status to acceleration envelope domain
function [weightsStatus, dangerEnv] = accEnvSpectrumEvaluation(domain, shaftFreqTag)
    
    % Get shaft frequency data
    [positions, ~, ~, weights, validPositions] = getTagPositionsHistory(domain, shaftFreqTag);
    
    % To get peaks evaluated of history 
    statusThresholdAndTrend = ...
        evaluatorThresholdTrend(domain.trendResult(validPositions), domain.statusCurrentThreshold(validPositions));
    
    subharmonicIndex = logical(mod(positions / 0.5, 2));
    % Get main harmonics data
    mainWeights = weights(~subharmonicIndex);
    mainStatusHistory = statusThresholdAndTrend(~subharmonicIndex);
    % Get subharmonics data
    subWeights = weights(subharmonicIndex);
    subStatusHistory = statusThresholdAndTrend(subharmonicIndex);
    % Get valid weights of main harmonics
    mainWeightsStatus = sum(bsxfun(@times, mainWeights', mainStatusHistory));
    % Evaluate weights of subharmonics
    subWeightsStatus = sum(bsxfun(@times, subWeights', subStatusHistory));
    
    % Combine weights statuses
    weightsStatus = mainWeightsStatus + (0.2 * subWeightsStatus);
    
    dangerEnv = sum(bsxfun(@times, weights', statusThresholdAndTrend));
end