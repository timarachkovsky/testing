classdef directCurrentMotor < motor
    
    properties (Access = protected)
        % The number of collector plates
        collectorPlatesNumber
        % The number of pole pairs
        polePairsNumber
        % The number of armature teeth
        armatureTeethNumber
        % The type of rectifier
        rectifierType
    end
    
    methods
        function myDCMotor = directCurrentMotor(myElementType, myClassType, myModel, myName, myShaftFreq, myLineFreq, ...
                myCollectorPlatesNumber, myPolePairsNumber, myArmatureTeethNumber, myRectifierType)
            
            myId = '12';
            myDCMotor = myDCMotor@motor(myElementType, myClassType, myModel, myName, myShaftFreq, myLineFreq, myId);
            myDCMotor.collectorPlatesNumber = myCollectorPlatesNumber;
            myDCMotor.polePairsNumber = myPolePairsNumber;
            myDCMotor.armatureTeethNumber = myArmatureTeethNumber;
            myDCMotor.rectifierType = myRectifierType;
        end
        
        function basicFreqList = getBasicFreqList(myDCMotor)
            
            collectorFrequency = myDCMotor.shaftFreq * myDCMotor.collectorPlatesNumber;
            teethFrequencyArmature = myDCMotor.shaftFreq * myDCMotor.armatureTeethNumber;
            brushFrequency = 2 * myDCMotor.shaftFreq * myDCMotor.polePairsNumber;
            
            if strcmpi(myDCMotor.rectifierType, 'full-wave')
                SCR = 6 * myDCMotor.lineFreq;
            else
                SCR = 3 * myDCMotor.lineFreq;
            end
            
            twiceLineFreq = 2 * myDCMotor.lineFreq;
            
            basicFreqList = [ ...
                1, myDCMotor.shaftFreq, {'shaftFreq'}; ...
                3, twiceLineFreq, {'twiceLineFreq'}; ...
                6, collectorFrequency, {'collectorFrequency'}; ...
                7, teethFrequencyArmature, {'teethFrequencyArmature'}; ...
                8, brushFrequency, {'brushFrequency'}; ...
                9, SCR, {'SCR'}; ...
                ];
        end
    end
    
end

