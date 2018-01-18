classdef classifier

    properties ( Access = protected) 
        classifierStruct         % defFreq and parameters structure
        classifierType

        peakTable
    end
    
    methods (Access = public)

        function myClassifier = classifier(myClassifierStruct,myClassifierType, myPeakTable)

            myClassifier.classifierStruct = myClassifierStruct;
            myClassifier.classifierType = myClassifierType;
            myClassifier.peakTable = myPeakTable;
        end

        s = file2struct(file);

        % GETDEFECTSTATUS function creates a special structure consisting
        % of found 
        function [statusStruct] = getDefectStatus(myClassifier, element, config)

            basicFreqList = getBasicFreqList(element);
            shaftFreq = getShaftFreq(element);
            elementType = getElementType(element);

            if isprop(element,'type')
                type = getType(element);
            else
                type = elementType;
            end

            myClassifierType = [elementType, 'Classifier'];
            defectStruct = myClassifier.classifierStruct.classStruct.(myClassifierType).(type);
            defectsNumber = numel(defectStruct.defect);

%% ________________________ Create empty struct ________________________ %%

            accelerationEnvelopeSpectrum = myClassifier.createEmptyStructFrequencyDomain(defectsNumber);
            
            if ~config.frequencyRefinement
                periodicityStruct = myClassifier.createEmptyStructPeriodicity(defectsNumber);
                accelerationSpectrum = myClassifier.createEmptyStructFrequencyDomain(defectsNumber);
                velocitySpectrum = myClassifier.createEmptyStructFrequencyDomain(defectsNumber);
                displacementSpectrum = myClassifier.createEmptyStructFrequencyDomain(defectsNumber);
                metricsStruct = cell(defectsNumber,1);
            end
            
            defStatusName = cellfun(@(x) x.Attributes.name, defectStruct.defect, 'UniformOutput', false)';
            validDefectID = 1:1:defectsNumber;
            maskEnable = cellfun(@(x) logical(str2double(x.Attributes.enable)), defectStruct.defect)';
            validDefectID = validDefectID(maskEnable);

            validDefectsNumber = numel(validDefectID);

%% _______ Fill struct of frequency domain, time domain, metrics _______ %%

            if ~config.frequencyRefinement
                for i  = 1:1:validDefectsNumber
                
                    % To check, that parameters of element have been inputted
                    % correctly
                    modeDisableDefect = false(5, 1);

                    % Frequency domain          
                    file.peakTable = myClassifier.peakTable.accelerationEnvelopeSpectrum;  
                    [accelerationEnvelopeSpectrum, modeDisableDefect(1)]= createFilledStructure(myClassifier, file, accelerationEnvelopeSpectrum, 'accelerationEnvelopeSpectrum',...
                                                                 i, validDefectID, config, defectStruct, basicFreqList);

                    file.peakTable = myClassifier.peakTable.accelerationSpectrum; 
                    [accelerationSpectrum, modeDisableDefect(2)] = createFilledStructure(myClassifier, file, accelerationSpectrum, 'accelerationSpectrum',...
                                                         i, validDefectID, config, defectStruct, basicFreqList);

                    file.peakTable = myClassifier.peakTable.velocitySpectrum; 
                    [velocitySpectrum, modeDisableDefect(3)] = createFilledStructure(myClassifier, file, velocitySpectrum, 'velocitySpectrum',...
                                                     i, validDefectID, config, defectStruct, basicFreqList);

                    file.peakTable = myClassifier.peakTable.displacementSpectrum; 
                    [displacementSpectrum, modeDisableDefect(4)] = createFilledStructure(myClassifier, file, displacementSpectrum, 'displacementSpectrum',...
                                                         i, validDefectID, config, defectStruct, basicFreqList);

                    % Time domain
                    file.peakTable = myClassifier.peakTable.accelerationEnvelopeSpectrum; 
                    [periodicityStruct, modeDisableDefect(5)] = createFilledStructure(myClassifier,  file, periodicityStruct, 'periodicity', ...
                                                i, validDefectID, config, defectStruct, basicFreqList);

                    % Metrics
                    metricsStruct{i, 1} = struct2defFreq(myClassifier, defectStruct, validDefectID(1,i), basicFreqList, 'metrics');

                    % To disable defect 
                    if any(modeDisableDefect)
                        metricsStruct{i, 1} = [];

                        if ~isnan(periodicityStruct.mainFrequency{i})
                            periodicityStruct = myClassifier.toDoEmptyStruct(periodicityStruct, i);
                        end

                        if ~isnan(accelerationEnvelopeSpectrum.mainFrequency{i})
                            accelerationEnvelopeSpectrum = myClassifier.toDoEmptyStruct(accelerationEnvelopeSpectrum, i);
                        end

                        if ~isnan(accelerationSpectrum.mainFrequency{i})
                            accelerationSpectrum = myClassifier.toDoEmptyStruct(accelerationSpectrum, i);
                        end

                        if ~isnan(velocitySpectrum.mainFrequency{i})
                            velocitySpectrum = myClassifier.toDoEmptyStruct(velocitySpectrum, i);
                        end

                        if ~isnan(displacementSpectrum.mainFrequency{i})
                            displacementSpectrum = myClassifier.toDoEmptyStruct(displacementSpectrum, i);
                        end
                    end
                end
            else
                
                for i  = 1:1:validDefectsNumber
                    
                    % Frequency domain          
                    file.peakTable = myClassifier.peakTable.accelerationEnvelopeSpectrum;  
                    [accelerationEnvelopeSpectrum, modeDisableDefect(1)]= createFilledStructure(myClassifier, file, accelerationEnvelopeSpectrum, 'accelerationEnvelopeSpectrum',...
                                                                 i, validDefectID, config, defectStruct, basicFreqList);
                    % To disable defect 
                    if any(modeDisableDefect)

                        if ~isnan(accelerationEnvelopeSpectrum.mainFrequency{i})
                            accelerationEnvelopeSpectrum = myClassifier.toDoEmptyStruct(accelerationEnvelopeSpectrum, i);
                        end
                    end
                end
                
                accelerationSpectrum = [];
                velocitySpectrum = [];
                displacementSpectrum = [];
                periodicityStruct = [];
                metricsStruct = [];
            end
            
