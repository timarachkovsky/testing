function plotPeaksFound2(File_data) %MySignal, myPeaksTable
% Draw Graphics for peakFinder
    params=File_data.parameters;
    freqPlot = File_data.frequencies; %frequencies are in signal and File_data. positions are in peak tables.
    xLength = numel(freqPlot);
    coefPlot = File_data.coefficients;
    coefPlot = coefPlot/max(coefPlot);
    rmsLevel = rms(coefPlot);
    myPeaksTable = File_data.ComRes;  %Plot all peaks info.
    %{
    Peaks = [myPeaksTable.height];
    maxPeak = max(Peaks);
    coefPlotZoom = coefPlot;
    coefPlotZoom(coefPlot > maxPeak) = rmsLevel;
    coefPlotZoom = coefPlotZoom/maxPeak;
    rmsLevelZoom = rmsLevel/maxPeak;

    figure('Color', 'w');
    hold on;

    plot([freqPlot(1) freqPlot(xLength)], [rmsLevel rmsLevel], ':k');
    plot([freqPlot(1) freqPlot(xLength)], [rmsLevelZoom rmsLevelZoom], '--k');
    plot(freqPlot, coefPlotZoom, 'c');
    %Valid peaks evaluation.
        %plot([myFinder.result.position], [myFinder.result.height]/maxPeak,'ro');
        %{
        pos = [myPeaksTable.position];
        hei = [myPeaksTable.height]/maxPeak;
        plot(pos(myPeaksTable.validity), hei(myPeaksTable.validity),'ro');
        %}
    plot([File_data.result.position], [File_data.result.height]/maxPeak,'ro');

    stem([myPeaksTable.position], [myPeaksTable.validity],'.', 'Color', [0.0 0.85 0.15]); 
    stem([myPeaksTable.position], [myPeaksTable.prominence], '.', 'Color', [0.85 0.15 0.0]);
    plot(freqPlot, coefPlot, 'b');

    title('Scalogram');
    xlabel('Frequency, Hz');
    legend('rmsScl','rmsZoom','sclZoom','peaksFd','validity','prominen','sclOrig');
    hold off;
    %}
    peaksFreq = [myPeaksTable.position];
    peaksHeight = [myPeaksTable.height]*rmsLevel; %Because we normalized peaks to RMS.
    rmsProminence = rms([myPeaksTable.prominence]);
    maxPeak = max(peaksHeight);
    %Zoom is truncated and normalized to max peak scalogram.
    coefPlotZoom = coefPlot;
    coefPlotZoom(coefPlot > maxPeak) = rmsLevel;
    coefPlotZoom = coefPlotZoom/maxPeak;
    rmsLevelZoom = rmsLevel/maxPeak;

    validIndex = ~cellfun('isempty',strfind({myPeaksTable.label}, 'valid'));
    mbValidIndex = ~cellfun('isempty',strfind({myPeaksTable.label}, 'mbVal'));
    interestingIndex = ~cellfun('isempty',strfind({myPeaksTable.label}, 'mbInt'));

    figure('Color', 'w');
    hold on;

    plot([freqPlot(1) freqPlot(xLength)], [rmsLevel rmsLevel], ':k');
    plot([freqPlot(1) freqPlot(xLength)], [rmsLevelZoom rmsLevelZoom], ':k');
    heightThresholds = str2num(params.heightThresholds); 
    plot([freqPlot(1) freqPlot(xLength)], [rmsLevelZoom rmsLevelZoom]*heightThresholds(1), '--k');
    plot([freqPlot(1) freqPlot(xLength)], [rmsLevelZoom rmsLevelZoom]*heightThresholds(2), '--k');
    plot([freqPlot(1) freqPlot(xLength)], [rmsProminence rmsProminence], ':G');
    plot(freqPlot, coefPlotZoom, 'c');
    plot(peaksFreq(validIndex), peaksHeight(validIndex)/maxPeak,'ro');
    plot(peaksFreq(mbValidIndex), peaksHeight(mbValidIndex)/maxPeak,'yo');
    plot(peaksFreq(interestingIndex), peaksHeight(interestingIndex)/maxPeak,'mo');
    stem(peaksFreq, [myPeaksTable.validity],'.', 'Color', [0.0 0.85 0.15]); 
    stem(peaksFreq, [myPeaksTable.prominence], '.', 'Color', [0.85 0.15 0.0]);
	prominenceThresholds = str2num(params.prominenceThresholds);
	plot([freqPlot(1) freqPlot(xLength)], [prominenceThresholds(2) prominenceThresholds(2)], '--', 'Color', [0.85 0.15 0.0]);
	plot([freqPlot(1) freqPlot(xLength)], [prominenceThresholds(1) prominenceThresholds(1)], '--', 'Color', [0.85 0.15 0.0]);
	validityThresholds = params.validityThresholds; %str2num(params.validityThresholds);
    plot([freqPlot(1) freqPlot(xLength)], [validityThresholds(3) validityThresholds(3)], '--', 'Color', [0.0 0.85 0.15]); %max - valid threshold
	plot([freqPlot(1) freqPlot(xLength)], [validityThresholds(2) validityThresholds(2)], '--', 'Color', [0.0 0.85 0.15]);
	plot([freqPlot(1) freqPlot(xLength)], [validityThresholds(1) validityThresholds(1)], '--', 'Color', [0.0 0.85 0.15]); %Min - mbInt.
    plot(freqPlot, coefPlot, 'b');

    title('Scalogram');
    xlabel('Frequency, Hz');
   % legend('rmsScl','rmsZoom','sclZoom','validPk','mbValPk','mbIntPk','validity','prominen','sclOrig');
    hold off;
end