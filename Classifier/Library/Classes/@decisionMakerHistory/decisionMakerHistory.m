classdef decisionMakerHistory 
   % Class is decision maker for several methods with history
    
    properties (Access = private)
        % Input properties
        config
        mySchemeClassifier
        myTimeFrequencyClassifier
        statusStructXml
        decisionMakerCompression
        
        % Output properties
        resultStruct
    end
    
    methods (Access = public)
        % Constructor
        function [myDecisionMakerHistory] = decisionMakerHistory(config, file)
            
            % Filling basic properties   
            myDecisionMakerHistory.config.peakComparison = ...
                config.config.parameters.evaluation.decisionMaker.peakComparison;
            myDecisionMakerHistory.config.decisionMaker = ...
                config.config.parameters.evaluation.decisionMaker.decisionMakerHistory;
            nameFileStatus = config.config.parameters.evaluation.statusWriter.Attributes.nameTempStatusFile;
            myDecisionMakerHistory.config.plots = config.config.parameters.evaluation.plots.Attributes;
            myDecisionMakerHistory.config.plots.printPlotsEnable = config.config.parameters.common.printPlotsEnable.Attributes.value;
            myDecisionMakerHistory.config.plots.visible = config.config.parameters.common.printPlotsEnable.Attributes.visible;
            myDecisionMakerHistory.config.plots.title = config.config.parameters.common.printPlotsEnable.Attributes.title;
            myDecisionMakerHistory.config.translations = file.translations;
            
            % To fill objects of single processing
            myDecisionMakerHistory.myTimeFrequencyClassifier = file.myTimeFrequencyClassifier;
            myDecisionMakerHistory.mySchemeClassifier = file.mySchemeClassifier;
            
            % To fill base result structure
            myDecisionMakerHistory.resultStruct = myDecisionMakerHistory.createEmptyStatusWith2Defects();
            
            % To fill raw status structure
            statusStruct = xml2struct(fullfile(pwd,'Out',[nameFileStatus '.xml']));
            statusStruct = statusStruct.equipment;
            statusStruct = rmfield(statusStruct,'processingTime');
            statusStruct = rmfield(statusStruct,'Attributes');
            if isfield(statusStruct,'decisionMaker')
                statusStruct = rmfield(statusStruct,'decisionMaker');
            end
            myDecisionMakerHistory.statusStructXml = statusStruct;
            myDecisionMakerHistory.decisionMakerCompression = file.decisionMakerCompression;
        end
        
        % PROCESSINGDECISIONMAKER main function of decision maker for calculation
        function [myDecisionMakerHistory] = processingDecisionMaker(myDecisionMakerHistory)
            
            enableTimeFrequency = isfield(myDecisionMakerHistory.statusStructXml, 'timeFrequencyDomainClassifier');
            enableFrequency = isfield(myDecisionMakerHistory.statusStructXml, 'frequencyDomainClassifier');
            
            % To choose calculation with known elements or unknown 
            if enableFrequency || enableTimeFrequency
                    
                myDecisionMakerHistory.resultStruct = ...
                    addClassifiersToDecisionMaker(myDecisionMakerHistory, enableTimeFrequency, enableFrequency); 
                
                [myDecisionMakerHistory.resultStruct, tablePeriodicityOk] = addPeriodicityToDecisionMaker(myDecisionMakerHistory);
                
                myDecisionMakerHistory.resultStruct = addIso7919ToDecisionMaker(myDecisionMakerHistory);
                
                myDecisionMakerHistory.resultStruct = addShaftTrajectoryToDecisionMaker(myDecisionMakerHistory);
                
                myDecisionMakerHistory.resultStruct = addMetricsToDecisionMaker(myDecisionMakerHistory);
                
                myDecisionMakerHistory.resultStruct = evaluateDefects(myDecisionMakerHistory);
                
                myDecisionMakerHistory.resultStruct = checkForUnknownDefect(myDecisionMakerHistory, tablePeriodicityOk);
                
                % To add time classifier after evelaute and compare all patern of defects 
                myDecisionMakerHistory = addTimeDomainClassifier(myDecisionMakerHistory);
            else
                myDecisionMakerHistory.resultStruct = addMetricsToDecisionMaker(myDecisionMakerHistory); 
                
                myDecisionMakerHistory.resultStruct = addPeriodicityToUnknownDefect(myDecisionMakerHistory);
                
                myDecisionMakerHistory.resultStruct = evaluateDefects(myDecisionMakerHistory);
                
                myDecisionMakerHistory = addTimeDomainClassifier(myDecisionMakerHistory);
            end
            
            % Add iso10816 defect
            myDecisionMakerHistory.resultStruct = addStatusToIso10816Defect(myDecisionMakerHistory);
            
            % Add iso7919 defects
            myDecisionMakerHistory.resultStruct = addStatusToIso7919Defect(myDecisionMakerHistory);
            
            % Add vdi3834 defects
            myDecisionMakerHistory.resultStruct = addStatusToVdi3834Defect(myDecisionMakerHistory);
            
            % If status more 100%
            exceedingStatus = find(cell2mat({myDecisionMakerHistory.resultStruct.status}) > 100);
            if ~isempty(exceedingStatus)
                for i = 1:1:length(exceedingStatus)
                    myDecisionMakerHistory.resultStruct(exceedingStatus(i)).status = 100;
                end
            end
            
            % Plot growth of defects
            if str2double(myDecisionMakerHistory.config.decisionMaker.Attributes.plotEnable) && ...
                    ~isempty(myDecisionMakerHistory.decisionMakerCompression.tableStatuses)
                
                plotDefectHistory(myDecisionMakerHistory);
            end
        end
        
        % FILLDOCNODE function add to informative tags in docNode structure 
        function docNode = fillDocNode(myDecisionMakerHistory, docNode)
            
            % Replace existing DecisionMaker node with new one
            docRootNode = docNode.getDocumentElement;
            if hasChildNodes(docRootNode)
                childNodes = getChildNodes(docRootNode);
                numChildNodes = getLength(childNodes);
                for count = 1:numChildNodes
                    theChild = item(childNodes,count-1);
                    name = toCharArray(getNodeName(theChild))';
                    if strcmp(name,'decisionMaker')
                        docRootNode.removeChild(theChild);
                        break;
                    end
                end 
            end
            
            statusStruct = myDecisionMakerHistory.resultStruct;
            
            % Create decisionMaker node
            decisionMakerNode = docNode.createElement('decisionMaker');
            
            % Get element names
            elementNames = {statusStruct.schemeName};
            % Get unique element names
            uniqueElements = unique(elementNames, 'stable');
            % Checking for unique elements in the statusStruct, cutting
            % corresponding to them parts of the statusStruct and putting
            % it into the CREATEELEMENTNODE function for element docNode
            % part creation
            for elementNumber = 1 : 1 : length(uniqueElements)
                currentElementName = uniqueElements{elementNumber};
                currentElementIndex = ismember(elementNames, currentElementName);
                elementStatusStruct = statusStruct(currentElementIndex);
                elementNode = myDecisionMakerHistory.createElementNode(docNode, elementStatusStruct);
                decisionMakerNode.appendChild(elementNode);
            end
            % Create docRoot node
            docRootNode = docNode.getDocumentElement;
            % Set specraClassifier node to docRoot node
            docRootNode.appendChild(decisionMakerNode);
        end
        
        % Getters
        function statusStruct = getResultStruct(myDecisionMakerHistory)
            statusStruct = myDecisionMakerHistory.resultStruct;
        end
    end
    
    methods (Access = private)
        % ADDCLASSIFIERSTODECISIONMAKER function add structure
        % time-frequency and frequency classifiers to structure of decision
        % makers and compare result between them
        function statusStruct = addClassifiersToDecisionMaker(myDecisionMakerHistory, enableTimeFrequency, enableFrequency)
            
            % To get status struct of decisionMaker
            statusStruct = myDecisionMakerHistory.resultStruct;
            
            % To get status struct of time-frequency classifier 
            if enableTimeFrequency
                
                % To determine numbers of resonant frequencies
                numbersRanges = length(myDecisionMakerHistory.statusStructXml.timeFrequencyDomainClassifier.resonantFrequency);
                
                % To get struct how the frequency classifier
                if numbersRanges == 1
                    if isfield(myDecisionMakerHistory.statusStructXml.timeFrequencyDomainClassifier.resonantFrequency, 'frequencyDomainClassifier')
                        timeFrequencyStruct = {decisionMakerHistory.xmlStructToTable( ...
                            myDecisionMakerHistory.statusStructXml.timeFrequencyDomainClassifier.resonantFrequency.frequencyDomainClassifier)};
                    else
                        timeFrequencyStruct = [];
                    end
                else
                    timeFrequencyStruct = cell(numbersRanges,1);
                    for i = 1:1:numbersRanges
                        timeFrequencyStruct{i, 1} = decisionMakerHistory.xmlStructToTable( ...
                          myDecisionMakerHistory.statusStructXml.timeFrequencyDomainClassifier.resonantFrequency{1, i}.frequencyDomainClassifier);
                    end
                end
                
                if ~isempty(timeFrequencyStruct)
                    % To fill empty frequency classifier
                    numberDefects = length(timeFrequencyStruct{1,1});
                    frequencyStruct = zeros(1, numberDefects);
                end
            else
                timeFrequencyStruct = [];
            end
                
            % To get status struct of frequency classifier
            if enableFrequency
                
                % Create status result struct from status.xml
                frequencyStruct = ...
                    decisionMakerHistory.xmlStructToTable(myDecisionMakerHistory.statusStructXml.frequencyDomainClassifier);
                numberDefects = length(frequencyStruct);
                
                if isempty(timeFrequencyStruct)
                    % To fill empty temi-frequency classifier
                    timeFrequencyStruct = {zeros(numberDefects,1)};
                    numbersRanges = 1;
                end
            end
                
            % Compare statuses
            vectorNumberRanges = 1:1:numbersRanges;
            tempStatusStruct = myDecisionMakerHistory.createEmptyResultStruct(numberDefects);
            for i = 1:1:numberDefects
                tempStatusStruct(i) = myDecisionMakerHistory.fillingStatusesClassifier(frequencyStruct(1,i), ...
                    arrayfun(@(x) timeFrequencyStruct{x, 1}(i), vectorNumberRanges));
            end 
            
            % Delete LUBRICATION_DEFECT if there is not rollingBearing
            % elements
            if nnz(contains({tempStatusStruct.class}, 'rollingBearing'))
                startPos = 3;
            else
                statusStruct = statusStruct(1);
                startPos = 2;
            end
            
            % To get struct with metrics and periodicity
            if enableFrequency
                structSingleProcessing = getStatusStruct(myDecisionMakerHistory.mySchemeClassifier);
            else
                myObjectStruct = getObjectStruct(myDecisionMakerHistory.myTimeFrequencyClassifier);
                structSingleProcessing = getStatusStruct(myObjectStruct{1});
            end
            
            % To add periodicity and metrics required to status struct
            listNameSingle = {structSingleProcessing.defectTagName};
            listSchemeName = {structSingleProcessing.name};
            for i = 1:1:numberDefects
                positionDefect = strcmpi(listNameSingle, tempStatusStruct(i).tagNameDefect);
                positionClass = strcmpi(listSchemeName, tempStatusStruct(i).schemeName);
                numberPosition = positionDefect & positionClass;
                if nnz(numberPosition) == 1
                    
                    % To add metrics
                    if ~isempty(structSingleProcessing(numberPosition).metrics)
                        tempStatusStruct(i).requiredMetrics.name = strsplit(structSingleProcessing(numberPosition).metrics.name);
                        tempStatusStruct(i).requiredMetrics.weight = str2num(structSingleProcessing(numberPosition).metrics.weight);
                    end
                    
                    % To add periodicity
                    if ~isempty(structSingleProcessing(numberPosition).periodicity.mainFrequency)
                        tempStatusStruct(i).requiredPeriodicity = structSingleProcessing(numberPosition).periodicity;
                    end
                else
                   warning('Structures are not corresponding between history and single processings'); 
                end
            end
            
            % Write to result struct
            statusStruct(startPos:startPos+numberDefects-1) = tempStatusStruct;  
        end
        
        % ADDPERIODICITYTODECISIONMAKER function increasing status, 
        % if signal have required stably periodicity of defect
        function [statusStruct, tablePeriodicityOk] = addPeriodicityToDecisionMaker(myDecisionMakerHistory)
            
            % To get status struct of decisionMaker
            statusStruct = myDecisionMakerHistory.resultStruct;
            
            tablePeriodicityOk = false(length(statusStruct),1);
            peakComparisonConfig = myDecisionMakerHistory.config.peakComparison.Attributes;
            
            % To check enable of periodicity
            if isfield(myDecisionMakerHistory.statusStructXml, 'periodicity')
                frequences = str2num(myDecisionMakerHistory.statusStructXml.periodicity.informativeTags.frequency.Attributes.value);
                historyStatus = logical(str2num(myDecisionMakerHistory.statusStructXml.periodicity.informativeTags.historyValidity.Attributes.value));
                
                % To check validity of periodicity
                if nnz(historyStatus)
                    
                    validFrequences = frequences(historyStatus);
                    
                    % To find non empty fields with requiredPeriodicity
                    positionNonEmpty = find(~cellfun(@isempty, {statusStruct.requiredPeriodicity}));
                    if ~isempty(positionNonEmpty)
                        for i = 1:1:length(positionNonEmpty)
                            requiredFreq = statusStruct(positionNonEmpty(i)).requiredPeriodicity.mainFrequency;
                            position = arrayfun(@(x) ~isempty(getSimilarElements(x, validFrequences, peakComparisonConfig)), requiredFreq);
                            
                            if nnz(position) && statusStruct(positionNonEmpty(i)).status ~= -1
                                statusPeriodicity = 100*(sum(statusStruct(positionNonEmpty(i)).requiredPeriodicity.mainWeight(position)));
                                statusStruct(positionNonEmpty(i)).informativesTags.periodicity.statusAll = statusPeriodicity;
                                tablePeriodicityOk(positionNonEmpty(i)) = true;
                            end
                        end
                    end
                end
            end
        end
        
        % ADDISO7919TODECISIONMAKER function
        function [statusStruct] = addIso7919ToDecisionMaker(myDecisionMakerHistory)
            
            % Get status struct of decisionMaker
            statusStruct = myDecisionMakerHistory.resultStruct;
            
            if isfield(myDecisionMakerHistory.statusStructXml, 'iso7919')
                
                % Get iso7919 status struct
                iso7919Struct = myDecisionMakerHistory.statusStructXml.iso7919.status;
                shaftNames = fieldnames(iso7919Struct);
                
                % Get iso7919 informativeTags
                informativeTags = getInformativeTags(myDecisionMakerHistory.mySchemeClassifier);
                iso7919InformativeTags = informativeTags.classStruct.shaftClassifier.shaft.defect{1, 2}.iso7919.data.Attributes;
                
                % Get enough status values
                enoughIso7919 = str2double(myDecisionMakerHistory.config.decisionMaker.Attributes.enoughIso7919) * 100;
                
                % Find shaft defects in the statusStruct for each shaft
                shaftDefectsPositions = cellfun(@(shaftName) find(strcmp({statusStruct.schemeName}, shaftName)), ...
                    shaftNames, 'UniformOutput', false);
                % Find the defect "ROTOR_IMBALANCE" in the statusStruct
                % for each shaft
                shaftImbalancePositions = cellfun(@(defectsIndex) defectsIndex(strcmp({statusStruct(defectsIndex).tagNameDefect}, 'ROTOR_IMBALANCE')), ...
                    shaftDefectsPositions, 'UniformOutput', true);
                                
                for shaftNumber = 1 : 1 : length(shaftNames)
                    % Get the shaft schemeName
                    shaftSchemeName = shaftNames{shaftNumber};
                    shaftImbalancePosition = shaftImbalancePositions(shaftNumber);
                    
                    % Get shaft data
                    shaftStatus = double(str2numStatus.(iso7919Struct.(shaftSchemeName).Attributes.value)) * 100;
                    shaftWeight = str2double(iso7919InformativeTags.weight);
                    
                    shaftStruct.status = shaftStatus;
                    shaftStruct.weight = shaftWeight;
                    
                    if shaftStatus >= enoughIso7919
                        shaftStruct.statusAll = round(shaftStatus * shaftWeight);
                    else
                        shaftStruct.statusAll = 0;
                    end
                    
                    statusStruct(shaftImbalancePosition).informativesTags.iso7919 = shaftStruct;
                end
            end
            
        end
        
        % ADDSHAFTTRAJECTORYTODECISIONMAKER function
        function [statusStruct] = addShaftTrajectoryToDecisionMaker(myDecisionMakerHistory)
            
            % Get status struct of decisionMaker
            statusStruct = myDecisionMakerHistory.resultStruct;
            
            if isfield(myDecisionMakerHistory.statusStructXml, 'shaftTrajectory')
                
                % Get shaftTrajectory status struct
                shaftTrajectoryStruct = myDecisionMakerHistory.statusStructXml.shaftTrajectory.status;
                shaftNames = fieldnames(shaftTrajectoryStruct);
                if length(shaftNames) == 1
                    if strcmp(shaftNames, 'shaft')
                        return;
                    end
                end
                
                % Get shaftTrajectory informativeTags
                informativeTags = getInformativeTags(myDecisionMakerHistory.mySchemeClassifier);
                shaftTrajectoryInformativeTags = informativeTags.classStruct.shaftClassifier.shaft.defect{1, 2}.shaftTrajectory.data.Attributes;
                
                % Get enough status values
                enoughShaftTrajectory = str2double(myDecisionMakerHistory.config.decisionMaker.Attributes.enoughShaftTrajectory) * 100;
                
                % Find shaft defects in the statusStruct for each shaft
                shaftDefectsPositions = cellfun(@(shaftName) find(strcmp({statusStruct.schemeName}, shaftName)), ...
                    shaftNames, 'UniformOutput', false);
                % Find the defect "ROTOR_IMBALANCE" in the statusStruct
                % for each shaft
                shaftImbalancePositions = cellfun(@(defectsIndex) defectsIndex(strcmp({statusStruct(defectsIndex).tagNameDefect}, 'ROTOR_IMBALANCE')), ...
                    shaftDefectsPositions, 'UniformOutput', true);
                                
                for shaftNumber = 1 : 1 : length(shaftNames)
                    % Get the shaft schemeName
                    shaftSchemeName = shaftNames{shaftNumber};
                    shaftImbalancePosition = shaftImbalancePositions(shaftNumber);
                    
                    % Get shaft data
                    shaftStatus = str2double(shaftTrajectoryStruct.(shaftSchemeName).Attributes.value) * 100;
                    shaftWeight = str2double(shaftTrajectoryInformativeTags.weight);
                    
                    shaftStruct.status = shaftStatus;
                    shaftStruct.weight = shaftWeight;
                    
                    if shaftStatus >= enoughShaftTrajectory
                        shaftStruct.statusAll = round(shaftStatus * shaftWeight);
                    else
                        shaftStruct.statusAll = 0;
                    end
                    
                    statusStruct(shaftImbalancePosition).informativesTags.shaftTrajectory = shaftStruct;
                end
            end
            
        end
        
        % ADDMETRICSTODECISIONMAKER function add required metrics to defects
        % structure of decision maker
        function statusStruct = addMetricsToDecisionMaker(myDecisionMakerHistory)
            
            % To get position non empty defects with required metrics
            posNonEmptyMetrics = ~cellfun(@isempty, {myDecisionMakerHistory.resultStruct.requiredMetrics});
            nonEmptyCnt = nnz(posNonEmptyMetrics);
            parameters = myDecisionMakerHistory.config.decisionMaker.Attributes;
            
            % To fill decision maker sturcture through metrics
            if nonEmptyCnt
                posNonEmpty = find(posNonEmptyMetrics);
                for i = 1:1:nonEmptyCnt
                    myDecisionMakerHistory.resultStruct(posNonEmpty(i)) = ...
                        myDecisionMakerHistory.fillingMetrics(myDecisionMakerHistory.resultStruct(posNonEmpty(i)), ...
                                                                myDecisionMakerHistory.statusStructXml, parameters);
                end
            end
            
            if isfield(myDecisionMakerHistory.resultStruct(1).informativesTags, 'metrics_velocity_iso10816')
                
                % Remove iso10816 from "UNKNOWN DEFECT"
                myDecisionMakerHistory.resultStruct(1).informativesTags = rmfield(myDecisionMakerHistory.resultStruct(1).informativesTags, ...
                    'metrics_velocity_iso10816');
            end
            
            statusStruct = myDecisionMakerHistory.resultStruct;
        end
        
        % EVALUATEDEFECTS function evaluate defects with filled 
        % informative tags
        function statusStruct = evaluateDefects(myDecisionMakerHistory)
            
            % To get initial parameters and variables
            statusStruct = myDecisionMakerHistory.resultStruct;
            numberDefects = length(statusStruct);
            enoughFrequencyClassifiers = ...
                str2double(myDecisionMakerHistory.config.decisionMaker.Attributes.enoughFrequencyClassifiers)*100;
            
            % To fill status of statusStruct with requiremed methods
            for i = 1:1:numberDefects
                
                structDefect = statusStruct(i);
                if structDefect.status ~= -1
                    defFuncName = ['maker_' structDefect.class '_' structDefect.tagNameDefect];
                    if exist([defFuncName '.m'], 'file') == 2
                        statusStruct(i).status = feval(defFuncName, structDefect);
                    else
                        statusStruct(i).status = decisionMakerHistory.evaluateDefectsForAll(structDefect, enoughFrequencyClassifiers);
                    end
                end
            end
            
            % To evaluate element with status of all defects functions
            allElement = {statusStruct.schemeName};
            elementNameUniq = unique(allElement);
            for i = 1:1:length(elementNameUniq)
                if nnz(~contains(elementNameUniq(i), 'unknown'))
                    positionElementFunctions = strcmpi(allElement,  elementNameUniq(i));
                    structTempFunction = statusStruct(positionElementFunctions);
                    functionName = ['element_' structTempFunction(1).class];
                    if exist([functionName '.m'], 'file') == 2
                        statusStruct(positionElementFunctions) = feval(functionName, structTempFunction);
                    end
                end
            end

            % If result less enoughWithClassifiers, 0 in status
            enoughWithClassifiers = str2double(myDecisionMakerHistory.config.decisionMaker.Attributes.enoughWithClassifiers)*100;
            posLessEnough = cellfun(@(x) x < enoughWithClassifiers, {statusStruct.status}) & ~cellfun(@(x) x == -1 , {statusStruct.status});
            numberPosLessEnough = find(posLessEnough);
            if ~isempty(numberPosLessEnough)
                for i = 1:1:nnz(numberPosLessEnough)
                    statusStruct(numberPosLessEnough(i)).status = 0;
                end
            end
        end
        
        % ADDTIMEDOMAINClassifier function check
        % timeDomainClassifier and add it to decision makers
        function myDecisionMakerHistory = addTimeDomainClassifier(myDecisionMakerHistory)
            
            if isfield(myDecisionMakerHistory.statusStructXml, 'timeDomainClassifier')
                
                enoughTimeDomain = str2double(myDecisionMakerHistory.config.decisionMaker.Attributes.enoughTimeDomain );
                enoughWithClassifiers = str2double(myDecisionMakerHistory.config.decisionMaker.Attributes.enoughWithClassifiers);
                contributionTimeDomain = str2double(myDecisionMakerHistory.config.decisionMaker.Attributes.contributionTimeDomain);
                
                if ~strcmpi(myDecisionMakerHistory.statusStructXml.timeDomainClassifier.status.Attributes.elementType, 'unknown')
                    if str2double(myDecisionMakerHistory.statusStructXml.timeDomainClassifier.status.Attributes.similarity) >= enoughTimeDomain
                        
                        % DUMMY --
                            if strcmpi(myDecisionMakerHistory.statusStructXml.timeDomainClassifier.status.Attributes.elementType, 'generator') 
                                myDecisionMakerHistory.statusStructXml.timeDomainClassifier.status.Attributes.elementType = 'motor';
                            end
                        % -- DUMMY
                        
                        % To get data for timeDomainClassifer 
                        timeDomain.element = myDecisionMakerHistory.statusStructXml.timeDomainClassifier.status.Attributes.elementType;
                        timeDomain.similarity = str2double(myDecisionMakerHistory.statusStructXml.timeDomainClassifier.status.Attributes.similarity);
                        timeDomain.similarityTrend = str2double(myDecisionMakerHistory.statusStructXml.timeDomainClassifier.status.Attributes.similarityTrend);
                        timeDomain.severity = str2double(myDecisionMakerHistory.statusStructXml.timeDomainClassifier.status.Attributes.severity);
                        timeDomain.value = str2double(myDecisionMakerHistory.statusStructXml.timeDomainClassifier.status.Attributes.value);

                        timeDomain.similarity = round(timeDomain.similarity);
                        timeDomain.status = decisionMakerHistory.evealuateHistoryTimeClassifier(timeDomain);
                        
                        statusStruct = myDecisionMakerHistory.resultStruct;
                        
                        % To find similar element of timeDomain to decision maker
                        positionSimilarElements = ~cellfun(@isempty, strfind(lower({statusStruct.class}), timeDomain.element));
                        structureSimilaritElement = statusStruct(positionSimilarElements);
                        
                        % To delete "unknow defect"
                        needSavePos = ~contains(lower({structureSimilaritElement.schemeName}), 'unknown');
                        if nnz(~needSavePos)
                            structureSimilaritElement = structureSimilaritElement(needSavePos);
                        end
                        
                        % Check enough of FrequiencyDomain status
                        if ~isempty(structureSimilaritElement)
                            positiomEnoughStatus = ...
                                cellfun(@(x) x >= enoughWithClassifiers, {structureSimilaritElement.status});
                            structureSimilaritElement = structureSimilaritElement(positiomEnoughStatus);
                            if ~isempty(structureSimilaritElement)
                                frequencyDomainOk = true;
                            else
                                frequencyDomainOk = false;
                            end
                        else
                            frequencyDomainOk = false;
                        end
                        
                        if frequencyDomainOk

                            % To find unique elements
                            uniqElement = unique({structureSimilaritElement.schemeName});
                            numberElement = length(uniqElement);

                            % To determind mean and max of status to elements
                            posAdd = zeros(numberElement,1);
                            meanElements = posAdd;
                            maxElements = posAdd; 
                            for i = 1:1:length(uniqElement)
                                structureTemp = structureSimilaritElement(...
                                    ismember({structureSimilaritElement.schemeName}, uniqElement(i)));

                                statusTemp = cell2mat({structureTemp.status});
                                meanElements(i,1) = mean(statusTemp(statusTemp >= enoughWithClassifiers));
                                maxElements(i,1) = max(statusTemp);
                            end

                            % To find most dangerous element
                            posMeanElement = find(max(meanElements) == meanElements);
                            posMaxElement = find(max(maxElements) == maxElements);
                            valueFind = posMeanElement(ismember(posMeanElement, posMaxElement));

                            if ~isempty(valueFind)
                                posAdd = valueFind;
                            else
                                % If max status of element don't coincides 
                                % with mean status of element, find mean in 
                                % maximum of status and mean of status. 
                                % Next choosen max between them
                                meanVectorWithMaxes = mean([meanElements(posMaxElement) maxElements(posMaxElement)], 2)';
                                meanVectorWithMeans = mean([meanElements(posMeanElement) maxElements(posMeanElement)], 2)';
                                
                                vectorTemp = [meanVectorWithMaxes meanVectorWithMeans];
                                vectorPos = [posMaxElement posMeanElement];
                                
                                posAdd = vectorPos(max(vectorTemp) == vectorTemp);
                            end

                            % To add status of timeDomain in decision
                            % maker
                            for i = 1:1:length(posAdd) 
                                positionAddElement = find(ismember({statusStruct.schemeName}, uniqElement(posAdd(i))));
                                statusTimeDomain = round(contributionTimeDomain * timeDomain.status);
                                for j = 1:1:length(positionAddElement)
                                    
                                    if statusStruct(positionAddElement(j)).status >= enoughWithClassifiers 
                                        
                                        addStruct.timeDomainClassifier.statusAll = statusTimeDomain;
                                        
                                        statusStruct(positionAddElement(j)).informativesTags = ...
                                            decisionMakerHistory.updateStruct(statusStruct(positionAddElement(j)).informativesTags, addStruct);
                                        
                                        statusStruct(positionAddElement(j)).status = ...
                                            statusStruct(positionAddElement(j)).status + statusTimeDomain;
                                    end
                                end

                            end

                        else
                            % To add unknown defect of element
                            statusStruct = decisionMakerHistory.addedTimeDomainUnknown(statusStruct, timeDomain, contributionTimeDomain);
                        end
                        
                        % Push to report
                        myDecisionMakerHistory.resultStruct = statusStruct;
                    end
                end
            end
            
        end
        
        % CHECKFORUNKNOWNDEFECT function add some methods in "unknown defect", if needed 
        function statusStruct = checkForUnknownDefect(myDecisionMakerHistory, tablePeriodicityOk)
            
            statusStruct = myDecisionMakerHistory.resultStruct;
            enoughWithClassifiers = str2double(myDecisionMakerHistory.config.decisionMaker.Attributes.enoughWithClassifiers)*100;            
            
            % To check not used metrics, which it have most danger
            if ~isempty(statusStruct(1).informativesTags)
                nameMetrics = fieldnames(statusStruct(1).informativesTags);
                numberMetrics = length(nameMetrics);
                statusMetrics = zeros(length(nameMetrics),1);
                numberDefects = length(statusStruct);
                
                % Table wich in row - defects, colum - nameMetrics
                tableStatusAndMetrics = zeros(numberDefects - 1, numberMetrics);
                
                % To evaluate each defects besides "unknown defect"
                for i = 2:1:numberDefects
                    if ~isempty(statusStruct(i).informativesTags)
                        nameMethodsForDefect = fieldnames(statusStruct(i).informativesTags);
                        
                        positionTrueMetrics = logical(cellfun(@(x) nnz(strcmpi(nameMethodsForDefect, x)), nameMetrics));
                        tableStatusAndMetrics(i-1, positionTrueMetrics) = statusStruct(i).status;
                        statusMetrics = statusMetrics + positionTrueMetrics; 
                    end
                end
                
                % To check metrics, that enough dangerous, but not
                % influence of defects
                numberPosAddedMetrics = find(statusMetrics);
                if ~isempty(numberPosAddedMetrics)
                    for i = 1:1:length(numberPosAddedMetrics)
                        if ~nnz(enoughWithClassifiers <= tableStatusAndMetrics(:, numberPosAddedMetrics(i)))
                            statusMetrics(numberPosAddedMetrics(i)) = 0;
                        end
                    end
                    
                    nameMetricsRemove = nameMetrics(logical(statusMetrics));
                    
                    statusStruct(1).informativesTags = rmfield(statusStruct(1).informativesTags, nameMetricsRemove);
                end
            end
            
            statusStruct = addPeriodicityToUnknownDefect(myDecisionMakerHistory, statusStruct, tablePeriodicityOk);
            
            deleteUnknownDefect = false;
            if isempty(statusStruct(1).informativesTags)
                
                deleteUnknownDefect = true;
            elseif isempty(fieldnames(statusStruct(1).informativesTags))
                
                deleteUnknownDefect = true;
            end
            
            if deleteUnknownDefect
                statusStruct(1).informativesTags = [];
                statusStruct(1).status = 0;
            else
                statusStruct(1).status = myDecisionMakerHistory.evaluateDefectsForAll(statusStruct(1));
            end
        end
        
        % ADDPERIODICITUTOUNKNOWNDEFECT function add periodicity method to
        % UNKNOWN DEFECT
        function statusStruct = addPeriodicityToUnknownDefect(myDecisionMakerHistory, statusStruct, tablePeriodicityOk)
            
            if nargin == 1
                statusStruct = myDecisionMakerHistory.resultStruct;
                tablePeriodicityOk = false(length(statusStruct),1);
            end
            
            % To add periodicity to unknown defect
            if isfield(myDecisionMakerHistory.statusStructXml, 'periodicity')
                
                frequences = str2num(myDecisionMakerHistory.statusStructXml.periodicity.informativeTags.frequency.Attributes.value);
                historyStatus = logical(str2num(myDecisionMakerHistory.statusStructXml.periodicity.informativeTags.historyValidity.Attributes.value));
                validFrequences = frequences(historyStatus);
                enoughWithClassifiers = str2double(myDecisionMakerHistory.config.decisionMaker.Attributes.enoughWithClassifiers)*100;            
                
                if ~isempty(validFrequences)
                    if nnz(tablePeriodicityOk)
                        
                        % To check status in classifier
                        if all(cellfun(@(x) x >= enoughWithClassifiers, {statusStruct(tablePeriodicityOk).status}))
                            addPeriodicity = false;
                        else
                            addPeriodicity = true;
                        end
                    else
                        addPeriodicity = true;
                    end
                    
                    if addPeriodicity 
                        contributionPeriodicity = 100*(str2double(myDecisionMakerHistory.config.decisionMaker.Attributes.contributionPeriodicity));
                        statusStruct(1).informativesTags.periodicity.statusAll = contributionPeriodicity;
                    end
                end
            end
        end
        
        % ADDSTATUSTOISO10816DEFECT function adds defect "ISO10816 LIMIT
        % EXCEEDING"
        function statusStruct = addStatusToIso10816Defect(myDecisionMakerHistory)
            
            statusStruct = myDecisionMakerHistory.resultStruct;
            
            if isfield(myDecisionMakerHistory.statusStructXml, 'metrics')
                if isfield(myDecisionMakerHistory.statusStructXml.metrics, 'velocity')
                    if isfield(myDecisionMakerHistory.statusStructXml.metrics.velocity.status, 'iso10816')
                        
                        % Get status and multiply by 100%
                        iso10816Status = round(double(str2numStatus.(myDecisionMakerHistory.statusStructXml.metrics.velocity.informativeTags.iso10816.Attributes.status)) * 100);
                        
                        % Create iso10816 defect
                        iso10816DefectNumber = length(statusStruct) + 1;
                        statusStruct(iso10816DefectNumber).class = 'equipment';
                        statusStruct(iso10816DefectNumber).schemeName = 'unknown001';
                        statusStruct(iso10816DefectNumber).tagNameElement = 'equipment';
                        statusStruct(iso10816DefectNumber).tagNameDefect = 'ISO10816_LIMIT_EXCEEDING';
                        statusStruct(iso10816DefectNumber).status = iso10816Status;
                        statusStruct(iso10816DefectNumber).informativesTags.iso10816.statusAll = iso10816Status;
                        statusStruct(iso10816DefectNumber).requiredMetrics = [];
                        statusStruct(iso10816DefectNumber).requiredPeriodicity = [];
                    end
                end
            end
            
        end
        
        % ADDSTATUSTOISO7919DEFECT function adds defects "ISO7919 LIMIT
        % EXCEEDING"
        function statusStruct = addStatusToIso7919Defect(myDecisionMakerHistory)
            
            statusStruct = myDecisionMakerHistory.resultStruct;
            
            if isfield(myDecisionMakerHistory.statusStructXml, 'iso7919')
                
                iso7919Struct = myDecisionMakerHistory.statusStructXml.iso7919;
                shaftNames = fieldnames(iso7919Struct.status);
                
                for shaftNumber = 1 : 1 : length(shaftNames)
                    
                    % Get status and multiply by 100%
                    iso7919Status = round(double(str2numStatus.(iso7919Struct.status.(shaftNames{shaftNumber}).Attributes.value)) * 100);
                    
                    % Create iso7919 defect
                    iso7919DefectNumber = length(statusStruct) + 1;
                    statusStruct(iso7919DefectNumber).class = 'shaft';
                    statusStruct(iso7919DefectNumber).schemeName = shaftNames{shaftNumber};
                    statusStruct(iso7919DefectNumber).tagNameElement = 'shaft';
                    statusStruct(iso7919DefectNumber).tagNameDefect = 'ISO7919_LIMIT_EXCEEDING';
                    statusStruct(iso7919DefectNumber).status = iso7919Status;
                    statusStruct(iso7919DefectNumber).periodicity.mainFrequency = nan(1);
                    statusStruct(iso7919DefectNumber).metrics = [];
                    
                    shaftStruct.iso7919.statusAll = iso7919Status;
                    statusStruct(iso7919DefectNumber).informativesTags = ...
                        myDecisionMakerHistory.updateStruct(statusStruct(iso7919DefectNumber).informativesTags, shaftStruct);
                end
            end
            
        end
        
        % ADDSTATUSTOVDI3834DEFECT function adds defects
        % "VDI3834 COMPONENT LIMIT EXCEEDING"
        function statusStruct = addStatusToVdi3834Defect(myDecisionMakerHistory)
            
            statusStruct = myDecisionMakerHistory.resultStruct;
            
            if isfield(myDecisionMakerHistory.statusStructXml, 'vdi3834')
                
                vdi3834Struct = myDecisionMakerHistory.statusStructXml.vdi3834;
                
                % Get component names
                componentNames = fieldnames(vdi3834Struct.status);
                
                for componentNumber = 1 : 1 : length(componentNames)
                    
                    % Get the component name
                    componentName = componentNames{componentNumber};
                    
                    % Get area names of the component
                    areaNames = fieldnames(vdi3834Struct.status.(componentName));
                    
                    areaStatuses = [];
                    
                    for areaNumber = 1 : 1 : length(areaNames)
                        
                        % Get the area name
                        areaName = areaNames{areaNumber};
                        
                        if ~isempty(vdi3834Struct.status.(componentName).(areaName))
                            areaStatuses = [areaStatuses, strsplit(vdi3834Struct.status.(componentName).(areaName).Attributes.value, ',')];
                        end
                    end
                    
                    % Get the max status and myltiply by 100%
                    maxComponentStatus = round(max(cellfun(@(status) double(str2numStatus.(status)), areaStatuses)) * 100);
                    
                    % Create the vdi3834 component defect
                    componentDefectNumber = length(statusStruct) + 1;
                    statusStruct(componentDefectNumber).class = 'equipment';
                    statusStruct(componentDefectNumber).schemeName = regexprep(componentName, '_(\d*)', '$1');
                    statusStruct(componentDefectNumber).tagNameElement = 'equipment';
                    if strfind(componentName, 'windTurbineConstruction')
                        statusStruct(componentDefectNumber).tagNameDefect = 'VDI3834_CONSTRUCTION_LIMIT_EXCEEDING';
                    elseif strfind(componentName, 'windTurbineRotor')
                        statusStruct(componentDefectNumber).tagNameDefect = 'VDI3834_ROTOR_LIMIT_EXCEEDING';
                    elseif strfind(componentName, 'windTurbineGearbox')
                        statusStruct(componentDefectNumber).tagNameDefect = 'VDI3834_GEARBOX_LIMIT_EXCEEDING';
                    elseif strfind(componentName, 'windTurbineGenerator')
                        statusStruct(componentDefectNumber).tagNameDefect = 'VDI3834_GENERATOR_LIMIT_EXCEEDING';
                    end
                    statusStruct(componentDefectNumber).status = maxComponentStatus;
                    statusStruct(componentDefectNumber).periodicity.mainFrequency = nan(1);
                    statusStruct(componentDefectNumber).metrics = [];
                    
                    componentStruct.vdi3834.statusAll = maxComponentStatus;
                    statusStruct(componentDefectNumber).informativesTags = ...
                        myDecisionMakerHistory.updateStruct(statusStruct(componentDefectNumber).informativesTags, componentStruct);
                end
                
                
            end
            
        end
        
        % PLOTDEFECTHISTORY function plot progressing of defect
        function plotDefectHistory(myDecisionMakerHistory)
            
            iLoger = loger.getInstance;
            
            tableStatuses = myDecisionMakerHistory.decisionMakerCompression.tableStatuses;
            
            schemeNameResult = {myDecisionMakerHistory.resultStruct.schemeName};
            defectNameResult = {myDecisionMakerHistory.resultStruct.tagNameDefect};

            schemeNameHistory = {tableStatuses.name};
            defectNameHistory = {tableStatuses.nameDefect};

            schemeNameStatus = ismember(schemeNameHistory, schemeNameResult);
            defectNameStatus = ismember(defectNameHistory, defectNameResult);
            
            numberDefects = length(defectNameHistory);
            
            if ~(nnz(and(schemeNameStatus, defectNameStatus)) == numberDefects)
                
                printWarning(iLoger, 'There are discrepancies in defects');
            end
            
            if length(myDecisionMakerHistory.decisionMakerCompression.vectorDate) > 2
                % Get parameters
                parameters.fontSize = str2double(myDecisionMakerHistory.config.plots.fontSize);
                parameters.imageFormat = myDecisionMakerHistory.config.plots.imageFormat;
                parameters.imageQuality = myDecisionMakerHistory.config.plots.imageQuality;
                parameters.imageResolution = myDecisionMakerHistory.config.plots.imageResolution;
                parameters.imageSize = str2num(myDecisionMakerHistory.config.plots.imageSize);
                parameters.sizeUnits = myDecisionMakerHistory.config.plots.sizeUnits;
                parameters.printPlotsEnable = str2double(myDecisionMakerHistory.config.plots.printPlotsEnable);
                parameters.visible = myDecisionMakerHistory.config.plots.visible;
                parameters.title = myDecisionMakerHistory.config.plots.title;
                parameters.actualPeriodName = myDecisionMakerHistory.config.translations.actualPeriod.Attributes.name;
                parameters.percentShortName = myDecisionMakerHistory.config.translations.percent.Attributes.shortName;
                parameters.statusName = myDecisionMakerHistory.config.translations.status.Attributes.name;
                
                vectorTime = myDecisionMakerHistory.decisionMakerCompression.vectorDate;
                
                % Set current status
                vectorStatusCurrent = [myDecisionMakerHistory.resultStruct.status];
                
                posNeedSave = false(numberDefects, 1);
                for i = 1:1:numberDefects
                    
                    posScheme = strcmpi(schemeNameResult, tableStatuses(i).name);
                    posDefect = strcmpi(defectNameResult, tableStatuses(i).nameDefect);
                    
                    posNeedDefect = and(posScheme, posDefect);
                    
                    statusTemp = vectorStatusCurrent(posNeedDefect);
                    
                    if statusTemp > 0
                        posNeedSave(i) = true(1,1);
                    end
                    
                    if any(posNeedDefect)
                        tableStatuses(i).compressedStatuses{end} = num2str(statusTemp);
                    end
                end
                
                tableStatusesDefect = tableStatuses(posNeedSave);
                
                numVector = 1:1:length(vectorTime);
                % Plot each defect
                for i = 1:1:nnz(posNeedSave)
                    myDecisionMakerHistory.plotDefect(tableStatusesDefect(i), vectorTime, numVector, parameters)
                end
            end
        end
    end
    
    methods (Static)
        
        % FILLINGSTATUSESCLASSIFIER function is comparing status 
        % frequency and time-frequency classifiers. Writing 
        % informative fields for one defect
        function struct = fillingStatusesClassifier(frequencyStruct, timeFrequencyStruct)
            
            % To create empty result defect
            if (isstruct(timeFrequencyStruct) && isstruct(frequencyStruct)) || ...
                (isstruct(frequencyStruct) && ~isstruct(timeFrequencyStruct))
                
                struct = decisionMakerHistory.fillingCommonClassifier(frequencyStruct);
            else
                struct = decisionMakerHistory.fillingCommonClassifier(timeFrequencyStruct(1));
            end
            
            % To fill data for time-frequecny classifier
            if isstruct(timeFrequencyStruct)
                
                % To create empty informatives tags with time-frequecny
                % classifier
                numbersTimeFrequencyStructs = length(timeFrequencyStruct);
                nameExist = arrayfun(@(x) ['timeFrequencyClassifierResonans' num2str(x{1,1})], ...
                            num2cell(1:1:numbersTimeFrequencyStructs), 'UniformOutput', false);
                struct.informativesTags = cell2struct(cell(numbersTimeFrequencyStructs, 1), nameExist, 1);
                
                % To fill data for time-frequecny classifier
                for i = 1:1:numbersTimeFrequencyStructs
                    struct.informativesTags.(nameExist{i}) = ...
                        decisionMakerHistory.fillingInformativeTagsClassifier(timeFrequencyStruct(i));
                end
            end
            
            % To fill data for frequecny classifier
            if isstruct(frequencyStruct)
                 
                struct.informativesTags.frequencyClassifier = ...
                    decisionMakerHistory.fillingInformativeTagsClassifier(frequencyStruct);
            end
        end
        
        % CREATEEMPTYRESULTSTRUCT function is creating result struct
        % with empty fields for frequency and time-frequency domains
        function statusStruct = createEmptyResultStruct(numberDefects)
            
            statusStruct(numberDefects).class = [];
            statusStruct(numberDefects).schemeName = [];
            statusStruct(numberDefects).tagNameElement = [];
            statusStruct(numberDefects).tagNameDefect = [];
            statusStruct(numberDefects).status = [];
            statusStruct(numberDefects).informativesTags = [];
            statusStruct(numberDefects).requiredMetrics = [];
            statusStruct(numberDefects).requiredPeriodicity = [];
        end
        
        % CREATEEMPTYSTATUSWITH2DEFECTS function is creating empty defects:
        % UNIDENTIFIED_DEFECT and LUBRICATION_DEFECT
        function statusStruct = createEmptyStatusWith2Defects()
            
            % Create empty unknown defect
            statusStruct(1).class = 'equipment';
            statusStruct(1).schemeName = 'unknown001';
            statusStruct(1).tagNameElement = 'equipment';
            statusStruct(1).tagNameDefect = 'UNIDENTIFIED_DEFECT';
            statusStruct(1).status = 0;
            statusStruct(1).informativesTags = [];
            statusStruct(1).requiredMetrics.name = [{'metrics'} {'spmLRHR'} {'iso15242'} {'octaveSpectrum'} {'scalogram'}];
            statusStruct(1).requiredMetrics.weight = [1 1 1 1 1];
            statusStruct(1).requiredPeriodicity = [];
            
            % Create empty lubrication defect
            statusStruct(2).class = 'rollingBearing';
            statusStruct(2).schemeName = 'unknown002';
            statusStruct(2).tagNameElement = 'bearing';
            statusStruct(2).tagNameDefect = 'LUBRICATION_DEFECT';
            statusStruct(2).status = 0;
            statusStruct(2).informativesTags = [];
            statusStruct(2).requiredMetrics.name = [{'spmLRHR'} {'metrics_acceleration_noiseLog'}];
            statusStruct(2).requiredMetrics.weight = [0.5 0.5];
            statusStruct(2).requiredPeriodicity = [];
        end
        
        % CREATEELEMENTNODE function is creating element for doc node
        function elementNode = createElementNode(docNode, elementStatusStruct)
            % Create element node
            elementNode = docNode.createElement('element');
            % Set attributes of element node
            elementNode.setAttribute('tagName', elementStatusStruct(1).tagNameElement);
            elementNode.setAttribute('class', elementStatusStruct(1).class);
            elementNode.setAttribute('schemeName', elementStatusStruct(1).schemeName);
            
            % Get defect tag names in each space
            defectTagNames = {elementStatusStruct.tagNameDefect};
            
            for i = 1:1:length(defectTagNames)
                currentDefectName = defectTagNames{i};
                
                % Create defect node
                defectNode = docNode.createElement('defect');
                % Set attributes of defect node
                defectNode.setAttribute('tagName', currentDefectName);
                defectNode.setAttribute('status', num2str(round(elementStatusStruct(i).status)));

                % Create informativeTags node
                informativeTagsNode = docNode.createElement('informativeTags');
                
                % Check every informativeTags
                if ~isempty(elementStatusStruct(i).informativesTags)
                    nameMethods = fieldnames(elementStatusStruct(i).informativesTags);
                    
                    % To add time-frequency classifier in one line to
                    % status
                    posTimeFrequency = cellfun(@(x) contains(x, 'timeFrequencyClassifierResonans'), nameMethods);
                    numberResonans = nnz(posTimeFrequency);
                    if numberResonans
                        nameMethodsTemp = cell(length(nameMethods) - numberResonans + 1, 1);
                        
                        if length(nameMethodsTemp) ~= 1
                            nameMethodsTemp(1:end-1) = nameMethods(~posTimeFrequency);
                        end
                        nameMethodsTemp{end} = 'timeFrequencyClassifier';
                        
                        statusTemp = zeros(1, numberResonans);
                        nameTimeFrequency = nameMethods(posTimeFrequency);
                        for j = 1:1:numberResonans
                            statusTemp(1, j) = elementStatusStruct(i).informativesTags.(nameTimeFrequency{j}).statusAll;
                        end
                        
                        elementStatusStruct(i).informativesTags.timeFrequencyClassifier.statusAll = statusTemp;
                        nameMethods = nameMethodsTemp;
                    end
                    
                    for j = 1:1:length(nameMethods)
                        nameMethodsNode = docNode.createElement(nameMethods{j});
                        if ~isempty(elementStatusStruct(i).informativesTags.(nameMethods{j}))
                            value = round(elementStatusStruct(i).informativesTags.(nameMethods{j}).statusAll);
                            nameMethodsNode.setAttribute('status', vector2strStandardFormat(value));
                            informativeTagsNode.appendChild(nameMethodsNode);
                        end  
                    end
                end
                
                % Set informativeTags node to defect node
                defectNode.appendChild(informativeTagsNode);
                % Set defect node to element node
                elementNode.appendChild(defectNode);
            end
        end

        % XMLSTRUCTTOTABLE function create table of defects from .xml
        function structMethod = xmlStructToTable(structXml)
            
            numbersElements = length(structXml.element);
            
            % Checking the number of defects for current type of element
            % Write one defect in a cell as well as several defects
            if isstruct(structXml.element)
                currentElement = structXml.element;
                structXml.element = [];
                structXml.element{1,1} = currentElement;
            end
            numberDefects = 0;
            for elementNum = 1:1:numbersElements
                numberDefects = numberDefects + length(structXml.element{1, elementNum}.defect);
                if isstruct(structXml.element{1, elementNum}.defect)
                    currentDefects = structXml.element{1, elementNum}.defect;
                    structXml.element{1, elementNum}.defect = [];
                    structXml.element{1, elementNum}.defect{1, 1} = currentDefects;
                end
            end
            
            % To create empty result table 
            structMethod(numberDefects).class = [];
            structMethod(numberDefects).schemeName = [];
            structMethod(numberDefects).tagNameElement = [];
            structMethod(numberDefects).tagNameDefect = [];
            structMethod(numberDefects).similarity = [];
            structMethod(numberDefects).similarityTrend = [];
            structMethod(numberDefects).level = [];
            structMethod(numberDefects).historyDanger = [];
            structMethod(numberDefects).historySimilarity = [];
            structMethod(numberDefects).durationLevel = [];
            
            % To fill empty result table through .xml
            numDefects = 1;
            for i = 1:1:numbersElements
                numberDefectsElement = length(structXml.element{1, i}.defect);
                
                for j = 1:1:numberDefectsElement
                    structMethod(numDefects).class = structXml.element{1, i}.Attributes.class;
                    structMethod(numDefects).schemeName = structXml.element{1, i}.Attributes.schemeName;
                    structMethod(numDefects).tagNameElement = structXml.element{1, i}.Attributes.tagName;
                    structMethod(numDefects).tagNameDefect = structXml.element{1, i}.defect{1, j}.Attributes.tagName;
                    structMethod(numDefects).similarity = str2double(structXml.element{1, i}.defect{1, j}.status.Attributes.similarity);
                    structMethod(numDefects).similarityTrend = str2double(structXml.element{1, i}.defect{1, j}.status.Attributes.similarityTrend);
                    structMethod(numDefects).level = structXml.element{1, i}.defect{1, j}.status.Attributes.level;
                    structMethod(numDefects).historyDanger = str2double(structXml.element{1, i}.defect{1, j}.status.Attributes.historyDanger);
                    structMethod(numDefects).historySimilarity = str2double(structXml.element{1, i}.defect{1, j}.status.Attributes.historySimilarity);
                    structMethod(numDefects).durationLevel = str2double(structXml.element{1, i}.defect{1, j}.status.Attributes.durationLevel);
                    
                    numDefects = numDefects + 1;
                end
            end
        end
        
        % FILLINGCOMMONCLASSIFIER function fill common fileds from .xml 
        % for result table
        function stuctureOutput = fillingCommonClassifier(structureInput)
            if structureInput.similarity == -1
                stuctureOutput.status = -1;
            else
                stuctureOutput.status = 0;
            end
            stuctureOutput.class = structureInput.class;
            stuctureOutput.schemeName = structureInput.schemeName;
            stuctureOutput.tagNameElement = structureInput.tagNameElement;
            stuctureOutput.tagNameDefect = structureInput.tagNameDefect;
            stuctureOutput.requiredMetrics = [];
            stuctureOutput.requiredPeriodicity = [];
        end
        
        % FILLINGINFORMATIVETAGSCLASSIFIER function fill information for
        % each defect and evaluate status of defect through 3
        % parameters:similarity, trend of similarity, history danger
        function stuctureOutput = fillingInformativeTagsClassifier(structureInput)
            stuctureOutput.similarity = structureInput.similarity;
            stuctureOutput.similarityTrend = structureInput.similarityTrend;
            stuctureOutput.historyDanger = structureInput.historyDanger;
            stuctureOutput.historySimilarity = structureInput.historySimilarity;
            
            if stuctureOutput.historySimilarity ~= -1
                
                % To determined status between historyDanger and
                % historySimilarity
                status = [structureInput.historySimilarity structureInput.historyDanger];
                stuctureOutput.statusAll = (max(status) + mean(status))/2;
            else
                stuctureOutput.statusAll = -1;
            end
        end

        % FILLINGMETRICS function fill required metrics to defect in
        % decison maker structure
        function statusStruct = fillingMetrics(statusStruct, rowStatusStruct, parameters)
            
            % If defect is enabled
            if statusStruct.status ~= -1
                iLoger = loger.getInstance;
                nameMethods = fieldnames(rowStatusStruct);

                % Write name all methods and corresponding them function
                % names
                nameAllMethods = ...
                    {'metrics',    'octaveSpectrum', 'scalogram', 'iso15242',    'spmLRHR'};
                functionNameMethods = ...
                    {'addMetrics', 'addOctave',      'addOctave', 'addIso15242', 'addSmpLRHR'};

                % To add methods to informativeTags of decision maker
                for i = 1:1:length(nameAllMethods)
                    
                    nameEnough = ['enough' upperCase(nameAllMethods{i}, 'firstWithoutChanges')];
                    metricsPos = cellfun(@(x) ~isempty(strfind(x, nameAllMethods{i})), ...
                                                    statusStruct.requiredMetrics.name);
                    existMethod = nnz(strcmp(nameMethods, nameAllMethods{i}));
                    
                    % To check exist method and name metrics in raw status
                    % struct
                    if nnz(metricsPos) && ~existMethod
                        printComputeInfo(iLoger, 'Decision Maked history', ['Method of ' nameAllMethods{i} ' turned off.']);
                    end
                    if nnz(metricsPos) && existMethod
                        metricsStruct.name = statusStruct.requiredMetrics.name(metricsPos);
                        metricsStruct.weight = statusStruct.requiredMetrics.weight(metricsPos);
                            
                        % To add methods
                        structMetrics = feval(['decisionMakerHistory.' functionNameMethods{i}], ...
                                                rowStatusStruct.(nameAllMethods{i}), metricsStruct, str2double(parameters.(nameEnough))* 100);
                        statusStruct.informativesTags = ...
                            decisionMakerHistory.updateStruct(statusStruct.informativesTags, structMetrics);
                    end
                end
            end
        end
        
        % ADDMETRICS function add all enabled metrics to decision maker
        function structureOutPut = addMetrics(rowStatusStruct, metricsStruct, enoughMetrics)
            
            % If is required evaluation of all enabled metrics
            if nnz(cellfun(@(x) length(x) == 7, metricsStruct.name))
                
                % To fill all exist metrics in .xml
                nameDomain = fieldnames(rowStatusStruct);
                
                % Max numbers of metrics
                tempNameAllMetrics = cell(1,33);
                
                % To fill first domain
                nameAllMetricsDomain = fieldnames(rowStatusStruct.(nameDomain{1}).status);
                numberAllMetrics = length(nameAllMetricsDomain);
                tempNameAllMetrics(1:numberAllMetrics) = cellfun(@(x) ['metrics_' nameDomain{1} '_' x], nameAllMetricsDomain, 'UniformOutput', false);
                
                % To fill next domain
                for i = 2:1:length(nameDomain)
                    nameAllMetricsDomain = fieldnames(rowStatusStruct.(nameDomain{i}).status);
                    numbeCurrent = length(nameAllMetricsDomain);
                    tempNameAllMetrics(numberAllMetrics + 1 : numberAllMetrics + numbeCurrent) = ...
                        cellfun(@(x) ['metrics_' nameDomain{i} '_' x], nameAllMetricsDomain, 'UniformOutput', false);
                    
                    numberAllMetrics = numberAllMetrics + numbeCurrent;
                end
                
                tempNameAllMetrics = tempNameAllMetrics(~cellfun(@isempty, tempNameAllMetrics));
                
                
                % To prepare structure for processing
                metricsStruct.name = tempNameAllMetrics;
                numberMetricsAll = length(metricsStruct.name); 
                tempWeight = metricsStruct.weight;
                metricsStruct.weight = zeros(1,numberMetricsAll);
                metricsStruct.weight(1:end) = tempWeight;
                existMetrics = ones(numberMetricsAll,1);
                metricsTempName = cellfun(@(x) x(9:end), metricsStruct.name, 'UniformOutput', false);
            else
                % Delete word "metrics"
                metricsTempName = cellfun(@(x) x(9:end), metricsStruct.name, 'UniformOutput', false);

                % To check exist metrics in status.xml
                numberMetrics = length(metricsTempName);
                existMetrics = zeros(numberMetrics, 1);
                for i = 1:1:numberMetrics
                    tempName = split(metricsTempName(i), '_');
                    if isfield(rowStatusStruct, tempName{1})
                        if isfield(rowStatusStruct.(tempName{1}).status, tempName{2})
                            existMetrics(i) = 1;
                        end
                    end
                end
            end
            
            numberExistMetrics = nnz(existMetrics);
            if numberExistMetrics
                existMetrics = logical(existMetrics);
                metricsStructTemp.name = metricsTempName(existMetrics);
                metricsStructTemp.weight = metricsStruct.weight(existMetrics);
                
                % To prepare metrics name for informatives tags
                nameExist = metricsStruct.name(existMetrics);
                structureOutPut = cell2struct(cell(numberExistMetrics, 1), nameExist, 1);
                
                % To add metrics to decision maker structure
                for i = 1:1:numberExistMetrics
                    tempName = split(metricsStructTemp.name(i), '_');
                    statusStructTemp.status = ...
                        str2double(rowStatusStruct.(tempName{1}).status.(tempName{2}).Attributes.value);
                    statusStructTemp.weight = metricsStructTemp.weight(i) * 100;
                    
                    if statusStructTemp.weight < 0
                        switch decisionMakerHistory.determineStateClassfierStatuses(statusStructTemp.status)
                            case 2
                                statusTemp = abs(statusStructTemp.weight);
                            otherwise 
                                statusTemp = 0;
                        end
                        
                        statusStructTemp.statusAll = statusTemp;
                        structureOutPut.(nameExist{i}) = statusStructTemp;
                    else
                        if statusStructTemp.status >= enoughMetrics

                            % To evaluate metric with history information
                            if isempty(strfind(tempName{2,1}, 'unidentifiedPeaksNumbers'))
                                switch decisionMakerHistory.determineStateClassfierStatuses(statusStructTemp.status)
                                    case 3
                                        statusTemp = (statusStructTemp.weight * 0.5);
                                    case 4
                                        statusTemp = statusStructTemp.weight;
                                    otherwise
                                        statusTemp = 0;
                                end
                            else
                                statusTemp = statusStructTemp.status;
                            end
                            
                            statusStructTemp.statusAll = statusTemp;
                            structureOutPut.(nameExist{i}) = statusStructTemp;
                        else
                            statusStructTemp.statusAll = 0;
                            structureOutPut.(nameExist{i}) = statusStructTemp;
                        end
                    end
                    structureOutPut.(nameExist{i}).statusAll = round(structureOutPut.(nameExist{i}).statusAll);
                end
            else
                structureOutPut = [];
            end
        end
        
        % ADDOCTAVE function add method octave spectrum and scalogramm to
        % decision maker
        function structureOutPut = addOctave(rowStatusStruct, metricsStruct, enoughOctaveOrScalogram)
            
            metricsStruct.weight = metricsStruct.weight(1);
            
            % To get name of method and required range 
            rangeOctaves = strsplit(metricsStruct.name{1}, '_');
            nameMethod = rangeOctaves{1}; 
           
            structureOutPut = cell2struct(cell(1, 1), nameMethod, 1);
                    
            structureOutPut.(nameMethod).frequency = str2num(rowStatusStruct.informativeTags.frequencies.Attributes.value);
            structureOutPut.(nameMethod).status = str2num(rowStatusStruct.status.Attributes.value);
            
            if length(rangeOctaves) == 2
                rangeOctaves = rangeOctaves{2};
                rangeOctaves = cellfun(@str2double, strsplit(rangeOctaves, ':'));
            else
                rangeOctaves = [0 NaN]; 
            end
                
            % To get status with required range 
            posFirst = find(rangeOctaves(1) > structureOutPut.(nameMethod).frequency, 1, 'last');
            if isempty(posFirst)
                posFirst = 1;
            end
            if nnz(isnan(rangeOctaves))
                posLast = length(structureOutPut.(nameMethod).frequency);
            else
                posLast = find(rangeOctaves(2) < structureOutPut.(nameMethod).frequency, 1, 'first');
            end
            
            % To fill method to staus struct
            structureOutPut.(nameMethod).requirementFrequency = structureOutPut.(nameMethod).frequency(posFirst:posLast);
            structureOutPut.(nameMethod).requirementStatuses = structureOutPut.(nameMethod).status(posFirst:posLast);
            structureOutPut.(nameMethod).weight = metricsStruct.weight;
            structureOutPut.(nameMethod).statusAll = max(structureOutPut.(nameMethod).requirementStatuses);
            
            if structureOutPut.(nameMethod).statusAll < enoughOctaveOrScalogram
                structureOutPut.(nameMethod).statusAll = 0;
            else
                structureOutPut.(nameMethod).statusAll = structureOutPut.(nameMethod).statusAll * metricsStruct.weight;
            end
        end
        
        % ADDISO15242 function add method iso15242 to decision maker
        function structureOutPut = addIso15242(rowStatusStruct, metricsStruct, enoughIso15242)
            
            % To get name of method
            names = strsplit(metricsStruct.name{1}, '_');
            nameMethod = names{1}; 
            
            structureOutPut = cell2struct(cell(1, 1), nameMethod, 1);
            
            % To fill basic data to informatives tags
            structureOutPut.(nameMethod).vRms1Log = str2double(rowStatusStruct.status.vRms1Log.Attributes.statusOfHistory);
            structureOutPut.(nameMethod).vRms2Log = str2double(rowStatusStruct.status.vRms2Log.Attributes.statusOfHistory);
            structureOutPut.(nameMethod).vRms3Log = str2double(rowStatusStruct.status.vRms3Log.Attributes.statusOfHistory);
            
            % To get status with specific metrics
            if length(names) == 1
                structureOutPut.(nameMethod).statusAll = str2double(rowStatusStruct.status.Attributes.value) ...
                    * metricsStruct.weight(1);
            else
                names{2}(1) = upper(names{2}(1));
                nameMetrics = ['status' names{2}];
                
                structureOutPut.(nameMethod).statusAll = str2double(rowStatusStruct.status.Attributes.(nameMetrics)) ...
                    * metricsStruct.weight(1);
            end
            
            if structureOutPut.(nameMethod).statusAll < enoughIso15242
                structureOutPut.(nameMethod).statusAll = 0;
            end
        end
        
        % ADDSPMLRHR function add method spmLrHr to decision maker
        function structureOutPut = addSmpLRHR(rowStatusStruct, metricsStruct, enoughSpmLRHR)
            
            % To get name of method
            names = strsplit(metricsStruct.name{1}, '_');
            nameMethod = names{1}; 
            
            structureOutPut = cell2struct(cell(1, 1), nameMethod, 1);
            
            % To get status with specific metrics
            structureOutPut.(nameMethod).LR = str2double(rowStatusStruct.status.lR.Attributes.statusOfHistory);
            structureOutPut.(nameMethod).HR = str2double(rowStatusStruct.status.hR.Attributes.statusOfHistory);
            structureOutPut.(nameMethod).Delta = str2double(rowStatusStruct.status.delta.Attributes.statusOfHistory);
            
            if length(names) == 1
                structureOutPut.(nameMethod).statusAll = ...
                    str2double(rowStatusStruct.status.Attributes.value) * metricsStruct.weight(1);
            else
                iLoger = loger.getInstance;
                printComputeInfo(iLoger, 'Decision Maker history', 'Incorrect input argument in spmLRHR in informativeTags.xml');
                structureOutPut.(nameMethod).statusAll = 0;
            end
            
            if structureOutPut.(nameMethod).statusAll < enoughSpmLRHR 
                structureOutPut.(nameMethod).statusAll = 0;
            end
        end
        
        % UPDATESTRUCT function update structure of informative tags with
        % requered informations
        function updatedStruct = updateStruct(previousStruct, addStruct)
            
            if ~isempty(addStruct)
                
                % Prepare for to update
                if isempty(previousStruct)
                    
                    nameAdd = fieldnames(addStruct);
                    numberAdd = length(nameAdd);
                    numberFields = numberAdd;
                    nameFields = cell(numberFields,1);
                    nameFields(1:numberFields) = nameAdd;
                else
                    namePrevious = fieldnames(previousStruct);
                    nameAdd = fieldnames(addStruct);
                    numberPrevious = length(namePrevious);
                    numberAdd = length(nameAdd);
                    numberFields = numberPrevious + numberAdd;
                    nameFields = cell(numberFields,1);
                    nameFields(1:numberPrevious) = namePrevious;
                    nameFields(numberPrevious+1:numberFields) = nameAdd; 
                end
                
                updatedStruct = cell2struct(cell(numberFields, 1), nameFields, 1);
                
                % To add previous struct to updateStruct
                if ~isempty(previousStruct)
                    for i = 1:1:numberPrevious
                        updatedStruct.(namePrevious{i}) = previousStruct.(namePrevious{i});
                    end
                end
                    
                % To add required struct to updateStruct
                for i = 1:1:numberAdd
                    updatedStruct.(nameAdd{i}) = addStruct.(nameAdd{i});
                end
                
            else
                updatedStruct = previousStruct;
            end
        end
        
        % EVALUATEDEFECTSFORALL function evaluate status of defect through
        % exist informatives tags
        function status = evaluateDefectsForAll(statusStruct, enoughFrequencyClassifiers)
            
            if isempty(statusStruct.informativesTags)
                status = 0;
            else
                
                % To get status each methods
                nameMethods = fieldnames(statusStruct.informativesTags);
                numberMethods = length(nameMethods);
                
                vectorStatus = zeros(numberMethods,1);
                for i = 1:1:numberMethods
                    if ~isempty(statusStruct.informativesTags.(nameMethods{i}))
                        vectorStatus(i, 1) = statusStruct.informativesTags.(nameMethods{i}).statusAll;
                    end
                end
 
                % If evaluate UNIDENTIFIED_DEFECT
                if strcmpi(statusStruct.tagNameDefect, 'UNIDENTIFIED_DEFECT')
                    status = max(vectorStatus);
                    return
                end
                
                % To exclude timeFrequencyClassifier and frequencClassifier
                % from decisonMaker, to use only maximum between them
                posTimeFrequencyClassifeir = cellfun(@(x) contains(x, 'timeFrequencyClassifierResonans'), nameMethods);
                posFrequencyClassifeir = strcmpi(nameMethods, 'frequencyClassifier');
                posAllClassifiers = logical(posTimeFrequencyClassifeir + posFrequencyClassifeir);
                if nnz(posTimeFrequencyClassifeir) && nnz(posFrequencyClassifeir)
                    
                    % To check enough status of classifier
                    vectorStatus(vectorStatus(posAllClassifiers) < enoughFrequencyClassifiers) = 0;
                    
                    % To find max and write it to status
                    maxClassifier = max(vectorStatus(posAllClassifiers));
                    vectorStatus(posFrequencyClassifeir) = maxClassifier;
                    vectorStatus(posTimeFrequencyClassifeir) = 0;
                    
                elseif nnz(posTimeFrequencyClassifeir)
                    
                    vectorStatus(vectorStatus(posTimeFrequencyClassifeir) < enoughFrequencyClassifiers) = 0;
                    % To find max and write it to status
                    maxClassifier = max(vectorStatus(posTimeFrequencyClassifeir));
                    vectorStatus(posTimeFrequencyClassifeir) = 0;
                    vectorStatus(posTimeFrequencyClassifeir(1,1)) = maxClassifier;
                end
                
                % To sum status each methods
                status = sum(vectorStatus);
            end
        end
        
        % ADDEDTIMEDOMAINUNKNOWN function add "UNKNOWN DEFECT" to timeDomainClassifier 
        function statusStruct = addedTimeDomainUnknown(statusStruct, timeDomain, contributionTimeDomain)
            
            % To find privious unknown defects
            positionUnknownDef = contains({statusStruct.schemeName}, 'unknown');
            
            % To increase on one numbers defects and countment unknown defects
            cntStartFill = strtrim(num2str(nnz(positionUnknownDef) + 1));
            numberElementAdd = length(statusStruct) + 1;
            
            % To prepare some fields to status struct
            if length(cntStartFill) == 1
                schemeName = ['unknown00' cntStartFill];
            elseif length(cntStartFill) == 2
                schemeName = ['unknown0' cntStartFill];
            else
                schemeName = ['unknown' cntStartFill];
            end
