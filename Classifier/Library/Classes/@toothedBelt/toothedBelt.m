classdef toothedBelt < smoothBelt
    % TOOTHEDBELT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        % Number of teeth
        teethNumber
    end
    
    methods
        function myToothedBelt = toothedBelt(myElementType, myClassType, myName, myShaftFreq1, mySheaveDiameter1, mySheaveDiameter2, myBeltLength, myTeethNumber)
            myId = '10';
            myToothedBelt = myToothedBelt@smoothBelt(myElementType, myClassType, myName, myShaftFreq1, mySheaveDiameter1, mySheaveDiameter2, myBeltLength, myId);
            myToothedBelt.teethNumber = myTeethNumber;
            myToothedBelt = addMeshingFreq(myToothedBelt);
        end
        
        % Setters/Getters ...
        function myToothedBelt = setTeethNumber(myToothedBelt, myTeethNumber)
            myToothedBelt.teethNumber = myTeethNumber;
        end
        function myTeethNumber = getTeethNumber(myToothedBelt)
            myTeethNumber = myToothedBelt.teethNumber;
        end
        % ... Setters/Getters
    end
    
    methods (Access = protected)
        function myToothedBelt = addMeshingFreq(myToothedBelt)
            % Get the frequency of the first sheave
            sheaveFreq1 = myToothedBelt.basicFreqList{2, 2};
            % Tooth meshing frequency
            meshingFreq = sheaveFreq1 * pi * myToothedBelt.sheaveDiameter1 / myToothedBelt.beltLength * myToothedBelt.teethNumber;
            
            myToothedBelt.basicFreqList = [ ...
                myToothedBelt.basicFreqList;
                31, meshingFreq, {'meshingFreq'} ...
                ];
        end
    end
    
end

