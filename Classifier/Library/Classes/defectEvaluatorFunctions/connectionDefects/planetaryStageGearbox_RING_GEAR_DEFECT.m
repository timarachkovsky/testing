function [similarity, level, defectStruct] = planetaryStageGearbox_RING_GEAR_DEFECT(defectStruct, ~, initialPeakTable)
%   RING_GEAR_DEFECT
%   Developer:      Kosmach
%   Date:           04.10.2017
%%
%    main:
%               1) k * n * carrierFreq, k > 2, n - number of
%               satellites
%    
%    additional: 
%               1) k * gearMeshFreqSun +- satellitesFreq
%               k > 1
%   
%% ______________ RING_GEAR_DEFECT  ________________ %%

    logProminenceThreshold = 0;
    SPFG = {27}; % SPFG tag
    modTag = {[24 22]}; % [gearMeshFreqSun +- satellitesFreq] tag

    [statusEnv, defectStruct.accelerationEnvelopeSpectrum] = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, ...
        SPFG, modTag, initialPeakTable.accelerationEnvelopeSpectrum, logProminenceThreshold, defectStruct.basicFreqs);
    [statusAcc, defectStruct.accelerationSpectrum] = spectrumEvaluation(defectStruct.accelerationSpectrum, SPFG, ...
        modTag, initialPeakTable.accelerationSpectrum, logProminenceThreshold, defectStruct.basicFreqs);
    
    statusAcc = statusAcc * 1.2;
    
    similarity = max([statusEnv, statusAcc]);
    
    similarity(similarity > 1) = 1;
    
    level = 'NaN';

end

% SPECTRUMEVALUATION function evaluates spectrum 
function [weightsStatus, spectrumDefectStruct] = spectrumEvaluation(spectrumDefectStruct, SPFG, ...
    modTag, initialPeakTable, logProminenceThreshold, basicFreqs)
    
    % Get sun frequency data
    [positions, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, SPFG);
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
        getModulationEvaluationVector(spectrumDefectStruct, modTag, initialPeakTable, basicFreqs);
    % Get valid modulation weights
    modDefectWeights = modWeights((modLogProminence > logProminenceThreshold) & (modEstimations == 1));
    % Evaluate modulation weights
    mod1WeightsStatus = sum(modDefectWeights);
    if mod1WeightsStatus > 0.2
        mod1WeightsStatus = 0.2;
    end

    % Combine weights statuses
    weightsStatus = weightsStatus + mod1WeightsStatus;
end