%% ____________________ Create status structure ________________________ %%

            statusStruct.statusName = defStatusName;

            % Frequency-domain parameters
            if ~isempty(accelerationEnvelopeSpectrum)
                statusStruct.accelerationEnvelopeSpectrum = accelerationEnvelopeSpectrum;
            end
            if ~isempty(accelerationSpectrum)
                statusStruct.accelerationSpectrum = accelerationSpectrum;
            end
            if ~isempty(velocitySpectrum)
                statusStruct.velocitySpectrum = velocitySpectrum;
            end
            if ~isempty(displacementSpectrum)
                statusStruct.displacementSpectrum = displacementSpectrum;
            end

            % Time-domain parameters
            if ~isempty(periodicityStruct)
                statusStruct.periodicity = periodicityStruct;
            end

            if ~isempty(metricsStruct)
                % Metrics parameters
                statusStruct.metrics = metricsStruct; 
            end
        end

        function myClassifier = setClassifierType(myClassifier,myClassifierType)
            myClassifier.classifierType = myClassifierType;
        end
        function myClassifierType = getClassifierType(myClassifier)
            myClassifierType = myClassifier.classifierType;
        end

        function myClassifier = setClassifierStruct(myClassifier,myClassifierStruct )
            myClassifier.classifierStruct = myClassifierStruct;
        end
        function myClassifierStruct = getClassifierStruct(myClassifier)
            myClassifierStruct = myClassifier.classifierStruct;
        end

        function myClassifier = sePeakTable(myClassifier,mypeakTable)
            myClassifier.peakTable = mypeakTable;
        end
        function myPeakTable = getPeakTable(myClassifier)
            myPeakTable = myClassifier.peakTable;
        end
    end
    
    methods (Access = private) 
        % STRUCT2DEFFREQ function transforms informativeTags structure to elements
        % defect frequencies in the time\frequency-domain using elemets tagList
        % (list of the main defect frequencies of every element)
        function [ mainParameters, additionalParameters, modeDisableDefect] = struct2defFreq(myClassifier, profileStruct, defectID, tagList, mode)
            if nargin < 4
                mode = 'accelerationEnvelopeSpectrum';
            end
            
            modeDisableDefect = false(1);
            
            switch(mode)
                case 'periodicity'
                    if isfield(profileStruct.defect{1,defectID}, 'periodicity')
                        % Get main/additional frequencies in time_domain
                        data = str2num(profileStruct.defect{1,defectID}.periodicity.data.Attributes.d);
                        tag = str2num(profileStruct.defect{1,defectID}.periodicity.tag.Attributes.t);
                        mod = str2num(profileStruct.defect{1,defectID}.periodicity.mod.Attributes.m);
                        weight = str2num(profileStruct.defect{1,defectID}.periodicity.weight.Attributes.w);
                        % Calculation of the main defect frequencies of the current element
                        [mainParameters, modeDisableDefect] = myClassifier.getDefFreq(data, tag, mod, tagList, weight, modeDisableDefect);
                        additionalParameters = [];
                    else
                        mainParameters = [];additionalParameters = [];
                    end
                case {'accelerationEnvelopeSpectrum', 'accelerationSpectrum', ...
                        'velocitySpectrum', 'displacementSpectrum'}
                    if isfield(profileStruct.defect{1,defectID}, mode)
                        mainData = str2num(profileStruct.defect{1,defectID}.(mode).dataM.Attributes.d);
                        mainTag = str2num(profileStruct.defect{1,defectID}.(mode).tagM.Attributes.t);
                        mainMod = str2num(profileStruct.defect{1,defectID}.(mode).modM.Attributes.m);
                        mainWeight = str2num(profileStruct.defect{1,defectID}.(mode).weightM.Attributes.w);
                        % Calculation of the main defect frequencies of the current element
                        [mainParameters, modeDisableDefect] = myClassifier.getDefFreq(mainData, mainTag, mainMod, tagList, mainWeight, modeDisableDefect);

                        additionalData = str2num(profileStruct.defect{1,defectID}.(mode).dataA.Attributes.d);
                        additionalTag = str2num(profileStruct.defect{1,defectID}.(mode).tagA.Attributes.t);
                        additionalMod = str2num(profileStruct.defect{1,defectID}.(mode).modA.Attributes.m);
                        additionalWeight = str2num(profileStruct.defect{1,defectID}.(mode).weightA.Attributes.w);
                        % Calculation of the additional defect frequencies of the current element
                        [additionalParameters, modeDisableDefect] = myClassifier.getDefFreq(additionalData, additionalTag, additionalMod, tagList, additionalWeight, modeDisableDefect);
                    else
                        mainParameters = []; additionalParameters = [];
                    end
                % Add new metrics parsing function 
                case 'metrics'
                    if isfield(profileStruct.defect{1,defectID}, 'metrics')
                        % Get main metrics parameters
                        mainParameters.name = profileStruct.defect{1,defectID}.metrics.data.Attributes.name;
                        mainParameters.weight = profileStruct.defect{1,defectID}.metrics.data.Attributes.weight;
                    else
                        mainParameters = [];
                    end
                otherwise
                    mainParameters = []; additionalParameters = [];
            end
        end

        function [ fillStructFrequencyDomain, modeDisableDefect ] = createFilledStructure(myClassifier,  file, fillStructFrequencyDomain,...
                                                            mode, defectNumber, validDefectID, parameters, ...
                                                            defectStruct, basicFreqList)
            % Create vector of required frequencies
            [mainStruct, additionalStruct, modeDisableDefect] = struct2defFreq(myClassifier, defectStruct, ...
                    validDefectID(1,defectNumber), basicFreqList, mode);

            flagFillDomain = 1;

