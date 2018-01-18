function [status] = checkSameTag(tagPeakTable, currentTag)

    status = false(1);
    if ~isempty(currentTag)
        
        % If free peak or energy peak
        if tagPeakTable == 0 || tagPeakTable == 2
            status = true(1);
        else
            % if line frequency
            if length(currentTag) == 1
                % If lineFreq == shaft, it is OK
                if tagPeakTable == currentTag || (currentTag == 1 && tagPeakTable == 3)
                    status = true(1);
                end
            end    
        end
    end
end

