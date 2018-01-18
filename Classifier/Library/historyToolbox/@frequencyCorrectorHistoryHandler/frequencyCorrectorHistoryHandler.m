classdef frequencyCorrectorHistoryHandler < historyHandler
    % FREQUENCYCORRECTORHISTORYHANDLER class is used to evaluation changes in frequencyCorrector
    % over time
    
    properties (Access = protected)
        parameters    % include parameters for this class from config.xml
    end
    
    methods (Access = public)
        % FREQUENCYCORRECTORHISTORYHANDLER constructor method
        function [myFrequencyCorrectorHistoryHandler] = frequencyCorrectorHistoryHandler(myConfig, myFiles, myTranslations, myXmlToStructHistory)
            if nargin < 1
                error('There are not enough input arguments!');
            end
            
            myContainerTag = 'frequencyCorrector';
            myFrequencyCorrectorHistoryHandler = ...
                myFrequencyCorrectorHistoryHandler@historyHandler(myConfig, myFiles, myContainerTag, myTranslations, myXmlToStructHistory);
            
            % Extract parameters from config
            Parameters = [];
            if isfield(myFiles.files, 'history')
                if isfield(myFiles.files.history.Attributes, 'actualPeriod')
                    Parameters.actualPeriod = myFiles.files.history.Attributes.actualPeriod;
                end
            end
            Parameters.debugModeEnable = myConfig.config.parameters.common.debugModeEnable.Attributes.value;
            Parameters.plots = myConfig.config.parameters.evaluation.plots.Attributes;
            Parameters.plotEnable = myConfig.config.parameters.evaluation.history.Attributes.plotEnable;
            Parameters.plotVisible = myConfig.config.parameters.common.printPlotsEnable.Attributes.visible;
            Parameters.plotTitle = myConfig.config.parameters.common.printPlotsEnable.Attributes.title;
            Parameters.printPlotsEnable = myConfig.config.parameters.common.printPlotsEnable.Attributes.value;
            
            % Check parameters and set default parameters (if the
            % parameters is empty)
            Parameters = fill_struct(Parameters, 'actualPeriod', '35');
            Parameters = fill_struct(Parameters, 'debugModeEnable', '0');
            Parameters = fill_struct(Parameters, 'plotEnable', '0');
            Parameters = fill_struct(Parameters, 'plotVisible', '0');
            Parameters = fill_struct(Parameters, 'printPlotsEnable', '0');
            
            myFrequencyCorrectorHistoryHandler.parameters = Parameters;
            
            myFrequencyCorrectorHistoryHandler = createFuzzyContainer(myFrequencyCorrectorHistoryHandler);
            myFrequencyCorrectorHistoryHandler = historyProcessing(myFrequencyCorrectorHistoryHandler);
        end
        
        % FILLDOCNODE function fills docNode document with calculated
        % result data
        function [docNode] = fillDocNode(myFrequencyCorrectorHistoryHandler, docNode)
