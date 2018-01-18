function [validM, validP] = getPeaksMerge(file, shaftFreq, defectFreq, modulation, parameters)
% GETPEAKSMERGE The function calculates the magnitude peaks with different
% accuracy and merges them
%   Developer:              N. Kosmach
%   Development date:
%   Modified by:            P. Riabtsev
%   Modification date:      08-07-2016

if nargin<5
    parameters = [];
end

%% ---------- Default parameters ---------------------------------------

parameters = fill_struct(parameters, 'accuracy', '2; 10; 20');
parameters = fill_struct(parameters, 'peakThreshold', '1.3');

accuracy = str2num(parameters.accuracy);
peakThreshold = str2num(parameters.peakThreshold);

if ~isempty(defectFreq)

% Get the values with different accuracy
for i = 1 : 1 : length(accuracy)
    [validMagi{1, i}, validPeaksi{1, i}] = getPeaks(file, shaftFreq, defectFreq, accuracy(i), peakThreshold);
end

% Create new matrix
[m, n] = size(validMagi{1, 1});
validM = zeros(m, n);
validP = zeros(m, n);

if (modulation == 0)     % ===== No modulation ========================
    for j = 1 : 1 : length(accuracy)

        switch j

            % Record the values with the first accuracy
            case 1
                validM = validMagi{1, j};
                validP = validPeaksi{1, j};

            % Compare the values with different accuracy
            otherwise
                % These frequencies will remain the same
                willRemain = validM > validMagi{1, j};
                % These frequencies will be replaced
                willReplaced = ~willRemain;

                % Record the maximum magnitude of the two matrices
                validM =(validM .* willRemain) + (validMagi{1, j} .* willReplaced);
                % Record peaks with maximum values of the two matrices
                validP = (validP .* willRemain) + (validPeaksi{1, j} .* willReplaced);

        end

    end
else        % ===== Modulation is present =============================

    % Find vectors with modulation
    [modVect, ~] = find(modulation > 0);

    % Create matrix with modulation position
    modPosition = zeros(m, n);

    for numRow = 1 : 1 : length(modVect)
        row = modVect(numRow);
        for position = 2 : 3 : n
            modPosition(row, position) = 1;
        end
        % Set modulation position
        modPosition(row, : ) = ~modPosition(row, : );
    end

    % Merge
    for j = 1 : 1 : length(accuracy)

        switch j

            % ===== Record the values with the first accuracy =========
            case 1
                validM = validMagi{1, j};
                validP = validPeaksi{1, j};

            % ===== Compare the values with different accuracy ========
            otherwise
                % Position exceeds the value with less accuracy
                excValues = validM > validMagi{1, j};

                willRemain = excValues + modPosition;
                % These frequencies will remain the same
                willRemain(willRemain > 0) = 1;
                % These frequencies will be replaced
                willReplaced = ~willRemain;                 

                % Record the maximum magnitude of the two matrices
                validM =(validM .* willRemain) + (validMagi{1, j} .* willReplaced);
                % Record peaks with maximum values of the two matrices
                validP = (validP .* willRemain) + (validPeaksi{1, j} .* willReplaced);

        end

    end

end
else
  validM = defectFreq;    
  validP = defectFreq;
end
end