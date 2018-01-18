% HISTORY_GEARING_MISALIGNMENT_SHAFTS
%
% Developer:              Kosmach N.
% Development date:       11.05.2017
% Modified by:            Kosmach N.
% Modification date:      21-09-2017 
%%   
%    main:
%               1) 1,2 *shaftFreq1
%               2)  Fz +(-) shaftFreq1, 2*Fz more remaining
%                   or
%               1) 1,2 *shaftFreq2
%               2)  Fz +(-) shaftFreq2, 2*Fz more remaining
%   

function [similarityHistory, historyDangerous] = history_gearing_MISALIGNMENT_SHAFTS(defectStruct, myFiles)

    shaft1Tag = 17; % shaftFreq1 tag
    shaft2Tag = 18; % shaftFreq2 tag
    
    modWhithShaft1 = [19 17]; % [Fz +(-) shaftFreq1] tag
    modWhithShaft2 = [19 18]; % [Fz +(-) shaftFreq2] tag
    [statusShaft1, dangerShaft1] = defectEvaluationForOneShaft(defectStruct, shaft1Tag, modWhithShaft1, myFiles);
    [statusShaft2, dangerShaft2] = defectEvaluationForOneShaft(defectStruct, shaft2Tag, modWhithShaft2, myFiles);
    
    similarityHistory = max([statusShaft1, statusShaft2]);
    
    historyDangerous = max([dangerShaft1 dangerShaft2]);
end

% DEFECTEVALUATIONFORONESHAFT function evaluate defect for one shaft
function [status, dangerStatus] = defectEvaluationForOneShaft(defectStruct, shaftTag, modWhithShaft, myFiles)
        
	[gearMeshAccEnvStatus, dangerEnv]  = ...
		evaluateGearMeshFrequency(defectStruct.accelerationEnvelopeSpectrum, shaftTag, modWhithShaft, myFiles);
	
	[gearMeshAccStatus, dangerAcc] = ...
		evaluateGearMeshFrequency(defectStruct.accelerationSpectrum, shaftTag, modWhithShaft, myFiles);
	
	status = max([gearMeshAccEnvStatus gearMeshAccStatus*1.2]);
    if status > 1
		status = 1;
    end
    
    dangerStatus = max([dangerEnv dangerAcc]);
end

% DEFECTEVALUATIONFORONESHAFT function evaluate defect for one shaft
function [status, danger] = evaluateGearMeshFrequency(domain, shaftTag, modWhithShaft, myFiles)

    % To get data of shaft
	[shaftPositions, ~, ~, weightsShaft, validPositions] = getTagPositionsHistory(domain, shaftTag);
    
    % To get dangerous history of shaft
    statusHistoryShaft = evaluatorThresholdTrend(domain.trendResult(validPositions), ...
        domain.statusCurrentThreshold(validPositions));
    
    % To get status shaft
    statusShaft = bsxfun(@times, weightsShaft', statusHistoryShaft);
    
    if ~isempty(shaftPositions)
        
        resultStructMod = evaluationModulationHistory(domain, myFiles);
        
        % To find needed tag
        positionTagsNeeded = bsxfun(@and, resultStructMod.mainTag == modWhithShaft(1), ...
                                            resultStructMod.sideBandTag == modWhithShaft(2));
        
        newStructMod.status = resultStructMod.status(positionTagsNeeded);
        newStructMod.weightMainPeak = resultStructMod.weightMainPeak(positionTagsNeeded);
        newStructMod.position = resultStructMod.position(positionTagsNeeded);
        newStructMod.magnitudes = resultStructMod.magnitudes(positionTagsNeeded);
        
        if nnz(newStructMod.status)
            if nnz(newStructMod.position == 2)
                if nnz(newStructMod.magnitudes(newStructMod.position == 2) >= newStructMod.magnitudes) == ...
                        length(newStructMod.magnitudes)
                    secondLargest = 1;
                else
                    secondLargest = 0;
                end
            else
                secondLargest = 0;
            end
            weights = newStructMod.weightMainPeak;
            estimationsMod = newStructMod.status;
        else
            secondLargest = 0;
            weights = 0;
            estimationsMod = 0;
        end
        status = (sum(bsxfun(@times, weights, estimationsMod))*secondLargest) + sum(statusShaft);
        
        statuModDanger = (sum(bsxfun(@times, weights, estimationsMod))) + sum(statusShaft);
    else
        status = 0;
        statuModDanger = 0;
    end
    
    danger = statusShaft + statuModDanger;
end