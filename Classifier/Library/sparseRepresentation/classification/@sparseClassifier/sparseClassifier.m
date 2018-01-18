classdef sparseClassifier
    %SPARSECLASSIFIER Summary of this class goes here
    %   Detailed explanation goes here

    properties (Access = private)
        
        %Input properties:
        envelopeClassifier
        sparseData
        config
        
        %Output properties:
        
        statusStruct
    end
    
    methods (Access = public)
        
        % Constructor function 
        function [myClassifier] = sparseClassifier(myData,myConfig)
            if nargin < 1
               myConfig = []; 
            end
            
            myClassifier.config = myConfig;
            myClassifier.sparseData = myData;
            myClassifier.envelopeClassifier = [];

        end
        
        function [myClassifier] = initWithEnvelopeClassifier(myClassifier,myEnvelopeClassifier)
           myClassifier.envelopeClassifier = myEnvelopeClassifier;
        end
        
        function [myClassifier] = initWithFiles(myClassifier,files)
           myClassifier.envelopeClassifier = schemeClassifier(files.classifierStruct,...
                                                  files.informativeTags,...
                                                  files.config,...
                                                  files.peakTable);
        end
        
        % Getters / Setters ...
        function [myStatusStruct] = getStatusStruct(myClassifier)
            myStatusStruct = myClassifier.statusStruct;
        end
        function [myClassifier] = setStatusStruct(myClassifier,myStatusStruct)
           myClassifier.statusStruct = myStatusStruct; 
        end
        % ... Getters / Setters 
        
        % CREATESTATUSSTRUCT function build subStatusStructs, merge them
        % and calculate status for each defect using defectEvaluator
        function [myClassifier] = createStatusStruct(myClassifier)
            
                mySparseData = myClassifier.sparseData;
                if isempty(mySparseData)
                    myClassifier.statusStruct = [];
                    return;
                end
                for i = 1:1:length(mySparseData)
                   subStatusStruct{i,1} = createSubStatusStruct(myClassifier, mySparseData(i)); 
                end
                
                % Calculate defect similarity based on the time- and
                % frequency-domain information
                myBaseStruct = mergeSubStatusStruct(myClassifier,subStatusStruct);
                myDefectEvaluator = defectEvaluator(myBaseStruct);
                myClassifier.statusStruct  = getStatusStruct(myDefectEvaluator);

        end
        
        % 
        function [docNode] = createDocNode(myClassifier)
            
            % dummy ...
            [myStatusStruct] = myClassifier.statusStruct;
            docNode = [];
            % ... dummy
        end
        
        % FILLDOCNODE function adds sparseClassifier result to existing
        % docNode element.
        function [docNode] = fillDocNode(myClassifier,docNode)
            
            if isempty(myClassifier.statusStruct)
                return;
            end
            [myStatusStruct] = myClassifier.statusStruct;
            
            docRootNode = docNode.getDocumentElement;
            sparseClassifierNode = docNode.createElement('sparseClassifier');
            docRootNode.appendChild(sparseClassifierNode);
            
            % Checking for unique elements in the statusStruct, cutting
            % corresponding to them parts of the statusStruct and putting
            % them into the CREATEELEMENTNODE function (for element docNode 
            % part creation)
            for i=1:1:length(myStatusStruct)
                elementsNames{i,1} = getfield(myStatusStruct(i),'name');
            end
            
            uniqueElements = unique(elementsNames);
            for i=1:1:length(uniqueElements)
                elementStatusStruct = myStatusStruct(find(ismember(elementsNames,uniqueElements(i,1))));
                elementNode = createElementNode( myClassifier,docNode,elementStatusStruct );
                sparseClassifierNode.appendChild(elementNode);
            end 
        end
        
        % CREATEELEMENTNODE function forms docNode for each element
        % containing frequency, magnintudes, frequencyNames & frequnecyTags
        function [elementNode] = createElementNode( myClassifier,docNode,elementStruct )
            
            elementNode = docNode.createElement('element');
            elementNode.setAttribute('schemeName', elementStruct(1).name);
            elementNode.setAttribute('baseFrequency',num2str(elementStruct(1).baseFreq));
            
            for i=1:1:length(elementStruct)
               
                % Find nonintersected elements between @allDefectFrequencies
                % and @directDefectFrequencies
                defectNode = docNode.createElement('defect');
                defectNode.setAttribute('tagName', elementStruct(i).defectTagName);
                
                % Fill status parameters. 
                statusNode = docNode.createElement('status');
                statusNode.setAttribute('value', num2str(ceil(elementStruct(i).similarity.*100)));
                statusNode.setAttribute('similarity', num2str(elementStruct(i).similarity,'%10.2f'));
                statusNode.setAttribute('energy', '');
                statusNode.setAttribute('intensivity', '');
                statusNode.setAttribute('trend', '');
                
                informativeTagsNode = docNode.createElement('informativeTags');
                
                timeDomainNode = docNode.createElement('timeDomain');
                timeDomainNode.setAttribute('frequencies',num2str(elementStruct(i).mTimeDefFreqValid,'%10.2f'));
                timeDomainNode.setAttribute('frequenciesTagNames',num2str(elementStruct(i).mTimeDefFreqNameValid));
                timeDomainNode.setAttribute('frequenciesUnvalid',num2str(elementStruct(i).mTimeDefFreqUnvalid,'%10.2f'));
                timeDomainNode.setAttribute('frequenciesValidities',num2str(elementStruct(i).mTimeDefFreqValidities,'%10.2f'));
                timeDomainNode.setAttribute('energyContribution',num2str(elementStruct(i).mTimeEnergyContribution,'%10.2f'));
                timeDomainNode.setAttribute('resonantFrequency',num2str(elementStruct(i).mTimeResonantFrequency,'%10.2f'));
                timeDomainNode.setAttribute('envelopeClassifierSimilarity',num2str(elementStruct(i).envClassifierSimilarity,'%10.2f'));
                
                % The main informativeTags for defect probability
                % calculations
                frequencyDomainNode = docNode.createElement('frequencyDomain');
                frequencyDomainNode.setAttribute('tagNames', strjoin(reshape(elementStruct(i).aDefFreqNameValid,1,[])));
                frequencyDomainNode.setAttribute('relatedTagNames', strjoin(reshape(elementStruct(i).aDefFreqTagValid,1,[])));
                frequencyDomainNode.setAttribute('frequencies', num2str(elementStruct(i).aDefFreqValid,'%10.2f'));
                frequencyDomainNode.setAttribute('magnitudes', num2str(elementStruct(i).aDefMagValid','%10.2f'));
                frequencyDomainNode.setAttribute('prominences', num2str(elementStruct(i).aDefPromValid','%10.2f'));
                
                informativeTagsNode.appendChild(timeDomainNode);
                informativeTagsNode.appendChild(frequencyDomainNode);
                
                defectNode.appendChild(statusNode);
                defectNode.appendChild(informativeTagsNode);
                elementNode.appendChild(defectNode);
                   
            end
        end
        
    end
    
    methods (Access = private)
        
        % CREATESUBSTATUSSTRUCT function 
        function [myStatusStruct] = createSubStatusStruct(myClassifier,mySparseData)
            
           myStatusStruct = [];
           if ~isempty(myClassifier.envelopeClassifier)
               % "Aiming" sparse classification method
               [myEnvelopeClassifier] = myClassifier.envelopeClassifier;
               [myEnvelopeClassifier] = setPeakTable(myEnvelopeClassifier,mySparseData.peakTable);
               [myEnvelopeClassifier] = refreshClassifiers(myEnvelopeClassifier);
               [myEnvelopeClassifier] = createFilledClassifierStruct(myEnvelopeClassifier);
               [myEnvelopeClassifier] = createStatusStruct(myEnvelopeClassifier);

               [baseStruct] = getStatusStruct(myEnvelopeClassifier);
               [baseStruct] = fillBaseStruct(myClassifier, baseStruct, mySparseData);
           else
               % "Blind" sparse classification method
               [baseStruct] = createBaseStruct(myClassifier,mySparseData);
           end
           
           
%            [baseStruct] = validateBaseStruct(myClassifier, baseStruct);
           
           myStatusStruct = baseStruct;
            
        end
                
        % FILLBASESTRUCT function adds to baseStruct valid time-domain data
        function [newBaseStruct] = fillBaseStruct(myClassifier, myBaseStruct, mySparseData)
            
            if nargin < 3
               mySparseData = myClassifier.sparseData;
            end
            
            newBaseStruct = struct([]);
            frequencies{1,1} = mySparseData.frequencies;
            validities = mySparseData.validities;
            resonantFrequency = mySparseData.resonantFrequency;
            energyContribution = mySparseData.energyContribution;
%             minSimilarity = 0.3;
            
            k = 0;
            for i = 1:1:length(myBaseStruct)
                positionValid = cell2mat(cellfun(@find,cellfun(@ismember, myBaseStruct(i).mTimeDefFreq, frequencies,'UniformOutput',0),'UniformOutput',0));
                position = linspace(1,length(frequencies{1,1}),length(frequencies{1,1}));
                position(1,positionValid) = 0;
                positionUnvalid = nonzeros(position);
                
                % Form a newBaseStruct consisting only defects with average
                % or greater similarities and found valid time-domain
                % periods
%                 if ~isempty(positionValid) && myBaseStruct(i).similarity > minSimilarity
                if ~isempty(positionValid)
                    k = k + 1;
                    temp = myBaseStruct(i);
                    
                    [element,defName] = strtok(temp.defFuncName, '_');
                    newDefFuncName = [element,'S',defName];
                    temp.defFuncName = newDefFuncName;
                    
                    temp.envClassifierSimilarity = temp.similarity;
                    temp.mTimeDefFreqValid = myBaseStruct(i).mTimeDefFreq{1,1}(1,positionValid);
                    temp.mTimeDefFreqNameValid = myBaseStruct(i).mTimeDefFreqName{1,1}{1,positionValid};
                    temp.mTimeDefFreqTagValid = myBaseStruct(i).mTimeDefFreqTag{1,1}{1,positionValid};
                    temp.mTimeDefMagValid = myBaseStruct(i).mTimeDefMag{1,1}(1,positionValid);
                    temp.mTimeDefPromValid = myBaseStruct(i).mTimeDefProm{1,1}(1,positionValid);
                    
                    if ~isempty(positionUnvalid)
                        temp.mTimeDefFreqUnvalid = frequencies{1,1}(1,positionUnvalid);
                    else
                        temp.mTimeDefFreqUnvalid = [];
                    end
                    temp.mTimeDefFreqValidities = validities;     
                    temp.mTimeResonantFrequency = resonantFrequency;
                    temp.mTimeEnergyContribution  = energyContribution;
                    temp.mTimeStatus = 'known';
                    
                    if k == 1
                        newBaseStruct = temp;
                    else
                        newBaseStruct(k) = temp;
                    end
                    
                end
            end
            
            % If there is no valid frequencies for found periods fill
            % newBaseStruct with @Unknown frequencies and their validities
            if isempty(newBaseStruct)
                
                % Create pattern of baseStruct row to fill with @unknown
                % info
                if ~isempty(myBaseStruct)
                    newBaseStruct = myBaseStruct(1);
                    newBaseStruct = structfun(@(x) '[]', newBaseStruct, 'UniformOutput', false);
                end
                
                newBaseStruct.defFuncName = 'unknown';
                newBaseStruct.name = 'unknown';
                newBaseStruct.baseFreq = 'unknown';
                newBaseStruct.aDefFreqNameValid = {'unknown'};
                newBaseStruct.aDefFreqTagValid = {'unknown'};
                newBaseStruct.enable = 1;
                newBaseStruct.envClassifierSimilarity = [];
                newBaseStruct.mTimeDefFreqValid = [];
                newBaseStruct.mTimeDefFreqNameValid = [];
                newBaseStruct.mTimeDefFreqTagValid = [];
                newBaseStruct.mTimeDefMagValid = [];
                newBaseStruct.mTimeDefPromValid = [];
                
                newBaseStruct.mTimeDefFreqUnvalid = frequencies{1,1};
                newBaseStruct.mTimeDefFreqValidities = validities;
                newBaseStruct.mTimeResonantFrequency = resonantFrequency;
                newBaseStruct.mTimeEnergyContribution  = energyContribution;
                newBaseStruct.mTimeStatus = 'unknown';
            end
        end
        
        
        % CREATEBASESTRUCT function ...
        function [baseStruct] = createBaseStruct(myClassifier,mySparseData)
            if nargin < 2
                mySparseData = myClassifier.sparseData; 
            end
%             baseStruct = struct([]);
            frequencies{1,1} = mySparseData.frequencies;
            validities = mySparseData.validities;
            resonantFrequency = mySparseData.resonantFrequency;
            energyContribution = mySparseData.energyContribution;
            
            baseStruct.defFuncName = 'unknown';
            baseStruct.name = 'unknown';
            baseStruct.baseFreq = 'unknown';
            
            baseStruct.defectTagName = 'unknown';
            baseStruct.aDefFreqNameValid = {'unknown'};
            baseStruct.aDefFreqTagValid = {'unknown'};
            baseStruct.aDefFreqValid = [];
            baseStruct.aDefMagValid = [];
            baseStruct.aDefPromValid = [];

            baseStruct.enable = 1;
            baseStruct.envClassifierSimilarity = [];
            baseStruct.mTimeDefFreqValid = [];
            baseStruct.mTimeDefFreqNameValid = [];
            baseStruct.mTimeDefFreqTagValid = [];
            baseStruct.mTimeDefMagValid = [];
            baseStruct.mTimeDefPromValid = [];

            baseStruct.mTimeDefFreqUnvalid = frequencies{1,1};
            baseStruct.mTimeDefFreqValidities = validities;
            baseStruct.mTimeResonantFrequency = resonantFrequency;
            baseStruct.mTimeEnergyContribution  = energyContribution;
            baseStruct.mTimeStatus = 'unknown';
           
        end

        % MERGESUBSTATUSSTRUCT function merge several subStruct into one 
        function [myStatusStruct] = mergeSubStatusStruct(myClassifier,mySubStatusStruct)
            
            myStatusStruct = struct([]);
            subStructNumber = length(mySubStatusStruct);
            
            if subStructNumber == 0
               return; 
            end
            
            k = 0;
            for i = 1:1:subStructNumber
                subDefectsNumber = length(mySubStatusStruct{i,1});
                if subDefectsNumber <0
                   return; 
                end
                
                for  j = 1:1:subDefectsNumber
                   k = k+1;
                   if k == 1
                        myStatusStruct = mySubStatusStruct{i,1}(j);
                   else
                        myStatusStruct(k) = mySubStatusStruct{i,1}(j);
                   end
                end
            end

        end
        
    end
    
    methods (Static = true, Access = private)
        
        % Transform input data (consisting of resonantFrequencies,
        % energyContribution, envelopeSpectrums end etc of the number of 
        % clalogram scales) to common structure 
        function  [myParsedData] = parseData(myData)
            
            if isempty(myData)
               myParsedData = [];
               return;
            end
            
            k = 0;
            for i = 1:1:length(myData)
                if ~isempty(myData{1,i}.data)
                    myParsedData(k).envelopeSpectrum = myData{1,i}.envelopeSpectrum;
                    myParsedData.data = [];
                    dataLength = length(myData.data);
                end
                
            end
            
%             myParsedData = myData;
%             myParsedData.data = [];
%             dataLength = length(myData.data)
%             
%             frequencies = zeros(1,dataLength);
%             validities = zeros(1,dataLength);
%             for i = 1:1:dataLength
%                 frequencies(1,i) = myData.data(i).frequency;
%                 validities(1,i) = myData.data(i).validity;
%             end
%             myParsedData.frequencies{1,1} = frequencies;
%             myParsedData.validities{1,1} = validities;
            
        end
    end
    
end

