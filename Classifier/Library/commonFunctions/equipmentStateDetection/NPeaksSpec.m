function [ Result ] = NPeaksSpec( File )

    peakTable = File.acceleration.envelopeSpectrum.peakTable;
    if isempty(peakTable)
        Result = 0;
    else
        Result = size(peakTable,1);
    end

end

