function [similarity, level, defectStruct] = planetaryStageGearbox_SATELLITES_DEFECT(defectStruct, ~, initialPeakTable)
%   SATELLITES_DEFECT
%   Developer:      Kosmach
%   Date:           04.10.2017
%%
%    main:
%               1) k * 2 * satellitesFreq, k > 2
%    
%    additional: 
%               1) k * gearMeshFreqSun +- satellitesFreq
%               2) k * gearMeshFreqSatellites +- satellitesFreq,
%               k > 1
%   
%% ______________ SATELLITES_DEFECT  ________________ %%

    logProminenceThreshold = 0;
    satellitesFreq = {22}; % SPFS tag
    modTag1 = {[24 22]}; % [gearMeshFreqSun +- satellitesFreq] tag
    modTag2 = {[25 22]}; % [gearMeshFreqSatellites +- satellitesFreq] tag

    [statusEnv, defectStruct.accelerationEnvelopeSpectrum] = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, ...
        satellitesFreq, modTag1, modTag2, initialPeakTable.accelerationEnvelopeSpectrum, logProminenceThreshold, defectStruct.basicFreqs);
    [statusAcc, defectStruct.accelerationSpectrum] = spectrumEvaluation(defectStruct.accelerationSpectrum, satellitesFreq, ...
        modTag1, modTag2, initialPeakTable.accelerationSpectrum, logProminenceThreshold, defectStruct.basicFreqs);
    
    statusAcc = statusAcc * 1.2;
    
    similarity = max([statusEnv, statusAcc]);
    
    similarity(similarity > 1) = 1;
    
    level = 'NaN';

end

% SPECTRUMEVALUATION function evaluates spectrum 
function [weightsStatus, spectrumDefectStruct] = spectrumEvaluation(spectrumDefectStruct, satellitesFreq, ...
    modTag1, modTag2, initialPeakTable, logProminenceThreshold, basicFreqs)
    
    % Get sun frequency data
    [positions, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, satellitesFreq);
    % Validation rule
    if ~isempty(positions)
        % Check the prominence threshold
        defectProminenceIndex = logProminence > logProminenceThreshold;
        % Get valid data
        defectWeights = weights(defectProminenceIndex);
        % Evaluate weights
        weightsStatus = sum(defectWeights);
    else
        weightsStatus = 0;
    end
    
    % Get modulation data1
    [~, modEstimations, ~, modLogProminence, modWeights, spectrumDefectStruct] = ...
        getModulationEvaluationVector(spectrumDefectStruct, modTag1, initialPeakTable, basicFreqs);
    % Get valid modulation weights
    modDefectWeights = modWeights((modLogProminence > logProminenceThreshold) & (modEstimations == 1));
    % Evaluate modulation weights
    mod1WeightsStatus = sum(modDefectWeights);
    if mod1WeightsStatus > 0.2
        mod1WeightsStatus = 0.2;
    end
    
    % Get modulation data2
    [~, modEstimations, ~, modLogProminence, modWeights, spectrumDefectStruct] = ...
        getModulationEvaluationVector(spectrumDefectStruct, modTag2, initialPeakTable, basicFreqs);
    % Get valid modulation weights
    modDefectWeights = modWeights((modLogProminence > logProminenceThreshold) & (modEstimations == 1));
    % Evaluate modulation weights
    mod2WeightsStatus = sum(modDefectWeights);
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