% Creator:      Kosmach N.
% Date:           04.03.2017

% GETAPPEAREDPEAKS function is compares initial peaks and 
% currently peaks, result is numeric posiion of apperead peaks.
function statusAppeared = ...
    getAppearedPeaks(currentlyPeaks, initialPeaks)
    
    statusAppeared = [];

    if isempty(currentlyPeaks)
        processing = 0;
    else
        if all(cellfun(@isempty, currentlyPeaks)) 
            processing = 0;
        elseif isempty(initialPeaks)
            processing = 1;
        elseif nnz(contains(initialPeaks, 'NaN')) % NaN - training period will be
            processing = 0;
        else
            processing = 1;
        end
    end
    
    if processing
        if ~isempty(initialPeaks)
            initialPeaks = strsplit(initialPeaks);
        end
        currentlyPeaks = strtrim(currentlyPeaks);
        [~, statusAppeared] = setdiff(currentlyPeaks, initialPeaks);
    end
end

