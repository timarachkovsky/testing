% HISTORY_INDUCTIONMOTOR_CRACKED_BROKEN_ROTOR_BARS function returns status of
% induction motor defect of history
% 
% Defect requirements:
%     main:
%         1) k1 * shaftFreq +(-) k2 * polePassFreq, k1 < 6;
%     additional:
% 
% Developer:              Kosmach N.
% Development date:       06.06.2017
% Modified by:            Kosmach N.
% Modification date:      25.09.2017

function [similarityHistory, historyDangerous] = history_inductionMotor_CRACKED_BROKEN_ROTOR_BARS(defectStruct, myFiles)
    
%     modTag = [1 5]; % [shaftFreq +(-) polePassFreq] tag

    [similarityHistory, historyDangerous] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, myFiles);
end

% ACCENVSPECTRUMEVALUATION function calculate status to acceleration envelope domain
function [weightsStatus, historyDangerous] = accSpectrumEvaluation(domain, myFiles)
    
    % Get modulation data
    resultStruct = evaluationModulationHistory(domain, myFiles);
    weights = resultStruct.weightMainPeak;
    positions = resultStruct.position;
    magnitudes = resultStruct.magnitudes;
    statusThresholdAndTrend = resultStruct.status;
    
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
        defectWeights = weights(defectPeaksIndex);
        statusThresholdAndTrendWithPattern = statusThresholdAndTrend(defectPeaksIndex);
        % Evaluate weights
        weightsStatus = sum(bsxfun(@times, defectWeights, statusThresholdAndTrendWithPattern));
        historyDangerous = sum(bsxfun(@times, weights, statusThresholdAndTrend));
    else
        weightsStatus = 0;
        historyDangerous = 0;
    end
end

