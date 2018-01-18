function  shaftFreqCorrect  = frequencyEstimationProcessing( file, config )

%% ________________________ Default Parameters_________________________ %%

freqNumber = length(file.shaftVector.freq);
file.signal = file.envelopeSpectrum;

 %% ________________________ Frequency estimation ______________________ %%

shaftVectorSmoothed = NaN(freqNumber,1);
shaftVectorPeakTable = NaN(freqNumber,1);
shaftVector = zeros(freqNumber,1);

for i=1:1:freqNumber
    file.frequencyNominal = file.shaftVector.freq(i);
    
    if str2num(config.frequencyEstimationSmoothed.Attributes.processingEnable)
        if str2num(config.frequencyEstimationSmoothed.rough.Attributes.processingEnable)
            parameters = []; 
            parameters = config.frequencyEstimationSmoothed.rough.Attributes;
    %         parameters = setfield(parameters, 'plotEnable', config.frequencyEstimationSmoothed.Attributes.plotEnable);
            parameters.common = config.frequencyEstimationSmoothed.Attributes;
            [shaftVectorSmoothed(i,1), frequencyProbabilities(i,1)]= frequencyEstimationSmoothed(file, parameters);
            file.frequencyNominal = shaftVectorSmoothed(i,1);
        end

        if str2num(config.frequencyEstimationSmoothed.accurate.Attributes.processingEnable) && ~frequencyProbabilities
            parameters = []; 
            parameters = config.frequencyEstimationSmoothed.accurate.Attributes;
    %         parameters = setfield(parameters, 'plotEnable', config.frequencyEstimationSmoothed.Attributes.plotEnable);
            parameters.common = config.frequencyEstimationSmoothed.Attributes;
            shaftVectorSmoothed(i,1) = frequencyEstimationSmoothed(file, parameters);
        end
    end
    
    if str2num(config.frequencyEstimationPeak.Attributes.processingEnable)
        if ~isempty(file.peakTable)
            shaftVectorPeakTable(i,1) = frequencyEstimationPeak(file.shaftVector.freq(i), file.peakTable(:,1));
            if ~isempty(shaftVectorSmoothed(i,1)) && ~isempty(shaftVectorPeakTable(i,1))...
                    && (abs(shaftVectorSmoothed(i,1)-shaftVectorPeakTable(i,1))/file.shaftVector.freq(i)>0.01)
                shaftVectorPeakTable = [];
                shaftVectorPeakTable = frequencyEstimationPeak(shaftVectorSmoothed, file.peakTable(:,1));
            end
        end
    end
end

% result validation
for i = 1:1:freqNumber
    if ~isnan(shaftVectorPeakTable(i,1))
        shaftVector(i,1) = shaftVectorPeakTable(i,1);
    elseif ~isnan(shaftVectorSmoothed(i,1))
        shaftVector(i,1) = shaftVectorSmoothed(i,1);
    else 
        shaftVector(i,1) = 0;
    end
end

  % Fill shaftFreqTable with coeffs --> fullCorrespondenceTable
  fullCorrespondenceTable  = createFullCorrespondenceTable(file);
  
  % Recalculate shaft freq vector by multiplying it with  
  % fullCorrespondenceTable and dividing by the number of nonzeros elements
  % in shaftVector (averaging)
  if nnz(shaftVector)
      shaftFreqCorrect = shaftVector'*fullCorrespondenceTable.matrix/nnz(shaftVector);
  else
      shaftFreqCorrect = file.shaftVector.freq;
  end

end