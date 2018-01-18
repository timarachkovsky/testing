%FREQUENCYVALIDATION Summary of this function goes here
%   Detailed explanation goes here

function [ freqEstimationAccurate ] = frequencyEstimationPeak( frequency, baseFreqVector, config )

if nargin < 3
   config = [];
end

%% ____________________ Default Parameters ____________________________ %%

config = fill_struct(config, 'plotEnable','1');
config = fill_struct(config, 'freqHarmonicsNumber','4');
config = fill_struct(config, 'percentRange','5');

config.plotEnable = str2num(config.plotEnable);
config.freqHarmonicsNumber = str2num(config.freqHarmonicsNumber);
config.percentRange = str2num(config.percentRange);

%% _______________________ Calculations _______________________________ %%

% Calculate N freqs harmonics and find similar frequencies in baseFreqVector
baseVector = 1:1:config.freqHarmonicsNumber;
harmonicsVector = frequency*baseVector;
for i=1:1:length(harmonicsVector)
    similarFreqs{i,1} = getSimilarElements(harmonicsVector(1,i),baseFreqVector,config);
end
averageSimilarFreqs = cellfun(@mean,similarFreqs);
freqEstimationRough = mean(nonzeros(bsxfun(@rdivide,averageSimilarFreqs,baseVector')));
if isnan(freqEstimationRough) || isempty(nonzeros(averageSimilarFreqs(1:2,1)))
    freqEstimationAccurate = NaN;
    return;
end

similarFreqs = [];averageSimilarFreqs = [];
baseVector = 1:1:config.freqHarmonicsNumber;
harmonicsVector = freqEstimationRough*(1:1:config.freqHarmonicsNumber);
for i=1:1:length(harmonicsVector)
    config.freqRange = num2str(config.percentRange/100*freqEstimationRough);
    similarFreqs{i,1} = getSimilarElements(harmonicsVector(1,i),baseFreqVector,config);
end
averageSimilarFreqs = cellfun(@mean,similarFreqs);
freqEstimationAccurate = mean(nonzeros(bsxfun(@rdivide,averageSimilarFreqs,baseVector')));