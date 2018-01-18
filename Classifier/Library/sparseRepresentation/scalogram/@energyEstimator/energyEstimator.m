classdef energyEstimator
    %energyEstimator calculate area uner some scalogram point (scalogram peak)
    %
    % Main idea is estimation of energy for some wavelet by scalogram hill
    %
    % 2016-11-22..29 - 1v0, Ratgor.
    
    properties (Access = private)
        
        % @scalogram include scales vector & frequency vector & config
        scalogram
        
        % @points is vector of scales for analysing
        % best to provide with heignt, width, prominence etc.
        % energy field will be added, output range [0..1]
        scalogramPoints
        
        % @config for point energy estimation
        config
        
        translations
        
        iLoger

    end % properties (Access = private)
    
    methods (Access = public)
        
        % Constructor method
        function [myEnergyEstimator] = energyEstimator( scalogram, scalogramPoints )
            myEnergyEstimator.scalogram = scalogram;
            myEnergyEstimator.scalogramPoints = scalogramPoints;
            
            myEnergyEstimator.config = scalogram.peakFinderConfig.energyEstimation;
            myEnergyEstimator.config.Attributes.plotVisible = scalogram.peakFinderConfig.Attributes.plotVisible;
            myEnergyEstimator.config.Attributes.plotTitle = scalogram.peakFinderConfig.Attributes.plotTitle;
            myEnergyEstimator.config.plots = scalogram.peakFinderConfig.plots;
            
            myEnergyEstimator.translations = scalogram.translations;
            myEnergyEstimator.iLoger = loger.getInstance;
        end

        % Getters / Setters ...
        function [myConfig] = getConfig(myEnergyEstimator)
            myConfig = myEnergyEstimator.config;
        end
        function [myEnergyEstimator] = setConfig(myEnergyEstimator, myConfig)
           myEnergyEstimator.config = myConfig; 
        end

        function [myScalogram] = getScalogram(myEnergyEstimator)
            myScalogram = myEnergyEstimator.scalogram;
        end
        function [myEnergyEstimator] = setScalogram(myEnergyEstimator, myScalogram)
           myEnergyEstimator.scalogram = myScalogram; 
        end
        
        function [myScalogramPoints] = getScalogramPoints(myEnergyEstimator)
            myScalogramPoints = myEnergyEstimator.scalogramPoints;
        end
        function [myEnergyEstimator] = setScalogramPoints(myEnergyEstimator, myScalogramPoints)
           myEnergyEstimator.scalogramPoints = myScalogramPoints; 
        end
        % ... Getters / Setters
       
        % GETSCALOGRAMPOINTENERGY function 
        % Calculate area under some point (peak by frequency) of scalogram
        function [scalogramPoints] = getScalogramPointsEnergy( myEnergyEstimator )
            
            % normalize each scale depending on wavelet resonance frequency
            myEnergyEstimator = normalizeScalogram( myEnergyEstimator );
            
            % detect parameters of scalogram areas over scales points 
            myEnergyEstimator = detectPointArea( myEnergyEstimator );
            
            % estimate & return points energy
            [scalogramPoints] = estimateEnergy( myEnergyEstimator );

        end
        
    end % methods (Access = public)
    
    methods (Static, Access = public)
        
        % ESTIMATESCALOGRAMPOINTSENERGY is static cell for GETSCALOGRAMPOINTSENERGY function 
        function [scalogramPoints, energyFigure] = estimateScalogramPointsEnergy( scalogram, scalogramPoints )
            
            % if "Copy values If Exist" enabled,
            % check & copy if energy estimation results have been estimated yet
            % if any value is empty - racalculate it
            if scalogram.peakFinderConfig.energyEstimation.Attributes.scalogramEnergyForceRecast == '0'
                
                scalogramPointsNumber = length(scalogramPoints);
                
                % check all energy and labels are already in the result
                if isfield(scalogramPoints, 'energy')...
                        && isfield(scalogramPoints, 'energyLabel')
                    % if result is not full, next step to recast
                    if nnz([scalogramPoints.energy]) == scalogramPointsNumber ...
                            && nnz(~cellfun('isempty',{scalogramPoints.energyLabel})) == scalogramPointsNumber
                        return
                    end
                end
                
                % check & copy energy and labels from valid peaks data
                if isfield(scalogram.validPeaks, 'energy')...
                        && isfield(scalogram.validPeaks, 'energyLabel')
                    for i = 1 : length(scalogramPoints)
                        copyIndex = find([scalogram.validPeaks.frequencies] == scalogramPoints(i).frequencies, 1);
                        if ~isempty(copyIndex)
                            scalogramPoints(i).energy = scalogram.validPeaks(copyIndex).energy;
                            scalogramPoints(i).energyLabel = scalogram.validPeaks(copyIndex).energyLabel;
                        end
                    end
                    % if result is not full, next step to recast
                    if nnz([scalogramPoints.energy]) == scalogramPointsNumber ...
                            && nnz(~cellfun('isempty',{scalogramPoints.energyLabel})) == scalogramPointsNumber
                        return
                    end
                end
                
                % check & copy energy and labels from all peaks data
                if isfield(scalogram.allPeaks, 'energy')...
                        && isfield(scalogram.allPeaks, 'energyLabel')
                    for i = 1 : length(scalogramPoints)
                        copyIndex = find([scalogram.allPeaks.frequencies] == scalogramPoints(i).frequencies, 1);
                        if ~isempty(copyIndex)
                            scalogramPoints(i).energy = scalogram.allPeaks(copyIndex).energy;
                            scalogramPoints(i).energyLabel = scalogram.allPeaks(copyIndex).energyLabel;
                        end
                    end
                    % if result is not full, next step to recast
                    if nnz([scalogramPoints.energy]) == scalogramPointsNumber ...
                            && nnz(~cellfun('isempty',{scalogramPoints.energyLabel})) == scalogramPointsNumber
                        return
                    end
                end
            end
                           
            % create an object
            myEnergyEstimator = energyEstimator( scalogram, scalogramPoints );
            
            % Calculate area under the points of scalogram
            scalogramPoints = getScalogramPointsEnergy(myEnergyEstimator);
            
            % Plot energy estimation results
            if myEnergyEstimator.config.Attributes.plotEnable == '1'
                energyFigure = plotEnergyEstimation(myEnergyEstimator);
            end
            
        end
        
        % ESTIMATESCALOGRAMPOINTSENERGY is static cell for GETSCALOGRAMPOINTSENERGY function 
        function [energyFigure, scalogramPoints] = plotScalogramPointsEnergy(scalogram, scalogramPoints)
            
            % create an object
            myEnergyEstimator = energyEstimator(scalogram, scalogramPoints);
            
            % plot results
            [energyFigure, myEnergyEstimator] = plotEnergyEstimation(myEnergyEstimator);
            
            % remove additional plot data
            scalogramPoints = getScalogramPoints(myEnergyEstimator);
       end    
    end % methods (Static, Access = public)
    
    methods (Access = private)

        % normalize each scale depending on wavelet resonance frequency
        function [myEnergyEstimator] = normalizeScalogram(myEnergyEstimator)
           
            scalogramCoeff = myEnergyEstimator.scalogram.coefficients;
            scalogramFreq = myEnergyEstimator.scalogram.frequencies;
            myEnergyEstimator.scalogram.coefficients = scalogramCoeff / 1.;
            
        end

        % detect parameters of scalogram areas over scales points 
        function [myEnergyEstimator] = detectPointArea(myEnergyEstimator)
           
            scalogramPoints = myEnergyEstimator.scalogramPoints;
            if ~(isfield(scalogramPoints, 'frequencies')... change to 'frequency'
            && isfield(scalogramPoints, 'height')...
            && isfield(scalogramPoints, 'width')...
            && isfield(scalogramPoints, 'prominence'))
                % shink out another way...
                printWarning(myEnergyEstimator.iLoger, 'not enough peak params for energy estimation');
            end;
        end

        % estimate points energy
        function [scalogramPoints] = estimateEnergy(myEnergyEstimator)
            
            % Prepare energy estimation
            scalogramCoeff = myEnergyEstimator.scalogram.coefficients;
            scalogramCoeff = scalogramCoeff./max(scalogramCoeff);
            scalogramFreq = myEnergyEstimator.scalogram.frequencies;
            scalogramEnergy = sum(scalogramCoeff);
            
            % Prepare assigning energy labels (default "High, Medium, Low, Insign")
            energyEstimationThresholds = str2num(myEnergyEstimator.config.Attributes.energyEstimationThresholds);
            energyEstimationLabels = strsplit(myEnergyEstimator.config.Attributes.energyEstimationLabels, ', ');

            % Apply selected hill base estimation method
            switch (myEnergyEstimator.config.Attributes.energyEstimationMethod)
                % Area from peak & L/R points width/2 (width estimates on half prominence heiht)
                % downto scalogram zero (full height peak hill)
                case 'fullHillHeight_halfPromWidth'
                    [leftCoeffIndex, rightCoeffIndex, hillBase] = energyEstimationBase_HPW(myEnergyEstimator);
                    % Recommenden energyEstimationThresholds withoul normalization
                    % ="0.15, 0.10, 0.05" withoul normalization
                    energyBase = zeros(size(hillBase));
                    
                % Area from peak & L/R points width (width estimates on half prominence heiht)
                % upto scalogram peak (only cap of peak hill)
                case 'capHillHeight_doubleHalfPromWidth'
                    [leftCoeffIndex, rightCoeffIndex, hillBase] = energyEstimationBase_DHPW(myEnergyEstimator);
                    % Recommenden energyEstimationThresholds withoul normalization
                    % ="0.10, 0.025, 0.005" withoul normalization
                    % ="0.15, 0.075, 0.01" ??
                    energyBase = hillBase;
                    
                % Area from peak L/R half upper valley heiht upto scalogram peak
                case 'capHillHeight_upperValleyWidth'
                    [leftCoeffIndex, rightCoeffIndex, hillBase] = energyEstimationBase_UVW(myEnergyEstimator);
                    energyBase = hillBase;

                % Area from peak L/R upper valley heiht downto scalogram zero
                case 'fullHillHeight_upperValleyWidth'
                    [leftCoeffIndex, rightCoeffIndex, hillBase] = energyEstimationBase_UVW(myEnergyEstimator);
                    energyBase = zeros(size(hillBase));

                % Area from peak L/R upper valley heiht downto scalogram zero
                case 'minScalHillHeight_upperValleyWidth'
                    [leftCoeffIndex, rightCoeffIndex, hillBase] = energyEstimationBase_UVW(myEnergyEstimator);
                    energyBase(1:length(hillBase)) = min(scalogramCoeff);

                otherwise
					error('Unknown peak energy base estimation method');
            end

            % Process each point separately
            scalogramPoints = [myEnergyEstimator.scalogramPoints];
            scalogramPointsNumber = length(scalogramPoints);
            for i = 1 : scalogramPointsNumber
                
                % Estimate energy
                pointEnergy = sum(scalogramCoeff(leftCoeffIndex(i) : rightCoeffIndex(i)) - energyBase(i));
                energyRatio = pointEnergy / scalogramEnergy;
                scalogramPoints(i).energy = energyRatio;
                
                % Assign energy labels
                if scalogramPoints(i).energy >= energyEstimationThresholds(1)
                    scalogramPoints(i).energyLabel = energyEstimationLabels{1};
                elseif scalogramPoints(i).energy >= energyEstimationThresholds(2)
                    scalogramPoints(i).energyLabel = energyEstimationLabels{2};
                elseif scalogramPoints(i).energy >= energyEstimationThresholds(3)
                    scalogramPoints(i).energyLabel = energyEstimationLabels{3};
                else
                    scalogramPoints(i).energyLabel = energyEstimationLabels{4};
                end        
                
                % Prepare plot energy estimation results
                if myEnergyEstimator.config.Attributes.plotEnable == '1'
                    scalogramPoints(i).PlotBHV = hillBase(i); % draw base of hill here
                    scalogramPoints(i).PlotBEV = energyBase(i); % draw area form this baseline
                    scalogramPoints(i).PlotBLI = leftCoeffIndex(i);
                    scalogramPoints(i).PlotBRI = rightCoeffIndex(i);
                    scalogramPoints(i).PlotBLF = scalogramFreq(leftCoeffIndex(i));
                    scalogramPoints(i).PlotBRF = scalogramFreq(rightCoeffIndex(i));
                end
            end % of for
            
        end % of estimate points energy function
        
        % Calculate scalogram hill base method #1 fullHillHeight_halfPromWidth
        function [leftCoeffIndex, rightCoeffIndex, hillBase] = energyEstimationBase_HPW(myEnergyEstimator)
            
            scalogramCoeff = myEnergyEstimator.scalogram.coefficients;
            scalogramCoeff = scalogramCoeff./max(scalogramCoeff);
            scalogramFreq = myEnergyEstimator.scalogram.frequencies;
            scalogramCoeffNumber = length(scalogramCoeff);
            
            scalogramPoints = [myEnergyEstimator.scalogramPoints];
            scalogramPointsNumber = length(scalogramPoints);

            pointFrequency = [myEnergyEstimator.scalogramPoints.frequencies];
            pointHeight = [myEnergyEstimator.scalogramPoints.height];
            pointProminence = [myEnergyEstimator.scalogramPoints.prominence];
            hillBase = pointHeight - pointProminence./2;
            
            for i = 1 : scalogramPointsNumber
                
                currentPeakIndex = find((scalogramFreq == pointFrequency(i)), 1);
                rightCoeffIndex(i) = currentPeakIndex;
                leftCoeffIndex(i) = currentPeakIndex;
                
                % Left peak hill side
                if currentPeakIndex > 1
                    for j = currentPeakIndex - 1 : -1 : 1
                        leftCoeffIndex(i) = j;
                        if (scalogramCoeff(j) < hillBase(i))
                            break;
                        end
                    end
                end
                
                % Right peak hill side
                if currentPeakIndex < scalogramCoeffNumber
                    for j = currentPeakIndex + 1 : +1 : scalogramCoeffNumber
                        rightCoeffIndex(i) = j;
                        if (scalogramCoeff(j) < hillBase(i))
                            break;
                        end
                    end
                end
            end
            
        end % of Calculate scalogram hill base method #1
        
        % Calculate scalogram hill base method #2 capHillHeight_doubleHalfPromWidth
        function [leftCoeffIndex, rightCoeffIndex, hillBase] = energyEstimationBase_DHPW(myEnergyEstimator)
            
            scalogramCoeff = myEnergyEstimator.scalogram.coefficients;
            scalogramCoeff = scalogramCoeff./max(scalogramCoeff);
            scalogramFreq = myEnergyEstimator.scalogram.frequencies;
            scalogramCoeffNumber = length(scalogramCoeff);
            
            scalogramPoints = [myEnergyEstimator.scalogramPoints];
            scalogramPointsNumber = length(scalogramPoints);

            pointFrequency = [myEnergyEstimator.scalogramPoints.frequencies];
            pointHeight = [myEnergyEstimator.scalogramPoints.height];
            pointWidth = [myEnergyEstimator.scalogramPoints.width];
            pointProminence = [myEnergyEstimator.scalogramPoints.prominence];
            hillBase = pointHeight - pointProminence;
            
            for i = 1 : scalogramPointsNumber
                
                currentPeakIndex = find((scalogramFreq == pointFrequency(i)), 1);
                rightCoeffIndex(i) = currentPeakIndex;
                leftCoeffIndex(i) = currentPeakIndex;
                
                % Left peak hill side
                if currentPeakIndex > 1
                    for j = currentPeakIndex - 1 : -1 : 1
                        if (scalogramFreq(j) < pointFrequency(i) - pointWidth(i))
                            break;
                        end
                        leftCoeffIndex(i) = j;
                    end
                end
                
                % Right peak hill side
                if currentPeakIndex < scalogramCoeffNumber
                    for j = currentPeakIndex + 1 : +1 : scalogramCoeffNumber
                        if (scalogramFreq(j) > pointFrequency(i) + pointWidth(i))
                            break;
                        end
                        rightCoeffIndex(i) = j;
                    end
                end
            end
            
        end % of Calculate scalogram hill base method #2
        
        % Calculate scalogram hill base method #3 capHillHeight_upperValleyWidth
        function [leftCoeffIndex, rightCoeffIndex, hillBase] = energyEstimationBase_UVW(myEnergyEstimator)
            
            % Main idea: use peak indexes on scalogram frequency vector
            % and compeare peak height values on that index points
            % Algorithm:
            % 1) Find index of current peak, sort peaks by frequency
            % and find frequencies of all peaks out of curr peak width
            % 2) Find index of nearest right scalogram point from 3 cases 
            % higher than current peak, neighbour peak, scalogram border
            % 3) Same for the nearest left scalogram point index
            % 4) Find index of local minimum in the left valley - part
            % of scalogram between current peak and left scalogram point 
            % 5) Same for the right valley local minimum index
            % 6) Select the most high of left and right local minimums
            % 7) Use it's height as peak base and left or right border
            % 8) Find right or left hill border pair on the same height
            
            scalogramCoeff = myEnergyEstimator.scalogram.coefficients;
            scalogramCoeff = scalogramCoeff./max(scalogramCoeff);
            scalogramFreq = myEnergyEstimator.scalogram.frequencies;

            scalogramCoeffNumber = length(scalogramCoeff);
            
            scalogramPoints = [myEnergyEstimator.scalogramPoints];
            scalogramPointsNumber = length(scalogramPoints);

            pointFrequency = [myEnergyEstimator.scalogramPoints.frequencies];
            pointHeight = [myEnergyEstimator.scalogramPoints.height];
            pointWidth = [myEnergyEstimator.scalogramPoints.width];
            pointProminence = [myEnergyEstimator.scalogramPoints.prominence];
            hillBase = pointHeight - pointProminence;
            
            for i = 1 : scalogramPointsNumber

                % indexes of current and nearest peaks
                currentPeakIndex = find((scalogramFreq == pointFrequency(i)), 1);
                sortedPointFrequency = sort(pointFrequency);
                rightPeakFrequency = sortedPointFrequency(find(sortedPointFrequency > pointFrequency(i)+pointWidth(i), 1, 'first'));           
                leftPeakFrequency = sortedPointFrequency(find(sortedPointFrequency < pointFrequency(i)-pointWidth(i), 1, 'last'));
                

                % fix right scalogram point is higher than current peak 
                % or more right than nearest right peak
                overCapPointsIndex = find(scalogramCoeff >= pointHeight(i));
                rightOvercapIndex = overCapPointsIndex(find((overCapPointsIndex > currentPeakIndex), 1));
                if isempty(rightOvercapIndex)
                    rightOvercapIndex = scalogramCoeffNumber;
                end
                if ~isempty(rightPeakFrequency)
                    rightPeakIndex = find((scalogramFreq == rightPeakFrequency), 1, 'first');
                    if (rightOvercapIndex > rightPeakIndex)
                    rightOvercapIndex = rightPeakIndex;
                    end
                end
                
                % fix left scalogram point is higher than current peak
                % or more left than nearest right peak
                overCapPointsIndex = fliplr(overCapPointsIndex);
                leftOvercapIndex = overCapPointsIndex(find((overCapPointsIndex < currentPeakIndex), 1));
                if isempty(leftOvercapIndex)
                    leftOvercapIndex = 1;
                end
                if ~isempty(leftPeakFrequency)
                    leftPeakIndex = find((scalogramFreq == leftPeakFrequency), 1, 'last');
                    if (leftOvercapIndex < leftPeakIndex)
                    leftOvercapIndex = leftPeakIndex;
                    end
                end
                
                % find left local minimum
                leftValleyIndexes = leftOvercapIndex:currentPeakIndex;
                [~, leftMinValleyIndex] = min(scalogramCoeff(leftValleyIndexes));
                leftMinValleyIndex = leftValleyIndexes(leftMinValleyIndex);
                
                % find right local minimum
                rightValleyIndexes = currentPeakIndex:rightOvercapIndex;
                [~, rightMinValleyIndex] = min(scalogramCoeff(rightValleyIndexes));
                rightMinValleyIndex = rightValleyIndexes(rightMinValleyIndex);

                % select upper local minimum
                % and find pair point at the equivalent level
                if(scalogramCoeff(leftMinValleyIndex) < scalogramCoeff(rightMinValleyIndex))
                    hillBase(i) = scalogramCoeff(rightMinValleyIndex);
                    leftValleyIndexes = leftMinValleyIndex:currentPeakIndex;
                    leftMinValleyIndex = leftValleyIndexes(find(...
                        scalogramCoeff(leftValleyIndexes) <= scalogramCoeff(rightMinValleyIndex), 1, 'last'));

                else
                    hillBase(i) = scalogramCoeff(leftMinValleyIndex);
                    rightValleyIndexes = currentPeakIndex:rightMinValleyIndex;
                    rightMinValleyIndex = rightValleyIndexes(find(...
                        scalogramCoeff(rightValleyIndexes) <= scalogramCoeff(leftMinValleyIndex), 1, 'first'));
                end
                
                %output
                leftCoeffIndex(i) = leftMinValleyIndex;
                rightCoeffIndex(i) = rightMinValleyIndex;
            end
            
        end % of Calculate scalogram hill base method #3
        
        % Draw Graphics for energyEstimator
        function [myFigure, myEnergyEstimator] = plotEnergyEstimation(myEnergyEstimator)
            
            % Get common parameters
            Translations = myEnergyEstimator.translations;
            plotVisible = myEnergyEstimator.config.Attributes.plotVisible;
            plotTitle = myEnergyEstimator.config.Attributes.plotTitle;
            sizeUnits = myEnergyEstimator.config.plots.sizeUnits;
            imageSize = str2num(myEnergyEstimator.config.plots.imageSize);
            fontSize = str2double(myEnergyEstimator.config.plots.fontSize);
            
            frequency = myEnergyEstimator.scalogram.frequencies;
            xLength = numel(frequency);
            
            scalocramCoeff = myEnergyEstimator.scalogram.coefficients;
            scalocramCoeff = scalocramCoeff / max(scalocramCoeff);
            rmsCoeff = rms(scalocramCoeff);
            
            peaksHeight = [myEnergyEstimator.scalogram.allPeaks.height];
            maxPeak = max(peaksHeight);
            rmsPeak = rms(peaksHeight);
            
            if ~isempty(myEnergyEstimator.scalogramPoints)
                validPeaksFreq = [myEnergyEstimator.scalogramPoints.frequencies];
                validPeaksHeight = [myEnergyEstimator.scalogramPoints.height];
            else
                validPeaksFreq = [];
                validPeaksHeight = [];
            end
            
            myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
            hold on;
            
            % Plot
            plot(frequency, scalocramCoeff, 'b');
            plot([frequency(1) frequency(xLength)], [rmsCoeff rmsCoeff], '--b');
            plot([frequency(1) frequency(xLength)], [rmsPeak rmsPeak], '--r');
            plot(validPeaksFreq, validPeaksHeight, 'ro');
            % Two basevalues is not allowd - it's matlab 2014a-2016b bug
            % So, drawing multiple stems, areas, bars - is uncomfortable. 
            % But, if basevalues is the same - all right.
            for i = 1 : length(myEnergyEstimator.scalogramPoints)
                if ~any(diff([myEnergyEstimator.scalogramPoints.PlotBEV]))
                    area(frequency(myEnergyEstimator.scalogramPoints(i).PlotBLI:myEnergyEstimator.scalogramPoints(i).PlotBRI),...
                        scalocramCoeff(myEnergyEstimator.scalogramPoints(i).PlotBLI:myEnergyEstimator.scalogramPoints(i).PlotBRI),...
                        'basevalue', myEnergyEstimator.scalogramPoints(i).PlotBEV, 'showbaseline', 'off', ...
                        'facecolor', [0 0.75 1], 'facealpha', 0.35, 'linestyle', '-');
                elseif (i == 1)
                    area(frequency(myEnergyEstimator.scalogramPoints(1).PlotBLI:myEnergyEstimator.scalogramPoints(1).PlotBRI),...
                        scalocramCoeff(myEnergyEstimator.scalogramPoints(1).PlotBLI:myEnergyEstimator.scalogramPoints(1).PlotBRI),...
                        'basevalue', myEnergyEstimator.scalogramPoints(1).PlotBEV, 'showbaseline', 'off', ...
                        'facecolor', [0 0.75 1], 'facealpha', 0.35, 'linestyle', '-');
                end
                PlotBLI = [myEnergyEstimator.scalogramPoints(i).PlotBLF myEnergyEstimator.scalogramPoints(i).PlotBRF];
                PlotBLH = [myEnergyEstimator.scalogramPoints(i).PlotBHV myEnergyEstimator.scalogramPoints(i).PlotBHV];
                plot(PlotBLI, PlotBLH, 'Color', 'r');
            end
            hold off;
            grid on;
            
            % Get axes data
            myAxes = myFigure.CurrentAxes;
            % Set axes font size
            myAxes.FontSize = fontSize;
            
            % Figure title
            switch (myEnergyEstimator.scalogram.signalType)
                case 'SWD'
                    if strcmp(plotTitle, 'on')
                        title(myAxes, [upperCase(Translations.scalogram.Attributes.name, 'first'), ' - ', ...
                            upperCase(Translations.swd.Attributes.name, 'all')]);
                    end
                case 'normalized'
                    if strcmp(plotTitle, 'on')
                        title(myAxes, [upperCase(Translations.scalogram.Attributes.name, 'first'), ' - ', ...
                            upperCase(Translations.normalized.Attributes.name, 'first')]);
                    end
            end
            % Figure labels
            xlabel(myAxes, [upperCase(Translations.frequency.Attributes.name, 'first'), ', ', ...
                upperCase(Translations.frequency.Attributes.value, 'first')]);
            ylabel(myAxes, upperCase(Translations.level.Attributes.name, 'first'));
            % Figure legend
            legend({'Scalogram', 'Scalogram RMS', 'Peaks RMS', 'Valid peak', 'Energy', 'Base'});
            
            % Set axes limits
            xLimits = xlim(myAxes);
            yLimits = ylim(myAxes);
            xlim(myAxes, [0 xLimits(2)]);
            ylim(myAxes, [0 yLimits(2)]);
            
% RTG debug this feature here and peaksFinder line 1151 %myFinder = setResult(myFinder, myResult);
%             % Delete additional peaks data, used for plotting
%             if myEnergyEstimator.config.Attributes.plotKeepAdditionalData == '0'
%                 myEnergyEstimator.scalogramPoints = rmfield(myEnergyEstimator.scalogramPoints,...
%                     {'PlotBHV', 'PlotBEV', 'PlotBLI', 'PlotBRI', 'PlotBLF', 'PlotBRF'});
%             end

        end % of plotEnergyEstimation function    
        
    end % of methods (Access = private)
        
end

