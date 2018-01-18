% HISTORY_SHAFT_ROTOR_IMBALANCE function returns status of shaft defect "Rotor 
% imbalance" with history(defectID = 2)
% 
% Defect requirements:
%     main:
%         1) k * shaftFreq, k = 1;
%         2) There are no k * shaftFreq, k > 2;
%            1 * shaftFreq >> k * shaftFreq (k > 1)
% 
% Developer:              Kosmach N.
% Development date:       04.03.2017
% Modified by:            Kosmach N.
% Modification date:      18.09.2017

function [similarityHistory, historyDangerous] = history_shaft_ROTOR_IMBALANCE(defectStruct,~)
   
    shaftFreq = 1; % BPFO tag

    % To evaluate acceleration spectrum
    [statusAcc, dangerAcc] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, shaftFreq);
    
    % To evaluate envelope acceleration spectrum
    [statusDisp, dangerDisp] = dispSpectrumEvaluation(defectStruct.displacementSpectrum, shaftFreq);
    
    results = [statusAcc statusDisp];
    results(results < 0) = 0;
    results(results > 1) = 1;
    if statusAcc > statusDisp
        similarityHistory = (min(results) + rms(results)) / 2;
    else
        similarityHistory = statusDisp;
    end
    
    historyDangerous = max([dangerAcc, dangerDisp]);
end

% ACCSPECTRUMEVALUATION function calculate status to acceleration domain
function [weightsStatus, danger] = accSpectrumEvaluation(domain, shaftFreq)

    % To evaluate with pattern
    [positions, ~, ~, weights, positionsPattern] = getTagPositionsHistory(domain, shaftFreq);
    
    if ~isempty(positions)
        
        % To get peaks evaluated of history 
        statusThresholdAndTrend = evaluatorThresholdTrend(domain.trendResult(positionsPattern), domain.statusCurrentThreshold(positionsPattern));
        if nnz(positions == 1)
            
            % To calculateresult
            weightsStatus = sum(weights' .* statusThresholdAndTrend);
        else
            weightsStatus = 0;
        end
        danger = sum(weights' .* statusThresholdAndTrend);
    else
        weightsStatus = 0;
        danger = 0;
    end
end

% DISPSPECTRUMEVALUATION function calculate status to acceleration envelope domain
function [weightsStatus, danger] = dispSpectrumEvaluation(domain, shaftFreq)

    % Get BPFO data
    [positions, ~, magnitudes, weights, positionValid] = getTagPositionsHistory(domain, shaftFreq);
    % To get peaks evaluated of history 
    statusThresholdAndTrend = evaluatorThresholdTrend(domain.trendResult(positionValid), domain.statusCurrentThreshold(positionValid));
    % Validation rule
    if ~isempty(positions)
        firstHarmonicIndex = find(positions == 1);
        if ~isempty(firstHarmonicIndex)
            % Preallocate defect peak index
            defectPeaksIndex = false(length(magnitudes), 1);
            % Find the first higher harmonic index
            firstHigherHarmonicIndex = firstHarmonicIndex + 1;
            % Evaluate higher harmonics
            defectPeaksIndex(firstHigherHarmonicIndex : end) = magnitudes(firstHigherHarmonicIndex : end) < (0.25 * magnitudes(firstHarmonicIndex));
            % Evaluate the first harmonic
            if length(magnitudes) > 1
                defectPeaksIndex(firstHarmonicIndex) = defectPeaksIndex(firstHigherHarmonicIndex);
            else
                defectPeaksIndex(firstHarmonicIndex) = true;
            end
            % Get valid history
            historyValid = statusThresholdAndTrend(defectPeaksIndex);
            % Get valid data
            defectWeights = weights(defectPeaksIndex)';
            % Evaluate weights
            weightsStatus = sum(bsxfun(@times, defectWeights, historyValid));
        else
            weightsStatus = 0;
        end
        danger = sum(bsxfun(@times, weights', statusThresholdAndTrend));
    else
        weightsStatus = 0;
        danger = 0;
    end
end