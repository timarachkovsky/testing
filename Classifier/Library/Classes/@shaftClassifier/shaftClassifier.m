classdef shaftClassifier < classifier
    
    properties ( Access = protected )
        shaftElement
        basicFreqList
    end
    
    methods

        function myClassifier = shaftClassifier(myClassifierStruct, myClassifierType, myShaftElement, frequencyTable)
            myClassifier = myClassifier@classifier(myClassifierStruct, myClassifierType, frequencyTable);
            myClassifier.shaftElement = myShaftElement;
            myClassifier.basicFreqList = getBasicFreqList(myShaftElement);
        end
        
        function myBasicFreqList = getBasicFreqList(myClassifier)
            myBasicFreqList = myClassifier.basicFreqList;
        end  
        
        function setBasicFreqList(myClassifier, myBasicFreqList)
             myClassifier.basicFreqList = myBasicFreqList;
        end  
        
        function myShaftElement = getShaftElement(myClassifier)
            myShaftElement = myClassifier.shaftElement;
        end  
        
        function setShaftElement(myClassifier, myShaftElement)
             myClassifier.shaftElement = myShaftElement;
        end  

        function   [ statusStruct] = getDefectStatus(myClassifier, config)
            [statusStruct] = getDefectStatus@classifier( myClassifier, myClassifier.shaftElement,config);  
        end

    end
    
    methods ( Access = protected )       
            function    status_out = defectDecisionMaker(status_in, varargin)
            
            status_in = cell2mat(varargin);
            % Here should be some disp code
            status_out = status_in;

            end
        end
 end
    

