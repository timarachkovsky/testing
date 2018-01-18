% HISTORY_INDUCTIONMOTOR_ROTOR_ECCENTRICITY function returns status of induction
% motor defect of history
% 
% Defect requirements:
%     main:
%         1) 1* twiceLineFreq +(-) k * polePassFreq;
%     additional:
%         1) 1 * shaftFreq +(-) k * polePassFreq;
% 
% Developer:              Kosmach N.
% Development date:       06.06.2017
% Modified by:            Kosmach N.
% Modification date:      25.09.2017

function [similarityHistory, historyDangerous] = history_inductionMotor_ROTOR_ECCENTRICITY(defectStruct, myFiles)
    
    mainModTag = [3 5]; % [twiceLineFreq +(-) polePassFreq] tag
    addModTag = [1 5]; % [shaftFreq +(-) polePassFreq] tag

    similarityHistory = accSpectrumEvaluation(defectStruct.accelerationSpectrum, myFiles, mainModTag, addModTag);
    historyDangerous = similarityHistory;
end

% ACCSPECTRUMEVALUATION function calculate status to acceleration domain
function [weightsStatus] = accSpectrumEvaluation(domain, myFiles, mainModTag, addModTag)

    resultStructMod = evaluationModulationHistory(domain, myFiles);
        
    % To find needed tag for mainMod
    positionMainModNeeded = bsxfun(@and, resultStructMod.mainTag == mainModTag(1), ...
                                            resultStructMod.sideBandTag == mainModTag(2));
                                        
    % Evaluate weights for mainMod
    mainModWeightsStatus = sum(bsxfun(@times, resultStructMod.status(positionMainModNeeded), ...
                                             resultStructMod.weightMainPeak(positionMainModNeeded)));

    % To find needed tag for addMod
    positionAddModNeeded = bsxfun(@and, resultStructMod.mainTag == addModTag(1), ...
                                            resultStructMod.sideBandTag == addModTag(2));
                                        
    % Evaluate weights for addMod
    addModWeightsStatus = sum(bsxfun(@times, resultStructMod.status(positionAddModNeeded), ...
                                             resultStructMod.weightMainPeak(positionAddModNeeded)));
    
    % Combine weights statuses
    if (mainModWeightsStatus ~= 0)
        weightsStatus = (0.8 * mainModWeightsStatus) + (0.2 * addModWeightsStatus);
    else
        weightsStatus = 0;
    end
end
