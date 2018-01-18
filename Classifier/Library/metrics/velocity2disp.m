% VELOCITY2DISP transforms velocity signal to dispaclement and calculates
% displacement rms value in the specific range (default frequency range is
% set by ISO)
function [ file, rmsDisplacement  ] = velocity2disp( file, config )

%% ____________________ Default parameters ____________________________ %%
if nargin < 2
   config = [];
end

config = fill_struct(config, 'lowFrequency','4');
config = fill_struct(config, 'rmsFrequencyRange','0.1:200');

deviceLowFrequency = str2double(config.lowFrequency);
velocity = file.velocity.signal; % [m/s^2]
Fs = file.Fs;
signalLength = length(velocity);
dt = 1/Fs;
t = 0:dt:dt*(signalLength-1); % [s]
df = Fs/signalLength;
f = 0:df:df*(signalLength-1);

%% _______________________ Main Calculations __________________________ %%

% Implement time-domain integration of velocity signal to transform it
% to displacement (standard measure unit of velocity is [mm/s], so
% multiply by 1000 result);
velocity = detrend(velocity - mean(velocity));
displacement = detrend(cumtrapz(t, velocity), 'linear')*1000; % [mm/s] --> [mkm]
displacement = (displacement - mean(displacement));

% Filtration velocity signal from the low frequency of device
Rs = 2.5;
Rp = 0.25;
Ws = deviceLowFrequency * (2 / Fs);
Wp = 2 * deviceLowFrequency * (2 / Fs);
[n, Wn] = buttord(Wp, Ws, Rp, Rs);
[b, a] = butter(n, Wn, 'high');
displacement = filtfilt(b, a, displacement);

% Write displacement signal and time-vector to File-structure
file.displacement.signal = displacement;
file.displacement.timeVector = t';

% % Displacement RMS calculation
% % The standard displacement range = [0.1; 200] Hz
% [rmsLowFreq,rmsHighFreq] = strtok(config.rmsFrequencyRange,':');
% rmsLowFreq = str2double(rmsLowFreq);
% if strcmp(rmsHighFreq,':Fs') || isempty(rmsHighFreq)
%     rmsHighFreq = Fs;
% else
%     rmsHighFreq = str2double(rmsHighFreq(2:end)); 
% end
% 
% displacementSpectrum = fft(displacement);
% lowPosition = round(rmsLowFreq/df)+1;
% highPosition = round(rmsHighFreq/df)+1;
% displacementSpectrum(1:lowPosition-1,:)=0;
% displacementSpectrum(highPosition+1:end,:)=0;
% 
% rmsDisplacement = rms(ifft(displacementSpectrum,'symmetric'));

rmsDisplacement = [];

end

