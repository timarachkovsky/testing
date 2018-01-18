% Creator   Kosmach N.
% Date       26.01.2017       
classdef str2numStatus < double
    % Return status in numeric  
    % Example:
    % s = double(str2numStatus.green),
    % whos
    % s = 0.25
    enumeration
        GREEN (0.25)
        YELLOW (0.5)
        ORANGE (0.75)
        RED (1)
        empt (0)
        NaN(0)
        
        % Only for spmLRHR method
        YELLOWDecrease (-0.5)
        ORANGEDecrease (-0.75)
        REDDecrease (-1)
        
        A (0.25)
        B (0.5)
        C (0.75)
        D (1)
    end
    
    methods(Static) 
        
        % CONVERTNUMTOSTR function convert numeric status to sting status
        % with methods
        function statusStr = convertNumToStr(statusNum, mode)
            
            % If mode == 1 it is iso10816 methods
            if nargin == 1
                mode = 0;
            end
            
            if mode == 1
                switch(statusNum)
                    case 0.25
                        statusStr = 'A';
                    case 0.5
                        statusStr = 'B';
                    case 0.75
                        statusStr = 'C';
                    case 1
                        statusStr = 'D';
                    otherwise
                        statusStr = 'unknow';
                end
            else
                switch(statusNum)
                    case 0
                        statusStr = 'empt';
                    case 0.25
                        statusStr = 'GREEN';
                    case 0.5
                        statusStr = 'YELLOW';
                    case 0.75
                        statusStr = 'ORANGE';
                    case 1
                        statusStr = 'RED';
                    otherwise
                        statusStr = 'unknow';
                end
            end
        end
    end
end

