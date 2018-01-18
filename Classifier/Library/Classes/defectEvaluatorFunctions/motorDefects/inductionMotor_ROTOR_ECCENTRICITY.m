% INDUCTIONMOTOR_ROTOR_ECCENTRICITY function returns status of induction
% motor defect "Rotor Eccentricity" (defectID = 7)
% 
% Defect requirements:
%     main:
%         1) 1* twiceLineFreq +(-) k * polePassFreq;
%     additional:
%         1) 1 * shaftFreq +(-) k * polePassFreq;
% 
% Developer:              P. Riabtsev
% Development date:       11-05-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = inductionMotor_ROTOR_ECCENTRICITY(defectStruct, ~, initialPeakTable)
    
    mainModTag = {[3 5]}; % [twiceLineFreq +(-) polePassFreq] tag
    addModTag = {[1 5]}; % [shaftFreq +(-) polePassFreq] tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    [accWeightsStatus, defectStruct.accelerationSpectrum] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, mainModTag, addModTag, ...
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
function [weightsStatus, spectrumDefectStruct] = accSpectrumEvaluation(spectrumDefectStruct, mainModTag, addModTag, logProminenceThreshold, initialPeakTable, basicFreqs)
    
    % Get main modulation data
    [~, mainModEstimations, ~, mainModLogProminence, mainModWeights, spectrumDefectStruct] = getModulationEvaluationVector(spectrumDefectStruct, mainModTag, initialPeakTable, basicFreqs);
    % Get valid weights
    mainModDefectWeights = mainModWeights((mainModLogProminence > logProminenceThreshold) & (mainModEstimations == 1));
    % Evaluate weights
    mainModWeightsStatus = sum(mainModDefectWeights);
    
    % Get additional modulation data
    [~, addModEstimations, ~, addModLogProminence, addModWeights, spectrumDefectStruct] = getModulationEvaluationVector(spectrumDefectStruct, addModTag, initialPeakTable, basicFreqs);
    % Get valid weights
    addModDefectWeights = addModWeights((addModLogProminence > logProminenceThreshold) & (addModEstimations == 1));
    % Evaluate weights
    addModWeightsStatus = sum(addModDefectWeights);
    
    % Combine weights statuses
    if (mainModWeightsStatus ~= 0)
        weightsStatus = (0.8 * mainModWeightsStatus) + (0.2 * addModWeightsStatus);
    else
        weightsStatus = 0;
    end
end

