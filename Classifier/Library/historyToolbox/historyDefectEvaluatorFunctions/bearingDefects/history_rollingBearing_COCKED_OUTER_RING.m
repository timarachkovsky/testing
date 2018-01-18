% HISTORY_ROLLINGBEARINGN_MISALIGNMENT_OUTER_RING function returns a status of
% rolling bearing defect "Misalignment of the Outer Ring" with history (defectID = 2)
% 
% Defect requirements:
%     main:
%         1) 2 * BPFO;
%     additional:
%         1) 2k * BPFO
% 
% Developer:              Kosmach N.
% Development date:       15.05.2017
% Modified by:            Kosmach N.
% Modification date:      13.09.2017

function [similarityHistory, historyDangerous] = history_rollingBearing_COCKED_OUTER_RING(defectStruct, ~)

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
    
    historyDangerous = max([dangerEnv dangerAcc]);
end

% ACCSPECTRUMEVALUATION function calculate status to acceleration domain
function [weightsStatus, dangerStatus] = accSpectrumEvaluation(domain, BPFOTag)

    % To evaluate with pattern
    [~, ~, ~, ~, positionsPattern] = getTagPositionsHistory(domain, BPFOTag);
    
    % To get weights all peaks
    weight = str2num(domain.defectiveWeights{1, 1});

    % To get peaks evaluated of history 
    statusThresholdAndTrend = evaluatorThresholdTrend(domain.trendResult, domain.statusCurrentThreshold);
    
    % To calculateresult
    weight(~positionsPattern) = 0;
    weightsStatus = sum(weight .* statusThresholdAndTrend);
    
    dangerStatus = weightsStatus;
end

% ACCENVSPECTRUMEVALUATION function calculate status to acceleration envelope domain
function [weightsStatus, dangerStatus] = accEnvSpectrumEvaluation(domain, BPFOTag)

    % To evaluate with pattern
    positionsPattern = accEnvSpectrumEvaluationPattern(domain, BPFOTag);
    
   
    % To get weights all peaks
    weight = str2num(domain.defectiveWeights{1, 1});
    
    if ~isempty(weight)
        % To get peaks evaluated of history 
        statusThresholdAndTrend = evaluatorThresholdTrend(domain.trendResult, domain.statusCurrentThreshold);

        % To get history danger
        [~, ~, ~, ~, positionsPatternHistory] = getTagPositionsHistory(domain, BPFOTag);
        tempWeight = weight;
        tempWeight(~positionsPatternHistory) = 0;
        dangerStatus = sum(tempWeight .* statusThresholdAndTrend);
        
        % To calculateresult
        weight(~positionsPattern) = 0;
        weightsStatus = sum(weight .* statusThresholdAndTrend);
    else
        weightsStatus = 0;
        dangerStatus = 0;
    end
end

% ACCENVSPECTRUMEVALUATION function evaluates acceleration envelope
% spectrum with pattern
function [positionsPattern] = accEnvSpectrumEvaluationPattern(domain, BPFOTag)

    % Get BPFO data
    [positions, ~, magnitudes, ~, positionValid] = getTagPositionsHistory(domain, BPFOTag);
    % Validation rule
    if ~isempty(positions)
        % Find odd positions index
        oddPositionsIndex = logical(mod(positions, 2));
        % Get odd positions data
        oddPositions = positions(oddPositionsIndex);
        oddMagnitudes = magnitudes(oddPositionsIndex);
        % Get even positions data
        evenPositions = positions(~oddPositionsIndex);
        evenMagnitudes = magnitudes(~oddPositionsIndex);
        % Evaluate even positions
        if ~isempty(evenPositions)
            % Calculate previous even positions
            previousEvenPositions = evenPositions - 1;
            % Get magnitudes of existing odd positions which are previous
            % the even positions
            previousEvenMagnitudes = zeros(length(previousEvenPositions), 1);
            [~, existPreviousEvenIndex, existOddIndex] = intersect(previousEvenPositions, oddPositions, 'stable');
            previousEvenMagnitudes(existPreviousEvenIndex) = oddMagnitudes(existOddIndex);
            % Validate even positions
            defectEvenIndex = (0.5 * evenMagnitudes) > previousEvenMagnitudes;
            % Validate all even positions
            positionsPattern = defectEvenIndex;
        else
            positionsPattern = false(length(positionValid), 1);
        end
    else
        positionsPattern = false(length(positionValid), 1);
    end
end