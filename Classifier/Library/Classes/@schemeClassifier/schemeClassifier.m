classdef schemeClassifier
    %SCHEMECLASSIFIER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        
        tag
        id
        
        classifierStruct
        informativeTags
        
        peakTable
        
%         iHistoryManager
%         isHistoryValid
        
        shaftClassifiers
        bearingClassifiers
        connectionClassifiers
        motorClassifiers
        couplingClassifiers
        fanClassifiers
		
        filledClassifierStruct
        statusStruct
        
        config % configuration structure 
        
        mainFreqStruct % mainFreqStruct contains basic frequencies of each 
                       % element in the scheme
    end
    
    methods (Access = public)
        
        % fuction creates classifier for each element in the kinematics
        function mySchemeClassifier = schemeClassifier(File, classifierStruct, myConfig, modeTimeFrequency, id)
            
            if nargin<5
               id = 1; 
            end
            
            % Mode for timeFrequencyClassifier class
            if nargin < 4
                modeTimeFrequency = 0;
                id = 1;
            end
            
            
            if modeTimeFrequency == 1
                mySchemeClassifier.tag = 'TFD';
            else
                mySchemeClassifier.tag = 'FD';
            end
            
            if ~isfield(File, 'frequencyRefinement')
                File.frequencyRefinement = false;
            end
            
            if nargin < 3 
               mySchemeClassifier.config = []; 
            elseif nargin >= 3
                mySchemeClassifier.config = mySchemeClassifier.setAndConvertConfig(myConfig, File.frequencyRefinement);
            end
            
            mySchemeClassifier.id = id;
            
            
            
            if nargin ~= 0
                mySchemeClassifier.classifierStruct = classifierStruct;
                
                mySchemeClassifier.informativeTags = File.informativeTags;
                
                mySchemeClassifier.peakTable.accelerationEnvelopeSpectrum = single(File.acceleration.envelopeSpectrum.peakTable);
                
                if ~File.frequencyRefinement
                    mySchemeClassifier.peakTable.accelerationSpectrum = single(File.acceleration.spectrum.peakTable);
                    mySchemeClassifier.peakTable.velocitySpectrum = single(File.velocity.spectrum.peakTable);
                    mySchemeClassifier.peakTable.displacementSpectrum = single(File.displacement.spectrum.peakTable);
                end
                % creating a frequency table 
                % Create shaft, bearing, connection & motor classifiers, which
                % contain the main properties of each element & and classify
                % elements defects
                [mySchemeClassifier] = createClassifiers(mySchemeClassifier);
            else
                mySchemeClassifier = createEmptySchemeClassifier(mySchemeClassifier);
            end
        end
        
        
        % Getters / Setters ... 
        function [ classifierStruct ] = getClassifierStruct ( mySchemeClassifier )
            classifierStruct = mySchemeClassifier.classifierStruct;
        end
        function [mySchemeClassifier] = setClassifierStruct(mySchemeClassifier,myClassifierStruct)
            mySchemeClassifier.classifierStruct = myClassifierStruct;
        end
        
        function [myPeakTable] = getPeakTable( mySchemeClassifier)
            myPeakTable = mySchemeClassifier.peakTable;
        end
        function [mySchemeClassifier] = setPeakTable(mySchemeClassifier,myPeakTable)
            mySchemeClassifier.peakTable = myPeakTable;
        end
        
        function [myInformativeTags] = getInformativeTags( mySchemeClassifier)
            myInformativeTags = mySchemeClassifier.informativeTags;
        end
        function [mySchemeClassifier] = setInformativeTags(mySchemeClassifier,myInformativeTags)
            mySchemeClassifier.informativeTags = myInformativeTags;
        end
        
        function [myConfig] = getConfig(mySchemeClassifier)
            myConfig = mySchemeClassifier.config;
        end
        function [mySchemeClassifier] = setConfig(mySchemeClassifier, myConfig)
            mySchemeClassifier.config = myConfig;
        end
        
%         function [myHistoryManager] = getHistoryManager(mySchemeClassifier)
%             myHistoryManager = mySchemeClassifier.iHistoryManager;
%         end
%         function [mySchemeClassifier] = setHistoryManager(mySchemeClassifier,myHistoryManager)
%             mySchemeClassifier.iHistoryManager = myHistoryManager;
%             mySchemeClassifier.isHistoryValid = 1;
%         end
        
        function [myMainFreqStruct] = getMainFreqStruct(mySchemeClassifier)
            myMainFreqStruct = mySchemeClassifier.mainFreqStruct;
        end
        function [mySchemeClassifier] = setMainFreqStruct(mySchemeClassifier,myMainFreqStruct)
            mySchemeClassifier.mainFreqStruct = myMainFreqStruct;
        end
        
        function [ shaftClassifiers ] = getShaftClassifiers ( mySchemeClassifier )
            shaftClassifiers = mySchemeClassifier.shaftClassifiers;
        end
        function [ connectionClassifiers ] = getConnectionClassifiers ( mySchemeClassifier )
            connectionClassifiers = mySchemeClassifier.connectionClassifiers;
        end
        function [ bearingClassifiers ] = getBearingClassifiers ( mySchemeClassifier )
            bearingClassifiers = mySchemeClassifier.bearingClassifiers;
        end
		function [ motorClassifiers ] = getMotorClassifiers ( mySchemeClassifier )
            motorClassifiers = mySchemeClassifier.motorClassifiers;
        end
        function [coplingClassifiers] = getCouplingClassifiers(mySchemeClassifier)
            coplingClassifiers = mySchemeClassifier.couplingClassifiers;
        end
        
        function [myFilledClassifierStruct] = getFilledClassifierStruct ( mySchemeClassifier)
            myFilledClassifierStruct = mySchemeClassifier.filledClassifierStruct;
        end
        function [mySchemeClassifier] = setFilledClassifierStruct(mySchemeClassifier,myFilledClassifierStruct)
            mySchemeClassifier.filledClassifierStruct = myFilledClassifierStruct;
        end
        
        function [myStatusStruct] = getStatusStruct ( mySchemeClassifier)
            myStatusStruct = mySchemeClassifier.statusStruct;
        end
        function [mySchemeClassifier] = setStatusStruct(mySchemeClassifier,myStatusStruct)
            mySchemeClassifier.statusStruct = myStatusStruct;
        end
        
        function [myValidStruct,myFilledPeakTable,nonValidPeaks] = getValidatorStruct( mySchemeClassifier )
            
