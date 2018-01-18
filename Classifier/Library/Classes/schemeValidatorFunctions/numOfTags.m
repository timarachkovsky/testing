
% Version : v1_0
% Developer: ASLM
% Date: 22.08.2016

function [ number, positions ] = numOfTags( tagColumn, currentRow )

% if nargin <3
%    comparisonMode = 'isequal'; 
% end
currentTag = tagColumn(currentRow, 1);

% Checking for empty positions to work only with non-empty
pos = find(~cellfun(@isempty, tagColumn(:, 1)));
if isempty(pos)
   number = 0;
   positions = [];
   return;
end

% Find all similar elements in the tagColumn and return its number
currentTagVector = repmat(currentTag, size(tagColumn(pos, 1)));
% number = nnz(~cellfun(@isempty,cellfun(@find,...
%     cellfun(@ismember,tagColumn(pos,1),currentTagVector,'UniformOutput',0),'UniformOutput',0)));

% if strcmp(comparisonMode,'ismember') 
%     similarCells = cellfun(@isequal, tagColumn(pos,1), currentTagVector, 'UniformOutput', false);
%     currentTagVector = repmat({currentTag{1}(1)},size(tagColumn(pos,1)));
%     mainTag = cellfun(@isequal, tagColumn(pos, 1), currentTagVector, 'UniformOutput', false);
%     similarCells = cell2mat(mainTag) + cell2mat(similarCells);
% else
    similarCells = cellfun(@isequal, tagColumn(pos, 1), currentTagVector);
% end
positions = pos(similarCells, 1);
number = nnz(positions);

if isempty(number)
   number = 0; 
   positions = [];
end
