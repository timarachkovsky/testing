classdef motor < shaft
    % MOTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        % The class(type) of the motor
        type
        % The model of the motor
        model
        % The motor input frequency
        lineFreq
    end
    
    methods
        function myMotor = motor(myElementType, myClassType, myModel, myName, myShaftFreq, myLineFreq, myId)
            myMotor = myMotor@shaft(myElementType, myName, myShaftFreq, myId);
            myMotor.type = myClassType;
            myMotor.model = myModel;
            myMotor.lineFreq = myLineFreq;
        end
        
        % Setters/Getters ...
        function myMotor = setType(myMotor, myType)
            myMotor.type = myType;
        end
        function myType = getType(myMotor)
            myType = myMotor.type;
        end
        
        function myMotor = setModel(myMotor, myModel)
            myMotor.model = myModel;
        end
        function myModel = getModel(myMotor)
            myModel = myMotor.model;
        end
        
        function myMotor = setLineFreq(myMotor, myLineFreq)
            myMotor.lineFreq = myLineFreq;
        end
        function myLineFreq = getLineFreq(myMotor)
            myLineFreq = myMotor.lineFreq;
        end
        % ... Setters/Getters
    end
    
end

