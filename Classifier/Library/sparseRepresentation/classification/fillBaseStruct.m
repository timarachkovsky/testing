%FILLBASESTRUCT Summary of this function goes here
%   Detailed explanation goes here
function [ result, baseStruct ] = fillBaseStruct( baseStruct, validResult, file, config )

%% ________________________ Default Parameters ________________________ %%

if nargin < 2
   config = []; 
end

% config = fill_struct(config, '');

validDefectsNumber = length(validResult);
baseStructLength = length(baseStruct);
baseStruct = repmat(baseStruct,1,validDefectsNumber);
%% ________________________ Calculations ______________________________ %%
k = 0;
l = 0;
for i=1:1:validDefectsNumber
    file.frequency = validResult{i,1}.frequency;
    
    mySparseClassifier =  schemeClassifier(file.classifierStruct,...
                                file.informativeTagsFile, config, validResult{i,1}.peakTable);
    [~, statusStruct] = getStatusFile( mySparseClassifier,...
                                validResult{i,1}.envelopeSpectrum, file.Fs);
    
    for j=1:1:baseStructLength
        k = k+1;
        if ~isempty(baseStruct(k).timeDomain)
            file.frequencyTable = baseStruct(k).timeDomain.defFreq';
        else
            baseStruct(k).validTimeDomain = [];
            continue
        end
        [~ ,frequency] = peakComparison(file);
        if ~nnz(frequency)
            baseStruct(k).validTimeDomain = [];
        else
            l=l+1;
            baseStruct(k).validTimeDomain.defFreq = frequency;
            baseStruct(k).validTimeDomain.defFreqName = baseStruct(k).timeDomain.defFreqName(find(baseStruct(k).timeDomain.defFreq==frequency));
            baseStruct(k).energyContribution = validResult{i,1}.energyContribution;
            baseStruct(k).scaleRange = validResult{i,1}.scaleRange;
            baseStruct(k).peakTable = validResult{i,1}.peakTable;
            baseStruct(k).sparseSignal = validResult{i,1}.sparseSignal;
            baseStruct(k).envelopeSpectrum = validResult{i,1}.envelopeSpectrum;
            baseStruct(k).pattern = validResult{i,1}.pattern;
            
            [~,defNum] = strtok( baseStruct(k).defectId, '_');defNum = str2num(defNum(2:end));            
            elementDefStruct = statusStruct.([baseStruct(k).elementType,'Defects']).(baseStruct(k).type);
            
            strNum = 0;
            for s = 1:1:numel(elementDefStruct)
               if strcmp(elementDefStruct{1,s}.name,baseStruct(k).name)
                   strNum = s;
                   break
               end
            end
            if ~nnz(strNum)
               warning('There no such element in the status struct!'); 
            end
            
            baseStruct(k).validFreqDomain.defFreq = elementDefStruct{1,strNum}.mDefFreq{defNum,1};
            baseStruct(k).validFreqDomain.defFreqName = elementDefStruct{1,strNum}.mDefFreqName{defNum,1};
            baseStruct(k).validFreqDomain.defMag = elementDefStruct{1,strNum}.mDefMag{defNum,1};
            
            result(l)= baseStruct(k);
                     
        end
%         frequency = [];
    end
end

end

