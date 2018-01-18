function [similarity, level, defectStruct] = planetaryStageGearbox_CARRIER_SHAFT_RUN_OUT(defectStruct, ~, initialPeakTable)
%   CARRIER_SHAFT_RUN_OUT
%   Developer:      Kosmach
%   Date:           04.10.2017
%%
%    main:
%               1) k * carrierFreq, k > 1
%    
%    additional: 
%               1) k * gearMeshFreqSatellites +- carrierFreq, k =
%               1,2 ...
%   
%% ______________ CARRIER_SHAFT_RUN_OUT  ________________ %%

    logProminenceThreshold = 0;
    carrierFreq = {21};     % carrierFreq
    modTag = {[25 21]}; % [gearMeshFreqSatellites +- carrierFreq] tag

    [statusEnv, defectStruct.accelerationEnvelopeSpectrum] = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, ...
        carrierFreq, modTag, initialPeakTable.accelerationEnvelopeSpectrum, logProminenceThreshold, defectStruct.basicFreqs);
    [statusAcc, defectStruct.accelerationSpectrum] = spectrumEvaluation(defectStruct.accelerationSpectrum, carrierFreq, ...
        modTag, initialPeakTable.accelerationSpectrum, logProminenceThreshold, defectStruct.basicFreqs);
    
    statusAcc = statusAcc * 1.2;
    
    similarity = max([statusEnv, statusAcc]);
    
    similarity(similarity > 1) = 1;
    
    level = 'NaN';

end

% SPECTRUMEVALUATION function evaluates spectrum 
function [weightsStatus, spectrumDefectStruct] = spectrumEvaluation(spectrumDefectStruct, carrierFreq, ...
    modTag, initialPeakTable, logProminenceThreshold, basicFreqs)
    
    % Get sun frequency data
    [positions, ~, magnitudes, logProminence, weights] = getTagPositions(spectrumDefectStruct, carrierFreq);
    % Validation rule
    if ~isempty(positions)
        % Preallocate defect peak index
        defectPeaksIndex = false(length(magnitudes), 1);
        % Evaluate the first harmonic
        firstHarmonicIndex = find(positions == 1);
        if ~isempty(firstHarmonicIndex)
            % Validate the first hatmonic
            defectPeaksIndex(firstHarmonicIndex) = magnitudes(firstHarmonicIndex) == max(magnitudes(positions ~= 2));
            % Evaluate higher harmonics
            for peakNumber = firstHarmonicIndex + 1 : 1 : length(magnitudes)
                % Check that current peak is less than 75% of previous peaks
                isLessHigherHarmonic = all(magnitudes(peakNumber) < (0.75 * magnitudes(defectPeaksIndex)));
                % Check that current peak is greater than 25% of previous peaks
                isGreaterHigherHarmonic = any(magnitudes(peakNumber) > (0.25 * magnitudes(defectPeaksIndex)));
                % Validate current peak
                defectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
            end
        end
        % Check the prominence threshold
        defectProminenceIndex = logProminence > logProminenceThreshold;
        % Validate all peaks
        validPeaksIndex = defectPeaksIndex & defectProminenceIndex;
        % Get valid data
        defectWeights = weights(validPeaksIndex);
        % Evaluate weights
        weightsStatus = sum(defectWeights);
    else
        weightsStatus = 0;
    end
    
    % Get modulation data
    [~, modEstimations, ~, modLogProminence, modWeights, spectrumDefectStruct] = ...
        getModulationEvaluationVector(spectrumDefectStruct, modTag, initialPeakTable, basicFreqs);
    % Get valid modulation weights
    modDefectWeights = modWeights((modLogProminence > logProminenceThreshold) & (modEstimations == 1));
    % Evaluate modulation weights
    modWeightsStatus = sum(modDefectWeights);
    if modWeightsStatus > 0.2
        modWeightsStatus = 0.2;
    end
    
    % Combine weights statuses
    weightsStatus = weightsStatus + modWeightsStatus;
end