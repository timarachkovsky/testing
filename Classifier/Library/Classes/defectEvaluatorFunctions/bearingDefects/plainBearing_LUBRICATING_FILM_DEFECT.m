% PLAINBEARING_FILM_DEFECT function returns a status of the defect
%
% Defect requirements:
%	main(velocity and displacment):
%               1) k * shaftFreq, k = [(0.42 ... 0.48), 1]
%   additional:
%
% Developer:              Kosmach N.
% Development date:       01-10-2017
% Modified by:            
% Modification date:   
            
function [similarity, level, defectStruct] = plainBearing_LUBRICATING_FILM_DEFECT(defectStruct, ~, ~)

    tag046 = {16}; % (0.46 * shaftFrequency) tag
    tag1 = {1}; % shaftFrequency tag
    logProminenceThreshold = 3; % dB (relative to the noise)
    
    % VELOCITY SPECTRUM evaluation
    velWeightsStatus = spectrumEvaluation(defectStruct.velocitySpectrum, tag046, tag1, logProminenceThreshold);
    
    % DISPLACEMENT SPECTRUM evaluation
    dispWeightsStatus = spectrumEvaluation(defectStruct.displacementSpectrum, tag046, tag1, logProminenceThreshold);
    
    % Combine results
    results = [velWeightsStatus, dispWeightsStatus];
    results(results < 0) = 0;
    results(results > 1) = 1;
    % Evaluate the defect similarity
    similarity = (min(results) + rms(results)) / 2;
    
    % The level is not evaluated
    level = 'NaN';
end

% SPECTRUMEVALUATION function evaluates spectrum
function [weightsStatus] = spectrumEvaluation(spectrumDefectStruct, tag046, tag1, logProminenceThreshold)
    
    % Get shaft0.46 frequency data
    [~, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, tag046);
    
    if ~isempty(weights)
        % Get valid weights
        defectWeights = weights(logProminence > logProminenceThreshold);
        % Evaluate weights
        weightsStatus046 = sum(defectWeights);
    
        % Get shaft frequency data
        [~, ~, ~, logProminence, weights] = getTagPositions(spectrumDefectStruct, tag1);
        % Get valid weights
        defectWeights = weights(logProminence > logProminenceThreshold);
        % Evaluate weights
        weightsStatusShaft = sum(defectWeights);
        
        weightsStatus = weightsStatus046 + weightsStatusShaft;
    else
        weightsStatus = 0;
    end
end