% HISTORY_GEARING_GEAR_MESH
% Developer:              Kosmach N.
% Development date:       08.05.2017
% Modified by:            Kosmach N.
% Modification date:      21-09-2017 
% 
%%
%    main:
%               1) 1,2 *shaftFreq2 or 1,2 *shaftFreq1
%               2)  n*Fz, n = 1, 2, 3 
%   
function [similarityHistory, historyDangerous] = history_gearing_GEAR_MESH(defectStruct, myFiles)

    shaft1Tag = 17; % shaftFreq1 tag
    shaft2Tag = 18; % shaftFreq2 tag
    
    modWhithShaft1 = [19 17]; % [Fz +(-) shaftFreq1] tag
    modWhithShaft2 = [19 18]; % [Fz +(-) shaftFreq2] tag
    
    [statusShaft1, dangerShaft1]= defectEvaluationForOneShaft(defectStruct, shaft1Tag, modWhithShaft1, myFiles);
    [statusShaft2, dangerShaft2] = defectEvaluationForOneShaft(defectStruct, shaft2Tag, modWhithShaft2, myFiles);
    
    similarityHistory = max([statusShaft1 statusShaft2]);
    historyDangerous = max([dangerShaft1 dangerShaft2]);
end

% DEFECTEVALUATIONFORONESHAFT function evaluate defect for one shaft
function [status, dangerShaft] = defectEvaluationForOneShaft(defectStruct, shaftTag, modWhithShaft, myFiles)
        
	[gearMeshEnvStatus, dangerGearMeshEnv]  = ...
		evaluateGearMeshFrequency(defectStruct.accelerationEnvelopeSpectrum, shaftTag, modWhithShaft, myFiles);
	
	[gearMeshAccStatus, dangerGearMeshAcc] = ...
		evaluateGearMeshFrequency(defectStruct.accelerationSpectrum, shaftTag, modWhithShaft, myFiles);
	
	status = max([gearMeshEnvStatus gearMeshAccStatus*1.2]);
    
    dangerShaft = max([dangerGearMeshEnv dangerGearMeshAcc]);
    if status > 1
		status = 1;
    end
end

% DEFECTEVALUATIONFORONESHAFT function evaluate defect for one shaft
function [status, danger] = evaluateGearMeshFrequency(domain, shaftTag, modWhithShaft, myFiles)

    % To get data of shaft
	[shaftPositions, ~, ~, weightsShaft, validPositions] = getTagPositionsHistory(domain, shaftTag);
    
    % To get dangerous history of shaft
    statusHistoryShaft = evaluatorThresholdTrend(domain.trendResult(validPositions), ...
        domain.statusCurrentThreshold(validPositions));
    
    % To get status shaft
    statusShaft = sum(bsxfun(@times, weightsShaft', statusHistoryShaft));
    
    if ~isempty(shaftPositions)
        
        % To find numbers of non modulation harmonics 
		resultStructMod = evaluationModulationHistory(domain, myFiles);
        nonValidPosition = (resultStructMod.mainTag == modWhithShaft(1)) & ...
                           (resultStructMod.sideBandTag == modWhithShaft(2));
        numberHarmonicsNonValid = resultStructMod.position(nonValidPosition);
                       
        % To get current GM frequencies
        [gearPositions, ~, ~, gearWeights, gearValidPositions] = getTagPositionsHistory(domain, modWhithShaft(1));
                
        % To find non modulated positions
        posValid = ~ismember(gearPositions, numberHarmonicsNonValid);
    
        % To evaluate history dangerous of GM
        statusHistoryGear = evaluatorThresholdTrend(domain.trendResult(gearValidPositions), ...
            domain.statusCurrentThreshold(gearValidPositions));
        weights = bsxfun(@times, gearWeights(posValid)', statusHistoryGear(posValid));

        status = sum(weights) + statusShaft;  
        
        statuModDanger = bsxfun(@times, gearWeights', statusHistoryGear);
    else
        statuModDanger = 0;
        status = 0;
    end
    
    danger = statusShaft + statuModDanger;
end