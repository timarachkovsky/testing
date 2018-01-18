% HISTORY_ROLLINGBEARINGN_COCKED_INNER_RING_DEFECT_ROLLING_ELEMENT
% function returns a status of rolling bearing defect "Misalignment of the
% inner ring and the rolling elements defects with history" (defectID = 10)
% 
% Defect requirements:
%     main:
%         1) k1 * BSF +(-) k2 * shaftFreq (in acceleration envelope
%         spectrum)
%            
% Developer:              Kosmach N.
% Development date:       11.05.2017 
% Modified by:            Kosmach N.
% Modification date:      13.09.2017     

function [similarityHistory, historyDangerous] = ...
    history_rollingBearing_COCKED_INNER_RING_DEFECT_ROLLING_ELEMENT(defectStruct, myFiles)
    
%     modTag = {[12 1]}; % [BSF +(-) shaftFreq] tag % not need, because here use only one type of modulation

    similarityHistory = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, myFiles);
    similarityHistory(similarityHistory < 0) = 0;
    similarityHistory(similarityHistory > 1) = 1;
    
    historyDangerous = similarityHistory;
end

% SPECTRUMEVALUATION function evaluates spectrum
function [status] = spectrumEvaluation(domain, myFiles)
    
    resultStruct  =  evaluationModulationHistory(domain, myFiles);
    
    if ~nnz(resultStruct.weightMainPeak)
        status = 0;
        return
    end
    
    status = sum(resultStruct.status .* resultStruct.weightMainPeak);
end