%             % Set range for detecting frequency
%             if ~str2double(parameters.freqRange)
%                 parameters.freqRange = num2str((str2double(parameters.percentRange)/100)*shaftFreq);
%             end

            % Check presence required frequencies
            if ~isempty(mainStruct) && ~isempty(additionalStruct) %&& ~isempty(file.peakTable)
                
                file.frequency = mainStruct.frequencies;
                [mainStruct.magnitude, mainStruct.frequencies, mainStruct.prominence, mainStruct.logProminence] = myClassifier.peakComparison(file, parameters);
                file.frequency = additionalStruct.frequencies;
                [additionalStruct.magnitude, additionalStruct.frequencies, additionalStruct.prominence,additionalStruct.logProminence] = myClassifier.peakComparison(file, parameters);

            elseif ~isempty(mainStruct) %&& ~isempty(file.peakTable)
                mainStruct.magnitude = single(0);
                mainStruct.logProminence = single(0);
                mainStruct.prominence = single(0);
            else
                flagFillDomain = 0;
            end

            if flagFillDomain
                % Push to report
                if strfind(mode, 'periodicity') 
                    fillStructFrequencyDomain.mainFrequency{validDefectID(1, defectNumber), 1} = mainStruct.frequencies;
                    fillStructFrequencyDomain.mainMagnitude{validDefectID(1, defectNumber), 1} = mainStruct.magnitude;
                    fillStructFrequencyDomain.mainFrequencyName{validDefectID(1, defectNumber), 1} = mainStruct.frequenciesNames;
                    fillStructFrequencyDomain.mainFrequencyTag{validDefectID(1, defectNumber), 1} = mainStruct.frequenciesTags;
                    fillStructFrequencyDomain.mainProminence{validDefectID(1, defectNumber), 1} = mainStruct.prominence;
                    fillStructFrequencyDomain.mainLogProminence{validDefectID(1, defectNumber), 1} = mainStruct.logProminence;
                    fillStructFrequencyDomain.mainWeight{validDefectID(1, defectNumber), 1} = mainStruct.frequenciesWeights;
                else
                    fillStructFrequencyDomain = myClassifier.pushToReport(fillStructFrequencyDomain, ...
                        validDefectID, defectNumber, 'main', mainStruct);
                    fillStructFrequencyDomain = myClassifier.pushToReport(fillStructFrequencyDomain, ...
                        validDefectID, defectNumber, 'additional', additionalStruct);
                end
            else
                
                varibleNan = nan(1, 'single');
                if strfind(mode, 'periodicity') 
                    
                    fillStructFrequencyDomain.mainFrequency{validDefectID(1, defectNumber), 1} = varibleNan;
                    fillStructFrequencyDomain.mainMagnitude{validDefectID(1, defectNumber), 1} = varibleNan;
                    fillStructFrequencyDomain.mainFrequencyName{validDefectID(1, defectNumber), 1} = varibleNan;
                    fillStructFrequencyDomain.mainFrequencyTag{validDefectID(1, defectNumber), 1} = varibleNan;
                    fillStructFrequencyDomain.mainProminence{validDefectID(1, defectNumber), 1} = varibleNan;
                    fillStructFrequencyDomain.mainLogProminence{validDefectID(1, defectNumber), 1} = varibleNan;
                    fillStructFrequencyDomain.mainWeight{validDefectID(1, defectNumber), 1} = varibleNan;
                else
                    fillStructFrequencyDomain.mainFrequency{validDefectID(1, defectNumber), 1} = varibleNan;
                    fillStructFrequencyDomain.mainMagnitude{validDefectID(1, defectNumber), 1} = varibleNan;
                    fillStructFrequencyDomain.mainFrequencyName{validDefectID(1, defectNumber), 1} = varibleNan;
                    fillStructFrequencyDomain.mainFrequencyTag{validDefectID(1, defectNumber), 1} = varibleNan;
                    fillStructFrequencyDomain.mainProminence{validDefectID(1, defectNumber), 1} = varibleNan;
                    fillStructFrequencyDomain.mainLogProminence{validDefectID(1, defectNumber), 1} = varibleNan;
                    fillStructFrequencyDomain.mainWeight{validDefectID(1, defectNumber), 1} = varibleNan;

                    fillStructFrequencyDomain.additionalFrequency{validDefectID(1, defectNumber), 1} = varibleNan;
                    fillStructFrequencyDomain.additionalMagnitude{validDefectID(1, defectNumber), 1} = varibleNan;
                    fillStructFrequencyDomain.additionalFrequencyName{validDefectID(1, defectNumber), 1} = varibleNan;
                    fillStructFrequencyDomain.additionalFrequencyTag{validDefectID(1, defectNumber), 1} = varibleNan;
                    fillStructFrequencyDomain.additionalProminence{validDefectID(1, defectNumber), 1} = varibleNan;
                    fillStructFrequencyDomain.additionalLogProminence{validDefectID(1, defectNumber), 1} = varibleNan;
                    fillStructFrequencyDomain.additionalWeight{validDefectID(1, defectNumber), 1} = varibleNan;
                end
            end
        end

    end

    methods (Static)
        % GETDEFFREQ function description ... 
        % Example: 
        %         struct2defFreq()              schemeValidator()
        % 2*f1+-1*f5 --->  [2*f1_1*f5]   ---> [2,1] (Num); [1,5](Tag)
        % 2*(f1-f5)  --->  [2*f1_f5]     ---> [2] (Num); [1,5](Tag)
        function [result, modeDisableDefect] = getDefFreq(data, tag, modCount, tagList, weight, modeDisableDefect)

            if nargin < 5
                weight = [];
            end

            % To check correct input frequencies
            [numberFreq, numberColum] = size(tag);
            requiredTagColumn = unique(reshape(tag,[1 numberFreq*numberColum]));
            requiredTagColumn = requiredTagColumn(requiredTagColumn ~= 0);
            tagNumberAll = cell2mat(tagList(:, 1));
            requiredTagPositions = ismember(tagNumberAll, requiredTagColumn);
            freqListTag = cell2mat(tagList(:, 2));
            
            if ~nnz(isnan(freqListTag(requiredTagPositions)))
            
                % Number of frequency vectors and frequencies values in each
                % frequency vectors
                [vectorLength, freqLength] = size(data);
                % Length of basicFreqList
                tagListLength = length(tagList( : , 1));

                if isempty(weight)
                    weight = zeros(vectorLength, freqLength);
                end

                % Create vectors of main frequencies
                mainValues = zeros(vectorLength, freqLength);	% values main frequencies
                mainWeight = zeros(vectorLength, freqLength);	% weights of main frequencies
                mainNames = cell(vectorLength, freqLength);     % names of main frequencies
                mainTags = cell(vectorLength, freqLength);      % tags of main frequencies
                % Create vector of deductible frequencies
