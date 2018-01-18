% PEAKCOMPARISON function compares the defect frequencies and the 
% frequencies which are found
%
% Developer:              N. Kosmach
% Development date:       04-08-2016
% Modified by:            N. Kosmach
% Modification date:      01-11-2016

% Modified by:            N. Kosmach
% Modification date:      20-20-2017 (function "findWithDecreasingRange" is added instead "max", 
% when "peakComparison" find more one frequency for one reqiered frequency")

function [validMag, validFreq, validProm, validLogProm] = peakComparison(file, config)

%% _____________________ Default Parameters ___________________________ %%
    
    % If the input parameters are not empty
    if nargin < 2
        config = []; 
    end
    
%% _______________________ Default Parameters _________________________ %%
    
    config = fill_struct(config,'percentRange', '1'); % in [%]
    config = fill_struct(config,'freqRange', '0'); % in [Hz]
    
%% _____________________ Calculations _________________________________ %%
    
    if ~isempty(file.frequency)
        [m, n] = size(file.frequency);
        validFreq = zeros(size(file.frequency));
        validMag = zeros(size(file.frequency));
        % Peaks prominence vector
        validProm = zeros(size(file.frequency));
        validLogProm = zeros(size(file.frequency));
    %     [~,column] = size(file.frequency);
        [~,column] = size(file.peakTable);
        % Peak search the required peaks in table
        if ~isempty(file.peakTable)
            for i = 1:1:m
                for j = 1:1:n
                    validFreqVector = getSimilarElements(file.frequency(i, j), file.peakTable(:,1), config);
                    if validFreqVector ~= -1
                        if column > 1 && nnz(validFreqVector)
                            
                            positionNumber = find(ismember(file.peakTable(:,1), validFreqVector));
                            if nnz(positionNumber) == 1

                                validFreq(i, j) = validFreqVector;
                                validMag(i, j) = file.peakTable(positionNumber, 2);
                                validProm(i, j) = file.peakTable(positionNumber, 3);
                                validLogProm(i, j) = file.peakTable(positionNumber, 4);
                            else
                                numberTruePos = findWithDecreasingRange(file.frequency(i, j), ...
                                                                        file.peakTable(positionNumber, 1), ...
                                                                        file.peakTable(positionNumber, 2));

                                validFreq(i, j) = file.peakTable(positionNumber(numberTruePos), 1);
                                validMag(i, j) = file.peakTable(positionNumber(numberTruePos), 2);
                                validProm(i, j) = file.peakTable(positionNumber(numberTruePos), 3);
                                validLogProm(i, j) = file.peakTable(positionNumber(numberTruePos), 4);
                            end
                        else 
                            validFreq(i, j) = validFreqVector(1,1);
                            validMag(i, j) = 0;
                            validProm(i, j) = 0;
                            validLogProm(i, j) = 0;
                        end
                    end
                end
            end
        end
    else
      validMag = 0;    
      validFreq = 0;
      validProm = 0;
      validLogProm = 0;
    end 
end
