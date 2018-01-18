% HISTORY_ROLLINGBEARINGN_MISALIGNMENT_INNER_RING function returns status of rolling
% bearing defect "Misalignment of the inner ring with history" (defectID = 9)
% 
% Defect requirements:
%     main:
%         1) k * (shaftFreq - FTF);
% 
% Developer:              Kosmach N.
% Development date:       15.05.2017
% Modified by:            Kosmach N.
% Modification date:      13.09.2017

function [similarityHistory, historyDangerous] = ...
    history_rollingBearing_COCKED_INNER_RING(defectStruct, ~)

    difTag = 33; % shaftFTF tag

    % To evaluate acceleration spectrum
    [statusAcc, dangerAcc] = accSpectrumEvaluation(defectStruct.accelerationSpectrum, difTag);
    
    % To evaluate envelope acceleration spectrum
    [statusEnv, dangerEnv] = accEnvSpectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, difTag);

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
function [weightsStatus, statusHistory] = accSpectrumEvaluation(domain, difTag)

    % To evaluate with pattern
    [~, ~, ~, ~, positionsPattern] = getTagPositionsHistory(domain, difTag);
    
    % To get weights all peaks
    weight = str2num(domain.defectiveWeights{1, 1});
    
    if ~isempty(weight)
        % To get peaks evaluated of history 
        statusThresholdAndTrend = evaluatorThresholdTrend(domain.trendResult, domain.statusCurrentThreshold);
        
        % To calculateresult
        weight(~positionsPattern) = 0;
        weightsStatus = sum(weight .* statusThresholdAndTrend);
    else
        weightsStatus = 0;
    end
    
    statusHistory = weightsStatus;
end

% ACCENVSPECTRUMEVALUATION function calculate status to acceleration envelope domain
function [weightsStatus, dangerStatus] = accEnvSpectrumEvaluation(domain, difTag)

    % To evaluate with pattern
    positionsPattern = accEnvSpectrumEvaluationPattern(domain, difTag);
    
    % To get weights all peaks
    weight = str2num(domain.defectiveWeights{1, 1});
    
    if ~isempty(weight)
        % To get peaks evaluated of history 
        statusThresholdAndTrend = evaluatorThresholdTrend(domain.trendResult, domain.statusCurrentThreshold);

        % To get history danger
        [~, ~, ~, ~, positionsPatternHistory] = getTagPositionsHistory(domain, difTag);
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
function [positionsPattern] = accEnvSpectrumEvaluationPattern(domain, difTag)

    % Get data of frequency difference harmonics
    [positions, ~, magnitudes, ~, validPositions] = getTagPositionsHistory(domain, difTag);
    % Validation rule
    if ~isempty(positions)
        % Preallocate defect peaks index
        defectPeaksIndex = false(length(magnitudes), 1);
        % Evaluate the first harmonic
        firstHarmonicIndex = find(positions == 1);
        if ~isempty(firstHarmonicIndex)
            % Validate the first harmonic
            defectPeaksIndex(firstHarmonicIndex) = magnitudes(firstHarmonicIndex) == max(magnitudes(positions ~= 2));
        end
        % Evaluate the second harmonic
        secondHarmonicIndex = find(positions == 2);
        if ~isempty(secondHarmonicIndex)
            % Check that the second harmonic is the maximum
            isMaxSecondHarmonic = magnitudes(secondHarmonicIndex) == max(magnitudes(positions ~= 1));
            if ~isempty(firstHarmonicIndex)
                % Check that the second harmonic is greater than 120% of
                % the first harmonic
                isGreaterSecondHarmonic = magnitudes(secondHarmonicIndex) > (1.20 * magnitudes(firstHarmonicIndex));
                % Validate the second harmonic
                defectPeaksIndex(secondHarmonicIndex) = isMaxSecondHarmonic & isGreaterSecondHarmonic;
            else
                % Validate the second harmonic
                defectPeaksIndex(secondHarmonicIndex) = isMaxSecondHarmonic;
            end
        end
        % Find the first higher harmonic index
        if ~isempty(secondHarmonicIndex)
            firstHigherHarmonicIndex = secondHarmonicIndex + 1;
        else
            firstHigherHarmonicIndex = firstHarmonicIndex + 1;
        end
        if (firstHigherHarmonicIndex > 1)
            % Evaluate higher harmonics
            for peakNumber = firstHigherHarmonicIndex : 1 : length(magnitudes)
                % Check that current peak less than previous peaks
                isLessHigherHarmonic = all(magnitudes(peakNumber) < magnitudes(defectPeaksIndex));
                % Check that current peak greater than 25% of previous peaks
                isGreaterHigherHarmonic = any(magnitudes(peakNumber) > (0.25 * magnitudes(defectPeaksIndex)));
                % Validate current peak
                defectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
            end
        end
        % To get validated position
        positionsPattern = defectPeaksIndex;
    else
        positionsPattern = false(1, validPositions);
    end
end
