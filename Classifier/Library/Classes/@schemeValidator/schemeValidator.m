classdef schemeValidator
    %SCHEMEVALIDATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        
        % INPUT:
        Config
        initialPeakTable
        
        % OUTPUT
        displacementValidator
        velocityValidator
        accelerationValidator
        envelopeValidator
        
        validStruct     % 
        filledPeakTable %
        nonValidPeaksNumbers
    end
    
    methods (Access = public)
        % Constructor fucntion 
        function [myValidator] = schemeValidator(statusStruct, peakTable, mainFreqStruct, informativeTagsStruct, myConfig)
            
            peakTable = schemeValidator.peakTableToSingle(peakTable, myConfig.frequencyRefinement);
            
            myValidator.Config = myConfig;
            myValidator.initialPeakTable = peakTable;
            
            [peakTable, statusStruct] = deletePeakWithCutoffLevel(myValidator, peakTable, statusStruct);
            
            % To check needing add lineFreq tag to peakTable
            [peakTable] = myValidator.checkAddLineFreq(statusStruct, peakTable, mainFreqStruct, myConfig);
            
            if ~myConfig.frequencyRefinement
                myValidator.displacementValidator = dispSpecValidator(statusStruct, peakTable, mainFreqStruct, informativeTagsStruct, myConfig);
                myValidator.velocityValidator = velSpecValidator(statusStruct, peakTable, mainFreqStruct, informativeTagsStruct, myConfig);

                myValidator.accelerationValidator = accSpecValidator(statusStruct, peakTable, mainFreqStruct, informativeTagsStruct, myConfig);
            end
            
            myValidator.envelopeValidator = accEnvSpecValidator(statusStruct, peakTable, mainFreqStruct, informativeTagsStruct, myConfig);
            
            [myValidator] = createValidStruct(myValidator);
            
            if ~myConfig.frequencyRefinement
                [myValidator] = fillStructPeriodicityAndMetrics(myValidator, statusStruct);
                % Set unidentified peaks numbers
                myValidator.nonValidPeaksNumbers.acceleration = myValidator.accelerationValidator.nonValidPeaksNumbers;
                myValidator.nonValidPeaksNumbers.envelopeAcceleration = myValidator.envelopeValidator.nonValidPeaksNumbers;
                myValidator.nonValidPeaksNumbers.velocity = myValidator.velocityValidator.nonValidPeaksNumbers;
                myValidator.nonValidPeaksNumbers.displacement = myValidator.displacementValidator.nonValidPeaksNumbers;
            end
            
        end
        
        % Getters / Setters ...
        
        function [myConfig] = getConfig(myValidator)
           myConfig= myValidator.Config; 
        end
        function [myValidator] = setConfig(myValidator, myConfig)
            myValidator.Config = myConfig;
        end
        
        function [myValidStruct] = getValidStruct(myValidator)
           myValidStruct= myValidator.validStruct; 
        end
        function [myValidator] = setValidStruct(myValidator, myValidStruct)
            myValidator.validStruct = myValidStruct;
        end
        
        function [myFilledPeakTable] = getFilledPeakTable(myValidator)
           myFilledPeakTable= myValidator.filledPeakTable; 
        end
        function [myValidator] = setFilledPeakTable(myValidator, myFilledPeakTable)
            myValidator.filledPeakTable = myFilledPeakTable;
        end
        
        function myNonValidPeaksNumbers = getNonValidPeaksNumbers(myValidator)
            myNonValidPeaksNumbers = myValidator.nonValidPeaksNumbers;
        end
        
        function [myInitialPeakTable] = getInitialPeakTable(myValidator)
           myInitialPeakTable = myValidator.initialPeakTable; 
        end
        function [myValidator] = setInitialPeakTable(myValidator, myInitialPeakTable)
            myValidator.initialPeakTable = myInitialPeakTable;
        end
        % ... Getters / Setters
        
        % VALIDATIONPROCESSING function ... 
        function [myValidator] = validationProcessing(myValidator)
            
            if ~myValidator.Config.frequencyRefinement
                % Displacement Spectrum Features Validation
                myValidator.displacementValidator = validationProcessing(myValidator.displacementValidator);

                % Velocity Spectrum Features Validation
                myValidator.velocityValidator = validationProcessing(myValidator.velocityValidator);

                % Acceleration Spectrum Features Validation
                myValidator.accelerationValidator = validationProcessing(myValidator.accelerationValidator);
            end
            
            % Acceleration Envelope Spectrum Features Validation
            myValidator.envelopeValidator = validationProcessing(myValidator.envelopeValidator);
        end

    end
    
    methods (Access = private)
        
        function [myValidator] = createValidStruct(myValidator)
            
            [myValidator] = validationProcessing(myValidator);
            
            % Here shold be crossValidation function ... 
            %                ....
            % ... Here shold be crossValidation function
            
            % Get valid structure
            if ~myValidator.Config.frequencyRefinement
                
                myValidStruct.displacementSpectrum = getValidStruct(myValidator.displacementValidator);
                myValidStruct.velocitySpectrum = getValidStruct(myValidator.velocityValidator);
                myValidStruct.accelerationSpectrum = getValidStruct(myValidator.accelerationValidator);
            end 
            
            myValidStruct.accelerationEnvelopeSpectrum = getValidStruct(myValidator.envelopeValidator);
            
            % Reshape valid structure
            myValidStruct = reshapeValidStruct(myValidator, myValidStruct);

            myValidator.validStruct = myValidStruct;
            
            myValidator.filledPeakTable = getFilledPeakTable(myValidator.envelopeValidator);
            
        end
        
        function [newValidStruct] = reshapeValidStruct(myValidator, myValidStruct)
            
            % Get space names
            spaceNames = fieldnames(myValidStruct);
            
            trueSpaceIndex = cellfun(@(spaceName) ~isempty(myValidStruct.(spaceName)), spaceNames);
            spaceNames = spaceNames(trueSpaceIndex);
            % Get element names in each space
            elementNames = cellfun(@(spaceName) {myValidStruct.(spaceName).name}, spaceNames, 'UniformOutput', false);
            % Get unique element names
            uniqueElements = unique([elementNames{1 : end}], 'stable');
            % Checking for unique elements in the valid structure, cutting
            % corresponding to them parts of the valid structure
            newValidStruct = [];
            for elementNumber = 1 : 1 : length(uniqueElements)
                % Create structures for each element
                myElementStruct = [];
                for spaceNumber = 1 : 1 : length(spaceNames)
                    currentSpaceName = spaceNames{spaceNumber};
                    currentElementNames = {myValidStruct.(currentSpaceName).name};
                    % Find the checking element in the current space
                    uniqueElementIndex = ismember(currentElementNames, uniqueElements(elementNumber));
                    myElementStruct.(currentSpaceName) = myValidStruct.(currentSpaceName)(uniqueElementIndex);
                end
                % Reshape each element structure
                newElementStruct = reshapeElementStruct(myValidator, myElementStruct);
                % Add reshaped element structure
                newValidStruct = [newValidStruct newElementStruct];
            end
        end
        
        function [newElementStruct] = reshapeElementStruct(myValidator, myElementStruct)
            
            % Get space names
            spaceNames = fieldnames(myElementStruct);
            % Get defect tag names in each space
            defectTagNames = cellfun(@(spaceName) {myElementStruct.(spaceName).defectTagName}, spaceNames, 'UniformOutput', false);
            % Get unique defect names
            uniqueDefects = unique([defectTagNames{1 : end}], 'stable');
            % Checking for unique defects in the element structure, cutting
            % corresponding to them parts of the element structure
            for defectNumber = 1 : 1 : length(uniqueDefects)
                currentDefectName = uniqueDefects{defectNumber};
                
                % Find the current defect in each space
                defectIndex = cellfun(@(defectTagName) ismember(defectTagName, currentDefectName), defectTagNames, 'UniformOutput', false);
                % Find spaces with the current defect
                defectSpaceIndex = find(cellfun(@nnz, defectIndex));
                % Get space names with the current defect
                defectSpaceNames = spaceNames(defectSpaceIndex);
                % Get defect index in the first space containing the defect
                inFirstSpaceDefectIndex = find(defectIndex{defectSpaceIndex(1)});
                
                % Fill common fields
                newElementStruct(defectNumber).elementType = myElementStruct.(defectSpaceNames{1})(inFirstSpaceDefectIndex).elementType;
                newElementStruct(defectNumber).class = myElementStruct.(defectSpaceNames{1})(inFirstSpaceDefectIndex).class;
                newElementStruct(defectNumber).name = myElementStruct.(defectSpaceNames{1})(inFirstSpaceDefectIndex).name;
                newElementStruct(defectNumber).basicFreqs = myElementStruct.(defectSpaceNames{1})(inFirstSpaceDefectIndex).basicFreqs;
                newElementStruct(defectNumber).defectName = myElementStruct.(defectSpaceNames{1})(inFirstSpaceDefectIndex).defectName;
                newElementStruct(defectNumber).defectTagName = myElementStruct.(defectSpaceNames{1})(inFirstSpaceDefectIndex).defectTagName;
                newElementStruct(defectNumber).defectId = myElementStruct.(defectSpaceNames{1})(inFirstSpaceDefectIndex).defectId;
                newElementStruct(defectNumber).defFuncName = myElementStruct.(defectSpaceNames{1})(inFirstSpaceDefectIndex).defFuncName;
                newElementStruct(defectNumber).id = myElementStruct.(defectSpaceNames{1})(inFirstSpaceDefectIndex).id;
                newElementStruct(defectNumber).baseFreq = myElementStruct.(defectSpaceNames{1})(inFirstSpaceDefectIndex).baseFreq;
                newElementStruct(defectNumber).priority = myElementStruct.(defectSpaceNames{1})(inFirstSpaceDefectIndex).priority;
                newElementStruct(defectNumber).enable = myElementStruct.(defectSpaceNames{1})(inFirstSpaceDefectIndex).enable;
                
                % Fill defect spaces
                for spaceNumber = 1 : 1 : length(spaceNames)
                    currentSpaceName = spaceNames{spaceNumber};
                    
                    if ~ismember(currentSpaceName, defectSpaceNames)
                        % Create empty defect space
                        newElementStruct(defectNumber).(currentSpaceName) = [];
                    else
                        % Get index of the defect in the current space
                        inSpaceDefectIndex = (find(defectIndex{spaceNumber}));
                        % Fill main tags
                        newElementStruct(defectNumber).(currentSpaceName).mainFrequency = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).mainFrequency;
                        newElementStruct(defectNumber).(currentSpaceName).mainFrequencyName = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).mainFrequencyName;
                        newElementStruct(defectNumber).(currentSpaceName).mainFrequencyTag = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).mainFrequencyTag;
                        newElementStruct(defectNumber).(currentSpaceName).mainMagnitude = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).mainMagnitude;
                        newElementStruct(defectNumber).(currentSpaceName).mainProminence = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).mainProminence;
                        newElementStruct(defectNumber).(currentSpaceName).mainLogProminence = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).mainLogProminence;
                        newElementStruct(defectNumber).(currentSpaceName).mainWeight = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).mainWeight;
                        % Fill additional tags
                        newElementStruct(defectNumber).(currentSpaceName).additionalFrequency = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).additionalFrequency;
                        newElementStruct(defectNumber).(currentSpaceName).additionalFrequencyName = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).additionalFrequencyName;
                        newElementStruct(defectNumber).(currentSpaceName).additionalFrequencyTag = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).additionalFrequencyTag;
                        newElementStruct(defectNumber).(currentSpaceName).additionalMagnitude = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).additionalMagnitude;
                        newElementStruct(defectNumber).(currentSpaceName).additionalProminence = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).additionalProminence;
                        newElementStruct(defectNumber).(currentSpaceName).additionalLogProminence = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).additionalLogProminence;
                        newElementStruct(defectNumber).(currentSpaceName).additionalWeight = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).additionalWeight;
                        % Fill main valid tags
                        newElementStruct(defectNumber).(currentSpaceName).mainFrequencyValid = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).mainFrequencyValid;
                        newElementStruct(defectNumber).(currentSpaceName).mainFrequencyNameValid = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).mainFrequencyNameValid;
                        newElementStruct(defectNumber).(currentSpaceName).mainFrequencyTagValid = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).mainFrequencyTagValid;
                        newElementStruct(defectNumber).(currentSpaceName).mainFrequencyTagNumberValid = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).mainFrequencyTagNumberValid;
                        newElementStruct(defectNumber).(currentSpaceName).mainFrequencyTagNameValid = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).mainFrequencyTagNameValid;
                        newElementStruct(defectNumber).(currentSpaceName).mainMagnitudeValid = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).mainMagnitudeValid;
                        newElementStruct(defectNumber).(currentSpaceName).mainProminenceValid = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).mainProminenceValid;
                        newElementStruct(defectNumber).(currentSpaceName).mainLogProminenceValid = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).mainLogProminenceValid;
                        newElementStruct(defectNumber).(currentSpaceName).mainWeightValid = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).mainWeightValid;
                        % Fill additional valid tags
                        newElementStruct(defectNumber).(currentSpaceName).additionalFrequencyValid = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).additionalFrequencyValid;
                        newElementStruct(defectNumber).(currentSpaceName).additionalFrequencyNameValid = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).additionalFrequencyNameValid;
                        newElementStruct(defectNumber).(currentSpaceName).additionalFrequencyTagValid = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).additionalFrequencyTagValid;
                        newElementStruct(defectNumber).(currentSpaceName).additionalMagnitudeValid = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).additionalMagnitudeValid;
                        newElementStruct(defectNumber).(currentSpaceName).additionalProminenceValid = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).additionalProminenceValid;
                        newElementStruct(defectNumber).(currentSpaceName).additionalWeightValid = myElementStruct.(currentSpaceName)(inSpaceDefectIndex).additionalWeightValid;
                    end
                end
            end
        end
        
        % DELETEPEAKWITHCUTOFFLEVEL function deleting frequency less
        % of parameter in config (validLogLevel) form PEAKTABLE
        function [peakTable, statusStruct] = deletePeakWithCutoffLevel(myValidator, peakTable, statusStruct)
            
            % Delete frequency from peakTable
            validLogLevel = str2double(myValidator.Config.validLogLevel);
            
            if ~isempty(peakTable.accelerationEnvelopeSpectrum)
                peakTable.accelerationEnvelopeSpectrum = ...
                    peakTable.accelerationEnvelopeSpectrum(peakTable.accelerationEnvelopeSpectrum(:,4) > validLogLevel,:);
            end
            
            if ~isempty(peakTable.accelerationSpectrum)
                peakTable.accelerationSpectrum = ...
                    peakTable.accelerationSpectrum(peakTable.accelerationSpectrum(:,4) > validLogLevel,:);
            end
            
            if ~isempty(peakTable.velocitySpectrum)
                peakTable.velocitySpectrum = ...
                    peakTable.velocitySpectrum(peakTable.velocitySpectrum(:,4) > validLogLevel,:);
            end
            
            if ~isempty(peakTable.displacementSpectrum)
                peakTable.displacementSpectrum = ...
                    peakTable.displacementSpectrum(peakTable.displacementSpectrum(:,4) > validLogLevel,:);
            end
            
            % Delete frequency from statusStruct
            nameAllFields = fieldnames(peakTable);
            nameFieldsNonEmpty = nameAllFields(cellfun(@(x) ~isempty(peakTable.(x)), nameAllFields));
            numberNonEmptyFields = length(nameFieldsNonEmpty);
            
			nameFieldsEmpty = nameAllFields(cellfun(@(x) isempty(peakTable.(x)), nameAllFields));
            numberEmptyFields = length(nameFieldsEmpty);
			
            nameListElements = fieldnames(statusStruct);
            
            if ~myValidator.Config.frequencyRefinement
                for i = 1:1:length(nameListElements)
                    structureElements = statusStruct.(nameListElements{i});
                    tempNameList = fieldnames(structureElements);
                    structureElements = structureElements.(tempNameList{1});

                    for j = 1:1:length(structureElements)
                        for k = 1:1:numberNonEmptyFields
                            structureElements{j}.(nameFieldsNonEmpty{k}) = ...
                                myValidator.deleteFrequencyInDomain(structureElements{j}.(nameFieldsNonEmpty{k}), validLogLevel);
                        end

                        for k = 1:1:numberEmptyFields
                            structureElements{j}.(nameFieldsEmpty{k}) = ...
                                myValidator.deleteFrequencyInDomainEmpty(structureElements{j}.(nameFieldsEmpty{k}));
                        end
                    end
                    statusStruct.(nameListElements{i}).(tempNameList{1}) = structureElements;
                end
            else
                
                for i = 1:1:length(nameListElements)
                    structureElements = statusStruct.(nameListElements{i});
                    tempNameList = fieldnames(structureElements);
                    structureElements = structureElements.(tempNameList{1});

                    for j = 1:1:length(structureElements)
                        for k = 1:1:numberNonEmptyFields
                            structureElements{j}.(nameFieldsNonEmpty{k}) = ...
                                myValidator.deleteFrequencyInDomain(structureElements{j}.(nameFieldsNonEmpty{k}), validLogLevel);
                        end
                    end
                    statusStruct.(nameListElements{i}).(tempNameList{1}) = structureElements;
                end
            end

        end
        
        % FILLSTRUCTPeriodicityANDMETRICS function filling validStruct with time
        % domain and metrics
        function [myValidator] = fillStructPeriodicityAndMetrics(myValidator, statusStruct)
            myValidStruct = getValidStruct(myValidator);
            namesElementValidStruct = {myValidStruct.name};
            defectsValidStruct = {myValidStruct.defectName};
            nameListElements = fieldnames(statusStruct);
            for i = 1:1:length(nameListElements)
                structureElements = statusStruct.(nameListElements{i});
                tempNameList = fieldnames(structureElements);
                structureElements = structureElements.(tempNameList{1});
                for j = 1:1:length(structureElements)
                    nameElement = structureElements{j}.name;
                    trueVectorNames = ismember(namesElementValidStruct, nameElement);
                    for k = 1:1:length(structureElements{j}.statusName)
                        defectName = structureElements{j}.statusName{k};
                        trueVectorDefects = ismember(defectsValidStruct, defectName);
                        positionInValidStruct = ...
                            find(bsxfun(@times,trueVectorDefects,trueVectorNames));
                        
                        myValidStruct(positionInValidStruct).periodicity.mainFrequency = ...
                            structureElements{j}.periodicity.mainFrequency{k,:};
                        myValidStruct(positionInValidStruct).periodicity.mainMagnitude = ...
                            structureElements{j}.periodicity.mainMagnitude{k,:};
                        myValidStruct(positionInValidStruct).periodicity.mainFrequencyName = ...
                            structureElements{j}.periodicity.mainFrequencyName{k,:};
                        myValidStruct(positionInValidStruct).periodicity.mainFrequencyTag = ...
                            structureElements{j}.periodicity.mainFrequencyTag{k,:};
                        myValidStruct(positionInValidStruct).periodicity.mainProminence = ...
                            structureElements{j}.periodicity.mainProminence{k,:};
                        myValidStruct(positionInValidStruct).periodicity.mainLogProminence = ...
                            structureElements{j}.periodicity.mainLogProminence{k,:};
                        myValidStruct(positionInValidStruct).periodicity.mainWeight = ...
                            structureElements{j}.periodicity.mainWeight{k,:};
                        
                        myValidStruct(positionInValidStruct).metrics = ...
                            structureElements{j}.metrics{k,:};
                    end
                end
            end
            myValidator = setValidStruct(myValidator, myValidStruct);
        end
    end
    
    methods(Static)
        
        % DELETEFREQUENCYINDOMAIN function deleting frequency less
        % of parameter in config (validLogLevel) form DOMAIN
        function [domain] = deleteFrequencyInDomain(domain, validLogLevel)
            nameList = fieldnames(domain);
            for i = 1:1:length(domain.mainLogProminence(:,1))
                % Main fields
                if isnan(domain.mainLogProminence{i})
                    truePos = 1;
                else
                    truePos = domain.mainLogProminence{i} > validLogLevel;
                end
                for j = 1:1:7
                    domain.(nameList{j}){i} = domain.(nameList{j}){i}(truePos);
                end
                
                % Additional fields
                if isnan(domain.additionalLogProminence{i})
                    truePos = 1;
                else
                    truePos = domain.additionalLogProminence{i} > validLogLevel;
                end
                for j = 8:1:14
                    domain.(nameList{j}){i} = domain.(nameList{j}){i}(truePos);
                end
            end
        end
        
        % DELETEFREQUENCYINDOMAINEMPTY function deleting frequency if
        % peakTable is empty
        function [domain] = deleteFrequencyInDomainEmpty(domain)
            nameList = fieldnames(domain);
            for i = 1:1:length(domain.mainLogProminence(:,1))
                % Main fields
                if isnan(domain.mainLogProminence{i})
                    truePos = 1;
                else
                    truePos = 0;
                end
                for j = 1:1:7
                    domain.(nameList{j}){i} = domain.(nameList{j}){i}(logical(truePos));
                end
                
                % Additional fields
                if isnan(domain.additionalLogProminence{i})
                    truePos = 1;
                else
                    truePos = 0;
                end
                for j = 8:1:14
                    domain.(nameList{j}){i} = domain.(nameList{j}){i}(logical(truePos));
                end	
            end
        end
        
        % CHECKADDLINEFREQ function check in motor element enabling and add
        % lineFreq tag to peakTable
        function [peakTable] = checkAddLineFreq(statusStruct, peakTable, mainFreqStruct, myConfig)
            
            if ~myConfig.frequencyRefinement
                if str2double(myConfig.enableFindLineFreq)
                    peakTable.accelerationSpectrum = schemeValidator.checkLengthPeakTable(peakTable.accelerationSpectrum);
                    peakTable.velocitySpectrum = schemeValidator.checkLengthPeakTable(peakTable.velocitySpectrum);
                    peakTable.displacementSpectrum = schemeValidator.checkLengthPeakTable(peakTable.displacementSpectrum);

                    if isfield(statusStruct, 'motorDefects')

                        numberMotors = length(statusStruct.motorDefects.motor);

                        lineFreq = 0;
                        enableAdding = 0;
                        for i = 1:1:numberMotors
                            if statusStruct.motorDefects.motor{i}.priority && statusStruct.motorDefects.motor{i}.enable
                                positoinLineFreq = strcmpi({mainFreqStruct.element.name}, statusStruct.motorDefects.motor{1, 1}.name);

                                basicFreqs = mainFreqStruct.element(positoinLineFreq).basicFreqs;


                                % To find twiceLineFreq in basicFreqs (tag = 3)
                                lineFreq = basicFreqs{cell2mat(basicFreqs(:, 1)) == 3, 2};
                                enableAdding = 1;
                                break
                            end
                        end

                        if enableAdding 
                            peakTable.accelerationSpectrum = schemeValidator.findLineFrequency(peakTable.accelerationSpectrum, lineFreq, myConfig);
                            peakTable.velocitySpectrum = schemeValidator.findLineFrequency(peakTable.velocitySpectrum, lineFreq, myConfig);
                            peakTable.displacementSpectrum = schemeValidator.findLineFrequency(peakTable.displacementSpectrum, lineFreq, myConfig);
                        end
                    end
                end
            end
        end
        
        % FINDWITHDECREASINGRANGE function find most close frequency in frequencies vector 
        function peakTableOutput = findLineFrequency(peakTable, twiceLineFreq, myConfig)

            peakTableOutput = peakTable;

            positionFree = peakTableOutput(:, 5) == 0;

            % To set parameters from config
            freqRangeTwiceLineFreq = str2num(myConfig.freqRangeTwiceLineFreq);
            harmomicsTwiceLineFreq = cellfun(@(x) str2num(x) * twiceLineFreq, ...
                strsplit(myConfig.harmomicsTwiceLineFreq, ';'), 'UniformOutput', false);

            for i = 1:1:length(freqRangeTwiceLineFreq)
                
                peakTableOutput = schemeValidator.fillPeakTable(harmomicsTwiceLineFreq{i}, peakTableOutput, ...
                                                                freqRangeTwiceLineFreq(i), positionFree);
            end
        end

        % CHECKLENGTHPEAKTABLE function check numbers of colum of peak table and add
        % colum if need
        function peakTableOutput = checkLengthPeakTable(peakTable)
            
            [frequenciesNumbers, columNumbers] = size(peakTable);

            peakTableOutput = peakTable;

            if columNumbers == 4
                peakTableOutput(:, 5) = zeros(frequenciesNumbers, 1);
            end
        end
        
        % FILLPEAKTABLE function find lineFreq(3) tag in narrow range
        function peakTableOutput = fillPeakTable(soughtValue, peakTableOutput, freqRange, positionFree)

            for i = 1:1:length(soughtValue)

                positionEverage = bsxfun(@times, peakTableOutput(:,1) >= soughtValue(i) - freqRange,  ...
                                                 peakTableOutput(:,1) <= soughtValue(i) + freqRange);
                positionEverage = logical(bsxfun(@times, positionEverage, positionFree));

                if nnz(positionEverage)
                    if nnz(positionEverage) == 1
                        peakTableOutput(positionEverage, 5) = 3;
                    else
                        numberPosition = find(positionEverage);
                        resultPositions = ...
                            findWithDecreasingRange(50, peakTableOutput(numberPosition, 1), peakTableOutput(numberPosition, 2));
                        peakTableOutput(numberPosition(resultPositions), 5) = 3;
                    end
                end
            end
        end
        
    end
    
    methods(Static)
        
        function peakTable = peakTableToSingle(peakTable, modeFrequencyRefinement)
            
            peakTable.accelerationEnvelopeSpectrum = single(peakTable.accelerationEnvelopeSpectrum);
            
            if ~modeFrequencyRefinement
                peakTable.accelerationSpectrum = single(peakTable.accelerationSpectrum);
                peakTable.velocitySpectrum = single(peakTable.velocitySpectrum);
                peakTable.displacementSpectrum = single(peakTable.displacementSpectrum);
            else
                peakTable.accelerationSpectrum = single([]);
                peakTable.velocitySpectrum = single([]);
                peakTable.displacementSpectrum = single([]);
            end
        end
        
    end
end

