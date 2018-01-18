function [ Result, myTrack ] = frequencyTracking( File, config )
%SIGNALEQUALIZATION function equalize signal part (by resampling) with
%respect of instantaneous shaft (or other) frequency

% ********************************************************************** %
% Developer     : ASLM
% Date          : 29/09/2017
% Version       : v1.0
% ********************************************************************** %


if nargin < 2
   error('There is no config file for frequency tracking!');
end



%% ______________________ Frequency Tracking __________________________ %%

File1.Fs = File.Fs;
File1.signal = File.acceleration.signal;

Parameters = config;
field2add = fields(config.Attributes);
for i = 1:numel(field2add)
     Parameters = setfield(Parameters, field2add{i}, config.Attributes.(field2add{i}));
end
      
[myTracker] = frequencyTracker(Parameters);
[myTracker] = create(myTracker, File1);
[myTrack] = createFrequencyTrack(myTracker);


%% _______________________ Signal Resampling __________________________ %%
if myTrack.validity > 0
    
    Parameters = [];
    Parameters = config;
    
    if isfield(Parameters, 'filtering')
        field2add = fields(Parameters.filtering);
        for i = 1:numel(field2add)
             Parameters = setfield(Parameters, field2add{i}, Parameters.filtering.(field2add{i}));
        end
        if isfield(Parameters, 'secPerFrame')
            Parameters = rmfield(Parameters, 'secPerFrame');
        end
    end
    
    if isfield(Parameters, 'logSpectrogram')
        if isfield(Parameters.logSpectrogram, 'Attributes')
            field2add = fields(Parameters.logSpectrogram.Attributes);
            for i = 1:numel(field2add)
                 Parameters = setfield(Parameters, field2add{i}, Parameters.logSpectrogram.Attributes.(field2add{i}));
            end
        end
    end
    Parameters.plotEnable = config.Attributes.plotEnable;
    
    [File] = multiscaleResampling(File, myTrack, Parameters, 'acc'); 
    [File] = multiscaleResampling(File, myTrack, Parameters, 'env');
    
    % Fill struct 
    Result.Fs = File.Fs;
    Result.acceleration.signal = File.acceleration.signalResampled;
    Result.acceleration.signalOrigin = File.acceleration.signal;
    Result.acceleration.envelopeSignal = File.envelope.signalResampled;
    if isfield(Result.acceleration, 'secondarySignal')
        Result.acceleration.secondarySignal = File.acceleration.secondarySignalResampled;
    end
    
else
    Result = File;
end



