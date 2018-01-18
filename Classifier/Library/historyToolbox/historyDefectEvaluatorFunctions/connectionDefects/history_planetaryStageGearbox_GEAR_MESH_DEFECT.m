% GEAR_MESH_DEFECT function returns status of defect
%
% Defect requirements:
%%
%    main:
%               1) k * gearMeshFreqSun, k > 1
%               2) k * gearMeshFreqSatellites, k > 1
%    
%    additional: 
%               1) k * sunFreq, k > 1
%               2) k * carrierFreq, k > 1
%   
% 
% Developer:              Kosmach N.
% Development date:       05.10.2017
% Modified by:            
% Modification date:      

function [similarityHistory, historyDangerous] = history_planetaryStageGearbox_GEAR_MESH_DEFECT(defectStruct, ~)

    gearMeshFreqSun = 25; % SPFS tag
    gearMeshFreqSatellites = 25; % SPFS tag
    sunFreq = 20; % sunFreq tag
    carrierFreq = 21; % carrierFreq
    
    % To evaluate acceleration spectrum
    statusAcc = spectrumEvaluation(defectStruct.accelerationSpectrum, ...
        gearMeshFreqSun, gearMeshFreqSatellites, sunFreq, carrierFreq);
    
    % To evaluate envelope acceleration spectrum
    statusEnv = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, ...
        gearMeshFreqSun, gearMeshFreqSatellites, sunFreq, carrierFreq);
    
    similarityHistory = max([statusAcc*1.2 statusEnv]);
    similarityHistory(similarityHistory < 0) = 0;
    similarityHistory(similarityHistory > 1) = 1;
    
    historyDangerous = similarityHistory;
end

% ACCENVSPECTRUMEVALUATION function calculate status to sprctrums domain
function [weightsStatus] = spectrumEvaluation(domain, gearMeshFreqSun, gearMeshFreqSatellites, sunFreq, carrierFreq)
    
    % Get gearMeshFreqSun data
    [positions, ~, ~, weights, validPositions] = getTagPositionsHistory(domain, gearMeshFreqSun);
    
    % To get peaks evaluated of history 
    statusThresholdAndTrendGearMeshFreqSun = ...
        evaluatorThresholdTrend(domain.trendResult(validPositions), domain.statusCurrentThreshold(validPositions));
    
    % Validation rule
    if ~isempty(positions) || nnz(statusThresholdAndTrendGearMeshFreqSun)
        % Get valid history
        historyValid = statusThresholdAndTrendGearMeshFreqSun;
        % Get valid weights
        defectWeights = weights';
        % Evaluate weights
        weightsGearMeshFreqSun = sum(bsxfun(@times, defectWeights, historyValid));
    else
        weightsGearMeshFreqSun = 0;
    end
    
    % Get gearMeshFreqSatellites data
    [positions, ~, ~, weights, validPositions] = getTagPositionsHistory(domain, gearMeshFreqSatellites);
    
    % To get peaks evaluated of history 
    statusThresholdAndTrendGearMeshFreqSatellites = ...
        evaluatorThresholdTrend(domain.trendResult(validPositions), domain.statusCurrentThreshold(validPositions));
    
    % Validation rule
    if ~isempty(positions) || nnz(statusThresholdAndTrendGearMeshFreqSatellites)
        % Get valid history
        historyValid = statusThresholdAndTrendGearMeshFreqSatellites;
        % Get valid weights
        defectWeights = weights';
        % Evaluate weights
        weightsGearMeshFreqSatellites = sum(bsxfun(@times, defectWeights, historyValid));
    else
        weightsGearMeshFreqSatellites = 0;
    end
    
    if weightsGearMeshFreqSatellites == weightsGearMeshFreqSun
		statusMain = weightsGearMeshFreqSatellites;
    else
		statusMain = weightsGearMeshFreqSatellites + weightsGearMeshFreqSun;
    end
    
    % Get sunFreq data
    [positions, ~, ~, weights, validPositions] = getTagPositionsHistory(domain, sunFreq);
    
    % To get peaks evaluated of history 
    statusThresholdAndTrendSunFreq = ...
        evaluatorThresholdTrend(domain.trendResult(validPositions), domain.statusCurrentThreshold(validPositions));
    
    % Validation rule
    if ~isempty(positions) || nnz(statusThresholdAndTrendSunFreq)
        % Get valid history
        historyValid = statusThresholdAndTrendSunFreq;
        % Get valid weights
        defectWeights = weights';
        % Evaluate weights
        weightsSunFreq  = sum(bsxfun(@times, defectWeights, historyValid));
    else
        weightsSunFreq = 0;
    end
    
    % Get carrierFreq data
    [positions, ~, ~, weights, validPositions] = getTagPositionsHistory(domain, carrierFreq);
    
    % To get peaks evaluated of history 
    statusThresholdAndTrendCarrierFreq = ...
        evaluatorThresholdTrend(domain.trendResult(validPositions), domain.statusCurrentThreshold(validPositions));
    
    % Validation rule
    if ~isempty(positions) || nnz(statusThresholdAndTrendCarrierFreq)
        % Get valid history
        historyValid = statusThresholdAndTrendCarrierFreq;
        % Get valid weights
        defectWeights = weights';
        % Evaluate weights
        weightsCarrierFreq  = sum(bsxfun(@times, defectWeights, historyValid));
    else
        weightsCarrierFreq = 0;
    end
    
    if (weightsCarrierFreq + weightsSunFreq) > 0.2
        statusAdditional = 0.2;
    else
        statusAdditional = weightsCarrierFreq + weightsSunFreq;
    end
    
    % Combine weights statuses
    weightsStatus = statusAdditional + statusMain;
end