% Creator:      Kosmach N.
% Date:           14.03.2017

%EVALUATORWEIGHTTRESHOLDTREND function evaluated common weight defect with
% status of threshold and trend, also with weight each peak. 
% Sum weight peaks with same status of threshold and trend and set the most dangerous
function [ status ,commonWeight ] = evaluatorWeightThresholdTrend(trendPeaks, thresholdVector, weight)
    [ statusThresholdAndTrend ] = evaluatorThresholdTrend(trendPeaks, thresholdVector);
    [ status, commonWeight ] = evaluatorWeightAndStatus(statusThresholdAndTrend, weight);
end

