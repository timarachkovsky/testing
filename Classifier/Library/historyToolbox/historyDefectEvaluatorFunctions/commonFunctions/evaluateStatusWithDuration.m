% EVALUATESTATUSWITHDURATION function is find stable status of the history of
% thresholds

% vectorStatus - vector of status, the last file must be in the end

% Developer:    Kosmach N.
% Date:         23.03.2017
% Modified:     Kosmach N.
% Date:         20.06.2017

function [ status ] = evaluateStatusWithDuration(vectorStatus, myFiles)

    stablePeriodStatus = str2double(myFiles.files.history.Attributes.stablePeriodStatus);
    if ~strcmp(vectorStatus(end), 'NaN')
        % Crop training period of peaks
        lengthVectorStatus = length(vectorStatus);
        if ~(nnz(cellfun(@isempty, vectorStatus)) == lengthVectorStatus)
            nonEmptyPos = find(cellfun(@isempty, vectorStatus), 1, 'last');
            if ~isempty(nonEmptyPos) 
                vectorStatus = vectorStatus(nonEmptyPos+1:end);
            end
            nonNanPos = find(strcmp(vectorStatus, 'NaN'), 1, 'first');
            if ~isempty(nonNanPos) 
                vectorStatus = vectorStatus(nonNanPos+1:end);
            end
        end

        % Evaluate threshold status of peak
        posLastNonCrunet = find(~cellfun(@(x)  ...
            strcmp(x,vectorStatus(end)), vectorStatus), 1, 'last');
        if ~isempty(posLastNonCrunet)
            numberCurrentStatus =  length(vectorStatus) - posLastNonCrunet;
            if numberCurrentStatus >= stablePeriodStatus
                status = vectorStatus(end);
            else
                % If percent current status more requirement, status =
                % current, else status = previous
                if nnz(cellfun(@(x) strcmp(x,vectorStatus(end)), ...
                        vectorStatus))/length(vectorStatus) >= str2double(myFiles.files.history.Attributes.percentStatusOfHistory)
                    status = vectorStatus(end);
                else
%                     status = vectorStatus(posLastNonCrunet);
                    % If current status does not fit find the previous 
                    % STABLE status
                    status = evaluateStatusWithDuration(vectorStatus(1:posLastNonCrunet), myFiles);
                end
            end
        else
            
            if length(vectorStatus) >= stablePeriodStatus
                status = vectorStatus(end);
            else
                status{1,1} = [];
            end
        end
    else
        status{1,1} = '';
    end
    if isempty(status{1,1})
        status = {'NaN'};
    end
end

