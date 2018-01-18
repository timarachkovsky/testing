% GETTAGPOSITIONSHISTORY function finds specific tag position from 
% the validStruct and returns their position
% values vector
% 
% INPUT:
% 
% spectrumStruct - the structure which contains frequencies
% 
% tagName - the tag name to find peaks positions
% 
% OUTPUT:
% 
% positions - positions of peaks corresponding to the tag name
% 
% names - use in function getModulationEvaluationVector to create
% sidebands peaks names
% 
% magnitudes - magnitudes of peaks corresponding to the tag name
% 
% weights - weights of peaks corresponding to the tag name
%
% validPosition - all position having input tag
function [positions, names, magnitudes, weights, validPositions] = getTagPositionsHistory(defectStruct, tagName)
    
    if nnz(cellfun(@isempty, defectStruct.tagTable(:,1)))
        modFull = false;
    else
        % To get all tags of peaks
        tagColumn = cellfun(@(x) strsplit(x, '_'), defectStruct.tagTable(:,1), 'UniformOutput', false);
        tagColumn = cellfun(@(x) parsingTagsToNum(x), tagColumn, 'UniformOutput', false);
        % To find positions of peaks corresponding to the tag name
        validPositions(:, 1) = cellfun(@(currentTag) isequal(currentTag, tagName), tagColumn);
        if ~nnz(validPositions)
            modFull = false;
        else
            modFull = true;
        end
    end
    
    
    if ~modFull
        positions = [];
        names = [];
        magnitudes = [];
%         logProminence = [];
        weights = [];
        validPositions = false(length(defectStruct.tagTable(:,1)), 1);
        return;
    else
        % Get positions of found peaks
        positions = cellfun(@(x) findNumHarmonic(x), defectStruct.tagTable(validPositions,1));
        % Get names of found peaks
        names = defectStruct.nameTable(validPositions,1);
        % Get magnitudes of found peaks
        magnitudes = defectStruct.dataCompression(validPositions, 1);
%         % Get logarithmic prominence of found peaks
%         logProminenceColumn = defectStruct.mainLogProminenceValid;
%         logProminence = logProminenceColumn(validPositions, 1);
        % Get weights of found peaks
        weights = str2num(defectStruct.defectiveWeights{1, 1})';
        weights = weights(validPositions);
    end
end

function value = parsingTagsToNum(str)
    
    if length(str) == 2
        posTag1 = strfind(str{1}, '*');
        posTag2 = strfind(str{2}, '*');
        
        value = [str2double(str{1}(posTag1+1 : end)) str2double(str{2}(posTag2+1 :end))];
    else
        posTag = strfind(str{1}, '*');
        
        value = str2double(str{1}(posTag+1 : end));
    end
end

function value = findNumHarmonic(str)
    endPos = strfind(str, '*');
    endPos = endPos(1);
    
    value = str2double(str(1 : endPos-1));
end