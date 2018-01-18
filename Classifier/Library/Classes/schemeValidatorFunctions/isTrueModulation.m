function [ statusModulation ] = isTrueModulation( tagColumn,numColumn,nameColum,currentRow )
%ISTRUEMODULATION 

% Test gag ... 
%     currentRow = 1;
%     tagColumn = [{[1 5]}; {1}; {[1 5]}; {1}; {1}; {[1 5]}];
%     numColumn = [1; 1; 1; 2; 3; 3];
% ... test gag 
    
    % Checking for empty positions to work only with non-empty
    availabilityMod = any(~cellfun(@isempty, tagColumn(:,1)));
    if ~availabilityMod
        statusModulation = 0;
        return;
    end
    
    currentPositions = find(numColumn(:,:) == numColumn(currentRow, 1));
    currentTag = tagColumn(currentRow,1);
    
    % Modulation checking
    [isModulation, carrierTag, ~] = isModulationTag(currentTag);
    
    % Find carrier element in the tagColumn and return "yes/no"
    if isModulation 
        
        carrierTagVector = repmat(carrierTag, size(tagColumn(currentPositions, 1)));
        carrier = nnz(cellfun(@isequal, tagColumn(currentPositions, 1), carrierTagVector));
%         carrierPositions = currentPositions(find(cellfun(@nnz,carrierSimilarCells)),1);
%         carrier = nnz(~cellfun(@isempty,cellfun(@find,carrierSimilarCells,'UniformOutput', false)));

        % Find all similar modulation elements in the tagColumn and return their number
        modulationTagVector = repmat(currentTag, size(tagColumn(currentPositions, 1)));
        modulationSimilarCells = cellfun(@isequal,tagColumn(currentPositions,1), modulationTagVector);
        modulationPositions = currentPositions(modulationSimilarCells);
%         modulationNumber = nnz(~cellfun(@isempty,cellfun(@find,modulationSimilarCells,'UniformOutput',0)));
        sidebandNameForPeak = nameColum(modulationPositions)';

        statusModulation = getModulationEvaluation(carrier, sidebandNameForPeak);
    
    else 
        statusModulation = 0;
    end
    
end

