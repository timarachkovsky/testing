classdef bearingClassifier < shaftClassifier
    
    properties ( Access = protected )
        bearing       % shaft bearing type
    end
    
    methods

%         function myClassifier = bearingClassifier(myClassifierStruct,myClassifierType,myValidator,myBearingElement, frequencyTable)  
%             myClassifier = myClassifier@shaftClassifier(myClassifierStruct,myClassifierType,myValidator,myBearingElement, frequencyTable);
%             myClassifier.bearing = myBearingElement;
%         end

        function myClassifier = bearingClassifier(myClassifierStruct,myClassifierType,myBearingElement, frequencyTable)  
            myClassifier = myClassifier@shaftClassifier(myClassifierStruct,myClassifierType,myBearingElement, frequencyTable);
            myClassifier.bearing = myBearingElement;
        end
        
        function myBearing = getBearing(myBearingClassifier)
            myBearing = myBearingClassifier.bearing;
        end
         
        function  setBearing(myBearingClassifier,myBearing)
            myBearingClassifier.bearing = myBearing;
        end
        
%         function [profile, bearing, shaftFreq, tagList] = getClassifierParameters(myClassifier)
%                 profile = myClassifier.profile;
%                 bearing = myClassifier.bearing;
%                 shaftFreq = myClassifier.shaftFreq;
%                 tagList = myClassifier.tagList;
%         end
        
%         function myTagList = getTagList(myClassifier)
%                 [ FTF , BSF , BPFO, BPFI ]= getMainFreq(myClassifier.bearing, myClassifier.shaftFreq);
%                 myTagList = [1 myClassifier.shaftFreq; 2 FTF; 3 BSF; 4 BPFO; 5 BPFI ];
% %                 clear -regexp ^FTF ^BSF ^BPFO ^BPFI;
%         end
     
        
        %% Add user login below this line
        
        [ status ] = getBearingDefectStatusID1(validMainPeaks2,validMainPeaks20,validAddPeaks2,validAddPeaks20)       % Defect #3 OUTER RING SKEWNESS
        [ status ] = getBearingDefectStatusID2(validMainPeaks2,validMainPeaks20,validAddPeaks2,validAddPeaks20)       % Defect #4 OUTER RING WEAR
        [ status ] = getBearingDefectStatusID3(validMainPeaks2,validMainPeaks20,validAddPeaks2,validAddPeaks20)       % Defect #5 SINKS (CRACKS) on the OUTER RING
        [ status ] = getBearingDefectStatusID4(validMainPeaks2,validMainPeaks20,validAddPeaks2,validAddPeaks20)       % Defect #6 INNER RING WEAR
        [ status ] = getBearingDefectStatusID5(validMainPeaks2,validMainPeaks20,validAddPeaks2,validAddPeaks20)       % Defect #7 SINKS (CRACKS) on the INNER RING
        [ status ] = getBearingDefectStatusID6(validMainPeaks2,validMainPeaks20,validAddPeaks2,validAddPeaks20)       % Defect #8 The WEAR of ROLLING ELEMENTS and SEPERATOR
        [ status ] = getBearingDefectStatusID7(validMainPeaks2,validMainPeaks20,validAddPeaks2,validAddPeaks20)       % Defect #9 SINKS, CHIPS on the ROLLING ELEMENTS

        %    Add user login above this line
        
        %% 
       
%         function   [ status,statusName, mDefFreq,mDefMag,aDefFreq,aDefMag,mValidDefFreq,mValidDefMag,aValidDefFreq,aValidDefMag ] = getDefectStatus( innerSignal, Fs, myClassifier)
%                 
% %              N = 8;
%              [ status,statusName, mDefFreq,mDefMag,aDefFreq,aDefMag,mValidDefFreq,mValidDefMag,aValidDefFreq,aValidDefMag] = getDefectStatus@shaftClassifier( innerSignal, Fs, myClassifier);
%             
%         end

%         function   [statusStruct] = getDefectStatus( innerSignal, Fs, myClassifier, config)
%              [statusStruct] = getDefectStatus@shaftClassifier( innerSignal, Fs, myClassifier, config);
%         end

        function   [statusStruct] = getDefectStatus(myClassifier, config)
             [statusStruct] = getDefectStatus@shaftClassifier(myClassifier, config);
        end

    end
    
    
        methods ( Access = protected )
        
        function    status_out = defectDecisionMaker(status_in, varargin)
            
            status_in = cell2mat(varargin);
            status_out = status_in;

        end
        
    end
           
end
   

