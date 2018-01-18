% Developer:            Kosmach
% Date:                 03.10.2016   
% Modified by:          Kosmach 
% Modification date:    05.04.2017 added finding of frequencies with less grid   

% GETMODULATIONEVALUATIONVECTOR function is evaluate modulation
function [uniqVector, estimationVector, magnitudes, logProminence, weights, defectStruct] = ...
    getModulationEvaluationVector(defectStruct, tagNameMod, initialPeakTable, basicFreqs)

    % finding the side vector modulation components
    [positionVectorMod, sidebandName, ~, ~, ~, frequenciesSideband, positionsSideBand] ...
        = getTagPositions(defectStruct, tagNameMod);
    % finding the main vector modulation components
    [positionMain, ~, magnitudes, logProminence, weights, frequenciesMain] ...
        = getTagPositions(defectStruct, {(tagNameMod{1,1}(1,1))});
    % vector unique positions
    uniqVector = positionMain;
    % vector weight modulations
    estimationVector = zeros([length(uniqVector) 1]);
    
    sidebandNameValid = cell(length(sidebandName),1);
    structSideband = createEmptyStruct(length(sidebandName));
    % formation weight vector modulation
    frequencyModulating = basicFreqs(ismember(cell2mat(basicFreqs(:,1)), tagNameMod{1}(2)),2);
    for i = 1:1:length(uniqVector)
        sidebandNameForPeak = sidebandName(positionVectorMod == uniqVector(i,1));
        mainNum = nnz(positionMain == uniqVector(i,1));
        
        structureForPeak.mainPeak = mainNum;
        structureForPeak.mainFreq = frequenciesMain(positionMain == uniqVector(i,1));
        structureForPeak.sidebandName = sidebandNameForPeak;
        structureForPeak.sidebandFreq = frequenciesSideband(positionVectorMod == uniqVector(i,1));
        
        [mainNum, sidebandNameForPeakValid, structSidebandForPeak] = modulationsSearch(initialPeakTable, structureForPeak, frequencyModulating{1});
        if ~isempty(sidebandNameForPeakValid)
            posEmpty = find(~cellfun(@isempty, sidebandNameValid),1,'last') + 1;
            if isempty(~posEmpty)
                posEmpty = 1;
            end
            positionTemp = posEmpty:posEmpty + length(sidebandNameForPeakValid)-1;
            sidebandNameValid(positionTemp) = sidebandNameForPeakValid;
            structSideband.posChangedFreq(positionTemp) = structSidebandForPeak.posChangedFreq;
            structSideband.validMag(positionTemp) = structSidebandForPeak.validMag;
            structSideband.validFreq(positionTemp) = structSidebandForPeak.validFreq;
            structSideband.validLogProm(positionTemp) = structSidebandForPeak.validLogProm;
            structSideband.validProm(positionTemp) = structSidebandForPeak.validProm; 
        end
        % determination of the weight of each modulation and rounding the result
        estimationVector(i,1) = round(getModulationEvaluation(mainNum, sidebandNameForPeakValid)*100)/100;
        
    end
    % Delet empty cells
    posNeenedDeleting = ~cellfun(@isempty, sidebandNameValid);
%     if (length(structSideband.validMag) ~= nnz(structSideband.validMag)) && ...
%             (~isempty(structSideband.validMag))
%         posNeenedDeleting = logical(bsxfun(@times,posNeenedDeleting,structSideband.validMag>0));
%     end
    sidebandNameValid = sidebandNameValid(posNeenedDeleting);
    structSideband.posChangedFreq = structSideband.posChangedFreq(posNeenedDeleting);
    structSideband.validMag = structSideband.validMag(posNeenedDeleting);
    structSideband.validFreq = structSideband.validFreq(posNeenedDeleting);
    structSideband.validLogProm = structSideband.validLogProm(posNeenedDeleting);
    structSideband.validProm = structSideband.validProm(posNeenedDeleting);
    defectStruct = deleteUnvalidModulation(...
            sidebandNameValid, sidebandName, positionsSideBand, defectStruct, structSideband);
end

% DELETEUNVALIDMODULATION function delete invalid modulation peaks
function defectStruct = deleteUnvalidModulation(nameValid, name, positions, defectStruct, structSideband)

