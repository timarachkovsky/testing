% PLAINBEARING_COCKED_PLAIN_BEARING function returns a status of wear defect
%
% Defect requirements:
%	main:
%               1) k * shaftFreq, k = 2 4 6 ... 10 (acceleration and envelopee)
%
% Developer:              Kosmach N.
% Development date:       02-10-2017
% Modified by:            
% Modification date:    

function [similarityHistory, historyDangerous] = history_plainBearing_COCKED_PLAIN_BEARING(defectStruct, ~)

    shaftFreqTag = 1; % shaftFreq tag

    % To evaluate acceleration spectrum
    [statusAcc, dangerAcc] = spectrumEvaluation(defectStruct.accelerationSpectrum, shaftFreqTag);
    
    % To evaluate envelope acceleration spectrum
    [statusEnv, dangerEnv] = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, shaftFreqTag);
    
    results = [statusAcc statusEnv];
    results(results < 0) = 0;
    results(results > 1) = 1;
    if statusAcc > statusEnv
        similarityHistory = (min(results) + rms(results)) / 2;
    else
        similarityHistory = statusEnv;
    end
    
    historyDangerous = max([dangerEnv, dangerAcc]);
end

% ACCSPECTRUMEVALUATION function calculate status to domain
function [weightsStatus, dangerAcc] = spectrumEvaluation(domain, shaftFreqTag)

    % Get shaft data
    [~, ~, ~, weights, validPositions] = getTagPositionsHistory(domain, shaftFreqTag);
    % To get peaks evaluated of history 
    statusThresholdAndTrend = ...
        evaluatorThresholdTrend(domain.trendResult(validPositions), domain.statusCurrentThreshold(validPositions));
    % Evaluate weights
    weightsStatus = sum(bsxfun(@times, weights', statusThresholdAndTrend));
    
    dangerAcc = weightsStatus;
end