classdef accEnvSpecValidator < accSpecValidator
    % ACCENVSPECVALIDATOR class is validated frequency with tags 
    % and numbers of harmonics into acceleration spectral domain
    
    methods (Access = public)
        
        % Constructor function ... 
        function [myValidator] = accEnvSpecValidator(statusStruct,peakTable,mainFreqStruct,informativeTagsStruct,myConfig)
		
            validatorType = 'accelerationEnvelopeSpectrum';
            myValidator = myValidator@accSpecValidator(statusStruct,peakTable,mainFreqStruct,informativeTagsStruct,myConfig,validatorType);
            
        end
        
        % VALIDATIONPROCESSING a function is main for validation of peaks, 
        % added the column into peakTable for frequencyCorrection
        function [ myValidator ] = validationProcessing(myValidator)
                        
            [ preContainer ] = myValidator.createPreValidationContainer();
            [ myValidator ] = preValidation(myValidator, preContainer);
            
            [ postContainer ] = myValidator.createPostValidationContainer();
            [ myValidator ] = postValidation(myValidator, postContainer);
            
            [ myValidStruct ] = addValidData2ValidStruct(myValidator);            
            myValidator.validStruct = myValidStruct;
            
            validPeaks = addColumn(myValidator);
            myValidator.filledPeakTable(:,end+1) = validPeaks;
            
            myValidator.nonValidPeaksNumbers = nnz(~validPeaks);

        end
            
    end 
end

