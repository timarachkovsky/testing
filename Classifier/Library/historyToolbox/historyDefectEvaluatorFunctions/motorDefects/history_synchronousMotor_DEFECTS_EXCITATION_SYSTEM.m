% HISTORY_SYNCHRONOUSMOTOR_DEFECTS_EXCITATION_SYSTEM function returns status of
% synchronous motor defect of history
% 
% Defect requirements:
%     main:
%         1) k1 * coilFreq +(-) k2 * shaftFreq, k1 < 4;
%     additional:
% 
% Developer:              Kosmach N.
% Development date:       06.06.2017
% Modified by:            Kosmach N.
% Modification date:      25.09.2017

function [similarityHistory, historyDangerous] = history_synchronousMotor_DEFECTS_EXCITATION_SYSTEM(defectStruct,myFiles)
%     modTag = {[10 1]}; % [coilFreq +(-) shaftFreq] tag

    similarityHistory = spectrumEvaluation(defectStruct.accelerationSpectrum, myFiles);
    historyDangerous = similarityHistory;
end

% SPECTRUMEVALUATION function evaluates spectrum
function [weightsStatus] = spectrumEvaluation(domain, myFiles)

    % Get modulation data
    resultStruct = evaluationModulationHistory(domain, myFiles);
    if nnz(resultStruct.status)
        weightsStatus =  sum(bsxfun(@times, resultStruct.weightMainPeak, resultStruct.status));
    else
        weightsStatus = 0;
    end
end