function [ File ] = test_frequencyTracking( File, config )
%SIGNALEQUALIZATION function equalize signal part (by resampling) with
%respect of instantaneous shaft (or other) frequency

% ********************************************************************** %
% Developer     : ASLM
% Date          : 29/09/2017
% Version       : v1.0
% ********************************************************************** %

if nargin == 1
    config = [];
end
    commonFields = fields(config.Attributes);
 
    
    sizeUnits = config.plots.sizeUnits;
    imageSize = str2num(config.plots.imageSize);
    fontSize = str2double(config.plots.fontSize);
    imageFormat = config.plots.imageFormat;
    imageQuality = config.plots.imageQuality;
    imageResolution = config.plots.imageResolution;
    
    
    
    
    parameters = [];
    parameters = config.logSpectrogram.Attributes;
    if ~isempty(commonFields)
        for i = 1:numel(commonFields)
            parameters = setfield(parameters, commonFields{i}, config.Attributes.(commonFields{i}));
        end
    end
    parameters.printPlotsEnable = config.printPlotsEnable;
    parameters.plotVisible = config.plotVisible;
    parameters.parpoolEnable = config.parpoolEnable;
    parameters.translations = config.translations;
    parameters.debugModeEnable = config.debugModeEnable;
    parameters.plots = config.plots;
    parameters.filtering = config.filtering;
    parameters.interpolationFactor = '1000';
    
%% _______________________ TEST_SIGNAL_PRERESEMPLING __________________ %%
% if str2double(parameters.debugModeEnable)
%     [ File , shiftData ] = test_preresempling( File, parameters );
% end

%% ________________ ENVELOPE CORRELOGRAM TRACKING _____________________ %%
% Original Signal filtering and enveloping
% 
% [file1] = envFiltering(File, parameters);
%     
% % Calculate shift-invariant envelope spectrogram
% [ Result_env ] = logSpectrogram( file1, parameters, 'env_spec' );
% 
% 
% parameters_1 = parameters;
% parameters_1.lowFrequency = '4';
% parameters_1.highFrequency = '16';
% [ Result_env_1 ] = logSpectrogram( file1, parameters_1, 'env_spec' );
% 
% 
% parameters_2 = parameters;
% parameters_2.lowFrequency = '8';
% parameters_2.highFrequency = '32';
% [ Result_env_2 ] = logSpectrogram( file1, parameters_2, 'env_spec' );
% 
% 
% parameters_3 = parameters;
% parameters_3.lowFrequency = '16';
% parameters_3.highFrequency = '64';
% [ Result_env_3 ] = logSpectrogram( file1, parameters_3, 'env_spec' );
% 
% 
% parameters_4 = parameters;
% parameters_4.lowFrequency = '32';
% parameters_4.highFrequency = '128';
% [ Result_env_4 ] = logSpectrogram( file1, parameters_4, 'env_spec' );
% 
% 
% parameters_5 = parameters;
% parameters_5.lowFrequency = '64';
% parameters_5.highFrequency = '256';
% [ Result_env_5 ] = logSpectrogram( file1, parameters_5, 'env_spec' );
% 
% 
% 
%     parameters1 = [];
%     parameters1 = config.correlogramTracking.Attributes;
%     if ~isempty(commonFields)
%         for i = 1:numel(commonFields)
%             parameters1 = setfield(parameters1, commonFields{i}, config.Attributes.(commonFields{i}));
%         end
%     end
%     parameters1.printPlotsEnable = config.printPlotsEnable;
%     parameters1.plotVisible = config.plotVisible;
%     parameters1.parpoolEnable = config.parpoolEnable;
%     parameters1.translations = config.translations;
%     parameters1.debugModeEnable = config.debugModeEnable;
%     parameters1.plots = config.plots;
% % Correlogram-based frequency tracking
% [Result_env, status_env] = correlogramTracking( Result_env, parameters1, 'env_spec');
% 
% 
% [Result_env_1, status_env_1] = correlogramTracking( Result_env_1, parameters1, 'env_spec');
% [Result_env_2, status_env_2] = correlogramTracking( Result_env_2, parameters1, 'env_spec');
% [Result_env_3, status_env_3] = correlogramTracking( Result_env_3, parameters1, 'env_spec');
% [Result_env_4, status_env_4] = correlogramTracking( Result_env_4, parameters1, 'env_spec');
% [Result_env_5, status_env_5] = correlogramTracking( Result_env_5, parameters1, 'env_spec');
% 
% 
% % % if strcmp(status_env, 'true')
% % %     [file1] = multiscaleResampling(file1, Result_env, parameters);
% % % end


