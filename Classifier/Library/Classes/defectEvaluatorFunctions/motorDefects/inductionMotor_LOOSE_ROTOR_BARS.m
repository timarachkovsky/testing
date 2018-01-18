% INDUCTIONMOTOR_LOOSE_ROTOR_BARS function returns status of induction
% motor defect "Loose Rotor Bars" (defectID = 4)
% 
% Defect requirements:
%     main:
%         1) k1 * barFreq +(-) k2 * twiceLineFreq, k1 = [1, 2];
%     additional:
%         1) 2 * barFreq > 1 * barFreq;
% 
% Developer:              P. Riabtsev
% Development date:       11-05-2017
% Modified by:            
% Modification date:      

function [similarity, level, defectStruct] = inductionMotor_LOOSE_ROTOR_BARS(defectStruct, ~, initialPeakTable)
    
    modTag = {[4 3]}; % [barFreq +(-) twiceLineFreq] tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % ACCELERATION SPECTRUM evaluation
    [accWeightsStatus, defectStruct.accelerationSpectrum] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, modTag, ...
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
function [weightsStatus, spectrumDefectStruct] = accSpectrumEvaluation(spectrumDefectStruct, modTag, logProminenceThreshold, initialPeakTable, basicFreqs)
    
    % Get modulation data
    [positions, estimations, magnitudes, logProminence, weights, spectrumDefectStruct] = getModulationEvaluationVector(spectrumDefectStruct, modTag, initialPeakTable, basicFreqs);
    % Get valid weights
    defectWeights = weights((logProminence > logProminenceThreshold) & (estimations == 1));
    % Evaluate weights
    weightsStatus = sum(defectWeights);
    
    % Find the first harmonic index
    firstHarmonicIndex = positions == 1;
    % Find the second harmonic index
    secondHarmonicIndex = positions == 2;
    % Evaluate additional requirement
    if (magnitudes(secondHarmonicIndex) > magnitudes(firstHarmonicIndex))
        weightsStatus = weightsStatus + 0.2;
    end
end