%             mySchemeClassifier.FilledClassifierStruct = createFilledClassifierStruct ( mySchemeClassifier , signal, Fs );
%             mySchemeClassifier = createFilledClassifierStruct(mySchemeClassifier);

            if isempty(mySchemeClassifier.filledClassifierStruct)
                mySchemeClassifier = createFilledClassifierStruct(mySchemeClassifier);
            end
            
            myFilledClassifierStruct = mySchemeClassifier.filledClassifierStruct;
            myMainFreqStruct = mySchemeClassifier.mainFreqStruct;
            myPeakTable = mySchemeClassifier.peakTable;
            myInformativeTags = mySchemeClassifier.informativeTags;
            myConfig = mySchemeClassifier.config.schemeValidator; % Need to be REVIEWed !!!  
            
            % schemeValidator
            mySchemeValidator = schemeValidator(myFilledClassifierStruct,myPeakTable,myMainFreqStruct,myInformativeTags,myConfig);
            myValidStruct = getValidStruct(mySchemeValidator);
            myFilledPeakTable = getFilledPeakTable(mySchemeValidator);
            nonValidPeaks = getNonValidPeaksNumbers(mySchemeValidator);
            
        end
        function [docNodeStruct] = getDocNode(mySchemeClassifier)
            
            if isempty(mySchemeClassifier.filledClassifierStruct)
                mySchemeClassifier = createFilledClassifierStruct(mySchemeClassifier);
            end
            
            % Create 
            docNode = createDocNode(mySchemeClassifier);
            docNodeStruct.docNode = docNode;
            if(nargout == 0)
                fileName = 'statusFile';
                xmlFileName = fullfile(pwd,'Out',[fileName,'.xml']);
                xmlwrite(xmlFileName,docNode);
                type(xmlFileName); % to displayon the screen
            end
        end
        
    % ... Getters / Setters 
        
        function [myFilledClassifierStruct] = addFilledClassifierStructElement(mySchemeClassifier, myFilledClassifierStruct,elementType,elementNumber)
            
            struct = getClassifierStruct(mySchemeClassifier);  
            myFilledClassifierStruct.([elementType,'Defects']).(elementType){1,elementNumber} = getDefectStatus(mySchemeClassifier.([elementType,'Classifiers']){1,elementNumber},mySchemeClassifier.config.peakComparison);
        
            myFilledClassifierStruct.([elementType,'Defects']).(elementType){1,elementNumber}.name          = struct.([elementType,'Struct']).(elementType)(elementNumber).name;     
            myFilledClassifierStruct.([elementType,'Defects']).(elementType){1,elementNumber}.elementType   = struct.([elementType,'Struct']).(elementType)(elementNumber).classType;
            myFilledClassifierStruct.([elementType,'Defects']).(elementType){1,elementNumber}.priority      = struct.([elementType,'Struct']).(elementType)(elementNumber).priority;
            myElement = getShaftElement(mySchemeClassifier.([elementType,'Classifiers']){1,elementNumber});
            myFilledClassifierStruct.([elementType,'Defects']).(elementType){1,elementNumber}.id            = getId(myElement);
            myFilledClassifierStruct.([elementType,'Defects']).(elementType){1,elementNumber}.enable        = struct.([elementType,'Struct']).(elementType)(elementNumber).enable;
            
            
            switch(elementType)
                case {'shaft','fan'}
                    myFilledClassifierStruct.([elementType,'Defects']).(elementType){1,elementNumber}.baseFreq = struct.([elementType,'Struct']).(elementType)(elementNumber).freq;
                case {'connection'}
                    myFilledClassifierStruct.([elementType,'Defects']).(elementType){1,elementNumber}.baseFreq = struct.([elementType,'Struct']).(elementType)(elementNumber).freq1;
                case {'coupling'}
                    myFilledClassifierStruct.([elementType,'Defects']).(elementType){1,elementNumber}.baseFreq = struct.([elementType,'Struct']).(elementType)(elementNumber).shaftFreq;
                case {'motor'}
                    myFilledClassifierStruct.([elementType,'Defects']).(elementType){1,elementNumber}.baseFreq = struct.([elementType,'Struct']).(elementType)(elementNumber).freq;
                    myFilledClassifierStruct.([elementType,'Defects']).(elementType){1,elementNumber}.model = struct.([elementType,'Struct']).(elementType)(elementNumber).model;     
                case {'bearing'}
                    myFilledClassifierStruct.([elementType,'Defects']).(elementType){1,elementNumber}.baseFreq = struct.([elementType,'Struct']).(elementType)(elementNumber).shaftFreq;
                    myFilledClassifierStruct.([elementType,'Defects']).(elementType){1,elementNumber}.model = struct.([elementType,'Struct']).(elementType)(elementNumber).model;     
                otherwise
                     myFilledClassifierStruct.([elementType,'Defects']).(elementType){1,elementNumber}.baseFreq = struct.([elementType,'Struct']).(elementType)(elementNumber).shaftFreq;
            end

        end
    
    
        function [mySchemeClassifier] = createFilledClassifierStruct (mySchemeClassifier)
                        
            shaftCount = length(mySchemeClassifier.shaftClassifiers);
            connectionCount = length(mySchemeClassifier.connectionClassifiers);
            bearingCount = length(mySchemeClassifier.bearingClassifiers);
            motorCount = length(mySchemeClassifier.motorClassifiers);
            couplingCount = length(mySchemeClassifier.couplingClassifiers);
			fanCount = length(mySchemeClassifier.fanClassifiers);
            
            myFilledClassifierStruct = [];
            
            if(shaftCount >=1)
                for i=1:1:shaftCount
                    
                    [myFilledClassifierStruct] = addFilledClassifierStructElement(mySchemeClassifier, myFilledClassifierStruct,'shaft',i);
                end    
            end

            if(connectionCount >=1)
                for i=1:1:connectionCount
                    [myFilledClassifierStruct] = addFilledClassifierStructElement(mySchemeClassifier, myFilledClassifierStruct,'connection',i);
                end    
            end
            
            if(bearingCount >=1)
                for i=1:1:bearingCount
                    if ~isempty(mySchemeClassifier.bearingClassifiers{1,i})
                        
                        [myFilledClassifierStruct] = addFilledClassifierStructElement(mySchemeClassifier, myFilledClassifierStruct,'bearing',i);
                    end   
                end    
            end
          
            if(motorCount >=1)
                for i=1:1:motorCount
                    
                    [myFilledClassifierStruct] = addFilledClassifierStructElement(mySchemeClassifier, myFilledClassifierStruct,'motor',i);
                end    
            end
            
            if(couplingCount >= 1)
                for i = 1 : 1 : couplingCount
                    
                    [myFilledClassifierStruct] = addFilledClassifierStructElement(mySchemeClassifier, myFilledClassifierStruct,'coupling',i);
                end
            end
            
            if(fanCount >= 1)
                for i = 1 : 1 : fanCount 
                    
                    [myFilledClassifierStruct] = addFilledClassifierStructElement(mySchemeClassifier, myFilledClassifierStruct,'fan',i);
                end
            end
            mySchemeClassifier.filledClassifierStruct = myFilledClassifierStruct;
            
        end
        function [mySchemeClassifier, nonValidPeaks] = createStatusStruct(mySchemeClassifier)
            
            % Get valid structure
            [myValidStruct, ~, nonValidPeaks] = getValidatorStruct(mySchemeClassifier);
            % Get the equipment class
            
            myClassifierStruct = getClassifierStruct(mySchemeClassifier);
            equipmentClass = myClassifierStruct.common.equipmentClass;
            % Evaluate defects
            initialPeakTable = getPeakTable(mySchemeClassifier);
            myDefectEvaluator = defectEvaluator(myValidStruct, equipmentClass, initialPeakTable);
            mySchemeClassifier.statusStruct = getStatusStruct(myDefectEvaluator);

        end
        function [mySchemeClassifier] = refreshClassifiers ( mySchemeClassifier )
            
           [mySchemeClassifier] = deleteClassifiers(mySchemeClassifier );
           [mySchemeClassifier] = createClassifiers(mySchemeClassifier );
           
        end
        
        % CREATEDOCNODE function forms full-filled  docNode containing the
        % main information about each element in the kinematics
        function [docNode] = createDocNode(mySchemeClassifier)
            
            % The docNode header creation
            docNode = com.mathworks.xml.XMLUtils.createDocument('equipment');
            % Create docRoot node
            docRootNode = docNode.getDocumentElement;
            % Set attributes of docRoot node
            % Get device name from equipmentProfile
            equipmentName = mySchemeClassifier.classifierStruct.common.equipmentName;
            docRootNode.setAttribute('name', equipmentName);
            
            docNode = fillDocNode(mySchemeClassifier, docNode);
            
        end
        
        % FILLDOCNODE function adds schemeClassifier result data to
        % existing docNode element
        function [docNode, frequencyDomainClassifierNode] = fillDocNode(mySchemeClassifier, docNode, timeFrequencyMode)
            
            if nargin < 3
                timeFrequencyMode = 0;
            end
            
            myStatusStruct = getStatusStruct(mySchemeClassifier);
            if isempty(myStatusStruct)
                mySchemeClassifier = createStatusStruct(mySchemeClassifier);
                myStatusStruct = getStatusStruct(mySchemeClassifier);
            end
            
            % Create spectraClassifier node
            frequencyDomainClassifierNode = docNode.createElement('frequencyDomainClassifier');
            
            % Get element names
            elementNames = {myStatusStruct.name};
            % Get unique element names
            uniqueElements = unique(elementNames, 'stable');
            % Checking for unique elements in the statusStruct, cutting
            % corresponding to them parts of the statusStruct and putting
            % it into the CREATEELEMENTNODE function for element docNode
            % part creation
            for elementNumber = 1 : 1 : length(uniqueElements)
                currentElementName = uniqueElements{elementNumber};
                currentElementIndex = ismember(elementNames, currentElementName);
                elementStatusStruct = myStatusStruct(currentElementIndex);
                elementNode = createElementNode(mySchemeClassifier, docNode, elementStatusStruct);
                frequencyDomainClassifierNode.appendChild(elementNode);
            end
            if timeFrequencyMode == 0
                % Create docRoot node
                docRootNode = docNode.getDocumentElement;
                % Set specraClassifier node to docRoot node
                docRootNode.appendChild(frequencyDomainClassifierNode);
            end
        end

        % SAVESTATUSIMAGES function saves defect informative features on
        % the signal spectrum image ( *.jpg)
        function saveStatusImages ( mySchemeClassifier, File )
            
            iLoger = loger.getInstance;
            
            myStatusStruct = mySchemeClassifier.statusStruct;
            defectsNumber = length(myStatusStruct);
            % It is recommended to use parfor instead
            
            File.acceleration.frequencyVector = single(File.acceleration.frequencyVector);
            File.velocity.frequencyVector = single(File.velocity.frequencyVector);
            File.displacement.frequencyVector = single(File.displacement.frequencyVector);
            
            if mySchemeClassifier.config.parpoolEnable
                parfor i = 1:1:defectsNumber
                    defectStruct = myStatusStruct(i);
                    plotAndPrint(mySchemeClassifier, File, defectStruct);
                end
            else
                for i = 1:1:defectsNumber
                    defectStruct = myStatusStruct(i);
                    plotAndPrint(mySchemeClassifier, File, defectStruct);
                end
            end
            
            % Check saved images
            spectraTags = {'displacement', 'velocity', 'acceleration', 'accelerationEnvelope'};
            imagesTags = [];
            for spectrumNumber = 1 : 1 : length(spectraTags)
                % Find nonempty spectrum fields
                spectrumName = [spectraTags{spectrumNumber}, 'Spectrum'];
                spectrumIndex = ~cellfun(@isempty, {myStatusStruct.(spectrumName)});
                spectrumStatusStruct = myStatusStruct(spectrumIndex);
                % Find plotted spectrum fields
                spectrumPlotIndex = cellfun(@(defectStruct) ~isempty(getfield(defectStruct, 'mainFrequencyValid')), ...
                    {spectrumStatusStruct.(spectrumName)});
                % Get data for spectrum image tags
                elementSchemeNames = {spectrumStatusStruct(spectrumPlotIndex).name};
                defectTagNames = {spectrumStatusStruct(spectrumPlotIndex).defectTagName};
                % Make spectrum image tags
                spectrumImagesTags = cellfun(@(element, defect) [element, '-', defect], ...
                    elementSchemeNames, defectTagNames, 'UniformOutput', false);
                % Add spectrum image tags to common list
                imagesTags = [imagesTags, spectrumImagesTags];
            end
            
            if checkImages(fullfile(pwd, 'Out'), imagesTags, mySchemeClassifier.config.plot.imageFormat)
                printComputeInfo(iLoger, 'Frequency-domain classifier', 'The method images were saved.')
            end
        end
        
        % CREATEELEMENTNODE function forms docNode for each element
        % containing frequency, magnintudes, frequencyNames &
        % frequnecyTags
        function [elementNode] = createElementNode(mySchemeClassifier, docNode, elementStatusStruct)
            
            % Create element node
            elementNode = docNode.createElement('element');
            % Set attributes of element node
            elementNode.setAttribute('tagName', elementStatusStruct(1).elementType);
            elementNode.setAttribute('class', elementStatusStruct(1).class);
            elementNode.setAttribute('schemeName', elementStatusStruct(1).name);
            elementNode.setAttribute('baseFrequency', num2str(elementStatusStruct(1).baseFreq));
            
            % Get defect tag names in each space
            defectTagNames = {elementStatusStruct.defectTagName};
            
            for defectNumber = 1 : 1 : length(defectTagNames)
                currentDefectName = defectTagNames{defectNumber};
                
                % Create defect node
                defectNode = docNode.createElement('defect');
                % Set attributes of defect node
                defectNode.setAttribute('tagName', currentDefectName);
                
                % Create status node
                statusNode = docNode.createElement('status');
                % Fill status node attributes 
                status = num2str(round(elementStatusStruct(defectNumber).similarity * 100));
                statusNode.setAttribute('value', status);
                statusNode.setAttribute('historyDanger', status);
                statusNode.setAttribute('similarity', status);
                statusNode.setAttribute('historySimilarity', status);
                statusNode.setAttribute('level', elementStatusStruct(defectNumber).level);
                statusNode.setAttribute('durationLevel', '');
                statusNode.setAttribute('similarityTrend', '');
                
                % Create informativeTags node
                informativeTagsNode = docNode.createElement('informativeTags');
                
                elementFieldNames = fieldnames(elementStatusStruct);
                spaceFieldIndex = contains(elementFieldNames, 'Spectrum');
                spaceNames = elementFieldNames(spaceFieldIndex);
                nonEmptySpaceIndex = cellfun(@(spaceName) ~isempty(elementStatusStruct(defectNumber).(spaceName)), spaceNames);
                nonEmptySpaceNames = spaceNames(nonEmptySpaceIndex);
                
                % Check every spaces
                for spaceNumber = 1 : 1 : length(nonEmptySpaceNames)
                    currentSpaceName = nonEmptySpaceNames{spaceNumber};
                    
                    % Find nonintersected elements between
                    % @allDefectFrequencies and @directDefectFrequencies
                    [~, intersectIndex] = intersect(elementStatusStruct(defectNumber).(currentSpaceName).mainFrequencyValid, ...
                        elementStatusStruct(defectNumber).(currentSpaceName).additionalFrequencyValid);
                    nonDefectIndex = setdiff(linspace(1, length(elementStatusStruct(defectNumber).(currentSpaceName).mainFrequencyValid), ...
                        length(elementStatusStruct(defectNumber).(currentSpaceName).mainFrequencyValid)), intersectIndex);
                    
                    % Create validate node containing the main
                    % informativeTags for defect weight calculations
                    validatedNode = docNode.createElement('validated');
                    % Fill validate node attributes
                    validatedNode.setAttribute('tagNames', vector2strStandardFormat(reshape(elementStatusStruct(defectNumber).(currentSpaceName).mainFrequencyNameValid, 1, [])));
                    validatedNode.setAttribute('relatedTagNames', vector2strStandardFormat(reshape(elementStatusStruct(defectNumber).(currentSpaceName).mainFrequencyTagValid, 1, [])));
                    validatedNode.setAttribute('frequencies', vector2strStandardFormat(elementStatusStruct(defectNumber).(currentSpaceName).mainFrequencyValid'));
                    validatedNode.setAttribute('magnitudes', vector2strStandardFormat(elementStatusStruct(defectNumber).(currentSpaceName).mainMagnitudeValid'));
                    validatedNode.setAttribute('prominences', vector2strStandardFormat(elementStatusStruct(defectNumber).(currentSpaceName).mainProminenceValid'));
                    validatedNode.setAttribute('weights', vector2strStandardFormat(elementStatusStruct(defectNumber).(currentSpaceName).mainWeightValid'));
                    
                    % For training period
                    trainingPeriodNode = docNode.createElement('trainingPeriod');
                    trainingPeriodNode.setAttribute('mean', []);
                    trainingPeriodNode.setAttribute('std', []);
                    trainingPeriodNode.setAttribute('relatedTagNames', []);
                    trainingPeriodNode.setAttribute('tagNames', []);
                    trainingPeriodNode.setAttribute('status', []);
                    trainingPeriodNode.setAttribute('initialTagNames', []);
                    
                    % Create unvalidate node containing all
                    % informativeTags (without schemeValidator usage)
                    unvalidatedNode = docNode.createElement('unvalidated');
					% Find nonzeros frequencies index
                    unvalidateIndex = find(elementStatusStruct(defectNumber).(currentSpaceName).mainFrequency > 0);
                    mainFrequencyName = elementStatusStruct(defectNumber).(currentSpaceName).mainFrequencyName(unvalidateIndex);
                    mainFrequencyTag = elementStatusStruct(defectNumber).(currentSpaceName).mainFrequencyTag(unvalidateIndex);
                    % Fill unvalidate node attributes
                    unvalidatedNode.setAttribute('tagNames', vector2strStandardFormat(reshape(mainFrequencyName, 1, [])));
                    unvalidatedNode.setAttribute('relatedTagNames', vector2strStandardFormat(reshape(mainFrequencyTag, 1, [])));
                    unvalidatedNode.setAttribute('frequencies', vector2strStandardFormat(elementStatusStruct(defectNumber).(currentSpaceName).mainFrequency(unvalidateIndex)'));
                    unvalidatedNode.setAttribute('magnitudes', vector2strStandardFormat(elementStatusStruct(defectNumber).(currentSpaceName).mainMagnitude(unvalidateIndex)'));
                    unvalidatedNode.setAttribute('prominences', vector2strStandardFormat(elementStatusStruct(defectNumber).(currentSpaceName).mainProminence(unvalidateIndex)'));
                    unvalidatedNode.setAttribute('weights', vector2strStandardFormat(elementStatusStruct(defectNumber).(currentSpaceName).mainWeight(unvalidateIndex)'));
                    
                    % Create defective node containing space for
                    % spaces division
                    defectiveNode = docNode.createElement('defective');
                    % Fill defective node attributes
                    defectiveNode.setAttribute('tagNames', vector2strStandardFormat(reshape(elementStatusStruct(defectNumber).(currentSpaceName).additionalFrequencyNameValid, 1, [])));
                    defectiveNode.setAttribute('relatedTagNames', vector2strStandardFormat(reshape(elementStatusStruct(defectNumber).(currentSpaceName).additionalFrequencyTagValid, 1, [])));
                    defectiveNode.setAttribute('frequencies', vector2strStandardFormat(elementStatusStruct(defectNumber).(currentSpaceName).additionalFrequencyValid'));
                    defectiveNode.setAttribute('magnitudes', vector2strStandardFormat(elementStatusStruct(defectNumber).(currentSpaceName).additionalMagnitudeValid'));
                    defectiveNode.setAttribute('prominences', vector2strStandardFormat(elementStatusStruct(defectNumber).(currentSpaceName).additionalProminenceValid'));
                    defectiveNode.setAttribute('weights', vector2strStandardFormat(elementStatusStruct(defectNumber).(currentSpaceName).additionalWeightValid'));
                    
                    % Create nondefective node containing space
                    % for spaces division
                    nondefectiveNode = docNode.createElement('nondefective');
                    % Fill nondefective node attributes
                    nondefectiveNode.setAttribute('tagNames', vector2strStandardFormat(reshape(elementStatusStruct(defectNumber).(currentSpaceName).mainFrequencyNameValid(nonDefectIndex, 1), 1, [])));
                    nondefectiveNode.setAttribute('relatedTagNames', vector2strStandardFormat(reshape(elementStatusStruct(defectNumber).(currentSpaceName).mainFrequencyTagValid(nonDefectIndex, 1), 1, [])));
                    nondefectiveNode.setAttribute('frequencies', vector2strStandardFormat(elementStatusStruct(defectNumber).(currentSpaceName).mainFrequencyValid(nonDefectIndex, 1)'));
                    nondefectiveNode.setAttribute('magnitudes', vector2strStandardFormat(elementStatusStruct(defectNumber).(currentSpaceName).mainMagnitudeValid(nonDefectIndex, 1)'));
                    nondefectiveNode.setAttribute('prominences', vector2strStandardFormat(elementStatusStruct(defectNumber).(currentSpaceName).mainProminenceValid(nonDefectIndex, 1)'));
                    nondefectiveNode.setAttribute('weights', vector2strStandardFormat(elementStatusStruct(defectNumber).(currentSpaceName).mainWeightValid(nonDefectIndex, 1)'));
                    
                    % Create space node
                    spaceNode = docNode.createElement(currentSpaceName);
                    
                    % Set defective, nondefective, validate, unvalidate
                    % nodes to space node
                    spaceNode.appendChild(defectiveNode);
                    spaceNode.appendChild(trainingPeriodNode);
                    spaceNode.appendChild(nondefectiveNode);
                    spaceNode.appendChild(validatedNode);
                    spaceNode.appendChild(unvalidatedNode);
                    
                    % Set space node to informativeTags node
                    informativeTagsNode.appendChild(spaceNode);
                end
                
                % Set status, informativeTags node to defect node
                defectNode.appendChild(statusNode);
                defectNode.appendChild(informativeTagsNode);
                % Set defect node to element node
                elementNode.appendChild(defectNode);
            end
        end
        
        % CREATEEMPTYSCHENECLASSIFIER function create empty object
        function mySchemeClassifier = createEmptySchemeClassifier(mySchemeClassifier)
            
            mySchemeClassifier.classifierStruct = [];
            mySchemeClassifier.informativeTags = [];
        
            mySchemeClassifier.peakTable = [];

            mySchemeClassifier.shaftClassifiers = [];
            mySchemeClassifier.bearingClassifiers = [];
            mySchemeClassifier.connectionClassifiers = [];
            mySchemeClassifier.motorClassifiers = [];
            mySchemeClassifier.couplingClassifiers = [];
            mySchemeClassifier.fanClassifiers = [];
		
            mySchemeClassifier.filledClassifierStruct = [];
            mySchemeClassifier.statusStruct = [];
        
            mySchemeClassifier.config = [];
        
            mySchemeClassifier.mainFreqStruct = [];
        end
    end
    
    methods (Access = protected)
        
%         [ s ] = xml2struct( file );
        
        function [mySchemeClassifier] = createClassifiers ( mySchemeClassifier )
%                 iLoger = loger.getInstance;
%                 printComputeInfo(iLoger, 'Scheme classifier', 'Proceed to create classifier.');
            
            struct = getClassifierStruct(  mySchemeClassifier );  
            frequencyTable = getPeakTable( mySchemeClassifier );
            
            % If exist, create shaftClassifiers
            if isfield(struct, 'shaftStruct')
                if isfield(struct.shaftStruct, 'shaft')
                    shaftCount = length(struct.shaftStruct.shaft);
                    for shaftNumber = 1:1:shaftCount
                        [mySchemeClassifier] = addShaftClassifier( mySchemeClassifier, shaftNumber, frequencyTable);
                    end
                end
            end
            
            % If exist, create bearingClassifiers
            if isfield(struct, 'bearingStruct')
                if isfield(struct.bearingStruct, 'bearing')
                    bearingCount = length(struct.bearingStruct.bearing);
                    for bearingNumber = 1:1:bearingCount
                        [mySchemeClassifier] = addBearingClassifier( mySchemeClassifier, bearingNumber, frequencyTable);
                    end
                end
            end            
            
            % If exist, create connectionClassifiers
            if isfield(struct, 'connectionStruct')
                if isfield(struct.connectionStruct, 'connection')
                    connectionCount = length(struct.connectionStruct.connection);
                    for connectionNumber = 1:1:connectionCount
                        [mySchemeClassifier] = addConnectionClassifier( mySchemeClassifier, connectionNumber, frequencyTable);
                    end
                end
            end      
        
            % If exist, create motorClassifiers
            if isfield(struct, 'motorStruct')
                if isfield(struct.motorStruct, 'motor')
                    motorCount = length(struct.motorStruct.motor);
                    for motorNumber = 1:1:motorCount
                        [mySchemeClassifier] = addMotorClassifier( mySchemeClassifier, motorNumber, frequencyTable);
                    end
                end
            end
            
            % If exist, create couplingClassifiers
            if isfield(struct, 'couplingStruct')
                if isfield(struct.couplingStruct, 'coupling')
                    couplingCount = length(struct.couplingStruct.coupling);
                    for couplingNumber = 1:1:couplingCount
                        [mySchemeClassifier] = addCouplingClassifier( mySchemeClassifier, couplingNumber, frequencyTable);
                    end
                end
            end
            
            % If exist, create fanClassifiers
            if isfield(struct, 'fanStruct')
                if isfield(struct.fanStruct, 'fan')
                    fanCount = length(struct.fanStruct.fan);
                    for fanNumber = 1:1:fanCount
                        [mySchemeClassifier] = addFanClassifier( mySchemeClassifier, fanNumber, frequencyTable);
                    end
                end
            end
            
%                 printComputeInfo(iLoger, 'Scheme classifier', 'Creation classifier is COMPLETE.');
        end
        
        function [mySchemeClassifier] = deleteClassifiers ( mySchemeClassifier )
            mySchemeClassifier.shaftClassifiers = [];
            mySchemeClassifier.connectionClassifiers = [];
            mySchemeClassifier.bearingClassifiers = [];
            mySchemeClassifier.motorClassifiers = [];
            mySchemeClassifier.mainFreqStruct = [];
        end
        
        function [mySchemeClassifier] = addShaftClassifier ( mySchemeClassifier, shaftNumber, frequencyTable )
            struct = getClassifierStruct(  mySchemeClassifier );
            
            if isfield(struct, 'shaftStruct')
                if isfield(struct.shaftStruct, 'shaft')
                    myClassType = struct.shaftStruct.shaft(shaftNumber).classType;
                    myElementType = struct.shaftStruct.shaft(shaftNumber).elementType;
                    myShaftName = struct.shaftStruct.shaft(shaftNumber).name;
                    myShaftFreq = struct.shaftStruct.shaft(shaftNumber).freq;
                    myShaft = shaft(myClassType, myShaftName, myShaftFreq);
                    
                    % Set element in the mainFreqStruct
                    element.elementType = myClassType;
                    element.classType = myElementType;
                    element.name = myShaftName;
                    element.basicFreqs = getBasicFreqList(myShaft);                        
                    [mySchemeClassifier] = addMainFreqStructElement(mySchemeClassifier,element);
                    
                    myClassifierType = 'shaftClassifier';
                    myShaftClassifier = shaftClassifier(mySchemeClassifier.informativeTags,myClassifierType,myShaft, frequencyTable);
                    
                    % If there is no shaft element yet, add one
                    if isempty(mySchemeClassifier.shaftClassifiers)
                        mySchemeClassifier.shaftClassifiers{1,1} = myShaftClassifier;
                    else
                        mySchemeClassifier.shaftClassifiers{1,end+1} = myShaftClassifier;
                    end
                    
                end
            end
        end
        function [mySchemeClassifier] = addConnectionClassifier(mySchemeClassifier, connectionNumber, frequencyTable)
            struct = getClassifierStruct(mySchemeClassifier);
            if isfield(struct, 'connectionStruct')
                if isfield(struct.connectionStruct, 'connection')
                    myClassType = struct.connectionStruct.connection(connectionNumber).classType;
                    myElementType = struct.connectionStruct.connection(connectionNumber).elementType;
%                     myModel = struct.connectionStruct.connection(connectionNumber).model;
                    myName = struct.connectionStruct.connection(connectionNumber).name;
                    myShaftFreq1 = struct.connectionStruct.connection(connectionNumber).freq1;
%                     myShaftFreq2 = struct.connectionStruct.connection(connectionNumber).freq2;
                    
                    if strfind(myClassType, 'gearing')
                        
                        myZ1 = struct.connectionStruct.connection(connectionNumber).z1;
                        myZ2 = struct.connectionStruct.connection(connectionNumber).z2;
                        myConnection = gearing(myElementType, myClassType, myName, myShaftFreq1, myZ1, myZ2);
                    elseif strfind(myClassType, 'smoothBelt')
                        
                        myBeltLength = struct.connectionStruct.connection(connectionNumber).beltLength;
                        mySheaveDiameter1 = struct.connectionStruct.connection(connectionNumber).sheaveDiameter1;
                        mySheaveDiameter2 = struct.connectionStruct.connection(connectionNumber).sheaveDiameter2;
                        myConnection = smoothBelt(myElementType, myClassType, myName, myShaftFreq1, mySheaveDiameter1, mySheaveDiameter2, myBeltLength);
                    elseif strfind(myClassType, 'toothedBelt')
                        
                        myBeltLength = struct.connectionStruct.connection(connectionNumber).beltLength;
                        mySheaveDiameter1 = struct.connectionStruct.connection(connectionNumber).sheaveDiameter1;
                        mySheaveDiameter2 = struct.connectionStruct.connection(connectionNumber).sheaveDiameter2;
                        myZ1 = struct.connectionStruct.connection(connectionNumber).z1;
                        myConnection = toothedBelt(myElementType, myClassType, myName, myShaftFreq1, mySheaveDiameter1, mySheaveDiameter2, myBeltLength, myZ1);
                    elseif strfind(myClassType, 'planetaryStageGearbox')
                        
                        myZ1 = struct.connectionStruct.connection(connectionNumber).z1;
                        myZ2 = struct.connectionStruct.connection(connectionNumber).z2;
                        myPlanetWheelNumber = struct.connectionStruct.connection(connectionNumber).planetWheelNumber;
                        myTeethNumberRingGear= struct.connectionStruct.connection(connectionNumber).teethNumberRingGear;
                        myPositionPlanetWheel = struct.connectionStruct.connection(connectionNumber).positionPlanetWheel;
                        
                        myConnection = planetaryStageGearbox(myElementType, myClassType, myName, myShaftFreq1, ...
                                                             myZ1, myZ2, myPlanetWheelNumber, myTeethNumberRingGear, myPositionPlanetWheel);
                    end
                    
                    % Set element in the mainFreqStruct
                    element.elementType = myElementType;
                    element.classType = myClassType;
                    element.name = myName;
                    element.basicFreqs = getBasicFreqList(myConnection);                        
                    [mySchemeClassifier] = addMainFreqStructElement(mySchemeClassifier,element);
                    
                    myClassifierType = 'connectionClassifier';
                    myConnectionClassifier = connectionClassifier(mySchemeClassifier.informativeTags, myClassifierType, myConnection, frequencyTable);
                    
                    % If there is no connenction element yet, add one
                    if isempty(mySchemeClassifier.connectionClassifiers)
                        mySchemeClassifier.connectionClassifiers{1,1} = myConnectionClassifier;
                    else
                        mySchemeClassifier.connectionClassifiers{1,end+1} = myConnectionClassifier;
                    end
                end
            end
        end  
        function [mySchemeClassifier] = addBearingClassifier ( mySchemeClassifier, bearingNumber, frequencyTable)
            struct = getClassifierStruct(  mySchemeClassifier );
            if isfield(struct, 'bearingStruct')
                if isfield(struct.bearingStruct, 'bearing')
                    myElementType = struct.bearingStruct.bearing(bearingNumber).elementType;
                    myClassType = struct.bearingStruct.bearing(bearingNumber).classType;
%                     myClass = struct.bearingStruct.bearing(bearingNumber).class;
                    myModel = struct.bearingStruct.bearing(bearingNumber).model;
                    myName = struct.bearingStruct.bearing(bearingNumber).name;
                    myShaftFreq = struct.bearingStruct.bearing(bearingNumber).shaftFreq;
                    
                    if strfind(myClassType, 'rollingBearing')
                        myBd = struct.bearingStruct.bearing(bearingNumber).Bd;
                        myPd = struct.bearingStruct.bearing(bearingNumber).Pd;
                        myNb = struct.bearingStruct.bearing(bearingNumber).Nb;
                        myAngle = struct.bearingStruct.bearing(bearingNumber).angle;
                        myBearing = rollingBearing(myElementType,myClassType,myModel,myName,myShaftFreq,myBd,myPd,myNb,myAngle);
                    elseif strfind(myClassType, 'plainBearing')
                        myBearing = plainBearing(myElementType,myClassType, myModel, myName, myShaftFreq);
                    end
                    
                    % Set element in the mainFreqStruct
                    element.elementType = myElementType;
                    element.classType = myClassType;
                    element.name = myName;
                    element.basicFreqs = getBasicFreqList(myBearing);                        
                    [mySchemeClassifier] = addMainFreqStructElement(mySchemeClassifier,element);
                    
                    myClassifierType = 'bearingClassifier';
                    myBearingClassifier = bearingClassifier(mySchemeClassifier.informativeTags, myClassifierType, myBearing, frequencyTable);
                    
                    % If there is no bearing element yet, add one
                    if isempty(mySchemeClassifier.bearingClassifiers)
                        mySchemeClassifier.bearingClassifiers{1,1} = myBearingClassifier;
                    else
                        mySchemeClassifier.bearingClassifiers{1,end+1} = myBearingClassifier;
                    end
                end  
            end
        end
		function [mySchemeClassifier] = addMotorClassifier (mySchemeClassifier, motorNumber, frequencyTable)
            struct = getClassifierStruct(mySchemeClassifier);
             if isfield(struct, 'motorStruct')
                if isfield(struct.motorStruct, 'motor')
                    myElementType = struct.motorStruct.motor(motorNumber).elementType;
                    myClassType = struct.motorStruct.motor(motorNumber).classType;
                    myModel = struct.motorStruct.motor(motorNumber).model;
                    myName = struct.motorStruct.motor(motorNumber).name;
                    myShaftFreq = struct.motorStruct.motor(motorNumber).freq;
                    myLineFreq = struct.motorStruct.motor(motorNumber).lineFrequency;
                    
                    if strfind(myClassType, 'inductionMotor')
                        myBarsNumber = struct.motorStruct.motor(motorNumber).barsNumber;
                        myPolePairsNumber = struct.motorStruct.motor(motorNumber).polePairsNumber;
                        myMotor = inductionMotor(myElementType, myClassType, myModel, myName, myShaftFreq, myLineFreq, myBarsNumber, myPolePairsNumber);
                    elseif strfind(myClassType, 'synchronousMotor')
                        myCoilsNumber = struct.motorStruct.motor(motorNumber).coilsNumber;
                        myMotor = synchronousMotor(myElementType, myClassType, myModel, myName, myShaftFreq, myLineFreq, myCoilsNumber);
                    elseif strfind(myClassType, 'directCurrentMotor')
                        
                        myCollectorPlatesNumber = struct.motorStruct.motor(motorNumber).collectorPlatesNumber;
                        myArmatureTeethNumber = struct.motorStruct.motor(motorNumber).armatureTeethNumber ;
                        myRectifierType = struct.motorStruct.motor(motorNumber).rectifierType;
                        myPolePairsNumber = struct.motorStruct.motor(motorNumber).polePairsNumber;
                        myMotor = directCurrentMotor(myElementType, myClassType, myModel, myName, myShaftFreq, myLineFreq, ...
                            myCollectorPlatesNumber, myPolePairsNumber, myArmatureTeethNumber, myRectifierType);
                    end
                    
                    % Set element in the mainFreqStruct
                    element.elementType = myElementType;
                    element.classType = myClassType;
                    element.name = myName;
                    element.basicFreqs = getBasicFreqList(myMotor);
                    [mySchemeClassifier] = addMainFreqStructElement(mySchemeClassifier, element);
                    
                    myClassifierType = 'motorClassifier';
                    myMotorClassifier = motorClassifier(mySchemeClassifier.informativeTags, myClassifierType, myMotor, frequencyTable);
                    
                    % If there is no motor element yet, add one
                    if isempty(mySchemeClassifier.motorClassifiers)
                        mySchemeClassifier.motorClassifiers{1, 1} = myMotorClassifier;
                    else
                        mySchemeClassifier.motorClassifiers{1, end + 1} = myMotorClassifier;
                    end
                end
            end
        end
        function [mySchemeClassifier] = addCouplingClassifier (mySchemeClassifier, couplingNumber, frequencyTable)
            struct = getClassifierStruct(mySchemeClassifier);
            if isfield(struct, 'couplingStruct')
                if isfield(struct.couplingStruct, 'coupling')
                    myClassType = struct.couplingStruct.coupling(couplingNumber).classType;
                    myName = struct.couplingStruct.coupling(couplingNumber).name;
                    myShaftFreq = struct.couplingStruct.coupling(couplingNumber).shaftFreq;
                    myCoupling = coupling(myClassType, myName, myShaftFreq);
                    
                    % Set element in the mainFreqStruct
                    element.elementType = myClassType;
                    element.classType = myClassType;
                    element.name = myName;
                    element.basicFreqs = getBasicFreqList(myCoupling);                        
                    [mySchemeClassifier] = addMainFreqStructElement(mySchemeClassifier, element);
                    
                    myClassifierType = 'couplingClassifier';
                    myCouplingClassifier = couplingClassifier(mySchemeClassifier.informativeTags, myClassifierType, myCoupling, frequencyTable);
                    
                    % If there is no shaft element yet, add one
                    if isempty(mySchemeClassifier.couplingClassifiers)
                        mySchemeClassifier.couplingClassifiers{1, 1} = myCouplingClassifier;
                    else
                        mySchemeClassifier.couplingClassifiers{1, end + 1} = myCouplingClassifier;
                    end
                end
            end
        end        
        function [mySchemeClassifier] = addFanClassifier (mySchemeClassifier, fanNumber, frequencyTable)
            struct = getClassifierStruct(  mySchemeClassifier );
             if isfield(struct, 'fanStruct')
                if isfield(struct.fanStruct, 'fan') 
                    myClassType = struct.fanStruct.fan(fanNumber).classType;
                    myModel = struct.fanStruct.fan(fanNumber).model;
                    myName = struct.fanStruct.fan(fanNumber).name;
                    myShaftFreq = struct.fanStruct.fan(fanNumber).freq;
                    myBladesNumber = struct.fanStruct.fan(fanNumber).bladesNumber;
                    myFan = fan(myClassType, myModel, myName, myShaftFreq, myBladesNumber );
                end
                
                % Set element in the mainFreqStruct
                element.elementType = myClassType;
                element.classType = myClassType;
                element.name = myName;
                element.basicFreqs = getBasicFreqList(myFan);                        
                [mySchemeClassifier] = addMainFreqStructElement(mySchemeClassifier,element);
                
                myClassifierType = 'fanClassifier';
                myFanClassifier = fanClassifier(mySchemeClassifier.informativeTags, myClassifierType, myFan, frequencyTable);

                % If there is no fan element yet, add one
                if isempty(mySchemeClassifier.fanClassifiers)
                    mySchemeClassifier.fanClassifiers{1,1} = myFanClassifier;
                else
                    mySchemeClassifier.fanClassifiers{1,end+1} = myFanClassifier;
                end
            end
            
        end
        
        % function to add element to the end of struct. Each element
        % consists of element class, name and mainFreqs list;
        function [mySchemeClassifier]= addMainFreqStructElement(mySchemeClassifier,element)
            myMainFreqStruct = getMainFreqStruct(mySchemeClassifier);
            if nargin == 2 && ~isempty(element)
                if isfield(myMainFreqStruct, 'element')
                    myMainFreqStruct.element(end+1,1) = element;
                else
                    myMainFreqStruct.element = element;
                end
            end
            [mySchemeClassifier] = setMainFreqStruct(mySchemeClassifier,myMainFreqStruct);
        end
        
        % PLOTANDPRINT function draws envSpectrum with informative
        % frequencies (main and additional) on it for current defect
        function plotAndPrint(mySchemeClassifier, File, DefectStruct)
            
            % Get parameters
            domainTag = mySchemeClassifier.tag;
            Translations = File.translations;
            
            debugModeEnable = mySchemeClassifier.config.plot.debugModeEnable;
            printPlotsEnable = mySchemeClassifier.config.plot.printPlotsEnable;
            plotVisible = mySchemeClassifier.config.plot.plotVisible;
            plotTitle = mySchemeClassifier.config.plot.plotTitle;
            
            sizeUnits = mySchemeClassifier.config.plot.sizeUnits;
            imageSize = mySchemeClassifier.config.plot.imageSize;
            fontSize = mySchemeClassifier.config.plot.fontSize;
            imageFormat = mySchemeClassifier.config.plot.imageFormat;
            imageQuality = mySchemeClassifier.config.plot.imageQuality;
            imageResolution = mySchemeClassifier.config.plot.imageResolution;
            
            % Find spectrum fields
            defectStructFieldNames = fieldnames(DefectStruct);
            allSpectrumFieldIndex = cellfun(@(fieldName) contains(fieldName, 'Spectrum'), defectStructFieldNames);
            allSpectrumFieldNames = defectStructFieldNames(allSpectrumFieldIndex);
            
            for spectrumNumber = 1 : 1 : length(allSpectrumFieldNames)
                
                % Get the field name of the spectrum
                spectrumFieldName = allSpectrumFieldNames{spectrumNumber};
                % Get the spectrum defectStruct
                SpectrumDefectStruct = DefectStruct.(spectrumFieldName);
                
                if ~isempty(SpectrumDefectStruct)
                    
                    % Get valid frequencies data
                    mainFrequency = SpectrumDefectStruct.mainFrequencyValid;
                    mainFrequencyName = SpectrumDefectStruct.mainFrequencyNameValid;
                    additionalFrequency = SpectrumDefectStruct.additionalFrequencyValid;
                    additionalFrequencyName = SpectrumDefectStruct.additionalFrequencyNameValid;
                    
                    mainFrequencyLength = length(mainFrequency);
                    if mainFrequencyLength
                        
                        % Get the signal type and the spectrum type
                        [signalType, spectrumType] = strsplit(spectrumFieldName, {'Envelope', 'Spectrum'});
                        signalType = signalType{1};
                        spectrumType = spectrumType{1};
                        spectrumType(1) = lower(spectrumType(1));
                        % Get the short signal type and the signal type
                        % translation
                        switch signalType
                            case 'acceleration'
                                if strcmp(spectrumType, 'envelopeSpectrum')
                                    shortSignalType = 'env';
                                    spectrumTypeTranslation = Translations.envelopeSpectrum.Attributes.name;
                                else
                                    shortSignalType = 'acc';
                                    spectrumTypeTranslation = Translations.spectrum.Attributes.name;
                                end
                                signalTypeTranslation = Translations.acceleration.Attributes.name;
                                units = Translations.acceleration.Attributes.value;
                            case 'velocity'
                                shortSignalType = 'vel';
                                spectrumTypeTranslation = Translations.spectrum.Attributes.name;
                                signalTypeTranslation = Translations.velocity.Attributes.name;
                                units = Translations.velocity.Attributes.value;
                            case 'displacement'
                                shortSignalType = 'disp';
                                spectrumTypeTranslation = Translations.spectrum.Attributes.name;
                                signalTypeTranslation = Translations.displacement.Attributes.name;
                                units = Translations.displacement.Attributes.value;
                            otherwise
                                shortSignalType = 'acc';
                                spectrumTypeTranslation = Translations.spectrum.Attributes.name;
                                signalTypeTranslation = Translations.acceleration.Attributes.name;
                                units = Translations.acceleration.Attributes.value;
                        end
                        
                        % Get spectrum data
                        spectrum = File.(signalType).(spectrumType).amplitude;
                        frequency = File.(signalType).frequencyVector;
                        
                        % Plot
                        myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
                        myPlot = plot(frequency, spectrum);
                        grid on;
                        
                        % Get axes data
                        myAxes = myFigure.CurrentAxes;
                        % Set axes font size
                        myAxes.FontSize = fontSize;
                        
                        % Figure title
                        if strcmp(plotTitle, 'on')
                            title(myAxes, [upperCase(Translations.element.Attributes.name, 'first'), ' - ', DefectStruct.name, ' : ', ...
                                upperCase(Translations.defect.Attributes.name, 'first'), ' - ', DefectStruct.defectName, ' : ', ...
                                upperCase(spectrumTypeTranslation, 'allFirst'), ' - ', upperCase(signalTypeTranslation, 'first')]);
                        end
                        % Figure labels
                        xlabel(myAxes, [upperCase(Translations.frequency.Attributes.name, 'first'), ', ', ...
                            upperCase(Translations.frequency.Attributes.value, 'first')]);
                        ylabel(myAxes, [upperCase(Translations.magnitude.Attributes.name, 'first'), ', ', units]);
                        
                        % Set axes limits
                        xScale = 1.2;
                        yScale = 1.2;
                        df = File.(signalType).df;
                        xMax = max(mainFrequency) * xScale;
                        if xMax < 100
                            xMax = 100;
                        end
                        if length(spectrum( : , 1)) < ceil(xMax / df)
                            yMax = max(spectrum(10 : end, 1)) * yScale;
                        else
                            yMax = max(spectrum(10 : ceil(xMax / df), 1)) * yScale;
                        end
                        xlim(myAxes, [0 xMax]);
                        ylim(myAxes, [0 yMax]);
                        
                        % Get @Line class to add datatips
                        myLine = handle(myPlot);
                        
                        % Mark @additionalFrequencyValid
                        additionalMarkerColor = 'r';
                        additionalFrequencyPositions = arrayfun(@(freq) find(frequency == freq), additionalFrequency);
                        additionalMagnitude = spectrum(additionalFrequencyPositions);
                        if debugModeEnable
                            addDatatips(mySchemeClassifier, myLine, additionalFrequencyPositions, additionalFrequencyName, additionalMarkerColor, fontSize / 2);
                            if ~isempty(additionalFrequencyPositions)
                                hold on;
                                stem(additionalFrequencyPositions(1), additionalMagnitude(1), ...
                                    'LineStyle', 'none', 'LineWidth', 1, ...
                                    'Marker', 'o', 'MarkerSize', 10, 'MarkerEdgeColor', additionalMarkerColor, 'MarkerFaceColor', 'none');
                                hold off;
                            end
                        else
                            myFigure = mySchemeClassifier.markFrequencies(myFigure, additionalFrequency, additionalMagnitude, additionalFrequencyName, additionalMarkerColor, fontSize / 2);
                        end
                        
                        % Find nonintersected elements between
                        % @mainFrequencyValid and @additionsFrequencyValid
%                         [~, intersectIndex] = intersect(mainFrequency, additionalFrequency);
%                         nonIntersectIndex = setdiff(linspace(1, mainFrequencyLength, mainFrequencyLength), intersectIndex);
                        nonIntersectIndex = ~ismember(mainFrequency, additionalFrequency);
                        
                        % Mark @mainFrequencyValid (not
                        % @additionalFrequencyValid)
                        nonIntersectMarkerColor = 'g';
                        if ~isempty(nonIntersectIndex)
                            nonIntersectFrequency = mainFrequency(nonIntersectIndex, 1);
                            nonIntersectFrequencyPositions = arrayfun(@(freq) find(frequency == freq), nonIntersectFrequency);
                            nonIntersectMagnitude = spectrum(nonIntersectFrequencyPositions);
                            nonIntersectFrequencyName = mainFrequencyName(nonIntersectIndex, 1);
                            if debugModeEnable
                                addDatatips(mySchemeClassifier, myLine, nonIntersectFrequencyPositions, nonIntersectFrequencyName, nonIntersectMarkerColor, fontSize / 2);
                                if ~isempty(nonIntersectFrequencyPositions)
                                    hold on;
                                    stem(nonIntersectFrequencyPositions(1), nonIntersectMagnitude(1), ...
                                        'LineStyle', 'none', 'LineWidth', 1, ...
                                        'Marker', 'o', 'MarkerSize', 10, 'MarkerEdgeColor', nonIntersectMarkerColor, 'MarkerFaceColor', 'none');
                                    hold off;
                                end
                            else
                                myFigure = mySchemeClassifier.markFrequencies(myFigure, nonIntersectFrequency, nonIntersectMagnitude, nonIntersectFrequencyName, nonIntersectMarkerColor, fontSize / 2);
                            end
                            
                            % Display legend
                            legend('Spectrum', 'Valid peaks', 'Invalid peaks');
                        else
                            % Display legend
                            legend('Spectrum', 'Valid peaks');
                        end
                        
                        if debugModeEnable
                            % Debug mode
                            text(xMax * 0.020, yMax * 0.975, ['Similarity: ', num2str(round(DefectStruct.similarity * 100)), '%'], ...
                                'FontSize', fontSize, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
                                'BackgroundColor', 'w', 'EdgeColor', 'k');
                        end
                        
                        if printPlotsEnable
                            % Save the image to the @Out directory
%                             imageNumber = '1';
                            imageNumber = num2str(mySchemeClassifier.id);
                            fileName = [DefectStruct.elementType, '-', DefectStruct.name, '-', DefectStruct.defectTagName, '-', shortSignalType, '-', domainTag, '-', imageNumber];
                            fullFileName = fullfile(pwd, 'Out', fileName);
                            print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
                        end
                        
                        % Close figure with visibility off
                        if strcmpi(plotVisible, 'off')
                            close(myFigure)
                        end
                    end
                end
            end
            
            
        end
        
        function [myDtip, myLine] = addDatatips(mySchemeClassifier, myLine, frequenciesPositions, frequenciesNames, markerColor, fontSize)
            
            cursorMode = datacursormode(gcf);
            set(cursorMode, 'UpdateFcn', @mySchemeClassifier.customDatatipFunction);
            xData = get(myLine, 'XData');
            yData = get(myLine, 'YData');
            
            for freqPosition = 1 : 1 : numel(frequenciesPositions)
                freqIndex = frequenciesPositions(freqPosition);
                pause(0.0001)
                set(myLine, 'UserData', frequenciesNames{freqPosition});
                if (freqIndex > 0)
                    myDtip(freqPosition) = cursorMode.createDatatip(myLine);
                    set(myLine, 'UserData', frequenciesNames{freqPosition});
                    set(myDtip(freqPosition), 'FontSize', fontSize, ...
                        'Marker', 'o', 'MarkerSize', 10, 'MarkerFaceColor', 'none', 'MarkerEdgeColor', markerColor, ...
                        'HitTest', 'off');
                    set(myLine, 'UserData', frequenciesNames{freqPosition});
                    dtipPosition = [xData(freqIndex), yData(freqIndex), 1];
                    set(myLine, 'UserData', frequenciesNames{freqPosition});
                    myDtip(freqPosition).Position = dtipPosition;
                    set(myLine, 'UserData', frequenciesNames{freqPosition});
                else
                    myDtip(freqPosition) = cursorMode.createDatatip(myLine);
                end
                set(myLine, 'UserData', frequenciesNames{freqPosition});
            end
        end
        
    end
    
    methods (Static)
        
        function [text] = customDatatipFunction(~, event)
            
            position = get(event, 'Position');
            frequencyName = event.Target.UserData;
            text = { ...
                frequencyName, ...
                [num2str(position(1), 4), ' Hz']};
            clear frequencyName;
        end
        
        function [myFigure, myStem, myText] = markFrequencies(myFigure, frequencies, magnitudes, descriptions, markerColor, fontSize)
            
            hold on
            % Plot markers
            myStem = stem(frequencies, magnitudes, ...
                'LineStyle', 'none', 'LineWidth', 1, ...
                'Marker', 'o', 'MarkerSize', 10, 'MarkerEdgeColor', markerColor, 'MarkerFaceColor', 'none');
            % Make marker descriptions
            textContent = cellfun(@(name, frequency) {name, [num2str(frequency), ' Hz']}, descriptions, num2cell(frequencies), ...
                'UniformOutput', false);
            if length(textContent) == 1
                textContent = textContent{1};
            end
            % Set text boxes background color
            switch markerColor
                case 'r'
                    BackgroundColor = [1 0.9 0.9];
                case 'g'
                    BackgroundColor = [0.9 1 0.9];
            end
            % Find repetitive frequencies
            [~, uniqueIndex] = unique(frequencies);
            alignmentIndex{1} = uniqueIndex;
            repetitiveIndex = setdiff(linspace(1, length(frequencies), length(frequencies))', uniqueIndex);
            repetitiveFrequencies = frequencies(repetitiveIndex);
            for i = 2 : 1 : 4
                [~, currentUniqueIndex] = unique(repetitiveFrequencies);
                uniqueIndex = repetitiveIndex(currentUniqueIndex);
                if i == 4
                    alignmentIndex{i} = repetitiveIndex;
                else
                    alignmentIndex{i} = uniqueIndex;
                end
                repetitiveIndex = setdiff(repetitiveIndex, uniqueIndex);
                repetitiveFrequencies = frequencies(repetitiveIndex);
            end
            % Add descriptions to markers
            myText = text(double(frequencies), magnitudes, textContent, ...
                'FontSize', fontSize, ...
                'EdgeColor', [0.8 0.8 0.8], 'BackgroundColor', BackgroundColor, 'Margin', 1, 'LineWidth', 1, ...
                'Units', 'data', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
            % Place text boxes outside the markers and set text boxes
            % alignment
            set(myText, 'Units', 'points');
            arrayfun(@(textObject) set(textObject, 'Position', textObject.Position + [6, 6, 0]), myText(alignmentIndex{1}));
            arrayfun(@(textObject) set(textObject, 'Position', textObject.Position + [6, -6, 0]), myText(alignmentIndex{2}));
            arrayfun(@(textObject) set(textObject, 'Position', textObject.Position + [-6, -6, 0]), myText(alignmentIndex{3}));
            arrayfun(@(textObject) set(textObject, 'Position', textObject.Position + [-6, 6, 0]), myText(alignmentIndex{4}));
            arrayfun(@(textObject) set(textObject, 'HorizontalAlignment', 'right'), ...
                myText([alignmentIndex{3}; alignmentIndex{4}]));
            arrayfun(@(textObject) set(textObject, 'VerticalAlignment', 'top'), ...
                myText([alignmentIndex{2}; alignmentIndex{3}]));
            set(myText, 'Units', 'data');
            hold off
        end
        
        function config = setAndConvertConfig(myConfig, frequencyRefinement)
            
            % Set parameters for plot
            config.plot.debugModeEnable = logical(str2double(myConfig.config.parameters.common.debugModeEnable.Attributes.value));
            config.plot.printPlotsEnable = logical(str2double(myConfig.config.parameters.common.printPlotsEnable.Attributes.value));
            config.plot.plotVisible = myConfig.config.parameters.common.printPlotsEnable.Attributes.visible;
            config.plot.plotTitle = myConfig.config.parameters.common.printPlotsEnable.Attributes.title;
            
            config.plot.sizeUnits = myConfig.config.parameters.evaluation.plots.Attributes.sizeUnits;
            config.plot.imageSize = str2num(myConfig.config.parameters.evaluation.plots.Attributes.imageSize);
            config.plot.fontSize = str2double(myConfig.config.parameters.evaluation.plots.Attributes.fontSize);
            config.plot.imageFormat = myConfig.config.parameters.evaluation.plots.Attributes.imageFormat;
            config.plot.imageQuality = myConfig.config.parameters.evaluation.plots.Attributes.imageQuality;
            config.plot.imageResolution = myConfig.config.parameters.evaluation.plots.Attributes.imageResolution;
            
            % Set parameters for schemeValidator
            config.schemeValidator = myConfig.config.parameters.evaluation.frequencyDomainClassifier.schemeValidator.Attributes;
            config.schemeValidator.frequencyRefinement = frequencyRefinement;
            
            % Set parameters for peakComparison
            config.peakComparison.coefficientModeFunction = str2double(myConfig.config.parameters.evaluation.frequencyDomainClassifier.peakComparison.Attributes.coefficientModeFunction);
            config.peakComparison.freqRange = str2double(myConfig.config.parameters.evaluation.frequencyDomainClassifier.peakComparison.Attributes.freqRange);
            config.peakComparison.modeFunction = logical(str2double(myConfig.config.parameters.evaluation.frequencyDomainClassifier.peakComparison.Attributes.modeFunction));
            config.peakComparison.percentRange = str2double(myConfig.config.parameters.evaluation.frequencyDomainClassifier.peakComparison.Attributes.percentRange);
            config.peakComparison.frequencyRefinement = frequencyRefinement;
            
            % Set parameters for parpool
            config.parpoolEnable = str2double(myConfig.config.parameters.common.parpoolEnable.Attributes.value);
            
        end
        
    end
    
end

