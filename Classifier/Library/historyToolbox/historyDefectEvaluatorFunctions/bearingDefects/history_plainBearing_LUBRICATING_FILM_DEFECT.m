% PLAINBEARING_FILM_DEFECT function returns a status of the defect
%
% Defect requirements:
%	main(velocity and displacment):
%               1) k * shaftFreq, k = [(0.42 ... 0.48), 1]
%   additional:
%
% Developer:              Kosmach N.
% Development date:       02-10-2017
% Modified by:            
% Modification date:   

function [similarityHistory, historyDangerous] = history_plainBearing_LUBRICATING_FILM_DEFECT(defectStruct, ~)

    shaftFreqTag = 1; % shaftFreq tag
    tag046 = 16; % (0.46 * shaftFrequency) tag

    % To evaluate velocity spectrum
    [statusVel, dangerVel] = spectrumEvaluation(defectStruct.velocitySpectrum, shaftFreqTag, tag046);
    
    % To evaluate displacementSpectrum spectrum
    [statusDisp, dangerDidp] = spectrumEvaluation(defectStruct.displacementSpectrum, shaftFreqTag, tag046);
    
    results = [statusVel statusDisp];
    results(results < 0) = 0;
    results(results > 1) = 1;
    if statusVel > statusDisp
        similarityHistory = (min(results) + rms(results)) / 2;
    else
        similarityHistory = statusDisp;
    end
    
    historyDangerous = max([dangerDidp, dangerVel]);
end

% SPECTRUMEVALUATION function calculate status to domain
function [similarity, danger] = spectrumEvaluation(domain, shaftFreqTag, tag046)

    % Get shaft0.46 frequency date
    [~, ~, ~, weights, validPositions] = getTagPositionsHistory(domain, tag046);
    
    if ~isempty(weights)
    % To get peaks evaluated of history 
    statusThresholdAndTrend046 = ...
        evaluatorThresholdTrend(domain.trendResult(validPositions), domain.statusCurrentThreshold(validPositions));
    % Evaluate weights
    similarity046 = sum(bsxfun(@times, weights', statusThresholdAndTrend046));
    
    % Get shaft frequency date
    [~, ~, ~, weights, validPositions] = getTagPositionsHistory(domain, shaftFreqTag);
    statusThresholdAndTrendShaft = ...
        evaluatorThresholdTrend(domain.trendResult(validPositions), domain.statusCurrentThreshold(validPositions));
    % Evaluate weights
    similarityShaft = sum(bsxfun(@times, weights', statusThresholdAndTrendShaft));
    
    similarity = similarity046 + similarityShaft;
    danger = similarity;
    else
        similarity = 0;
        danger = 0;
    end
end