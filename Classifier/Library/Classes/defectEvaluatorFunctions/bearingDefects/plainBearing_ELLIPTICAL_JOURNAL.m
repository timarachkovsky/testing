% PLAINBEARING_ELLIPTICAL_JOURNAL function returns a status of the defect
%
% Defect requirements:
%	main:
%               1) 2 * shaftFreq > 1 * shaftFreq
%
% Developer:              Kosmach N.
% Development date:       01-10-2017
% Modified by:            
% Modification date:  

function [similarity, level, defectStruct] = plainBearing_ELLIPTICAL_JOURNAL(defectStruct, ~, ~)

    shaftFreqTag = {1}; % shaftFrequency tag
    logProminenceThreshold = 3; % dB (relative to the noise)
        
    % DISPLACEMENT SPECTRUM evaluation
    dispWeightsStatus = spectrumEvaluation(defectStruct.displacementSpectrum, shaftFreqTag, logProminenceThreshold);
    
    similarity = dispWeightsStatus;
    similarity(similarity < 0) = 0;
    similarity(similarity > 1) = 1;
    
    % The level is not evaluated
    level = 'NaN';
end

% SPECTRUMEVALUATION function evaluates spectrum
function [weightsStatus] = spectrumEvaluation(spectrumDefectStruct, shaftFreqTag, logProminenceThreshold)
    
    [positions, ~, magnitudes, logProminence, weights] = getTagPositions(spectrumDefectStruct, shaftFreqTag);
    weightsStatus = 0;
    
    if nnz(positions ~= 2)
        
        if nnz(positions == 1)
            if magnitudes(positions == 1) < magnitudes(positions == 2)
                % Get valid weights
                defectWeights = weights(logProminence > logProminenceThreshold);
                % Evaluate weights
                weightsStatus = sum(defectWeights);
            end
        else
            % Get valid weights
            defectWeights = weights(logProminence > logProminenceThreshold);
            % Evaluate weights
            weightsStatus = sum(defectWeights);
        end
    end
end