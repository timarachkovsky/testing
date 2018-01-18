% HISTORY_ROLLINGBEARING_WEAR_INNER_RING function returns status of rolling bearing
% defect "Wear of the inner ring" with history (defectID = 5)
% 
% Defect requirements:
%     main:
%         1) k * shaftFreq;
%     additional:
%         1) BPFI;
% 
% Developer:              Kosmach N.
% Development date:       15.05.2017
% Modified by:            Kosmach N.
% Modification date:      14.09.2017

function [similarityHistory, historyDangerous] = history_rollingBearing_WEAR_INNER_RING(defectStruct, ~)

    BPFITag = 14; % BPFI tag
    shaftFreqTag = 1; % shaftFreq tag

    % To evaluate acceleration spectrum
    [statusAcc, dangerAcc] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, BPFITag, shaftFreqTag);
    
    % To evaluate envelope acceleration spectrum
    [statusEnv, dangerEnv] = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, shaftFreqTag, BPFITag);
    
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
function [weightsStatus, dangerAcc] = accSpectrumEvaluation(domain, BPFITag, shaftFreqTag)

    % Get BPFI data
    [~, ~, ~, weightsBPFI, validPositionsBPFI] = getTagPositionsHistory(domain, BPFITag);
    % To get peaks evaluated of history 
    statusThresholdAndTrendBPFI = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsBPFI), domain.statusCurrentThreshold(validPositionsBPFI));
    % Evaluate status
    BPFIWeightsStatus = sum(bsxfun(@times, weightsBPFI', statusThresholdAndTrendBPFI));
    
    % Get shaft data
    [~, ~, ~, weightsShaft, validPositionsShaft] = getTagPositionsHistory(domain, shaftFreqTag);
    % To get peaks evaluated of history 
    statusThresholdAndTrendShaft = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsShaft), domain.statusCurrentThreshold(validPositionsShaft));
    % Evaluate status
    shaftWeightsStatus = sum(bsxfun(@times, weightsShaft', statusThresholdAndTrendShaft));
    
    % Combine weights statuses
    if (BPFIWeightsStatus ~= 0)
        weightsStatus = (BPFIWeightsStatus + shaftWeightsStatus)/2 ;
    else
        weightsStatus = 0;
    end
    
    dangerAcc = weightsStatus;
end

% ACCENVSPECTRUMEVALUATION function calculate status to acceleration envelope domain
function [weightsStatus, dangerEnv] = accEnvSpectrumEvaluation(domain, shaftFreqTag, BPFITag)
    
    % Get shaft data
    [shaftPositions, ~, shaftMagnitudes, shaftWeights, validPositionsShaft] = getTagPositionsHistory(domain, shaftFreqTag);
    
    % To get peaks evaluated of history 
    statusThresholdAndTrendShaft = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsShaft), domain.statusCurrentThreshold(validPositionsShaft));
    
    if ~isempty(shaftPositions)
        % Preallocate defect peaks index
        shaftDefectPeaksIndex = false(length(shaftMagnitudes), 1);
        % Evalaute the first peak
        shaftDefectPeaksIndex(1) = shaftMagnitudes(1) == max(shaftMagnitudes);
        % Evaluate the higher harmonics
        for peakNumber = 2 : 1 : length(shaftMagnitudes)
            % Check that current peak is less than of previous defect peaks
            isLessHigherHarmonic = all(shaftMagnitudes(peakNumber) < shaftMagnitudes(shaftDefectPeaksIndex));
            % Check that current peak is greater than 75% of previous peak
            isGreaterHigherHarmonic = any(shaftMagnitudes(peakNumber) > (0.75 * shaftMagnitudes(shaftDefectPeaksIndex)));
            % Validate current peak
            shaftDefectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
        end
        % Get valid weights
        shaftFreqDefectWeights = shaftWeights(shaftDefectPeaksIndex);
        % Get valid history
        shaftDefectHistory = statusThresholdAndTrendShaft(shaftDefectPeaksIndex);
        % Evaluate weights
        shaftFreqWeightsStatus = sum(bsxfun(@times, shaftFreqDefectWeights', shaftDefectHistory));
        
        shaftStatusDanger = sum(bsxfun(@times, shaftWeights', statusThresholdAndTrendShaft));
    else
        shaftFreqWeightsStatus = 0;
        shaftStatusDanger = 0;
    end
    
    % Get BPFI data
    [~, ~, ~, shaftBPFI, validPositionsBPFI] = getTagPositionsHistory(domain, BPFITag);
    % To get peaks evaluated of history 
    statusThresholdAndTrendBPFI = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsBPFI), domain.statusCurrentThreshold(validPositionsBPFI));
    % Evaluate status
    BPFIWeightsStatus = sum(bsxfun(@times, shaftBPFI', statusThresholdAndTrendBPFI));
    
    % Combine weights statuses
    if (BPFIWeightsStatus ~= 0)
        weightsStatus = (shaftFreqWeightsStatus + BPFIWeightsStatus) / 2;
    else
        weightsStatus = 0;
    end
    
    dangerEnv = (shaftStatusDanger + BPFIWeightsStatus) / 2;
end

