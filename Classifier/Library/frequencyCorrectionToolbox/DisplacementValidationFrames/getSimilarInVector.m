function [ similarVector, validPositions ] = getSimilarInVector(element, file, config )

similarVector = [];
if nargin <3
   config = []; 
end

%% _____________________ Default Parameters ___________________________ %%
config = fill_struct(config,'percentRange', '1'); % in [%]
config = fill_struct(config,'sortStr', 'none');
config = fill_struct(config,'freqRange', '0'); % in [Hz]

if ischar(config.percentRange)
    config.percentRange = str2double(config.percentRange);
end
config.freqRange = str2double(config.freqRange);

%% _____________________ Calculations _________________________________ %%

% Form element frequencies = [element, element, ...] and init similarity range
if ~isempty(file)
    frequencies = file;
else
    similarVector = [];
    validPositions = false;
    return
end
elementVector = ones(size(frequencies)).*element;
% Use percentRange by default
if ~config.freqRange
    delta = config.percentRange/100;
else
    delta = config.freqRange/element;
end
% Implement element-by-element comparison ans find frequencies elements
% belonging to range [element-delta; element + delta];
validPositions = bsxfun(@and,bsxfun(@lt,frequencies,elementVector*(1+delta)),...
    bsxfun(@ge,frequencies,elementVector*(1-delta)));

if ~strcmp(config.sortStr, 'none')
    [~, validPositions] = sort(validPositions, config.sortStr);
end

similarVector = unique(nonzeros(bsxfun(@times,frequencies,validPositions)));
validPositions = find(validPositions);
% If there no similar elements in frequencies set similarVector to zero value
if isempty(similarVector)
    similarVector = [];
    validPositions = false;
end