%                 deductValues = zeros(vectorLength, freqLength);     % values of deductible frequencies
%                 deductNames = cell(vectorLength, freqLength);       % names of deductible frequencies
%                 deductTags = cell(vectorLength, freqLength);        % tags of deductible frequencies
                % Create vectors of modulation frequencies
                modValues = zeros(vectorLength, freqLength * max(modCount));    % values of modulation frequencies
                modWeight = zeros(vectorLength, freqLength * max(modCount));	% weights of modulation frequencies
                modNames = cell(vectorLength, freqLength * max(modCount));      % names of modulation frequencies
                modTags = cell(vectorLength, freqLength * max(modCount));       % tags of modulation frequencies
                modFactors = zeros(vectorLength, freqLength * max(modCount));	% factors of modulation frequencies

                % Fill vectors of main, deductible, modulation frequencies
                for vectorNumber = 1 : 1 : vectorLength
                    for tagNumber = 1 : 1 : tagListLength
                        if isequal(tag(vectorNumber, 1), tagList{tagNumber, 1})
                            % Fill vectors of main frequencies
                            mainValues(vectorNumber, : ) = data(vectorNumber, : ) * tagList{tagNumber, 2};
                            mainWeight(vectorNumber, : ) = weight(vectorNumber, : );
                            for freqNumber = 1 : 1 : freqLength
                                mainNames{vectorNumber, freqNumber} = [num2str(data(vectorNumber, freqNumber)), '*', tagList{tagNumber, 3}];
                                mainTags{vectorNumber, freqNumber} = [num2str(data(vectorNumber, freqNumber)), '*', num2str(tagList{tagNumber, 1})];
                            end
                            break;
                        end
                    end
                    for tagNumber = 1 : 1 : tagListLength
                        if isequal(tag(vectorNumber, 2), tagList{tagNumber, 1})
                            % Fill vectors of deductible frequencies
