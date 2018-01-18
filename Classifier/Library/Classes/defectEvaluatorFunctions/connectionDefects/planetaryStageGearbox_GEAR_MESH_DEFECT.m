function [similarity, level, defectStruct] = planetaryStageGearbox_GEAR_MESH_DEFECT(defectStruct, ~, ~)
%   GEAR_MESH_DEFECT
%   Developer:      Kosmach
%   Date:           04.10.2017
%%
%    main:
%               1) k * gearMeshFreqSun, k > 1
%               2) k * gearMeshFreqSatellites, k > 1
%    
%    additional: 
%               1) k * sunFreq, k > 1
%               2) k * carrierFreq, k > 1
%   
%% ______________ GEAR_MESH_DEFECT  ________________ %%

    logProminenceThreshold = 0;
    gearMeshFreqSun = {24}; % SPFS tag
    gearMeshFreqSatellites = {25}; % SPFS tag
    sunFreq = {20}; % sunFreq tag
    carrierFreq = {21}; % carrierFreq

    statusEnv = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, ...
        gearMeshFreqSun, gearMeshFreqSatellites, sunFreq, carrierFreq, logProminenceThreshold);
    statusAcc = spectrumEvaluation(defectStruct.accelerationSpectrum, ...
        gearMeshFreqSun, gearMeshFreqSatellites, sunFreq, carrierFreq, logProminenceThreshold);
    
    statusAcc = statusAcc * 1.2;
    
    similarity = max([statusEnv, statusAcc]);
    
    similarity(similarity > 1) = 1;
    
    level = 'NaN';

end

% SPECTRUMEVALUATION function evaluates spectrum 
function [weightsStatus] = spectrumEvaluation(spectrumDefectStruct, ...
    gearMeshFreqSun, gearMeshFreqSatellites, sunFreq, carrierFreq, logProminenceThreshold)
    
    % Get gearMeshFreqSun data
    [positions, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, gearMeshFreqSun);
    % Validation rule
    if ~isempty(positions)
        % Check the prominence threshold
        defectProminenceIndex = logProminence > logProminenceThreshold;
        % Get valid data
        defectWeights = weights(defectProminenceIndex);
        % Evaluate weights
        gearMeshFreqSunStatus = sum(defectWeights);
    else
        gearMeshFreqSunStatus = 0;
    end
    
    % Get gearMeshFreqSatellites data
    [positions, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, gearMeshFreqSatellites);
    % Validation rule
    if ~isempty(positions)
        % Check the prominence threshold
        defectProminenceIndex = logProminence > logProminenceThreshold;
        % Get valid data
        defectWeights = weights(defectProminenceIndex);
        % Evaluate weights
        gearMeshFreqSatellitesStatus = sum(defectWeights);
    else
        gearMeshFreqSatellitesStatus = 0;
    end
    
	if gearMeshFreqSatellitesStatus == gearMeshFreqSunStatus
		statusMain = gearMeshFreqSatellitesStatus;
	else
		statusMain = gearMeshFreqSatellitesStatus + gearMeshFreqSunStatus;
	end
	
    % Get sunFreq data
    [positions, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, sunFreq);
    % Validation rule
    if ~isempty(positions)
        % Check the prominence threshold
        defectProminenceIndex = logProminence > logProminenceThreshold;
        % Get valid data
        defectWeights = weights(defectProminenceIndex);
        % Evaluate weights
        sunFreqStatus = sum(defectWeights);
    else
        sunFreqStatus = 0;
    end
    
    % Get carrierFreq data
    [positions, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, carrierFreq);
    % Validation rule
    if ~isempty(positions)
        % Check the prominence threshold
        defectProminenceIndex = logProminence > logProminenceThreshold;
        % Get valid data
        defectWeights = weights(defectProminenceIndex);
        % Evaluate weights
        carrierFreqStatus = sum(defectWeights);
    else
        carrierFreqStatus = 0;
    end
    
    if (carrierFreqStatus + sunFreqStatus) > 0.2
        statusAdditional = 0.2;
    else
        statusAdditional = carrierFreqStatus + sunFreqStatus;
    end
    
    
    % Combine weights statuses
    weightsStatus = statusAdditional + statusMain;
end