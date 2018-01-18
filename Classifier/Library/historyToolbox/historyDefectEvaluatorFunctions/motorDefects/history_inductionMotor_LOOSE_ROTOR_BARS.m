% HISTORY_INDUCTIONMOTOR_LOOSE_ROTOR_BARS function returns status of induction
% motor defect of history
% 
% Defect requirements:
%     main:
%         1) k1 * barFreq +(-) k2 * twiceLineFreq, k1 = [1, 2];
%     additional:
%         1) 2 * barFreq > 1 * barFreq;
% 
% Developer:              Kosmach N.
% Development date:       06.06.2017
% Modified by:            Kosmach N.
% Modification date:      25.09.2017

function [similarityHistory, historyDangerous] = history_inductionMotor_LOOSE_ROTOR_BARS(defectStruct, myFiles)

%     modTag = {[4 3]}; % [barFreq +(-) twiceLineFreq] tag

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
    
    % Find the first harmonic index
    firstHarmonicIndex = resultStruct.position == 1;
    % Find the second harmonic index
    secondHarmonicIndex = resultStruct.position == 2;
    % Evaluate additional requirement
    if (resultStruct.magnitudes(secondHarmonicIndex) > resultStruct.magnitudes(firstHarmonicIndex))
        weightsStatus = weightsStatus + 0.2;
    end
end
