classdef periodicityHistoryContainer < historyContainer
    % periodicityHistoryContainer
    % Discription: Class is designed to storage data parsed from history
    
    properties (Access = protected)
        historyTable % structure of data from history
    end
    
     methods (Access = public)
        % Constructor function
        function myPeriodicityHistoryContainer = periodicityHistoryContainer(myFiles, myXmlToStructHistory)
            myHistoryType = 'periodicity';
            myPeriodicityHistoryContainer = myPeriodicityHistoryContainer@historyContainer(myFiles, myHistoryType, myXmlToStructHistory);
            
            [myPeriodicityHistoryContainer] = createPeriodicityHistoryTable(myPeriodicityHistoryContainer);
        end
        
        function [myPeriodicityHistoryTable] = getHistoryTable(myHistoryContainer)
            myPeriodicityHistoryTable = myHistoryContainer.historyTable;
        end
        function [myHistoryContainer] = setHistoryTable(myHistoryContainer,myHistoryTable)
            myHistoryContainer.historyTable = myHistoryTable;
        end    
        
     end
    
    methods (Access = protected)
        % CREATEHISTORYTABLE forms pattern of the historyTable from the
        % currentData (current status.xml) for further filling with history
        % data
        function [myPeriodicityHistoryContainer] = createPeriodicityHistoryTable(myPeriodicityHistoryContainer)
            myData.myCurrentData = getCurrentData(myPeriodicityHistoryContainer);
            myData.myHistoryData = getHistoryData(myPeriodicityHistoryContainer);
            
            myHistoryTable = data2Table(myPeriodicityHistoryContainer, myData);
            
            myPeriodicityHistoryContainer = setHistoryTable(myPeriodicityHistoryContainer,myHistoryTable);
        end

        % DATA2TABLE function transforms some inputData (in the
        % statusStruct format) to the table format
        function [myTable] = data2Table(myPeriodicityHistoryContainer, myData)
    
            informativeTags = myData.myCurrentData.informativeTags;
            if ~isempty(myData.myHistoryData)
                informativeTags = [informativeTags  reshape(cellfun(@(x)x.informativeTags, myData.myHistoryData), 1, [])];
            end
            myTable.frequency = []; myTable.energyContribution = [];  myTable.filtrationRange = [];
            myTable.traninPeriod = []; myTable.validity = []; myTable.type = [];
            myTable.resonantFrequency = []; myTable.averageAmpl = []; myTable.measureNum = [];
            myTable.maxMeasureNum = length(informativeTags);
            
            for i = 1:1:length(informativeTags)
                myTable.frequency = [myTable.frequency str2num(informativeTags(i).frequency.Attributes.value)];
                myTable.energyContribution = [myTable.energyContribution str2num(informativeTags(i).energyContribution.Attributes.value)];
%                 myTable.traninPeriod = [myTable.traninPeriod informativeTags(i).traninPeriod.Attributes];
                myTable.validity = [myTable.validity str2num(informativeTags(i).validity.Attributes.value)];
                if ~isempty(informativeTags(i).type.Attributes.value)
                    myTable.type = [myTable.type strsplit(informativeTags(i).type.Attributes.value, ',')];
                end
                myTable.resonantFrequency = [myTable.resonantFrequency str2num(informativeTags(i).resonantFrequency.Attributes.value)];
                myTable.averageAmpl = [myTable.averageAmpl str2num(informativeTags(i).averageAmpl.Attributes.value)];
                myTable.filtrationRange = [myTable.filtrationRange ...
                                            myPeriodicityHistoryContainer.rangesToFormat(informativeTags(i).filtrationRange.Attributes.value)];

                %According measure number. The current measure is the first.
                if ~isempty(myTable.frequency)
                    myTable.measureNum = [myTable.measureNum repmat( i, 1, numel(str2num(informativeTags(i).frequency.Attributes.value)) )];
                end
            end
            
            % Set date information.
            myTable.date = getDate(myPeriodicityHistoryContainer);
        end
        
    end
    
    methods(Access = public)
        
        function [equalIdxs] = compareData(myPeriodicityHistoryContainer, myData, myConfig)
            %Check does the first data cell contain 2 rows; if it is - it's filtration ranges; orient them as findClose requires.
            if size(myData{1}, 1) == 2
                myData{1} = myData{1}';
            end
            %If there is the only one element - return it.
            if numel(myData{2}) == 1
                equalIdxs = {1};
                return;
            end
            %Find all similar elements, where all rows are similar.
            similarIndexes = cell(1, size(myData, 1)); range = str2num(myConfig.range);
            for i = 1:size(myData, 1) %Data rows. similarIndexes are rows with cells of similars indexes in each data row.
                params = myConfig;
                params.range = num2str(range(i)); params.sortType = params.sortType{i}; %Take the current's data row similarity range. Bidimentional config is the only one - 4 the first array, if itis bidimentional.
                [similarIndexes{i}, ~] = myPeriodicityHistoryContainer.findClose(myData{i}, params); %(i, :)
            end
            %=====Intersection of the similars in the columns.=====
            aloneIdxs = reshape(1:max(size(myData{1})), 1, []); %All indexes are potentially alones.
            equalIdxs = [];
            for i = 1:numel(similarIndexes{1})
                for j = 1:numel(similarIndexes{2})
                    %Indexes of elements, that consist in both rows.
                    equalIdexes = intersect(similarIndexes{1}{i}, similarIndexes{2}{j});
                    if ~isempty(equalIdexes) %Add set of equals.
                        equalIdxs = [equalIdxs {equalIdexes}];
                    end
                    %Exclude from alones similars.
                    aloneIdxs = setxor(aloneIdxs, equalIdexes);
                end
            end
            %Add alones in separate cells.
            equalIdxs = [equalIdxs reshape(num2cell(aloneIdxs), 1, [])];
        end
        
    end
    
    methods(Access = public, Static = true)
        
        function [similarIndexes, similarValues] = findClose(myData, myConfig)
            [ similarValues, ~, similarIndexes, aloneIdxs ] = getSimilars( myData, myConfig); %struct('range', num2str(myRange)) 
            %Put together unique elems.
            if iscell(similarIndexes)
               similarIndexes = cellfun(@(x) find(x), similarIndexes, 'UniformOutput', false); 
            else
                similarIndexes = [];
            end
            if aloneIdxs
                similarIndexes = [similarIndexes' arrayfun(@(x) x, aloneIdxs, 'UniformOutput', false)];
            end
        end
    
        function numericRanges = rangesToFormat(inputRanges)
            if ~isempty(inputRanges)

                inputRangesCell = strsplit(inputRanges, ',');
                numericRanges = cell2mat(cellfun(@(x) str2num(x)', inputRangesCell, 'UniformOutput', false));
            else
                numericRanges = [];
            end
        end
    end
end
