% HISTORY_TOOTHEDBELT_BELT_SLIP function returns status of smooth belt defect of
% history
% 
% Defect requirements:
%     main:
%         1) k1 * sheaveFreq1 +(-) k2 * beltFreq;
%         2) k1 * sheaveFreq2 +(-) k2 * beltFreq;
%     additional:
% 
% Developer:              Kosmach N.
% Development date:       07-06-2017
% Modified by:            Kosmach N.
% Modification date:      22.09.2017

function [similarityHistory, historyDangerous] = history_toothedBelt_BELT_SLIP(defectStruct, myFiles)

    sheave1ModTag = [29 28]; % [sheaveFreq1 +(-) beltFreq] tag
    sheave2ModTag = [30 28]; % [sheaveFreq2 +(-) beltFreq] tag
    
    % ACCELERATION SPECTRUM evaluation
    similarityHistory = accSpectrumEvaluation(defectStruct.accelerationSpectrum, sheave1ModTag, sheave2ModTag, myFiles);
    
    similarityHistory(similarityHistory < 0) = 0;
    similarityHistory(similarityHistory > 1) = 1;

    historyDangerous = similarityHistory;
end

% ACCSPECTRUMEVALUATION function evaluates acceleration spectrum
function weightsStatus = accSpectrumEvaluation(domain, sheave1ModTag, sheave2ModTag, myFiles)
    
    resultStructMod = evaluationModulationHistory(domain, myFiles);
        
    % To find needed tag for sheave1
    positionsheave1Needed = bsxfun(@and, resultStructMod.mainTag == sheave1ModTag(1), ...
                                            resultStructMod.sideBandTag == sheave1ModTag(2));
                                        
    % Evaluate weights for sheave1
    sheave1ModWeightsStatus = sum(bsxfun(@times, resultStructMod.status(positionsheave1Needed), ...
                                             resultStructMod.weightMainPeak(positionsheave1Needed)));

    % To find needed tag for sheave2
    positionsheave2Needed = bsxfun(@and, resultStructMod.mainTag == sheave2ModTag(1), ...
                                            resultStructMod.sideBandTag == sheave2ModTag(2));
                                        
    % Evaluate weights for sheave2
    sheave2ModWeightsStatus = sum(bsxfun(@times, resultStructMod.status(positionsheave2Needed), ...
                                             resultStructMod.weightMainPeak(positionsheave2Needed)));
    
    % Combine weights statuses
    weightsStatus = max([sheave1ModWeightsStatus sheave2ModWeightsStatus]);
end