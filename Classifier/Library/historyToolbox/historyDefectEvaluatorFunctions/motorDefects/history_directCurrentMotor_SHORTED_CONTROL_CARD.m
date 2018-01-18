% SHORTED_CONTROL_CARD function returns a status of the defect
% 
% Defect requirements:
%     main:
%         1) k1 * shaftFreq, k2 * LF, SCR
%     additional:
%         
% Developer:              Kosmach N.
% Development date:       09.10.2017
% Modified by:            
% Modification date:      

function [similarityHistory, historyDangerous] = history_directCurrentMotor_SHORTED_CONTROL_CARD(defectStruct, ~)
    
    SCR = 9; % SCR tag
    shaftFreqTag = 1; % shaftFreq tag
    lineFreq = 3; % lineFreq tag
    
    % ACCELERATION SPECTRUM evaluation
    similarityHistory = accSpectrumEvaluation(defectStruct.accelerationSpectrum, ...
        shaftFreqTag, SCR, lineFreq);
    
    similarityHistory(similarityHistory > 1) = 1;
    historyDangerous = similarityHistory;
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum
function [weightsStatus] = accSpectrumEvaluation(domain, ...
    shaftFreqTag, SCR, lineFreq)
    
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
    
    % Get lineFreq data
    [~, ~, ~, weightsLineFreq, validPositionsLineFreq] = getTagPositionsHistory(domain, lineFreq);
    % To get peaks evaluated of history 
    statusThresholdAndTrendLineFreq = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsLineFreq), domain.statusCurrentThreshold(validPositionsLineFreq));
    % Evaluate weights
    lineFreqWeightsStatus = sum(bsxfun(@times, weightsLineFreq', statusThresholdAndTrendLineFreq));
    
    weightsStatus = shaftWeightsStatus + SCRWeightsStatus + lineFreqWeightsStatus;
end