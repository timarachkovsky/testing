classdef frequencyDomainHistoryHandler < historyHandler
    % FREQUENCYDOMAINHISTORYHANDLER class evaluate defects based on 
    % spectra and determined dangerous of the defect into time
    
    properties (Access = protected)
        
        % The parameters for this class
        parameters
    end
    
    methods (Access = public)        
        % Constructor function
        function [myFrequencyDomainHistoryHandler] = ...
                frequencyDomainHistoryHandler(myConfig, myFiles, myTranslations, myXmlToStructHistory)
            if nargin < 1
               error('There are not enough input arguments!'); 
            end
            
            myContainerTag = 'frequencyDomain';
            myFrequencyDomainHistoryHandler =  myFrequencyDomainHistoryHandler@historyHandler(myConfig, myFiles, myContainerTag, myTranslations, myXmlToStructHistory);
            
            parameters = [];
            if isfield(myConfig.config.parameters.evaluation.history, 'frequencyDomainHistoryHandler')
            	parameters = myConfig.config.parameters.evaluation.history.frequencyDomainHistoryHandler.Attributes;
            end
%             if isfield(myFiles.files.history.Attributes, 'actualPeriod')
%                 parameters = setfield(parameters, 'maxPeriod', myFiles.files.history.Attributes.actualPeriod);
%             end
            if isfield(myConfig.config.parameters.common, 'parpoolEnable')
                parameters.parpoolEnable = ...
                    myConfig.config.parameters.common.parpoolEnable.Attributes.value;
            end
