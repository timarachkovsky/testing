classdef bearingElement < shaft
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        type
        model
    end
    
    methods
        function myBearing = bearingElement(myElementType,myClassType,myModel,myName, myShaftFreq, myId)
            myBearing = myBearing@shaft(myElementType, myName, myShaftFreq,myId);
%             myBearing = myBearing@element(myElementType, myName);
            myBearing.type = myClassType;
            myBearing.model = myModel;
        end
        
        function  setType(myBearing,myType)
            myBearing.type = myType;
        end
        
        function  setModel(myBearing,myModel)
            myBearing.model = myModel;
        end
        
        function myType = getType(myBearing)
           myType =  myBearing.type;
        end
        
        function myModel = getModel(myBearing)
           myModel =  myBearing.model;
        end
    end
    
end

