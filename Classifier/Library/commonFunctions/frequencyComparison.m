function [ similarVector ] = frequencyComparison(element, frequencies, config)

    % Form element frequencies = [element, element, ...] and init similarity range
    elementVector = ones(size(frequencies)).*element;
    % Use percentRange by default
    if config.modeFunction
        delta = ((0.03*sqrt(element/config.coefficientModeFunction)))/element;
    else
        if ~config.freqRange
            delta = config.percentRange/100;
        else
            delta = config.freqRange/element;
        end
    end
    
    % Implement element-by-element comparison ans find frequencies elements
    % belonging to range [element-delta; element + delta];
    similarVector = find(bsxfun(@and,bsxfun(@lt,frequencies,elementVector*(1 + delta)),...
                                 bsxfun(@ge,frequencies,elementVector*(1 - delta))));
end

