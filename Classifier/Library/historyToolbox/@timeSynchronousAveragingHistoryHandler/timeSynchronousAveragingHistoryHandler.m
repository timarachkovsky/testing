classdef timeSynchronousAveragingHistoryHandler < historyHandler
    
    
    properties (Access = protected)
        % Input properties
        parameters % configurable parameters
    end
    
    methods (Access = public)
        % Constructor function
        function [myTSAHistoryHandler] = timeSynchronousAveragingHistoryHandler(myConfig, myFiles, myTranslations, myXmlToStructHistory)
            if nargin < 1
               error('There are not enough input arguments!'); 
            end
            
            myContainerTag = 'timeSynchronousAveraging';
            myTSAHistoryHandler = myTSAHistoryHandler@historyHandler(myConfig, myFiles, myContainerTag, myTranslations, myXmlToStructHistory);
            
            % Set standard parameters
            parameters.lineCoef = str2num(myConfig.config.parameters.evaluation.timeSynchronousAveraging.Attributes.lineCoef);
            parameters.maxPeriod = myFiles.files.history.Attributes.actualPeriod;
            parameters.debugModeEnable = myConfig.config.parameters.common.debugModeEnable.Attributes.value;
            methodPlotEnable = myConfig.config.parameters.evaluation.timeSynchronousAveraging.Attributes.plotEnable;
            historyPlotEnable = myConfig.config.parameters.evaluation.history.Attributes.plotEnable;
            if strcmp(methodPlotEnable, historyPlotEnable)
                parameters.plotEnable = methodPlotEnable;
            else
                parameters.plotEnable = '0';
            end
            parameters.plots = myConfig.config.parameters.evaluation.plots.Attributes;
            parameters.plotVisible = myConfig.config.parameters.common.printPlotsEnable.Attributes.visible;
            parameters.plotTitle = myConfig.config.parameters.common.printPlotsEnable.Attributes.title;
            parameters.printPlotsEnable = myConfig.config.parameters.common.printPlotsEnable.Attributes.value;
            
            myTSAHistoryHandler.parameters = parameters;
            
            % Craete decision making container to calculate result status 
            [myTSAHistoryHandler] = createFuzzyContainer(myTSAHistoryHandler);
            myTSAHistoryHandler = historyProcessing(myTSAHistoryHandler);
        end
        
        % FILLDOCNODE function fills docNode document with calculated
        % result data
        function [docNode] = fillDocNode(myTSAHistoryHandler, docNode)
            
            iLoger = loger.getInstance;
            myResultStruct = getResult(myTSAHistoryHandler);
            
            % Replace existing spm node with new one
            docRootNode = docNode.getDocumentElement;
            if hasChildNodes(docRootNode)
                childNodes = getChildNodes(docRootNode);
                numChildNodes = getLength(childNodes);
                for count = 1:numChildNodes
                    theChild = item(childNodes,count-1);
                    name = toCharArray(getNodeName(theChild))';
                    if strcmp(name,'timeSynchronousAveraging')
                        docRootNode.removeChild(theChild);
                        break;
                    end
                end
            end
            
            tsaNode = docNode.createElement('timeSynchronousAveraging');
            
            % Create status and informativeTags nodes
            statusNode = docNode.createElement('status');
            informativeTagsNode = docNode.createElement('informativeTags');
            
            if isfield(myResultStruct.currentStatus.informativeTags, 'gearing')                
                
                lengthStatusGearing = length(myResultStruct.currentStatus.status.gearing);
                if lengthStatusGearing == 1
                    myResultStruct.currentStatus.status.gearing = {myResultStruct.currentStatus.status.gearing};
                end
                
                lengthInformativeGearing = length(myResultStruct.currentStatus.informativeTags.gearing);
                if lengthInformativeGearing == 1
                    myResultStruct.currentStatus.informativeTags.gearing = {myResultStruct.currentStatus.informativeTags.gearing};
                end
                
                if isempty(myResultStruct.tables)
                    
                    statusNode.setAttribute('value', '0');
                    
                    statusOfHistory = cell(lengthStatusGearing, 1); 
                    statusOfHistory(:) = {'0'};
                    
                    statusOfHistoryRange = cell(lengthInformativeGearing, 1);
                    statusOfHistoryRange(:) = {'0'};
                    
                    statusTag = cell(lengthInformativeGearing, 1);
                    statusTag(:) = {''};
                else
                    
                    vectorStatus = cell2mat({myResultStruct.tables.statusHistory}); 
                    
                    % Set status for all method
                    status = max(vectorStatus);
                    statusNode.setAttribute('value', num2str(status));

                    % Set status for each gearing
                    name = {myResultStruct.tables(:).name};
                    nameGearing = cellfun(@(x) strsplit(x, '-'), name, 'UniformOutput', false);
                    nameGearing = cellfun(@(x) x{1}, nameGearing, 'UniformOutput', false);
                    
                    nameUniqGearing = unique(nameGearing);
                    
                    uniqGearingNumber = length(nameUniqGearing);
                    statusOfHistory = cell(uniqGearingNumber, 1);
                    for i = 1:1:uniqGearingNumber
                        
                        posGearing = strcmpi(nameGearing, nameUniqGearing{i});
                        
                        statusOfHistory{i} = num2str(max(vectorStatus(posGearing)));
                    end
                    
                    % Set status for each range
                    statusOfHistoryRange = strsplit(num2str(vectorStatus));
                    
                    % Set tagsStatus for each range
                    statusTag = {myResultStruct.tables(:).statusTag};
                    statusTag = cellfun(@(x) x{1}, statusTag, 'UniformOutput', false);
                end
                
                % Fill status
                for i = 1:1:lengthStatusGearing
                    
                    % Create range node for the status node
                    gearingStatusNode = docNode.createElement('gearing');
                    gearingStatusNode.setAttribute('gearingName', myResultStruct.currentStatus.status.gearing{i}.Attributes.gearingName);
                    gearingStatusNode.setAttribute('status', myResultStruct.currentStatus.status.gearing{i}.Attributes.status);
                    gearingStatusNode.setAttribute('statusOfHistory', statusOfHistory{i});
                    
                    % Set the shaft node to the status node
                    statusNode.appendChild(gearingStatusNode);
                end
                
                % Fill informativeTags
                for i = 1:1:lengthInformativeGearing
                    
                    % Create range node for the status node      
                    rangeInformativeTagsNode = docNode.createElement('gearing');
                    rangeInformativeTagsNode.setAttribute('name', myResultStruct.currentStatus.informativeTags.gearing{i}.Attributes.name);
                    rangeInformativeTagsNode.setAttribute('validGM', myResultStruct.currentStatus.informativeTags.gearing{i}.Attributes.validGM);
                    rangeInformativeTagsNode.setAttribute('validShaftFreq', myResultStruct.currentStatus.informativeTags.gearing{i}.Attributes.validShaftFreq);
                    rangeInformativeTagsNode.setAttribute('status', myResultStruct.currentStatus.informativeTags.gearing{i}.Attributes.status);
                    rangeInformativeTagsNode.setAttribute('modulationCoef', myResultStruct.currentStatus.informativeTags.gearing{i}.Attributes.modulationCoef);
                    rangeInformativeTagsNode.setAttribute('statusOfHistory', statusOfHistoryRange{i});
                    rangeInformativeTagsNode.setAttribute('statusTag', statusTag{i});
                    
                    % Set the shaft node to the status node
                    informativeTagsNode.appendChild(rangeInformativeTagsNode);
                end
                
            else
                statusNode.setAttribute('value', '0');
            end
            
            % Set status and informativeTags nodes to the method node
            tsaNode.appendChild(statusNode);
            tsaNode.appendChild(informativeTagsNode);
            
            docRootNode.appendChild(tsaNode);
            
            printComputeInfo(iLoger, 'timeSynchronousAveragingHistoryHandler', 'docNode structure was successfully updated.');
        end
    end
    
    methods (Access = protected)  
        % HISTORYPROCESSING function calculate status
        function [myTSAHistoryHandler] = historyProcessing(myTSAHistoryHandler)
            % Loger initialization
            iLoger = loger.getInstance;
            
            % Get data from history files
            myHistoryContainer = getHistoryContainer(myTSAHistoryHandler);
            myHistoryTable = getHistoryTable(myHistoryContainer); 
            myFiles = getFiles(myTSAHistoryHandler);
            
            if isempty(myHistoryTable.tables) || length(myHistoryTable.date) < 3
                
                if length(myHistoryTable.date) < 3
                    printComputeInfo(iLoger, 'Time synchronous averaging history', 'There is empty history.');
                end
                    
                myHistoryTable.tables = [];
                myTSAHistoryHandler.result = myHistoryTable;
                return
            end
            
            % Set config parametrs 
            myConfig = getConfig(myTSAHistoryHandler);
            trendParameters = [];   
            if (isfield(myConfig.config.parameters.evaluation.history, 'trend'))
                trendParameters = myConfig.config.parameters.evaluation.history.trend.Attributes;
            end
            trendParameters.maxPeriod = myTSAHistoryHandler.parameters.maxPeriod;
            
            % dummy
            actualPeriod = str2double(myTSAHistoryHandler.parameters.maxPeriod);
            
            numberRanges = length(myHistoryTable.tables);
                        
            compressionSamples = cell(numberRanges, 1);
            
            % Calculation of status
            for i = 1:1:numberRanges
                
                if myHistoryTable.tables(i).rangesStatuses(1)
                    
                    modulationsCoef = myHistoryTable.tables(i).modulationsCoef;
                    modulationsCoef(~myHistoryTable.tables(i).rangesStatuses) = nan(1, 'single');

                    % Calculate trend
                    myTempObjTrendHandler = trendHandler(modulationsCoef, trendParameters, myHistoryTable.date);
                    tempTrendStatus = getResult(myTempObjTrendHandler);
                    tempTrendObj = getTrend(myTempObjTrendHandler);
                    signalTrend = getSignal(tempTrendObj);
                    comparisonDate = getDate(tempTrendObj);
                    
                    compressionSamples{i}.data = signalTrend;
                    compressionSamples{i}.time = comparisonDate;

                    % Evaluate treshold for current state with comprassion
                    myHistoryTable.tables(i).statusTag{1} = ...
                        myTSAHistoryHandler.thresholdsEvaluation(signalTrend(end), myTSAHistoryHandler.parameters.lineCoef);

                    % Evaluate status of history with thresholds
                    [~, compressionData] = myTSAHistoryHandler.evaluateDurationStatus(trendParameters, ...
                        myHistoryTable.tables(i).statusTag', myHistoryTable.date);
                    statusEvaluated = myTSAHistoryHandler.evaluateStatus(compressionData.data, myFiles);

                    % Evaluate status of history
                    inputArgs = [actualPeriod, double(str2numStatus.(statusEvaluated{1,1})), tempTrendStatus];                    
                    myHistoryTable.tables(i).statusHistory = int8(evalfis(inputArgs, myTSAHistoryHandler.fuzzyContainer)*100);
                else
                    
                    myHistoryTable.tables(i).statusHistory = int8(0);
                    myHistoryTable.tables(i).statusTag(1) = {''};
                end
            end  
            
            myTSAHistoryHandler.result = myHistoryTable;
            
            if str2double(myTSAHistoryHandler.parameters.plotEnable)
                
                plotAndPrint(myTSAHistoryHandler, compressionSamples);
                
                if checkImages(fullfile(pwd, 'Out'), 'history-TSA-acc-', myTSAHistoryHandler.parameters.plots.imageFormat)
                    printComputeInfo(iLoger, 'timeSynchronousAveragingHistoryHandler', 'The method images were saved.')
                end
            end
			printComputeInfo(iLoger, 'timeSynchronousAveragingHistoryHandler', 'timeSynchronousAveraging history processing COMPLETE.');
        end
        
        % PLOTANDPRINT function draws and saves plots
        function plotAndPrint(myOctaveSpectrumHistoryHandler, compressionSamples)
            
            % Get parameters
            Translations = myOctaveSpectrumHistoryHandler.translations;
            
            plotVisible = myOctaveSpectrumHistoryHandler.parameters.plotVisible;
            plotTitle = myOctaveSpectrumHistoryHandler.parameters.plotTitle;
            printPlotsEnable = str2double(myOctaveSpectrumHistoryHandler.parameters.printPlotsEnable);
            sizeUnits = myOctaveSpectrumHistoryHandler.parameters.plots.sizeUnits;
            imageSize = str2num(myOctaveSpectrumHistoryHandler.parameters.plots.imageSize);
            fontSize = str2double(myOctaveSpectrumHistoryHandler.parameters.plots.fontSize);
            imageFormat = myOctaveSpectrumHistoryHandler.parameters.plots.imageFormat;
            imageQuality = myOctaveSpectrumHistoryHandler.parameters.plots.imageQuality;
            imageResolution = myOctaveSpectrumHistoryHandler.parameters.plots.imageResolution;
            
            myResult = myOctaveSpectrumHistoryHandler.result.tables;
            lineCoef = myOctaveSpectrumHistoryHandler.parameters.lineCoef;
            
            tresholdsAverage = (50 - lineCoef(2))/lineCoef(1);
            tresholdsMax = (75 - lineCoef(2))/lineCoef(1);
            thresholdsValues = [tresholdsMax tresholdsAverage];
            
            thresholdsLabels = {'Damage level', 'Warning level', 'Normal level'};
            
            for i = 1:1:length(myResult)
    
                if ~isempty(compressionSamples{i})
                    
                    vectorX = 1:1:length(compressionSamples{i}.data);
                    
                    if length(vectorX) > 3
                    
                        % Plot
                        myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');

                        hold on;
                        % Plot the signal and the approximation
                        myPlot(1) = plot(vectorX, compressionSamples{i}.data, ...
                            'Color', [0, 1, 1], 'LineWidth', 2);
                        % Plot thresholds

                        [myFigure, myArea] = fillArea(myFigure, thresholdsValues);

                        hold off;
                        grid on;

                        % Get axes data
                        myAxes = myFigure.CurrentAxes;
                        % Set axes font size
                        myAxes.FontSize = fontSize;

                        % Figure title
                        if strcmp(plotTitle, 'on')
                            title(myAxes, [upperCase(Translations.timeSynchronousAveraging.Attributes.shortName) ' ' ...
                                           upperCase(myResult(i).name, 'first') '. Status: ' num2str(myResult(i).statusHistory)]);
                        end        
                        % Figure labels
                        xlabel(myAxes, upperCase(Translations.actualPeriod.Attributes.name, 'first'));
                        ylabel(myAxes, upperCase(Translations.modulationCoefficient.Attributes.name, 'first'));
                        % Replace the x-axis values by the date
                        xticks(myAxes, vectorX);
                        xticklabels(myAxes, compressionSamples{i}.time);
                        xtickangle(myAxes, 90);
                        % Display legend
                        legend([myPlot, flip(myArea)], ...
                            [{'Values'}, thresholdsLabels], ...
                            'Location', 'northwest');

                        if printPlotsEnable
                            imageNumber = num2str(i);
                            % Save the image to the @Out directory
                            fileName = ['history-TSA-acc-', imageNumber];
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

        % CREATEFUZZYCONTAINER function create rules to calculate status  
        function [myTSAHistoryHandler] = createFuzzyContainer(myTSAHistoryHandler)            
            maxPeriod = str2double(myTSAHistoryHandler.parameters.maxPeriod);
            container = newfis('optipaper');
            
            % INPUT:
            % Init 3-state @actualPeriod variable
            container = addvar(container,'input','actualPeriod',[-0.75 (maxPeriod + 0.75)]);
            container = addmf(container,'input',1,'short','gauss2mf',[0.25 1 0.25 2]);
            container = addmf(container,'input',1,'long','gauss2mf',[0.25 3 0.25 maxPeriod]);
            container = addmf(container,'input',1,'no','gaussmf',[0.25 0]);
            
            % INPUT:
            % Init 3-state @lowThreshold variable
            container = addvar(container,'input','tags',[-0.25 1.25]);
            container = addmf(container,'input',2,'green','gauss2mf',[0.1 0 0.0625 0.5]);
            container = addmf(container, 'input',2,'orange','gaussmf',[0.0625 0.75]);
            container = addmf(container, 'input',2,'red','gaussmf',[0.0625 1]);
            
            % INPUT:
            % Init 6-state @lowLevel variable
            container = addvar(container,'input','trendStatus',[-1.375 1.875]);
            container = addmf(container,'input',3,'declining','gaussmf',[0.125 -1]);
            container = addmf(container,'input',3,'mb_declining','gaussmf',[0.125 -0.5]);
            container = addmf(container,'input',3,'stable','gaussmf',[0.125 0]);
            container = addmf(container,'input',3,'mb_growing','gaussmf',[0.125 0.5]);
            container = addmf(container,'input',3,'growing','gaussmf',[0.125 1]);
            container = addmf(container,'input',3,'unknown','gaussmf',[0.125 1.5]);
            
            % OUTPUT:
            % Init 4-state @result variable
            container = addvar(container, 'output', 'result', [0 1]);
            container = addmf(container,'output',1,'possiblyTroubling','gaussmf',[0.0625  0.375]);
            container = addmf(container,'output',1,'troubling','gaussmf',[0.0625 0.625]);
            container = addmf(container,'output',1,'critical','gauss2mf',[0.0625 0.875 0.01 1]);
            container = addmf(container,'output',1,'noDangerous','gauss2mf',[0.1 0 0.0625 0.125]);     
            
            ruleList = [ 3  0  0  4  1  1; % short or no actualPeriod
                         1  0  0  4  1  1;
                         
                         2  1  1  1  1  1;
                         2  1  2  1  1  1;  
                         2  1  3  1  1  1;
                         2  1  4  2  1  1;
                         2  1  5  3  1  1;
                         2  1  6  1  1  1;
                         
                         2  2  1  1  1  1;
                         2  2  2  1  1  1;
                         2  2  3  2  1  1;
                         2  2  4  2  1  1;
                         2  2  5  3  1  1;
                         2  2  6  2  1  1;
                         
                         2  3  0  3  1  1;
                       ];

            container = addrule(container,ruleList);        
            myTSAHistoryHandler.fuzzyContainer = container;
        end
        
    end
    
    methods(Static)
        
        % THRESHOLDSEVALUATION function is value evaluation base on 
        % function line
        function status = thresholdsEvaluation(value, parameters)
            
            % Evaluate status
            % 150*2 + 25
            statusNumeric = parameters(1)*value + parameters(2);
            
            if statusNumeric < 50
                
                status = 'GREEN';
            elseif statusNumeric >= 75 &&  statusNumeric < 100

                status = 'ORANGE';
            else 
                status = 'RED';
            end
        end
    end
    
end

