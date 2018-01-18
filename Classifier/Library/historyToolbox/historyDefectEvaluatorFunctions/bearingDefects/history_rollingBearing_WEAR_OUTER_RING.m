% HISTORY_ROLLINGBEARINGN_WEAR_OUTER_RING function returns a status of
% rolling bearing defect "Wear of the Outer Ring" with history (defectID = 3)
% 
% Defect requirements:
%     main:
%         1) BPFO;
%     additional:
%         1) k * BPFO, k < 4
% 
% Developer:              P. Riabtsev
% Development date:       15-05-2017
% Modified by:            
% Modification date:      

function [similarityHistory, historyDangerous] = history_rollingBearing_WEAR_OUTER_RING(defectStruct, ~)

    BPFOTag = 13; % BPFO tag

    % To evaluate acceleration spectrum
    [statusAcc, dangerAcc] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, BPFOTag);
    
    % To evaluate envelope acceleration spectrum
    [statusEnv, dangerEnv] = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, BPFOTag);
    
    results = [statusAcc statusEnv];
    results(results < 0) = 0;
    results(results > 1) = 1;
    if statusAcc > statusEnv
        similarityHistory = (min(results) + rms(results)) / 2;
    else
        similarityHistory = statusEnv;
    end
    
    historyDangerous = max([dangerAcc dangerEnv]);
end

% ACCSPECTRUMEVALUATION function calculate status to acceleration domain
function [weightsStatus, dangerAcc] = accSpectrumEvaluation(domain, BPFOTag)

    % Get BPFO data
    [~, ~, ~, weightsBPFO, validPositionsBPFO] = getTagPositionsHistory(domain, BPFOTag);
    % To get peaks evaluated of history 
    statusThresholdAndTrendBPFO = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsBPFO), domain.statusCurrentThreshold(validPositionsBPFO));
    % Evaluate weights
    weightsStatus = sum(bsxfun(@times, weightsBPFO', statusThresholdAndTrendBPFO));
    
    dangerAcc = weightsStatus;
end

% ACCENVSPECTRUMEVALUATION function calculate status to acceleration envelope domain
function [weightsStatus, dangerEnv] = accEnvSpectrumEvaluation(domain, BPFOTag)
    
    % Get BPFO data
    [positions, ~, magnitudes, weights, validPositions] = getTagPositionsHistory(domain, BPFOTag);
    % To get peaks evaluated of history 
    statusThresholdAndTrendBPFO = ...
        evaluatorThresholdTrend(domain.trendResult(validPositions), domain.statusCurrentThreshold(validPositions));
    % Validation rule
    if ~isempty(positions)
        % Preallocate defect peaks index
        defectPeaksIndex = false(length(magnitudes), 1);
        % Evaluate the first peak
        defectPeaksIndex(1) = magnitudes(1) == max(magnitudes);
        % Evaluate higher harmonics
        for peakNumber = 2 : 1 : length(magnitudes)
            % Check that current peak less than 75% of previous defect peaks
            isLessHigherHarmonic = all(magnitudes(peakNumber) < (0.75 * magnitudes(defectPeaksIndex)));
            % Check that current peak is greater than 25% of previous peaks
            isGreaterHigherHarmonic = any(magnitudes(peakNumber) > (0.25 * magnitudes(defectPeaksIndex)));
            % Validate current peak
            defectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
        end
        % Get valid weights
        defectWeights = weights(defectPeaksIndex);
        % Get hitory validity
        defectHistory = statusThresholdAndTrendBPFO(defectPeaksIndex);
        % Evaluate weights
        weightsStatus = sum(bsxfun(@times, defectWeights', defectHistory));
        
        dangerEnv = sum(bsxfun(@times, weights', statusThresholdAndTrendBPFO));
    else
        weightsStatus = 0;
        dangerEnv = 0;
    end
end