% ROLLINGBEARINGN_GROOVES_CHIPPED_ROLLING_ELEMENTS function returns a
% status of rolling bearing defect "Grooves, chipped on the rolling
% elements" (defectID = 8)
% 
% Defect requirements:
%     main:
%         1) 2k1 * BSF +(-) k2 * FTF (in acceleration envelope spectrum);
%         2) 2k * BSF (in acceleration spectrum);
%         3) BEF (?)
%     additional:
%         1) k1 * BSF +(-) k2 * FTF
% 
% Developer:              P. Riabtsev
% Development date:       29-03-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = rollingBearing_GROOVES_CHIPPED_ROLLING_ELEMENTS(defectStruct, ~, initialPeakTable)
    
    BSFTag = {12}; % BSF tag
    modTag = {[12 11]}; % [BSF +(-) FTF] tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    [accWeightsStatus, defectStruct.accelerationSpectrum] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, BSFTag, modTag, ...
        logProminenceThreshold, initialPeakTable.accelerationSpectrum, defectStruct.basicFreqs);
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    [accEnvWeightsStatus, defectStruct.accelerationEnvelopeSpectrum] = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, modTag, ...
        logProminenceThreshold, initialPeakTable.accelerationEnvelopeSpectrum, defectStruct.basicFreqs);
    
    % Combine results
    results = [accEnvWeightsStatus, accWeightsStatus];
    results(results < 0) = 0;
    results(results > 1) = 1;
    % Evaluate the defect similarity
    similarity = (min(results) + rms(results)) / 2;
    
    % The level is not evaluated
    level = 'NaN';
end

% ACCSPECTRUMEVALUATION function evaluates acceleration spectrum
function [weightsStatus, spectrumDefectStruct] = accSpectrumEvaluation(spectrumDefectStruct, BSFTag, modTag, logProminenceThreshold, initialPeakTable, basicFreqs)
    
    % Get BSF data
    [BSFPositions, ~, ~, BSFLogProminence, BSFWeights] = getTagPositions(spectrumDefectStruct, BSFTag);
    % Find odd BSF positions index
    oddBSFPositionsIndex = logical(mod(BSFPositions, 2));
    % Get even BSF positions data
    evenBSFLogProminence = BSFLogProminence(~oddBSFPositionsIndex);
    evenBSFWeights = BSFWeights(~oddBSFPositionsIndex);
    % Get valid even BSF weights
    evenBSFDefectWeights = evenBSFWeights(evenBSFLogProminence > logProminenceThreshold);
    % Evaluate BSF weights
    evenBSFWeigthsStatus = sum(evenBSFDefectWeights);
    
    % Get modulation data
    [~, modEstimations, ~, modLogProminence, modWeights, spectrumDefectStruct] = getModulationEvaluationVector(spectrumDefectStruct, modTag, initialPeakTable, basicFreqs);
    % Get valid modulation weights
    modDefectWeights = modWeights((modLogProminence > logProminenceThreshold) & (modEstimations == 1));
    % Evaluate modulation weights
    modWeightsStatus = sum(modDefectWeights);
    
    % Combine weights statuses
    weightsStatus = (2 * evenBSFWeigthsStatus) + (0.2 * modWeightsStatus);
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum
function [weightsStatus, spectrumDefectStruct] = accEnvSpectrumEvaluation(spectrumDefectStruct, modTag, logProminenceThreshold, initialPeakTable, basicFreqs)
    
    % Get modulation data
    [modPositions, modEstimations, ~, modLogProminence, modWeights, spectrumDefectStruct] = getModulationEvaluationVector(spectrumDefectStruct, modTag, initialPeakTable, basicFreqs);
    % Validation rule
    if ~isempty(modPositions)
        % Check the prominence threshold
        defectProminenceIndex = modLogProminence > logProminenceThreshold;
        % Get valid weights
        estimatedWeights = modWeights .* (modEstimations + 1);
        defectWeights = estimatedWeights(defectProminenceIndex);
        % Evaluate weights
        weightsStatus = sum(defectWeights);
    else
        weightsStatus = 0;
    end
end