function [ isModFlag, carrierTag, modulationTag ] = isModulationTag( myTag )
%ISMODULATIONTAG function returns isModFlag: 1 - @true; 0 - @false
% myTag format =>> {[carrierTag, modulationTag]} - isModFlag = 1
% myTag format =>> {[carrierTag]} - isModFlag = 0
    
    myTagLength = length(myTag{1,1});    
    if myTagLength > 1
        isModFlag = true(1);
        carrierTag{1,1} = myTag{1,1}(1,1);
        modulationTag{1,1} = myTag{1,1}(1,2);
    else
        isModFlag = false(1);
        carrierTag = [];
        modulationTag = [];
    end
    
end

