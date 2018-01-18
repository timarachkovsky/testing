classdef defectEvaluator
    
    properties (Access = protected)
        
        % Output property:
        statusStruct
    end
    
    methods (Access = public)
        
        function [myDefectEvaluator] = defectEvaluator(myDefectStruct, myEquipmentClass, initialPeakTable)
            myStatusStruct = createStatusStruct(myDefectEvaluator, myDefectStruct, myEquipmentClass, initialPeakTable);
            myDefectEvaluator.statusStruct = myStatusStruct;
        end
        
        % Getters / Setters ...
        function [myStatusStruct] = getStatusStruct(myDefectEvaluator)
            myStatusStruct = myDefectEvaluator.statusStruct;
        end
        function [myDefectEvaluator] = setStatusStruct(myDefectEvaluator, myStatusStruct)
            myDefectEvaluator.statusStruct = myStatusStruct;
        end
        % ... Getters / Setters
    end
    
    methods (Access = protected)
        
        function [myDefectStruct] = createStatusStruct(myDefectEvaluator, myDefectStruct, myEquipmentClass, initialPeakTable)
%             myDefectStruct = myDefectStruct;
            % Evaluate defects
            defectTagNames = {myDefectStruct.defectTagName};
            for defectNumber = 1 : 1 : length(defectTagNames)
                if myDefectStruct(defectNumber).enable
                    defFuncName = myDefectStruct(defectNumber).defFuncName;
                    [similarity, level, myDefectStruct(defectNumber)] = feval(defFuncName, myDefectStruct(defectNumber), myEquipmentClass, initialPeakTable);
                    myDefectStruct(defectNumber).similarity = double(similarity);
                    myDefectStruct(defectNumber).level = level;
                else
                    myDefectStruct(defectNumber).similarity = -0.01;
                    myDefectStruct(defectNumber).level = [];
                end
            end
        end

    end
    
end

