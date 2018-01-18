% SATELLITES_DEFECT function returns status of defect
%
% Defect requirements:
%%
%    main:
%               1) k * 2 * satellitesFreq, k > 2
%    
%    additional: 
%               1) k * gearMeshFreqSun +- satellitesFreq
%               2) k * gearMeshFreqSatellites +- satellitesFreq,
%               k > 1
%   
% 
% Developer:              Kosmach N.
% Development date:       04.10.2017
% Modified by:            
% Modification date:      

function [similarityHistory, historyDangerous] = history_planetaryStageGearbox_SATELLITES_DEFECT(defectStruct, myFiles)

    satellitesFreq = 22; % SPFS tag
    modTag1 = [24 22]; % [gearMeshFreqSun +- satellitesFreq] tag
    modTag2 = [25 22]; % [gearMeshFreqSatellites +- satellitesFreq] tag
    
    % To evaluate acceleration spectrum
    statusAcc = spectrumEvaluation(defectStruct.accelerationSpectrum, satellitesFreq, modTag1, modTag2, myFiles);
    
    % To evaluate envelope acceleration spectrum
    statusEnv = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, satellitesFreq, modTag1, modTag2, myFiles);
    
    similarityHistory = max([statusAcc*1.2 statusEnv]);
    similarityHistory(similarityHistory < 0) = 0;
    similarityHistory(similarityHistory > 1) = 1;
    
    historyDangerous = similarityHistory;
end

% ACCENVSPECTRUMEVALUATION function calculate status to sprctrums domain
function [weightsStatus] = spectrumEvaluation(domain, satellitesFreq, modTag1, modTag2, myFiles)
    
    % Get satellitesFreq data
    [positions, ~, ~, weights, validPositions] = getTagPositionsHistory(domain, satellitesFreq);
    
    % To get peaks evaluated of history 
    statusThresholdAndTrend = ...
        evaluatorThresholdTrend(domain.trendResult(validPositions), domain.statusCurrentThreshold(validPositions));
    
    % Validation rule
    if ~isempty(positions) || nnz(statusThresholdAndTrend)
        % Get valid history
        historyValid = statusThresholdAndTrend;
        % Get valid weights
        defectWeights = weights';
        % Evaluate weights
        weightsStatus = sum(bsxfun(@times, defectWeights, historyValid));
    else
        weightsStatus = 0;
    end
    
    % To get history informations about modulations
    resultStructMod = evaluationModulationHistory(domain, myFiles);
    
    % To find needed tag for modTag1
    positionsheave1Needed = bsxfun(@and, resultStructMod.mainTag == modTag1(1), ...
                                            resultStructMod.sideBandTag == modTag1(2));
                                        
    % Evaluate weights for modTag1
    mod1WeightsStatus = sum(bsxfun(@times, resultStructMod.status(positionsheave1Needed), ...
                                             resultStructMod.weightMainPeak(positionsheave1Needed)));
    if mod1WeightsStatus > 0.2
        mod1WeightsStatus = 0.2;
    end                                  
                                         
    % To find needed tag for modTag2
    positionsheave2Needed = bsxfun(@and, resultStructMod.mainTag == modTag2(1), ...
                                            resultStructMod.sideBandTag == modTag2(2));
                                        
    % Evaluate weights for modTag2
    mod2WeightsStatus = sum(bsxfun(@times, resultStructMod.status(positionsheave2Needed), ...
                                             resultStructMod.weightMainPeak(positionsheave2Needed)));
    if mod2WeightsStatus > 0.2
        mod2WeightsStatus = 0.2;
    end                                  
                                         
    if mod2WeightsStatus == mod1WeightsStatus
        modWeightsStatus = mod1WeightsStatus;
    else
        modWeightsStatus = mod1WeightsStatus + mod2WeightsStatus;
    end
    
    % Combine weights statuses
    weightsStatus = weightsStatus + modWeightsStatus;
end