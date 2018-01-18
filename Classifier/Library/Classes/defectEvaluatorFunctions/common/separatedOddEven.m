% SEPARATEDODDENEV fucntion separated odd and even numbers
%
% Developer:              P. Riabtsev
% Development date:       07-11-2016
% Modified by:            
% Modification date:      

function [odd, even, oddNumber, evenNumber] = separatedOddEven(numbers)
    
    if nargin < 1
        numbers = [];
    end
    
    if ~isnumeric(numbers)
        numbers = NaN;
    end
    
    % Indices of odd numbers
    oddIndex = mod(numbers, 2) == 1;
    % Odd numbers
    odd = numbers(oddIndex);
    % The number of odd numbers
    oddNumber = nnz(odd);
    
    % Indices of even numbers
    evenIndex = mod(numbers, 2) == 0;
    % Even numbers
    even = numbers(evenIndex);
    % The number of even numbers
    evenNumber = nnz(even);
end