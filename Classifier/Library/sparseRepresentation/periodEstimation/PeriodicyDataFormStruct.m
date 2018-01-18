function PeriodicyData = PeriodicyDataFormStruct(DitsanceData, peaksOverlap)
    %PeriodicyDataFormStruct forms a common struct with all periodicy
    %information from ACF's peaks information.
    
    %Indexes of frames, that put together periodicy are in each cell.
    ValidIndexSimilars = [DitsanceData.ValidIndexSimilars];
    if ~iscell(ValidIndexSimilars)
        PeriodicyData.PeaksPositions = [];
        PeriodicyData.PeaksDistancies = [];
        PeriodicyData.PeaksDistSTD = [];
        PeriodicyData.AverageLeaf = [];
        PeriodicyData.LowLeaf = [];
        return;
    end
    %Peaks positions of the periodicies - original table with peaks vector that divided on frames.
    PeaksCorrelPositionMatrix = [DitsanceData.PeaksCorrelPositionMatrix];
    %Distancies between according peaks of the periodicies.
    diffDistanceMatrix = [DitsanceData.diffDistanceMatrix];
    %STD of distancies %in valid frames.
    stdDistanceVector = [DitsanceData.stdDistanceVector];
    validFrames = find(DitsanceData.validationVector);

    %Put the data in the periodicy's struct.
    %Get from peaks and distance matrixes only valid windows and put it together.
    %It's need to choose only peaks of the current periodicy.
    for i=1:numel(ValidIndexSimilars) %To number of periodicies.
        %Get the current periodicy's frames and make row vectors from them.
        TheCurrPeriodicyFrames = validFrames(ValidIndexSimilars{i});
        PeaksPositions = PeaksCorrelPositionMatrix(TheCurrPeriodicyFrames, :);
        PeaksDistancies = diffDistanceMatrix(TheCurrPeriodicyFrames, :);
        %Make a vectors.
        PeaksPositions = reshape(PeaksPositions, 1, []); %Matrix to vector.
        %Delete a similar elements (overlaps) and fill struct.
        PeriodicyData(i).PeaksPositions = unique(PeaksPositions);
        %Valid windows number.
        PeriodicyData(i).validFrames = TheCurrPeriodicyFrames;
        %Distance vector.
        PeaksDistancies = PeaksDistancies( 1:end, 1:end - (peaksOverlap - 2) ); %Delete overlap; decrement it because diff vector id shorter.
        PeaksDistancies = reshape(PeaksDistancies, 1, []); %Matrix to vector.
        PeriodicyData(i).PeaksDistancies = PeaksDistancies;
        % Put in data of the whole periodicy - dist. STD and period table element.
        PeaksDistSTD = stdDistanceVector(TheCurrPeriodicyFrames);  %STD of distancies in the current periodicy's frames.
        %PeriodicyData(i).PeaksDistSTDwind = mean(PeaksDistSTD);
        %PeriodicyData(i).PeaksDistSTD = std(PeriodicyData(i).PeaksPositions);
        PeriodicyData(i).PeaksDistSTD = mean(PeaksDistSTD);
        %BaseTableInfo: average period (mean of distancies), frequency, number of periods, validity.
        %PeriodicyData(i).BaseTableInfo = BaseTable(i);
        PeriodicyData(i).AverageLeaf = [];
        PeriodicyData(i).LowLeaf = [];
    end 
end