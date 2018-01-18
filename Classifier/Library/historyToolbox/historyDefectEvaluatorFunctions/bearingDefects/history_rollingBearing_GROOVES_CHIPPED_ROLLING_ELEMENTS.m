% HISTORY_ROLLINGBEARINGN_GROOVES_CHIPPED_ROLLING_ELEMENTS function returns a
% status of rolling bearing defect "Grooves, chipped on the rolling
% elements" with history (defectID = 8)
% 
% Defect requirements:
%     main:
%         1) 2k1 * BSF +(-) k2 * FTF (in acceleration envelope spectrum);
%         2) 2k * BSF (in acceleration spectrum);
%         3) BEF (?)
%     additional:
%         1) k1 * BSF +(-) k2 * FTF
% 
% Developer:              Kosmach N.
% Development date:       11.05.2017
% Modified by:            Kosmach N.
% Modification date:      14.09.2017


function [similarityHistory, historyDangerous] = ...
    history_rollingBearing_GROOVES_CHIPPED_ROLLING_ELEMENTS(defectStruct, myFiles)

    BSFTag = 12; % BSF tag
%     modTag = [12 11]; % [BSF +(-) FTF] tag, not used, because one
%     modulation tag

    % To evaluate acceleration spectrum
    [statusAcc, dangerAcc] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, BSFTag, myFiles);
    
    % To evaluate envelope acceleration spectrum
    [statusEnv, dangerEnv] = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, myFiles);
    
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
function [weightsStatus, dangerStatus] = accSpectrumEvaluation(domain, BSFTag, myFiles)

    % modTag - is not used, because function have one 

    weightsStatus = 0;

    % Get BSF data
    [BSFPositions, ~, weights, ~, validPositions] = getTagPositionsHistory(domain, BSFTag);
    
    if ~isempty(BSFPositions)
        % Find odd BSF positions index
        evenBSF = ~logical(mod(BSFPositions, 2));
    else
        evenBSF = 0;
    end
    
    % To get peaks evaluated of history 
        statusThresholdAndTrend = ...
            evaluatorThresholdTrend(domain.trendResult(validPositions), domain.statusCurrentThreshold(validPositions));
        
    if nnz(evenBSF)
        weightsStatus = sum(bsxfun(@times, weights(evenBSF)' * 2, statusThresholdAndTrend(evenBSF)));
    end
        
    % Get modulation data
    resultStruct = evaluationModulationHistory(domain, myFiles);
    if nnz(resultStruct.status)
        modulationStatus = sum(bsxfun(@times, resultStruct.weightMainPeak, resultStruct.status));
        weightsStatus = weightsStatus + sum(bsxfun(@times, resultStruct.weightMainPeak * 0.2, resultStruct.status));
    else
        modulationStatus = 0;
    end
    
    dangerStatus = sum(bsxfun(@times, weights', statusThresholdAndTrend)) + modulationStatus;
end

% ACCENVSPECTRUMEVALUATION function calculate status to acceleration envelope domain
function [weightsStatus, dangerStatus] = accEnvSpectrumEvaluation(domain, myFiles)
    
    % Get modulation data
    resultStruct = evaluationModulationHistory(domain, myFiles);
    if nnz(resultStruct.status)
        weightsStatus =  sum(bsxfun(@times, resultStruct.weightMainPeak * 2, resultStruct.status));
    else
        weightsStatus = 0;
    end
    
    dangerStatus = weightsStatus;
end

