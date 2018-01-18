% PHASE_LOSS function returns a status of the defect
% 
% Defect requirements:
%     main:
%         1) k1 * shaftFreq, 1/3 * SCR, 2/3 * SCR, SCR
%     additional:
%         
% Developer:              Kosmach N.
% Development date:       09.10.2017
% Modified by:            
% Modification date:      

function [similarityHistory, historyDangerous] = history_directCurrentMotor_PHASE_LOSS(defectStruct, ~)
    
    SCR = 9; % SCR tag
    shaftFreqTag = 1; % shaftFreq tag
    
    % ACCELERATION SPECTRUM evaluation
    similarityHistory = accSpectrumEvaluation(defectStruct.accelerationSpectrum, ...
        shaftFreqTag, SCR);
    
    similarityHistory(similarityHistory > 1) = 1;
    historyDangerous = similarityHistory;
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum
function [weightsStatus] = accSpectrumEvaluation(domain, ...
    shaftFreqTag, SCR)
    
    % Get SCR data
    [~, ~, ~, weightsSCR, validPositionsSCR] = getTagPositionsHistory(domain, SCR);
    % To get peaks evaluated of history 
    statusThresholdAndTrendSCR = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsSCR), domain.statusCurrentThreshold(validPositionsSCR));
    % Evaluate weights
    SCRWeightsStatus = sum(bsxfun(@times, weightsSCR', statusThresholdAndTrendSCR));
    
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
    
    weightsStatus = shaftWeightsStatus + SCRWeightsStatus;
end