% ISO10816 function evaluates the rms vibration velocity according to
% ISO 10816-1-97 standard
% 
% INPUT:
% 
% rmsValue - rms value of vibration velocity, mm/s (double)
% 
% equipmentClass - class of equipment in accordance with standard (char)
% equipmentClass = '1' | '2' | '3' | '4'
% 
% OUTPUT:
% 
% status - status of vibration velocity
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
% boundaries - zone boundaries for the specified equipment class, mm/s
% (double array)
% 
% Developer:              P. Riabtsev
% Development date:       16-01-2017
% Modified by:            
% Modification date:      
function [status, boundaries] = iso10816(rmsValue, equipmentClass)
    
    if isempty(rmsValue)
        % Unknown
        status = [];
        boundaries = [];
        return;
    end
    
    % Determine the values of the zone boundaries in accordance with the
    % equipment class
    switch str2double(equipmentClass)
        case 1
            % Class 1
            ABBoundary = 0.71;
            BCBoundary = 1.8;
            CDBoundary = 4.5;
        case 2
            % Class 2
            ABBoundary = 1.12;
            BCBoundary = 2.8;
            CDBoundary = 7.1;
        case 3
            % Class 3
            ABBoundary = 1.8;
            BCBoundary = 4.5;
            CDBoundary = 11.2;
        case 4
            % Class 4
            ABBoundary = 2.8;
            BCBoundary = 7.1;
            CDBoundary = 18;
        otherwise
            % Unknown
            status = [];
            boundaries = [];
            return;
    end
    
    % Get boundaries
    boundaries = [ABBoundary, BCBoundary, CDBoundary];
    
    % Evaluate the rms vibration velocity
    if rmsValue < ABBoundary
        % Zone A
        status = 'A';
    elseif (rmsValue >= ABBoundary) && (rmsValue < BCBoundary)
        % Zone B
        status = 'B';
    elseif (rmsValue >= BCBoundary) && (rmsValue < CDBoundary)
        % Zone C
        status = 'C';
    elseif rmsValue >= CDBoundary
        % Zone D
        status = 'D';
    else
        % Unknown
        status = [];
    end
    
end

