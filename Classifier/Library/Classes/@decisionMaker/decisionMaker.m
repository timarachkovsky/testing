classdef decisionMaker
   % Class is decision maker for several methods without history
    
    properties (Access = private)
        % Input properties
        config
        
        mySchemeClassifier
        iso10816Struct
        periodicityTable
        myTimeFrequencyClassifier
        File
        timeDomain
        iso7919Struct
        shaftTrajectory
        vdi3834Struct
        
        % Output properties
        resultStruct
    end
    
    methods (Access = public)
        % Constructor
        function [myDecisionMaker] = decisionMaker(config, statuses)
            
            % Filling basic properties
            myDecisionMaker.mySchemeClassifier = statuses.mySchemeClassifier;
            myDecisionMaker.iso10816Struct = statuses.structureIso10816;
            myDecisionMaker.periodicityTable = statuses.periodicityTable;
            myDecisionMaker.myTimeFrequencyClassifier = statuses.myTimeFrequencyClassifier;
            myDecisionMaker.File = statuses.File;
            
            % DUMMY --
                if ~isempty(statuses.patternResult)
                    if nnz(~cellfun(@isempty, strfind(statuses.patternResult.element, 'generator')))
                        statuses.patternResult.element = {'motor'};
                    end
                end
            % -- DUMMY
            myDecisionMaker.timeDomain = statuses.patternResult;
            
            myDecisionMaker.iso7919Struct = statuses.structureIso7919;
            myDecisionMaker.shaftTrajectory = statuses.shaftTrajectoryStatus;
            myDecisionMaker.vdi3834Struct = statuses.structureVdi3834;
            
            myDecisionMaker.config.peakComparison = ...
                config.config.parameters.evaluation.decisionMaker.peakComparison;
            myDecisionMaker.config.decisionMaker = ...
                config.config.parameters.evaluation.decisionMaker.decisionMaker;
            
            myDecisionMaker.resultStruct = myDecisionMaker.createEmptyStatusWith2Defects();
        end
        
        % PROCESSINGDECISIONMAKER main function of decision maker for calculation
        function [myDecisionMaker] = processingDecisionMaker(myDecisionMaker)
            
            % To check enable of timeFrequencyClassifier
            parameters.decisionMaker = myDecisionMaker.config.decisionMaker.Attributes;
            if ~isempty(myDecisionMaker.myTimeFrequencyClassifier)
                if ~isempty(myDecisionMaker.myTimeFrequencyClassifier.objectsStruct)
                    enableTimeFrequencyClassifier = 1;
                else
                    enableTimeFrequencyClassifier = 0;
                end
            else
                enableTimeFrequencyClassifier = 0;
            end
            
            % To choose calculation with known elements ot unknown 
            if ~isempty(myDecisionMaker.mySchemeClassifier) || enableTimeFrequencyClassifier
                
                myDecisionMaker.resultStruct = compareClassifier(myDecisionMaker, enableTimeFrequencyClassifier);                 
                parameters.peakComparison = myDecisionMaker.config.peakComparison.Attributes;
                parameters.enableTimeFrequencyClassifier = enableTimeFrequencyClassifier;
                
                % Decision maker base on theed method: time, frequency
                % domain, iso 10816, iso 7919, shaft trajectory
                myDecisionMaker = decisionMakerWithFrequencyDomain(myDecisionMaker, parameters);
            else
                % Decision maker base on one/two method: time domain and/or iso 10816
                myDecisionMaker.resultStruct = decisionMakerWithoutFrequencyDomain(myDecisionMaker, parameters.decisionMaker);
            end
        end
        
        % Getters/Setters
        function mySchemeClassifier = getSchemeClassifierObject(myDecisionMaker)
            mySchemeClassifier = myDecisionMaker.mySchemeClassifier;
        end
        function resultStruct = getResultStruct(myDecisionMaker)
            resultStruct = myDecisionMaker.resultStruct;
        end
        
        % FILLDOCNODE function add to informative tags in docNode structure 
        function docNode = fillDocNode(myDecisionMaker, docNode)
            statusStruct = myDecisionMaker.resultStruct;
            
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
                elementNode = myDecisionMaker.createElementNode(docNode, elementStatusStruct);
                decisionMakerNode.appendChild(elementNode);
            end
            % Create docRoot node
            docRootNode = docNode.getDocumentElement;
            % Set specraClassifier node to docRoot node
            docRootNode.appendChild(decisionMakerNode);
        end
    end
    
    methods (Access = private)
        
        % DECISIONMAKERWITHFREQUENCYDOMAIN function added similarity to
        % some defects with time domain and iso 10816. If similarity of
        % defects less threshold(config parametrs), add "Unidentified defect".
        function [myDecisionMaker] = ...
                decisionMakerWithFrequencyDomain(myDecisionMaker, parameters)
            
            % To add periodicity to decisionMaker
            [myDecisionMaker.resultStruct, positionPeriodicityEnable] = myDecisionMaker.addPeriodicityToFrequencyDomain(...
                myDecisionMaker.resultStruct, myDecisionMaker.periodicityTable, parameters);
            
            % Add iso7919 to decisionMaker
            iso7919InformativeTags = ...
                myDecisionMaker.File.informativeTags.classStruct.shaftClassifier.shaft.defect{1, 2}.iso7919.data.Attributes;
            myDecisionMaker.resultStruct = myDecisionMaker.addIso7919ToFrequencyDomain(...
                myDecisionMaker.resultStruct, myDecisionMaker.iso7919Struct, iso7919InformativeTags, parameters);
            
            % Add shaftTrajectory to decisionMaker
            shaftTrajectoryInformativeTags = ...
                myDecisionMaker.File.informativeTags.classStruct.shaftClassifier.shaft.defect{1, 2}.shaftTrajectory.data.Attributes;
            myDecisionMaker.resultStruct = myDecisionMaker.addShaftTrajectoryToFrequencyDomain(...
                myDecisionMaker.resultStruct, myDecisionMaker.shaftTrajectory, shaftTrajectoryInformativeTags, parameters);
            
            % To add metrics to decisionMaker
            tableMetrics = myDecisionMaker.createMetricsTable(myDecisionMaker.File, myDecisionMaker.iso10816Struct.status);
            myDecisionMaker.resultStruct = myDecisionMaker.addMetricsToFrequencyDomain(...
                myDecisionMaker.resultStruct, tableMetrics, parameters);
            
            % If status more 1
            exceedingStatus = find(cell2mat({myDecisionMaker.resultStruct.status}) > 1);
            if ~isempty(exceedingStatus)
                for i = 1:1:length(exceedingStatus)
                    myDecisionMaker.resultStruct(exceedingStatus(i)).status = 1;
                end
            end
            
            enoughWithClassifiers = str2double(parameters.decisionMaker.enoughWithClassifiers);
            enoughPeriodicity = str2double(parameters.decisionMaker.enoughPeriodicity);
            
            if ~isempty(myDecisionMaker.periodicityTable)    
                if nnz(positionPeriodicityEnable)
                    % Check enough of status
                    statusFrequencyDomain = cell2mat({myDecisionMaker.resultStruct(logical(positionPeriodicityEnable)).status});
                    positionMoreValidity = ...
                        cell2mat({myDecisionMaker.periodicityTable.validity}) ...
                        > enoughPeriodicity;

                    % If not enough of similarity, to add "Unidentified defect" with periodicity
                    if ~nnz(statusFrequencyDomain >= enoughWithClassifiers) && ...
                        nnz(positionMoreValidity)

                        statusPeriodicity = sum(cell2mat({myDecisionMaker.periodicityTable(positionMoreValidity).validity}))/...
                            nnz(positionMoreValidity);

                        myDecisionMaker.resultStruct(1).status = statusPeriodicity;
                        myDecisionMaker.resultStruct(1).informativesTags.periodicity = statusPeriodicity; 
                    end
                end
            end
            
            % To add timeDomainClassifier to decisionMaker
            myDecisionMaker.resultStruct = myDecisionMaker.addTimeDomainToFrequencyDomain( ...
                myDecisionMaker.resultStruct, myDecisionMaker.timeDomain, parameters.decisionMaker);
            
            % If status more 1
            exceedingStatus = find(cell2mat({myDecisionMaker.resultStruct.status}) > 1);
            if ~isempty(exceedingStatus)
                for i = 1:1:length(exceedingStatus)
                    myDecisionMaker.resultStruct(exceedingStatus(i)).status = 1;
                end
            end
            
            % To check unknown defect for timeDomainClassifer
            if ~isempty(myDecisionMaker.timeDomain)
                posUnknown = cellfun(@isempty, strfind({myDecisionMaker.resultStruct.schemeName}, 'unknown'));
                
                tempStatusStruct = myDecisionMaker.resultStruct(posUnknown);
                
                if ~isempty(tempStatusStruct)
                    
                    numberDefects = length(tempStatusStruct);
                    positionAddTimeDomainClassifier = false(numberDefects,1);
                    for i = 1:1:numberDefects
                        nameInformativeTags = fieldnames(tempStatusStruct(i).informativesTags);
                        
                        if nnz(strcmp(nameInformativeTags, 'timeDomainClassifier'))
                            positionAddTimeDomainClassifier(i) = 1;
                        end
                    end
                    
                    if nnz(cellfun(@(x) x < enoughWithClassifiers,{tempStatusStruct(positionAddTimeDomainClassifier).status}))
                        % To add unknown defect of element
                            myDecisionMaker.resultStruct = decisionMaker.addTimeDomainUnknown(...
                                myDecisionMaker.resultStruct, myDecisionMaker.timeDomain, parameters.decisionMaker);
                    end
                end
            end
            
            % Add defect "ISO10816 LIMIT EXCEEDING"
            myDecisionMaker.resultStruct = myDecisionMaker.addStatusToIso10816Defect(...
                myDecisionMaker.resultStruct, myDecisionMaker.iso10816Struct);
            
            % Add defect "ISO7919 LIMIT EXCEEDING"
            myDecisionMaker.resultStruct = myDecisionMaker.addStatusToIso7919Defect(...
                myDecisionMaker.resultStruct, myDecisionMaker.iso7919Struct);
            
            % Add defect "VDI3834 COMPONENT LIMIT EXCEEDENG"
            myDecisionMaker.resultStruct = myDecisionMaker.addStatusToVdi3834Defect(...
                myDecisionMaker.resultStruct, myDecisionMaker.vdi3834Struct);
            
        end
        
        % DECISIONMAKERWITHOUTFREQUENCYDOMAIN function adding unidentified
        % defect base on two/one methods: time domain and/or iso 10816
        function statusStruct = decisionMakerWithoutFrequencyDomain(myDecisionMaker, parameters)
            statusStruct = myDecisionMaker.resultStruct;
            
            % Check status of periodicity
            if ~isempty(myDecisionMaker.periodicityTable)
                
                positionMoreValidity = ...
                        cell2mat({myDecisionMaker.periodicityTable.validity}) ...
                        > str2double(parameters.enoughPeriodicity);

                if nnz(positionMoreValidity)
                    statusPeriodicity = sum(cell2mat({myDecisionMaker.periodicityTable(positionMoreValidity).validity}))/...
                        nnz(positionMoreValidity);
                    
                    statusStruct(1).status = statusPeriodicity;
                    statusStruct(1).informativesTags.periodicity = statusPeriodicity; 
                end
            end
            
            % To check status of metrics
            tableMetrics = myDecisionMaker.createMetricsTable(myDecisionMaker.File, myDecisionMaker.iso10816Struct.status);
            positionOkMetrics = cellfun(@(x) x > 0.25, {tableMetrics.status}, 'UniformOutput', true);
            if nnz(positionOkMetrics) 
                statusStruct(1) = ...
                    myDecisionMaker.addMetricsToUndefinedDefect(statusStruct(1), tableMetrics(positionOkMetrics));
            end
            
            % To check status of timeDomainClassifier
            if ~isempty(myDecisionMaker.timeDomain)
                if ~strcmpi(myDecisionMaker.timeDomain.element, 'unknown')
                    if myDecisionMaker.timeDomain.similarity >= str2double(parameters.enoughTimeDomain)
                        % To add unknown defect of element
                        statusStruct = myDecisionMaker.addTimeDomainUnknown(statusStruct, myDecisionMaker.timeDomain, parameters);
                    end
                end
            end
            
            % Add defect "ISO10816 LIMIT EXCEEDING"
            statusStruct = myDecisionMaker.addStatusToIso10816Defect(...
                statusStruct, myDecisionMaker.iso10816Struct);
            
            % Add defect "ISO7919 LIMIT EXCEEDING"
            statusStruct = myDecisionMaker.addStatusToIso7919Defect(...
                statusStruct, myDecisionMaker.iso7919Struct);
            
            % Add defect "VDI3834 COMPONENT LIMIT EXCEEDENG"
            statusStruct = myDecisionMaker.addStatusToVdi3834Defect(...
                statusStruct, myDecisionMaker.vdi3834Struct);
            
            % If status more 1
            exceedingStatus = find(cell2mat({statusStruct.status}) > 1);
            if ~isempty(exceedingStatus)
                for i = 1:1:length(exceedingStatus)
                    statusStruct(exceedingStatus(i)).status = 1;
                end
            end
        end
        
        % COMPARECLASSIFIER function is compare results between 
        % time-frequency and frequency classifiers
        function statusStruct = compareClassifier(myDecisionMaker, enableTimeFrequencyClassifier)
            
            % Get status struct of classifiers
            statusStruct = myDecisionMaker.resultStruct;
            
            % Get status struct of time-frequency classifier 
            if enableTimeFrequencyClassifier
                
                objectsClassifier = myDecisionMaker.myTimeFrequencyClassifier.objectsStruct;
                numberObjects = length(objectsClassifier);
                numberDefects = length(getStatusStruct(objectsClassifier{1,1}));
                statusFrequency = nan(1,numberDefects);
                
                timeFrequencyStatus = zeros(numberObjects,numberDefects);
                for i = 1:1:numberObjects
                    temp = getStatusStruct(objectsClassifier{i});
                    timeFrequencyStatus(i,:) = cell2mat({temp.similarity});
                end
                
                structName = temp;
            else
                numberObjects = 0;
            end
                
            % Get status struct of frequency classifier
            if ~isempty(myDecisionMaker.mySchemeClassifier)
                
                frequencyStruct = getStatusStruct(myDecisionMaker.mySchemeClassifier);
                numberDefects = length(frequencyStruct);
                statusFrequency = cell2mat({frequencyStruct.similarity});
                
                if numberObjects == 0
                    timeFrequencyStatus = nan(1,numberDefects);
                end
                structName = frequencyStruct;
            end
                
            % Compare statuses
            tempStatusStruct = myDecisionMaker.createEmptyResultStruct(numberDefects);
            for i = 1:1:numberDefects
                tempStatusStruct(i) = myDecisionMaker.compareStatusesClassifier(structName(i), statusFrequency(1,i), ...
                    timeFrequencyStatus(:,i));
            end 
            
            % Delete LUBRICATION_DEFECT if there is not rollingBearing
            % elements
            if nnz(contains({tempStatusStruct.class}, 'rollingBearing'))
                startPos = 3;
            else
                statusStruct = statusStruct(1);
                startPos = 2;
            end
            
            % Write to result struct
            statusStruct(startPos:startPos+numberDefects-1) = tempStatusStruct;  
        end
    end
    
    methods (Static)
        
        % COMPARESTATUSESCLASSIFIER function is comparing status and
        % writing informative fields
        function struct = compareStatusesClassifier(structName, frequencyStruct, timeFrequencyStruct)
            
            % To write informative fields
            struct.class = structName.class;
            struct.schemeName = structName.name;
            struct.tagNameElement = structName.elementType;
            struct.tagNameDefect = structName.defectTagName;
            
            % Compare status if time-frequency and frequency classifiers is enable
            if nnz(~isnan(frequencyStruct))&& nnz(~isnan(timeFrequencyStruct))
                
                struct.status = max([frequencyStruct timeFrequencyStruct']);
                struct.informativesTags.timeFrequencyClassifier = timeFrequencyStruct;
                struct.informativesTags.frequencyClassifier = frequencyStruct;
            elseif nnz(~isnan(frequencyStruct))
                
                struct.status = frequencyStruct;
                struct.informativesTags.frequencyClassifier = frequencyStruct;
            else
                struct.status = max(timeFrequencyStruct);
                struct.informativesTags.timeFrequencyClassifier = timeFrequencyStruct;
            end
            
            struct.periodicity = structName.periodicity;
            struct.metrics = structName.metrics;
        end
        
        % CREATEEMPTYRESULTSTRUCT function is creating result struct
        % with empty fields
        function statusStruct = createEmptyResultStruct(numberDefects)
            
            statusStruct(numberDefects).class = [];
            statusStruct(numberDefects).schemeName = [];
            statusStruct(numberDefects).tagNameElement = [];
            statusStruct(numberDefects).tagNameDefect = [];
            statusStruct(numberDefects).status = [];
            statusStruct(numberDefects).informativesTags = [];
            statusStruct(numberDefects).periodicity.mainFrequency = nan(1);
            statusStruct(numberDefects).metrics = [];
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
            statusStruct(1).periodicity.mainFrequency = nan(1);
            statusStruct(1).metrics = [];
            
            % Create empty lubrication defect
            statusStruct(2).class = 'rollingBearing';
            statusStruct(2).schemeName = 'unknown002';
            statusStruct(2).tagNameElement = 'bearing';
            statusStruct(2).tagNameDefect = 'LUBRICATION_DEFECT';
            statusStruct(2).status = 0;
            statusStruct(2).informativesTags = [];
            statusStruct(2).periodicity.mainFrequency = nan(1);
            statusStruct(2).metrics = [];
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
                defectNode.setAttribute('status', num2str(round(elementStatusStruct(i).status*100)));

                % Create informativeTags node
                informativeTagsNode = docNode.createElement('informativeTags');
                
                % Check every informativeTags
                if ~isempty(elementStatusStruct(i).informativesTags)
                    nameMethods = fieldnames(elementStatusStruct(i).informativesTags);
                    
                    for j = 1:1:length(nameMethods)
                        nameMethodsNode = docNode.createElement(nameMethods{j});
                        if isnumeric(elementStatusStruct(i).informativesTags.(nameMethods{j}))
                            value = elementStatusStruct(i).informativesTags.(nameMethods{j});
                            if length(value(1,:)) < length(value(:,1))
                                value = value';
                            end
                            value = round(value*100);
                            nameMethodsNode.setAttribute('status', vector2strStandardFormat(value));
                        else
                            nameMethodsNode.setAttribute('status', ...
                                elementStatusStruct(i).informativesTags.(nameMethods{j}));
                        end
                        informativeTagsNode.appendChild(nameMethodsNode);
                    end
                end
                
                % Set informativeTags node to defect node
                defectNode.appendChild(informativeTagsNode);
                % Set defect node to element node
                elementNode.appendChild(defectNode);
            end
        end
        
        % CREATEMETRICSTABLE function create metrics table with status of
        % each metrics
        function tableMetrics = createMetricsTable(File, iso10816Status)
            
            metricsNameAcc = fieldnames(File.acceleration.metrics);
            metricsNameVel = fieldnames(File.velocity.metrics);
            metricsNameDisp = fieldnames(File.displacement.metrics);
            
            numberOfFieldsAcc = length(metricsNameAcc);
            numberOfFieldsVel = length(metricsNameVel);
            numberOfFieldsDisp = length(metricsNameDisp);
            numberOfFields = numberOfFieldsAcc + numberOfFieldsVel + numberOfFieldsDisp + 1;
            
            tableMetrics(numberOfFields).domain = [];
            tableMetrics(numberOfFields).metricsName = [];
            tableMetrics(numberOfFields).status = [];
            tableMetrics(numberOfFields).includedToDeffect = [];
            tableMetrics(numberOfFields).enoughSimilarity = [];
            
            tableMetrics = decisionMaker.fillTableMetrics(File, tableMetrics, metricsNameAcc, ...
                1, numberOfFieldsAcc, 'acceleration');
            tableMetrics = decisionMaker.fillTableMetrics(File, tableMetrics, metricsNameVel, ...
                numberOfFieldsAcc+1, numberOfFieldsAcc+numberOfFieldsVel, 'velocity');
            tableMetrics = decisionMaker.fillTableMetrics(File, tableMetrics, metricsNameDisp, ...
                numberOfFieldsAcc+numberOfFieldsVel+2, numberOfFields, 'displacement');
            
            % Add iso10816
            tableMetrics(numberOfFieldsAcc+numberOfFieldsVel+1).domain = 'velocity';
            tableMetrics(numberOfFieldsAcc+numberOfFieldsVel+1).metricsName = 'iso10816';
            if isempty(iso10816Status)
                tableMetrics(numberOfFieldsAcc+numberOfFieldsVel+1).status = 0;
            else
                tableMetrics(numberOfFieldsAcc+numberOfFieldsVel+1).status = double(str2numStatus.(iso10816Status));
            end    
            tableMetrics(numberOfFieldsAcc+numberOfFieldsVel+1).includedToDeffect = 'no';
        end
        
        % FillTABLEMETRICS function is filling table metrics
        function tableMetrics = fillTableMetrics(File, tableMetrics, metricsNameAcc, start, stop, domain)
            
            for i = start:1:stop
                tableMetrics(i).domain = domain;
                tableMetrics(i).metricsName = metricsNameAcc{i - start + 1};
                status = File.(domain).metrics.(metricsNameAcc{i - start + 1}).status;
                if isempty(status)
                    tableMetrics(i).status = 0;
                else
                    tableMetrics(i).status = double(str2numStatus.(status));
                end    
                tableMetrics(i).includedToDeffect = 'no';
            end
        end
        
        % COMPAREMETRICSANDDEFECTS function adding metrics of 
        % defect to status based on metrics status
        function [statusStruct, tableMetrics] = compareMetricsAndDefects(statusStruct, tableMetrics, parameters)
            
            % To get name metrics and weight from informative tags
            merticsName = split(statusStruct.metrics.name);
            postionMetricsName = ...
                arrayfun(@(x) contains(x, 'metrics'), ...
                merticsName, 'UniformOutput', true);
            merticsWeight = str2num(statusStruct.metrics.weight)';
            merticsName = merticsName(postionMetricsName);
            merticsWeight = merticsWeight(postionMetricsName);
            
            for i=1:1:length(merticsName)
                currentMetrics = split(merticsName(i), '_');
                
%                 if ~(length(currentMetrics) < 3)
%                     currentMetrics = currentMetrics(2:3);

                    % Serch needed metrics into table metrics
                    numberDomain = contains({tableMetrics.domain}, currentMetrics(1)); 
                    numberMetrics = contains({tableMetrics.metricsName}, currentMetrics(2)); 
                    rowMetrics = bsxfun(@times, numberDomain, numberMetrics); 
                    if nnz(rowMetrics)
                        numberInTableMetrics = find(rowMetrics, 1, 'first');

                        % Fill status structure with metrics result
                        if (tableMetrics(numberInTableMetrics).status) > 0.25

                            statusStruct.informativesTags = setfield(statusStruct.informativesTags, ...
                                ['metrics_' currentMetrics{1} '_' currentMetrics{2}], ...
                                tableMetrics(numberInTableMetrics).status);

                            if statusStruct.status ~= -0.01 && statusStruct.status <= parameters.enoughFrequencyClassifiers
                                tableMetrics(numberInTableMetrics).includedToDeffect = 'yes';  
                                statusIncrease = merticsWeight(i) * tableMetrics(numberInTableMetrics).status;
                                statusStruct.status = statusStruct.status + statusIncrease;

                                if statusStruct.status < parameters.enoughWithClassifiers
                                    tableMetrics(numberInTableMetrics).enoughSimilarity = 'no';
                                end
                            end
                        end
                    end
%                 end
            end
        end

        % ADDMETRICSTOUNDEFINEDDEF function adding some information in
        % "UNKNOWN DEFECTS"
        function statusStruct = addMetricsToUndefinedDefect(statusStruct, tableMetrics)
            
            % Remove iso10816 data from the metric table to
            % exclude from "UNKNOWN DEFECTS"
            positionIso10816 = cellfun(@(metricName) strcmp(metricName, 'iso10816'), {tableMetrics.metricsName}, 'UniformOutput', true);
            tableMetrics = tableMetrics(~positionIso10816);
            
            % If in "UNKNOWN DEFECTS" have already adding metrics, delete
            % it
            if ~isempty(statusStruct.informativesTags)
                namesCurrentMetrics = fieldnames(statusStruct.informativesTags);
                nameRequireAdded = arrayfun(@(x) ['metrics_' tableMetrics(x).domain '_' tableMetrics(x).metricsName], 1:1:length(tableMetrics), 'UniformOutput', false);
                positionNeedeDelete = cellfun(@(x) nnz(strcmp(x, namesCurrentMetrics)), nameRequireAdded);
                if nnz(positionNeedeDelete)
                    if nnz(positionNeedeDelete) == length(tableMetrics)
                        tableMetrics = [];
                    else
                        tableMetrics = tableMetrics(~positionNeedeDelete);
                    end
                end
            end
            
            % To Add metrics
            if ~isempty(tableMetrics)
                for i=1:1:length(tableMetrics)
                    statusStruct.informativesTags = setfield(statusStruct.informativesTags, ...
                        ['metrics_' tableMetrics(i).domain '_' tableMetrics(i).metricsName], tableMetrics(i).status);
                end
                statusStruct.status = statusStruct.status + max(cell2mat({tableMetrics.status}));
            end
        end
        
        % ADDSTATUSTOISO10816DEFECT function adds defect "ISO10816 LIMIT
        % EXCEEDING"
        function [statusStruct] = addStatusToIso10816Defect(statusStruct, iso10816Struct)
            
            if ~isempty(iso10816Struct.status)
                
                % Get status
                iso10816Status = double(str2numStatus.(iso10816Struct.status));
                
                % Create iso10816 defect
                iso10816DefectNumber = length(statusStruct) + 1;
                statusStruct(iso10816DefectNumber).class = 'equipment';
                statusStruct(iso10816DefectNumber).schemeName = 'unknown001';
                statusStruct(iso10816DefectNumber).tagNameElement = 'equipment';
                statusStruct(iso10816DefectNumber).tagNameDefect = 'ISO10816_LIMIT_EXCEEDING';
                statusStruct(iso10816DefectNumber).status = iso10816Status;
                statusStruct(iso10816DefectNumber).informativesTags.iso10816 = iso10816Status;
                statusStruct(iso10816DefectNumber).periodicity.mainFrequency = nan(1);
                statusStruct(iso10816DefectNumber).metrics = [];
            end
            
        end
        
        % ADDSTATUSTOISO7919DEFECT function adds defects "ISO7919 LIMIT
        % EXCEEDING"
        function [statusStruct] = addStatusToIso7919Defect(statusStruct, iso7919Struct)
            
            if ~isempty(iso7919Struct)
                
                for shaftNumber = 1 : 1 : length(iso7919Struct)
                    
                    % Get status
                    iso7919Status = double(str2numStatus.(iso7919Struct(shaftNumber).status));
                    
                    % Create iso7919 defect
                    iso7919DefectNumber = length(statusStruct) + 1;
                    statusStruct(iso7919DefectNumber).class = 'shaft';
                    statusStruct(iso7919DefectNumber).schemeName = iso7919Struct(shaftNumber).name;
                    statusStruct(iso7919DefectNumber).tagNameElement = 'shaft';
                    statusStruct(iso7919DefectNumber).tagNameDefect = 'ISO7919_LIMIT_EXCEEDING';
                    statusStruct(iso7919DefectNumber).status = iso7919Status;
                    statusStruct(iso7919DefectNumber).informativesTags.iso7919 = iso7919Status;
                    statusStruct(iso7919DefectNumber).periodicity.mainFrequency = nan(1);
                    statusStruct(iso7919DefectNumber).metrics = [];
                end
            end
            
        end
        
        % ADDSTATUSTOVDI3834DEFECT function adds the defects "VDI3834
        % COMPONENT LIMIT EXCEEDENG"
        function [statusStruct] = addStatusToVdi3834Defect(statusStruct, vdi3834Struct)
            
            if isempty(vdi3834Struct)
                return;
            end
            
            % Get component names
            componentNames = fieldnames(vdi3834Struct);
            
            for componentNumber = 1 : 1 : length(componentNames)
                
                % Get the component name
                componentName = componentNames{componentNumber};
                
                if isempty(vdi3834Struct.(componentName))
                    continue;
                end
                
                % Get area names of the component
                areaNames = fieldnames(vdi3834Struct.(componentName));
                
                areaStatuses = [];
                
                for areaNumber = 1 : 1 : length(areaNames)
                    
                    % Get the area name
                    areaName = areaNames{areaNumber};
                    
                    if ~isempty(vdi3834Struct.(componentName).(areaName))
                        areaStatuses = [areaStatuses, {vdi3834Struct.(componentName).(areaName).status}];
                    end
                end
                
                % Get the max status
                maxComponentStatus = max(cellfun(@(status) double(str2numStatus.(status)), areaStatuses));
                
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
                statusStruct(componentDefectNumber).informativesTags.vdi3834 = maxComponentStatus;
                statusStruct(componentDefectNumber).periodicity.mainFrequency = nan(1);
                statusStruct(componentDefectNumber).metrics = [];
            end
            
        end
        
        % ADDPERIODICITYTOFREQUENCYDOMAIN function add and check 
        % periodicity to decision maker through frequencyDomain
        function [statusStruct, positionPeriodicityEnable] = addPeriodicityToFrequencyDomain(statusStruct, periodicityTable, parameters)
            
            positionPeriodicityEnable = 0;
            
            % To check exist of periodicity status
            if ~isempty(periodicityTable)
                periodFrequency = cell2mat({periodicityTable.frequency})';
                periodStatuses = cell2mat({periodicityTable.validity})';
                
                enoughPeriodicity = str2double(parameters.decisionMaker.enoughPeriodicity);
                enoughFrequencyClassifiers = str2double(parameters.decisionMaker.enoughFrequencyClassifiers);
                
                numberElements = length(statusStruct);
                positionPeriodicityEnable = zeros(numberElements, 1);

                % To compare time domain status with frequency domain and
                % decision maker
                for i=1:1:numberElements
                    if ~isnan(statusStruct(i).periodicity.mainFrequency)

                        numbersRequirementsFrequency = nnz(statusStruct(i).periodicity.mainFrequency);
                        periodSimilarity = zeros(numbersRequirementsFrequency,1);
                        for j=1:1:numbersRequirementsFrequency
                            similarElements = getSimilarElements(statusStruct(i).periodicity.mainFrequency(j), ...
                                periodFrequency, parameters.peakComparison);
                                
                            if ~isempty(similarElements)
                                periodSimilarity(j) = max(periodStatuses(ismember(periodFrequency, similarElements)));
                                positionPeriodicityEnable(i) = 1;
                            end
                        end
                        
                        periodSimilarity(periodSimilarity < enoughPeriodicity) = 0;
                        
                        if positionPeriodicityEnable(i)
                            statusPeriodicityAdd = sum(bsxfun(@times, statusStruct(i).periodicity.mainWeight, periodSimilarity));
                            statusStruct(i).informativesTags.periodicity = statusPeriodicityAdd;
                            
                            if statusStruct(i).status ~= -0.01 && statusStruct(i).status <= enoughFrequencyClassifiers
                                statusStruct(i).status = statusStruct(i).status + statusPeriodicityAdd;
                            end
                        end
                        
                    end
                end
            end
        end
        
        % ADDISO7919TOFREQUENCYDOMAIN function adds iso7919 statuses to
        % decision maker through frequencyDomain
        function [statusStruct] = addIso7919ToFrequencyDomain(statusStruct, iso7919Struct, informativeTags, parameters)
            if ~isempty(iso7919Struct)
                % Get enough status values
                enoughIso7919 = str2double(parameters.decisionMaker.enoughIso7919);
                enoughFrequencyClassifiers = str2double(parameters.decisionMaker.enoughFrequencyClassifiers);
                
                for shaftNumber = 1 : 1 : length(iso7919Struct)
                    % Get the shaft schemeName
                    shaftSchemeName = iso7919Struct(shaftNumber).name;
                    % Find the shaft in the statusStruct
                    shaftIndex = strcmp({statusStruct.schemeName}, shaftSchemeName);
                    % Find the defect "ROTOR_IMBALANCE" in the
                    % statusStruct
                    defectIndex = strcmp({statusStruct.tagNameDefect}, 'ROTOR_IMBALANCE');
                    % Get the defect "ROTOR_IMBALANCE" of the shaft
                    shaftDefectIndex = shaftIndex & defectIndex;
                    
                    % Get the iso7919 status of the shaft
                    shaftStatus = double(str2numStatus.(iso7919Struct(shaftNumber).status));
                    statusStruct(shaftDefectIndex).informativesTags.iso7919 = shaftStatus;
                    
                    if shaftStatus > enoughIso7919
                        currentStatus = statusStruct(shaftDefectIndex).status;
                        if (currentStatus ~= -0.01) && (currentStatus <= enoughFrequencyClassifiers)
                            % Add the iso7919 status
                            statusIncrement = str2double(informativeTags.weight) * shaftStatus;
                            statusStruct(shaftDefectIndex).status = currentStatus + statusIncrement;
                        end
                    end
                end
            end
        end
        
        % ADDSHAFTTRAJECTORYTOFREQUENCYDOMAIN function adds
        % shaftTrajectory statuses to decision maker through
        % frequencyDomain
        function [statusStruct] = addShaftTrajectoryToFrequencyDomain(statusStruct, shaftTrajectory, informativeTags, parameters)
            if ~isempty(shaftTrajectory)
                
                shaftNames = shaftTrajectory.shaftSchemeName;
                if length(shaftNames) == 1
                    if strcmp(shaftNames, 'shaft')
                        return;
                    end
                end
                
                % Get enough status values
                enoughShaftTrajectory = str2double(parameters.decisionMaker.enoughShaftTrajectory);
                enoughFrequencyClassifiers = str2double(parameters.decisionMaker.enoughFrequencyClassifiers);
                
                for shaftNumber = 1 : 1 : length(shaftNames)
                    % Get the shaft schemeName
                    shaftSchemeName = shaftTrajectory.shaftSchemeName{shaftNumber};
                    % Find the shaft in the statusStruct
                    shaftIndex = strcmp({statusStruct.schemeName}, shaftSchemeName);
                    % Find the defect "ROTOR_IMBALANCE" in the
                    % statusStruct
                    defectIndex = strcmp({statusStruct.tagNameDefect}, 'ROTOR_IMBALANCE');
                    % Get the defect "ROTOR_IMBALANCE" of the shaft
                    shaftDefectIndex = shaftIndex & defectIndex;
                    
                    % Get the shaftTrajectory status of the shaft
                    shaftStatus = shaftTrajectory.ellipticity;
                    statusStruct(shaftDefectIndex).informativesTags.shaftTrajectory = shaftStatus;
                    
                    if shaftStatus > enoughShaftTrajectory
                        currentStatus = statusStruct(shaftDefectIndex).status;
                        if (currentStatus ~= -0.01) && (currentStatus <= enoughFrequencyClassifiers)
                            % Add the shaftTrajectory status
                            statusIncrement = str2double(informativeTags.weight) * shaftStatus;
                            statusStruct(shaftDefectIndex).status = currentStatus + statusIncrement;
                        end
                    end
                end
            end
        end
        
        % ADDMETRICSTOFREQUENCYDOMAIN function add and check 
        % metrics to decision maker through frequencyDomain
        function statusStruct = addMetricsToFrequencyDomain(statusStruct, tableMetrics, parameters)
            
            % Check status of metrics
            positionOkMetrics = cellfun(@(x) x > 0.25, {tableMetrics.status}, 'UniformOutput', true);
            if nnz(positionOkMetrics) 
                
                posNonEmptyMetrics = ~cellfun(@isempty, {statusStruct.metrics});
                posNonEmptyCnt = nnz(posNonEmptyMetrics);
                
                % To check informative tags of metrics in defects
                if posNonEmptyCnt
                    
                    % Find defects with informative tags of metrics and
                    % update status of defects based on metrics
                    posNumberNonEmptyMetrics = find(posNonEmptyMetrics);
                    tempParameters.enoughWithClassifiers = str2double(parameters.decisionMaker.enoughWithClassifiers);
                    tempParameters.enoughFrequencyClassifiers = str2double(parameters.decisionMaker.enoughFrequencyClassifiers);
                    for i = 1:1:posNonEmptyCnt
                        [statusStruct(posNumberNonEmptyMetrics(i)), tableMetrics] = ...
                            decisionMaker.compareMetricsAndDefects(statusStruct(posNumberNonEmptyMetrics(i)), tableMetrics, tempParameters);
                    end
                    
                    % To check UnknownDefect and it added if needed
                    numberYes = arrayfun(@(x) contains(tableMetrics(x).includedToDeffect, 'yes'), 1:1:length(tableMetrics));
                    posotionAddedMetrics = bsxfun(@times, numberYes, positionOkMetrics);
                    
                    % If damage metrics not added into defects
                    if nnz(posotionAddedMetrics) ~= nnz(positionOkMetrics)
                        statusStruct(1) = ...
                            decisionMaker.addMetricsToUndefinedDefect(statusStruct(1), ...
                            (tableMetrics(logical(bsxfun(@times, ~numberYes, positionOkMetrics)))));
                    end
                    
                    % If damage metricses added into defects, but 
                    % it have small weight into thier
                    if nnz(posotionAddedMetrics)
                        positionNotEnough = arrayfun(@(x) ~isempty(tableMetrics(x).enoughSimilarity), 1:1:length(tableMetrics));    
                        if nnz(positionNotEnough)
                            statusStruct(1) = ...
                                decisionMaker.addMetricsToUndefinedDefect(statusStruct(1), (tableMetrics(positionNotEnough)));
                        end
                    end
                else
                    statusStruct(1) = ...
                        decisionMaker.addMetricsToUndefinedDefect(statusStruct(1), tableMetrics(positionOkMetrics));
                end
            end
        end
        
        % ADDTIMEDOMAINTOFREQUENCYDOMAIN function check
        % timeDomainClassifier and add it to decision makers
        function statusStruct = addTimeDomainToFrequencyDomain(statusStruct, timeDomain, parameters)
            
            enoughTimeDomain = str2double(parameters.enoughTimeDomain); 
            enoughFrequencyClassifiers = str2double(parameters.enoughFrequencyClassifiers);
            if ~isempty(timeDomain)
                if ~strcmpi(timeDomain.element, 'unknown')
                    if (timeDomain.similarity)/100 >= enoughTimeDomain
                        
                        % To find similar element of timeDomain to decision maker
                        positionSimilarElements = ~cellfun(@isempty, strfind(lower({statusStruct.class}), timeDomain.element));
                        structureSimilaritElement = statusStruct(positionSimilarElements);
                        
                        % To delete "unknow defect"
                        needSavePos = cellfun(@isempty, strfind(lower({structureSimilaritElement.schemeName}), 'unknown'));
                        if nnz(~needSavePos)
                            structureSimilaritElement = structureSimilaritElement(needSavePos);
                        end
                        
                        if ~isempty(structureSimilaritElement)

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
                                meanElements(i,1) = mean(statusTemp);
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
                            contributionTimeDomain = str2double(parameters.contributionTimeDomain);
                            for i = 1:1:length(posAdd) 
                                positionAddElement = find(ismember({statusStruct.schemeName}, uniqElement(posAdd(i))));
                                statusTimeDomain = contributionTimeDomain*timeDomain.similarity/100;
                                for j = 1:1:length(positionAddElement)

                                    statusStruct(positionAddElement(j)).informativesTags = ...
                                        setfield(statusStruct(positionAddElement(j)).informativesTags, ...
                                        'timeDomainClassifier', statusTimeDomain);

                                    if statusStruct(i).status <= enoughFrequencyClassifiers
                                        statusStruct(positionAddElement(j)).status = ...
                                            statusStruct(positionAddElement(j)).status + statusTimeDomain;
                                    end
                                end

                            end

                        else
                            % To add unknown defect of element
                            statusStruct = decisionMaker.addTimeDomainUnknown(statusStruct, timeDomain, parameters);
                        end
                    end
                end
            end
        end
        
        % ADDTIMEDOMAINUNKNOWN function add "UNKNOWN DEFECT" to timeDomainClassifier 
        function statusStruct = addTimeDomainUnknown(statusStruct, timeDomain, parameters)
            
            % To find privious unknown defects
            positionUnknownDef = ~cellfun(@isempty, strfind({statusStruct.schemeName}, 'unknown'));
            
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
%             status = str2double(parameters.contributionTimeDomain)*timeDomain.similarity;
            status = timeDomain.similarity/100;

            % To add information to status struct
            statusStruct(numberElementAdd).tagNameDefect = ['UNIDENTIFIED_' upperCase(timeDomain.element{1})];
            statusStruct(numberElementAdd).tagNameElement = timeDomain.element{1};
            statusStruct(numberElementAdd).schemeName = schemeName;
            statusStruct(numberElementAdd).class = 'equipment';
            statusStruct(numberElementAdd).status = status;    
            statusStruct(numberElementAdd).informativesTags.timeDomainClassifier = status;
            statusStruct(numberElementAdd).periodicity.mainFrequency = nan(1);
            statusStruct(numberElementAdd).metrics = [];
        end
    end
end


