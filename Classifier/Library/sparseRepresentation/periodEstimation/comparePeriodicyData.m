function PeriodicyData = comparePeriodicyData(PeriodicyDataStructs, baseTable)
    if isempty(baseTable)
        PeriodicyData = [];
        return
    end
    HighTableIdx = [baseTable.IndexHigh];
    AverageTableIdx = [baseTable.IndexAverage];
    LowTableIdx = [baseTable.IndexLow];
    for i = 1:2 %Periodicy data struct count.
        CurrPeriodicyData = PeriodicyDataStructs{i};
        NumStructs = numel(CurrPeriodicyData);
        for j = 1:NumStructs
            %Put in result struct higher struct element.
        end
    end
end