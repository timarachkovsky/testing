function [ Result ] = octaveSpectrum( File, Config )
% OCTAVESPECTRUM function forms the set of low and high bound
% frequencies 

% Developer : ASLM
% Date      : 12/12/2016
% Version   : v1.0

%% _________________________ Default Paramenters ______________________ %%

if nargin < 2 
    Config = [];
end

Config = fill_struct(Config, 'lowFrequency','16'); % low frequency range margin
Config = fill_struct(Config, 'highFrequency','16000'); % high frequency range margin
Config = fill_struct(Config, 'filterMode','1/3 octave'); 
Config = fill_struct(Config, 'roundingEnable','1'); % Enable rounding to the nearest 2^i value

switch(Config.filterMode)
    case '1 octave'
        pointsPerOctave = 1;
    case '1/3 octave'
        pointsPerOctave = 3;
    case '1/6 octave'
        pointsPerOctave = 6;
    case '1/12 octave'
        pointsPerOctave = 12;
    otherwise
        pointsPerOctave = 1;
end
%%
signal = File.signal;
Fs = File.Fs;
signalLength = length(signal);
df = Fs/signalLength;

%% ________________________ MAIN_CALCULATIONS _________________________ %%

% Form frequencies array with several points per octave and recalculate it
% to the position format.
roundingEnable = str2double(Config.roundingEnable);
lowFrequency = str2double(Config.lowFrequency);
highFrequency = str2double(Config.highFrequency);
[frequencies] = quadraspace(lowFrequency,highFrequency,pointsPerOctave,roundingEnable,'pointsPerOctave');

positions = round(frequencies/df);
lowPosition = positions(1,1:end-1);
highPosition = positions(1,2:end);
centralFrequencies = frequencies(1,1:end-1) + diff(frequencies)/2;

frameLength = highPosition-lowPosition;
spectrumLinesNumber = length(highPosition);
spectrum = abs(fft(File.signal))/signalLength;

% Calculate the averaged level of each spectrum octave part
myOctaveSpectrum = zeros(1,spectrumLinesNumber);
for i = 1:1:spectrumLinesNumber
    myOctaveSpectrum(:,i) = sum(spectrum(lowPosition(1,i):highPosition(1,i),1))/frameLength(1,i);
end

Result.amplitude = myOctaveSpectrum;
Result.frequencies = centralFrequencies;

end