%                             deductValues(vectorNumber, : ) = data(vectorNumber, : ) * tagList{tagNumber, 2};
%                             for freqNumber = 1 : 1 : freqLength
%                                 deductNames{vectorNumber, freqNumber} = [num2str(data(vectorNumber, freqNumber)), '*', tagList{tagNumber, 3}];
%                                 deductTags{vectorNumber, freqNumber} = [num2str(data(vectorNumber, freqNumber)), '*', num2str(tagList{tagNumber, 1})];
%                             end
                            if modCount(vectorNumber) ~= 0
                                % Fill vectors of modulation frequencies
                                modFactors(vectorNumber, : ) = linspace(1, freqLength * max(modCount), freqLength * max(modCount));
                                modValues(vectorNumber, : ) = modFactors(vectorNumber, : ) * tagList{tagNumber, 2};
                                modWeight(vectorNumber, : ) = zeros(1, length(modValues(vectorNumber, : )));
                                for modFreqNumber = 1 : 1 : freqLength * max(modCount)
                                    modNames{vectorNumber, modFreqNumber} = [num2str(modFactors(vectorNumber, modFreqNumber)), '*', tagList{tagNumber, 3}];
                                    modTags{vectorNumber, modFreqNumber} = [num2str(modFactors(vectorNumber, modFreqNumber)), '*', num2str(tagList{tagNumber, 1})];
                                end
                            end
                            break;
                        end
                    end
                end

                % Count nonzeros element in each vectors of main frequencies
                nnzFreqNumber = zeros(1, vectorLength);
                for vectorNumber = 1: 1 : vectorLength
                    nnzFreqNumber(vectorNumber) = nnz(mainValues(vectorNumber, : ));
                end
                % Max count of nonzero elements
                freqLength = max(nnzFreqNumber);

                % Combine main, deductible, modulation frequncy vectors
                % Create empty matrices of the frequency data
                if modCount == 0
                    freqValues = zeros(vectorLength, freqLength, 'single');
                    freqWeight = zeros(vectorLength, freqLength, 'single');
                    freqNames = cell(vectorLength, freqLength);
                    freqTags = cell(vectorLength, freqLength);
                else
                    freqValues = zeros(vectorLength, freqLength * (2 * max(modCount) + 1), 'single');
                    freqWeight = zeros(vectorLength, freqLength * (2 * max(modCount) + 1), 'single');
                    freqNames = cell(vectorLength, freqLength * (2 * max(modCount) + 1));
                    freqTags = cell(vectorLength, freqLength * (2 * max(modCount) + 1));
                end
                for vectorNumber = 1 : 1 : vectorLength
                    switch modCount(vectorNumber)
                        % For modulation 1 or 0 sidebands
                        % Example: 
                        %     for 1: 1*(shaftFreq-FTF), 2*(shaftFreq-FTF) ...
                        %     for 0: 1*shaftFreq, 2*shaftFreq ...
                        case 0
                           % Vector formation frequency for the difference of
                           % the main and sideband
                            freqValues(vectorNumber, 1 : freqLength) = mainValues(vectorNumber, 1 : freqLength); %- deductValues(vectorNumber, 1 : freqLength);
                            freqWeight(vectorNumber, 1 : freqLength) = mainWeight(vectorNumber, 1 : freqLength);
                            for freqNumber = 1: 1 : freqLength
