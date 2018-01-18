classdef historyHandler
    %HISTORYHANDLER
    % Discription: Class is designed to storage data from parsed history,
    % create class "trendHandler"
    
    properties (Access = protected)
        % Input properties
        config % configuration structure
        files % information structure of history files
        translations % translations for plots
        
        iLoger
        
        trendHandler % class object "trendHandler"
        historyContainer % data from history
        historyValidity
        fuzzyContainer % provides rules to implement status calculation
        
        % Output property
        result % struct contains status generally, intermediates status,
        % data of current file (status.xml)
    end
    
    methods (Access = public)
        
        % Constructor function
        function [myHistoryHandler] = historyHandler(myConfig, myFiles, myContainerTag, myTranslations, myXmlToStructHistory)
            
            myHistoryHandler.iLoger = loger.getInstance;
            
            if nargin == 0
                myHistoryHandler.config = [];
                myHistoryHandler.files = [];
                myHistoryHandler.translations = [];
                myHistoryHandler.historyContainer = [];
                error('There are not enough input argument!')
            else
                myHistoryHandler.config = myConfig;
                myHistoryHandler.files = myFiles;
                myHistoryHandler.translations = myTranslations;
                
                historyContainerType = [myContainerTag, 'HistoryContainer'];
                myHistoryHandler.historyContainer = feval(historyContainerType, myFiles, myXmlToStructHistory);
            end
        end
        
        % Getters/Setters ...
        function [myConfig] = getConfig(myHistoryHandler)
            myConfig = myHistoryHandler.config;
        end
        function [myHistoryHandler] = setConfig(myHistoryHandler,myConfig)
            myHistoryHandler.config = myConfig;
        end
        
        function [myFiles] = getFiles(myHistoryHandler)
            myFiles = myHistoryHandler.files;
        end
        function [myHistoryHandler] = setFiles(myHistoryHandler,myFiles)
            myHistoryHandler.files = myFiles;
        end
        
        function [myTranslations] = getTranslations(myHistoryHandler)
            myTranslations = myHistoryHandler.translations;
        end
        function [myHistoryHandler] = setTranslations(myHistoryHandler, myTranslations)
            myHistoryHandler.translations = myTranslations;
        end
        
        function [myTrendHandler] = getTrendHandler(myHistoryHandler)
            myTrendHandler = myHistoryHandler.trendHandler;
        end
        function [myHistoryHandler] = setTrendHandler(myHistoryHandler,myTrendHandler)
            myHistoryHandler.trendHandler = myTrendHandler;
        end
        
        function [myHistoryContainer] = getHistoryContainer(myHistoryHandler)
            myHistoryContainer = myHistoryHandler.historyContainer;
        end
        function [myHistoryHandler] = setHistoryContainer(myHistoryHandler,myHistoryContainer)
            myHistoryHandler.historyContainer = myHistoryContainer;
        end
        
        function [myFuzzyContainer] = getFuzzyContainer(myHistoryHandler)
            myFuzzyContainer = myHistoryHandler.fuzzyContainer;
        end
        function [myHistoryHandler] = setFuzzyContainer(myHistoryHandler,myFuzzyContainer)
            myHistoryHandler.fuzzyContainer = myFuzzyContainer;
        end
        
        function [myResult] = getResult(myHistoryHandler)
            myResult = myHistoryHandler.result;
        end
        function [myHistoryHandler] = setResult(myHistoryHandler, myResult)
            myHistoryHandler.result = myResult;
        end
        % ... Getters/Setters
        
        
        function [myHistoryHandler] = trendRecalculation(myHistoryHandler,mySignal,myConfig)
            myTrendHandler = getTrendHandler(myHistoryHandler);
            if nargin >= 3
                myTrendHandler = trendHandler(mySignal,myConfig);
            elseif nargin == 2
                myTrendHandler = trendHandler(mySignal);
            else
                myTrendHandler = trendRecalculation(myTrendHandler);
            end
            myHistoryHandler.trendHandler = myTrendHandler;
        end
    end
    
    % History handler classes specific methods
    methods (Access = protected)
        
        % CREATEIMAGESTRUCTNODE function creates a xml-node imageStructNode
        % with the input name nodeName and fills it with data frome the
        % input struct imageStruct
        function imageStructNode = createImageStructNode(myHistoryHandler, docNode, imageStruct, nodeName)
            imageStructNode = docNode.createElement(nodeName);
            
            % XY axis data
            xAxisNode = docNode.createElement('xAxis');
            yAxisNode = docNode.createElement('yAxis');
            xAxisNode.setAttribute('signal', vector2strStandardFormat(imageStruct.date));
            yAxisNode.setAttribute('signal', vector2strStandardFormat(imageStruct.signal( : , 2)'));
            xAxisNode.setAttribute('approx', vector2strStandardFormat(imageStruct.approx( : , 1)'));
            yAxisNode.setAttribute('approx', vector2strStandardFormat(imageStruct.approx( : , 2)'));
            
            imageStructNode.appendChild(xAxisNode);
            imageStructNode.appendChild(yAxisNode);
        end
    end
    
    methods (Abstract = true, Access = protected)
        [myResult] = historyProcessing(myHistoryHandler)
        [myHistoryHandler] = createFuzzyContainer(myHistoryHandler)
    end
    
    methods(Static)
        
        [ status ] = evaluateStatusWithDuration(vectorStatus, myFiles)
        
        % EVALUATESTATUS function evaluate status 
        function [status] = evaluateStatus(vectorStatus, myFiles)
            [ status ] = evaluateStatusWithDuration(vectorStatus, myFiles);
        end
        % EVALUATELEVEL function evaluate duration of current level
        function [durationCurrentLevel, compression] = evaluateDurationStatus(trendParameters, statuses, timeVector)

            % Get status with compression data
            myHistoryCompression = historyCompression(statuses, timeVector, trendParameters, 'threshold');
            compression = getCompressedHistory(myHistoryCompression);
            
            % Evaluate current level for duration
            posCurrentStatus = contains(compression.data,compression.data(end));
            posFirstZeros = find(flip(posCurrentStatus) == 0, 1, 'first');
            if ~isempty(posFirstZeros)
                durationCurrentLevel = posFirstZeros - 1;
            else
                durationCurrentLevel = length(compression.data);
            end
        end
    end
end

