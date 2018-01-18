% ENERGYPEAKFINDER function finds energy bumps in the logarithmic noise
% level of the logarithmic spectrum
% 
% Developer:              P. Riabtsev
% Development date:       23-10-2017
% 
% Modified by:            
% Modification date:      
function [energyAmplitudes, energyFrequencies, energyPositions, energyProminences, energyWidths, energyBands] = ...
    energyPeakFinder(logSpectrum, logNoiseLevelVector, frequencies, Config)
    
    % Get enrgy peak parameters
    minProminence = str2double(Config.minEnergyPeakProminence);
    maxWidthFactor = str2double(Config.maxEnergyPeakWidthFactor);
    maxWidth = str2double(Config.frameLength) * maxWidthFactor;
    
    % Find peak amplitudes and positions
    [peakAmplitudes, peakPositions] = findpeaks(logNoiseLevelVector);
    
    if isempty(peakPositions)
        % There are no energy peaks
        energyAmplitudes = [];
        energyPositions = [];
        energyFrequencies = [];
        energyProminences = [];
        energyWidths = [];
        energyBands = [];
        return;
    end
    
    peakFrequencies = frequencies(peakPositions);
    
    localMinAmplitudes = zeros(length(peakPositions) + 1, 1);
    localMinPositions = zeros(length(peakPositions) + 1, 1);
    % Find first local minimum
    [firstMinAmplitude, firstMinPosition] = min(logNoiseLevelVector(1 : peakPositions(1)));
    localMinAmplitudes(1) = firstMinAmplitude;
    localMinPositions(1) = firstMinPosition;
    % Find local minima
    for peakNumber = 1 : 1 : length(peakPositions) - 1
        
        [minAmplitude, minPosition] = min(logNoiseLevelVector(peakPositions(peakNumber) : peakPositions(peakNumber + 1)));
        localMinAmplitudes(peakNumber + 1) = minAmplitude;
        localMinPositions(peakNumber + 1) = peakPositions(peakNumber) + minPosition - 1;
    end
    % Find last local minimum
    [lastMinAmplitude, lastMinPosition] = min(logNoiseLevelVector(peakPositions(end) : end));
    localMinAmplitudes(end) = lastMinAmplitude;
    localMinPositions(end) = peakPositions(end) + lastMinPosition - 1;
    
    peakProminences = zeros(length(peakPositions), 1);
    peakBandPositions = zeros(length(peakPositions), 2);
    % Calculate peak prominences, bands and widths
    for peakNumber = 1 : 1 : length(peakPositions)
        
        if localMinAmplitudes(peakNumber) >= localMinAmplitudes(peakNumber + 1)
            % Calculate prominence level by left local minimum
            prominenceLevel = localMinAmplitudes(peakNumber);
        else
            % Calculate prominence level by right local minimum
            prominenceLevel = localMinAmplitudes(peakNumber + 1);
        end
        peakProminences(peakNumber) = peakAmplitudes(peakNumber) - prominenceLevel;
        
        halfProminenceLevel = prominenceLevel + peakProminences(peakNumber) / 2;
        halfProminenceValues = logNoiseLevelVector(localMinPositions(peakNumber) : localMinPositions(peakNumber + 1)) >= halfProminenceLevel;
        peakBandPositions(peakNumber, 1) = find(halfProminenceValues, 1, 'first') + localMinPositions(peakNumber) - 1;
        peakBandPositions(peakNumber, 2) = find(halfProminenceValues, 1, 'last') + localMinPositions(peakNumber) - 1;
    end
    peakBands = frequencies(peakBandPositions);
    peakWidths = diff(peakBands, 1, 2);
    
    % Find energy peaks
    maxWidthIndex = peakWidths < maxWidth;
    minProminenceIndex = peakProminences >= minProminence;
%     enoughProminenceIndex = peakProminences >= (minProminence * maxWidthFactor);
%     energyIndex = (maxWidthIndex & minProminenceIndex) | enoughProminenceIndex;
    energyIndex = (maxWidthIndex & minProminenceIndex);
    
    % Get energy peaks data
    energyAmplitudes = peakAmplitudes(energyIndex);
    energyPositions = peakPositions(energyIndex);
    energyFrequencies = peakFrequencies(energyIndex);
    energyProminences = peakProminences(energyIndex);
    energyWidths = peakWidths(energyIndex);
