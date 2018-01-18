function [ result ] = tagLocation( tagColumn, currentRow )
% TAGLOCATION function is evaluate position of tag of frequency, result is
% "start", "middle", "end"
 
% Inner arguments
numBefore = numOfTagsBeforeCurrent(tagColumn, currentRow);
numAfter = numOfTagsAfterCurrent(tagColumn, currentRow);

% Rules

% If there is only one tag in column OR there no tags before and some tags
% after --> set result to @start
if (numBefore == 0 && numAfter == 0) || (numBefore == 0 && numAfter > 0)
    result = 0;      
% If there are some tags before current and some tags after -->
% set result to @middle
elseif numBefore > 0 && numAfter > 0
    result = 1;
% If there are some tags before current one and there is no tags after 
% --> set result to @end
elseif numBefore > 0 && numAfter == 0
    result = 2;
% Otherwise, set result to @middle
else 
    result = 1;
end