%             status = contributionTimeDomain*timeDomain.status;
            status = timeDomain.status;
            
            % To add information to status struct
            statusStruct(numberElementAdd).tagNameDefect = ['UNIDENTIFIED_' upperCase(timeDomain.element)];
            statusStruct(numberElementAdd).tagNameElement = timeDomain.element;
            statusStruct(numberElementAdd).schemeName = schemeName;
            statusStruct(numberElementAdd).class = 'equipment';
            statusStruct(numberElementAdd).status = status;    
            statusStruct(numberElementAdd).informativesTags.timeDomainClassifier.statusAll = status;
            statusStruct(numberElementAdd).requiredMetrics = [];
        end
        
        % EVALUATEHISTORYTIMECLASSIFIER function evaluate similarity of
        % timeDomain with similarityTrend
        function status = evealuateHistoryTimeClassifier(timeDomain)
            
            statusTrend = decisionMakerHistory.evaluateTrend(timeDomain.similarityTrend);
            
            % Trend is decline
            if  statusTrend == -1 
                status = timeDomain.similarity*(1-0.1); 
                
            % Trend is mb_decline, stable, md_growing
            elseif statusTrend == 0
                status = timeDomain.similarity;
                
            % Trend is growing  
            elseif statusTrend == 1
                status = timeDomain.similarity*(1+0.2);
                
            % Trend is unknown
            else
                status = timeDomain.similarity*0.5;
            end
        end
        
        % 1 - no dengerous, 2 - green zone, 3 - yellow zone(maintenance),
        % 4 - red zone (critaical)
        function status = determineStateClassfierStatuses(value)
            
            if value < 25
                status = 1;
            elseif value >= 25 && value < 50
                status = 2;
            elseif value >= 50 && value < 75
                status = 3;
            else
                status = 4;
            end
        end
        
        % -1 - decline trend, 0 - stable trend 1 - increase trend, 1.5 -
        % unknown trend
        function status = evaluateTrend(value)
            % Trend is decline
            if  value <= -0.75 
                status = -1; 
                
            % Trend is mb_decline, stable, md_growing
            elseif value > -0.75 && value < 0.75
                status = 0;
                
            % Trend is growing  
            elseif value >= 0.75 && value < 1.25
                status = 1;
                
            % Trend is unknown
            else
                status = 1.5;
            end
        end
        
        % PLOTDEFECT function plot each progressing of defect 
        function plotDefect(tableStatuses, vectorTime, numVector, parameters)
            
            myFigure = figure('Units', parameters.sizeUnits, 'Position', parameters.imageSize, 'Visible', ...
                               parameters.visible, 'Color', 'w');
                           
            yValue = cellfun(@str2double, tableStatuses.compressedStatuses);
            yValue(yValue == -1) = 0;
            plot(numVector, yValue, 'LineWidth', 2);

            % Get axes data
            myAxes = myFigure.CurrentAxes;
            % Set axes font size
            myAxes.FontSize = parameters.fontSize;
            
            if strcmp(parameters.title, 'on')
                title(myAxes,['Element - ' tableStatuses.name ' : ' regexprep(tableStatuses.nameDefect, '_', ' ')])
            end

            xlabel(myAxes, upperCase(parameters.actualPeriodName, 'first'));
            ylabel(myAxes, [upperCase(parameters.statusName, 'first') ', ' parameters.percentShortName]);
                  
            xticks(myAxes, numVector);
            xticklabels(myAxes, vectorTime);
            xtickangle(myAxes, 90);
            
            grid on
            
            if parameters.printPlotsEnable
                % Save the image to the @Out directory
                fileName = ['history-' tableStatuses.tagName '-' tableStatuses.name '-' tableStatuses.nameDefect];
                fullFileName = fullfile(pwd, 'Out', fileName);
                print(myFigure, fullFileName, ['-d', parameters.imageFormat, parameters.imageQuality], ...
                                              ['-r', parameters.imageResolution]);
            end
            
            % Close figure with visibility off
            if strcmpi(parameters.visible, 'off')
                close(myFigure)
            end
        end
    end
end


