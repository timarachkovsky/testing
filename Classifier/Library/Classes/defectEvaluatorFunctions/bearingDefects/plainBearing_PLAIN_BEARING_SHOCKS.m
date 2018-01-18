% PLAINBEARING_PLAIN_BEARING_SHOCKS function returns a status of the defect
%
% Defect requirements:
%	main:
%               1) k * shaftFreq, k = 0 ... 10 (acceleration and envelopee)
%               2) k * shaftFreq, k = 1 ... 7 (acceleration envelope spectrum)
%
% Developer:              Kosmach N.
% Development date:       01-10-2017
% Modified by:            
% Modification date:    

function [similarity, level, defectStruct] = plainBearing_PLAIN_BEARING_SHOCKS(defectStruct, ~, ~)

    shaftFreq = {1}; % shaftFrequency tag
    logProminenceThreshold = 3;
    
    % ACCELERATION SPECTRUM evaluation
    accWeightsStatus = spectrumEvaluation(defectStruct.accelerationSpectrum, shaftFreq, logProminenceThreshold);
        
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    accEnvWeightsStatus = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, shaftFreq, logProminenceThreshold);
    
    % Combine results
    results = [accWeightsStatus, accEnvWeightsStatus];
    results(results < 0) = 0;
    results(results > 1) = 1;
    % Evaluate the defect similarity
    similarity = (min(results) + rms(results)) / 2;
    
    % The level is not evaluated
    level = 'NaN';
end

% SPECTRUMEVALUATION function evaluates spectrum
function [weightsStatus] = spectrumEvaluation(spectrumDefectStruct, shaftFreq, logProminenceThreshold)
    
    % Get shaftFreq data
    [~, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, shaftFreq);
    % Get valid weights
    defectWeights = weights(logProminence > logProminenceThreshold);
    % Evaluate weights
    weightsStatus = sum(defectWeights);
end

