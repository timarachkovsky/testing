classdef fan < shaft
    % FAN class is designed to store data about the fan element
    
    properties (Access = protected)
        % The blades/vanes number of the fan
        bladesNumber
    end
    
    properties
        % The model of the fan
        model
    end
    
    methods
        % Constructor function
        function myFan = fan(myElementType, myModel, myName, myShaftFreq, myBladesNumber)
            myId = '8';
            myFan = myFan@shaft(myElementType, myName, myShaftFreq,myId);
            myFan.bladesNumber = myBladesNumber;
            myFan.model = myModel;
            myFan.basicFreqList = getBasicFreqList(myFan);
        end
        
        % Setters/Getters ...
        function myFan = setBladesNumber(myFan, myBladesNumber)
            myFan.bladesNumber = myBladesNumber;
        end
        function myBladesNumber = getBladesNumber(myFan)
            myBladesNumber = myFan.bladesNumber;
        end
        
        function myFan = setModel(myFan, myModel)
            myFan.model= myModel;
        end
        function myModel = getModel(myFan)
            myModel = myFan.model;
        end
        % ... Setters/Getters
        
        function basicFreqList = getBasicFreqList(myFan)
            % Blade/vane pass frequency
            bladePass = myFan.shaftFreq * myFan.bladesNumber;
            
            basicFreqList = [ ...
                1, myFan.shaftFreq, {'shaftFreq'}; ...
                32, bladePass, {'bladePass'} ...
                ];
        end
    end 
end

