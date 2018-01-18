classdef fanClassifier < shaftClassifier 
    % FANCLASSIFIER class is designed to find required 
    % frequency in spectrum
    
    properties
        fan
    end
    
    methods
        % Constructor function
%         function myFanClassifier = fanClassifier(myClassifierStruct,myClassifierType,myValidator,myFanElement, frequencyTable)
%             myFanClassifier = myFanClassifier@shaftClassifier(myClassifierStruct,myClassifierType,myValidator,myFanElement, frequencyTable);
%             myFanClassifier.fan = myFanElement;
%         end
        function myFanClassifier = fanClassifier(myClassifierStruct,myClassifierType,myFanElement, frequencyTable)
            myFanClassifier = myFanClassifier@shaftClassifier(myClassifierStruct,myClassifierType,myFanElement, frequencyTable);
            myFanClassifier.fan = myFanElement;
        end
        
        % Getter / setter ...
        function myFan = getFan(myFanClassifier)
            myFan = myFanClassifier.fan;
        end
        
        function setFan(myFanClassifier, myFan)
           myFanClassifier.fan =  myFan;
        end
        % ... Getter / setter
        
        function [ statusStruct ] = getDefectStatus(myClassifier, config)
            [ statusStruct] = getDefectStatus@shaftClassifier(myClassifier, config);
        end
    end
    
    methods ( Access = protected )
        function  [status] = defectDecisionMaker(defStatus,varargin)
            defStatus = cell2mat(varargin);
            status = defStatus;
        end
    end
end