%% TEST

% % 
% % File1.Fs = File.Fs;
% % File1.signal = File.acceleration.signal;
% % parameters.lowFrequencyEnvelope = '500';
% % parameters.highFrequencyEnvelope = '5000';
% % % 
% % % mySpectrogram = spectrogram2(parameters, 'NORM-env');
% % % mySpectrogram = create(mySpectrogram, File1);
% % % plotAndPrint(mySpectrogram);
% % 
% % [myTracker] = frequencyTracker(parameters);
% % [myTracker] = create(myTracker, File1);
% % myTrack = createFrequencyTrack(myTracker);


% myTracker = spectrogramLogTracker(parameters, 'acc');
% myTracker = create(myTracker, File1);
% frequencyTrack = createTrack(myTracker);
% [myMultiTrack] = createMultiTrack(myTracker);
% 
% 
% mySpectrogramLog = spectrogram2Log(parameters, 'acc');
% mySpectrogramLog = create(mySpectrogramLog, File1);
% plotAndPrint(mySpectrogramLog);
% Result = getWithFrequencyRange(mySpectrogramLog, 4, 16);
% Result = getWithFrequencyRange(mySpectrogramLog, 8, 32);
% Result = getWithFrequencyRange(mySpectrogramLog, 16, 64);
% Result = getWithFrequencyRange(mySpectrogramLog, 32, 128);
% Result = getWithFrequencyRange(mySpectrogramLog, 64, 256);


%% _____________________  CORRELOGRAM TRACKING ________________________ %%

% % % 
% % % 
% % % % Calculate shift-invariant spectrogram 
% % % tic
% % [ Result ] = logSpectrogram( File, parameters , 'spec' ); %%%%%%%%%%%%%%%^^^^^^^^^^^^^^^^^^^
% 
% % % toc
% % % 
% % % parameters_1 = parameters;
% % % parameters_1.lowFrequency = '4';
% % % parameters_1.highFrequency = '16';
% % % [ Result_1 ] = logSpectrogram( File, parameters_1, 'spec' );
% % % 
% % % 
% % % parameters_2 = parameters;
% % % parameters_2.lowFrequency = '8';
% % % parameters_2.highFrequency = '32';
% % % [ Result_2 ] = logSpectrogram( File, parameters_2, 'spec' );
% % % 
% % % 
% % % parameters_3 = parameters;
% % % parameters_3.lowFrequency = '16';
% % % parameters_3.highFrequency = '64';
% % % [ Result_3 ] = logSpectrogram( File, parameters_3, 'spec' );
% % % 
% % % 
% % % parameters_4 = parameters;
% % % parameters_4.lowFrequency = '32';
% % % parameters_4.highFrequency = '128';
% % % [ Result_4 ] = logSpectrogram( File, parameters_4, 'spec' );
% % % 
% % % 
% % % parameters_5 = parameters;
% % % parameters_5.lowFrequency = '64';
% % % parameters_5.highFrequency = '256';
% % % [ Result_5 ] = logSpectrogram( File, parameters_5, 'spec' );
% % % 
% % % 
    parameters1 = [];
%     parameters1 = config.correlogramTracking.Attributes;
    if ~isempty(commonFields)
        for i = 1:numel(commonFields)
            parameters1 = setfield(parameters1, commonFields{i}, config.Attributes.(commonFields{i}));
        end
    end
    parameters1.printPlotsEnable = config.printPlotsEnable;
    parameters1.plotVisible = config.plotVisible;
    parameters1.parpoolEnable = config.parpoolEnable;
    parameters1.translations = config.translations;
    parameters1.debugModeEnable = config.debugModeEnable;
    parameters1.plots = config.plots;
