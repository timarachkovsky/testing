classdef timeDomainHistoryHandler < historyHandler
    % TIMEDOMAINHISTORYHANDLER class evaluate similarity of defectly element
    
    properties (Access = protected)
        
        % The parameters for this class
        parameters
    end
    
    methods (Access = public)        
        % Constructor function
        function [myTimeDomainHistoryHandler] = ...
                timeDomainHistoryHandler(myConfig, myFiles, myTranslations, myXmlToStructHistory)
            if nargin < 1
               error('There are not enough input arguments!'); 
            end
            
            myContainerTag = 'timeDomain';
            myTimeDomainHistoryHandler =  myTimeDomainHistoryHandler@historyHandler(myConfig, myFiles, myContainerTag, myTranslations, myXmlToStructHistory);
            
            parameters = [];
            if isfield(myFiles.files.history.Attributes, 'actualPeriod')
                parameters = setfield(parameters, 'maxPeriod', myFiles.files.history.Attributes.actualPeriod);
            end
            if isfield(myConfig.config.parameters.common, 'parpoolEnable')
                parameters.parpoolEnable = ...
                    myConfig.config.parameters.common.parpoolEnable.Attributes.value;
            end

            myTimeDomainHistoryHandler.parameters = parameters;
            
            myTimeDomainHistoryHandler.trendHandler = [];
            myTimeDomainHistoryHandler = historyProcessing(myTimeDomainHistoryHandler);
        end
        
        % FILLDOCNODE function fills docNode document with calculated
        % result data
        function [docNode] = fillDocNode(myTimeDomainHistoryHandler, docNode)
            
            iLoger = loger.getInstance;
            myResult = getResult(myTimeDomainHistoryHandler);
            
            % Replace existing envelopeClassifier node with new one
            docRootNode = docNode.getDocumentElement;
            if hasChildNodes(docRootNode)
                childNodes = getChildNodes(docRootNode);
                numChildNodes = getLength(childNodes);
                for count = 1:numChildNodes
                    theChild = item(childNodes,count-1);
                    name = toCharArray(getNodeName(theChild))';
                    if strcmp(name,'timeDomainClassifier')
                        docRootNode.removeChild(theChild);
                        break;
                    end
                end
            end
            
            timeDomainClassifierNode = docNode.createElement('timeDomainClassifier');
            docRootNode.appendChild(timeDomainClassifierNode);
            
            % Status Node
            statusNode = docNode.createElement('status');
            statusNode.setAttribute('elementType', myResult.rawCurrentData.status.Attributes.elementType); 
            statusNode.setAttribute('similarity', myResult.rawCurrentData.status.Attributes.similarity); 
            statusNode.setAttribute('similarityTrend', num2str(myResult.statusTrend)); 
            statusNode.setAttribute('severity', myResult.rawCurrentData.status.Attributes.severity); 
            statusNode.setAttribute('tag', myResult.rawCurrentData.status.Attributes.tag);
            statusNode.setAttribute('value', myResult.rawCurrentData.status.Attributes.value); 
            
            % InformativeTags Node
            informativeTagsNode = docNode.createElement('informativeTags');
            
            frequencynNode = docNode.createElement('frequency');
            frequencynNode.setAttribute('value', myResult.rawCurrentData.informativeTags.frequency.Attributes.value);
            
            frequencynNode.setAttribute('tag', myResult.rawCurrentData.informativeTags.frequency.Attributes.tag);
            
            signalTypeNode = docNode.createElement('signalType');
            signalTypeNode.setAttribute('value', myResult.rawCurrentData.informativeTags.signalType.Attributes.value);
            
            periodicityNode = docNode.createElement('periodicity');
            periodicityNode.setAttribute('value', myResult.rawCurrentData.informativeTags.periodicity.Attributes.value);
            
            patternTypeNode = docNode.createElement('patternType');
            patternTypeNode.setAttribute('value', myResult.rawCurrentData.informativeTags.patternType.Attributes.value);
            
            equipmentTypeNode = docNode.createElement('equipmentType');
            equipmentTypeNode.setAttribute('value', myResult.rawCurrentData.informativeTags.equipmentType.Attributes.value);
            
            informativeTagsNode.appendChild(frequencynNode);
            informativeTagsNode.appendChild(signalTypeNode);
            informativeTagsNode.appendChild(periodicityNode);
            informativeTagsNode.appendChild(patternTypeNode);
            informativeTagsNode.appendChild(equipmentTypeNode);
            
            timeDomainClassifierNode.appendChild(statusNode);
            timeDomainClassifierNode.appendChild(informativeTagsNode);
            
            printComputeInfo(iLoger, 'TimeDomainHistoryHandler', 'docNode structure was successfully updated.');
        end
    end
    
    methods (Access = protected)   
        
        % HISTORYPROCESSING function 
        function [myTimeDomainHistoryHandler] = historyProcessing(myTimeDomainHistoryHandler)
            
			iLoger = loger.getInstance;
			
            % To get date from history container
            myHistoryContainer = getHistoryContainer(myTimeDomainHistoryHandler);
            myHistoryTable = getHistoryTable(myHistoryContainer); 
            vectorTime = getDate(myHistoryContainer);
            
            % To record to result structure
            resultStruct.rawCurrentData = myHistoryTable.rawCurrentData;
            
            % To find last stable informations of element  
            vectorElements = myHistoryTable.elements;
            currentElement = myHistoryTable.elements{1,1};
            posTrue = strcmp(vectorElements, currentElement);
            posCrop = find(~posTrue, 1, 'first');
            if isempty(posCrop)
                vectorSimilarity = myHistoryTable.similarity;
            else
                vectorSimilarity = myHistoryTable.similarity(1:posCrop-1,1);
                vectorTime = vectorTime(1:posCrop-1,1);
            end
            
            resultStruct.statusTrend = [];
            
            % To find no NaN similarity
            if nnz(isnan(vectorSimilarity))
                posNan = find(isnan(vectorSimilarity), 1, 'first');
                if posNan == 1
                    resultStruct.statusTrend = 1.5;
                else
                    vectorSimilarity = vectorSimilarity(1:posNan-1,1);
                    vectorTime = vectorSimilarity(1:posCrop-1,1);
                end
            end
            
            % To evaluate similarity trend
            if isempty(resultStruct.statusTrend)
                resultStruct.statusTrend = evaluateSimilarityTrend(myTimeDomainHistoryHandler, vectorSimilarity, vectorTime);
            end
            
            % To set data to result
            myTimeDomainHistoryHandler.result = resultStruct;
			printComputeInfo(iLoger, 'TimeDomainHistoryHandler', 'TimeDomainClassifier history processing COMPLETE.');
        end
        
        % EVALUATESIMILARITYTREND function is calculate status of similarity
        function [status] = evaluateSimilarityTrend(myTimeDomainHistoryHandler, vectorSimilarity, myDate)
            myConfig = getConfig(myTimeDomainHistoryHandler);
            
            tempParameters = [];
            if (isfield(myConfig.config.parameters.evaluation.history, 'trend'))
                tempParameters = myConfig.config.parameters.evaluation.history.trend.Attributes;
            end
            
            % Calculate status of similarity trend
            myTrendHandler = trendHandler(vectorSimilarity, tempParameters, myDate);
            status = getResult(myTrendHandler);
            
%             % Copmression data (the last similarity during the period)
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
%             end
%             % Calculate status of similarity trend
%             myTrendHandler = ...
%                 trendHandler(flip(compressionSimilarity), tempParameters, flip(compressiomDate));
%             status = getResult(myTrendHandler);
        end
        
        %Unused
        function [myTimeDomainHistoryHandler] = createFuzzyContainer(myTimeDomainHistoryHandler)   
            myTimeDomainHistoryHandler.fuzzyContainer = [];
        end
    end
end