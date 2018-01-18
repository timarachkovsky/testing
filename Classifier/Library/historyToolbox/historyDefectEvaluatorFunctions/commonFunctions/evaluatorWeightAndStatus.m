%   Developer:      Kosmach
%   Date:              11.05.2017

% EVALUATORWEIGHTANDSTATUS function evaluate of vector states in aggregate with their 
% weights and return one of the most dangerous statuses
function [ status, commonWeight ] = evaluatorWeightAndStatus(statusThresholdAndTrend, weight)
    if nnz(statusThresholdAndTrend) ~= 0 && ~(sum(weight) == 0)
        [row, colum] = size(weight);
        if row < colum
            weight = weight';
        end
        % Critical 
        statusMatrix(1,:) = statusThresholdAndTrend == 1;
        % Dangerous
        statusMatrix(2,:) = statusThresholdAndTrend == 0.75;
        % Possibly dangerous 
        statusMatrix(3,:) = statusThresholdAndTrend == 0.5;
        % No dangerous 
        statusMatrix(4,:) = statusThresholdAndTrend == 0;

        % Sort with status trend
        sortVectorStatus = statusMatrix * weight;
        sortVectorStatus = sortVectorStatus(:,1);

        % Less 0.6 relatively max is "trash"
        % Used Cross validation with weight
        sortVectorStatus = validation(sortVectorStatus);
        sortVectorStatus(sortVectorStatus < max(sortVectorStatus)*0.6) = 0;
        
        if nnz(sortVectorStatus) == 1
            [pos, ~, commonWeight] = find(sortVectorStatus);
            status = statusThresholdAndTrend(logical(statusMatrix(pos,:)));
            status = status(1);
        else
            [pos, ~, commonWeight] = find(sortVectorStatus,1,'first');
            status = statusThresholdAndTrend(logical(statusMatrix(pos,:)));
            status = status(1);
        end
    else
        status = 0;
        commonWeight = 0; 
    end
end

% CROSSVALIDATION function validate statuses with crossing 
function sortVectorStatus = validation(sortVectorStatus)
%     tempSortVector(tempSortVector < max(tempSortVector)*0.6) = 0;
    sumDefect = sum(sortVectorStatus(1:3));
    sumNonDefect = sortVectorStatus(4);
    
    theshlod = 0.1;
    
    vectorCompare = bsxfun(@times, (sumNonDefect + theshlod) > sumDefect, ...
        (sumNonDefect - theshlod) < sumDefect);
    if nnz(vectorCompare) && ~(sumDefect == 0 && sumNonDefect > 0)
        sortVectorStatus(4) = 0;
    else
        if sumDefect > sumNonDefect
            sortVectorStatus(4) = 0;
        else
            sortVectorStatus(1:3) = 0;
        end
    end

end