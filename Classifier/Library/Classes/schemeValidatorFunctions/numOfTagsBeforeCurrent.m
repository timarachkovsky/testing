% Version : v1_0
% Developer: ASLM
% Date: 22.08.2016

function [ result ] = numOfTagsBeforeCurrent( tagColumn, currentRow )
% If standing on the first position OR there are no similar elemtants 
% in column before --> set result to 0;
% On the other hand set result to number of found elements
if currentRow == 1
    result = 0;
else

    currentTag = tagColumn(currentRow,1);
    % Checking for empty positions to work only with non-empty
    [pos,~] = find(~cellfun(@isempty,tagColumn(1:currentRow-1,1)));  
    if isempty(pos)
       result = 0;
       return;
    end
    % Checking similar tags in the tagColumn, every element of which may
    % have several formats (ex. {[i j]}, {[i]}, {[]}). If current tag
    % similar to some of them --> cnt+1
    currentTagVector = repmat(currentTag,size(tagColumn(pos,1)));  

    similarCells = cellfun(@isequal,tagColumn(pos,1),currentTagVector);

    result = nnz(similarCells);
%     if isempty(result)
%        result = 0; 
%     end
end




