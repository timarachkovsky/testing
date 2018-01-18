clear all; clc; 
close all;
% startup;
tic
% Check parpool object, if it's empty or workers number less then 4, create
% new parpool
poolobj = gcp('nocreate');
if isempty(poolobj) || poolobj.NumWorkers<4
    parpool(4);
end

% [Y,Fs] = audioread('bmz_data2.wav'); % inner ring wear

[Y,Fs] = audioread('16.rawdata.wav');
% [Y,Fs] = audioread('data3.wav'); % inner ring wear
% [Y,Fs] = audioread('data8.wav'); % outer ring wear


%% |__________________________ Scalogram calculation ___________________ %%
file.Fs = Fs;
file.signal = Y(1:round(length(Y)/4),1);  % 30 sec length
% calculate the most energetic frequencies of the signal
config.sideFreqCount = 1;
config.plotEnable = 1;
config.minFreqDistance = 5;
config.maxFreqCount = 20;   
config.logScaleEnable = 0;
config.freqStep = 200;
% config.varianceEnable = 0;
config.lowFreq = 100;
[maxCoef, freqMatrix] = maxCoefScalogram(file,config); 

%% ____________________________________________________________________ %%

% signal = Y(1:round(length(Y)/120),1);
signal = Y(1:round(length(Y)/15),1); % 8 second signal
% signal = Y(1:round(length(Y)),1);
dt = 1/Fs;
L = length(signal);
tmax = dt*L;
t = 0:dt:tmax-dt;
df=Fs/L;
f = 0:df:Fs-df;

%Build a basis of mexMorls signals
file.signal = signal;
L = length(freqMatrix(:,1));

fileTest(1,1) = file;
for i=1:1:L
    fileTest(i,1) = file;
end
for i=1:1:L
    fileTest(i,1).frequencies = freqMatrix(i,:);
end
% fileTest(1,1) = file;
% fileTest(1,1).frequencies = freqMatrix(3,:);

config.plotEnable = 1;
config.peaksPerFrame = 4;
config.patternCheckEnable = 0;
config.maxIteration = Fs;
parfor i=1:1:L
% for i=1:1:L
   result{i,1} = sparseProcessing( fileTest(i,1), config );
end
toc

validResult = notNanResult(result);
save('data.mat','validResult');



