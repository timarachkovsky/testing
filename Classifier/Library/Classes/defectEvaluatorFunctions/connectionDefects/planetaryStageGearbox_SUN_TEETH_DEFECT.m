function [similarity, level, defectStruct] = planetaryStageGearbox_SUN_TEETH_DEFECT(defectStruct, ~, initialPeakTable)
%   SUN_TEETH_DEFECT
%   Developer:      Kosmach
%   Date:           04.10.2017
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
%% ______________ SUN_TEETH_DEFECT  ________________ %%

    logProminenceThreshold = 0;
    SPFS = {26}; % SPFS tag
    modTag1 = {[24 23]}; % [gearMeshFreqSun +- (sunFreq - carrierFreq)] tag
    modTag2 = {[25 23]}; % [gearMeshFreqSatellites +- (sunFreq - carrierFreq)] tag

    [statusEnv, defectStruct.accelerationEnvelopeSpectrum] = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, ...
        SPFS, modTag1, modTag2, initialPeakTable.accelerationEnvelopeSpectrum, logProminenceThreshold, defectStruct.basicFreqs);
    [statusAcc, defectStruct.accelerationSpectrum] = spectrumEvaluation(defectStruct.accelerationSpectrum, SPFS, ...
        modTag1, modTag2, initialPeakTable.accelerationSpectrum, logProminenceThreshold, defectStruct.basicFreqs);
    
    statusAcc = statusAcc * 1.2;
    
    similarity = max([statusEnv, statusAcc]);
    
    similarity(similarity > 1) = 1;
    
    level = 'NaN';

end

% SPECTRUMEVALUATION function evaluates spectrum 
function [weightsStatus, spectrumDefectStruct] = spectrumEvaluation(spectrumDefectStruct, SPFS, ...
    modTag1, modTag2, initialPeakTable, logProminenceThreshold, basicFreqs)
    
    % Get sun frequency data
    [positions, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, SPFS);
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