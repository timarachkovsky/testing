% MODULATIONTAGSNUMBER function checks is there some neibour modulation
% components for current tag

%     currentRow = 4;
%     tagColumn = [{[1 5]}; {1}; {[1 5]}; {1}; {1}; {[1 5]}];
%     numColumn = [1; 1; 1; 2; 3; 3];
%     [ myNumber ] = modulationTagsNumber( tagColumn,numColumn,currentRow )
    
function [ myNumber ] = modulationTagsNumber( tagColumn, numColumn, currentRow )
    
    % Checking is there some nonempty tags in the column 
    [pos,~] = find(~cellfun(@isempty, tagColumn(:, 1)));
    if isempty(pos)
%         warning('There no enough tags to look for thier modulation tags!');
        myNumber = 0;
        return;
    end
    
    % Find tag positions with similar harmonic number 
    currentPositions = find(numColumn(:, :) == numColumn(currentRow, 1));
    
    % Check is there some neibour modulation components
%     myNumber = nnz(arrayfun(@isModulationTag,tagColumn(currentPositions)));
    posModulation = arrayfun(@isModulationTag , tagColumn(currentPositions));
    currentTag = tagColumn{currentRow};
    myNumber = nnz(cellfun(@(x) x(1) == currentTag(1), tagColumn(currentPositions(logical(posModulation))))); 
end

