function [ similarVector ] = getSimilarElements(element, peakTable, config )

similarVector = [];
if nargin <3
   config = []; 
end

%% _____________________ Default Parameters ___________________________ %%
config = fill_struct(config,'percentRange', '1'); % in [%]
config = fill_struct(config,'sortBy', 'none');
config = fill_struct(config,'freqRange', '0'); % in [Hz]
config = fill_struct(config,'modeFunction', '0'); % use function for comparison
config = fill_struct(config,'coefficientModeFunction', '1');

if ischar(config.percentRange)
    config.percentRange = str2double(config.percentRange);
end
config.freqRange = str2double(config.freqRange);
config.modeFunction = str2double(config.modeFunction);
config.coefficientModeFunction = str2double(config.coefficientModeFunction);
%% _____________________ Calculations _________________________________ %%

% Form element frequencies = [element, element, ...] and init similarity range
if ~isempty(peakTable)
    frequencies = peakTable(:,1);
else
    similarVector = [];
    return
end
elementVector = ones(size(frequencies)).*element;
% Use percentRange by default
if config.modeFunction
    delta = ((0.03*sqrt(element/config.coefficientModeFunction)))/element;
else
    if ~config.freqRange
        delta = config.percentRange/100;
    else
        delta = config.freqRange/element;
    end
end
% Implement element-by-element comparison ans find frequencies elements
% belonging to range [element-delta; element + delta];
validPositions = bsxfun(@and,bsxfun(@lt,frequencies,elementVector*(1+delta)),...
    bsxfun(@ge,frequencies,elementVector*(1-delta)));
% similarVector = nonzeros(bsxfun(@times,frequencies,validPositions));

switch (config.sortBy)
    case 'height'        
       heightArray = bsxfun(@times,peakTable(:,2),validPositions);
        if ~nnz(heightArray)
            return
        end
        [~, maxPosition] = max(heightArray);
        validPositions = validPositions*0; 
        validPositions(maxPosition,1) = 1;
    case 'prominence'
        prominenceArray = bsxfun(@times,peakTable(:,3),validPositions);
        if ~nnz(prominenceArray)
            return
        end
        [~, maxPosition] = max(prominenceArray);
        validPositions = validPositions*0; 
        validPositions(maxPosition,1) = 1;
    case 'global'
        globalArray = bsxfun(@times,bsxfun(@times,peakTable(:,2),validPositions),bsxfun(@times,peakTable(:,3),validPositions));
        if ~nnz(globalArray)
            return
        end
        [~, maxPosition] = max(globalArray);
        validPositions = validPositions*0; 
        validPositions(maxPosition,1) = 1;
    case 'none'
        validPositions = validPositions;
end

similarVector = unique(nonzeros(bsxfun(@times,frequencies,validPositions)));
% If there no similar elements in frequencies set similarVector to zero value
if isempty(similarVector)
    similarVector = [];
end
