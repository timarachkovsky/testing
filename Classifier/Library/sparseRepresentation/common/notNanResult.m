function [ result ] = notNanResult( cellArray )
%NOTNANRESULT Summary of this function goes here
%   Detailed explanation goes here

% Reshape cellArray to 1-D cell array 'temp'
result = [];    % nonNan output array
temp = [];      % array for buffering
for i = 1:1:length(cellArray)
   if isempty(temp)
      temp = cellArray{i,1}; 
   else
      temp = [temp; cellArray{i,1}];
   end
end

% Save only elements with nonNan frequency field
j = 0; % result array counter
for i=1:1:length(temp)
    if ~isnan(temp{i,1}.frequency)
        j = j+1;
        result{j,1}=temp{i,1};
    end
end

end

