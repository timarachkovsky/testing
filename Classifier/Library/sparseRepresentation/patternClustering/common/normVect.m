function [ normalized_vector ] = normVect( vector , mode )
% Normalize values of an array to be between -1 and 1
% original sign of the array values is maintained.

if nargin < 2
   mode = 'max'; 
end

switch(mode)
    case 'max'
        if abs(min(vector)) > max(vector)
            max_range_value = abs(min(vector));
            min_range_value = min(vector);
        else
            max_range_value = max(vector);
            min_range_value = -max(vector);
        end
        normalized_vector = 2 .* vector ./ (max_range_value - min_range_value);
        
     case 'sum'
        normalized_vector = vector/sum(vector);
end