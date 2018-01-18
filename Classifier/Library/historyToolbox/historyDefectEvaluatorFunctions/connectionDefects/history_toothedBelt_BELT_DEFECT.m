% HISTORY_TOOTHEDBELT_BELT_DEFECT function returns status of smooth belt defect
% of history
% 
% Defect requirements:
%     main:
%         1) k * beltFreq, k > 4;
%         2) k1 * meshingFreq +(-) k2 * beltFreq;
%     additional:
% 
% Developer:              Kosmach N.
% Development date:       07.06.2017
% Modified by:            Kosmach N.
% Modification date:      22.09.2017

function [similarityHistory, historyDangerous] = history_toothedBelt_BELT_DEFECT(defectStruct, myFiles)

    beltFreqTag = 28; % beltFreq tag
    modTag = [31 28]; % [meshingFreq +(-) beltFreq] tag
    
    % To evaluate acceleration spectrum
    [statusAcc, dangerAcc] = spectrumEvaluation(defectStruct.accelerationSpectrum, beltFreqTag, modTag, myFiles);
    
    % To evaluate envelope acceleration spectrum
    [statusEnv, dangerEnv] = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, beltFreqTag, modTag, myFiles);
    
    similarityHistory = max([statusAcc statusEnv]);
    similarityHistory(similarityHistory < 0) = 0;
    similarityHistory(similarityHistory > 1) = 1;
    
    historyDangerous = max([dangerAcc dangerEnv]);
end

% ACCENVSPECTRUMEVALUATION function calculate status to acceleration envelope domain
function [weightsStatus, darngerStatus] = spectrumEvaluation(domain, beltFreqTag, modTag, myFiles)
    
    % Get BPFO data
    [positions, ~, magnitudes, weights, validPositions] = getTagPositionsHistory(domain, beltFreqTag);
    
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
            defectEvenIndex = evenMagnitudes > previousMagnitudes;
            % Get valid weights of even positions
            defectEvenWeights = evenWeights(defectEvenIndex);
            % Get hisotry dangerous of even positions
            evenValidangerius = evenHistoryDangerous(defectEvenIndex);
            % Evaluate weights of even positions
            beltWeightsStatus = sum(bsxfun(@times, defectEvenWeights', evenValidangerius));
        else
            beltWeightsStatus = 0;
        end
        
        darngerStatus = sum(bsxfun(@times, weights', statusThresholdAndTrend));
    else
        beltWeightsStatus = 0;
        darngerStatus = 0;
    end
    
    resultStructMod = evaluationModulationHistory(domain, myFiles);
    % To find needed tag for mod
    positionsModTrue = bsxfun(@and, resultStructMod.mainTag == modTag(1), resultStructMod.sideBandTag == modTag(2));                                  
    % Evaluate weights for mod
    modWeightsStatus = sum(bsxfun(@times, resultStructMod.status(positionsModTrue), ...
                                             resultStructMod.weightMainPeak(positionsModTrue)));
                                         
    % Combine weights statuses
    if (modWeightsStatus ~= 0)
        weightsStatus = (beltWeightsStatus + modWeightsStatus) / 2;
        
        darngerStatus = (darngerStatus + modWeightsStatus) / 2;
    else
        weightsStatus = 0;
    end
end
