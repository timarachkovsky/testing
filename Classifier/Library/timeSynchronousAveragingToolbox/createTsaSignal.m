% CREATETSASIGNAL function calculates signal of TSA method and metrics of 
% TSA signal

% ********************************************************************** %
% Developer     : Kosmach N.
% Date          : 01.12.2017
% Version       : v1.0
% ********************************************************************** %

function [tsaSignal, deltaLastAndFirstSamlpes, coefModulation, tsaMean] = createTsaSignal(signal, step)

    numberFrame = floor(length(signal)/step);

    numberFreq = ceil(length(signal)/numberFrame);
    matrixForAverage = single(zeros(numberFreq, numberFrame));
    bufferStepTrue = step;
    roundingStep = floor(step);
    stepIter = 1;

    matrixForAverage(1:1:roundingStep,1) = signal(1:1:roundingStep);
    stepIter = stepIter + roundingStep;
    bufferStepTrue = bufferStepTrue + step;
    
    % Create table for tsa
    for i = 2:1:numberFrame

        if (round(bufferStepTrue)/bufferStepTrue) == 1
            roundingStep = ceil(step)-1;
        else
            roundingStep = floor(step)-1;
        end
        
        matrixForAverage(1:1:roundingStep+1,i) = signal(stepIter:1:stepIter+roundingStep);

        stepIter = stepIter + roundingStep + 1;
        bufferStepTrue = bufferStepTrue + step;
    end

    % Delete lasts row with empty samples
    matrixForAverage = matrixForAverage(1:1:end-1, :);
    numberFreq = numberFreq - 1;

    if nnz(matrixForAverage(end,:) == 0) == numberFrame
        posAllZeros = arrayfun(@(x) (nnz(matrixForAverage(x, :) == 0)) == numberFrame, 1:1:numberFreq);

        posZerosNumeric = find(posAllZeros);
        posTruePosition = posZerosNumeric(1):1:posZerosNumeric(end);
        if nnz(posZerosNumeric == posTruePosition) ~= length(posZerosNumeric)
            posNeedLeave = find(diff(posZerosNumeric) ~= 1, 1, 'last');
            notDelete = posZerosNumeric(posNeedLeave + 1) - 1;
        else
            notDelete = posZerosNumeric(1) - 1;
        end

        matrixForAverage = matrixForAverage(1:1:notDelete, :);
    end

    matrixForAverage(matrixForAverage == 0) = nan(1); 
    matrixForAverage = single(matrixForAverage);

    % Create average signal
    tsaSignal = mean(matrixForAverage, 2, 'omitnan');
    % Avoid pulse in the last sample
    tsaSignal = tsaSignal(1:1:end-1);
    
    % Calculate metrics of TSA signal
    deltaLastAndFirstSamlpes = abs(tsaSignal(1) - tsaSignal(end));

    maxTSA = max(tsaSignal);
    minTSA = min(tsaSignal);

    coefModulation = (maxTSA - minTSA)/(maxTSA + minTSA);

    tsaMean = mean(tsaSignal);
end