if ~isempty(name) || ~isempty(nameValid)
    posTrueValid = ismember(name,nameValid);
    
    % Delete unvalid frequencies
    if ~(nnz(posTrueValid) == length(name)) 
        positionNonMember = positions(~posTrueValid);
        vectorAllPosition = 1:1:length(defectStruct.mainFrequencyTagNumberValid);
        truePosition = vectorAllPosition(~ismember(vectorAllPosition, positionNonMember));
        defectStruct.mainFrequencyTagNumberValid = ...
            defectStruct.mainFrequencyTagNumberValid(truePosition,1);
        defectStruct.mainFrequencyNameValid = ...
            defectStruct.mainFrequencyNameValid(truePosition,1);
        defectStruct.mainMagnitudeValid = ...
            defectStruct.mainMagnitudeValid(truePosition,1);
        defectStruct.mainLogProminenceValid = ...
            defectStruct.mainLogProminenceValid(truePosition,1);
        defectStruct.mainWeightValid = ...
            defectStruct.mainWeightValid(truePosition,1);
        defectStruct.mainFrequencyValid = ...
            defectStruct.mainFrequencyValid(truePosition,1);
        defectStruct.mainFrequencyTagValid = ...
            defectStruct.mainFrequencyTagValid(truePosition,1);
        defectStruct.mainFrequencyTagNameValid = ...
            defectStruct.mainFrequencyTagNameValid(truePosition,1);
        defectStruct.mainProminenceValid = ...
            defectStruct.mainProminenceValid(truePosition,1);

        % Replace value such as frequency, logProminence, etc
        if nnz(structSideband.posChangedFreq)
            posNeededReplace = logical(structSideband.posChangedFreq);
            % Main frequencies
            posTrueValidReplace = ismember(defectStruct.mainFrequencyNameValid, ...
                nameValid(posNeededReplace));
%             positionsReplace = positions(posTrueValidReplace);
            
            defectStruct.mainFrequencyValid(posTrueValidReplace) = ...
            structSideband.validFreq(posNeededReplace);
            defectStruct.mainMagnitudeValid(posTrueValidReplace) = ...
            structSideband.validMag(posNeededReplace);
            defectStruct.mainLogProminenceValid(posTrueValidReplace) = ...
            structSideband.validLogProm(posNeededReplace);
            defectStruct.mainProminenceValid(posTrueValidReplace) = ...
            structSideband.validProm(posNeededReplace);   
        end
        
        [indexAdditional, indexMain] = ismember(defectStruct.additionalFrequencyNameValid,...
                    defectStruct.mainFrequencyNameValid);
        indexMain = nonzeros(indexMain);
                
        defectStruct.additionalFrequencyNameValid = ...
            defectStruct.additionalFrequencyNameValid(indexAdditional,1);
        defectStruct.additionalFrequencyTagValid = ...
            defectStruct.additionalFrequencyTagValid(indexAdditional,1);
        defectStruct.additionalWeightValid = ...
            defectStruct.additionalWeightValid(indexAdditional,1); 
        
        defectStruct.additionalFrequencyValid = ...
            defectStruct.mainFrequencyValid(indexMain,1);
        defectStruct.additionalMagnitudeValid = ...
            defectStruct.mainMagnitudeValid(indexMain,1);
        defectStruct.additionalProminenceValid = ...
            defectStruct.mainProminenceValid(indexMain,1);
    else
        if nnz(structSideband.posChangedFreq)
            % Replace value such as frequency, logProminence, etc
            if nnz(structSideband.posChangedFreq)
                % Main frequencies
                posNeededReplace = logical(structSideband.posChangedFreq);
                posTrueValidReplace = ismember(defectStruct.mainFrequencyNameValid, ...
                nameValid(posNeededReplace));
%                 positionsReplace = positions(posTrueValidReplace);

                defectStruct.mainFrequencyValid(posTrueValidReplace) = ...
                structSideband.validFreq(posNeededReplace);
                defectStruct.mainMagnitudeValid(posTrueValidReplace) = ...
                structSideband.validMag(posNeededReplace);
                defectStruct.mainLogProminenceValid(posTrueValidReplace) = ...
                structSideband.validLogProm(posNeededReplace);
                defectStruct.mainProminenceValid(posTrueValidReplace) = ...
                structSideband.validProm(posNeededReplace);   
            
                [~, indexMain] = ismember(defectStruct.additionalFrequencyNameValid,...
                    defectStruct.mainFrequencyNameValid);
                indexMain = nonzeros(indexMain);

                defectStruct.additionalFrequencyValid = ...
                    defectStruct.mainFrequencyValid(indexMain,1);
                defectStruct.additionalMagnitudeValid = ...
                    defectStruct.mainMagnitudeValid(indexMain,1);
                defectStruct.additionalProminenceValid = ...
                    defectStruct.mainProminenceValid(indexMain,1);
            end
        end
    end
end
end

% CREATEEMPTYSTRUCT function creating the empty structure for finding frequencies
function structSideband = createEmptyStruct(sizeStruct)
    structSideband.posChangedFreq = zeros(sizeStruct,1);
    structSideband.validMag = structSideband.posChangedFreq;
    structSideband.validFreq = structSideband.posChangedFreq;
    structSideband.validLogProm = structSideband.posChangedFreq;
    structSideband.validProm =  structSideband.posChangedFreq;
end