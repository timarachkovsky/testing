% SUN_TEETH_DEFECT function returns status of defect
%
% Defect requirements:
%%
%    main:
%               1) k * n * (sunFreq-carrierFreq), k >2, n - number of
%               satellites
%    
%    additional: 
%               1) k * gearMeshFreqSun +- (sunFreq - carrierFreq)
%               2) k * gearMeshFreqSatellites +- (sunFreq - carrierFreq)
%               k > 1
%   
% 
% Developer:              Kosmach N.
% Development date:       04.10.2017
% Modified by:            
% Modification date:      

function [similarityHistory, historyDangerous] = history_planetaryStageGearbox_SUN_TEETH_DEFECT(defectStruct, myFiles)

    SPFS = 26; % SPFS tag
    modTag1 = [24 23]; % [gearMeshFreqSun +- (sunFreq - carrierFreq)] tag
    modTag2 = [25 23]; % [gearMeshFreqSatellites +- (sunFreq - carrierFreq)] tag
    
    % To evaluate acceleration spectrum
    statusAcc = spectrumEvaluation(defectStruct.accelerationSpectrum, SPFS, modTag1, modTag2, myFiles);
    
    % To evaluate envelope acceleration spectrum
    statusEnv = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, SPFS, modTag1, modTag2, myFiles);
    
    similarityHistory = max([statusAcc*1.2 statusEnv]);
    similarityHistory(similarityHistory < 0) = 0;
    similarityHistory(similarityHistory > 1) = 1;
    
    historyDangerous = similarityHistory;
end

% ACCENVSPECTRUMEVALUATION function calculate status to sprctrums domain
function [weightsStatus] = spectrumEvaluation(domain, SPFS, modTag1, modTag2, myFiles)
    
    % Get BPFO data
    [positions, ~, ~, weights, validPositions] = getTagPositionsHistory(domain, SPFS);
    
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