%                                 if deductValues(vectorNumber, freqNumber) ~= 0
%                                     freqNames{vectorNumber, freqNumber} = [mainNames{vectorNumber, freqNumber}, '-', deductNames{vectorNumber, freqNumber}];
%                                     freqTags{vectorNumber, freqNumber} = [mainTags{vectorNumber, freqNumber}, '_', deductTags{vectorNumber, freqNumber}]; 
%                                 else
                                    freqNames{vectorNumber, freqNumber} = mainNames{vectorNumber, freqNumber};
                                    freqTags{vectorNumber, freqNumber} = mainTags{vectorNumber, freqNumber};
%                                 end
                            end
                        % For modulation 2 or more sidebands
                        % Example: 
                        %     1*shaftFreq-1*FTF, 1*shaftFreq, 1*shaftFreq+1*FTF ...
                        otherwise
                            % Create empty vectors of current modulation
                            % frequencies
                            currentModValues = cell(modCount(vectorNumber), 2);     % values of current modulation frequencies
                            currentModWeight = cell(modCount(vectorNumber), 2);     % weights of current modulation frequencies
                            currentModNames = currentModValues;                     % names of current modulation frequencies
                            currentModTags = currentModValues;                      % tags of current modulation frequencies
                            % Fill vectors of current modulation frequencies
                            for modNumber = 1 : 1 : modCount(vectorNumber)
                                currentModValues{modNumber, 1} = mainValues(vectorNumber, : ) - (ones(1, freqLength) * modNumber) * modValues(vectorNumber, 1);
                                currentModValues{modNumber, 2} = mainValues(vectorNumber, : ) + (ones(1, freqLength) * modNumber) * modValues(vectorNumber, 1);
                                currentModWeight{modNumber, 1} = modWeight(vectorNumber, : );
                                currentModWeight{modNumber, 2} = modWeight(vectorNumber, : );
                                for modFreqNumber = 1 : 1 : freqLength
                                    currentModNames{modNumber, 1}{1, modFreqNumber} = [mainNames{vectorNumber, modFreqNumber}, '-', modNames{vectorNumber, modNumber}];
                                    currentModNames{modNumber, 2}{1, modFreqNumber} = [mainNames{vectorNumber, modFreqNumber}, '+', modNames{vectorNumber, modNumber}];
                                    currentModTags{modNumber, 1}{1, modFreqNumber} = [mainTags{vectorNumber, modFreqNumber}, '_', modTags{vectorNumber, modNumber}];
                                    currentModTags{modNumber, 2}{1, modFreqNumber} = [mainTags{vectorNumber, modFreqNumber}, '_', modTags{vectorNumber, modNumber}];
                                end
                            end
                            % Sort vectors in order: sideband - main frequency - sideband
                            % The number of the main frequency
                            mainCounter = 1;
                            % The number of the sideband harmonic
                            modCounter = modCount(vectorNumber);
                            % The number of the last frequency of the last
                            % complited positive sideband
                            lastFreqNumber = 0;
                            for modFreqNumber = 1 : 1 : nnzFreqNumber(vectorNumber) * (2 * modCount(vectorNumber) + 1)
                                if modFreqNumber < modCount(vectorNumber) + 1 + lastFreqNumber
                                    % Fill the negative sideband of the
                                    % current main frequency
                                    freqValues(vectorNumber, modFreqNumber) = currentModValues{modCounter, 1}(1, mainCounter);
                                    freqWeight(vectorNumber, modFreqNumber) = currentModWeight{modCounter, 1}(1, mainCounter);
                                    freqNames{vectorNumber, modFreqNumber} = currentModNames{modCounter, 1}{1, mainCounter};
                                    freqTags{vectorNumber, modFreqNumber} = currentModTags{modCounter, 1}{1, mainCounter};
                                    modCounter = modCounter - 1;
                                elseif modFreqNumber == modCount(vectorNumber) + 1 + lastFreqNumber
                                    % Fill the current main frequency
                                    freqValues(vectorNumber, modFreqNumber) = mainValues(vectorNumber, mainCounter);
                                    freqWeight(vectorNumber, modFreqNumber) = mainWeight(vectorNumber, mainCounter);
                                    freqNames{vectorNumber, modFreqNumber} = mainNames{vectorNumber, mainCounter};
                                    freqTags{vectorNumber, modFreqNumber} = mainTags{vectorNumber, mainCounter};
                                    modCounter = 1;
                                else
                                    % Fill the positive sideband of the current
                                    % main frequency
                                    freqValues(vectorNumber, modFreqNumber) = currentModValues{modCounter, 2}(1, mainCounter);
                                    freqWeight(vectorNumber, modFreqNumber) = currentModWeight{modCounter, 2}(1, mainCounter);
                                    freqNames{vectorNumber, modFreqNumber} = currentModNames{modCounter, 2}{1, mainCounter};
                                    freqTags{vectorNumber, modFreqNumber} = currentModTags{modCounter, 2}{1, mainCounter};
                                    modCounter = modCounter + 1;
                                end
                                % Move to the next group of frequencies
                                if ~mod(modFreqNumber, (2 * modCount(vectorNumber) + 1))
                                    mainCounter = mainCounter + 1;
                                    lastFreqNumber = lastFreqNumber + (2 * modCount(vectorNumber) + 1);
                                    modCounter = modCount(vectorNumber);
                                end
                            end
                    end
                end
                % Save elements greater than 0
                freqNames = freqNames(freqValues > 0);
                freqWeight = freqWeight(freqValues > 0);
                freqTags = freqTags(freqValues > 0);
                freqValues = freqValues(freqValues > 0);
                if(size(freqNames, 2) < size(freqNames, 1))
                    % Rotate result vectors
                    freqNames = freqNames';
                    freqWeight = freqWeight';
                    freqTags = freqTags';
                    freqValues = freqValues';
                end
                % Delete repeating tags
                [freqNames, index] = unique(freqNames, 'stable');
                freqValues = freqValues(index);
                freqWeight = freqWeight(index);
                freqTags = freqTags(index);

                % Set the result
                result.frequencies = freqValues;
                result.frequenciesWeights = freqWeight;
                result.frequenciesNames = freqNames;
                result.frequenciesTags = freqTags;
            else
                
                % To disable all domains of defect 
                modeDisableDefect = true(1);
                
                % Set the result
                result.frequencies = [];
                result.frequenciesWeights = [];
                result.frequenciesNames = [];
                result.frequenciesTags = [];
            end
        end

        function emptyStruct = createEmptyStructFrequencyDomain(defectsNumber)
            emptyStruct.mainFrequency = cell(defectsNumber,1);
            emptyStruct.mainMagnitude = cell(defectsNumber,1);
            emptyStruct.mainFrequencyName = cell(defectsNumber,1);
            emptyStruct.mainFrequencyTag = cell(defectsNumber,1);
            emptyStruct.mainProminence = cell(defectsNumber,1);
            emptyStruct.mainLogProminence = cell(defectsNumber,1);
            emptyStruct.mainWeight = cell(defectsNumber,1);

            emptyStruct.additionalFrequency = cell(defectsNumber,1);
            emptyStruct.additionalMagnitude = cell(defectsNumber,1);
            emptyStruct.additionalFrequencyName = cell(defectsNumber,1);
            emptyStruct.additionalFrequencyTag = cell(defectsNumber,1);
            emptyStruct.additionalProminence = cell(defectsNumber,1);
            emptyStruct.additionalLogProminence = cell(defectsNumber,1);
            emptyStruct.additionalWeight = cell(defectsNumber,1);
        end
        function emptyStruct = createEmptyStructPeriodicity(defectsNumber)
            emptyStruct.mainFrequency = cell(defectsNumber,1);
            emptyStruct.mainMagnitude = cell(defectsNumber,1);
            emptyStruct.mainFrequencyName = cell(defectsNumber,1);
            emptyStruct.mainFrequencyTag = cell(defectsNumber,1);
            emptyStruct.mainProminence = cell(defectsNumber,1);
            emptyStruct.mainLogProminence = cell(defectsNumber,1);
            emptyStruct.mainWeight = cell(defectsNumber,1);
        end

        function struct = toDoEmptyStruct(struct, numberDefect)
            
            namesFields = fieldnames(struct);
            for i = 1:1:length(namesFields)
                struct.(namesFields{i}){numberDefect, 1} = [];
            end
        end
        
        % PUSHTOREPORT function deleting not found frequencies and sorting for 
        % frequency
        function fillStruct = pushToReport(fillStruct, validDefectID, defectNumber, structTag, struct)
            if ~isempty(struct.frequencies)
                
                matrixIndex = struct.frequencies > 0;
                
                tempFrequencies = struct.frequencies(matrixIndex);
                [tempFrequencies, index] = sort(tempFrequencies);
                tempMagnitude = struct.magnitude(matrixIndex);
                tempMagnitude = tempMagnitude(index);
                tempNames = struct.frequenciesNames(matrixIndex);
                tempNames = tempNames(index);
                tempTag = struct.frequenciesTags(matrixIndex);
                tempTag = tempTag(index);
                tempProminence = struct.prominence(matrixIndex);
                tempProminence = tempProminence(index);
                tempLogProminence = struct.logProminence(matrixIndex);
                tempLogProminence = tempLogProminence(index);
                tempWeights = struct.frequenciesWeights(matrixIndex);
                tempWeights = tempWeights(index);

                fillStruct.([structTag 'Frequency']){validDefectID(1, defectNumber), 1} = tempFrequencies;
                fillStruct.([structTag 'Magnitude']){validDefectID(1, defectNumber), 1} = tempMagnitude;
                fillStruct.([structTag 'FrequencyName']){validDefectID(1, defectNumber), 1} = tempNames;
                fillStruct.([structTag 'FrequencyTag']){validDefectID(1, defectNumber), 1} = tempTag;
                fillStruct.([structTag 'Prominence']){validDefectID(1, defectNumber), 1} = tempProminence;
                fillStruct.([structTag 'LogProminence']){validDefectID(1, defectNumber), 1} = tempLogProminence;
                fillStruct.([structTag 'Weight']){validDefectID(1, defectNumber), 1} = tempWeights;

            else
                fillStruct.([structTag 'FrequencyName']){validDefectID(1, defectNumber), 1} = [];
                fillStruct.([structTag 'FrequencyTag']){validDefectID(1, defectNumber), 1} = [];
                fillStruct.([structTag 'Prominence']){validDefectID(1, defectNumber), 1} = [];
                fillStruct.([structTag 'LogProminence']){validDefectID(1, defectNumber), 1} = [];
            end
        end 
        
        % PEAKCOMPARISON function compares required peaks and peakTable
        function [validMag, validFreq, validProm, validLogProm] = peakComparison(file, config)
            
            foundFrequencies = file.peakTable(:, 1);
            
            if ~isempty(file.frequency) && any(foundFrequencies)
                
                % Set initial varibals
                lengthRequiredFrequency = length(file.frequency);
                validFreq = zeros(1, lengthRequiredFrequency, 'single');
                validMag = validFreq;
                validProm = validFreq;
                validLogProm = validFreq;
                
                % Peak search the required peaks in table
                for i = 1:1:lengthRequiredFrequency

                    validPositionVector = frequencyComparison(file.frequency(1, i), foundFrequencies, config);
                    
                    if ~isempty(validPositionVector)

                        if numel(validPositionVector) == 1

                            validFreq(1, i) = foundFrequencies(validPositionVector, 1);
                            validMag(1, i) = file.peakTable(validPositionVector, 2);
                            validProm(1, i) = file.peakTable(validPositionVector, 3);
                            validLogProm(1, i) = file.peakTable(validPositionVector, 4);
                        else
                            numberTruePos = findWithDecreasingRange(file.frequency(1, i), ...
                                                                    foundFrequencies(validPositionVector, 1), ...
                                                                    file.peakTable(validPositionVector, 2));

                            validFreq(1, i) = foundFrequencies(validPositionVector(numberTruePos), 1);
                            validMag(1, i) = file.peakTable(validPositionVector(numberTruePos), 2);
                            validProm(1, i) = file.peakTable(validPositionVector(numberTruePos), 3);
                            validLogProm(1, i) = file.peakTable(validPositionVector(numberTruePos), 4);
                        end
                    end
                end
                
            else
              validMag = single(0);    
              validFreq = single(0);
              validProm = single(0);
              validLogProm = single(0);
            end 
            
        end
        
     end
end

