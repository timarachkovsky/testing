classdef velSpecValidator < dispSpecValidator
    %VELSPECVALIDATOR class is validated frequency with tags 
    % and numbers of harmonics into velocity domain
    
    properties (Access = protected)
    end
    
    methods (Access = public)
        
        % Constructor function ... 
        function [myValidator] = velSpecValidator(statusStruct,peakTable,mainFreqStruct,informativeTagsStruct,myConfig)
            
            validatorType = 'velocitySpectrum';
            myValidator = myValidator@dispSpecValidator(statusStruct,peakTable,mainFreqStruct,informativeTagsStruct,myConfig,validatorType);
            
        end
        
        % Getters / Setters ...
        
        % ... Getters / Setters 
        
    end
    
end