classdef coupling < shaft
    %COUPLING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = protected)
    end
    
    methods
        function myCoupling = coupling(myElementType, myName, myShaftFreq, myId)
            if nargin < 4
                myId = '7';     % coupling element ID
            end
            myCoupling = myCoupling@shaft(myElementType, myName, myShaftFreq, myId);
        end
    end
    
end