% RING_GEAR_DEFECT function returns status of defect
%
% Defect requirements:
%%
%    main:
%               1) k * n * carrierFreq, k > 2, n - number of
%               satellites
%    
%    additional: 
%               1) k * gearMeshFreqSun +- satellitesFreq
%               k > 1
%   
% 
% Developer:              Kosmach N.
% Development date:       04.10.2017
% Modified by:            
% Modification date:      

function [similarityHistory, historyDangerous] = history_planetaryStageGearbox_RING_GEAR_DEFECT(defectStruct, myFiles)

    SPFG = 27; % SPFG tag
    modTag = [24 22]; % [gearMeshFreqSun +- satellitesFreq] tag
    
    % To evaluate acceleration spectrum
    statusAcc = spectrumEvaluation(defectStruct.accelerationSpectrum, SPFG, modTag, myFiles);
    
    % To evaluate envelope acceleration spectrum
    statusEnv = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, SPFG, modTag, myFiles);
    
    similarityHistory = max([statusAcc*1.2 statusEnv]);
    similarityHistory(similarityHistory < 0) = 0;
    similarityHistory(similarityHistory > 1) = 1;
    
    historyDangerous = similarityHistory;
end

% ACCENVSPECTRUMEVALUATION function calculate status to sprctrums domain
function [weightsStatus] = spectrumEvaluation(domain, SPFG, modTag, myFiles)
    
    % Get SPFG data
    [positions, ~, ~, weights, validPositions] = getTagPositionsHistory(domain, SPFG);
    
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
    positionsheave1Needed = bsxfun(@and, resultStructMod.mainTag == modTag(1), ...
                                            resultStructMod.sideBandTag == modTag(2));
                                        
    % Evaluate weights for modTag1
    mod1WeightsStatus = sum(bsxfun(@times, resultStructMod.status(positionsheave1Needed), ...
                                             resultStructMod.weightMainPeak(positionsheave1Needed)));
    if mod1WeightsStatus > 0.2
        mod1WeightsStatus = 0.2;
    end                                  
    
    % Combine weights statuses
    weightsStatus = weightsStatus + mod1WeightsStatus;
end