% % % % Correlogram-based frequency tracking
% % [Result, status] = correlogramTracking( Result, parameters1, 'spec');
% % % 
% % % 
% % % [Result_1, status_1] = correlogramTracking( Result_1, parameters1, 'spec');
% % % [Result_2, status_2] = correlogramTracking( Result_2, parameters1, 'spec');
% % % [Result_3, status_3] = correlogramTracking( Result_3, parameters1, 'spec');
% % % [Result_4, status_4] = correlogramTracking( Result_4, parameters1, 'spec');
% % % [Result_5, status_5] = correlogramTracking( Result_5, parameters1, 'spec');
% % % 
% % Signal resampling
% % if strcmp(status, 'true')
%     Result.shift = (Result.shift-1)*100;
%     [File1] = multiscaleResampling(File, Result, parameters, 'acc'); 
%     
%     [File] = multiscaleResampling(File, Result, parameters, 'env'); 
%     [File2] = multiscaleResampling(File1, Result, parameters, 'env'); 
    
    
    S_before_R = load('ENV_before_RES_1.mat');  %% #1
    R_before_S = load('RES_before_ENV_2.mat');  %% #2
    
    Fs = File.Fs;
    %#1
    signal1 = S_before_R.signalResampled;
    df1 = Fs/length(signal1);
    f1 = 0:df1:Fs-df1;
    spectrum1 = abs(fft(signal1));
    spectrum1 = spectrum1/length(signal1);
    
    % #2
    signal2 = R_before_S.signal;
    df2 = Fs/length(signal2);
    f2 = 0:df2:Fs-df2;
    spectrum2 = abs(fft(signal2));
    spectrum2 = spectrum2/length(signal2);
    
    
        myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Color', 'w');
        plot(f1, spectrum1);
        hold on, plot(f2, spectrum2);
        xlabel('Frequency, Hz');
        ylabel('Amplitude, m/s^2');
        title([' Spectrum. Signal Resampling']);
        grid on;
        legend('S_b_R','R_b_S');
        myAxes = myFigure.CurrentAxes;
        myAxes.FontSize = fontSize;
    
    
    
% end
% % % 
% % % 
% % % 
% % % 
% % % 
% % % 
% % % % Decision Maker ...
% % %     myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Color', 'w');
% % %     hold on, grid on;
% % %     labels = [];
% % %     if ~isempty(Result.shift)
% % %         shiftEstimated = (Result.shift-1)*100;
% % %         timeEstimated = Result.time;
% % %         plot(timeEstimated,shiftEstimated,'--');
% % %         labels = {'spectrum'};
% % %     end
% % %     
% % %     if ~isempty(Result_env.shift)
% % %         shiftEstimated_env = (Result_env.shift-1)*100;
% % %         timeEstimated_env = Result_env.time;
% % %         plot(timeEstimated_env,shiftEstimated_env,'+');
% % %         labels = [labels, {'envelope spectrum'}];
% % %     end
% % %     
% % %     xlabel('Time, sec');
% % %     ylabel('Shift, %');
% % %     title(['Frequency trace comparison', '. Spec\_validity = ',num2str(Result.shiftValidity),', Spec\_env\_validity = ',num2str(Result_env.shiftValidity)]);
% % %     legend(labels);
% % %     
% % %     % Print image
% % %     fileName = 'Frequency Tracking';
% % %     fullFileName = fullfile(pwd, 'Out', fileName);
% % %     print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
% % %     
% % % 
% % % val = std(shiftEstimated-shiftEstimated_env);
% % % myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Color', 'w');
% % % plot(timeEstimated_env, abs(shiftEstimated-shiftEstimated_env));
% % % xlabel('Time, sec');
% % % ylabel('abs Error, %');
% % % title(['Frequency Traces Error. Std(Error) = ',num2str(val)]);
% % % grid on;  
% % % 
% % %     % Print image
% % %     fileName = 'Frequency Tracking_error';
% % %     fullFileName = fullfile(pwd, 'Out', fileName);
% % %     print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
% % % 
% % % %     hold o
% 
% Linear Prediction Test
[ Result ] = linearPredictionTracking( File, parameters ); 


%%

% % ... Decision Maker

% % Test ... comparison
% if str2double(parameters.debugModeEnable)
% 
%     shiftEstimated = (Result.shift-1)*100;
%     timeEstimated = Result.time;
% 
%     shiftOriginal = (shiftData.shift-1)*100;
%     timeOriginal = shiftData.time;
%     idx = find(timeOriginal == timeEstimated(1));
%     delta = shiftOriginal(idx);
%     shiftOriginal = shiftOriginal-delta;
% 
%     figure('Color','w'), hold on, grid on;
%     plot(timeOriginal,shiftOriginal,'--');
%     plot(timeEstimated,shiftEstimated,'*');
%     xlabel('Time, sec');
%     ylabel('Shift, %');
%     title('Frequency trace comparison');
%     legend('generated','estimated');
% end

