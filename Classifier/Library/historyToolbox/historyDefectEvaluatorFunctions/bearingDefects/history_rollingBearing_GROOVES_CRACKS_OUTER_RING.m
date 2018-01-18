% HISTORY_ROLLINGBEARINGN_GROOVES_CRACKS_OUTER_RING function returns a status of
% rolling bearing defect "Grooves, Cracks on the Outer Ring" with history (defectID = 4)
% 
% Defect requirements:
%     main:
%         1) k * BPFO, k > 3
% 
% Developer:              Kosmach N.
% Development date:       11.05.2017
% Modified by:            Kosmach N.
% Modification date:      14.09.2017


function [similarityHistory, historyDangerous] = ...
    history_rollingBearing_GROOVES_CRACKS_OUTER_RING(defectStruct, ~)

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
    
    historyDangerous = max([dangerEnv, dangerAcc]);
end

% ACCSPECTRUMEVALUATION function calculate status to acceleration domain
function [weightsStatus, dangerAcc] = accSpectrumEvaluation(domain, BPFOTag)

    % Get shaft data
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
    [positions, ~, magnitudes, weightsBPFO, validPositionsBPFO] = getTagPositionsHistory(domain, BPFOTag);
    
    % To get peaks evaluated of history 
    statusThresholdAndTrendBPFO = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsBPFO), domain.statusCurrentThreshold(validPositionsBPFO));
    
    % Validation rule
    if ~isempty(positions) || nnz(statusThresholdAndTrendBPFO)
        % Preallocate defect peaks index
        defectPeaksIndex = false(length(magnitudes), 1);
        % Evaluate the first peak
        % Check that the first peak is greater than 91% of the maximum peak
        defectPeaksIndex(1) = magnitudes(1) > (0.91 * max(magnitudes));
        % Evaluate higher harmonics
        for peakNumber = 2 : 1 : length(magnitudes)
            % Check that current peak is less than 110% of previous peaks
            isLessHigherHarmonic = all(magnitudes(peakNumber) < (1.10 * magnitudes(defectPeaksIndex)));
            % Check that current peak is greater than 90% of previous peaks
            isGreaterHigherHarmonic = any(magnitudes(peakNumber) > (0.90 * magnitudes(defectPeaksIndex)));
            % Validate current peak
            defectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
        end
        % Get valid weights
        defectWeights = weightsBPFO(defectPeaksIndex);
        %
        statusThresholdAndTrendBPFOWithPattern = statusThresholdAndTrendBPFO(defectPeaksIndex);
        % Evaluate weights
        weightsStatus = sum(bsxfun(@times, defectWeights', statusThresholdAndTrendBPFOWithPattern));
        
        dangerEnv = sum(bsxfun(@times, weightsBPFO', statusThresholdAndTrendBPFO));
    else
        dangerEnv = 0;
        weightsStatus = 0;
    end
end