%     energyWidths(energyWidths > maxWidth) = maxWidth;
    energyBands = peakBands(energyIndex, : );
    
    % _______________________ Plot energy peaks ________________________ %
    if str2double(Config.plotEnable) && ~isempty(energyAmplitudes)
        
        % Get parameters
        plotVisible = Config.plotVisible;
        sizeUnits = Config.plots.sizeUnits;
        imageSize = str2num(Config.plots.imageSize);
        
        energyBandPositions = peakBandPositions(energyIndex, : );
        
        figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
        hold on;
        plot(frequencies, logSpectrum, ...
            'DisplayName', 'Log spectrum');
        plot(frequencies, logNoiseLevelVector, ...
            'DisplayName', 'Log noise level');
        stem(energyFrequencies, energyAmplitudes, ...
            'LineStyle', 'none', 'LineWidth', 1, ...
            'Marker', 'o', 'MarkerSize', 10, 'MarkerFaceColor', 'none', ...
            'DisplayName', 'Energy peaks');
        myBandsPlot = plot(energyBands', logNoiseLevelVector(energyBandPositions)', ...
            'LineStyle', '--', 'LineWidth', 1, 'Color', [0.2 0.2 0.2], ...
            'DisplayName', 'Energy bands');
        hold off;
        grid on;
        % Turn off energy band annotations
        for plotNumber = 2 : 1 : length(myBandsPlot)
            myBandsPlot(plotNumber).Annotation.LegendInformation.IconDisplayStyle = 'off';
        end
        % Figure title, labels, legend
        title('Energy peaks');
        xlabel('Frequency, Hz');
        ylabel('Amplitude, dB');
        legend('show', 'Location', 'northwest');
        % Add descriptions to markers
        markersTextContent = arrayfun(@(frequency, width, prominence) ...
            {['Freq: ', num2str(frequency), ' Hz'], ['Width: ', num2str(width), ' Hz'], ['Prom: ', num2str(prominence), ' dB']}, ...
            energyFrequencies, energyWidths, energyProminences, ...
            'UniformOutput', false);
        if size(markersTextContent, 1) == 1
            markersTextContent = markersTextContent{1};
        end
        text(energyFrequencies, energyAmplitudes, markersTextContent, ...
            'EdgeColor', [0.8 0.8 0.8], 'BackgroundColor', [1 1 0.9], 'Margin', 1, 'LineWidth', 1, ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
        % Add description to the figure
        % Get the limits of axis
        xLimits = xlim;
        yLimits = ylim;
        % The bottom left point of the figure for the text
        % Calculate the position of the current text on x-axis
        xTextPosition = 0.020 * abs(diff(xLimits)) + xLimits(1);
        % Calculate the position of the current text on y-axis
        yTextPosition = 0.025 * abs(diff(yLimits)) + yLimits(1);
%         textContent = {
%             ['Frame = ', Config.frameLength, ' Hz'], ...
%             ['Step = ', Config.stepLength, ' Hz'], ...
%             ['Min peak prominence = ', num2str(minProminence), ' dB'], ...
%             ['Enough peak prominence = ', num2str(minProminence * maxWidthFactor), ' dB'], ...
%             ['Max peak width = ', num2str(maxWidth), ' Hz'], ...
%             };
        textContent = {
            ['Frame = ', Config.frameLength, ' Hz'], ...
            ['Step = ', Config.stepLength, ' Hz'], ...
            ['Min peak prominence = ', num2str(minProminence), ' dB'], ...
            ['Max peak width = ', num2str(maxWidth), ' Hz'], ...
            };
        text(xTextPosition, yTextPosition, textContent, ...
            'FontSize', 10, 'Interpreter', 'none', ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
            'BackgroundColor', 'w', 'EdgeColor', 'k');
        
        % Close figure with visibility off
        if strcmpi(plotVisible, 'off')
            close
        end
    end
    
end

