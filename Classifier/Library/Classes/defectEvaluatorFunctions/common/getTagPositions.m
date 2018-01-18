% GETTAGPOSITIONS function finds specific tag position in the tagColumn
% from the validStruct of the schemeValidator and returns their position
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
function [positions, names, magnitudes, logProminence, weights, frequencies, validPositions] = getTagPositions(defectStruct, tagName)
    % Get all tags of peaks
    tagColumn = defectStruct.mainFrequencyTagNameValid;
    % Find positions of peaks corresponding to the tag name
    validPositions( : , 1) = cellfun(@(currentTag) isequal(currentTag, tagName), tagColumn);
    if isempty(validPositions)
        positions = [];
        names = [];
        magnitudes = [];
        logProminence = [];
        weights = [];
        frequencies = [];
        validPositions = [];
        return;
    else
        % Get positions of found peaks
        numColumn = defectStruct.mainFrequencyTagNumberValid;
        positions = numColumn(validPositions, 1);
        % Get names of found peaks
        nameColumn = defectStruct.mainFrequencyNameValid;
        names = nameColumn(validPositions, 1);
        % Get magnitudes of found peaks
        magnitudeColumn = defectStruct.mainMagnitudeValid;
        magnitudes = magnitudeColumn(validPositions, 1);
        % Get logarithmic prominence of found peaks
        logProminenceColumn = defectStruct.mainLogProminenceValid;
        logProminence = logProminenceColumn(validPositions, 1);
        % Get weights of found peaks
        weightColumn = defectStruct.mainWeightValid;
        weights = weightColumn(validPositions, 1);
        % Get frequencies of found peaks
        frequenciesColumn = defectStruct.mainFrequencyValid;
        frequencies = frequenciesColumn(validPositions, 1);
        validPositions =find(validPositions);
    end
end



