function [ similarValue, similarNumber, validity, aloneIdxs, groupedIndexes, groupedValues] = getSimilars( signal, config )
%GETSIMILARS groups close signal samples.
%Returns a group average values, group elements number, group elements indexes,
%indexes of alone elements, all indexes divided on groups, all groups average values.

if nargin < 2
    config = [];
end
signal = reshape( signal, [], min(size(signal)) ); signalIdxs = ones(size(signal, 1), 1); validityTemp = [];

%% _______________________ Default Perameters _________________________ %%
config = fill_struct(config,'range','10'); % Range to find similar peak
                                         % distances [percents]
config = fill_struct(config,'sortType', 'descend');
config = fill_struct(config,'printEnable', '0');
%Range def params.
config = fill_struct(config, 'overlapPercent', '70');
config = fill_struct(config, 'percentageOfReange', '10');

range = str2double(config.range);
%% _______________________ Calculations _______________________________ %%
% Check all peak distances to find the similar ( belonging to the same
% range)
i = 0;
similarValueTemp = [];
%signal is mean distancies in the frames.
aloneIdxs = 1:numel(signalIdxs);
while nnz(signalIdxs)
    testVector = [];
    [row,col] = find(signalIdxs);
    %Take the first non-zero distance and make a signal-length vector to compare.
    %After processing it will be set to zero.
    testVector = ones(size(signalIdxs))*signal(row(1,1),col(1,1));
    %Compare element-by-element our signal (distancies) with the current
    %dist., find elements that lies in range around the current elem.
    if size(signal, 2) == 1
        sg = signal; sg(~logical(signalIdxs)) = NaN(size( sg(~logical(signalIdxs)) ));
        validElements = bsxfun(@and, bsxfun(@le,sg,testVector.*(1+range/100)),bsxfun(@ge,sg,testVector.*(1-range/100)));
    else %If ranges are assigned, take valid elements as overlapping and including ranges with the current one.
        %Compare the first non-processed range and all non-processed ranges.
        validElements = similarRanges(num2cell( signal(row(1,1), :) ), num2cell(signal(row(1,1):end, :)), config); %(:, row(1,1):end) 
        validElements = logical([zeros(size( 1:row(1,1)-1 ))'; validElements]);
    end
    %In we found clode dist., take average distance and sum of periods (correlogramm's peaks).
    if nnz(validElements)>=2
        i=i+1;
        similarValueTemp(i,1) = mean(signal(validElements,1));
        similarNumberTemp(i,1) = nnz(validElements);
        validityTemp{i,1} = validElements;
        aloneIdxs(validElements) = zeros(size( aloneIdxs(validElements) ));
    end
    signalIdxs(validElements,1) = 0;
end
%===Group elements by close values, sort groups by average value.===
aloneIdxs = find(aloneIdxs);
%Put together unique elems.
if iscell(validityTemp)
   groupedIndexes = cellfun(@(x) find(x), validityTemp, 'UniformOutput', false); 
else
    groupedIndexes = [];
end
if aloneIdxs
    groupedIndexes = [groupedIndexes' arrayfun(@(x) x, aloneIdxs, 'UniformOutput', false)];
end
groupedValues = cellfun(@(x) mean(signal(x, 1)), groupedIndexes);
[groupedValues, idxs] = sort(groupedValues, config.sortType);
groupedIndexes = reshape(groupedIndexes(idxs), 1, []);

if isempty(similarValueTemp)
    if str2double(config.printEnable), disp('There is no stable period in the signal.'); end
    similarValue = [];
    similarNumber = 0;
    validity = 0;
else
    similarValue = sort(similarValueTemp,config.sortType);
    [~,ai,bi] = intersect(similarValueTemp,similarValue);
    similarNumber = zeros(size(similarNumberTemp));
    validity = cell(size(validityTemp));
    
    for i=1:1:numel(similarValue)
        similarNumber(bi,1) = similarNumberTemp(ai,1);
        validity(bi,1) = validityTemp(ai,1);
    end
end

end