%             iLoger = loger.getInstance;
%             myResult = getResult(myFrequencyCorrectorHistoryHandler);
%             if isempty(myResult)
%                 % Frequency corrector history is empty
%                 return;
%             end
%             
%             % Replase an existing node with a new node
%             docRootNode = docNode.getDocumentElement;
%             if hasChildNodes(docRootNode)
%                 childNodes = getChildNodes(docRootNode);
%                 numChildNodes = getLength(childNodes);
%                 for i = 1 : 1 : numChildNodes
%                     currentChild = item(childNodes, i - 1);
%                     childName = toCharArray(getNodeName(currentChild))';
%                     if strcmp(childName, 'frequencyCorrector')
%                         docRootNode.removeChild(currentChild);
%                         break;
%                     end
%                 end
%             end
%             
%             % Create frequencyCorrector node
%             frequencyCorrectorNode = docNode.createElement('frequencyCorrector');
% 
%             frequencyCorrectorNode.setAttribute('estimatedFrequency', num2str(myResult.estimated));
%             frequencyCorrectorNode.setAttribute('initialFrequency', num2str(myResult.initial));
%             
%             if isnan(myResult.validity)
%                 frequencyCorrectorNode.setAttribute('validity', []);
%             else
%                 frequencyCorrectorNode.setAttribute('validity', num2str(myResult.validity));
%             end
%             % Set frequencyCorrector node to root node
%             docRootNode.appendChild(frequencyCorrectorNode);
%             printComputeInfo(iLoger, 'frequencyCorrectorHistoryHandler', 'docNode structure was successfully updated.');
        end
    end
    
    methods (Access = protected)
        
        % HISTORYPROCESSING function print frequencyCorrector data into @Out directory
        function [myFrequencyCorrectorHistoryHandler] = historyProcessing(myFrequencyCorrectorHistoryHandler)
            
            iLoger = loger.getInstance;
            
            % Get input data
            myHistoryContainer = getHistoryContainer(myFrequencyCorrectorHistoryHandler);
            myHistoryTable = getHistoryTable(myHistoryContainer);
            myHistoryTable.date = flip(myHistoryTable.date);
            myHistoryTable.initial = flip(myHistoryTable.initial);
            myHistoryTable.estimated = flip(myHistoryTable.estimated);
            myHistoryTable.validity = flip(myHistoryTable.validity);
            
            myFrequencyCorrectorHistoryHandler.result.initial = myHistoryTable.initial{end};
            myFrequencyCorrectorHistoryHandler.result.estimated = myHistoryTable.estimated{end};
            myFrequencyCorrectorHistoryHandler.result.validity = myHistoryTable.validity{end};
            
            % ____________________ PLOT RESULTS _________________ %
            if str2double(myFrequencyCorrectorHistoryHandler.parameters.plotEnable)
                
                % Get parameters
                Translations = myFrequencyCorrectorHistoryHandler.translations;
                
                plotVisible = myFrequencyCorrectorHistoryHandler.parameters.plotVisible;
                plotTitle = myFrequencyCorrectorHistoryHandler.parameters.plotTitle;
                printPlotsEnable = str2double(myFrequencyCorrectorHistoryHandler.parameters.printPlotsEnable);
                sizeUnits = myFrequencyCorrectorHistoryHandler.parameters.plots.sizeUnits;
                imageSize = str2num(myFrequencyCorrectorHistoryHandler.parameters.plots.imageSize);
                fontSize = str2double(myFrequencyCorrectorHistoryHandler.parameters.plots.fontSize);
                imageFormat = myFrequencyCorrectorHistoryHandler.parameters.plots.imageFormat;
                imageQuality = myFrequencyCorrectorHistoryHandler.parameters.plots.imageQuality;
                imageResolution = myFrequencyCorrectorHistoryHandler.parameters.plots.imageResolution;
                
                xValue = 1 : 1 : length(myHistoryTable.initial);
                posNotNan = ~cellfun(@isnan, myHistoryTable.validity);
                validityValuePos = posNotNan;
                
                % Delete minutes and seconds
                myHistoryTable.date = ...
                    cellfun(@(x, y) x(1 : y - 1), myHistoryTable.date, ...
                    cellfun(@(x) x(1, 1), ...
                    strfind(myHistoryTable.date, ':', 'ForceCellOutput', true), 'UniformOutput', false), 'UniformOutput', false);
                
                % Added tag "hours"
                myHistoryTable.date = ...
                    cellfun(@(x) [x 'h'], myHistoryTable.date, ...
                    'UniformOutput', false);
                
                % Plot
                myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
                hold on;
                % Plot initial value
                plot(xValue, cell2num(myHistoryTable.initial), ...
                    'Color', [0 1 1], 'LineWidth', 2);
                % Plot real value
                plot(xValue, cell2num(myHistoryTable.estimated), ...
                    '--', 'Color', [0 0 1], 'LineWidth', 2);
                if nnz(validityValuePos)
                    % Plot real value
                    vectorEstimated = cell2num(myHistoryTable.estimated);
                    plot(xValue(validityValuePos), vectorEstimated(validityValuePos), ...
                        'cX', 'Color', [1 0 0], 'MarkerSize', 10, 'LineWidth', 4);
                    legendLabels = {'Initial frequencies', 'Estimated frequencies', 'Validity OK'};
                else
                    legendLabels = {'Initial frequencies', 'Estimated frequencies'};
                end
                hold off;
                grid on;
                
                % Get axes data
                myAxes = myFigure.CurrentAxes;
                % Set axes font size
                myAxes.FontSize = fontSize;
                
                % Figure title
                if strcmp(plotTitle, 'on')
                    title(myAxes, [upperCase(Translations.shaftSpeedRefinement.Attributes.name, 'all'), ' - ', ...
                        upperCase(Translations.history.Attributes.name, 'first')]);
                end
                % Figure labels
                xlabel(myAxes, upperCase(Translations.actualPeriod.Attributes.name, 'first'));
                ylabel(myAxes, [upperCase(Translations.frequency.Attributes.name, 'first'), ', ', ...
                    upperCase(Translations.frequency.Attributes.value, 'first')]);
                % Replace the x-axis values by the date
                xticks(myAxes, xValue);
                xticklabels(myAxes, myHistoryTable.date);
                xtickangle(myAxes, 90);
                % Figure legend
                legend(legendLabels, 'Location', 'northwest');
                
                if printPlotsEnable
                    % Save the image to the @Out directory
                    imageNumber = '1';
                    fileName = ['history-SSR-full-acc-', imageNumber];
                    fullFileName = fullfile(pwd, 'Out', fileName);
                    print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
                end
                
                % Close figure with visibility off
                if strcmpi(plotVisible, 'off')
                    close(myFigure)
                end
            end
            printComputeInfo(iLoger, 'frequencyCorrectorHistoryHandler', 'FrequencyCorrection history processing COMPLETE.');
        end
        
        % (UNUSED)CREATEFUZZYCONTAINER function creates empty fuzzy container 
        function [myMetricsHistoryHandler] = createFuzzyContainer(myMetricsHistoryHandler)
            myMetricsHistoryHandler.fuzzyContainer = [];
        end
    end
end