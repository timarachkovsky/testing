classdef connectionElement < shaft
    % CONNECTIONELEMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        % The class(type) of the connection element
        type
    end
    
    methods
        function myConnectionElement = connectionElement(myElementType, myClassType, myName, myShaftFreq, myId)
            myConnectionElement = myConnectionElement@shaft(myElementType, myName, myShaftFreq, myId);
            myConnectionElement.type = myClassType;
        end
        
        % Setters/Getters ...
        function myConnectionElement = setType(myConnectionElement, myType)
            myConnectionElement.type = myType;
        end
        function myType = getType(myConnectionElement)
           myType = myConnectionElement.type;
        end
        % ... Setters/Getters
    end
    
end

