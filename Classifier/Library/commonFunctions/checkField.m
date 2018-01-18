% CHECKFIELD function checks the existence of the field in the structure
% 'Struct'. The field is specified in the variable 'varargin'.
% 
% 
% Developer:              P. Riabtsev
% Development date:       04-07-2017
% Modified by:            P. Riabtsev
% Modification date:      07-07-2017

function [status] = checkField(Struct, varargin)
    
    if nargin < 2
        status = [];
        return;
    end
    
    if ~isstruct(Struct)
        status = [];
        return;
    end
    
    singleFieldIndex = cellfun(@ischar, varargin);
    if ~all(singleFieldIndex)
        multipleFieldName = varargin{~singleFieldIndex};
        if ~iscellstr(multipleFieldName)
            status = [];
            return;
        end
    end
    
    status = findField(Struct, varargin{1, : });
end

function [status] = findField(Struct, varargin)
    
    if ischar(varargin{1, 1})
        % A single field
        fieldName = varargin(1, 1);
    else
        % A multiple field
        fieldName = varargin{1, 1};
    end
    
    if all(isfield(Struct, fieldName))
        for fieldNumber = 1 : 1 : length(fieldName)
            if length(varargin) > 1
                % Find next field
                if isstruct(Struct.(fieldName{1, fieldNumber}))
                    % The field has attachments
                    status = findField(Struct.(fieldName{1, fieldNumber}), varargin{1, 2 : end});
                    if ~status
                        % False status was found
                        break;
                    end
                else
                    % The field hasn't attachments
                    status = false;
                end
            else
                % The field exists
                status = true;
            end
        end
    else
        % At least one of the fields doesn't exist
        status = false;
    end
end

