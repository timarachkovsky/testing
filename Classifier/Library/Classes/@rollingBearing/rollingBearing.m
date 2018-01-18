classdef rollingBearing < bearingElement
    %BEARING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        Bd          % Ball or roller diameter
        Pd          % Pitch diameter
        Nb          % Number of balls or rollers
        angle       % Angle
    end
    
    methods
        
        function myRollingBearing = rollingBearing(myElementType,myClassType,myModel,myName,myShaftFreq,myBd,myPd,myNb,myAngle)
            myId = '2';
            myRollingBearing = myRollingBearing@bearingElement(myElementType,myClassType,myModel,myName,myShaftFreq,myId);
            if(nargin == 9)
                myRollingBearing.Bd = myBd;
                myRollingBearing.Pd = myPd;
                myRollingBearing.Nb = myNb;
                myRollingBearing.angle = myAngle;
            elseif(nargin == 8)
                myRollingBearing.Bd = myBd;
                myRollingBearing.Pd = myPd;
                myRollingBearing.Nb = myNb;
                myRollingBearing.angle = 0;
            else
                myRollingBearing.Bd = [];
                myRollingBearing.Pd = [];
                myRollingBearing.Nb = [];
                myRollingBearing.angle = [];
            end
            myRollingBearing.basicFreqList = getBasicFreqList(myRollingBearing);
        end
        
        function myRollingBearing = setBd(myRollingBearing, myBd)
            myRollingBearing.Bd = myBd;
        end
        
        function myRollingBearing = setPd(myRollingBearing, myPd)
            myRollingBearing.Pd = myPd;
        end
        
        function myRollingBearing = setNb(myRollingBearing, myNb)
            myRollingBearing.Nb = myNb;
        end
        
        function myRollingBearing = setAngle(myRollingBearing, myAngle)
            myRollingBearing.angle = myAngle;
        end
        
        function myBd = getBd(myRollingBearing)
            myBd =  myRollingBearing.Bd;
        end
        
        function myPd = getPd(myRollingBearing)
            myPd = myRollingBearing.Pd;
        end
        
        function myNb = getNb(myRollingBearing)
            myNb = myRollingBearing.Nb;
        end
        
        function myAngle = getAngle(myRollingBearing)
            myAngle = myRollingBearing.angle;
        end
        
        function [Bd, Pd, Nb, angle] = getBearingParameters(myRollingBearing)
            Bd = myRollingBearing.Bd;
            Pd = myRollingBearing.Pd;
            Nb = myRollingBearing.Nb;
            angle = myRollingBearing.angle;
        end
        
        function [FTF , BSF , BPFO, BPFI, BEF, shaftFTF] = getBearingFreq(myBearing, shaftFreq)
            % Fundamental Train Frequency
            FTF = shaftFreq / 2 * (1 - myBearing.Bd / myBearing.Pd * cos(myBearing.angle * pi / 180));
            % Ball Spin Frequency
            BSF = myBearing.Pd / (2 * myBearing.Bd) * shaftFreq * (1 - (myBearing.Bd / myBearing.Pd)^2 * (cos(myBearing.angle * pi / 180))^2);
            % Ball Pass Frequency of Inner ring
            BPFI = myBearing.Nb / 2 * shaftFreq * (1 + myBearing.Bd / myBearing.Pd * cos(myBearing.angle * pi / 180));
            % Ball Pass Frequency of Outer ring
            BPFO = myBearing.Nb / 2 * shaftFreq * (1 - myBearing.Bd / myBearing.Pd * cos(myBearing.angle * pi / 180));
            % Ball Excitation Frequency
            BEF = 2 * shaftFreq * ((myBearing.Pd / myBearing.Bd)^2 - 1);
            % Shaft frequency - FTF 
            shaftFTF = shaftFreq - FTF;
        end
        
        function basicFreqList = getBasicFreqList(myRollingBearing)
            [FTF , BSF , BPFO, BPFI, BEF, shaftFTF]= getBearingFreq(myRollingBearing, myRollingBearing.shaftFreq);
            basicFreqList = [1, myRollingBearing.shaftFreq, {'shaftFreq'}; ...
							 11, FTF, {'FTF'}; ...
							 12, BSF, {'BSF'}; ... 
							 13, BPFO, {'BPFO'}; ...
							 14, BPFI, {'BPFI'}; ...
							 15, BEF, {'BEF'}; ...
                             33, shaftFTF, {'(shaft-FTF)'}; ...
                             ];
        end
        
    end
    
end

