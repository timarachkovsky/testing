%   Developer:      Kosmach
%   Date:              11.05.2017

% EVALUATORTHRESHOLDTREND function evaluating trend and status of the threshold for each peak.
% Result of function is vector of status
function [statusThresholdAndTrend] = ...
            evaluatorThresholdTrend(trendPeaks, thresholdVector, initialPeaksNames, currentPeaks)
    
    % Mode with appeared peaks
    if nargin == 2
        mode = false;
    else
        mode = true;
    end

    if ~isempty(trendPeaks)
        container = newfis('optipaper');

        % INPUT:
        % Init 6-state @trend variable
        container = addvar(container,'input','trend',[-1.375 1.875]);
        container = addmf(container,'input',1,'declining','gaussmf',[0.125 -1]);
        container = addmf(container,'input',1,'mb_declining','gaussmf',[0.125 -0.5]);
        container = addmf(container,'input',1,'stable','gaussmf',[0.125 0]);
        container = addmf(container,'input',1,'mb_growing','gaussmf',[0.125 0.5]);
        container = addmf(container,'input',1,'growing','gaussmf',[0.125 1]);
        container = addmf(container,'input',1,'unknown','gaussmf',[0.125 1.5]);  

        % INPUT:
        % Init 4-state @energy variable
        container = addvar(container,'input','statusThreshold',[-0.125 1.125]);
        container = addmf(container,'input',2,'gree','trimf',[0.125 0.25 0.375]);
        container = addmf(container,'input',2,'orange','trimf',[0.375 0.625 0.875]);
        container = addmf(container,'input',2,'red','trimf',[0.875 1 1.125]);
        container = addmf(container,'input',2,'empty','trimf',[-0.125 0 0.125]);

        % OUTPUT:
        % Init 4-state @result variable
        container = addvar(container,'output','statusWeight',[-0.375 1.125]);
        container = addmf(container,'output',1,'possiblyDangerous','trimf',[0.375 0.5 0.625]);
        container = addmf(container,'output',1,'dangerous','trimf',[0.625 0.75 0.875]);
        container = addmf(container,'output',1,'critical','trimf',[0.875 1 1.125]);
        container = addmf(container,'output',1,'noDangerous','trimf',[-0.375 0 0.375]);

        % RULEs:
        ruleList = [ 0  3  3  1  1;
                     0  4  4  1  1;
        
                     1  1  1  1  1;
                     1  2  1  1  1; 

                     2  1  1  1  1;
                     2  2  2  1  1;

                     3  1  1  1  1;
                     3  2  2  1  1;

                     4  1  1  1  1;
                     4  2  2  1  1;

                     5  1  2  1  1;
                     5  2  3  1  1;

                     6  1  1  1  1;
                     6  2  1  1  1;
                   ];

        container = addrule(container, ruleList);

        % evaluated each peak with his trend and threshold status
        statusThresholdAndTrend = arrayfun(@(x) round(evalfis([trendPeaks(x,1), ...
            double(str2numStatus.(thresholdVector{x,1}))], container), 2), (1:length(trendPeaks)));
        
        % Mode with appeared peaks
        if mode
            statusApp = getAppearedPeaks(currentPeaks, initialPeaksNames);
            
            if ~isempty(statusApp)
                statusThresholdAndTrend(statusApp(statusThresholdAndTrend(statusApp) > 0)) = 0.75;
            end
        end
    else
        statusThresholdAndTrend = 0;
    end
end

