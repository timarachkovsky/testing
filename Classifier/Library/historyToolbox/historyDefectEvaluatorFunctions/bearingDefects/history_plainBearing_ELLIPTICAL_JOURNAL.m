% PLAINBEARING_ELLIPTICAL_JOURNAL function returns a status of the defect
%
% Defect requirements:
%	main:
%               1) 2 * shaftFreq > 1 * shaftFreq
%
% Developer:              Kosmach N.
% Development date:       02-10-2017
% Modified by:            
% Modification date:  

function [similarityHistory, historyDangerous] = history_plainBearing_ELLIPTICAL_JOURNAL(defectStruct, ~)

    shaftFreqTag = 1; % shaftFreq tag
    
    % To evaluate displacementSpectrum spectrum
    similarityHistory = spectrumEvaluation(defectStruct.displacementSpectrum, shaftFreqTag);

    similarityHistory(similarityHistory < 0) = 0;
    similarityHistory(similarityHistory > 1) = 1;
    
    historyDangerous = similarityHistory;
end

% SPECTRUMEVALUATION function calculate status to domain
function [similarity] = spectrumEvaluation(domain, shaftFreqTag)

    % Get shaft data
    [positions, ~, magnitudes, weights, validPositions] = getTagPositionsHistory(domain, shaftFreqTag);
    % To get peaks evaluated of history 
    statusThresholdAndTrend = ...
        evaluatorThresholdTrend(domain.trendResult(validPositions), domain.statusCurrentThreshold(validPositions));
    
    similarity = 0;
    
    if nnz(positions ~= 2)
        
        if nnz(positions == 1)
            
            if magnitudes(positions == 1) < magnitudes(positions == 2)
                
                % Evaluate weights
                similarity = sum(bsxfun(@times, weights', statusThresholdAndTrend));
            end
        else
            % Evaluate weights
            similarity = sum(bsxfun(@times, weights', statusThresholdAndTrend));
        end
    end
end

