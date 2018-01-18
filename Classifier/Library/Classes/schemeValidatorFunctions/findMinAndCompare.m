
% Version : v2_0
% Developer: ASLM
% Date: 22.08.2016

% Cangered Kosmach
% Date: 31.02.2017

function [ minValue, minValidity, distance] = findMinAndCompare(...
    numVector,maskVector,currentPos)
%% ________________________ Default Parameters ________________________ %%

% currentRow = numTable(rowNum,:);

%% _________________________ Calculations _______________________ %%

numVector(numVector(:,:)==0) = NaN;
[ minValue, minPosition ] = min(numVector([1:currentPos-1, currentPos+1:end]));
if isempty(minValue)
    minValue = 0;
    distance = 0;
    minValidity = 0;
    return;
end
minValidity = maskVector(minPosition);
currentValue = numVector(currentPos);
distance = currentValue-minValue;




