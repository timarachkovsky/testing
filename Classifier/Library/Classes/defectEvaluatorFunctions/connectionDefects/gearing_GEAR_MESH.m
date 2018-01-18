function [similarity, level, defectStruct] = gearing_GEAR_MESH(defectStruct, ~, initialPeakTable)
% GEARING_GEAR_MESH
%   Developer:      Kosmach
%   Date:           23.03.2017
%%
%    main:
%               1) 1,2 *shaftFreq2 or 1,2 *shaftFreq1
%               2)  n*Fz, n = 1, 2, 3 
%   

%% ______________ GEAR MESH (defectID = 1) ________________ %%
    shaft1Tag = {17}; % shaftFreq1 tag
    shaft2Tag = {18}; % shaftFreq2 tag
    
    modWhithShaft1 = {[19 17]}; % [Fz +(-) shaftFreq1] tag
    modWhithShaft2 = {[19 18]}; % [Fz +(-) shaftFreq2] tag
    [statusShaft1, defectStruct] = defectEvaluationForOneShaft(defectStruct, shaft1Tag, modWhithShaft1, initialPeakTable);
    [statusShaft2, defectStruct] = defectEvaluationForOneShaft(defectStruct, shaft2Tag, modWhithShaft2, initialPeakTable);
    
    similarity = max([statusShaft1, statusShaft2]);
    
    level = 'NaN';
end

% DEFECTEVALUATIONFORONESHAFT function evaluate defect for one shaft
function [status, defectStruct] = defectEvaluationForOneShaft(defectStruct, shaftTag, modWhithShaft, initialPeakTable)
        
    
	[gearMeshAccEnvStatus, defectStruct.accelerationEnvelopeSpectrum]  = ...
		evaluateGearMeshFrequency(defectStruct.accelerationEnvelopeSpectrum, shaftTag, modWhithShaft, ...
		initialPeakTable.accelerationEnvelopeSpectrum, defectStruct.basicFreqs);
	
	[gearMeshAccStatus, defectStruct.accelerationSpectrum] = ...
		evaluateGearMeshFrequency(defectStruct.accelerationSpectrum, shaftTag, modWhithShaft, ...
		initialPeakTable.accelerationSpectrum, defectStruct.basicFreqs);
	
	status = max([gearMeshAccEnvStatus gearMeshAccStatus*1.2]);
	if status > 1
		status = 1;
	end
   
end

% DEFECTEVALUATIONFORONESHAFT function evaluate defect for one shaft
function [status,domain] = evaluateGearMeshFrequency(domain, shaftTag, modWhithShaft, initialPeakTable, basicFreqs)

	[shaftPositions, ~, ~, ~, weightsShaft] = getTagPositions(domain, shaftTag);

    [~, estimationsMod, ~, logProminenceMod, weights,domain] = getModulationEvaluationVector(...
				domain, modWhithShaft, initialPeakTable, basicFreqs);
    
	if ~isempty(shaftPositions)
		if ~isempty(logProminenceMod)
			posPeakFalseMod = estimationsMod == 0;

			if nnz(posPeakFalseMod) == 0
				status = 0;
				return
			end

			weights = weights(logical(posPeakFalseMod));

			status = sum(weights) + sum(weightsShaft);
		else
			status = 0;
		end
	else
		status = 0;
	end
end