% FINDWITHDECREASINGRANGE function find most close frequency in frequencies vector 
%
% Input arguments:
% soughtValue - required freqiency 
% frequenciesVector - vector, that required frequency is searched
% magnitudesVector - vector of magnitude, appropriate to vectorFrequencies
%
% Output arguments:
% resultPositions - position of accurate frequency in frequenciesVector
%
% Developer:              Kosmach N.
% Development date:       20.10.2017
% Modified by:            
% Modification date:      

function resultPositions = findWithDecreasingRange(soughtValue, frequenciesVector, magnitudesVector)
    
    % To find distance
    vectorMin = abs(frequenciesVector - soughtValue);
    
    % To find minimun of distance
    [minimunValue, ~] = min(vectorMin);
    resultPositions = minimunValue == vectorMin;
    
    % To choose most right
    if nnz(resultPositions) ~= 1
        
        vectorResult = zeros(length(resultPositions), 1);
        [~, positionMax] = max(magnitudesVector(resultPositions));
        
        vectorResult(positionMax(1)) = 1;
        resultPositions = vectorResult;
    end
    
    resultPositions = logical(resultPositions);
end