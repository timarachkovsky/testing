% HISTORY_ROLLINGBEARINGN_NON_UNIFORM_RADIAL_TENSION function returns a status of
% rolling bearing defect "Non-uniform radial tension" with history (defectID = 1)
% 
% Defect requirements:
%     main:
%         1) 2k * shaftFreq
% 
% Developer:              Kosmach N.
% Development date:       15-05-2017
% Modified by:            
% Modification date:      

function [similarityHistory, historyDangerous] = history_rollingBearing_NON_UNIFORM_RADIAL_TENSION(defectStruct, ~)

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
    
    historyDangerous = max([dangerEnv, dangerAcc]);
end

% ACCSPECTRUMEVALUATION function calculate status to acceleration domain
function [weightsStatus, dangerAcc] = accSpectrumEvaluation(domain, shaftFreqTag)

    % Get shaft data
    [~, ~, ~, weights, validPositions] = getTagPositionsHistory(domain, shaftFreqTag);
    % To get peaks evaluated of history 
    statusThresholdAndTrend = ...
        evaluatorThresholdTrend(domain.trendResult(validPositions), domain.statusCurrentThreshold(validPositions));
    % Evaluate weights
    weightsStatus = sum(bsxfun(@times, weights', statusThresholdAndTrend));
    
    dangerAcc = weightsStatus;
end

% ACCENVSPECTRUMEVALUATION function calculate status to acceleration envelope domain
function [weightsStatus, dangerEnv] = accEnvSpectrumEvaluation(domain, shaftFreqTag)
    
    % Get BPFO data
    [positions, ~, magnitudes, weights, validPositions] = getTagPositionsHistory(domain, shaftFreqTag);
    
    % To get peaks evaluated of history 
    statusThresholdAndTrend = ...
        evaluatorThresholdTrend(domain.trendResult(validPositions), domain.statusCurrentThreshold(validPositions));
    
    % Validation rule
    if ~isempty(positions) || nnz(statusThresholdAndTrend)
        oddPositionsIndex = logical(mod(positions, 2));
        % Get odd positions data
        oddPositions = positions(oddPositionsIndex);
        oddMagnitudes = magnitudes(oddPositionsIndex);
        % Get even positions data
        evenPositions = positions(~oddPositionsIndex);
        evenMagnitudes = magnitudes(~oddPositionsIndex);
        evenWeights = weights(~oddPositionsIndex);
        evenHistoryDangerous = statusThresholdAndTrend(~oddPositionsIndex);
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
            % Get valid weights of even positions
            defectEvenWeights = evenWeights(defectEvenIndex);
            % Get hisotry dangerous of even positions
            evenValidangerius = evenHistoryDangerous(defectEvenIndex);
            % Evaluate weights of even positions
            weightsStatus = sum(bsxfun(@times, defectEvenWeights', evenValidangerius));
        else
            weightsStatus = 0;
        end
        
        dangerEnv = sum(bsxfun(@times, weights', statusThresholdAndTrend));
    else
        dangerEnv = 0;
        weightsStatus = 0;
    end
end