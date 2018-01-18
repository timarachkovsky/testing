% STR2CELL function converts a string of words separated by a comma in cell
%
% DESCRIPTION
% The comma after the word can be added to the word
% Equivalent to 
%     defectFreqNames = strsplit(defectStruct.informativeTags.defective.Attributes.tagNames, {'\s*', ',', '\s*'}, ...
%         'DelimiterType', 'RegularExpression', 'CollapseDelimiters', true);
%     defectFreqNames = defectFreqNames(cellfun(@(x) ~isempty(x), defectFreqNames))';
%
% Developer:              P. Riabtsev
% Development date:       26-10-2016
% Modified by:            
% Modification date:      

function [outputCell] = str2cell(inputStr)  

    if nargin < 1
        return
    end
    
    % Number of converted words
    cellCnt = 0;
    
    commasPositions = strfind(inputStr, ',');
    
    if isempty(commasPositions)
        cellCnt = cellCnt + 1;
        currentStr = inputStr;
%         outputCell{cellCnt, 1} = [currentStr, ',']; % with a comma
        outputCell{cellCnt, 1} = currentStr; % without a comma
        return
    end
    
    % The word before the first comma
    if commasPositions(1) > 1
        cellCnt = cellCnt + 1;
%         currentStr = inputStr(1 : commasPositions(1)); % with a comma
        currentStr = inputStr(1 : commasPositions(1) - 1); % without a comma
        outputCell{cellCnt, 1} = currentStr;
    end
    
    % Words between commas
    if length(commasPositions) > 1
        for i = 1 : 1 : length(commasPositions) - 1
            cellCnt = cellCnt + 1;
%             currentStr = inputStr((commasPositions(i) + 1) : commasPositions(i + 1)); % with a comma
            currentStr = inputStr((commasPositions(i) + 1) : (commasPositions(i + 1) - 1)); % without a comma
            outputCell{cellCnt, 1} = currentStr;
        end
    end
    
    % The word after the last comma
    if commasPositions(end) < length(inputStr)
        cellCnt = cellCnt + 1;
        currentStr = inputStr((commasPositions(end) + 1) : length(inputStr));
%         outputCell{cellCnt, 1} = [currentStr, ',']; % with a comma
        outputCell{cellCnt, 1} = currentStr; % without a comma
    end
end

