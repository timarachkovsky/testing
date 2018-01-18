% CHECKIMAGES function ...
% 
% Developer:              P. Riabtsev
% Development date:       09-07-2017
% Modified by:            
% Modification date:      

function [status] = checkImages(dirPath, imagesTags, imageFormat)
    
    status = false;
    
    if ischar(imagesTags)
        imagesTags = {imagesTags};
    end
    
    % The table of supported images formats and their extensions
    formatExtTable = { ...
        'jpeg', 'jpg';
        };
    
    if exist(dirPath, 'dir')
        % Get files data
        dirData = dir(dirPath);
        dirIndex = [dirData.isdir];
        filesData = dirData(~dirIndex);
        filesNames = {filesData.name};
        
        % Get images data
        formatVector = formatExtTable( : , 1);
        extVector = formatExtTable( : , 2);
        formatIndex = strcmp(formatVector, imageFormat);
        imageExt = extVector{formatIndex};
        imageIndex = cellfun(@(fileName) contains(fileName, ['.', imageExt]), filesNames);
        imagesData = filesData(imageIndex);
        imagesNames = {imagesData.name};
        
        % Check images
        if ~isempty(imagesTags) && ~isempty(imagesNames)
            if length(imagesTags) <= length(imagesNames)
                checkImagesIndex = contains(imagesNames, imagesTags, 'IgnoreCase', true);
                if nnz(checkImagesIndex) == length(imagesTags)
                    checkImagesData = imagesData(checkImagesIndex);
                    if all(cellfun(@nnz, {checkImagesData.bytes}))
                        status = true;
                    end
                end
            end
        end
    end
end

