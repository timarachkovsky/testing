% HISTORY_WEAR_ROLLING_ELEMENTS_AND_CAGE function returns a status
% of rolling bearing defect "Wear the rolling elements and cage" with history (defectID
% = 7)
% 
% Defect requirements:
%     main:
%         1) FTF;
%         2) shaftFreq - FTF
%     additional:
%         1) k * FTF;
%         2) k * (shaftFreq - FTF)
% 
%     main history:
%          1) k1 * FTF, k1 = 1, 2, 3
% Developer:              Kosmach N.
% Development date:       30-03-2017
% Modified by:            Kosmach N.
% Modification date:      15-09-2017

function [similarityHistory, historyDangerous] = history_rollingBearing_WEAR_ROLLING_ELEMENTS_AND_CAGE(defectStruct, ~)

    FTFTag = 11; % FTF tag
    difTag = 33; % shaftFTF tag

    similarityHistory = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, FTFTag, difTag);
    similarityHistory(similarityHistory < 0) = 0;
    similarityHistory(similarityHistory > 1) = 1;
    historyDangerous = similarityHistory;
end

% SPECTRUMEVALUATION function evaluates spectrum
function [weightsStatus] = spectrumEvaluation(domain, FTFTag, difTag)
    
    % Get FTF data
    [~, ~, ~, weightsFTF, validPositionsFTF] = getTagPositionsHistory(domain, FTFTag);
    % To get peaks evaluated of history 
    statusThresholdAndTrendFTF = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsFTF), domain.statusCurrentThreshold(validPositionsFTF));
    % Evaluate weights
    FTFWeightsStatus = sum(bsxfun(@times, weightsFTF', statusThresholdAndTrendFTF));
    
    % Get dif data
    [~, ~, ~, weightsDif, validPositionsDif] = getTagPositionsHistory(domain, difTag);
    % To get peaks evaluated of history 
    statusThresholdAndTrendDif = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsDif), domain.statusCurrentThreshold(validPositionsDif));
    % Evaluate weights
    difWeightsStatus = sum(bsxfun(@times, weightsDif', statusThresholdAndTrendDif));
    
    % Combine weights statuses
    weightsStatus = FTFWeightsStatus + (0.25 * difWeightsStatus);
end


