classdef trend
    % TREND class calculate slopes of approximation of inner signal, slopes
    % durations and signal approximation volatility and prepare the data
    % for printing images
    % 
    % Developer:              
    % Development date:       
    % Modified by:            P. Riabtsev
    % Modification date:      12-12-2016
    
    properties (Access = private)
        % INNER properties
        % Inner singal
        signal
        % Input struct with nessesary configuration
        config
        % Inner signal dates
        date
        
        % OUTER properties
        % The array with slopes of each monotone segment of approximation
        slopes
        % The array with durations of each monotone segment of
        % approximation
        durations
        % The value of signal volatility
        signalVolatility
        % The level of signal volatility relative to the value of signal
        % approximation volatility (low / high)
        relativeVolatilityLevel
        % Structure for printing images
        imageStruct
    end
    
    methods (Access = public)
        % Constructor function
        function myTrend = trend(mySignal, config, myDate)
            if ~exist('config', 'var') || isempty(config)
                config = [];
            end
            config = fill_struct(config, 'plotEnable', '0');
            config = fill_struct(config, 'rmsAccuracyPrimary', '15');
            config = fill_struct(config, 'rmsAccuracySecondary', '25');
            config = fill_struct(config, 'slopesThreshold', '3');
            config = fill_struct(config, 'meanDuration', '4');
            config = fill_struct(config, 'segmentPeriod', '6');
            config = fill_struct(config, 'signalVolatilityThreshold', '30');
            config = fill_struct(config, 'approxVolatilityThreshold', '20');
            
            myTrend.signal = mySignal;
            myTrend.config = config;
            myTrend.date = myDate;
            
            [myTrend] = calculateTrendParameters(myTrend);
        end
        
        % Getters/Setters ...
        % Inner properties
        function [mySignal] = getSignal(myTrend)
            mySignal = myTrend.signal;
        end
        function [myTrend] = setSignal(myTrend, mySignal)
            myTrend.signal = mySignal;
        end
        
        function [myConfig] = getConfig(myTrend)
            myConfig = myTrend.config;
        end
        function [myTrend] = setConfig(myTrend, myConfig)
            myTrend.config = myConfig;
        end
        
        function [myDate] = getDate(myTrend)
            myDate = myTrend.date;
        end
        function [myTrend] = setDate(myTrend, myDate)
            myTrend.date = myDate;
        end
        
        % Outer properties
        function [mySlopes] = getSlopes(myTrend)
            mySlopes = myTrend.slopes;
        end
        function [myDurations] = getDurations(myTrend)
            myDurations = myTrend.durations;
        end
        function [mySignalVolatility] = getSignalVolatility(myTrend)
            mySignalVolatility = myTrend.signalVolatility;
        end
        function [myRelativeVolatilityLevel] = getRelativeVolatilityLevel(myTrend)
            myRelativeVolatilityLevel = myTrend.relativeVolatilityLevel;
        end
        function [myImageStruct] = getImageStruct(myTrend)
            myImageStruct = myTrend.imageStruct;
        end
        % ... Getters/Setters
    end
    
    methods (Access = private)
        % MTA-analysis toolbox for multi-class trend analisys
        [optimal_epoches, slopes, xyApprox] = mta_analysis(varargin)
        
        % CREATEFUZZYCONTAINER function creates a fuzzy container with
        % specific variablers and rules
        function [container] = createFuzzyContainer(myTrend)
            signalVolatilityThreshold = str2double(myTrend.config.signalVolatilityThreshold);
            approxVolatilityThreshold = str2double(myTrend.config.approxVolatilityThreshold);
            container = newfis('optipaper');
            
            % INPUT:
            % Init states @fullSignalVolatility variable
            container = addvar(container, 'input', 'fullSignalVolatility', [-0.75 100.75]);
            container = addmf(container, 'input', 1, 'low', 'gauss2mf', [0.25 0 0.25 signalVolatilityThreshold]);
            container = addmf(container, 'input', 1, 'high', 'gauss2mf', [0.25 (signalVolatilityThreshold + 1) 0.25 100]);
            
            % Init states @fullApproxVolatility variable
            container = addvar(container, 'input', 'fullApproxVolatility', [-0.75 100.75]);
            container = addmf(container, 'input', 2, 'low', 'gauss2mf', [0.25 0 0.25 approxVolatilityThreshold]);
            container = addmf(container, 'input', 2, 'high', 'gauss2mf', [0.25 (approxVolatilityThreshold + 1) 0.25 100]);
            
            % Init states @signalSegmentVolatility variable
            container = addvar(container, 'input', 'signalSegmentVolatility', [-1.75 100.75]);
            container = addmf(container, 'input', 3, 'low', 'gauss2mf', [0.25 0 0.25 signalVolatilityThreshold]);
            container = addmf(container, 'input', 3, 'high', 'gauss2mf', [0.25 (signalVolatilityThreshold + 1) 0.25 100]);
            container = addmf(container, 'input', 3, 'no', 'gaussmf', [0.25 -1]);
            
            % Init states @segmentApproxVolatility variable
            container = addvar(container, 'input', 'segmentApproxVolatility', [-1.75 100.75]);
            container = addmf(container, 'input', 4, 'low', 'gauss2mf', [0.25 0 0.25 approxVolatilityThreshold]);
            container = addmf(container, 'input', 4, 'high', 'gauss2mf', [0.25 (approxVolatilityThreshold + 1) 0.25 100]);
            container = addmf(container, 'input', 4, 'no', 'gaussmf', [0.25 -1]);
            
            % OUTPUT:
            % Init states @approxLevel variable
            container = addvar(container, 'output', 'approxLevel', [0.25 2.75]);
            container = addmf(container, 'output', 1, 'primary', 'gaussmf', [0.25 1]);
            container = addmf(container, 'output', 1, 'secondary', 'gaussmf', [0.25 2]);
            
            % Init states @relativeVolatilityLevel variable
            container = addvar(container, 'output', 'relativeVolatilityLevel', [-0.75 1.75]);
            container = addmf(container, 'output', 2, 'low', 'gaussmf', [0.25 0]);
            container = addmf(container, 'output', 2, 'high', 'gaussmf', [0.25 1]);
            
            % RULES:
            % fullSignalVolatility, fullApproxVolatility,
            % signalSegmentVolatility, segmentApproxVolatility,
            % approxLevel, signalVolatility and etc
            
            ruleList = [
                1  1  3  3  1  1  1  1;
                1  1  1  1  1  1  1  1;
                1  1  2  1  1  2  1  1;
                1  1  2  2  2  2  1  1;
                
                2  1  3  3  1  2  1  1;
                2  1  1  1  1  1  1  1;
                2  1  2  1  1  2  1  1;
                2  1  2  2  2  2  1  1;
                
                2  2  3  3  2  2  1  1;
                2  2  1  1  1  1  1  1;
                2  2  2  1  1  2  1  1;
                2  2  2  2  2  2  1  1;
                ];
            
            container = addrule(container, ruleList);
        end
        
        % CALCULATETRENDPARAMETERS function find several trends in the
        % current signal and calculate the main parameters: direction,
        % strength and duration
        function [myTrend] = calculateTrendParameters(myTrend)
            ySignal = getSignal(myTrend);
            
            if (length(ySignal) < 4)
                % Input data is not enough
                myTrend.slopes = [];
                myTrend.durations = 0;
                myTrend.signalVolatility = [];
                myTrend.relativeVolatilityLevel = [];
                return;
            end
            
            xSignal( : , 1) = linspace(1, length(ySignal), length(ySignal));
            
