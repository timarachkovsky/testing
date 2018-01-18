function [myFigure, myArea] = fillArea(myFigure, thresholds, yCustomLimits)
    
    if nargin < 2
        error('There are not enough input arguments!');
    elseif nargin < 3
        yCustomLimits = [];
    end
    
    if size(thresholds, 1) > size(thresholds, 2)
        % Flip the threshold column vector in a row vector
        thresholds = thresholds';
    end
    
    % Get axes data
    myAxes = myFigure.CurrentAxes;
    xLimits = xlim(myAxes);
    yLimits = ylim(myAxes);
    
    % Get custom y-axis limits
    if length(yCustomLimits) == 1
        yMinLimit = yCustomLimits;
        yMaxLimit = yLimits(2);
    elseif length(yCustomLimits) == 2
        yMinLimit = yCustomLimits(1);
        yMaxLimit = yCustomLimits(2);
    else
        yMinLimit = yLimits(1);
        yMaxLimit = yLimits(2);
    end
    
    if yMinLimit >= thresholds(1)
        % Calculate the minimum y-axis limit
        yMinLimit = thresholds(1) - 1 / (length(thresholds) + 1) * (thresholds(end) - thresholds(1));
    end
    
    if yMaxLimit <= thresholds(end)
        % Calculate the maximum y-axis limit
        yMaxLimit = thresholds(end) + 1 / (length(thresholds) + 1) * (thresholds(end) - thresholds(1));
    end
    
    boundaries = [thresholds, yMaxLimit];
    durations = [boundaries(1), diff(boundaries)];
    durationsMatrix = repmat(durations, length(xLimits), 1);
    
    % Set the color map for the figure
    colormap(myFigure, 'jet');
    
    % Fill areas
    hold on;
    myArea = area(xLimits, durationsMatrix, yMinLimit, ...
        'ShowBaseLine', 'off', 'LineStyle', 'none', 'FaceAlpha', 0.15);
    hold off;
    
    % Set y-axis limits
    if length(yCustomLimits) == 1
        ylim(myAxes, [yCustomLimits, yMaxLimit]);
    elseif length(yCustomLimits) == 2
        ylim(myAxes, yCustomLimits);
    else
        ylim(myAxes, [yMinLimit, yMaxLimit]);
    end
%     % Freeze the y-axis
%     ylim(myAxes, yLimits);
    
    if length(thresholds) == 3
        % Set fill colors for 4 areas
        myArea(1).FaceColor = [0 1 0];
        myArea(2).FaceColor = [1 1 0];
        myArea(3).FaceColor = [1 0.5 0];
        myArea(4).FaceColor = [1 0 0];
    elseif length(thresholds) == 2
        % Set fill colors for 3 areas
        myArea(1).FaceColor = [0 1 0];
        myArea(2).FaceColor = [1 1 0];
        myArea(3).FaceColor = [1 0 0];
    end
    
end

