classdef peroiodicityHistoryHandler < historyHandler
    % peroiodicityHistoryHandler
    % Discription: Class is designed to evaluate the history of the time-domain correlation periods finding:
    % 1) Get data from history;
    % 2) Find all unique periods by both freqs - resonant and period;
    % 3) Set to each found for all watching time period it's validity. 
    % Input: history data 
    % Output structure: current data of history files, table with full periods data, validation data.
    % The main output parameter - "history" validity, that highlight possibly progressing defect, valid defect periods freqs.
    
    properties (Access = protected)
        % Input properties
        parameters % configurable parameters
    end
    
    methods (Access = public)
        % Constructor function
        function [myPeroiodicityHistoryHandler] = peroiodicityHistoryHandler(myConfig, myFiles, myTranslations, myXmlToStructHistory)
            if nargin < 1
               error('There are not enough input arguments!'); 
            end
            
            myContainerTag = 'periodicity';
            myPeroiodicityHistoryHandler = myPeroiodicityHistoryHandler@historyHandler(myConfig, myFiles, myContainerTag, myTranslations, myXmlToStructHistory);
            
            % Set standard parameters
            parameters = myConfig.config.parameters.evaluation.history.periodicityHistoryHandler.Attributes;
            parameters.trend = myConfig.config.parameters.evaluation.history.trend;
            parameters.intensivityHandler = myConfig.config.parameters.evaluation.history.intensivityHandler;
            if isfield(myFiles.files.history.Attributes, 'actualPeriod')
                parameters.maxPeriod = myFiles.files.history.Attributes.actualPeriod;
            end
            if isfield(myFiles.files.history.Attributes, 'comparisonRangesPercent')
                parameters.comparisonRangesPercent = myFiles.files.history.Attributes.comparisonRangesPercent;
            end
            if isfield(myFiles.files.history.Attributes, 'stableSequenceTreshold')
                parameters.stableSequenceTreshold = myFiles.files.history.Attributes.stableSequenceTreshold;
            end
            if isfield(myFiles.files.history.Attributes, 'sortStr')
                parameters.sortStr = myFiles.files.history.Attributes.sortStr;
            end
            if isfield(myFiles.files.history.Attributes, 'resonantFreqSimilarity')
                parameters.resonantFreqSimilarity = myFiles.files.history.Attributes.resonantFreqSimilarity;
            end
            if isfield(myFiles.files.history.Attributes, 'overlapPercent')
                parameters.overlapPercent = myFiles.files.history.Attributes.overlapPercent;
            end
            if isfield(myFiles.files.history.Attributes, 'percentageOfReange')
                parameters.percentageOfReange = myFiles.files.history.Attributes.percentageOfReange;
            end
            parameters = fill_struct(parameters, 'comparisonRangesPercent', '10 10'); %Resonant & period freqs similarity ranges.
            parameters = fill_struct(parameters, 'stableSequenceTreshold', '6'); %Number of one-by-one period detection, when validity is 1.
            parameters = fill_struct(parameters, 'sortStr', 'ascend ascend');
            %Choose approach of resonant frequency similarity: by closeness of central (resonant) freq or including filtration ranges.
            parameters = fill_struct(parameters, 'resonantFreqSimilarity', 'ranges'); %centralFreq ranges
            %Range similarity params.
            parameters = fill_struct(parameters, 'overlapPercent', '0.7');
            parameters = fill_struct(parameters, 'percentageOfReange', '1');
            
            myPeroiodicityHistoryHandler.parameters = parameters;
            
            myPeroiodicityHistoryHandler = historyProcessing(myPeroiodicityHistoryHandler);
        end
        
        % FILLDOCNODE function fills docNode document with calculated
        % result data
        function [docNode] = fillDocNode(myPeriodicityHistoryHandler, docNode)
            
            iLoger = loger.getInstance;
            myResultStruct = getResult(myPeriodicityHistoryHandler);
            intensivityThreshold = str2double(myPeriodicityHistoryHandler.parameters.intensivityThreshold);
            
            docRootNode = docNode.getDocumentElement;
            [docRootNode, theChild] = myPeriodicityHistoryHandler.remChild(docRootNode, 'periodicity');
            periodicityNode = docNode.createElement('periodicity');
            docRootNode.appendChild(periodicityNode);
            
            %=====Create all necessary status fields=====
            informativeTagsNode = docNode.createElement('informativeTags');
            statusNode = docNode.createElement('status');
            statusNode.setAttribute('value', ''); 
            
            frequencyTimeDomainNode = docNode.createElement('frequency');
            frequencyTimeDomainNode.setAttribute('value', '');
            energyContributionTimeDomainNode = docNode.createElement('energyContribution');
            energyContributionTimeDomainNode.setAttribute('value', '');
            validityTimeDomainNode = docNode.createElement('validity');
            validityTimeDomainNode.setAttribute('value', '');
            typePeriodicityNode = docNode.createElement('type');
            typePeriodicityNode.setAttribute('value', '');
            resonantFrequencyTimeDomainNode = docNode.createElement('resonantFrequency');
            resonantFrequencyTimeDomainNode.setAttribute('value', '');
            averageAmplTimeDomainNode = docNode.createElement('averageAmpl');
            averageAmplTimeDomainNode.setAttribute('value', '');
            filtrationRangeTimeDomainNode = docNode.createElement('filtrationRange');
            filtrationRangeTimeDomainNode.setAttribute('value', '');
            historyValidityTimeDomainNode = docNode.createElement('historyValidity');
            historyValidityTimeDomainNode.setAttribute( 'value', '' );
            
            informativeTagsNode.appendChild(frequencyTimeDomainNode);
            informativeTagsNode.appendChild(energyContributionTimeDomainNode);
            informativeTagsNode.appendChild(validityTimeDomainNode);
            informativeTagsNode.appendChild(typePeriodicityNode);
            informativeTagsNode.appendChild(resonantFrequencyTimeDomainNode);
            informativeTagsNode.appendChild(averageAmplTimeDomainNode);
            informativeTagsNode.appendChild(filtrationRangeTimeDomainNode);
            informativeTagsNode.appendChild(historyValidityTimeDomainNode);
            
            periodicityNode.appendChild(statusNode);
            periodicityNode.appendChild(informativeTagsNode);
            %Result is empty when there are no any period in the current and in the previous measures, so return an empty filled status.
            if isempty(myResultStruct)
                printComputeInfo(iLoger, 'iso15242HistoryHandler', 'docNode structure was successfully updated.');
                return;
            end
            
            %=====Fill original data from the current measure column.=====
            %===Get data of existing in the current measure elements.===
            %Get the first column (the last measure) and find non-empties (existing periodicies).
            currentExist = find(cellfun(@(x) ~isempty(x), myResultStruct.measureFrequencyTable(:, 1)));
            if isempty(currentExist)
                printComputeInfo(iLoger, 'iso15242HistoryHandler', 'docNode structure was successfully updated.');
                return;
            end
            myDataPerFr = []; myDataEC = []; myDataV = []; myDataT =[];  myDataRF = []; myDataAvA = []; myDataFilR = [];
            for i = currentExist' %1:numel(currentExist)
                myData = myResultStruct.measureFrequencyTable{i, 1};
                myDataPerFr = [myDataPerFr (myData{1}{1, 1})]; myDataEC = [myDataEC (myData{2}{1, 1})]; myDataV = [myDataV (myData{3}{1, 1})]; myDataT = [myDataT myData{4}{1, 1}];
                myDataRF = [myDataRF (myData{5}{1, 1})]; myDataAvA = [myDataAvA (myData{6}{1, 1})]; myDataFilR = [myDataFilR (myData{7}{1, 1})];
            end
            frequencyTimeDomainNode.setAttribute('value', vector2strStandardFormat(round(myDataPerFr, 2)));
            energyContributionTimeDomainNode.setAttribute('value', vector2strStandardFormat(round(myDataEC, 2)));
            validityTimeDomainNode.setAttribute('value', vector2strStandardFormat(round(myDataV, 2)));
            typePeriodicityNode.setAttribute('value', vector2strStandardFormat(myDataT));
            resonantFrequencyTimeDomainNode.setAttribute('value', vector2strStandardFormat(round(myDataRF, 2)));
            averageAmplTimeDomainNode.setAttribute('value', vector2strStandardFormat(round(myDataAvA, 2)));