%             % Flip the signal and inner signal date
%             ySignal = ySignal(end : -1 : 1);
%             myTrend.date = {myTrend.date{end : -1 : 1}}';
            
            % Prepare an array to approximate
            xyArray( : , 1) = xSignal;
            xyArray( : , 2) = ySignal;
            % Primary signal approximation
            [myEndPoints, mySlopes, xyApprox] = mta_analysis(xyArray, str2double(myTrend.config.rmsAccuracyPrimary));
            % Calculate durations of slopes
            myDurations = diff(myEndPoints);
            % Calculate the volatility of the signal
            mySignalVolatility = myTrend.calculateVolatility(xyArray);
            % Calculate the volatility of the primary signal approximation
            myPrimaryApproxVolatility = myTrend.calculateVolatility(xyApprox, ySignal(1));
            
            % Count the number of samples in the signal segment
            segmentPeriod = str2double(myTrend.config.segmentPeriod);
            if (segmentPeriod > 0) && (segmentPeriod < length(ySignal))
                % Cut the signal
                segmentXyArray = xyArray(end - segmentPeriod + 1 : end, : );
                % Cut the signal approximation
                segmentXyApprox = xyApprox(end - segmentPeriod + 1 : end, : );
                % Calculate the volatility of the signal segment
                segmentVolatility = myTrend.calculateVolatility(segmentXyArray, ySignal(1));
                % Calculate the volatility of the signal segment approximation
                segmentApproxVolatility = myTrend.calculateVolatility(segmentXyApprox, ySignal(1));
            else
                % Doesn't evaluate the signal segment
                segmentVolatility = -0.01;
                segmentApproxVolatility = -0.01;
            end
            % Determine the need for the secondary approximation using
            % volatility
            fuzzyContainer = createFuzzyContainer(myTrend);
            inputArgs = [mySignalVolatility, myPrimaryApproxVolatility, segmentVolatility, segmentApproxVolatility];
            % Volatility ceiling
            inputArgs(inputArgs > 100) = 100;
            containerOutput = evalfis(inputArgs, fuzzyContainer);
            approxLevel = round(containerOutput(1));
            if round(containerOutput(2)) == 0
                myRelativeVolatilityLevel = 'low';
            else
                myRelativeVolatilityLevel = 'high';
            end
            
            % Use secondary approximation if number of slopes greater then
            % slopes threshold and mean duration less then duration
            % threshold
            slopesNumber = length(mySlopes);
            meanDuration = mean(myDurations);
            if (slopesNumber > str2double(myTrend.config.slopesThreshold)) && (meanDuration < str2double(myTrend.config.meanDuration))
                approxLevel = 2;
                myRelativeVolatilityLevel = 'high';
            end
            
            % Secondary signal approximation
            mySecondaryApproxVolatility = [];
            if approxLevel == 2
                % Approximate the signal
                [roughEndPoints, roughSlopes, roughXyApprox] = mta_analysis(xyArray, str2double(myTrend.config.rmsAccuracySecondary));
                % Rewrite parameters of signal approximation
                if ~isempty(roughSlopes)
                    myEndPoints = roughEndPoints;
                    mySlopes = roughSlopes;
                    xyApprox = roughXyApprox;
                    % Recalculate durations of slopes
                    myDurations = diff(roughEndPoints);
                    % Calculate the volatility of the secondary signal approximation
                    mySecondaryApproxVolatility = myTrend.calculateVolatility(xyApprox, ySignal(1));
                end
            end
            
            % Elimination of discontinuities in signal aproximation and
            % calculate slopes normalization values
            [correctXyApprox, slopesNormalizValues] = myTrend.checkDiscontinuities(xyApprox, myEndPoints);
            % Recalculate signal approximation slopes in percent
            mySlopes = mySlopes ./ slopesNormalizValues * 100;
            
            % Set current slopes, durations, volatility values to myTrend
            % object
            myTrend.slopes = mySlopes;
            myTrend.durations = myDurations;
            myTrend.signalVolatility = mySignalVolatility;
            myTrend.relativeVolatilityLevel = myRelativeVolatilityLevel;
            % Fill image structure of myTrend object
            myTrend.imageStruct.signal = xyArray;
            myTrend.imageStruct.date = myTrend.date;
            myTrend.imageStruct.approx = correctXyApprox;
            
            % Plots trends
            if str2double(myTrend.config.plotEnable)
                figure('Units', 'points', 'Position', [0, 0, 800, 600], 'Visible', 'on', 'Color', 'w');
                title('Trending');
                hold on;
                grid on;
                
                % Plot the signal
                plot(xSignal, ySignal, '-ob', 'LineWidth', 2, ...
                    'DisplayName', 'Signal');
                % Plot the signal approximation
                plot(xyApprox( : , 1), xyApprox( : , 2), '--k', 'LineWidth', 2, ...
                    'DisplayName', 'Signal approximation');
                % Display legend
                legend('show', 'Location', 'northwest');
                
                % Sign signal approximation slopes
                for slopeNumber = 1 : 1 : length(mySlopes)
                    xTextPosition = (myEndPoints(slopeNumber, 1) + myEndPoints(slopeNumber + 1, 1)) / 2;
                    
                    firstSlopePoint = find(xyApprox( : , 1) == myEndPoints(slopeNumber, 1), 1, 'last');
                    lastSlopePoint = find(xyApprox( : , 1) == myEndPoints(slopeNumber + 1, 1), 1, 'first');
                    yTextPosition = (xyApprox(firstSlopePoint, 2) + xyApprox(lastSlopePoint, 2)) / 2;
                    
                    text(xTextPosition, yTextPosition, ...
                        {[num2str(round(mySlopes(slopeNumber) * 1000) / 1000), '%'], '\fontsize{20}\downarrow'}, ...
                        'FontSize', 10, 'Color', [1 0.5 0], ...
                        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
                end
                
                % Get the limits of axis
                xLimits = xlim;
                yLimits = ylim;
                % The bottom left point of the figure for the text
                % Calculate the position of the current text on x-axis
                xTextPosition = 0.020 * abs(diff(xLimits)) + xLimits(1);
                % Calculate the position of the current text on y-axis
                yTextPosition = 0.025 * abs(diff(yLimits)) + yLimits(1);
                
                if isempty(mySecondaryApproxVolatility)
                    textContent = {
                        ['Signal approximation level: ', num2str(approxLevel)], ...
                        ['Relative volatility level: ', myRelativeVolatilityLevel], ...
                        ['Signal volatility = ', num2str(mySignalVolatility), '%'], ...
                        ['Primary approximation volatility = ', num2str(round(myPrimaryApproxVolatility)), '%']
                        };
                else
                    textContent = {
                        ['Signal approximation level: ', num2str(approxLevel)], ...
                        ['Relative volatility level: ', myRelativeVolatilityLevel], ...
                        ['Signal volatility = ', num2str(mySignalVolatility), '%'], ...
                        ['Primary approximation volatility = ', num2str(round(myPrimaryApproxVolatility)), '%'], ...
                        ['Secondary approximation volatility = ', num2str(round(mySecondaryApproxVolatility)), '%']
                        };
                end
                
                % Display signal approximation volatility
                text(xTextPosition, yTextPosition, textContent, ...
                    'FontSize', 10, 'Interpreter', 'none', ...
                    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
                    'BackgroundColor', 'w', 'EdgeColor', 'k');
                
                % Replace the x-axis values by the date
                xticks(xSignal);
                xticklabels(myTrend.date);
                xtickangle(90);
                
                hold off;
            end
        end
    end
    
    methods (Static)
        % CALCULATEVOLATILITY function calculate volatility of input array
        %                  _________________________________
        %                 /               n               
        %     sigma = \  / 1 / (n - 1) * sum{ (m - v[i])^2 }
        %              \/                i-1
        % where:
        %     sigma - volatility
        %     v[i] = (x[i+1] - x[i]) / nV - relative deviation
        %     nV - normalization value (if the value is not defined, nV is 
        %         equal to signal swing
        %     n = length(v) - the number of observations
        %                  n
        %     m = 1 / n * sum{ v[i] } - arithmetical mean
        %                 i-1
        %
        % Input arguments:
        % xyArray - m-by-2 matrix contain x-axis values in the first column
        %     and y-axis values in the second column
        function [volatility, deviations] = calculateVolatility(xyArray, normalizValue)
            if nargin < 2
%                 % Set the normalization value equal to signal swing
%                 normalizValue = max(xyArray( : , 2)) - min(xyArray( : , 2));
                % Set the normalization value equal to absolute first value
                normalizValue = abs(xyArray(1, 2));
            end
            
            % Calculate the durations between samples
            durations = diff(xyArray( : , 1));
            % Set minimum durations if it is equal to zero
            durations(durations == 0) = 1;
            % Calculate deviations
            yArrayPrev = xyArray(1 : end - 1, 2);
            yArrayNext = xyArray(2 : end, 2);
            deviations = (yArrayNext - yArrayPrev) ./ normalizValue ./ durations;
            
            % Calculate volatility in percentage
            % Equivalent to:
            %     volatility = sqrt(1 / (length(deviations) - 1) * sum((mean(deviations) - deviations).^2)) * 100;
            volatility = std(deviations) * 100;
        end
        
        % ELEMENATEDISCONTINUITIES function replaces discontinuities in the
        % signal approximation on mean value of discontinuities endpoints
        % and calculate slopes normalization values
        function [correctXyApprox, slopesNormalizValues] = checkDiscontinuities(xyApprox, endPoints)
            % The values of the left endpoints of signal approximation for
            % the normilization of the slopes
            slopesNormalizPoints = endPoints(1 : end - 1);
            slopesNormalizValues = abs(xyApprox(slopesNormalizPoints, 2));
            % Positions of endpoint of discontinuities
            discontinPositions = find(diff(xyApprox( : , 1)) == 0);
            
            % Discontinuities do not exist
            if isempty(discontinPositions)
                correctXyApprox = xyApprox;
                return;
            end
            
            % Endpoints of discontinuities
            discontinValues( : , 1) = xyApprox(discontinPositions, 2);
            discontinValues( : , 2) = xyApprox(discontinPositions + 1, 2);
            % Junction points, that elemenate the discontinuities
            junctionPoints( : , 1) = xyApprox(discontinPositions, 1);
%             junctionPoints( : , 2) = mean(discontinValues, 2);
            junctionPoints( : , 2) = discontinValues( : , 2);
            % Remove the second points of discontinuities
            [correctXyApprox( : , 1), validPositions] = unique(xyApprox( : , 1));
            correctXyApprox( : , 2) = xyApprox(validPositions, 2);
            % Elimination of discontinuities
            correctXyApprox(junctionPoints( : , 1), 2) = junctionPoints( : , 2);
            
            % The values of the left endpoints of signal approximation for
            % the normilization of the slopes
            [~, correctNormalizPoints] = intersect(slopesNormalizPoints, junctionPoints( : , 1));
            slopesNormalizValues(correctNormalizPoints) = abs(discontinValues( : , 2));
        end
    end
end

