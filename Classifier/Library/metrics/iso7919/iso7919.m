% ISO7919 function evaluates the peak-to-peak vibration displacement
% according to ISO 7919 standards
% 
% INPUT:
% 
% peak2peakValue - peak-to-peak vibration displacement, mkm (double)
% 
% shaftSpeedVector - shaft rotational speed, r/min (double vector)
% 
% standardPart - the part of ISO 7919 standards (char)
% standardPart = '2' | '3' | '4' | '5'
% 
% OUTPUT:
% 
% status - status of vibration displacement (cell array)
% status = 'A' | 'B' | 'C' | 'D' | empty
%    A - The vibration of newly commissioned machines would normally fall
%    within this zone.
%    B - Machines with vibration within this zone are normally considered
%    acceptable for unrestricted long-term operation.
%    C - Machines with vibration within this zone are normally considered
%    unsatisfactory for long-term continuous operation. Generally, the
%    machine may be operated for a limited period in this condition until
%    a suitable opportunity arises for remedial action.
%    D - Vibration values within this zone are normally considered to be
%    of sufficient severity to cause damage to the machine
% 
%     A
%    ---
%     B    |
%    ---   | ALARM
%     C    |    |
%    ---        | TRIPS
%     D         |
% 
% thresholds - zone thresholds for the specified shaft rotational speed,
% mkm (cell array)
% 
% Developer:              P. Riabtsev
% Development date:       15-08-2017
% Modified by:            
% Modification date:      
function [status, thresholds] = iso7919(shaftSpeedVector, peak2peakValue, standardPart)
    
    if isempty(shaftSpeedVector)
        % Unknown
        status = cell(1);
        thresholds = cell(1);
        return;
    end
    
    if isempty(peak2peakValue)
        % Unknown
        status = cell(length(shaftSpeedVector), 1);
        thresholds = cell(length(shaftSpeedVector), 1);
        return;
    end
    
    % Determine the values of the zone boundaries in accordance with the
    % shaft rotational speed
    switch standardPart
        case '2'
            % ISO 7919-2
            % Boundary samples
            xSamples = [1500, 1800, 3000, 3600];
            yABSamples = [100, 95, 90, 80];
            yBCSamples = [200, 185, 165, 150];
            yCDSamples = [320, 290, 240, 220];
            
            rangeIndex{1} = shaftSpeedVector < 1800;
            rangeIndex{2} = shaftSpeedVector >= 1800 & shaftSpeedVector < 3000;
            rangeIndex{3} = shaftSpeedVector >= 3000;
            thresholds = cell(length(shaftSpeedVector), 1);
            for rangeNumber = 1 : 1 : length(rangeIndex)
                samples(1, : ) = {xSamples(rangeNumber : rangeNumber + 1), yABSamples(rangeNumber : rangeNumber + 1)};
                samples(2, : ) = {xSamples(rangeNumber : rangeNumber + 1), yBCSamples(rangeNumber : rangeNumber + 1)};
                samples(3, : ) = {xSamples(rangeNumber : rangeNumber + 1), yCDSamples(rangeNumber : rangeNumber + 1)};
                % Calculate boundaries
                thresholds(rangeIndex{rangeNumber}, 1) = restoreBoundaries(samples, shaftSpeedVector(rangeIndex{rangeNumber}));
            end
        case {'3', '4'}
            % ISO 7919-3, ISO 7919-4
            xSamples = [3000 3600];
            yABSamples = [90 80];
            yBCSamples = [165 150];
            yCDSamples = [240 220];
            
            samples(1, : ) = {xSamples, yABSamples};
            samples(2, : ) = {xSamples, yBCSamples};
            samples(3, : ) = {xSamples, yCDSamples};
            % Calculate boundaries
            thresholds = restoreBoundaries(samples, shaftSpeedVector);
        case '5'
            % ISO 7919-5
            % Boundary samples
            xSamples = [200 900];
            yABSamples = [150 135];
            yBCSamples = [250 225];
            yCDSamples = [500 450];
            
            samples(1, : ) = {xSamples, yABSamples};
            samples(2, : ) = {xSamples, yBCSamples};
            samples(3, : ) = {xSamples, yCDSamples};
            % Calculate boundaries
            thresholds = restoreBoundaries(samples, shaftSpeedVector);
        otherwise
            % Unknown
            status = cell(length(shaftSpeedVector), 1);
            thresholds = cell(length(shaftSpeedVector), 1);
            return;
    end
    
    % Evaluate the peak-to-peak vibration displacement
    status = cellfun(@(shaftSpeedThresholds) getStatus(peak2peakValue, shaftSpeedThresholds), ...
        thresholds, 'UniformOutput', false);
    
end

% RESTOREBOUNDARIES function restores the boundary curves from the curve
% samples and calculates the thresholds for the each shaft speed value
% 
% samples - n-by-2 cell array, the first column contains a double vector
%     with x-coordiantes of two curve points, the second column - a double
%     vector with y-coordinates of two curve points, n - the curve number
function [thresholds] = restoreBoundaries(samples, shaftSpeedVector)
    
    boundaries = zeros(length(shaftSpeedVector), size(samples, 1));
    for boundaryNumber = 1 : 1 : size(samples, 1)
        % Get the points of the boundary curve
        xSamples = samples{boundaryNumber, 1};
        ySamples = samples{boundaryNumber, 2};
        % Calculate the coefficients of the boundary curve
        a = (log2(ySamples(2)) - log2(ySamples(1))) / (log2(xSamples(2)) - log2(xSamples(1)));
        b = log2(ySamples(1)) - a * log2(xSamples(1));
        % Calculate boundaries
        boundaries( : , boundaryNumber) = power(shaftSpeedVector, a) * power(2, b);
    end
    thresholds = num2cell(boundaries, 2);
    
end

% GETSTATUS function evaluates the peak-to-peak vibration displacement by
% the thresholds
function [status] = getStatus(peak2peakValue, thresholds)
    
    if peak2peakValue < thresholds(1)
        % Zone A
        status = 'A';
    elseif (peak2peakValue >= thresholds(1)) && (peak2peakValue < thresholds(2))
        % Zone B
        status = 'B';
    elseif (peak2peakValue >= thresholds(2)) && (peak2peakValue < thresholds(3))
        % Zone C
        status = 'C';
    elseif peak2peakValue >= thresholds(3)
        % Zone D
        status = 'D';
    else
        % Unknown
        status = [];
    end
    
end

