% DEFECT_ANCHOR_WINDINGS function returns a status of the defect
% 
% Defect requirements:
%     main:
%         1) k1 * shaftFreq, k1 * teethFreq +- 2 * k2 shaftFreq
%     additional:
%         
% Developer:              Kosmach N.
% Development date:       09.10.2017
% Modified by:            
% Modification date:      

function [similarityHistory, historyDangerous] = history_directCurrentMotor_DEFECT_ANCHOR_WINDINGS(defectStruct, myFiles)
    
    shaftFreqTag = {1}; % shaftFreq tag
%     modTag = {[7 1]}; % [teethFreq +(-) shaftFreq] tag
    
    % ACCELERATION SPECTRUM evaluation
    similarityHistory = accSpectrumEvaluation(defectStruct.accelerationSpectrum, ...
        shaftFreqTag, myFiles);
    
    similarityHistory(similarityHistory > 1) = 1;
    
    historyDangerous = similarityHistory;
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum
function [weightsStatus] = accSpectrumEvaluation(domain, ...
    shaftFreqTag, myFiles)
    
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
    if shaftWeightsStatus > 0.5
        shaftWeightsStatus = 0.5;
    end
    
    % Combine weights statuses
    if (statusMod ~= 0)
        weightsStatus = statusMod + shaftWeightsStatus;
    else
        weightsStatus = 0;
    end
end