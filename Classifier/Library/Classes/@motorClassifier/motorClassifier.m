classdef motorClassifier < shaftClassifier
    %MOTORCLASSIFIER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties( Access = protected )
        motor
    end
    
    methods
        
        [ status ] = motorDefectStatusID1(validMainPeaks,validAddPeaks)       % Defect #1
        [ status ] = motorDefectStatusID2(validMainPeaks,validAddPeaks)       % Defect #2
        [ status ] = motorDefectStatusID3(validMainPeaks,validAddPeaks)       % Defect #3
        [ status ] = motorDefectStatusID4(validMainPeaks,validAddPeaks)       % Defect #4
        [ status ] = motorDefectStatusID5(validMainPeaks,validAddPeaks)       % Defect #5
        
%       function myClassifier = motorClassifier(myClassifierStruct,myClassifierType,myValidator,myMotorElement, frequencyTable)
%             myClassifier = myClassifier@shaftClassifier(myClassifierStruct,myClassifierType,myValidator,myMotorElement, frequencyTable);
%             myClassifier.motor = myMotorElement;
%       end 
      function myClassifier = motorClassifier(myClassifierStruct,myClassifierType,myMotorElement, frequencyTable)
            myClassifier = myClassifier@shaftClassifier(myClassifierStruct,myClassifierType,myMotorElement, frequencyTable);
            myClassifier.motor = myMotorElement;
      end 
        
      function myMotor = getMotor(myMotorClassifier)
            myMotor = myMotorClassifier.motor;
      end
        
      function  setMotor(myMotorClassifier,myMotor)
            myMotorClassifier.motor = myMotor;
      end
      
%       function [ statusStruct ] = getDefectStatus( innerSignal, Fs, myClassifier, config)
%             [ statusStruct] = getDefectStatus@shaftClassifier( innerSignal, Fs, myClassifier, config);
%         end

        function [ statusStruct ] = getDefectStatus(myClassifier, config)
            [ statusStruct] = getDefectStatus@shaftClassifier(myClassifier, config);
        end
    end
    
    methods ( Access = protected )
                function  [status] = defectDecisionMaker(defStatus,varargin)
                    defStatus = cell2mat(varargin);
                    status = defStatus;
%                     status = [];
                end
    end
end

