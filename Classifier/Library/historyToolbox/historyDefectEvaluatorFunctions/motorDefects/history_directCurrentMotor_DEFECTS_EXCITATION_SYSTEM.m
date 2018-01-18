% DEFECTS_EXCITATION_SYSTEM function returns a status of the defect
% 
% Defect requirements:
%     main:
%         1) k1 * teethFreq, without modulation on shaft
%     additional:
%         
% Developer:              Kosmach N.
% Development date:       09.10.2017
% Modified by:            
% Modification date:  

function [similarityHistory, historyDangerous] = history_directCurrentMotor_DEFECTS_EXCITATION_SYSTEM(defectStruct, myFiles)
    
    teethFreq = 7; % teethFreq tag
%   modTag = {[7 1]}; % [teethFreq +(-) shaftFreq] tag
    
    % ACCELERATION SPECTRUM evaluation
    similarityHistory = accSpectrumEvaluation(defectStruct.accelerationSpectrum, ...
        teethFreq, myFiles);
    
    similarityHistory(similarityHistory > 1) = 1;
    
    historyDangerous = similarityHistory;
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum
function [weightsStatus] = accSpectrumEvaluation(domain, ...
    teethFreq, myFiles)
    
    % Get modulation data
    resultStruct = evaluationModulationHistory(domain, myFiles);
    
    % Get teethFreq data
    [~, namesTeethFreq, ~, weightsTeethFreq, validPositionsTeethFreq] = getTagPositionsHistory(domain, teethFreq);
    % To get peaks evaluated of history 
    statusThresholdAndTrendTeethFreq = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsTeethFreq), domain.statusCurrentThreshold(validPositionsTeethFreq));
    % To exclude modulation
    positionNonMod = ~ismember(namesTeethFreq, resultStruct.main);
    % Evaluate weights
    teethFreqWeightsStatus = sum(bsxfun(@times, weightsTeethFreq(positionNonMod)', statusThresholdAndTrendTeethFreq(positionNonMod)));
    
    weightsStatus = teethFreqWeightsStatus;
end

