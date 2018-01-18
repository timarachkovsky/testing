%STRUCT2DEFSTRUCT Summary of this function goes here
%   Detailed explanation goes here
function [ baseStruct ] = createBaseStruct(file, config)

if nargin < 2 
   config = []; 
end

% INFORMATIVETAGSSTRUCT consists of defects names and its main frequency
% sequencies in specific format
informativeTagsStruct = file.informativeTagsStruct.classStruct;
% MAINFREQSTRUCT consists of elements types, their names and the lists of
% basic frequencies for each element which have been recalculated in the
% schemeClassifier with respect of the current main shaft frequency value
mainFreqStruct = file.mainFreqStruct.element;


%% ___________________ Default Parameters _____________________________ %%
config = fill_struct(config, 'freqDomainEnable', 1);
config = fill_struct(config, 'timeDomainEnable', 1);
config = fill_struct(config, 'allDefectIdEnable', 1);

%% ___________________ Main Calculations ______________________________ %%
elementsNumber = length(mainFreqStruct);
j = 0;
for i = 1:1:elementsNumber
    
    classifierType = [mainFreqStruct(i).elementType,'Classifier'];
    elementType = mainFreqStruct(i).type;
    
    defectStruct = informativeTagsStruct.(classifierType).(elementType);
    defectsNumber = length(defectStruct.defect);
    for defectId = 1:1:defectsNumber
        j = j+1;
            baseStruct(j).elementType = mainFreqStruct(i).elementType;
            baseStruct(j).type = mainFreqStruct(i).type;
            baseStruct(j).name = mainFreqStruct(i).name;
            baseStruct(j).basicFreqs = mainFreqStruct(i).basicFreqs;
            baseStruct(j).defectName = defectStruct.defect{1,defectId}.Attributes.name;
            baseStruct(j).defectId = defectStruct.defect{1,defectId}.Attributes.id;
        if config.freqDomainEnable
            [baseStruct(j).freqDomain]= struct2defFreq( defectStruct, defectId, baseStruct(j).basicFreqs);
        end
        if config.timeDomainEnable
            [baseStruct(j).timeDomain]= struct2defFreq( defectStruct, defectId, baseStruct(j).basicFreqs,0);
        end
    end
end

end

