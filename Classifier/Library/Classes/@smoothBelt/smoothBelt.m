classdef smoothBelt < connectionElement
    % SMOOTHBELT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        % Diameter of the first sheave
        sheaveDiameter1
        % Diameter of the second sheave
        sheaveDiameter2
        % Belt length
        beltLength
    end
    
    methods
        function mySmoothBelt = smoothBelt(myElementType, myClassType, myName, myShaftFreq1, mySheaveDiameter1, mySheaveDiameter2, myBeltLength, myId)
            if nargin < 8
                myId = '5';
            end
            mySmoothBelt = mySmoothBelt@connectionElement(myElementType, myClassType, myName, myShaftFreq1, myId);
            mySmoothBelt.sheaveDiameter1 = mySheaveDiameter1;
            mySmoothBelt.sheaveDiameter2 = mySheaveDiameter2;
            mySmoothBelt.beltLength = myBeltLength;
            mySmoothBelt = calculateBasicFreqList(mySmoothBelt);
        end
        
        % Setters/Getters ...
        function mySmoothBelt = setSheaveDiametr1(mySmoothBelt, mySheaveDiametr1)
            mySmoothBelt.sheaveDiametr1 = mySheaveDiametr1;
        end
        function mySheaveDiametr1 = getSheaveDiametr1(mySmoothBelt)
            mySheaveDiametr1 = mySmoothBelt.sheaveDiametr1;
        end
        
        function mySmoothBelt = setSheaveDiametr2(mySmoothBelt, mySheaveDiametr2)
            mySmoothBelt.sheaveDiametr2 = mySheaveDiametr2;
        end
        function mySheaveDiametr2 = getSheaveDiametr2(mySmoothBelt)
            mySheaveDiametr2 = mySmoothBelt.sheaveDiametr2;
        end
        
        function mySmoothBelt = setBeltLength(mySmoothBelt, myBeltLength)
            mySmoothBelt.beltLength = myBeltLength;
        end
        function myBeltLength = getBeltLength(mySmoothBelt)
            myBeltLength = mySmoothBelt.beltLength;
        end
        % ... Setters/Getters
    end
    
    methods (Access = protected)
        function mySmoothBelt = calculateBasicFreqList(mySmoothBelt)
            % Sheaves frequencies
            sheaveFreq1 = mySmoothBelt.shaftFreq;
            sheaveFreq2 = mySmoothBelt.shaftFreq * mySmoothBelt.sheaveDiameter1 / mySmoothBelt.sheaveDiameter2;
            % The frequency of oscillation of the belt
            beltFreq = sheaveFreq1 * pi * mySmoothBelt.sheaveDiameter1 / mySmoothBelt.beltLength;
            
            mySmoothBelt.basicFreqList = [ ...
                28, beltFreq, {'beltFreq'}; ...
                29, sheaveFreq1, {'sheaveFreq1'}; ...
                30, sheaveFreq2, {'sheaveFreq2'}; ...
                ];
        end
    end
    
end

