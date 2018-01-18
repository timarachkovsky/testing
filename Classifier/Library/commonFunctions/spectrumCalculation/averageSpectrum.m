function [ Result ] = averageSpectrum( File, Config )
% AVERAGESPECTRUM function cuts original signal to the several frames and
% builds direct and envelope spectrums of the frames with further averaging

% Developer : ASLM
% Date      : 12/12/2016
% Version   : v1.0

%% ______________________ DEFAULT_PARAMETERS __________________________ %%
if nargin < 2
   Config = []; 
end
Result = [];

Config = fill_struct(Config,'secPerFrame', '10'); % Set the length of the frame
Config = fill_struct(Config,'logBaseValue','1e-6'); % [mkm/s]
Config = fill_struct(Config,'plotEnable','0');

signal = File.signal;
filteredSignal = File.filteredSignal';
Fs = File.Fs;
signalLength = length(signal);
dt = 1/Fs;

frameLength = floor(str2double(Config.secPerFrame)/dt);
framesNumber = floor(signalLength/frameLength);
dfFrame = Fs/frameLength;
f = 0:dfFrame:Fs-dfFrame;

%% ____________________ MAIN_CALCULATIONS _____________________________ %%

% Direct Spectrum Calculation
signal = signal(1:frameLength*framesNumber,1);
signalFrames = reshape(signal,[],framesNumber);
spectrumFrames = abs(fft(signalFrames))/frameLength;
spectrum = sum(spectrumFrames,2)/framesNumber;

% Envelope Spectrum Calculation
filteredSignal = filteredSignal(1:frameLength*framesNumber,1);
filteredSignalFrames = reshape(filteredSignal,[],framesNumber);
envelopeSignalFrames = abs(hilbert(filteredSignalFrames));
envelopeSpectrumFrames = abs(fft(envelopeSignalFrames))/frameLength;
envelopeSpectrum = sum(envelopeSpectrumFrames,2)/framesNumber;

% Logarithmic Spectrum Calculation
baseValue = str2double(Config.logBaseValue);
logEnvelopeSpectrum = 20*log10(envelopeSpectrum/baseValue);
logSpectrum = 20*log10(spectrum/baseValue);

% Fills result structure
Result.spectrum = spectrum;
Result.envelopeSpectrum = envelopeSpectrum;
Result.logSpectrum = logSpectrum; 
Result.logEnvelopeSpectrum = logEnvelopeSpectrum; 
Result.frequencies = f;

% Plot results
if (strcmp(Config.plotEnable,'1'))
    figure, plot(f,spectrum);
    title('Spectrum'); xlabel('Frequency, Hz'); ylabel('Amplitude, m/s^2');
    figure, plot(f,envelopeSpectrum);
    title('Envelope Spectrum'); xlabel('Frequency, Hz'); ylabel('Amplitude, m/s^2');
    
    figure, plot(f, logSpectrum);
    title('Log Spectrum'); xlabel('Frequency, Hz'); ylabel('Amplitude, dB');
    figure, plot(f, logEnvelopeSpectrum);
    title('Log Envelope Spectrum'); xlabel('Frequency, Hz'); ylabel('Amplitude, dB');
end

end