%             parameters = fill_struct(parameters, 'intensivityThreshold', '0.3');
%             parameters = fill_struct(parameters, 'trendResultRange', '-0.75, -0.25, 0.25, 0.75, 1.25');
%             parameters = fill_struct(parameters, 'parpoolEnable', '0');
%             parameters = fill_struct(parameters, 'percentCurrentStatusThresholdOfHistory', '50');
%             parameters = fill_struct(parameters, 'stablePeriodStatusThresholdEachPeak', '3');
            myFrequencyDomainHistoryHandler.parameters = parameters;
            
            myFrequencyDomainHistoryHandler.trendHandler = [];
            myFrequencyDomainHistoryHandler = historyProcessing(myFrequencyDomainHistoryHandler);
        end
        
        % FILLDOCNODE function fills docNode document with calculated
        % result data
        function [docNode, envelopeClassifierNode] = fillDocNode(myEnvHistoryHandler, docNode, modeTimeFrequencyClassifier)
            
            if nargin < 3
                modeTimeFrequencyClassifier = 1;
            end
            
            iLoger = loger.getInstance;
            myResult = getResult(myEnvHistoryHandler);
            
            docRootNode = docNode.getDocumentElement;
            if modeTimeFrequencyClassifier
                % Replace existing frequencyDomainClassifier node with new one
                if hasChildNodes(docRootNode)
                    childNodes = getChildNodes(docRootNode);
                    numChildNodes = getLength(childNodes);
                    for count = 1:numChildNodes
                        theChild = item(childNodes,count-1);
                        name = toCharArray(getNodeName(theChild))';
                        if strcmp(name,'frequencyDomainClassifier')
                            docRootNode.removeChild(theChild);
                            break;
                        end
                    end
                end
            end
                
            envelopeClassifierNode = docNode.createElement('frequencyDomainClassifier');
            docRootNode.appendChild(envelopeClassifierNode);
            
            % Checking for unique elements in the statusStruct, cutting
            % corresponding to them parts of the statusStruct and putting
            % it into the CREATEELEMENTNODE function for element docNode 
            % part creation
            for i=1:1:length(myResult)
                elementsNames{i,1} = getfield(myResult(i),'schemeName');
            end
            
            uniqueElements = unique(elementsNames, 'stable');
            for i=1:1:length(uniqueElements)
                elementStruct = myResult(find(ismember(elementsNames,uniqueElements(i,1))));
                elementNode = createElementNode(myEnvHistoryHandler, docNode, elementStruct);
                envelopeClassifierNode.appendChild(elementNode);
            end
            
            if modeTimeFrequencyClassifier
                printComputeInfo(iLoger, 'FrequencyDomainHistoryHandler', 'docNode structure was successfully updated.');
            end
        end
        
    end
    
    methods (Access = protected)   
        
        % HISTORYPROCESSING function 
        function [myFrequencyDomainHistoryHandler] = historyProcessing(myFrequencyDomainHistoryHandler)
            
            iLoger = loger.getInstance;
            myHistoryContainer = getHistoryContainer(myFrequencyDomainHistoryHandler);
            myHistoryTable = getHistoryTable(myHistoryContainer);
            myDate = getDate(myHistoryContainer);
            defectsNumber = length(myHistoryTable);
            myFrequencyDomainHistoryHandler.result = myHistoryTable;
            
            % Calculate and fill historyTable with defectResult for each defect 
            % (intensivity,trend and similarity)
            if str2double(myFrequencyDomainHistoryHandler.parameters.parpoolEnable)
                parfor i=1:1:defectsNumber
					[myResult(i,:)] = ...
                        defectHistoryProcessing(myFrequencyDomainHistoryHandler,myHistoryTable(i),myDate);
                end
            else
                
                for i=1:1:defectsNumber     
					[myResult(i,:)] = ...
                        defectHistoryProcessing(myFrequencyDomainHistoryHandler,myHistoryTable(i),myDate);
                end
            end
            myFrequencyDomainHistoryHandler.result = myResult; 
            printComputeInfo(iLoger, 'FrequencyDomainHistoryHandler', 'FrequencyDomainClassifier history processing COMPLETE.');
        end
        
        %Unused
        function [myFrequencyDomainHistoryHandler] = createFuzzyContainer(myFrequencyDomainHistoryHandler)   
            myFrequencyDomainHistoryHandler.fuzzyContainer = [];
        end
        
        %DEFECTHISTORYPROCESSING function evaluate of defect all domains
        function [myResult] = defectHistoryProcessing(myFrequencyDomainHistoryHandler,myHistoryTable,myTimesVector)
            
            % Init myResult with current historyTable row data and further
            % fill it with calculated values
            statusDomain = [];
            if ~isempty(myHistoryTable.accelerationEnvelopeSpectrum)
                statusDomain.accelerationEnvelopeSpectrum = defectHistoryProcessingDomain( ...
                    myFrequencyDomainHistoryHandler,myHistoryTable.accelerationEnvelopeSpectrum,myTimesVector);
            end
            if ~isempty(myHistoryTable.accelerationSpectrum)
                statusDomain.accelerationSpectrum = defectHistoryProcessingDomain( ...
                    myFrequencyDomainHistoryHandler,myHistoryTable.accelerationSpectrum,myTimesVector);
            end
            if ~isempty(myHistoryTable.velocitySpectrum)
                statusDomain.velocitySpectrum = defectHistoryProcessingDomain( ...
                    myFrequencyDomainHistoryHandler,myHistoryTable.velocitySpectrum,myTimesVector);
            end
            if ~isempty(myHistoryTable.displacementSpectrum)
                statusDomain.displacementSpectrum = defectHistoryProcessingDomain( ...
                    myFrequencyDomainHistoryHandler,myHistoryTable.displacementSpectrum,myTimesVector);
            end
            
            % Get similarity trend 
            myHistoryTable.trendSimilarity = ...
                evaluateSimilarityTrend(myFrequencyDomainHistoryHandler, myHistoryTable.similarity', myTimesVector);
            
            % Evaluate level
            myHistoryTable.durationCurrentLevel = myFrequencyDomainHistoryHandler.evaluateDurationStatus(...
                myFrequencyDomainHistoryHandler.config.config.parameters.evaluation.history.trend.Attributes, myHistoryTable.level', myTimesVector);
            
            if ~isempty(statusDomain)
                %Evaluation status of defect
                myResult = getResultDefect(myFrequencyDomainHistoryHandler, statusDomain, myHistoryTable);
            else
                myResult = myHistoryTable;
                myResult.status = myResult.similarity(1);
                myResult.historySimilarity = myResult.similarity(1);
            end
        end
        
        % DEFECTHISTORYPROCESSINGDOMAIN function evaluate each peak in
        % required domain (envelope, direct, etc)
        function [statusDomain] = defectHistoryProcessingDomain(myFrequencyDomainHistoryHandler, myHistoryTable, myDate)
            
            myConfig = getConfig(myFrequencyDomainHistoryHandler);
            % Init myResult with current historyTable row data and further
            % fill it with calculated values
            myHistoryContainer = getHistoryContainer(myFrequencyDomainHistoryHandler);
            myFiles = getFiles(myHistoryContainer);

            %dummy default parameters of training period
                myFiles.myFiles.files.history.Attributes.trainingPeriodEnable = '1';
            %dummy
            
            magnitudesData = myHistoryTable.magnitudesTable{1,1};
            
            freqName = myHistoryTable.nameTable;
            freqTag = myHistoryTable.tagTable;
            
            trainingPeriodStd = myHistoryTable.trainingPeriodStd;
            trainingPeriodMean = myHistoryTable.trainingPeriodMean;
            trainingPeriodTagNames = myHistoryTable.trainingPeriodTagNames;
            trainingPeriodRelatedTagNames = myHistoryTable.trainingPeriodRelatedTagNames;
            trainingPeriodStatus = myHistoryTable.trainingPeriodStatus;
%             trainingPeriodWillBe = 0; % varibale represent training period was or will be. (default is was)
            
            [magnitudesLength,numberOfHistoryFiles] = size(magnitudesData);
            if isempty(magnitudesLength)
                printWarning(myFrequencyDomainHistoryHandler.iLoger, 'There is empty history!');
                return
            end
            
            % Compare trainingPeriodTagNames and freqName 
            if length(freqName(1,:)) > 1
                if ~isempty(freqName{1,1})
                    
                    % If appear new frequency, add to training period
                    trainingPeriodName = trainingPeriodTagNames(:,2);
                    trainingPeriodName(find(cellfun(@isempty, trainingPeriodName))) = {''};
                    [posDiffNameToFreq, posDiffNameToTraining] = ...
                        ismember(freqName(:,1),trainingPeriodName);
                    posDiffNameToFreq = ~posDiffNameToFreq;
                    posDiffNameToTraining = nonzeros(posDiffNameToTraining);
                    
                    firstInputDisable = nnz(~cellfun(@isempty, trainingPeriodTagNames(:,:)));
                    if firstInputDisable
                        amountAddRow = nnz(posDiffNameToFreq);
                    else
                        amountAddRow = nnz(posDiffNameToFreq)-1;
                        if amountAddRow < 0
                            amountAddRow = 0;
                        end
                    end
                    
                    if amountAddRow
                        currentElementTrainingPeriod = length(trainingPeriodTagNames(:,1));
                        trainingPeriodTagNames = ...
                            myFrequencyDomainHistoryHandler.getIncreasedMatrix(trainingPeriodTagNames, ...
                            amountAddRow);
                        
                        if firstInputDisable
                            trainingPeriodTagNames(currentElementTrainingPeriod+1:end,1) = ...
                                strtrim(freqName(posDiffNameToFreq,1));
                        else
                            trainingPeriodTagNames(currentElementTrainingPeriod:end,1) = ...
                                strtrim(freqName(posDiffNameToFreq,1));
                        end
                        trainingPeriodTagNames(posDiffNameToTraining,1) = ...
                            trainingPeriodTagNames(posDiffNameToTraining,2);
                    else
                        trainingPeriodTagNames(posDiffNameToTraining,1) = ...
                            trainingPeriodTagNames(posDiffNameToTraining,2);
                    end
                    
                    trainingPeriodName = trainingPeriodTagNames(:,1);
                    trainingPeriodName(find(cellfun(@isempty, trainingPeriodName))) = {''};
                    
                    % Get sort vector
                    [~, posSameName] = ismember(freqName(:,1),trainingPeriodName(:,1));
                    lengthTrainingPeriod = length(trainingPeriodTagNames(:,1));
                    vectorCurrentPos = 1:1:lengthTrainingPeriod;
                    sortVector = zeros(lengthTrainingPeriod,1);
                    sortVector(1:length(posSameName)) = posSameName;
                    vectorCurrentPos(nonzeros(posSameName)) = 0;
                    sortVector(sortVector == 0) = nonzeros(vectorCurrentPos);
                    
                    % Sort
                    trainingPeriodTagNames = trainingPeriodTagNames(sortVector,:);
                    trainingPeriodStd = ...
                        myFrequencyDomainHistoryHandler.getIncreasedMatrix(trainingPeriodStd, amountAddRow);
                    trainingPeriodStd = trainingPeriodStd(sortVector,:);
                    trainingPeriodMean = ...
                        myFrequencyDomainHistoryHandler.getIncreasedMatrix(trainingPeriodMean, amountAddRow);
                    trainingPeriodMean = trainingPeriodMean(sortVector,:);
                    trainingPeriodRelatedTagNames = ...
                        myFrequencyDomainHistoryHandler.getIncreasedMatrix(trainingPeriodRelatedTagNames, ...
                        amountAddRow);
                    trainingPeriodRelatedTagNames = trainingPeriodRelatedTagNames(sortVector,:);
                    trainingPeriodStatus = ...
                        myFrequencyDomainHistoryHandler.getIncreasedMatrix(trainingPeriodStatus, amountAddRow);
                    trainingPeriodStatus = trainingPeriodStatus(sortVector,:);
                end
            end
            
            intensivityResultVector = zeros(magnitudesLength,1);
            intensivityThreshold = str2double(myFrequencyDomainHistoryHandler.parameters.intensivityThreshold);
            trendResultVector = zeros(magnitudesLength,1);
            statusCurrentThreshold = cell(magnitudesLength,1);
            dataCompression = nan(magnitudesLength,numberOfHistoryFiles);
            for i=1:1:magnitudesLength
                % Find intensivity of current informative tag
                historyDataMagnitudes = magnitudesData(i,:);
                
                % Get compression magnitudes
                myHistoryCompression = ...
                    historyCompression(historyDataMagnitudes', myDate, ...
                    myConfig.config.parameters.evaluation.history.trend.Attributes, 'env');
                compression = getCompressedHistory(myHistoryCompression);
                historyDataMagnitudes = flip(compression.data);
                myDateMagnitudes = flip(compression.date);

                % Crop empty history 
                [historyDataMagnitudes, myDateMagnitudes, posLastNumericCrop] = ...
                    myFrequencyDomainHistoryHandler.cropEmptyHistory(historyDataMagnitudes, myDateMagnitudes);
                
                tempParameters = [];
                if (isfield(myConfig.config.parameters.evaluation.history, 'intensivityHandler'))
                    tempParameters = myConfig.config.parameters.evaluation.history.intensivityHandler.Attributes;
                    tempParameters.intensivityThreshold = ...
                        myFrequencyDomainHistoryHandler.parameters.intensivityThreshold;
                end
                
                myIntensivityHandler = intensivityHandler(historyDataMagnitudes', tempParameters);
                intensivityResultVector(i,1) = getResult(myIntensivityHandler); 
                posStablePeak = getPosStablePeak(myIntensivityHandler);
                % Crop with intensity
                historyDataMagnitudes = historyDataMagnitudes(1:posStablePeak);
                myDateMagnitudes = myDateMagnitudes(1:posStablePeak);
                
                % The variable for evaluation of modulations in defect functions 
                % of history
                dataCompression(i,1:1:length(historyDataMagnitudes)) = historyDataMagnitudes;
                
                % If current informative tag has a normal intensivity,
                % calculate trend paremeters of it history
                if intensivityResultVector(i,1) > intensivityThreshold 
                    tempParameters = [];
                    if (isfield(myConfig.config.parameters.evaluation.history, 'trend'))
                        tempParameters = myConfig.config.parameters.evaluation.history.trend.Attributes;
                        tempParameters.compressionEnable = '0';
                    end
                    
                    historyDataMagnitudes(historyDataMagnitudes==0) = NaN;

                    myTrendHandler = ...
                        trendHandler(historyDataMagnitudes, tempParameters, myDateMagnitudes);
                    trendResultVector(i,1) = getResult(myTrendHandler);
                    historyDataMagnitudes = getSignal(myTrendHandler)';
                    dateForTrainingPeriod = flip(myDateMagnitudes);
                    %Training period for each peak
                    [trainingPeriodStatus{i,1}, trainingPeriodMean{i,1}, trainingPeriodStd{i,1}] = ...
                            getTrainingPeriodAndStatus(trainingPeriodStd(i,:)', trainingPeriodMean(i,:)', ...
                            myFiles, dateForTrainingPeriod, historyDataMagnitudes,[],myDate); 
                    
                else
                    trendResultVector(i,1) = 1.5; % "Unknown" mode
                    trainingPeriodStatus{i,1} = 'NaN';
                    trainingPeriodMean{i,1} = [];
                    trainingPeriodStd{i,1} = [];
                end
                
                % Creatre status for training period
                if isempty(trainingPeriodMean{i,1}) && isempty(trainingPeriodStd{i,1})
                    trainingPeriodMean{i,1} = NaN;
                    trainingPeriodStd{i,1} = NaN;
                end
                name = freqName(i,find(cellfun(@(x) ~isempty(x), freqName(i,:)),1));
                tag = freqTag(i,find(cellfun(@(x) ~isempty(x), freqTag(i,:)),1));
                if ~isempty(name) && ~isempty(tag)
                    trainingPeriodRelatedTagNames{i,1} = tag{1,1};
                    trainingPeriodTagNames{i,1} = name{1,1};
                end
                
                % Training period if current peak just appears
                if ~isempty(trainingPeriodMean{i,1})
                    if intensivityResultVector(i,1) > intensivityThreshold && isnan(trainingPeriodMean{i,1})
                        % if current peak existence according to training Period
                        if nnz(~cell2mat(cellfun(@isempty, flip(trainingPeriodStd(i,:)'),'UniformOutput', false))) >= ...
                                str2double(myFiles.files.history.Attributes.trainingPeriod)
%                             if ~trainingPeriodWillBe
                                % Set current date for peak just appears
                                tempFiles = myFiles;
                                tempFiles.files.history.Attributes.trainingPeriodLastDate = dateForTrainingPeriod{end};

                                [trainingPeriodStatus{i,1}, trainingPeriodMean{i,1}, trainingPeriodStd{i,1}] = ...
                                    getTrainingPeriodAndStatus(trainingPeriodStd(i,:)', trainingPeriodMean(i,:)', ...
                                    tempFiles, dateForTrainingPeriod, historyDataMagnitudes,[],myDate); 
%                             end
                        end
                    end
                end
                
                if isempty(trainingPeriodStatus{i,1})
                    trainingPeriodStatus{i,1} = 'NaN';
                end
                % Get status of threshold with compression data
                myHistoryCompression = historyCompression(trainingPeriodStatus(i,:)', myDate,  ...
                    myConfig.config.parameters.evaluation.history.trend.Attributes, 'threshold');
                compression = getCompressedHistory(myHistoryCompression);
                vectorCompressionStatusThreshold = flip(compression.data);
                vectorCompressionStatusThreshold = ...
                    vectorCompressionStatusThreshold(1:posLastNumericCrop);
                vectorCompressionStatusThreshold = ...
                    flip(vectorCompressionStatusThreshold(1:posStablePeak));
                
                % Evaluate thresholds status of peak
                 statusCurrentThreshold(i,1) = ...
                    myFrequencyDomainHistoryHandler.evaluateStatus(vectorCompressionStatusThreshold, myFiles);
            end
            
            % Set initial name of frequency
            [trainingPeriodInitialTagNames, trainingPeriodWillBe] = ...
                myFrequencyDomainHistoryHandler.getInitialTagNames( ...
                trainingPeriodTagNames, trainingPeriodStatus, ...
                myHistoryTable.trainingPeriodInitialTagNames, myFiles, myDate');
            
            % prepare for docNode struct for training  period
            if nnz(~cellfun(@isempty, trainingPeriodTagNames(:,:))) >= 1 && ~trainingPeriodWillBe
                for i =1:1:length(trainingPeriodTagNames(:,1))
                    if isempty(trainingPeriodStd{i,1})
                        trainingPeriodStd{i,1} = trainingPeriodStd{i,2};
                        trainingPeriodMean{i,1} = trainingPeriodMean{i,2};
                    end
                    if isempty(trainingPeriodTagNames{i,1})
                        trainingPeriodTagNames{i,1} = ...
                            trainingPeriodTagNames{i,find(~cellfun(@isempty, trainingPeriodTagNames(i,:)),1)};
                        trainingPeriodRelatedTagNames{i,1} = ...
                            trainingPeriodRelatedTagNames{i,find(...
                            ~cellfun(@isempty, trainingPeriodRelatedTagNames(i,:)),1)};
                    end
                end
                trainingPeriodStd = ...
                    char(join(string(cellfun(@num2str, trainingPeriodStd(:,1), 'UniformOutput', false))));
                trainingPeriodMean = ...
                    char(join(string(cellfun(@num2str, trainingPeriodMean(:,1), 'UniformOutput', false))));
                trainingPeriodTagNames = ...
                    char(join(string(trainingPeriodTagNames(:,1))));
                trainingPeriodRelatedTagNames = ...
                    char(join(string(trainingPeriodRelatedTagNames(:,1))));
                
            else
                trainingPeriodStd = [];
                trainingPeriodMean = [];
                trainingPeriodTagNames = [];
                trainingPeriodRelatedTagNames = [];
            end
             
%             % Deleting non-filled cells
%             positionNan = find(isnan(dataCompression(1,:)),1,'first');
%             if ~isempty(positionNan) 
%                 dataCompression = dataCompression(:,1:1:positionNan-1);
%             end
            
            statusDomain.freqName = freqName;
            statusDomain.freqTag = freqTag;  
            statusDomain.dataCompression = dataCompression;
            
            statusDomain.statusCurrentThreshold = statusCurrentThreshold;
            statusDomain.trendResultVector = trendResultVector;
            statusDomain.intensivityResultVector = intensivityResultVector > intensivityThreshold;
            
            statusDomain.trainingPeriodStd = trainingPeriodStd;
            statusDomain.trainingPeriodMean = trainingPeriodMean;
            statusDomain.trainingPeriodTagNames = trainingPeriodTagNames;
            statusDomain.trainingPeriodRelatedTagNames = trainingPeriodRelatedTagNames;
            statusDomain.trainingPeriodStatus = trainingPeriodStatus(:,1);
            statusDomain.trainingPeriodInitialTagNames  = trainingPeriodInitialTagNames;
        end
        
        %GETRESULTDEFECT function is evaluating defect states
        function [myResult] = getResultDefect(myFrequencyDomainHistoryHandler, statusDomain, myHistoryTable)
            myHistoryContainer = getHistoryContainer(myFrequencyDomainHistoryHandler);
            myHistoryValidity = getHistoryValidity(myHistoryContainer);
            myFiles = getFiles(myFrequencyDomainHistoryHandler);
            myResult = myHistoryTable;
            
            % Push to report 
            nameDomain = fieldnames(statusDomain);
            for i = 1:1:length(nameDomain)
                myResult.(nameDomain{i}).trendResult = statusDomain.(nameDomain{i}).trendResultVector;
                
                myResult.(nameDomain{i}).trainingPeriodTagNames = ...
                    statusDomain.(nameDomain{i}).trainingPeriodTagNames;
                myResult.(nameDomain{i}).trainingPeriodRelatedTagNames = ...
                    statusDomain.(nameDomain{i}).trainingPeriodRelatedTagNames;
                myResult.(nameDomain{i}).trainingPeriodMean = ...
                    statusDomain.(nameDomain{i}).trainingPeriodMean;
                myResult.(nameDomain{i}).trainingPeriodStd = ...
                    statusDomain.(nameDomain{i}).trainingPeriodStd;
                myResult.(nameDomain{i}).trainingPeriodStatus =  ...
                    statusDomain.(nameDomain{i}).trainingPeriodStatus;
                myResult.(nameDomain{i}).trainingPeriodInitialTagNames = ...
                    statusDomain.(nameDomain{i}).trainingPeriodInitialTagNames;
                myResult.(nameDomain{i}).statusCurrentThreshold = ...
                    statusDomain.(nameDomain{i}).statusCurrentThreshold;
                
                myResult.(nameDomain{i}).dataCompression = ...
                    statusDomain.(nameDomain{i}).dataCompression;
                myResult.(nameDomain{i}).intensivityResultVector = ...
                    statusDomain.(nameDomain{i}).intensivityResultVector;
                
                myResult.(nameDomain{i}) = myFrequencyDomainHistoryHandler.addTrainingPeriodParameters(myResult.(nameDomain{i}),statusDomain.(nameDomain{i}));
            end
            %% Calculate defect status
            if myHistoryValidity
                myHistoryDefectEvaluator = historyDefectEvaluator(myResult, myFiles);
                myResult.historySimilarity = getHistorySimilarity(myHistoryDefectEvaluator);
                myResult.historyDanger = getHistoryDanger(myHistoryDefectEvaluator);
            else
                myResult.historySimilarity = -0.01;
                myResult.historyDanger = -0.01;
            end
        end
        
        % CREATEELEMENTNADE function create structure docNode for defect
        function [elementNode] = createElementNode(myFrequencyDomainHistoryHandler, docNode,elementStruct)
            
            elementNode = docNode.createElement('element');
            
            elementNode.setAttribute('tagName', elementStruct(1).elementTagName);
            elementNode.setAttribute('schemeName', elementStruct(1).schemeName);
            elementNode.setAttribute('class', elementStruct(1).class);
            elementNode.setAttribute('baseFrequency',num2str(elementStruct(1).baseFrequency));
    
            for i=1:1:length(elementStruct)
                
                defectNode = docNode.createElement('defect');
                defectNode.setAttribute('tagName', elementStruct(i).defectTagName);

                statusNode = docNode.createElement('status');
                statusNode.setAttribute('value', num2str(ceil(elementStruct(i).historySimilarity*100)));
                statusNode.setAttribute('historyDanger', num2str(ceil(elementStruct(i).historyDanger*100)));
                statusNode.setAttribute('historySimilarity', num2str(ceil(elementStruct(i).historySimilarity*100)));
                statusNode.setAttribute('level', elementStruct(i).level{1,1});
                statusNode.setAttribute('durationLevel', num2str(elementStruct(i).durationCurrentLevel));
                statusNode.setAttribute('similarity', num2str(round(elementStruct(i).similarity(1,1)*100)/100));
                statusNode.setAttribute('similarityTrend', ...
                    num2str(round(elementStruct(i).trendSimilarity*100)/100));
                
                informativeTagsNode = docNode.createElement('informativeTags');
                
                if ~isempty(elementStruct(i).displacementSpectrum)
                     [domainNode, docNode] = myFrequencyDomainHistoryHandler.fillDocNodeDomain( ...
                         elementStruct(i).displacementSpectrum, docNode, 'displacementSpectrum');
                     informativeTagsNode.appendChild(domainNode);
                end
                if ~isempty(elementStruct(i).velocitySpectrum)
                     [domainNode, docNode] = myFrequencyDomainHistoryHandler.fillDocNodeDomain( ...
                         elementStruct(i).velocitySpectrum, docNode, 'velocitySpectrum');
                     informativeTagsNode.appendChild(domainNode);
                end
                if ~isempty(elementStruct(i).accelerationSpectrum)
                     [domainNode, docNode] = myFrequencyDomainHistoryHandler.fillDocNodeDomain( ...
                         elementStruct(i).accelerationSpectrum, docNode, 'accelerationSpectrum');
                     informativeTagsNode.appendChild(domainNode);
                end
                if ~isempty(elementStruct(i).accelerationEnvelopeSpectrum)
                     [domainNode, docNode] = myFrequencyDomainHistoryHandler.fillDocNodeDomain( ...
                         elementStruct(i).accelerationEnvelopeSpectrum, docNode, 'accelerationEnvelopeSpectrum');
                     informativeTagsNode.appendChild(domainNode);
                end

                defectNode.appendChild(statusNode);
                defectNode.appendChild(informativeTagsNode);

                elementNode.appendChild(defectNode);
            end
        end
        
        % EVALUATESIMILARITYTREND function is calculate status of similarity
        function [status] = evaluateSimilarityTrend(myFrequencyDomainHistoryHandler, vectorSimilarity, myDate)
            myConfig = getConfig(myFrequencyDomainHistoryHandler);
            
            tempParameters = [];
            if (isfield(myConfig.config.parameters.evaluation.history, 'trend'))
                tempParameters = myConfig.config.parameters.evaluation.history.trend.Attributes;
            end
            
            % Off iLoger with parpool 
            tempParameters.compressionLogEnable = '0';
            if vectorSimilarity(1,1) ~= -1
                
                % To process for time-frequency classifier 
                if nnz(vectorSimilarity == -1)
                    posNegativeSimilarity = vectorSimilarity ~= -1;
                    vectorSimilarity = vectorSimilarity(posNegativeSimilarity);
                    myDate = myDate(posNegativeSimilarity);
                end
                
                % Calculate status of similarity trend
                myTrendHandler = trendHandler(vectorSimilarity, tempParameters, myDate);
                status = getResult(myTrendHandler);
            else
                status = 1.5;
            end
            % Copmression data (the last similarity during the period)
%             myHistoryCompression = historyCompression(cellstr(num2str(vectorSimilarity)), ...
%                 myDate,  myConfig.config.parameters.evaluation.history.trend.Attributes, 'threshold');
%             compression = getCompressedHistory(myHistoryCompression);
%             compressionSimilarity = str2double(string(compression.data));
%             compressiomDate = compression.date;
%             
%             tempParameters = [];
%             if (isfield(myConfig.config.parameters.evaluation.history, 'trend'))
%                 tempParameters = myConfig.config.parameters.evaluation.history.trend.Attributes;
%                 tempParameters.compressionEnable = '0';
%                 tempParameters.compressionLogEnable = '0';
%             end
%             % Calculate status of similarity trend
%             myTrendHandler = ...
%                 trendHandler(flip(compressionSimilarity), tempParameters, flip(compressiomDate));
%             status = getResult(myTrendHandler);

            
        end
        
    end
    
    methods(Static)
        
        % CROPEMPTYHISTORY To crop history data to first non empty element
        function [data, time, posLastNumeric] = cropEmptyHistory(data, time)
            if data(end) == 0 && (nnz(data)~=0)
                posLastNumeric = find(data ~= 0, 1, 'last');
                data = data(1:posLastNumeric);
                time = time(1:posLastNumeric);
            else
                posLastNumeric = length(data);
            end
        end
        
        % GETINITIALTAGNAMES function finds tag name into history with 
        % training period last date 
        function [vectorInitialTagNames, trainingPeriodWillBe] = ...
                getInitialTagNames(trainingPeriodTagNames, ...
                trainingPeriodStatus, trainingPeriodInitialTagNames, myFiles, timeVectorAll)
            
            trainingPeriodLastDate = myFiles.files.history.Attributes.trainingPeriodLastDate;  
            
            if strcmp(myFiles.files.history.Attributes.compressionPeriodTag, 'day')     
                trainingDate = datenum(str2double(trainingPeriodLastDate(7:10)), ...
                    str2double(trainingPeriodLastDate(4:5)), ...
                    str2double(trainingPeriodLastDate(1:2)));
                
                timeVectorNum = datenum(cellfun(@(x) str2double(x(7:10)),timeVectorAll), ...
                    cellfun(@(x) str2double(x(4:5)),timeVectorAll), ...
                    cellfun(@(x) str2double(x(1:2)),timeVectorAll));
                
            elseif strcmp(myFiles.files.history.Attributes.compressionPeriodTag, 'hour')
                trainingDate = datenum(str2double(trainingPeriodLastDate(7:10)), ...
                    str2double(trainingPeriodLastDate(4:5)), ...
                    str2double(trainingPeriodLastDate(1:2)), str2double(trainingPeriodLastDate(12:13)), 0, 0);
                
                timeVectorNum = datenum(cellfun(@(x) str2double(x(7:10)),timeVectorAll), ...
                    cellfun(@(x) str2double(x(4:5)),timeVectorAll), ...
                    cellfun(@(x) str2double(x(1:2)),timeVectorAll), ...
                    cellfun(@(x) str2double(x(12:13)),timeVectorAll), 0, 0);
                
            elseif strcmp(myFiles.files.history.Attributes.compressionPeriodTag, 'month')
                trainingDate = datenum(str2double(trainingPeriodLastDate(7:10)), ...
                    str2double(trainingPeriodLastDate(4:5)), 0);
                
                timeVectorNum = datenum(cellfun(@(x) str2double(x(7:10)),timeVectorAll), ...
                    cellfun(@(x) str2double(x(4:5)),timeVectorAll), 0);
                
            else
                printComputeInfo(iLoger, 'Training period', 'Incorrect input tag of history, it should be day/hour/month in filed compressionPeriodTag');
                error('Incorrect input tag of history, it should be day/hour/month in filed compressionPeriodTag')
            end 


            initialisationPosition = find(timeVectorNum == trainingDate, 1);
            posNext = find(timeVectorNum > trainingDate, 1, 'last');
            posPrevious = find(timeVectorNum < trainingDate, 1, 'first');
            
            if isempty(posNext) && isempty(initialisationPosition)
                vectorInitialTagNames = 'NaN';
                trainingPeriodWillBe = 1;
            else
                trainingPeriodWillBe = 0;
                
                if isempty(initialisationPosition) && isempty(posPrevious)
                    if length(trainingPeriodTagNames(1,:)) > 1 
                        vectorInitialTagNames = trainingPeriodInitialTagNames{1,2};
                    else
                        vectorInitialTagNames = '';
                    end
                else
                    vectorIntensivitePeak = ~(strcmp(trainingPeriodStatus(:, initialisationPosition), 'NaN') + ...
                        cellfun(@isempty, trainingPeriodStatus(:, initialisationPosition)));
                    vectorInitialTagNames = trainingPeriodTagNames(vectorIntensivitePeak, initialisationPosition);
                end
            end
            if ~isempty(vectorInitialTagNames) && ~nnz(strcmp(vectorInitialTagNames, 'NaN'))
                    vectorInitialTagNames = strjoin(vectorInitialTagNames(~cellfun(@isempty, vectorInitialTagNames)));
            end
            
        end
        
        % GETINCREASEDMATRIX function increases matrix with empty cell
        function [increasedMatrix] = getIncreasedMatrix(matrix, increased)
            [row, colum] = size(matrix);
            increasedMatrix = cell(increased+row, colum);
            increasedMatrix(1:row,:) = matrix(:,:); 
        end
        
        % FILLDOCNODEDOMAIN function fills docNode with found peaks:
        % unvalidated, validated, defective, nondefective, trainingPeriod
        function [domainNode, docNode] = fillDocNodeDomain(structDomain, docNode, tagDomain)
            % The main informativeTags for defect probability
            % calculations
            domainNode = docNode.createElement(tagDomain);
            
            validatedNode = docNode.createElement('validated');
            validatedNode.setAttribute('tagNames', structDomain.validatedTagNames);
            validatedNode.setAttribute('relatedTagNames', structDomain.validatedRelatedTagNames);
            validatedNode.setAttribute('frequencies', structDomain.validatedFrequencies);
            validatedNode.setAttribute('magnitudes', structDomain.validatedMagnitudes);
            validatedNode.setAttribute('prominences', structDomain.validatedProminences);
            validatedNode.setAttribute('weights', structDomain.validatedWeights);
            
            % Training period
            trainingPeriodNode = docNode.createElement('trainingPeriod');
            trainingPeriodNode.setAttribute('std', vector2strStandardFormat(structDomain.trainingPeriodStd));
            trainingPeriodNode.setAttribute('mean',  vector2strStandardFormat(structDomain.trainingPeriodMean));
            trainingPeriodNode.setAttribute('tagNames', vector2strStandardFormat(structDomain.trainingPeriodTagNames));
            trainingPeriodNode.setAttribute('relatedTagNames', vector2strStandardFormat(structDomain.trainingPeriodRelatedTagNames));
            trainingPeriodNode.setAttribute('initialTagNames', vector2strStandardFormat(structDomain.trainingPeriodInitialTagNames));
            if ~isempty(structDomain.trainingPeriodRelatedTagNames)
                structDomain.trainingPeriodStatus(cellfun(@isempty, structDomain.trainingPeriodStatus)) = {'NaN'};
                trainingPeriodNode.setAttribute('status', vector2strStandardFormat(structDomain.trainingPeriodStatus));
            else
                trainingPeriodNode.setAttribute('status', []);
            end
            % All informativeTags (without schemeValidator usage)
            unvalidatedNode = docNode.createElement('unvalidated');
            unvalidatedNode.setAttribute('tagNames', structDomain.unvalidatedTagNames);
            unvalidatedNode.setAttribute('relatedTagNames', structDomain.unvalidatedRelatedTagNames);
            unvalidatedNode.setAttribute('frequencies', structDomain.unvalidatedFrequencies);
            unvalidatedNode.setAttribute('magnitudes', structDomain.unvalidatedMagnitudes);
            unvalidatedNode.setAttribute('prominences', structDomain.unvalidatedProminences);
            unvalidatedNode.setAttribute('weights', structDomain.unvalidatedWeights);
            
            % InformativeTags for defect divicion
            defectiveNode = docNode.createElement('defective');
            defectiveNode.setAttribute('tagNames', structDomain.defectiveTagNames);
            defectiveNode.setAttribute('relatedTagNames', structDomain.defectiveRelatedTagNames);
            defectiveNode.setAttribute('frequencies', structDomain.defectiveFrequencies);
            defectiveNode.setAttribute('magnitudes', structDomain.defectiveMagnitudes);
            defectiveNode.setAttribute('prominences', structDomain.defectiveProminences);
            defectiveNode.setAttribute('weights', structDomain.defectiveWeights);

            defectiveNode.setAttribute('percentGrowth', vector2strStandardFormat(structDomain.defectivePercentGrowth));
            defectiveNode.setAttribute('growthStatus', vector2strStandardFormat(structDomain.defectiveGrowthStatus));
            defectiveNode.setAttribute('isInitial', vector2strStandardFormat(structDomain.defectiveIsInitial));
            
            % InformativeTags for defect divicion
            nondefectiveNode = docNode.createElement('nondefective');
            nondefectiveNode.setAttribute('tagNames', structDomain.nondefectiveTagNames);
            nondefectiveNode.setAttribute('relatedTagNames', structDomain.nondefectiveRelatedTagNames);
            nondefectiveNode.setAttribute('frequencies', structDomain.nondefectiveFrequencies);
            nondefectiveNode.setAttribute('magnitudes', structDomain.nondefectiveMagnitudes);
            nondefectiveNode.setAttribute('prominences', structDomain.nondefectiveProminences);
            nondefectiveNode.setAttribute('weights', structDomain.nondefectiveWeights);
            
            domainNode.appendChild(defectiveNode);
            domainNode.appendChild(trainingPeriodNode);
            domainNode.appendChild(nondefectiveNode);
            domainNode.appendChild(validatedNode);
            domainNode.appendChild(unvalidatedNode);
        end
        
        % ADDTRAININGPERIODPARAMETERS function finds trainingPeriod
        % parameters for found peaks and calculates metrics percentGrowth,
        % growthStatus, isInitial
        function [myResult] = addTrainingPeriodParameters(myResult, statusDomain)
            
            freqName = statusDomain.freqName(:,1)';
            
            if isempty(statusDomain.trainingPeriodTagNames) || isempty(freqName{1})
                
                myResult.defectivePercentGrowth = [];
                myResult.defectiveGrowthStatus = [];
                myResult.defectiveIsInitial = [];
                return;
            end
            
            trainingPeriodTagNames = strsplit(statusDomain.trainingPeriodTagNames);
            if ~isempty(statusDomain.trainingPeriodInitialTagNames)
                trainingPeriodInitialTagNames = strsplit(statusDomain.trainingPeriodInitialTagNames);
            else
                trainingPeriodInitialTagNames = {num2str([])};
            end
            
            percentGrowth = nan(size(freqName));
            growthStatus = nan(size(freqName));
            isInitial = nan(size(freqName));
            
            growthStatus = mat2cell(growthStatus, 1, ones(1,length(growthStatus)));
            isInitial = mat2cell(isInitial, 1, ones(1,length(isInitial)));
            
            mean = str2num(statusDomain.trainingPeriodMean);
            magnitudes = str2num(myResult.defectiveMagnitudes{1,1});
            
            
            for i = 1:numel(freqName)
                
                position = find(cellfun(@(x) ismember(x,freqName(i)), trainingPeriodTagNames));
                if ~isempty(position)
                    
                    meanCurrent = mean(position);
                    magnitudeCurrent = magnitudes(position);
                    
                    percentGrowth(i) = round(magnitudeCurrent/meanCurrent,2)*100 - 100; %  in [ % ]
                    growthStatus{i} = statusDomain.trainingPeriodStatus{position};
                end
                
                if nnz(cellfun(@(x) ismember(x,freqName(i)), trainingPeriodInitialTagNames)) > 0
                    isInitial{i} = 'true';
                else
                    isInitial{i} = 'false';
                end
            end
            myResult.defectivePercentGrowth = percentGrowth;
            myResult.defectiveGrowthStatus = growthStatus;
            myResult.defectiveIsInitial = isInitial;
            
        end
    end
end