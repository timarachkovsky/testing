% SYNCHRONOUSMOTOR_DEFECT_STATOR_WINDINGS function returns status of
% synchronous motor defect "Defect of Stator Windings" (defectID = 2)
% 
% Defect requirements:
%     main:
%         1) k1 * coilFreq +(-) k2 * twiceLineFreq, k1 < 4;
%     additional:
%         1) 1 * twiceLineFreq;
% 
% Developer:              P. Riabtsev
% Development date:       11-05-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = synchronousMotor_DEFECT_STATOR_WINDINGS(defectStruct, ~, initialPeakTable)
    
    modTag = {[10 3]}; % [coilFreq +(-) twiceLineFreq] tag
    TLFTag = {3}; % twice line frequency tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    [accWeightsStatus, defectStruct.accelerationSpectrum] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, modTag, TLFTag, ...
        logProminenceThreshold, initialPeakTable.accelerationSpectrum, defectStruct.basicFreqs);
    
    % Combine results
    results = accWeightsStatus;
    results(results < 0) = 0;
    results(results > 1) = 1;
    % Evaluate the defect similarity
    similarity = (min(results) + rms(results)) / 2;
    
    % The level is not evaluated
    level = 'NaN';
end

% ACCSPECTRUMEVALUATION function evaluates acceleration spectrum
function [weightsStatus, spectrumDefectStruct] = accSpectrumEvaluation(spectrumDefectStruct, modTag, TLFTag, logProminenceThreshold, initialPeakTable, basicFreqs)
    
    % Get modulation data
    [~, modEstimations, ~, modLogProminence, modWeights, spectrumDefectStruct] = getModulationEvaluationVector(spectrumDefectStruct, modTag, initialPeakTable, basicFreqs);
    % Get valid weights
    modDefectWeights = modWeights((modLogProminence > logProminenceThreshold) & (modEstimations == 1));
    % Evaluate weights
    modWeightsStatus = sum(modDefectWeights);
    
    % Get twice line frequency data
    [~, ~, ~, TLFLogProminence, TLFWeights] = getTagPositions(spectrumDefectStruct, TLFTag);
    % Get valid weights
    TLFDefectWeights = TLFWeights(TLFLogProminence > logProminenceThreshold);
    % Evaluate weights
    TLFWeightsStatus = sum(TLFDefectWeights);
    
    % Combine weights statuses
    if (modWeightsStatus ~= 0)
        weightsStatus = modWeightsStatus + (0.2 * TLFWeightsStatus);
    else
        weightsStatus = 0;
    end
end

