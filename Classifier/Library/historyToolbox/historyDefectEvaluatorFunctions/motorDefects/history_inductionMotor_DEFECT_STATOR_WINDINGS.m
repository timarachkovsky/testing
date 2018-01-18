% HISTORY_INDUCTIONMOTOR_DEFECT_STATOR_WINDINGS function returns status of
% synchronous motor defect of history
% 
% Defect requirements:
%     main:
%         1) k1 * barsFreq +(-) k2 * twiceLineFreq, k1 < 4;
%     additional:
%         1) 1 * twiceLineFreq;
% 
% Developer:              Kosmach N.
% Development date:       06.06.2017
% Modified by:            Kosmach N.
% Modification date:      25.09.2017

function [similarityHistory, historyDangerous] = history_inductionMotor_DEFECT_STATOR_WINDINGS(defectStruct, myFiles)

%     modTag = {[4 3]}; % [barFreq +(-) twiceLineFreq] tag
    TLFTag = 3; % twice line frequency tag

    similarityHistory = spectrumEvaluation(defectStruct.accelerationSpectrum, myFiles, TLFTag);
    historyDangerous = similarityHistory;
end

% SPECTRUMEVALUATION function evaluates spectrum
function [weightsStatus] = spectrumEvaluation(domain, myFiles, TLFTag)
    % Get modulation data
    resultStruct = evaluationModulationHistory(domain, myFiles);
    if nnz(resultStruct.status)
        statusMod =  sum(bsxfun(@times, resultStruct.weightMainPeak, resultStruct.status));
    end
    
    % Get TLF data
    [~, ~, ~, weightsTLF, validPositionsTLF] = getTagPositionsHistory(domain, TLFTag);
    % To get peaks evaluated of history 
    statusThresholdAndTrendTLF = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsTLF), domain.statusCurrentThreshold(validPositionsTLF));
    % Evaluate weights
    TLFWeightsStatus = sum(bsxfun(@times, weightsTLF', statusThresholdAndTrendTLF));
    
    % Combine weights statuses
    if nnz(resultStruct.status)
        weightsStatus = statusMod + (0.2 * TLFWeightsStatus);
    else
        weightsStatus = 0;
    end
end