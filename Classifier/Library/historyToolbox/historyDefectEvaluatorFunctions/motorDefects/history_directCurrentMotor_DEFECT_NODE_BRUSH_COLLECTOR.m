% DEFECT_NODE_BRUSH_COLLECTOR function returns a status of the defect
% 
% Defect requirements:
%     main:
%         1) k1 * collectorFrequency, brushFrequency
%     additional:
%         
% Developer:              Kosmach N.
% Development date:       09.10.2017
% Modified by:            
% Modification date:       

function [similarityHistory, historyDangerous] = history_directCurrentMotor_DEFECT_NODE_BRUSH_COLLECTOR(defectStruct, ~)
    
    collectorFrequencyTag = 6; % collectorFrequency tag
    brushFrequencyTag = 8; % brushFrequency tag
    
    % ACCELERATION SPECTRUM evaluation
    similarityHistory = accSpectrumEvaluation(defectStruct.accelerationSpectrum, ...
        collectorFrequencyTag, brushFrequencyTag);
    
    similarityHistory(similarityHistory > 1) = 1;
    
    historyDangerous = similarityHistory;
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum
function [weightsStatus] = accSpectrumEvaluation(domain, ...
    collectorFrequencyTag, brushFrequencyTag)
    
    % Get brush data
    [~, ~, ~, weightsBrush, validPositionsBrush] = getTagPositionsHistory(domain, brushFrequencyTag);
    % To get peaks evaluated of history 
    statusThresholdAndTrendBrush = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsBrush), domain.statusCurrentThreshold(validPositionsBrush));
    % Evaluate weights
    brushWeightsStatus = sum(bsxfun(@times, weightsBrush', statusThresholdAndTrendBrush));
    
    % Get collector data
    [~, ~, ~, weightsCollector, validPositionsCollector] = getTagPositionsHistory(domain, collectorFrequencyTag);
    % To get peaks evaluated of history 
    statusThresholdAndTrendCollector = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsCollector), domain.statusCurrentThreshold(validPositionsCollector));
    % Evaluate weights
    collectorWeightsStatus = sum(bsxfun(@times, weightsCollector', statusThresholdAndTrendCollector));
    
    weightsStatus = collectorWeightsStatus + brushWeightsStatus;
end