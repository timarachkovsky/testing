classdef shaft < element
    % SHAFT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        shaftFreq
        basicFreqList
    end
    
    methods
        function myShaft = shaft(myElementType, myShaftName, myShaftFreq, myId)
            if nargin == 3
                myId = '1';
            end
            myShaft = myShaft@element(myId, myElementType, myShaftName);
            myShaft.shaftFreq = myShaftFreq;
            myShaft.basicFreqList = [1 myShaft.shaftFreq {'shaftFreq'}];
        end
        
        % Setters/Getters ...
        function myShaft = setShaftFreq(myShaft, myShaftFreq)
            myShaft.shaftFreq = myShaftFreq;
        end
        function myShaftFreq = getShaftFreq(myShaft)
            myShaftFreq = myShaft.shaftFreq;
        end
        
        function myShaft = setBasicFreqList(myShaft, myBasicFreqList)
            myShaft.basicFreqList = myBasicFreqList;
        end
        function myBasicFreqList = getBasicFreqList(myShaft)
            myBasicFreqList = myShaft.basicFreqList;
        end
        % ... Setters/Getters
    end
    
end

