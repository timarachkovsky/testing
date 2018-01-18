% HISTORY_SMOOTHBELT_DEFECT_SECOND_SHEAVE function returns status of smooth belt
% defect of history
% 
% Defect requirements:
%     main:
%         1) k * sheaveFreq2, k > 4;
%     additional:
% 
% Developer:              Kosmach N.
% Development date:       07.06.2017
% Modified by:            Kosmach N.
% Modification date:      22.09.2017

function [similarityHistory, historyDangerous] = history_smoothBelt_DEFECT_SECOND_SHEAVE(defectStruct, ~)

    sheaveFreq2Tag = 30; % driven sheave frequency tag
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    [statusEnvAcc, dangerEnv] = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, sheaveFreq2Tag);
    
    % ACCELERATION SPECTRUM evaluation
    [statusAcc, dangerAcc] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, sheaveFreq2Tag);
    
    % Combine results
    results = [statusAcc statusEnvAcc];
    results(results < 0) = 0;
    results(results > 1) = 1;
    if statusEnvAcc > statusAcc
        similarityHistory = (min(results) + rms(results)) / 2;
    else
        similarityHistory = statusEnvAcc;
    end
    
    historyDangerous = max([dangerEnv, dangerAcc]);
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum 
function [weightsStatus, dangerStatus] = accEnvSpectrumEvaluation(domain, sheaveFreq2Tag)
    
    % Get sheaveFreq2 data
    [positions, ~, magnitudes, weights, positionValid] = getTagPositionsHistory(domain, sheaveFreq2Tag);
    % To get peaks evaluated of history 
    statusThresholdAndTrend = evaluatorThresholdTrend(domain.trendResult(positionValid), domain.statusCurrentThreshold(positionValid));
    % Validation rule
    if ~isempty(positions)
        % Preallocate defect peak index
        defectPeaksIndex = false(length(magnitudes), 1);
        % Evaluate the first peak
        % Check that the first peak is the maximum peak
        defectPeaksIndex(1) = magnitudes(1) == max(magnitudes);
        % Evaluate higher harmonics
        if defectPeaksIndex(1)
            for peakNumber = 2 : 1 : length(magnitudes)
                % Check that current peak is less than previous peaks
                isLessHigherHarmonic = all(magnitudes(peakNumber) < magnitudes(defectPeaksIndex));
                % Check that current peak is greater than 25% of previous
                % peaks
                isGreaterHigherHarmonic = any(magnitudes(peakNumber) > (0.25 * magnitudes(defectPeaksIndex)));
                % Validate current peak
                defectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
            end
        end
        % Get valid history
        historyValid = statusThresholdAndTrend(defectPeaksIndex);
        % Get valid weights
        defectWeights = weights(defectPeaksIndex)';
        % Evaluate weights
        weightsStatus = sum(bsxfun(@times, defectWeights, historyValid));
        dangerStatus = sum(bsxfun(@times, weights', statusThresholdAndTrend));
    else
        weightsStatus = 0;
        dangerStatus = 0;
    end
end

% ACCSPECTRUMEVALUATION function evaluates acceleration spectrum
function [weightsStatus, dangerStatus] = accSpectrumEvaluation(domain, sheaveFreq2Tag)
    
    % Get sheaveFreq2 data
    [positions, ~, magnitudes, weights, positionValid] = getTagPositionsHistory(domain, sheaveFreq2Tag);
    % To get peaks evaluated of history 
    statusThresholdAndTrend = evaluatorThresholdTrend(domain.trendResult(positionValid), domain.statusCurrentThreshold(positionValid));
    % Validation rule
    if ~isempty(positions)
        % Preallocate defect peak index
        defectPeaksIndex = false(length(magnitudes), 1);
        % Evaluate the first harmonic
        defectPeaksIndex(1) = true;
        % Evaluate higher harmonic
        defectPeaksIndex(2 : end) = magnitudes(2 : end) < magnitudes(1);
        % Get valid history
        historyValid = statusThresholdAndTrend(defectPeaksIndex);
        % Get valid weights
        defectWeights = weights(defectPeaksIndex)';
        % Evaluate weights
        weightsStatus = sum(bsxfun(@times, defectWeights, historyValid));
        dangerStatus = sum(bsxfun(@times, weights', statusThresholdAndTrend));
    else
        weightsStatus = 0;
        dangerStatus = 0;
    end
end