function plotCoarsePeaksFound2(File_data)
    freqPlot = File_data.frequencies;
    xLength = numel(freqPlot);

    peaksFreq = [File_data.ComRes.position];
    peaksHeight = [File_data.ComRes.height];
    maxPeak = max(peaksHeight);
    rmsPeaks = rms(peaksHeight);
    rmsPeaksZoom = rmsPeaks/maxPeak;
    stdPeaks = rmsPeaks + std(peaksHeight);
    stdPeaksZoom = stdPeaks/maxPeak;

    peasksPromin = [File_data.ComRes.prominence];
    rmsProminence = rms(peasksPromin);
    peasksProminNormal = peasksPromin/max(peasksPromin);

    coefPlot = File_data.coefficients;
    coefPlot = coefPlot/max(coefPlot);
    rmsCoeff = rms(coefPlot);
    rmsCoeffZoom = rmsCoeff/maxPeak;

    coefZoom = coefPlot;
    coefZoom(coefPlot > maxPeak) = rmsCoeff;
    coefZoom = coefZoom/maxPeak;

    figure('Color', 'w');
    hold on;

    plot(freqPlot, coefZoom, 'c');
    plot([freqPlot(1) freqPlot(xLength)], [rmsCoeffZoom rmsCoeffZoom], '*:c');
    plot([freqPlot(1) freqPlot(xLength)], [rmsPeaksZoom rmsPeaksZoom], '*--c');
    plot([freqPlot(1) freqPlot(xLength)], [stdPeaksZoom stdPeaksZoom], '--c');

    plot(freqPlot, coefPlot, 'b');
    plot([freqPlot(1) freqPlot(xLength)], [rmsCoeff rmsCoeff], '*:b');

    stem(peaksFreq, peasksPromin, '.', 'Color', [0.85 0.15 0.0]);
    plot([freqPlot(1) freqPlot(xLength)], [rmsProminence rmsProminence]*1.00, '*:', 'Color', [0.85 0.15 0.0]);

    %stem([File_data.result.position], [File_data.result.height], 'ro');
    stem([File_data.result.position], [File_data.result.height]/maxPeak, 'ro');

    title('Scalogram');
    xlabel('Frequency, Hz');
    legend('sclZoom','rmsScZoom','rmsPkZoom','stdPkZoom','sclogram','rmsScl','promin','rmsPromin','validPk');
    hold off;
end