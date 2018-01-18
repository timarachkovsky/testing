function [ result ] = correlogram( file, config )

if nargin < 2
    config = [];
end

%% ___________________ Default Parameters _____________________________ %%
%    config = fill_struct(config, 'freqNominal',10);  % Nominal main signal
                                                    % frequency (1/period)
   config = fill_struct(config, 'percentStep','0.1');    % Frequency step
   config = fill_struct(config, 'percentRange','10');    % Frequency range around
                                                % freqNominal to analize
   config = fill_struct(config, 'envelopeEnable','1');  % Envelope enable
   config = fill_struct(config, 'plotEnable','0');    % Plotting enable

   percentStep = str2double(config.percentStep);
   percentRange = str2double(config.percentRange);
   envelopeEnable = str2double(config.envelopeEnable);
   plotEnable = str2double(config.plotEnable);
   
   %% ___________________ Main Calculations ___________________________ %%

signal = double(file.signal);
Fs = file.Fs;
nominalFrequency = single(file.frequencyNominal);

if envelopeEnable == 1
   signal = envelope(signal);   
end

frequencyStep = nominalFrequency*percentStep/100; 
nominalFrequenciesNumber = floor(percentRange/percentStep);
nominalFrequencies = single(linspace(-nominalFrequenciesNumber,nominalFrequenciesNumber,...
                                2*nominalFrequenciesNumber+1))*frequencyStep + nominalFrequency;

framesLength = floor(bsxfun(@ldivide,nominalFrequencies, Fs));                            
maxFrameLength = framesLength(end,1); 
framesNumber = floor(length(signal)/maxFrameLength);                            

frameCorr = zeros(2*nominalFrequenciesNumber+1,framesNumber-1);
parfor i = 1:1:2*nominalFrequenciesNumber+1
% for i = 1:1:2*nominalFrequenciesNumber+1
   [frameCorr(i,:)]  = frameCorrelogram(signal,framesLength(i),framesNumber);
end

correlogramVector = sum(frameCorr,2)/(framesNumber-1);

[~, maxPosition] = max(correlogramVector) ;
result.frequency = double(nominalFrequencies(1,maxPosition)); 
result.correlogram = double(correlogramVector);


end

function [result] = frameCorrelogram(signal,frameLength,framesNumber)
    
    signal = signal(1:framesNumber*frameLength,1);
    
    signalFrames = num2cell(reshape(signal,[],framesNumber)',2);
    result = zeros(framesNumber-1,1);
    for i = 1:1:framesNumber-1
        
        baseResult = abs(fastcorr(signalFrames{i,1},signalFrames{i,1}));
        baseFrames = repmat(signalFrames(i,1),framesNumber-i,1);
        totalResult = abs(cellfun(@fastcorr,baseFrames,signalFrames(i+1:end,1)));
        result(i,1) = sum(totalResult,1)/baseResult/(framesNumber-i);
    end
end