%             filtrationRangeStr = arrayfun(@(x) num2str(round(myDataFilR(x, :).*100)/100), 1:2, 'UniformOutput', false);
%             filtrationRangeTimeDomainNode.setAttribute('value', strjoin(cellfun(@(x) strjoin(strsplit(x)), filtrationRangeStr, 'UniformOutput', false), '; ') ); %Join rows by semicolon.
            filtrationRangeTimeDomainNode.setAttribute('value', ...
                                                        char(strtrim(regexprep(strjoin(string(num2str(myDataFilR')), ','), ' +', ' '))));

%             filtrationRangeTimeDomainNode.setAttribute('value', num2str(myDataFilR));
            
            %=====Choose history intensivity validities of existing in the current status elements, fill in valid periods.=====
            frequency = reshape(myResultStruct.periodsFrequencies(currentExist), 1, []);
            histValids = reshape(myResultStruct.intensivityResultVector(currentExist), 1, []);
            historyValidityTimeDomainNode.setAttribute('value', vector2strStandardFormat(round(histValids, 2))); 
            %Choose valid periods by their appearence history validity.
            informativeFreqs = frequency(histValids > intensivityThreshold);
            statusNode.setAttribute( 'value', vector2strStandardFormat(round(informativeFreqs, 2)));
            
            printComputeInfo(iLoger, 'periodicityHistoryHandler', 'docNode structure was successfully updated.');
        end
    end
    
    methods (Access = protected)  
        
        % HISTORYPROCESSING function calculate status
        function [myPeriodicityHistoryHandler] = historyProcessing(myPeriodicityHistoryHandler)
            % Loger initialization
            iLoger = loger.getInstance;
            
            % Get data from history files
            myHistoryContainer = getHistoryContainer(myPeriodicityHistoryHandler);
            myTableOrig = getHistoryTable(myHistoryContainer);
            
            comparisonRangesPercent = str2num(myPeriodicityHistoryHandler.parameters.comparisonRangesPercent);
            stableSequenceTreshold = str2double(myPeriodicityHistoryHandler.parameters.stableSequenceTreshold);
            sortStr = strsplit(myPeriodicityHistoryHandler.parameters.sortStr);
            overlapPercent = str2double(myPeriodicityHistoryHandler.parameters.overlapPercent);
            percentageOfReange = str2double(myPeriodicityHistoryHandler.parameters.percentageOfReange);
            
            if isempty(myTableOrig.frequency)
                printComputeInfo(iLoger, 'Periodicity history', 'There is an empty history.');
                myPeriodicityHistoryHandler.result = [];
                return
            end
            myTable.validationData.initialTable = myTableOrig;
            if strcmp(myPeriodicityHistoryHandler.parameters.resonantFreqSimilarity, 'ranges')
                myData = {myTableOrig.filtrationRange}; myData = [myData; {myTableOrig.frequency}];
            else
                myData = [{myTableOrig.resonantFrequency}; {myTableOrig.frequency}];
            end
            
            %=====Choose similars by resonant frequency and periodicy.=====
            %Indexes of grouped elems by both freqs. Each cell is idxs of each periodicy in
            %the data vector, that characterises by resonant and period frequencies.
            similConf.range = num2str(comparisonRangesPercent); similConf.sortType = sortStr;
            similConf = fill_struct(similConf, 'overlapPercent', overlapPercent); similConf = fill_struct(similConf, 'percentageOfReange', percentageOfReange);
            [equalIdxs] = myHistoryContainer.compareData(myData, similConf);
			
            %=====Make a cell matrix size (unique elems - rows)x(measures number - columns).=====
            %Each cell is element with full periodicy information. Empty cells in row
            %are measures, when the current periodicy loss, in column are absent periods in the curr measure.
            measureFrequencyTable = cell(numel(equalIdxs), myTableOrig.maxMeasureNum); %Make columns number as the whole measures number, rest empty cells with empty measures. %numel(unique(myTableOrig.measureNum)) %max(myTableOrig.measureNum)
			
            %Average basic values.
            resonantFreqs = zeros( size(equalIdxs) )'; periodsFrequencies = resonantFreqs;
            stabilityMetric = resonantFreqs; averValid = resonantFreqs; averAmpl = resonantFreqs; histValid = resonantFreqs;
            for i = 1:numel(equalIdxs)
                %Put in each cell according 2 both freqs and measure number a measure data.
                for j = 1:numel(equalIdxs{i})
                    theCurrDataIdx = equalIdxs{i}(j); %Indexes of the current similars in the data vectors.
                    %Measure indexes, idxs in the rows, numbers of columns.
                    measIdx = myTableOrig.measureNum(theCurrDataIdx);
                    %Row index is an index if similars group, data will be sorted by both freq next time.
                    %==Make a vector of data (freq, ampl, valid ...) 4 each element of the current similars.==
                    theCurrDataCell = {{myTableOrig.frequency(theCurrDataIdx)}, {myTableOrig.energyContribution(theCurrDataIdx)}, {myTableOrig.validity(theCurrDataIdx)}, ...
                        {myTableOrig.type(theCurrDataIdx)}, {myTableOrig.resonantFrequency(theCurrDataIdx)}, {myTableOrig.averageAmpl(theCurrDataIdx)}, {myTableOrig.filtrationRange(:, theCurrDataIdx)}};
                    %Put in all data according 2 measure numb and both freqs.
                    measureFrequencyTable{i, measIdx} = theCurrDataCell;
                end
                %=====Average basic values (freqs, ...), compute the common history validity 4 the current periodicy.=====
                %Average freqs correspond 2 matrix columns - unique periods.
                resonantFreqs(i) = mean( myTableOrig.resonantFrequency(equalIdxs{i}) );
                periodsFrequencies(i) = mean( myTableOrig.frequency(equalIdxs{i}) );
                averValid(i) = mean( myTableOrig.validity(equalIdxs{i}) );
                %In original table amplitude averages by the long signal, here - by measures.
                averAmpl(i) = mean( myTableOrig.averageAmpl(equalIdxs{i}) );
                %=====Compute a history validity, depending on amplitude, validity, frequency and stability of occurrence.=====
                %The current periods existing measures.
                nonEmpties = cellfun(@(x) ~isempty(x), measureFrequencyTable(i, :)); nonEmpties = find(nonEmpties);
                theCurrStability = 1./diff(nonEmpties); %Inversely proportional 2 period detection time distance.
                if isempty(theCurrStability)
                    theCurrStability = 0;
                else
                    theCurrStability = [theCurrStability(1) theCurrStability];
                end
                stableDetectionIdxs = theCurrStability > 1/3;
                stableDetectionParts = takeOneByOneBands( double(~stableDetectionIdxs), struct( 'succession', 'zero', 'minInSuccession', '2') );
                stableDetectionElems = cellfun(@(x) x(1):x(2), stableDetectionParts, 'UniformOutput', false);
                stableDetectionElems = horzcat(stableDetectionElems{:}); %All elements (measures) on the stable parts.
                stabilityMetric(i) = numel(stableDetectionElems)/stableSequenceTreshold; %Relation stable elems num 2 min necessary.
                %History validity is weighted sum of other validity kinds. Restrict them previously to [0 1] range.
                histValid(i) = mean([averValid(i) averAmpl(i) min(stabilityMetric(i), 1)]);
            end
            %=====Sort by resonant, then period freqs.=====
            %Get groups of indexes of resFreqs, sorted by mean value.
            similConf = struct('range', num2str(comparisonRangesPercent(1)), 'sortType', sortStr{1});
            similConf = fill_struct(similConf, 'overlapPercent', overlapPercent); similConf = fill_struct(similConf, 'percentageOfReange', percentageOfReange);
            [~, ~, ~, ~, groupedIndexes] = getSimilars( resonantFreqs,  similConf);
			
			
            %Get sorted by period freq groups among each resFreq.
            similConf = struct('range', num2str(comparisonRangesPercent(2)), 'sortType', sortStr{2});
            similConf = fill_struct(similConf, 'overlapPercent', overlapPercent); similConf = fill_struct(similConf, 'percentageOfReange', percentageOfReange);
            [~, ~, ~, ~, groupedIndexesPeriod] = cellfun(@(x) getSimilars( periodsFrequencies(x),  similConf), groupedIndexes, 'UniformOutput', false);
			
            %Transpose indexes inside each resonant similars groups.
            groupedIndexes = cellfun(@(x, y) x(vertcat(y{:}))', groupedIndexes, groupedIndexesPeriod, 'UniformOutput', false);
            IdxsSort = horzcat(groupedIndexes{:}); %Row of ordered indexes.
			
            %Transpose all values.
            resonantFreqs = resonantFreqs(IdxsSort);
            periodsFrequencies = periodsFrequencies(IdxsSort);
            measureFrequencyTable = measureFrequencyTable(IdxsSort, :);
            averValid = averValid(IdxsSort);
            averAmpl = averAmpl(IdxsSort);
            stabilityMetric = stabilityMetric(IdxsSort);
            histValid = histValid(IdxsSort); %Validity computed by simple metrics.
            
            %=====Validate unique periods.=====
            % Compress appearing history of each freq. Get history data vector 4 each periodicy.
            %Transmit a measure cell vector 4 each periodicy. Get a vector of periods appearences.
            [myHistoryData, myDates] = arrayfun(@(x) getCompressedHist4period(myPeriodicityHistoryHandler, measureFrequencyTable(x, :)), 1:numel(IdxsSort), 'UniformOutput', false);
			
            % Crop empty history.
            [historyDataMagnitudes, myDateMagnitudes, posLastNumericCrop] = cellfun(@(x, y) myPeriodicityHistoryHandler.cropEmptyHistory(x, y), myHistoryData, myDates, 'UniformOutput', false);
            nonEmptIdxs = find(cellfun(@(x) ~isempty(x), historyDataMagnitudes)); %Get indexes of periodicies with valid history.
            intensivityResultVector = zeros(size(historyDataMagnitudes)); %Periodicies with a good history.
			
            %Compute an appearence intensivity.
            configIntensivityHandler = myPeriodicityHistoryHandler.parameters.intensivityHandler.Attributes;
            configIntensivityHandler.intensivityThreshold = myPeriodicityHistoryHandler.parameters.intensivityThreshold;
            myIntensivityHandler = cellfun(@(x) intensivityHandler(x, configIntensivityHandler), historyDataMagnitudes(nonEmptIdxs), 'UniformOutput', false);
            intensivityResultVector(nonEmptIdxs) = cellfun(@(x) getResult(x), myIntensivityHandler); 
            
            myTable.measureFrequencyTable = measureFrequencyTable;
            myTable.resonantFreqs = resonantFreqs;
            myTable.periodsFrequencies = periodsFrequencies;
            myTable.intensivityResultVector = intensivityResultVector;
            myTable.validationData.histValids = histValid;
            myTable.validationData.averValid = averValid;
            myTable.validationData.averAmplValidity = averAmpl;
            myTable.validationData.stabilityMetric = stabilityMetric;
            
            myPeriodicityHistoryHandler.result = myTable;
			
			printComputeInfo(iLoger, 'periodicityHistoryHandler', 'periodicityHistoryHandler history processing COMPLETE.');
        end
        
        function [myPeriodicityHistoryHandler] = createFuzzyContainer(myPeriodicityHistoryHandler)
        end
        
        % getCompressedHist4period Compresses the current periodicy appearing history during assigned time (day, ...).
        function [myHistoryData, myDates] = getCompressedHist4period(myPeriodicityHistoryHandler, data)
            validityVect = zeros(size(data)); nonEmptIdxs = cellfun(@(x) ~isempty(x), data); %Put zeros instead of empty data, it will be ignored during compression.
            validityVect(nonEmptIdxs) = cellfun(@(x) x{3}{:}, data(nonEmptIdxs)); %The third elem inside cell is validity.
            [myHistoryData, myDates] = getCompressedHist(myPeriodicityHistoryHandler, validityVect);
        end
        
        % getCompressedHist Compresses history during assigned time (day, ...).
        function [myHistoryData, myDates] = getCompressedHist(myPeriodicityHistoryHandler, data)
            myHistoryContainer = getHistoryContainer(myPeriodicityHistoryHandler);
            myDate = getDate(myHistoryContainer);
            myHistoryCompression = historyCompression(data, myDate, myPeriodicityHistoryHandler.parameters.trend.Attributes, 'env'); %myConfig.config.parameters.evaluation.history.trend.Attributes
            compression = getCompressedHistory(myHistoryCompression);
            myHistoryData = flip(compression.data); %Compressed data.
            myDates = flip(compression.date); %Time vector.
        end
        
    end
    
    methods(Static)
        
        % remChild removes assigned child node and get it back.
        function [docRootNode, theChild] = remChild(docRootNode, name2remove)
            % Remove assigned child node and get it back.
            if hasChildNodes(docRootNode)
                childNodes = getChildNodes(docRootNode);
                numChildNodes = getLength(childNodes);
                for count = 1:numChildNodes
                    theChild = item(childNodes,count-1);
                    name = toCharArray(getNodeName(theChild))';
                    if strcmp(name, name2remove)
                        docRootNode.removeChild(theChild);
                        break;
                    end
                end
            end
        end %remChild
        
        % CROPEMPTYHISTORY Crops history data to the first non-empty element.
        function [data, time, posLastNumeric] = cropEmptyHistory(data, time)
            if data(end) == 0 && (nnz(data)~=0)
                posLastNumeric = find(data ~= 0, 1, 'last');
                data = data(1:posLastNumeric);
                time = time(1:posLastNumeric);
            else
                posLastNumeric = length(data);
            end
        end
        
    end
    
end

