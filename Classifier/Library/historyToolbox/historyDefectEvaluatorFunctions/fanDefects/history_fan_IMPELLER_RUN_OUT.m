% FAN_IMPELLER_RUN_OUT function returns status of fan defect
% "Impeller Run-Out" (defectID = 1)
% 
% Defect requirements:
%     main:
%         1) k1 * bladePass +(-) k2 * shaftFreq (acceleration envelope
%         spectrum)
%     additional:
% 
% Developer:              Kosmach N.
% Development date:       08.06.2017
% Modified by:            Kosmach N.
% Modification date:      18.09.2017

function [similarityHistory, historyDangerous] = history_fan_IMPELLER_RUN_OUT(defectStruct, myFiles)
    
    shaftFreqTag = 1; % shaftFreqTag tag
%     modTag = {[3 1]}; % [bladePass +(-) shaftFreq] tag, not used, because one
%     modulation tag

    % To evaluate acceleration spectrum
    statusAcc = accSpectrumEvaluation(defectStruct.accelerationSpectrum, shaftFreqTag);
    
    % To evaluate envelope acceleration spectrum
    statusEnv = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, shaftFreqTag, myFiles);
    
    results = [statusAcc statusEnv];
    results(results < 0) = 0;
    results(results > 1) = 1;
    if statusAcc > statusEnv
        similarityHistory = (min(results) + rms(results)) / 2;
    else
        similarityHistory = statusEnv;
    end
    
    historyDangerous = similarityHistory;
end

% ACCSPECTRUMEVALUATION function calculate status to acceleration domain
function [weightsStatus] = accEnvSpectrumEvaluation(domain, shaftFreqTag, myFiles)

    % Get modulation data
    resultStruct = evaluationModulationHistory(domain, myFiles);
    if nnz(resultStruct.status)
        modWeightsStatus =  sum(bsxfun(@times, resultStruct.weightMainPeak, resultStruct.status));
    else
        modWeightsStatus = 0;
    end
    
    % Get shaft data
    [~, ~, ~, weightsShaft, validPositionsShaft] = getTagPositionsHistory(domain, shaftFreqTag);
    % To get peaks evaluated of history 
    statusThresholdAndTrendShaft = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsShaft), domain.statusCurrentThreshold(validPositionsShaft));
    % Evaluate weights
    shaftWeightsStatus = sum(bsxfun(@times, weightsShaft', statusThresholdAndTrendShaft));
    
    % Combine weights statuses
    if (modWeightsStatus ~= 0)
        weightsStatus = (modWeightsStatus + shaftWeightsStatus) / 2;
    else
        weightsStatus = 0;
    end
end

% ACCENVSPECTRUMEVALUATION function calculate status to acceleration envelope domain
function [weightsStatus] = accSpectrumEvaluation(domain, shaftFreqTag)
    % Get shaft data
    [~, ~, ~, weightsShaft, validPositionsShaft] = getTagPositionsHistory(domain, shaftFreqTag);
    % To get peaks evaluated of history 
    statusThresholdAndTrendShaft = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsShaft), domain.statusCurrentThreshold(validPositionsShaft));
    % Evaluate weights
    weightsStatus = sum(bsxfun(@times, weightsShaft', statusThresholdAndTrendShaft));
end
