classdef gearing < connectionElement
    %GEARING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties ( Access = protected )
        z1                         % the 1st shaft teeth count
        z2                         % the 2nd shaft teeth count
    end
    
    methods

    function myGearing = gearing(myElementType,myClassType,myName,myShaftFreq,myZ1,myZ2)
        myId = '3';
        myGearing = myGearing@connectionElement(myElementType,myClassType,myName,myShaftFreq,myId);
        if nargin == 5
            myGearing.z1 = myZ1;
            myGearing.z2 = myZ2;
        elseif nargin == 6
            myGearing.z1 = myZ1;
            myGearing.z2 = myZ2;
        else
            myGearing.z1 = [];
            myGearing.z2 = [];
        end
    end
         
     function [ shaftFreq1 , shaftFreq2,  teethFreq ]= getGearingFreq(myGearing, shaftFreq)
            shaftFreq1 = shaftFreq;                                                            
            shaftFreq2 = shaftFreq*myGearing.z1/myGearing.z2;              
            teethFreq = shaftFreq*myGearing.z1;                      
     end
     
    function basicFreqList = getBasicFreqList(myGearing)
        [ shaftFreq1 , shaftFreq2,  teethFreq ] = getGearingFreq(myGearing, myGearing.shaftFreq);
%         multiFreq = (teethFreq - shaftFreq2)/2;
%         basicFreqList = [1, shaftFreq1, {'shaftFreq1'}; 2, shaftFreq2, {'shaftFreq2'}; 3, teethFreq, {'teethFreq'}; 4, multiFreq, {'multiFreq'}];
        basicFreqList = [17, shaftFreq1, {'shaftFreq1'}; ...
						 18, shaftFreq2, {'shaftFreq2'}; ...
						 19, teethFreq, {'teethFreq'}];
    end
    
end
    
end

