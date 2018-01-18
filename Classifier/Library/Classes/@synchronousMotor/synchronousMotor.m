classdef synchronousMotor < motor
    % SYNCHRONOUSMOTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        % The number of stator coils
        coilsNumber
    end
    
    methods
        function mySynchronousMotor = synchronousMotor(myElementType, myClassType, myModel, myName, myShaftFreq, myLineFreq, myCoilsNumber)
            myId = '8';
            mySynchronousMotor = mySynchronousMotor@motor(myElementType, myClassType, myModel, myName, myShaftFreq, myLineFreq, myId);
            mySynchronousMotor.coilsNumber = myCoilsNumber;
            mySynchronousMotor.basicFreqList = getBasicFreqList(mySynchronousMotor);
        end
        
        % Setters/Getters ...
        function myInductionMotor = setCoilsNumber(myInductionMotor, myCoilsNumber)
            myInductionMotor.coilsNumber = myCoilsNumber;
        end
        function myCoilsNumber = getCoilsNumber(myInductionMotor)
            myCoilsNumber = myInductionMotor.coilsNumber;
        end
        % ... Setters/Getters
        
        function basicFreqList = getBasicFreqList(myInductionMotor)
            % Twice line frequency
            twiceLineFreq = 2 * myInductionMotor.lineFreq;
            % Stator coil passing frequency
            coilFreq = myInductionMotor.shaftFreq * myInductionMotor.coilsNumber;
            
            basicFreqList = [ ...
                1, myInductionMotor.shaftFreq, {'shaftFreq'}; ...
                3, twiceLineFreq, {'twiceLineFreq'}; ...
                10, coilFreq, {'coilFreq'}; ...
                ];
        end
    end
    
end

