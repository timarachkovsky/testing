classdef element
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
       id 
       elementType
       name
    end
    
    methods
        function myElement = element(myId,myElementType,myName)
            myElement.id = myId;
            myElement.elementType = myElementType;
            myElement.name = myName;
        end
        
        function  setId(myElement,myId)
            myElement.id = myId;
        end
        
        function  setElementType(myElement,myElementType)
            myElement.elementType = myElementType;
        end
        
        function setName(myElement,myName)
            myElement.name = myName;
        end
        
        function myId = getId(myElement)
           myId =  myElement.id;
        end
        
        function myElementType = getElementType(myElement)
           myElementType =  myElement.elementType;
        end
        
        function myName = getName(myElement)
           myName =  myElement.name;
        end
        
    end
end

