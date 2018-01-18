% HISTORY_COUPLING_COUPLING_DEFECT function returns a status of coupling defect
% of history 
% 
% Defect requirements:
%     main:
%         1) k * shaftFreq, k < 6 (acceleration spectrum)
% 
% Developer:              Kosmach N.
% Development date:       08.06.2017
% Modified by:            Kosmach N.
% Modification date:      19.09.2017

function [similarityHistory, historyDangerous] = history_coupling_COUPLING_DEFECT(defectStruct, ~)

    shaftFreqTag = 1; % shaft frequency tag

    % To evaluate acceleration spectrum
    [statusAcc, dangerAcc] = spectrumEvaluation(defectStruct.accelerationSpectrum, shaftFreqTag);
    
    % To evaluate envelope acceleration spectrum
    [statusEnv, dangerEnv] = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, shaftFreqTag);
    
    similarityHistory = max([statusAcc statusEnv]);
    
    similarityHistory(similarityHistory < 0) = 0;
    similarityHistory(similarityHistory > 1) = 1;
    
    historyDangerous = max([dangerAcc dangerEnv]);
end

% ACCSPECTRUMEVALUATION function calculate status to acceleration domain
function [weightsStatus, dangerStatus] = spectrumEvaluation(domain, shaftFreqTag)

    % Get bladePass data
    [positions, ~, magnitudes, weights, validPositions] = getTagPositionsHistory(domain, shaftFreqTag);
    
    % To get peaks evaluated of history 
    statusHistory = ...
        evaluatorThresholdTrend(domain.trendResult(validPositions), domain.statusCurrentThreshold(validPositions));
    
    % Validation rule
    if ~isempty(positions)
        % Preallocate defect peak index
        defectPeaksIndex = false(length(magnitudes), 1);
        % Evaluate the first peak
        % Check that the first peak is the maximum peak
        defectPeaksIndex(1) = magnitudes(1) == max(magnitudes);
        % Evaluate higher harmonics
        if defectPeaksIndex(1)
            for peakNumber = 2 : 1 : length(magnitudes)
                % Check that current peak is less than previous peaks
                isLessHigherHarmonic = all(magnitudes(peakNumber) < magnitudes(defectPeaksIndex));
                % Check that current peak is greater than 25% of previous
                % peaks
                isGreaterHigherHarmonic = any(magnitudes(peakNumber) > (0.25 * magnitudes(defectPeaksIndex)));
                % Validate current peak
                defectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
            end
        end
        % Get valid history
        statusHistoryTrue = statusHistory(defectPeaksIndex);
        % Get valid weights
        defectWeights = weights(defectPeaksIndex);
        % Evaluate weights
        weightsStatus = sum(bsxfun(@times, statusHistoryTrue, defectWeights'));
        
        dangerStatus = sum(bsxfun(@times, statusHistory, weights'));
    else
        weightsStatus = 0;
        dangerStatus = 0;
    end
end