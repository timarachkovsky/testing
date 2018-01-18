% HISTORY_FAN_BLADE_FAULTS function returns status of fan defect of history
% 
% Defect requirements:
%     main:
%         1) k1 * bladePass +(-) k2 * shaftFreq;
%     additional:
% 
% Developer:              Kosmach N.
% Development date:       08.06.2017
% Modified by:            Kosmach N.
% Modification date:      18.09.2017

function [similarityHistory, historyDangerous] = history_fan_BLADE_FAULTS(defectStruct, myFiles)

    shaftFreqTag = 1; % shaft frequency tag
%     modTag = [3 1]; % [bladePass +(-) shaftFreq] tag not used, because one
%     modulation tag

    % To evaluate acceleration spectrum
    [statusAcc, dangerAcc] = spectrumEvaluation(defectStruct.accelerationSpectrum, shaftFreqTag, myFiles);
    
    % To evaluate envelope acceleration spectrum
    [statusEnv, dangerEnv] = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, shaftFreqTag, myFiles);
    
    similarityHistory = max([statusAcc statusEnv]);
    
    similarityHistory(similarityHistory < 0) = 0;
    similarityHistory(similarityHistory > 1) = 1;
    
    historyDangerous = max([dangerAcc dangerEnv]);
end

% ACCSPECTRUMEVALUATION function calculate status to acceleration domain
function [weightsStatus, dangerStatus] = spectrumEvaluation(domain, shaftFreqTag, myFiles)

    % modTag - is not used, because function have one modulation tag

    weightsStatus = 0;

    % Get shaft data
    [shaftFreqPositions, ~, shaftFreqMagnitudes, shaftFreqWeights, validPositionsShaft] = getTagPositionsHistory(domain, shaftFreqTag);
    
    % To get peaks evaluated of history 
    statusHistoryShaft = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsShaft), domain.statusCurrentThreshold(validPositionsShaft));
    
    % Validation rule
    if ~isempty(shaftFreqPositions)
        % Preallocate defect peak index
        shaftFreqDefectPeaksIndex = false(length(shaftFreqMagnitudes), 1);
        % Evaluate the first peak
        % Check that the first peak is the maximum peak
        shaftFreqDefectPeaksIndex(1) = shaftFreqMagnitudes(1) == max(shaftFreqMagnitudes);
        % Evaluate higher harmonics
        if shaftFreqDefectPeaksIndex(1)
            for peakNumber = 2 : 1 : length(shaftFreqMagnitudes)
                % Check that current peak is less than previous peaks
                isLessHigherHarmonic = all(shaftFreqMagnitudes(peakNumber) < shaftFreqMagnitudes(shaftFreqDefectPeaksIndex));
                % Check that current peak is greater than 25% of previous
                % peaks
                isGreaterHigherHarmonic = any(shaftFreqMagnitudes(peakNumber) > (0.25 * shaftFreqMagnitudes(shaftFreqDefectPeaksIndex)));
                % Validate current peak
                shaftFreqDefectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
            end
        end
        % Get valid history
        statusHistoryShaftTure = statusHistoryShaft(shaftFreqDefectPeaksIndex);
        % Get valid weights
        shaftFreqDefectWeights = shaftFreqWeights(shaftFreqDefectPeaksIndex);
        % Evaluate weights
        shaftStatus = sum(bsxfun(@times, statusHistoryShaftTure, shaftFreqDefectWeights'));
        
        dangerStatus = sum(bsxfun(@times, statusHistoryShaft, shaftFreqWeights'));
    else
        shaftStatus = 0;
        dangerStatus = 0;
    end
        
    % Get modulation data
    resultStructMod = evaluationModulationHistory(domain, myFiles);
    if nnz(resultStructMod.status)
        
        statusMod = sum(bsxfun(@times, resultStructMod.weightMainPeak, resultStructMod.status));
        
        weightsStatus = shaftStatus + statusMod;
        
        dangerStatus = dangerStatus + statusMod;
    end
end