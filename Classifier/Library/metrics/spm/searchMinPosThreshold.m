function [ threshMinPos, peakCntCurrent,  numberPeaksMax] = searchMinPosThreshold( File, config )

% Function version : v1.1

% Developer:            Kosmach N.
% Data:                 21.07.2016
% Modified by:          Kosmach N.
% Modification date:    29.09.2017
%% --------------------- Description --------------------
% search threshold for a predetermined number of peaks in a certain grid distance
%% Parametrs
    if nargin < 2
        config = [];
    end
    config = fill_struct(config, 'peakCntRequired', '200'); % it should be 200 
    % peaks per one-second-frame (or 6000 per 30-second)
    config = fill_struct(config, 'distance', '20'); % this parameter may be
    % specified to ignore smaller peaks that may occur in close proximity to
    % a large local peak
    config = fill_struct(config, 'numberThresh', '10'); % number of samples in a
    % grid search threshold
    peakCntRequired = str2double(config.peakCntRequired);
    numberThresh = str2double(config.numberThresh);
    distance = str2double(config.distance);

%% Calculation
  
    numberPeaksVectors = zeros(numberThresh,1);
    signal = File.acceleration.signal;
    vectorThreshold = File.thresh;
    
    % Determining the number of peaks in each grid spacing
    if str2double(config.parpoolEnable)
        
        parfor i = 1:1:numberThresh    
            numberPeaksVectors(i,1) = findNumberPeaksWithTreshold(signal, vectorThreshold(i), distance);
        end
    else
        for i = 1:1:numberThresh 
            numberPeaksVectors(i,1) = findNumberPeaksWithTreshold(signal, vectorThreshold(i), distance);
        end
    end
    
    % Determining the required number of peaks
    vectorDistance = numberPeaksVectors - peakCntRequired;
    [minDistance, positionMin] = min(abs(vectorDistance)); 
    
    position = find(minDistance == abs(vectorDistance));
    
    if nnz(numberPeaksVectors == peakCntRequired)
        threshMinPos = find(numberPeaksVectors == peakCntRequired, 1);
    else
        if nnz(position) == 1
            threshMinPos = positionMin;
        else

            statusUniq = unique(vectorDistance(position));
            if all(statusUniq > 0)
                
                threshMinPos = find(vectorDistance == statusUniq, 1, 'last');
            elseif all(statusUniq < 0)
                
                threshMinPos = find(vectorDistance == statusUniq, 1, 'first');
            else
                posVectorMoreZeros = statusUniq > 0;
                threshMinPos = find(vectorDistance == statusUniq(posVectorMoreZeros), 1, 'last');
            end
        end
    end
    peakCntCurrent = numberPeaksVectors(threshMinPos); % number of found thresholds
    numberPeaksMax = numberPeaksVectors(1,1); % maximum number of peaks in the signal
end

function numberPeaks = findNumberPeaksWithTreshold(signal, threshold, distance)
    numberPeaks = length(findpeaks(signal,'MinPeakHeight',threshold,'MinPeakDistance', distance));
end