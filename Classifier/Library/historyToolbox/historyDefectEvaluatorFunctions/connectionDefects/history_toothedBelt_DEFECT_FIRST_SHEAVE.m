% HISTORY_TOOTHEDBELT_DEFECT_FIRST_SHEAVE function returns status of smooth belt
% defect of history
% 
% Defect requirements:
%     main:
%         1) k * sheaveFreq1, k > 4;
%         2) k1 * meshingFreq +(-) k2 * sheaveFreq1;
%     additional:
% 
% Developer:              Kosmach N.
% Development date:       07.06.2017
% Modified by:            Kosmach N.
% Modification date:      22.09.2017

function [similarityHistory, historyDangerous] = history_toothedBelt_DEFECT_FIRST_SHEAVE(defectStruct, myFiles)

    sheaveFreq1Tag = 29; % driving sheave frequency tag
    modTag = [31 29]; % [meshingFreq +(-) sheaveFreq1] tag
    
    % ACCELERATION ENVELOPE SPECTRUM evaluation
    [statusEnvAcc, dangerEnv] = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, sheaveFreq1Tag, modTag, myFiles);
    
    % ACCELERATION SPECTRUM evaluation
    [statusAcc, dangerAcc] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, sheaveFreq1Tag, modTag, myFiles);
    
    % Combine results
    results = [statusAcc statusEnvAcc];
    results(results < 0) = 0;
    results(results > 1) = 1;
    if statusEnvAcc > statusAcc
        similarityHistory = (min(results) + rms(results)) / 2;
    else
        similarityHistory = statusEnvAcc;
    end
    
    historyDangerous = max([dangerEnv dangerAcc]);
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum 
function [weightsStatus, dangerStatus] = accEnvSpectrumEvaluation(domain, sheaveFreq1Tag, modTag, myFiles)
    
    % Get sheaveFreq1 data
    [positions, ~, magnitudes, weights, positionValid] = getTagPositionsHistory(domain, sheaveFreq1Tag);
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
        beltWeightsStatus = sum(bsxfun(@times, defectWeights, historyValid));
        
        dangerStatus = sum(bsxfun(@times, weights', statusThresholdAndTrend));
    else
        beltWeightsStatus = 0;
        dangerStatus = 0;
    end
    
    resultStructMod = evaluationModulationHistory(domain, myFiles);
    % To find needed tag for mod
    positionsModTrue = bsxfun(@and, resultStructMod.mainTag == modTag(1), resultStructMod.sideBandTag == modTag(2));                                  
    % Evaluate weights for mod
    modWeightsStatus = sum(bsxfun(@times, resultStructMod.status(positionsModTrue), ...
                                             resultStructMod.weightMainPeak(positionsModTrue)));
                                         
    % Combine weights statuses
    if (modWeightsStatus ~= 0)
        weightsStatus = (beltWeightsStatus + modWeightsStatus) / 2;
        dangerStatus = (dangerStatus + modWeightsStatus) / 2;
    else
        weightsStatus = 0;
        dangerStatus = 0;
    end
end

% ACCSPECTRUMEVALUATION function evaluates acceleration spectrum
function [weightsStatus, dangerStatus] = accSpectrumEvaluation(domain, sheaveFreq1Tag, modTag, myFiles)
    
    % Get sheaveFreq1 data
    [positions, ~, magnitudes, weights, positionValid] = getTagPositionsHistory(domain, sheaveFreq1Tag);
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
        beltWeightsStatus = sum(bsxfun(@times, defectWeights, historyValid));
        
        dangerStatus = sum(bsxfun(@times, weights', statusThresholdAndTrend));
    else
        beltWeightsStatus = 0;
        dangerStatus = 0;
    end
    
    resultStructMod = evaluationModulationHistory(domain, myFiles);
    % To find needed tag for mod
    positionsModTrue = bsxfun(@and, resultStructMod.mainTag == modTag(1), resultStructMod.sideBandTag == modTag(2));                                  
    % Evaluate weights for mod
    modWeightsStatus = sum(bsxfun(@times, resultStructMod.status(positionsModTrue), ...
                                             resultStructMod.weightMainPeak(positionsModTrue)));
                                         
    % Combine weights statuses
    if (modWeightsStatus ~= 0)
        weightsStatus = (beltWeightsStatus + modWeightsStatus) / 2;
        dangerStatus = (dangerStatus + modWeightsStatus) / 2;
    else
        weightsStatus = 0;
        dangerStatus = 0;
    end
end