% HISTORY_ROLLINGBEARINGN_GROOVES_CRACKS_INNER_RING function returns a status of
% rolling bearing defect "Grooves, Cracks on the Inner Ring history" (defectID = 6)
% 
% Defect requirements:
%     main:
%         1) k1 * BPFI +(-) k2 * shaftFreq (in acceleration envelope
%         spectrum);
%         2) k * BPFI (in acceleration spectrum);
%     additional:
%         1) k * shaftFreq
% 
% Developer:                    Kosmach N.
% Development date:       11.05.2017
% Modified by:            
% Modification date:      


function [similarityHistory, historyDangerous] = ...
    history_rollingBearing_GROOVES_CRACKS_INNER_RING(defectStruct, myFiles)

    BPFITag = 14; % BPFI tag
    shaftFreqTag = 1; % shaftFreq tag
%     modTag = {[14 1]}; % [BPFI +(-) shaftFreq] tag, not used, because one
%     modulation tag

    % To evaluate acceleration spectrum
    [statusAcc, dangerAcc] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, BPFITag, shaftFreqTag);
    
    % To evaluate envelope acceleration spectrum
    [statusEnv, dangerEnv] = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, shaftFreqTag, myFiles);
    
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
function [weightsStatus, dangerStatus] = accSpectrumEvaluation(domain, BPFITag, shaftFreqTag)

    % Get BPFI data
    [~, ~, ~, weightsBPFI, validPositionsBPFI] = getTagPositionsHistory(domain, BPFITag);
    % To get peaks evaluated of history 
    statusThresholdAndTrendBPFI = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsBPFI), domain.statusCurrentThreshold(validPositionsBPFI));
    % Evaluate weights
    BPFIWeightsStatus = sum(bsxfun(@times, weightsBPFI', statusThresholdAndTrendBPFI));
    
    % Get shaft data
    [~, ~, ~, weightsShaft, validPositionsShaft] = getTagPositionsHistory(domain, shaftFreqTag);
    % To get peaks evaluated of history 
    statusThresholdAndTrendShaft = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsShaft), domain.statusCurrentThreshold(validPositionsShaft));
    % Evaluate weights
    shaftWeightsStatus = sum(bsxfun(@times, weightsShaft', statusThresholdAndTrendShaft));
    
    % Combine weights statuses
    if (BPFIWeightsStatus ~= 0)
        weightsStatus = (0.9 * BPFIWeightsStatus) + (0.1 * shaftWeightsStatus);
    else
        weightsStatus = 0;
    end
    
    dangerStatus = weightsStatus;
end

% ACCENVSPECTRUMEVALUATION function calculate status to acceleration envelope domain
function [weightsStatus, dangerStatus] = accEnvSpectrumEvaluation(domain, shaftFreqTag, myFiles)
    
    % Get modulation data
    resultStruct = evaluationModulationHistory(domain, myFiles);
    if nnz(resultStruct.status)
        statusMod =  sum(bsxfun(@times, resultStruct.weightMainPeak, resultStruct.status));
    end
    
    % Get shaft data
    [~, ~, ~, weightsShaft, validPositionsShaft] = getTagPositionsHistory(domain, shaftFreqTag);
    % To get peaks evaluated of history 
    statusThresholdAndTrendShaft = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsShaft), domain.statusCurrentThreshold(validPositionsShaft));
    % Evaluate weights
    shaftWeightsStatus = sum(bsxfun(@times, weightsShaft', statusThresholdAndTrendShaft));
    
    % Combine weights statuses
    if nnz(resultStruct.status)
        weightsStatus = (0.9 * statusMod) + (0.1 * shaftWeightsStatus);
    else
        weightsStatus = 0;
    end
    
    dangerStatus = weightsStatus;
end