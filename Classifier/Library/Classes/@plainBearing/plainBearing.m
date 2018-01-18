classdef plainBearing < bearingElement
    % PLAINBEARING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        
    end
    
    methods
        
        function myPlainBearing = plainBearing(myElementType, myClassType, myModel, myName, myShaftFreq)
            myId = '4';
            myPlainBearing = myPlainBearing@bearingElement(myElementType, myClassType, myModel, myName, myShaftFreq, myId);
            myPlainBearing.basicFreqList = getBasicFreqList(myPlainBearing);
        end
        
        function basicFreqList = getBasicFreqList(myPlainBearing)
            shaftFreq046 = 0.46 * myPlainBearing.shaftFreq;
            shaftFreq = myPlainBearing.shaftFreq;
            basicFreqList = [1, shaftFreq, {'shaftFreq'}; ...
							 16, shaftFreq046, {'0.46*shaftFreq'}; ...
							];
        end
        
    end
    
end