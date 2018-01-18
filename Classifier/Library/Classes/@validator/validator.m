classdef validator
    %VALIDATOR class is create tables of futher processing, 
    % class is superclass for accEnvSpecValidator, accSpecValidator,
    % velSpecValidator, dispSpecValidator
    
    properties (Access = public)
        
        % INPUT:
        Config % Configuration structure for

        % INTERNAL:
        filledPeakTable %
        
        numTable        % 
        tagTable        % 
        magTable        % Contains features of logMagnitude data
        nameTableMod    %
        freqTableRelevantPeakTable % Position frequencies into peakTable (use repeating frequencies)
        
        maskTable       % 
        
        % OUTPUT: 
        validStruct     % VALIDSTRUCT
        nonValidPeaksNumbers
        
        iLoger
    end
    
    methods (Access = public)
        
        % Constructor
        function [myValidator] = validator(myStatusStruct, myPeakTable, myMainDefectStruct, informationTagsStruct, myConfig, validatorType)
            
            if nargin <= 4
               myConfig = []; 
            end
            
            myValidator.iLoger = loger.getInstance;
            myValidator.Config = myConfig;
            myValidator.nonValidPeaksNumbers = [];
            
            [ myValidator ] = createValidStruct(myValidator,myStatusStruct,myPeakTable,myMainDefectStruct,informationTagsStruct,validatorType);

            %Delete fields without current domain
            if isfield(myValidator.validStruct, 'baseFreq') 

                domainDefect = arrayfun(@(x) ~isempty(x{:}), {myValidator.validStruct.baseFreq});
                myValidator.validStruct = myValidator.validStruct(domainDefect);
                myValidator.validStruct = myValidator.validStruct;
                myValidator.freqTableRelevantPeakTable = myValidator.freqTableRelevantPeakTable(:,domainDefect);

                myValidator.filledPeakTable = myPeakTable.(validatorType);

                myFrequnecyTagTable = [myValidator.validStruct(:).mainFrequencyTag];
                myFrequencyNameTable = [myValidator.validStruct(:).mainFrequencyName];
                myValidator.magTable = [myValidator.validStruct(:).mainLogProminence];
                
                [ myValidator ] = createSubTables(myValidator,myFrequnecyTagTable,myFrequencyNameTable);
            else
                myValidator = createEmptyValidator(myValidator, myPeakTable.(validatorType));
            end

        end
        
        % Getters / Setters ...

        function [myConfig] = getConfig(myValidator)
            myConfig = myValidator.config;
        end  
        function [myValidator] = setConfig(myValidator,myConfig)
            myValidator.config = myConfig;
        end
        
        function [myFilledPeakTable] = getFilledPeakTable(myValidator)
            myFilledPeakTable = myValidator.filledPeakTable;
        end  
        function [myValidator] = setFilledPeakTable(myValidator,myFilledPeakTable)
            myValidator.filledPeakTable = myFilledPeakTable;
        end
        
        function [myNumTable] = getNumTable(myValidator)
            myNumTable = myValidator.numTable;
        end  
        function [myValidator] = setNumTable(myValidator,myNumTable)
            myValidator.numTable = myNumTable;
        end

        function [myTagTable] = getTagTable(myValidator)
            myTagTable = myValidator.tagTable;
        end  
        function [myValidator] = setTagTable(myValidator,myTagTable)
            myValidator.tagTable = myTagTable;
        end

        function [myMagTable] = getMagTable(myValidator)
            myMagTable = myValidator.magTable;
        end  
        function [myValidator] = setMagTable(myValidator,myMagTable)
            myValidator.magTable = myMagTable;
        end
        
        function [myNameTableMod] = getNameTableMod(myValidator)
            myNameTableMod = myValidator.nameTableMod;
        end  
        function [myValidator] = setNameTableMod(myValidator,myNameTableMod)
            myValidator.nameTableMod = myNameTableMod;
        end
        
        function [myMaskTable] = getMaskTable(myValidator)
            myMaskTable = myValidator.maskTable;
        end  
        function [myValidator] = setMaskTable(myValidator,myMaskTable)
            myValidator.maskTable= myMaskTable;
        end
        
        function [myValidStruct] = getValidStruct(myValidator)
            myValidStruct = myValidator.validStruct;
        end  
        function [myValidator] = setValidStruct(myValidator,myValidStruct)
            myValidator.validStruct = myValidStruct;
        end

        % ... Getters / Setters 
              
    end
    
    methods (Access = protected)
        % The list of internal function for further incorporation
        
        % CREATEVALIDSTRUCT function forms base table for validation 
        function [myValidator] = createValidStruct(myValidator,statusStruct,peakTable,mainFreqStruct,informativeTagsStruct,validatorType)
            
            if nargin < 6
                validatorType = 'displacementSpectrum'; % displacementSpectrum / velocitySpectrum / 
                                                        % accelerationSpectrum / accelerationEnvelopeSpectrum
            end
            
            mainFreqStruct = mainFreqStruct.element;
            informativeTagsStruct = informativeTagsStruct.classStruct;
            elementsNumber = length(mainFreqStruct);
            
            % Find number of defects 
            numberDefectsMax = 0;
            for i = 1:1:elementsNumber
                
                classifierType = [mainFreqStruct(i).elementType,'Classifier'];
                elementClass = mainFreqStruct(i).classType;
                defectsNumber = length(informativeTagsStruct.(classifierType).(elementClass).defect);
                numberDefectsMax = numberDefectsMax + defectsNumber;
            end
            
            % Create empty validator table
            [myValidStruct] = myValidator.createEmptyValitadotTable(numberDefectsMax);
            
            % Fill validator table
            j = 0;
            for i = 1:1:elementsNumber

                classifierType = [mainFreqStruct(i).elementType,'Classifier'];
                elementClass = mainFreqStruct(i).classType;
                defectStruct = informativeTagsStruct.(classifierType).(elementClass);
                defectsNumber = length(defectStruct.defect);

                for defectId = 1:1:defectsNumber
                    j = j+1;
                    myValidStruct(j).elementType = mainFreqStruct(i).elementType;
                    myValidStruct(j).class = mainFreqStruct(i).classType;
                    myValidStruct(j).name = mainFreqStruct(i).name;
                    myValidStruct(j).basicFreqs = mainFreqStruct(i).basicFreqs;
                    myValidStruct(j).defectName = defectStruct.defect{1,defectId}.Attributes.name;
                    myValidStruct(j).defectTagName = defectStruct.defect{1,defectId}.Attributes.tagName;
                    myValidStruct(j).defectId = defectStruct.defect{1,defectId}.Attributes.id;
                    myValidStruct(j).defFuncName = [myValidStruct(j).class,'_',myValidStruct(j).defectTagName];
                end
            end
            [myValidStruct,freqTableRelevant] = fillValidStruct(myValidator,statusStruct,peakTable,myValidStruct,validatorType);
            
            % Set result
            myValidator.validStruct = myValidStruct;
            myValidator.freqTableRelevantPeakTable = freqTableRelevant;

        end
        
        % FILLVALIDSTRUC function extracts found defect features from the
        % statusStruct and fills with them the validStruct
        function [myValidStruct,freqTableRelevant] = fillValidStruct(myValidator,statusStruct,peakTable,myValidStruct,validatorType)
            
            validStructLength = int16(length(myValidStruct));
            maxLength = myValidator.getMaxRangeWhithRepeated(statusStruct,peakTable,myValidStruct,validatorType);
            freqTableRelevant = zeros(maxLength, validStructLength, 'int16');
            
            for k = 1:1:validStructLength

                [~,defNum] = strtok(myValidStruct(k).defectId, '_');
                defNum = str2double(defNum(2:end));            
                elementDefStruct = statusStruct.([myValidStruct(k).elementType,'Defects']).(myValidStruct(k).elementType);
                
                strNum = 0;
                for s = 1:1:numel(elementDefStruct)
                   if strcmp(elementDefStruct{1,s}.name,myValidStruct(k).name)
                       strNum = s;
                       break
                   end
                end
                if ~nnz(strNum)
                   printWarning(myValidator.iLoger, 'There no such element in the status struct!'); 
                end
                
                % Check for availability domain in defect
                if ~isempty(elementDefStruct{1,strNum}.(validatorType).mainFrequency{defNum,1})
                    if isnan(elementDefStruct{1,strNum}.(validatorType).mainFrequency{defNum,1})
                        existDomain = 0;
                    else
                        existDomain = 1;
                    end
                else
                    existDomain = 1;
                end
                
                if existDomain	
                    
                    myValidStruct(k).id = elementDefStruct{1,strNum}.id;
                    myValidStruct(k).baseFreq = elementDefStruct{1,strNum}.baseFreq;
                    myValidStruct(k).priority = logical(elementDefStruct{1,strNum}.priority);
                    myValidStruct(k).enable = elementDefStruct{1,strNum}.enable;
                    
					% Fill baseStruct with main content
					mainFrequencyName = cell(maxLength,1);
					mainFrequencyTag = mainFrequencyName;
					mainMagnitude = zeros(maxLength, 1, 'single');
					mainFrequency = mainMagnitude;
					mainProminence = mainMagnitude;
					mainLogProminence = mainMagnitude;
					mainWeight = mainMagnitude;
                    if ~isempty(elementDefStruct{1,strNum}.(validatorType).mainFrequency{defNum,1}) && elementDefStruct{1,strNum}.enable
                        tempVector(:,1) = single(elementDefStruct{1,strNum}.(validatorType).mainFrequency{defNum,1});
                        newPos = zeros(size(tempVector));
                        memoryForRepeatedFrequency = 0;
                        numberRepeated = 0;
                        for i=1:1:length(tempVector(:,1))
                            
                           % Processing for repeated main frequency
                           numberRepeatedCurrent = nnz(tempVector(i,1) == tempVector);
                           if numberRepeatedCurrent > 1
                               if length(memoryForRepeatedFrequency) == 1
                                   posElement = find(peakTable.(validatorType)(:,1)==tempVector(i,1))+numberRepeated;

                                   memoryForRepeatedFrequency = posElement:1:posElement+numberRepeatedCurrent-1;
                                   newPos(i,:) = posElement;
                                   numberRepeated = numberRepeatedCurrent+numberRepeated-1;
                                   indexMemoryPos = 1;
                               else   
                                   indexMemoryPos = 1+indexMemoryPos;
                                   if indexMemoryPos > length(memoryForRepeatedFrequency)
                                       posElement = find(peakTable.(validatorType)(:,1)==tempVector(i,1))+numberRepeated;
                                       memoryForRepeatedFrequency = posElement:1:posElement+numberRepeatedCurrent-1;
                                       numberRepeated = numberRepeatedCurrent+numberRepeated-1;
                                       indexMemoryPos = 1;
                                   end
                                   newPos(i,:) = memoryForRepeatedFrequency(indexMemoryPos);
                               end
                           else
                               memoryForRepeatedFrequency = 0;
                               [newPos(i,:)] = find(peakTable.(validatorType)(:,1)==tempVector(i,1))+numberRepeated;
                           end

                           freqTableRelevant(newPos(i,:),k) = find(peakTable.(validatorType)(:,1)==tempVector(i,1));
                           mainFrequencyName{newPos(i,1),:} = elementDefStruct{1,strNum}.(validatorType).mainFrequencyName{defNum,1}{1,i};
                           mainFrequencyTag{newPos(i,1),:} = elementDefStruct{1,strNum}.(validatorType).mainFrequencyTag{defNum,1}{1,i};
                           mainMagnitude(newPos(i,1),:) = elementDefStruct{1,strNum}.(validatorType).mainMagnitude{defNum,1}(1,i);
                           mainFrequency(newPos(i,1),:) = elementDefStruct{1,strNum}.(validatorType).mainFrequency{defNum,1}(1,i);
                           mainProminence(newPos(i,1),:) = elementDefStruct{1,strNum}.(validatorType).mainProminence{defNum,1}(1,i);
                           mainLogProminence(newPos(i,1),:) = elementDefStruct{1,strNum}.(validatorType).mainLogProminence{defNum,1}(1,i);
                           mainWeight(newPos(i,1),:) = elementDefStruct{1,strNum}.(validatorType).mainWeight{defNum,1}(1,i);
                        end
                    end
                    
					% fill struct with full-size vectors of defect frequencies,
					% magnitudes & their names for further schemeValidator work
					myValidStruct(k).mainFrequency = mainFrequency;
					myValidStruct(k).mainFrequencyName = mainFrequencyName;
					myValidStruct(k).mainFrequencyTag = mainFrequencyTag;
					myValidStruct(k).mainMagnitude = mainMagnitude;
					myValidStruct(k).mainProminence = mainProminence;
					myValidStruct(k).mainLogProminence = mainLogProminence;
					myValidStruct(k).mainWeight = mainWeight;
					clearvars tempVector newPos;
					
					% Fill baseStruct with additional content
					additionalFrequencyName = cell(maxLength,1);
					additionalFrequencyTag = additionalFrequencyName;
					additionalMagnitude = zeros(maxLength, 1, 'single');
					additionalFrequency = additionalMagnitude;
					additionalProminence = additionalMagnitude;
					additionalLogProminence = additionalMagnitude;
					additionalWeight = additionalMagnitude;
					if ~isempty(elementDefStruct{1,strNum}.(validatorType).additionalFrequency{defNum,1}) && elementDefStruct{1,strNum}.enable
						tempVector(:,1) = single(elementDefStruct{1,strNum}.(validatorType).additionalFrequency{defNum,1});
						newPos = zeros(size(tempVector));
                        memoryForRepeatedFrequency = 0;
                        numberRepeated = 0;
						for i=1:1:length(tempVector(:,1))
                           % Processing for repeated additional frequency
                           numberRepeatedCurrent = nnz(tempVector(i,1) == tempVector);
                           if numberRepeatedCurrent > 1
                               if length(memoryForRepeatedFrequency) == 1
                                   posElement = find(peakTable.(validatorType)(:,1)==tempVector(i,1))+numberRepeated;
                                   
                                   memoryForRepeatedFrequency = posElement:1:posElement+numberRepeatedCurrent-1;
                                   newPos(i,:) = posElement;
                                   numberRepeated = numberRepeatedCurrent+numberRepeated-1;
                                   indexMemoryPos = 1;
                               else   
                                   indexMemoryPos = 1+indexMemoryPos;
                                   if indexMemoryPos > length(memoryForRepeatedFrequency)
                                       posElement = find(peakTable.(validatorType)(:,1)==tempVector(i,1))+numberRepeated;
                                       memoryForRepeatedFrequency = posElement:1:posElement+numberRepeatedCurrent-1;
                                       numberRepeated = numberRepeatedCurrent+numberRepeated-1;
                                       indexMemoryPos = 1;
                                   end
                                   newPos(i,:) = memoryForRepeatedFrequency(indexMemoryPos);
                               end
                           else
                               memoryForRepeatedFrequency = 0;
                               [newPos(i,:)] = find(peakTable.(validatorType)(:,1)==tempVector(i,1))+numberRepeated;
                           end
                           
						   additionalFrequencyName{newPos(i,1),:} = elementDefStruct{1,strNum}.(validatorType).additionalFrequencyName{defNum,1}{1,i};
						   additionalFrequencyTag{newPos(i,1),:} = elementDefStruct{1,strNum}.(validatorType).additionalFrequencyTag{defNum,1}{1,i};
						   additionalMagnitude(newPos(i,1),:) = elementDefStruct{1,strNum}.(validatorType).additionalMagnitude{defNum,1}(1,i);
						   additionalFrequency(newPos(i,1),:) = elementDefStruct{1,strNum}.(validatorType).additionalFrequency{defNum,1}(1,i);
						   additionalProminence(newPos(i,1),:) = elementDefStruct{1,strNum}.(validatorType).additionalProminence{defNum,1}(1,i);
						   additionalLogProminence(newPos(i,1),:) = elementDefStruct{1,strNum}.(validatorType).additionalLogProminence{defNum,1}(1,i);
						   additionalWeight(newPos(i,1),:) = elementDefStruct{1,strNum}.(validatorType).additionalWeight{defNum,1}(1,i);
						end
					end
					% fill struct with full-size vectors of defect frequencies,
					% magnitudes & their names for further schemeValidator work
					myValidStruct(k).additionalFrequency = additionalFrequency;
					myValidStruct(k).additionalFrequencyName = additionalFrequencyName;
					myValidStruct(k).additionalFrequencyTag = additionalFrequencyTag;
					myValidStruct(k).additionalMagnitude = additionalMagnitude;
					myValidStruct(k).additionalProminence = additionalProminence;
					myValidStruct(k).additionalLogProminence = additionalLogProminence;
					myValidStruct(k).additionalWeight = additionalWeight;
					clearvars tempVector newPos;
                end
            end
            
        end
        
        % CREATESUBTABLES function separates original validTable to several
        % subtables of features serial number, features tags and 
        function [myValidator] = createSubTables(myValidator,myValidTagTable,myValidNameTable)
            
            [rowNum, colNum] = size(myValidTagTable);
            
            rowNum = int16(rowNum);
            colNum = int16(colNum);
            
            myNumTable = zeros(rowNum,colNum, 'int16');
            myTagTable = cell(rowNum,colNum);
            myNameTableMod = myTagTable;
            for i=1:1:rowNum  
                for j=1:1:colNum
                    if ~isempty(myValidTagTable{i, j})
                        
                        if isempty(strfind(myValidTagTable{i, j},'_'))
                            
                            [numStr,tagStr] = strtok(myValidTagTable{i, j}, '*');
                            tagStr = tagStr(1, 2:end);
                            myNumTable(i, j) = str2double(numStr); % fill table with number of harmonics
                            myTagTable{i, j} = int16(str2double(tagStr)); % fill table with tags of defect frequencies
                        else
                            % get first & second part of the tag string
                            % (ex. '5*2_1*2' --> numTable(i,j)=5;
                            % tagTable{i,j}={1,2}
                            [str1, str2] = strtok(myValidTagTable{i, j}, '_');
                            str2 = str2(1, 2:end);
                            [numStr1,tagStr1] = strtok(str1, '*');
                            tagStr1 = tagStr1(1,2:end);
                            [~,tagStr2] = strtok(str2, '*');
                            tagStr2 = tagStr2(1,2:end);
                            myNumTable(i,j) = str2double(numStr1);                       % fill table with number of harmonics
                            myTagTable{i,j} = int16([str2double(tagStr1) str2double(tagStr2)]);  % fill table with tags of defect frequencies
                            myNameTableMod{i,j} = myValidNameTable{i,j};
                        end
                    end
                end
            end
            
            myValidator.numTable = myNumTable;
            myValidator.tagTable = myTagTable;
            myValidator.nameTableMod = myNameTableMod;
        end
        
        % ADDVALIDDATA2VALIDSTRUCT function fills valid structure with new
        % validated data
        function [ myValidStruct ] = addValidData2ValidStruct(myValidator)
            
            myTagTable = myValidator.tagTable;
            myNumTable = myValidator.numTable;
            myMaskTable = myValidator.maskTable;
            
            myValidStruct = myValidator.validStruct;
            fieldsNumber = length(myValidStruct);
            
            % Add main frequencies, magnitudes, tags and etc. "Main" means
            % that it consists of 2 types of data: 1) which attached to
            % defect to check the similarity to the defect pattern and 2)
            % which is used to check the difference with the pattern
            for i = 1:1:fieldsNumber
                [x,~] = find(myMaskTable(:,i));
                myValidStruct(i).mainFrequencyValid = zeros(length(x), 1, 'single');
                myValidStruct(i).mainMagnitudeValid = myValidStruct(i).mainFrequencyValid;
                myValidStruct(i).mainProminenceValid = myValidStruct(i).mainFrequencyValid;
                myValidStruct(i).mainLogProminenceValid = myValidStruct(i).mainFrequencyValid;
                myValidStruct(i).mainFrequencyNameValid = cell(length(x), 1);
                myValidStruct(i).mainFrequencyTagValid = cell(length(x), 1);
                myValidStruct(i).mainFrequencyTagNumberValid = myValidStruct(i).mainFrequencyValid;
                myValidStruct(i).mainFrequencyTagNameValid = cell(length(x), 1);
                myValidStruct(i).mainWeightValid = myValidStruct(i).mainFrequencyValid;
                for j = 1:1:length(x)
                    myValidStruct(i).mainFrequencyValid(j,1) = myValidStruct(i).mainFrequency(x(j),1);
                    myValidStruct(i).mainMagnitudeValid(j,1) = myValidStruct(i).mainMagnitude(x(j),1);
                    myValidStruct(i).mainProminenceValid(j,1) = myValidStruct(i).mainProminence(x(j),1);
                    myValidStruct(i).mainLogProminenceValid(j,1) = myValidStruct(i).mainLogProminence(x(j),1);
                    myValidStruct(i).mainFrequencyNameValid(j,1) = myValidStruct(i).mainFrequencyName(x(j),1);
                    myValidStruct(i).mainFrequencyTagValid(j,1) = myValidStruct(i).mainFrequencyTag(x(j),1);
                    myValidStruct(i).mainFrequencyTagNumberValid(j,1) = myNumTable(x(j),i);
                    myValidStruct(i).mainFrequencyTagNameValid{j,1} = myTagTable(x(j),i);
                    myValidStruct(i).mainWeightValid(j,1) = myValidStruct(i).mainWeight(x(j),1);
                end
                
                % Add addditional frequencies, magnitudes, tags and etc. 
                % "Additional" means that it consists only of data, which 
                % attached to defect for checking similarity to the defect 
                % pattern.
                myValidStruct(i).additionalFrequencyName(find(...
                    cellfun(@isempty, myValidStruct(i).additionalFrequencyName))) = {''}; 
                AI = ismember(myValidStruct(i).additionalFrequencyName,...
                    myValidStruct(i).mainFrequencyNameValid);
                myValidStruct(i).additionalFrequencyValid = myValidStruct(i).additionalFrequency(AI);
                myValidStruct(i).additionalMagnitudeValid = myValidStruct(i).additionalMagnitude(AI);
                myValidStruct(i).additionalProminenceValid = myValidStruct(i).additionalProminence(AI);
                myValidStruct(i).additionalFrequencyNameValid = myValidStruct(i).additionalFrequencyName(AI);
                myValidStruct(i).additionalFrequencyTagValid = myValidStruct(i).additionalFrequencyTag(AI);
                myValidStruct(i).additionalWeightValid = myValidStruct(i).additionalWeight(AI);
            end
        end
        
        % All this functions need to be reviewed !!!!....
        [ minValue, minPosition, distance] = findMinAndCompare(numTable,rowNum,colNum);
        [ isModFlag, carrierTag, modulationTag ] = isModulationTag( myTag, myName );
        [ isModulationFlag ] = isTrueModulation( tagColumn,numColumn,nameColum,currentRow );
        [ myNumber ] = modulationTagsNumber( tagColumn,numColumn,currentRow );
        [ number, positions ] = numOfTags( tagColumn, currentRow, comparisonMode);
        [ result ] = numOfTagsAfterCurrent( tagColumn, currentRow );
        [ result ] = numOfTagsBeforeCurrent( tagColumn, currentRow );
        [ distToLatestTruePos, distToLatestPotPos, distAfter ] = tagDistance( numColumn, positions, currentRow, maskColumn);
        [ result ] = tagLocation( tagColumn, currentRow );
        
        function myValidator = createEmptyValidator(myValidator, myPeakTable)
            myValidator.filledPeakTable = myPeakTable;
            myValidator.validStruct = [];
            myValidator.numTable = [];
            myValidator.tagTable = [];
            myValidator.nameTableMod = [];
            myValidator.freqTableRelevantPeakTable = [];
        end
        
        % ADDCOLUMN function add the column into peakTable for frequencyCorrection
        function filledColumn = addColumn(myValidator)
            
            [~,row] = size(myValidator.maskTable);
            [colum,~] = size(myValidator.filledPeakTable);
            
            
            maskTableWithPeakTable = zeros(colum,row);
            for i=1:1:row
                tempMask = myValidator.freqTableRelevantPeakTable(:,i)>0;
                vectorRelevant = myValidator.freqTableRelevantPeakTable(tempMask,i);
                vectorTrueMask = myValidator.maskTable(tempMask,i);
                for k = 1:1:length(vectorRelevant)
                    repeatedCurrent = vectorRelevant(k,1) == vectorRelevant;
                    if nnz(repeatedCurrent) > 1
                        maskTableWithPeakTable(vectorRelevant(k),i) = ...
                            max(vectorTrueMask(repeatedCurrent));
                        k = k+nnz(repeatedCurrent)-1;
                    else
                        maskTableWithPeakTable(vectorRelevant(k),i) = vectorTrueMask(k); 
                    end
                end
            end
            filledColumn = sum(maskTableWithPeakTable,2);
            filledColumn(filledColumn>=0.8)=1;
            
        end
    end
    
    methods (Access = public, Abstract = true)
        
        [ myValidator ] = validationProcessing(myValidator);
        
    end
    
    methods (Access = protected, Abstract = true)
       
    % All this functions need to be reviewed !!!!....
  
        [ validTagTable,validNumTable, maskTable ] = postValidation( tagTable, numTable, maskTable, priorityColumn, fuzzyContainer );
        [ validTagTable,validNumTable, maskTable ] = preValidation( myValidator, fuzzyContainer);
    end
    
    methods (Access = protected, Static = true, Abstract = true)
        
        [ container ] = createPreValidationContainer(config);
        [ container ] = createPostValidationContainer(config); 
        
    end
    
    methods (Static)
        % GETMAXRANGEWHITHREPEATED the function is determined the max 
        % range of validTabel of the domain with repeated elements
        function [ maxLength ] = getMaxRangeWhithRepeated(statusStruct,peakTable,myValidStruct,validatorType)
            
            validStructLength = int16(length(myValidStruct));
            vectorLengthMain = zeros(validStructLength, 1, 'int16');
            vectorLengthAdditional = zeros(validStructLength, 1, 'int16');
            peakTableLength = int16(length(peakTable.(validatorType)(:,1)));
            for k=1:1:validStructLength
                
                [~,defNum] = strtok(myValidStruct(k).defectId, '_');
                defNum = str2double(defNum(2:end));            
                
                elementDefStruct = statusStruct.([myValidStruct(k).elementType,'Defects']).(myValidStruct(k).elementType);
                
                strNum = 0;
                for s = 1:1:numel(elementDefStruct)
                   if strcmp(elementDefStruct{1,s}.name,myValidStruct(k).name)
                       strNum = s;
                       break
                   end
                end
                if ~nnz(strNum)
                   printWarning(myValidator.iLoger, 'There no such element in the status struct!'); 
                end
                
                % Processing for main frequencies
                frequenciesVectorMain = single(elementDefStruct{1,strNum}.(validatorType).mainFrequency{defNum,1});
                if isempty(frequenciesVectorMain)
                    vectorLengthMain(k) = peakTableLength;
                elseif isnan(frequenciesVectorMain)
                    vectorLengthMain(k) = peakTableLength;
                else
                    %Find repeated elements
                    [n, bin] = histc(frequenciesVectorMain, unique(frequenciesVectorMain));
                    numberRepeatedElements  = nnz(ismember(bin, find(n > 1)));
                    
                    vectorLengthMain(k) = peakTableLength + numberRepeatedElements;
                end
                
                % Processing for additional frequencies
                frequenciesVectorAdditional = elementDefStruct{1,strNum}.(validatorType).additionalFrequency{defNum,1};
                if isempty(frequenciesVectorAdditional)
                    vectorLengthAdditional(k) = peakTableLength;
                elseif isnan(frequenciesVectorAdditional)
                    vectorLengthAdditional(k) = peakTableLength;
                else
                    %Find repeated elements
                    [n, bin] = histc(frequenciesVectorAdditional, unique(frequenciesVectorAdditional));
                    numberRepeatedElements  = nnz(ismember(bin, find(n > 1)));
                    
                    vectorLengthAdditional(k) = peakTableLength + numberRepeatedElements;
                end
            end
            maxLength = max([vectorLengthMain' vectorLengthAdditional']);
        end
        
        function [emptyValidatorTable] = createEmptyValitadotTable(numberElement)
            
            emptyValidatorTable(numberElement).elementType = [];
            emptyValidatorTable(numberElement).class = [];
            emptyValidatorTable(numberElement).name = [];
            emptyValidatorTable(numberElement).basicFreqs = [];
            emptyValidatorTable(numberElement).defectName = [];
            emptyValidatorTable(numberElement).defectTagName = [];
            emptyValidatorTable(numberElement).defectId = [];
            emptyValidatorTable(numberElement).defFuncName = [];
            
        end
        
    end
end