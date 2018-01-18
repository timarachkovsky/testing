% Developer:              Kosmach N.
% Development date:       04-11-2017
% Modified by:            
% Modification date:  

% VECTOR2STRSTANDARDRORMAT function transforms input vector to a string of 
% standard format
function standartFormat = vector2strStandardFormat(inputVector)

    if ~isempty(inputVector)
        % if inputVector is massives of cells
        if iscell(inputVector)
            if isnumeric(inputVector{1})
                standartFormat = regexprep(num2str(cell2mat(inputVector)), ' +', ',');
            else
                if length(inputVector) ~= 1
                    standartFormat = strjoin(inputVector, ',');
                else
                    standartFormat = inputVector{1};
                end
            end
        else
            % if inputVector is numeric
            if isnumeric(inputVector(1))
                if length(inputVector) ~= 1
                    standartFormat = regexprep(num2str(inputVector), ' +', ',');
                else
                    standartFormat = num2str(inputVector);
                end
            % if inputVector is string
            else
                if ischar(inputVector)
                    standartFormat = regexprep(inputVector,  ' +', ',');
                else
                    error('Incorrect input arguments');
                end
            end
        end
    else
        standartFormat = [];
    end
end

