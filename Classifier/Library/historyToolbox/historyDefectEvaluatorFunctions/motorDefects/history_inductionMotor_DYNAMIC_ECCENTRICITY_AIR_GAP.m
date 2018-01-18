% HISTORY_INDUCTIONMOTOR_DYNAMIC_ECCENTRICITY_AIR_GAP function returns status of
% induction motor defect of history
% 
% Defect requirements:
%     main:
%         1) k1 * barFreq +(-) k2 * shaftFreq, k1 = [1, 2];
%     additional:
%         1) 1 * shaftFreq;
% 
% Developer:              Kosmach N.
% Development date:       06.06.2017
% Modified by:            Kosmach N.
% Modification date:      25.09.2017

function [similarityHistory, historyDangerous] = history_inductionMotor_DYNAMIC_ECCENTRICITY_AIR_GAP(defectStruct, myFiles)

%     modTag = {[4 1]}; % [barFreq +(-) shaftFreq] tag
    shaftFreqTag = 1; % shaft frequency tag

    similarityHistory = spectrumEvaluation(defectStruct.accelerationSpectrum, myFiles, shaftFreqTag);
    historyDangerous = similarityHistory;
end

% SPECTRUMEVALUATION function evaluates spectrum
function [weightsStatus] = spectrumEvaluation(domain, myFiles, shaftFreqTag)

    % Get modulation data
    resultStruct = evaluationModulationHistory(domain, myFiles);
    if nnz(resultStruct.status)
        statusMod =  sum(bsxfun(@times, resultStruct.weightMainPeak, resultStruct.status));
    else
        statusMod = 0;
    end
    
    % Get shaft data
    [~, ~, ~, weightsShaft, validPositionsShaft] = getTagPositionsHistory(domain, shaftFreqTag);
    % To get peaks evaluated of history 
    statusThresholdAndTrendShaft = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsShaft), domain.statusCurrentThreshold(validPositionsShaft));
    % Evaluate weights
    shaftWeightsStatus = sum(bsxfun(@times, weightsShaft', statusThresholdAndTrendShaft));
    
    % Combine weights statuses
    if nnz(resultStruct.status)
        weightsStatus = statusMod + (0.2 * shaftWeightsStatus);
    else
        weightsStatus = 0;
    end
end


