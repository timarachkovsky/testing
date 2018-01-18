% HISTORY_FAN_PUMP_CAVITATION_FLOW_TURBULENCE function returns status of fan defect
% of hisotry
% 
% Defect requirements:
%     main:
%         1) k * bladePass;
%     additional:
% 
% Developer:              Kosmach N.
% Development date:       08.06.2017
% Modified by:            Kosmach N.
% Modification date:      19.09.2017

function [similarityHistory, historyDangerous] = history_fan_PUMP_CAVITATION_FLOW_TURBULENCE(defectStruct, ~)

    bladePassTag = 32; % bladePass tag

    % To evaluate acceleration spectrum
    [statusAcc, dangerAcc] = spectrumEvaluation(defectStruct.accelerationSpectrum, bladePassTag);
    
    % To evaluate envelope acceleration spectrum
    [statusEnv, dangerEnv] = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, bladePassTag);
    
    similarityHistory = max([statusAcc statusEnv]);
    
    similarityHistory(similarityHistory < 0) = 0;
    similarityHistory(similarityHistory > 1) = 1;
    
    historyDangerous = max([dangerAcc dangerEnv]);
end

% ACCSPECTRUMEVALUATION function calculate status to acceleration domain
function [weightsStatus, dangerStatus] = spectrumEvaluation(domain, bladePassTag)

    % Get bladePass data
    [bladePassPositions, ~, bladePassMagnitudes, bladePassWeights, validPositionsBladePass] = getTagPositionsHistory(domain, bladePassTag);
    
    % To get peaks evaluated of history 
    statusHistoryBladePass = ...
        evaluatorThresholdTrend(domain.trendResult(validPositionsBladePass), domain.statusCurrentThreshold(validPositionsBladePass));
    
    % Validation rule
    if ~isempty(bladePassPositions)
        % Preallocate defect peak index
        bladePassDefectPeaksIndex = false(length(bladePassMagnitudes), 1);
        % Evaluate the first peak
        % Check that the first peak is the maximum peak
        bladePassDefectPeaksIndex(1) = bladePassMagnitudes(1) == max(bladePassMagnitudes);
        % Evaluate higher harmonics
        if bladePassDefectPeaksIndex(1)
            for peakNumber = 2 : 1 : length(bladePassMagnitudes)
                % Check that current peak is less than previous peaks
                isLessHigherHarmonic = all(bladePassMagnitudes(peakNumber) < bladePassMagnitudes(bladePassDefectPeaksIndex));
                % Check that current peak is greater than 25% of previous
                % peaks
                isGreaterHigherHarmonic = any(bladePassMagnitudes(peakNumber) > (0.25 * bladePassMagnitudes(bladePassDefectPeaksIndex)));
                % Validate current peak
                bladePassDefectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
            end
        end
        % Get valid history
        statusHistoryBladePassTrue = statusHistoryBladePass(bladePassDefectPeaksIndex);
        % Get valid weights
        bladePassDefectWeights = bladePassWeights(bladePassDefectPeaksIndex);
        % Evaluate weights
        weightsStatus = sum(bsxfun(@times, statusHistoryBladePassTrue, bladePassDefectWeights'));
        
        dangerStatus = sum(bsxfun(@times, statusHistoryBladePass, bladePassWeights'));
    else
        weightsStatus = 0;
        dangerStatus = 0;
    end
end

