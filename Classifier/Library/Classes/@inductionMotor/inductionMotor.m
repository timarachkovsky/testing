classdef inductionMotor < motor
    % INDUCTIONMOTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        % The number of rotor bars
        barsNumber
        % The number of pole pairs
        polePairsNumber
    end
    
    methods
        function myInductionMotor = inductionMotor(myElementType, myClassType, myModel, myName, myShaftFreq, myLineFreq, myBarsNumber, myPolePairsNumber)
            myId = '6';
            myInductionMotor = myInductionMotor@motor(myElementType, myClassType, myModel, myName, myShaftFreq, myLineFreq, myId);
            myInductionMotor.barsNumber = myBarsNumber;
            myInductionMotor.polePairsNumber = myPolePairsNumber;
            myInductionMotor.basicFreqList = getBasicFreqList(myInductionMotor);
        end
        
        % Setters/Getters ...
        function myInductionMotor = setBarsNumber(myInductionMotor, myBarsNumber)
            myInductionMotor.barsNumber = myBarsNumber;
        end
        function myBarsNumber = getBarsNumber(myInductionMotor)
            myBarsNumber = myInductionMotor.barsNumber;
        end
        
        function myInductionMotor = setPolePairsNumber(myInductionMotor, myPolePairsNumber)
            myInductionMotor.polePairsNumber = myPolePairsNumber;
        end
        function myPolePairsNumber = getPolePairsNumber(myInductionMotor)
            myPolePairsNumber = myInductionMotor.polePairsNumber;
        end
        % ... Setters/Getters
        
        function basicFreqList = getBasicFreqList(myInductionMotor)
            % Twice line frequency
            twiceLineFreq = 2 * myInductionMotor.lineFreq;
            % Rotor bar passing frequency
            barFreq = myInductionMotor.shaftFreq * myInductionMotor.barsNumber;
            % Pole pass frequency
            synchronousFreq = myInductionMotor.lineFreq / myInductionMotor.polePairsNumber;  
            slipFreq = synchronousFreq - myInductionMotor.shaftFreq;
            polePassFreq = slipFreq * myInductionMotor.polePairsNumber;
            
            basicFreqList = [ ...
                1, myInductionMotor.shaftFreq, {'shaftFreq'}; ...
                3, twiceLineFreq, {'twiceLineFreq'}; ...
                4, barFreq, {'barFreq'}; ...
                5, polePassFreq, {'polePassFreq'}; ...
                ];
        end
    end
    
end

