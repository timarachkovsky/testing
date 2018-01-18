
%DIVEDEDCORRELOGRAM Summary of this function goes here
%   Detailed explanation goes here

% Function version : v1.0a
% Last change : 12.07.2016
% Developer : ASLM

function [ freqReal, corrCoefVectorFinal ] = dividedCorrelogram( file, config )
if nargin<2
   config = []; 
end

%% ______________________ Default Parameters __________________________ %%
   config = fill_struct(config, 'plotEnable','0');    % Plotting enable
   config = fill_struct(config, 'baseFrameCount','20');   % Frame count to
                                                        % calculate
                                                        % correlogram
   config = fill_struct(config, 'step','0.1');    % Frequency step
   config = fill_struct(config, 'range','10');    % Frequency range around
                                                % freqNominal to analize
   config = fill_struct(config, 'peakFactorThreshold', '2'); 
   
   config.plotEnable = str2num(config.plotEnable);
   config.baseFrameCount = str2num(config.baseFrameCount);
   config.step = str2num(config.step);
   config.range = str2num(config.range);
   config.peakFactorThreshold = str2num(config.peakFactorThreshold);
   
%% __________________________ MAIN_CALCULATIONS _______________________ %%
% Divide signal into the set of frames which consist of 50 baseFrames
freqNominal = file.freqNominal;
signalLength = length(file.signal);
signalFrameLength = config.baseFrameCount*((file.Fs/(freqNominal*(1-(config.range/100))))); % signal length corresponding baseFrameCount
if signalFrameLength > signalLength
    signalFrameLength = signalLength;
end
signalFrameCount = floor(signalLength/signalFrameLength);  % number of cut-off signals

startPos = int64(1:signalFrameLength:signalFrameLength*signalFrameCount);
endPos = int64(signalFrameLength:signalFrameLength:signalFrameLength*signalFrameCount+1);

% Calculate Correlogram function fot each signalFrame
fileNew.Fs = file.Fs;
for i=1:1:signalFrameCount
    fileNew.signal = [];
    fileNew.signal = file.signal(startPos(1,i):1:endPos(1,i),1);
    fileNew.freqNominal = file.freqNominal;
    [~, corrCoefVector(i,:)]= Correlogram(fileNew,config);
end

% Normolize corrCoefVector for each frame
maxVector = max(corrCoefVector,[],2);
corrCoefVector = bsxfun(@rdivide,corrCoefVector,maxVector);

% Multiply one by one corrCoefVectors to make peaks more strongly marked
corrCoefVectorFinal = ones(1,length(corrCoefVector(1,:)));
for i=1:1:signalFrameCount
    corrCoefVectorFinal = bsxfun(@times,corrCoefVectorFinal,corrCoefVector(i,:));
end

% Find max value of corrCoefVectorFinal as a possible realFrecuency
if config.range > 1
    [corrCoefMax,idx] = findpeaks(corrCoefVectorFinal,'NPeaks',5,'MinPeakProminence',rms(corrCoefVectorFinal));
else
    [corrCoefMax,idx] = max(corrCoefVectorFinal);
end

    dFreq = freqNominal*config.step/100;                                            
    NFreq = 2*config.range/100/(config.step/100) + 1;
%     freqNominal = config.freqNominal;
    freqVector = (freqNominal-dFreq*(NFreq-1)/2):dFreq:(freqNominal+dFreq*(NFreq-1)/2);

if ~isempty(corrCoefMax)
    
    % If there is more than 3 peaks, freq clarification is not valid; but
    % if there is only 2 close-standing peaks the max one must be selected
    if numel(idx) == 1
        freqReal = freqVector(idx);
    elseif numel(idx)>=2 && mean(diff(idx))<4
        [~,i] = max(corrCoefMax);
        idx = idx(i);
        freqReal = freqVector(idx);
    else
        freqReal = nan;
    end
    
    if (config.range > 1)
        peakFactor = corrCoefMax/rms(corrCoefVectorFinal);
        if (peakFactor < config.peakFactorThreshold)
           freqReal = nan;
        end
    end   
else
    freqReal = nan;
end
%% __________________________ PLOT_RESUTLs ____________________________ %%
    if config.plotEnable
        dt=1/file.Fs;
        tmax=dt*(signalLength-1);
        t=0:dt:tmax;

        figure;
        subplot(2,1,1)
        plot(t,file.signal,'r-');
        ylabel('Signal');
        legend('Record_1.wav');grid;zoom xon;

        subplot(2,1,2)
        plot(freqVector, corrCoefVectorFinal);
        ylabel('Correl Func Final');
        xlabel('Freq, Hz');
    end
                                                        
end

