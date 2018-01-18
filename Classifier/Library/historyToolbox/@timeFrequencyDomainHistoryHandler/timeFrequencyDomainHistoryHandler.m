classdef timeFrequencyDomainHistoryHandler < historyHandler
    % TIMEFREQUNCYDOMAINHISTORYHANDLER class evaluate frequency classifier
    % through scalogram date
    
    properties (Access = protected)
        
        % The parameters for this class
        parameters
    end
    
    methods (Access = public)        
        % Constructor function
        function [myTimeFrequencyDomainHistoryHandler] = ...
                timeFrequencyDomainHistoryHandler(myConfig, myFiles, myTranslations, myXmlToStructHistory)
            if nargin < 1
               error('There are not enough input arguments!'); 
            end
            
            myContainerTag = 'timeFrequencyDomain';
            myTimeFrequencyDomainHistoryHandler =  myTimeFrequencyDomainHistoryHandler@ ...
                historyHandler(myConfig, myFiles, myContainerTag, myTranslations, myXmlToStructHistory);
            
            parameters = [];
            if isfield(myConfig.config.parameters.evaluation.history, 'timeFrequencyDomainHistoryHandler')
                parameters.timeFrequencyDomain = ...
                    myConfig.config.parameters.evaluation.history.timeFrequencyDomainHistoryHandler.Attributes;
            end
            if isfield(myFiles.files.history.Attributes, 'actualPeriod')
                parameters = setfield(parameters, 'maxPeriod', myFiles.files.history.Attributes.actualPeriod);
            end
            if isfield(myConfig.config.parameters.common, 'parpoolEnable')
                parameters.parpoolEnable = ...
                    myConfig.config.parameters.common.parpoolEnable.Attributes.value;
            end

            myTimeFrequencyDomainHistoryHandler.parameters = parameters;
            
            myTimeFrequencyDomainHistoryHandler.trendHandler = [];
            myTimeFrequencyDomainHistoryHandler = historyProcessing(myTimeFrequencyDomainHistoryHandler);
        end
        
        % FILLDOCNODE function fills docNode document with calculated
        % result data
        function [docNode] = fillDocNode(myTimeFrequencyDomainHistoryHandler, docNode)
            
            iLoger = loger.getInstance;
            myResult = getResult(myTimeFrequencyDomainHistoryHandler);
            
            % Replace existing timeFrequencyDomainClassifier node with new one
            docRootNode = docNode.getDocumentElement;
            if hasChildNodes(docRootNode)
                childNodes = getChildNodes(docRootNode);
                numChildNodes = getLength(childNodes);
                for count = 1:numChildNodes
                    theChild = item(childNodes,count-1);
                    name = toCharArray(getNodeName(theChild))';
                    if strcmp(name,'timeFrequencyDomainClassifier')
                        docRootNode.removeChild(theChild);
                        break;
                    end
                end
            end
            
            timeFrequencyClassifierNode = docNode.createElement('timeFrequencyDomainClassifier');
            docRootNode.appendChild(timeFrequencyClassifierNode);
            
            for i = 1:1:length(myResult)
                
                resonantFrequencyNode = docNode.createElement('resonantFrequency');
                
                resonantFrequencyNode.setAttribute('value', myResult{i,1}.currentData.Attributes.value);
                resonantFrequencyNode.setAttribute('range', myResult{i,1}.currentData.Attributes.range);
                resonantFrequencyNode.setAttribute('energyContribution', myResult{i,1}.currentData.Attributes.energyContribution);
                
                % Filing of periodicity data
                periodicityNode = docNode.createElement('periodicity');

                    
                periodicityNode.setAttribute('frequency', myResult{i,1}.currentData.periodicity.Attributes.frequency);
                periodicityNode.setAttribute('type', myResult{i,1}.currentData.periodicity.Attributes.type);
                periodicityNode.setAttribute('validity', myResult{i,1}.currentData.periodicity.Attributes.validity);
                
                resonantFrequencyNode.appendChild(periodicityNode);
                
                if ~isempty(myResult{i, 1}.frequencyDomainClassifier)
                    % Filling schemeClassifier data
                    [~, frequencyDomainNode] = fillDocNode(myResult{i,1}.frequencyDomainClassifier, docNode, 0);
                    resonantFrequencyNode.appendChild(frequencyDomainNode);    
                end
                    
                timeFrequencyClassifierNode.appendChild(resonantFrequencyNode);
            end
            
            printComputeInfo(iLoger, 'TimeFrequencyDomainClassifier', 'docNode structure was successfully updated.');
        end
    end
    
    methods (Access = protected)   
        
        % HISTORYPROCESSING function 
        function [myTimeFrequencyDomainHistoryHandler] = historyProcessing(myTimeFrequencyDomainHistoryHandler)
            
			iLoger = loger.getInstance;
			
            % To get date from history container
            myHistoryContainer = getHistoryContainer(myTimeFrequencyDomainHistoryHandler);
            myHistoryTable = getHistoryTable(myHistoryContainer); 
            
            % To sort history data
            sortTable = myTimeFrequencyDomainHistoryHandler. ...
                sortTimeFrequencyClassifier(myHistoryTable, myTimeFrequencyDomainHistoryHandler.parameters.timeFrequencyDomain);
            
            % To evaluate sort data
            myTimeFrequencyDomainHistoryHandler.result = evaluateSortData(myTimeFrequencyDomainHistoryHandler, sortTable);
			printComputeInfo(iLoger, 'TimeFrequencyDomainClassifier', 'TimeFrequencyDomainClassifier history processing COMPLETE.');
        end
        
        % EVALUATESORTDATA function eveluate all resonant frequences through 
        % frequency classifier
        function result = evaluateSortData(myTimeFrequencyDomainHistoryHandler, sortTable)
            
            % To create empty result
            numnerObject = length(sortTable(:,1));
            result = cell(numnerObject, 1);
            
            % To get history of frequency classifier 
            for i = 1:1:numnerObject
                result{i, 1} = initialObjHistoryClassifier(myTimeFrequencyDomainHistoryHandler, sortTable(i, :));
            end
        end
        
        % INITIALOBJHISTORYCLASSIFIER function process history data for one 
        % resonant frequences through frequency classifier
        function result = initialObjHistoryClassifier(myTimeDomainHistoryHandler, historyTableSort)
            
            % To get data from history
            myHistoryContainer = getHistoryContainer(myTimeDomainHistoryHandler);
            files = getFiles(myHistoryContainer);
            config = getConfig(myTimeDomainHistoryHandler);
            Translations = getTranslations(myTimeDomainHistoryHandler);
            myXmlToStructHistoryObj = getXmlToStructHistoryObj(myHistoryContainer);
            myCurrentDate = getDate(myXmlToStructHistoryObj);
            myHistoryTable = getHistoryTable(myHistoryContainer); 

            numberFilesHistory = length(historyTableSort);
            
             % To fill empty cell with empty frequency classifier
            if nnz(~cellfun(@isempty, historyTableSort)) ~= numberFilesHistory
                
                emptyPos = find(cellfun(@isempty, historyTableSort));
                
                if nnz(emptyPos == numberFilesHistory)
                    historyTableSort{1,numberFilesHistory} = ...
                        myTimeDomainHistoryHandler.createEmptyClassifier(historyTableSort{1,1}, myHistoryTable{1, numberFilesHistory}, 1);
                    emptyPos = emptyPos(emptyPos ~= numberFilesHistory);
                end
                
                numberEmpty = nnz(emptyPos);
                for i = numberEmpty:-1:1
                    historyTableSort{emptyPos(i)} = ...
                        myTimeDomainHistoryHandler.createEmptyClassifier(historyTableSort{1, emptyPos(i)+1}, myHistoryTable{1, emptyPos(i)});
                end
            end
            
            % To make history with require format of class xmlToStructHistory
            formatHistoryXml = cell(1, numberFilesHistory);
            for i = 1:1:numberFilesHistory
                formatHistoryXml{1, i}.equipment = historyTableSort{1, i};
            end
            
            % To set data for history
            myXmlToStructHistoryObj = setCurrentDataRaw(myXmlToStructHistoryObj, formatHistoryXml{1, 1});
            if numberFilesHistory ~= 1
                formatHistoryXml = formatHistoryXml(1, 2:end)';
                myXmlToStructHistoryObj = setHistoryDataRaw(myXmlToStructHistoryObj, formatHistoryXml);
            end
            myParameters = getParameters(myXmlToStructHistoryObj);
            myParameters.logEnable = 0; 
            myXmlToStructHistoryObj = setParameters(myXmlToStructHistoryObj, myParameters);
            
            % To set vector time
            myCurrentDate = myCurrentDate(1:numberFilesHistory);
            myXmlToStructHistoryObj = setDate(myXmlToStructHistoryObj, myCurrentDate);
            
            % To process frequency classifier
            if isfield(historyTableSort{1, 1}, 'frequencyDomainClassifier')
                result.frequencyDomainClassifier = frequencyDomainHistoryHandler(config, files, Translations, myXmlToStructHistoryObj);
            else
                result.frequencyDomainClassifier = [];
            end
            result.currentData = historyTableSort{1,1};
            
            % If there is no scalogram data, then all result are zeros
            if isempty(historyTableSort{1, 1}.Attributes.range)
                
                myResult = getResult(result.frequencyDomainClassifier);
                
                for i = 1:1:length(myResult)
                    myResult(i).historySimilarity = 0;
                    myResult(i).historyDanger = 0;
                end
                
                result.frequencyDomainClassifier = setResult(result.frequencyDomainClassifier, myResult);
            end
        end
        
        %Unused
        function [myTimeDomainHistoryHandler] = createFuzzyContainer(myTimeDomainHistoryHandler)   
            myTimeDomainHistoryHandler.fuzzyContainer = [];
        end
    end
    
    methods(Static)
        
        % SORTTIMEFREQUENCYCLASSIFIER function sort result of time-frequency 
        % classifiers with special range of scalogram
        function sortTable = sortTimeFrequencyClassifier(myHistoryTable, parameters)
            
            % To set config parameters
            parametersCompare.overlapPercent = str2double(parameters.overlapPercent);
            parametersCompare.percentageOfReange = str2double(parameters.percentageOfReange);
            
            % To find current renges
            positionCurrentRange = find(~cellfun(@isempty, myHistoryTable(:,1)));
            numberCurrentRange = nnz(positionCurrentRange);
            currentRanges = cell(numberCurrentRange, 2);
            for i = 1:1:numberCurrentRange
                if ~isempty(myHistoryTable{positionCurrentRange(i), 1}.Attributes.range)
                    tempRange = strsplit(myHistoryTable{positionCurrentRange(i), 1}.Attributes.range, ' ');
                    currentRanges{i, 1} = str2double(tempRange{1});
                    currentRanges{i, 2} = str2double(tempRange{2});
                end
            end
            
            % To create initial parameters for history processing and
            % create sortTable with current data
            [~, colTable] = size(myHistoryTable);
            sortTable = cell(numberCurrentRange, colTable);
            sortTable(:, 1) = myHistoryTable(~cellfun(@isempty, myHistoryTable(:,1)), 1);
            myHistoryTable = myHistoryTable(:, 2:end);
            colTable = colTable - 1;
            
            % To sort history data
            for i = 1:1:colTable
                rowTablePos = find(~cellfun(@isempty, myHistoryTable(:,i)));
                numberNonEmpty = nnz(rowTablePos);
                if numberNonEmpty
                    
                    % To get history range
                    rangeHistory = cell(numberNonEmpty, 2);
                    noEmptyHistory = myHistoryTable(rowTablePos, i);
                    for j = 1:1:numberNonEmpty
                        if ~isempty(noEmptyHistory{j,1}.Attributes.range)
                            tempRange = strsplit(noEmptyHistory{j,1}.Attributes.range, ' ');
                            rangeHistory{j,1} = str2double(tempRange{1});
                            rangeHistory{j,2} = str2double(tempRange{2});
                        end
                    end
                    
                    % To sort
                    for j = 1:1:numberCurrentRange
                        positionFinding = similarRanges(currentRanges(j, :), rangeHistory, parametersCompare);
                        if nnz(positionFinding)
                            sortTable(j,i+1) = noEmptyHistory(positionFinding, 1);
                        end
                    end
                end
            end
        end
        
        % SIMILARRANGES function finding similar ranges
        status = similarRanges(currentRanges, vectorRanges, parameters)
        
        % CREATEEMPTYCLASSIFIER function create empty struct for frequency
        % classifier, mode = 1 - to fill traningEnable empty cell; mode = 0 - to 
        % fill traningEnable with input structure
        function emptyStruct = createEmptyClassifier(sturctInit, myHistoryTable, mode)
            
            if nargin < 3
                mode = 0;
            end
            
            if isfield(sturctInit, 'frequencyDomainClassifier')
                tempStruct = sturctInit.frequencyDomainClassifier;
                historyStruct = myHistoryTable.frequencyDomainClassifier;
                if ~isempty(tempStruct)
                numberElement = length(tempStruct.element);

                for i = 1:1:numberElement
                    numberDefect = length(tempStruct.element{1, i}.defect);
                    for j = 1:1:numberDefect
                        tempStruct.element{1, i}.defect{1, j}.status.Attributes.durationLevel = '';
                        tempStruct.element{1, i}.defect{1, j}.status.Attributes.historyDanger = '0';

                        tempStruct.element{1, i}.defect{1, j}.status.Attributes.level = '-1';
                        tempStruct.element{1, i}.defect{1, j}.status.Attributes.similarity = '0';
                        tempStruct.element{1, i}.defect{1, j}.status.Attributes.similarityTrend = '';
                        tempStruct.element{1, i}.defect{1, j}.status.Attributes.value = '0';

                        if isfield(tempStruct.element{1, i}.defect{1, j}.informativeTags, 'displacementSpectrum')
                            tempStruct.element{1, i}.defect{1, j}.informativeTags.displacementSpectrum = timeFrequencyDomainHistoryHandler. ...
                                fillDomainEmpty(historyStruct.element{1, i}.defect{1, j}.informativeTags.displacementSpectrum, 'other', mode);
                        end

                        if isfield(tempStruct.element{1, i}.defect{1, j}.informativeTags, 'velocitySpectrum')
                            tempStruct.element{1, i}.defect{1, j}.informativeTags.velocitySpectrum = timeFrequencyDomainHistoryHandler. ...
                                fillDomainEmpty(historyStruct.element{1, i}.defect{1, j}.informativeTags.velocitySpectrum, 'other', mode);
                        end

                        if isfield(tempStruct.element{1, i}.defect{1, j}.informativeTags, 'accelerationSpectrum')
                            tempStruct.element{1, i}.defect{1, j}.informativeTags.accelerationSpectrum = timeFrequencyDomainHistoryHandler. ...
                                fillDomainEmpty(historyStruct.element{1, i}.defect{1, j}.informativeTags.accelerationSpectrum, 'other', mode);
                        end

                        if isfield(tempStruct.element{1, i}.defect{1, j}.informativeTags, 'accelerationEnvelopeSpectrum')
                            tempStruct.element{1, i}.defect{1, j}.informativeTags.accelerationEnvelopeSpectrum = timeFrequencyDomainHistoryHandler. ...
                                fillDomainEmpty(tempStruct.element{1, i}.defect{1, j}.informativeTags.accelerationEnvelopeSpectrum, 'envelope', mode);
                        end
                    end
                end
                else
                    tempStruct = [];
                end
                emptyStruct.frequencyDomainClassifier = tempStruct;
            else
                emptyStruct.frequencyDomainClassifier = [];
            end
        end
        
        % FILLDOMAINEMPTY function fill domain with empty cell;
        % mode = 1 - to fill traningEnable empty cell; mode = 0 - to 
        % fill traningEnable with input structure
        function emptyStruct = fillDomainEmpty(fillStruct, modeDomain, mode)
            
            % To save training period, other to do empty
            emptyStruct = fillStruct;
            
            if strcmpi(modeDomain, 'envelope')
                emptyStruct.defective.Attributes = timeFrequencyDomainHistoryHandler.emptyFrequences(emptyStruct.defective.Attributes);
                emptyStruct.nondefective.Attributes = timeFrequencyDomainHistoryHandler.emptyFrequences(emptyStruct.nondefective.Attributes);
                emptyStruct.validated.Attributes = timeFrequencyDomainHistoryHandler.emptyFrequences(emptyStruct.validated.Attributes);
                emptyStruct.unvalidated.Attributes = timeFrequencyDomainHistoryHandler.emptyFrequences(emptyStruct.unvalidated.Attributes);

                % To fill traning period with mode == 1
                if mode
                    emptyStruct.trainingPeriod.Attributes.initialTagNames = '';
                    emptyStruct.trainingPeriod.Attributes.mean = '';
                    emptyStruct.trainingPeriod.Attributes.relatedTagNames = '';
                    emptyStruct.trainingPeriod.Attributes.status = '';
                    emptyStruct.trainingPeriod.Attributes.std = '';
                    emptyStruct.trainingPeriod.Attributes.tagNames = '';
                end
            end
        end
        
        % EMPTYFREQUENCES function fills fields empty
        function frequencesStruct = emptyFrequences(frequencesStruct)
            
            name = fieldnames(frequencesStruct);
            
            for i = 1:1:length(name)
                frequencesStruct.(name{i}) = '';
            end
        end
    end
end