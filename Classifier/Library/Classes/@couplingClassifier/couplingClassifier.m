classdef couplingClassifier < shaftClassifier
    %COUPLINGCLASSIFIER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        coupling
    end
    
    methods
        
%         function myClassifier = couplingClassifier(myClassifierStruct, myClassifierType, myValidator, myCouplingElement, frequencyTable)
%             myClassifier = myClassifier@shaftClassifier(myClassifierStruct, myClassifierType, myValidator, myCouplingElement, frequencyTable);
%             myClassifier.coupling = myCouplingElement;
%         end
        function myClassifier = couplingClassifier(myClassifierStruct, myClassifierType, myCouplingElement, frequencyTable)
            myClassifier = myClassifier@shaftClassifier(myClassifierStruct, myClassifierType, myCouplingElement, frequencyTable);
            myClassifier.coupling = myCouplingElement;
        end
        
        function myCoupling = getCoupling(myCouplingClassifier)
            myCoupling = myCouplingClassifier.coupling;
        end
         
        function myCoupling = setCoupling(myCouplingClassifier, myCoupling)
            myCouplingClassifier.coupling = myCoupling;
        end

        function [statusStruct] = getDefectStatus(myClassifier, config)
            [statusStruct] = getDefectStatus@shaftClassifier(myClassifier, config);
        end        
    end
    methods ( Access = protected )
        function  [status] = defectDecisionMaker(defStatus,varargin)
            defStatus = cell2mat(varargin);
            status = defStatus;
        end
    end
end

