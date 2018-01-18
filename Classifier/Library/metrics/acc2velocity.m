% ACC2VELOCITY transforms acceleration signal to velocity and calculates
% velocity rms value in the specific range (default frequency range is set
% by ISO)
function [ file, rmsVelocity ] = acc2velocity( file, config )

%% ____________________ Default parameters ____________________________ %%
if nargin < 2
   config = [];
end

config = fill_struct(config, 'lowFrequency','4');
config = fill_struct(config, 'rmsFrequencyRange','10:1000');

deviceLowFrequency = str2double(config.lowFrequency);
acceleration = file.acceleration.signal; % [m/s^2]
Fs = file.Fs;
signalLength = length(acceleration);
dt = 1/Fs;
t = 0:dt:dt*(signalLength-1); % [s]
df = Fs/signalLength;
f = 0:df:df*(signalLength-1);

% Write acceleration time-vector to File-structure
file.acceleration.timeVector = t';

%% _______________________ Main Calculations __________________________ %%

% Implement time-domain integration of acceleration signal to transform it
% to velocity (standard measure unit of velocity is [mm/s], so multiply by
% 1000 result);
acceleration = detrend(acceleration - mean(acceleration));
velocity = detrend(cumtrapz(t, acceleration), 'linear')*1000; % [m/s^2] --> [mm/s]
velocity = (velocity - mean(velocity));

% Filtration velocity signal from the low frequency of device
Rs = 2.5;
Rp = 0.25;
Ws = deviceLowFrequency * (2 / Fs);
Wp = 2 * deviceLowFrequency * (2 / Fs);
[n, Wn] = buttord(Wp, Ws, Rp, Rs);
[b, a] = butter(n, Wn, 'high');
velocity = filtfilt(b, a, velocity);

% Write velocity signal and time-vector to File-structure
file.velocity.signal = velocity;
file.velocity.timeVector = t';

% % Velocity RMS calculation
% % The standard velosity range = [10; 1000] Hz
% [rmsLowFreq,rmsHighFreq] = strtok(config.rmsFrequencyRange,':');
% rmsLowFreq = str2double(rmsLowFreq);
% if strcmp(rmsHighFreq,':Fs') || isempty(rmsHighFreq)
%     rmsHighFreq = Fs;
% else
%     rmsHighFreq = str2double(rmsHighFreq(2:end)); 
% end
% 
% velocitySpectrum = fft(velocity);
% lowPosition = round(rmsLowFreq/df)+1;
% highPosition = round(rmsHighFreq/df)+1;
% velocitySpectrum(1:lowPosition-1,:)=0;
% velocitySpectrum(highPosition+1:end,:)=0;
% 
% rmsVelocity = rms(ifft(velocitySpectrum,'symmetric'));

rmsVelocity = [];

end

