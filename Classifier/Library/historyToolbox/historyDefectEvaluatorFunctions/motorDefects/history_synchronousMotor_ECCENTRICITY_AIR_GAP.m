% SYNCHRONOUSMOTOR_ECCENTRICITY_AIR_GAP function returns status of
% synchronous motor defect of history
% 
% Defect requirements:
%     main:
%         1) k * twiceLineFreq, k < 5;
%     additional:
%         1) [1, 2] * shaftFreq;
% 
% Developer:              Kosmach N.
% Development date:       06.06.2017
% Modified by:            Kosmach N.
% Modification date:      25.09.2017

function [similarityHistory, historyDangerous] = history_synchronousMotor_ECCENTRICITY_AIR_GAP(defectStruct,~)

    shaftFreqTag = 1; % shaft frequency tag
    TLFTag = 3; % twice line frequency tag

    [similarityHistory, historyDangerous] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, TLFTag, shaftFreqTag);
end

% ACCSPECTRUMEVALUATION function calculate status to acceleration domain
function [weightsStatus, historyDangerous] = accSpectrumEvaluation(domain, TLFTag, shaftFreqTag)
    
    % Get TLF data
    [positions, ~, magnitudes, weights, validPositions] = getTagPositionsHistory(domain, TLFTag);
    
    % To get peaks evaluated of history 
    statusThresholdAndTrend = ...
        evaluatorThresholdTrend(domain.trendResult(validPositions), domain.statusCurrentThreshold(validPositions));
    
    % Validation rule
    if ~isempty(positions) || nnz(statusThresholdAndTrend)
        % Preallocate defect peaks index
        defectPeaksIndex = false(length(magnitudes), 1);
        % Evaluate the first peak
        % Check that the first peak is greater than 91% of the maximum peak
        defectPeaksIndex(1) = magnitudes(1) ==  max(magnitudes);
        % Evaluate higher harmonics
        if defectPeaksIndex(1)
            for peakNumber = 2 : 1 : length(magnitudes)
                % Check that current peak is less than 110% of previous peaks
                isLessHigherHarmonic = all(magnitudes(peakNumber) < magnitudes(defectPeaksIndex));
                % Check that current peak is greater than 90% of previous peaks
                isGreaterHigherHarmonic = any(magnitudes(peakNumber) > (0.25 * magnitudes(defectPeaksIndex)));
                % Validate current peak
                defectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
            end
        end
        % Get valid weights
        defectWeights = weights(defectPeaksIndex)';
        statusThresholdAndTrendWithPattern = statusThresholdAndTrend(defectPeaksIndex);
        % Evaluate weights
        weightsStatus = sum(bsxfun(@times, defectWeights, statusThresholdAndTrendWithPattern));
        
        historyDangerous = sum(bsxfun(@times, weights', statusThresholdAndTrend));
    else
        weightsStatus = 0;
        historyDangerous = 0;
    end
    
    % Get shaft data
    [~, ~, ~, weightsShaft, validPositionsShaft] = getTagPositionsHistory(domain, shaftFreqTag);
    
    % To get peaks evaluated of history 
    statusThresholdAndTrendShaft = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsShaft), domain.statusCurrentThreshold(validPositionsShaft));
    
    shaftFreqWeightsStatus = sum(bsxfun(@times, weightsShaft', statusThresholdAndTrendShaft));
    
    % Combine weights statuses
    if weightsStatus ~= 0
        weightsStatus = weightsStatus + (0.2 * shaftFreqWeightsStatus);
    end
    
    if historyDangerous ~= 0
        historyDangerous = historyDangerous + (0.2 * shaftFreqWeightsStatus);
    end
end
