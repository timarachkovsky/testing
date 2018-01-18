% HISTORY_SHAFT_SHAFT_RUN_OUT function returns a status of shaft defect "Shaft
% run-out" with history (defectID = 1)
% 
% Defect requirements:
%     main:
%         1) k * shaftFreq, k < 10;
%         2) k * shaftFreq < (k - 1) * shaftFreq
% 
% Developer:              Kosmach N.
% Development date:       04.03.2017
% Modified by:            Kosmach N.
% Modification date:      18.09.2017   

function [similarityHistory, historyDangerous] = history_shaft_SHAFT_RUN_OUT(defectStruct,~)

    shaftFreq = 1; % shaftFreq tag

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
    
    historyDangerous = max([dangerAcc dangerDisp]);
end

% ACCSPECTRUMEVALUATION function calculate status to acceleration domain
function [weightsStatus, danger] = accSpectrumEvaluation(domain, shaftFreq)

    % To evaluate with pattern
    [~, ~, ~, weights, positionsPattern] = getTagPositionsHistory(domain, shaftFreq);
    
    % To get peaks evaluated of history 
    statusThresholdAndTrend = evaluatorThresholdTrend(domain.trendResult(positionsPattern), domain.statusCurrentThreshold(positionsPattern));
    
    % To calculateresult
    weightsStatus = sum(weights' .* statusThresholdAndTrend);
    
    danger = weightsStatus;
end

% DISPSPECTRUMEVALUATION function calculate status to acceleration envelope domain
function [weightsStatus, danger] = dispSpectrumEvaluation(domain, shaftFreq)

    % Get shaft data
    [positions, names, magnitudes, weights, positionValid] = getTagPositionsHistory(domain, shaftFreq);
    % To get peaks evaluated of history 
    statusThresholdAndTrend = evaluatorThresholdTrend(domain.trendResult(positionValid), ...
        domain.statusCurrentThreshold(positionValid), domain.trainingPeriodInitialTagNames, names);
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
        % Get valid history
        historyValid = statusThresholdAndTrend(defectPeaksIndex);
        % Get valid data
        defectWeights = weights(defectPeaksIndex)';
        % Evaluate weights
        weightsStatus = sum(bsxfun(@times, defectWeights, historyValid));
        danger = sum(bsxfun(@times, weights', statusThresholdAndTrend));
    else
        weightsStatus = 0;
        danger = 0;
    end
end