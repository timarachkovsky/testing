% Inner control/spectral_method.m  v1.0
% 05-02-2016 
% Aslamov

function  [v_rms1_log, v_rms2_log, v_rms3_log, status] = iso15242Processing(File, parameters)

%% ____________________ Description ___________________________________ %%
% iso15242_method() calculate the rms level of vibrorate signal in 3
% ranges: [F_Low;F_Med1], [F_Med1; F_Med2], [F_Med2; F_High].
% F_Low, F_Med1, F_Med2, F_High depend on S frequency
% ______________________________________________________________________ %
%    Standard range frequencies:
% F_Low_standard = 50 Hz;              
% F_Med1_standard = 300 Hz;        % I range 
% F_Med2_standard = 1800 Hz;       % II range
% F_High_standard = 10000 Hz;      % III range

% Standard sensevity = 16/1000;

%% ____________________ Parameters ____________________________________ %%

if nargin < 2
    parameters = [];
end

iLoger = loger.getInstance;

parameters = fill_struct(parameters, 'timeInterval', '30'); % reduce the number of times a signal

parameters = fill_struct(parameters, 'Rp', '0.1');  % passband ripple, dB
parameters = fill_struct(parameters, 'Rs', '20');   % stopband attenuation, dB

parameters = fill_struct(parameters, 'F_Low', '50');  % Recalculate frequencies
parameters = fill_struct(parameters, 'F_Med1', '300');
parameters = fill_struct(parameters, 'F_Med2', '1800');
parameters = fill_struct(parameters, 'F_High', '10000');

parameters = fill_struct(parameters, 'v_rms_nominal', '0.05e-6'); % Zero-point of rms level

parameters = fill_struct(parameters, 'sensevity', '0.016');

warningLevel = str2num(parameters.warningLevel);
damageLevel = str2num(parameters.damageLevel);
sensevity = str2double(parameters.sensevity);
timeInterval = str2double(parameters.timeInterval);

plotEnable = str2double(parameters.plotEnable);
printPlotsEnable = str2double(parameters.printPlotsEnable);
plotVisible = parameters.plotVisible;
plotTitle = parameters.plotTitle;
historyEnable = str2double(parameters.historyEnable);
debugModeEnable = str2double(parameters.debugModeEnable);

sizeUnits = parameters.plots.sizeUnits;
imageSize = str2num(parameters.plots.imageSize);
fontSize = str2double(parameters.plots.fontSize);
imageFormat = parameters.plots.imageFormat;
imageQuality = parameters.plots.imageQuality;
imageResolution = parameters.plots.imageResolution;

Translations = File.translations;

F_Low = str2double(parameters.F_Low);  % Recalculate frequencies
F_Med1 = str2double(parameters.F_Med1);                                                                              
F_Med2 = str2double(parameters.F_Med2);
F_High = str2double(parameters.F_High);

Rp = str2double(parameters.Rp);    % passband ripple, dB 
Rs = str2double(parameters.Rs);    % stopband attenuation, dB

v_rms_nominal = str2double(parameters.v_rms_nominal); % Zero-point of rms level                               

if(size(File.acceleration.signal,2)>size(File.acceleration.signal,1))
           File.acceleration.signal = File.acceleration.signal';
end
if timeInterval<length(File.acceleration.signal)/File.Fs
    File.acceleration.signal = File.acceleration.signal(1:timeInterval*File.Fs,1)/sensevity; 
else
    File.acceleration.signal = File.acceleration.signal/sensevity;
end

%% ____________________ Calculation ___________________________________ %%

[m,~]=size(File.acceleration.signal);
dt=1/File.Fs;
tmax=dt*(m-1);
t=0:dt:tmax;
len = length(t);

% Convert vibroacceleration to vibrorate
% File = acc2velocity(File, parameters);
velocity = File.velocity.signal;
%% Create 3x P-filters for each range:
                    % I range 
Wp1=[F_Low*2/File.Fs F_Med1*2/File.Fs];                                                       
Ws1=[(F_Low-0.1*F_Low)*2/File.Fs (F_Med1+0.1*F_Med1)*2/File.Fs]; 
[~,Wn1] = buttord(Wp1,Ws1,Rp,Rs);         
[b1,a1] = butter(2,Wn1);                    
                    % II range
Wp2=[F_Med1*2/File.Fs F_Med2*2/File.Fs];
Ws2=[(F_Med1-0.1*F_Med1)*2/File.Fs (F_Med2+0.1*F_Med2)*2/File.Fs]; 
[~,Wn2] = buttord(Wp2,Ws2,Rp,Rs);         
[b2,a2] = butter(3,Wn2);                  
                    % III range
Wp3=[F_Med2*2/File.Fs F_High*2/File.Fs];
Ws3=[(F_Med2-0.1*F_Med2)*2/File.Fs (F_High+0.1*F_High)*2/File.Fs]; 
[~,Wn3] = buttord(Wp3,Ws3,Rp,Rs);         
[b3,a3] = butter(5,Wn3);                   

%% ____________________ RMS Levels Calculation ________________________ %%

% Signals after filtration
v_filt1 = filtfilt(b1,a1,(velocity));                     
v_filt2 = filtfilt(b2,a3,(velocity));
v_filt3 = filtfilt(b3,a3,(velocity));

% RMS values of the filtered signals
v_rms1 = rms(v_filt1);                                      
v_rms2 = rms(v_filt2);
v_rms3 = rms(v_filt3);

% Logarithmic values of the overall level of vibration in each range
v_rms1_log = 20*log10(v_rms1/v_rms_nominal);     
v_rms2_log = 20*log10(v_rms2/v_rms_nominal);      
v_rms3_log = 20*log10(v_rms3/v_rms_nominal);

vectorRms = [v_rms1_log v_rms2_log v_rms3_log];
% Calculate status for each octave (normal, warning, damage) 
if ~isempty(damageLevel) && ~isempty(warningLevel)
    if 3 ~= length(warningLevel) || ...
            3 ~= length(damageLevel) ||...
            length(warningLevel) ~= length(damageLevel)
        warningLevel = ones(1, 3)*mean(warningLevel);
        damageLevel = ones(1, 3)*mean(damageLevel);

        iLoger = loger.getInstance;
        printComputeInfo(iLoger, 'Octave spectrum method', 'Wrong exhibited thresholds!!!');
    end
    warningPositions = (vectorRms < damageLevel) & (vectorRms >= warningLevel);
    damagePositions = (vectorRms >= damageLevel);

    status(1,1:3) = {'GREEN'};
    status(1,warningPositions) = {'ORANGE'};
    status(1,damagePositions) = {'RED'};
else
    status(1, 1:3) = {''};
    warningPositions = [];
    damagePositions = [];
end

%% ____________________ PLOT_RESULTS __________________________________ %%

    if plotEnable 
        
%         if debugModeEnable
%             f = (0 : len - 1) / len * File.Fs;
%             % Plot signals filtering
%             figure('Color','w','Visible', plotVisible);
%             subplot(2, 1, 1);
%             plot(t, File.acceleration.signal);
%             ylabel('Acceleration, m/s^2');
%             xlabel('Time, s');
%             subplot(2, 1, 2);
%             plot(File.velocity.timeVector, velocity);
%             ylabel('Velosity, mm/s');
%             xlabel('Time, s');
%             if strcmpi(plotVisible, 'off')
%                 close
%             end
%             
%             % Plot Filters AFC
%             [H1, w1] = freqz(b1, a1, 8192);
%             [H2, w2] = freqz(b2, a2, 8192);
%             [H3, w3] = freqz(b3, a3, 8192);
%             figure('Color','w', 'Visible', plotVisible);
%             hold on;
%             plot(w1 * File.Fs / (2 * pi), abs(H1), 'r');
%             plot(w2 * File.Fs / (2 * pi), abs(H2), 'b');
%             plot(w3 * File.Fs / (2 * pi), abs(H3), 'g');
%             hold off;
%             ylabel('Filter AFC');
%             xlabel('Frequence, Hz');
%             if strcmpi(plotVisible, 'off')
%                 close
%             end
%             
%             % Plot spectra filtering
%             figure('Color','w','Visible', plotVisible);
%             subplot(2, 1, 1);
%             plot(f, abs(fft(File.acceleration.signal)) / len, 'b');
%             ylabel('Vibro acceleration Spec, m/s^2');
%             xlabel('Frequence, Hz');
%             subplot(2, 1, 2);
%             plot(abs(fft(velocity)) / len, 'r');
%             ylabel('Vibro rate Spec, mm/s');
%             xlabel('Frequence, Hz');
%             if strcmpi(plotVisible, 'off')
%                 close
%             end
%         end
        
        % Plot results
        spectrum(1, : ) = vectorRms;
        
        if nnz(warningPositions) ~= 0
            spectrum(1, warningPositions) = warningLevel(1, warningPositions);
            spectrum(2, warningPositions) = vectorRms(1, warningPositions) - warningLevel(1, warningPositions);
        end
        if nnz(damagePositions) ~= 0
            spectrum(1, damagePositions) = warningLevel(1, damagePositions);
            spectrum(2, damagePositions) = damageLevel(1, damagePositions) - warningLevel(1, damagePositions);
            spectrum(3, damagePositions) = vectorRms(1, damagePositions) - damageLevel(1, damagePositions);
        end
        
        % Plot
        myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
        myBar = bar(spectrum', 'stacked');
        if length(myBar) == 1
            myBar(1).FaceColor = [0 1 0];
        elseif length(myBar) == 2
            myBar(1).FaceColor = [0 1 0];
            myBar(2).FaceColor = [1 1 0];
        elseif length(myBar) == 3
            myBar(1).FaceColor = [0 1 0];
            myBar(2).FaceColor = [1 1 0];
            myBar(3).FaceColor = [1 0 0];
        end
        grid on;
        
        % Get axes data
        myAxes = myFigure.CurrentAxes;
        % Set axes font size
        myAxes.FontSize = fontSize;
        
        % Figure title
        if strcmp(plotTitle, 'on')
            title(myAxes, ['ISO15242 ', Translations.method.Attributes.name]);
        end
        % Figure labels
        xlabel(myAxes, [upperCase(Translations.centralFrequency.Attributes.name, 'first'), ', ', ...
            upperCase(Translations.frequency.Attributes.value, 'first')]);
        ylabel(myAxes, [upperCase(Translations.value.Attributes.name, 'first'), ', ', Translations.value.Attributes.value]);
        % Replace the x-axis values by the central frequencies
        xticks(myAxes, linspace(1, 3, 3));
        xticklabels(myAxes, round([(F_Low + F_Med1) / 2, (F_Med1 + F_Med2) / 2, (F_Med2 + F_High) / 2] * 100) / 100);
        
        % Set axes limits
        yScale = 1.5;
        yLimits = ylim;
        ylim(myAxes, [yLimits(1), yLimits(2) * yScale]);
        
        if printPlotsEnable && ~historyEnable
            % Save the image to the @Out directory
            imageNumber = '1';
            fileName = ['iso15242-full-vel-' imageNumber];
            fullFileName = fullfile(pwd, 'Out', fileName);
            print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
            
            if checkImages(fullfile(pwd, 'Out'), fileName, imageFormat)
                printComputeInfo(iLoger, 'iso15242', 'The method images were saved.')
            end
        end
        
        % Close figure with visibility off
        if strcmpi(plotVisible, 'off')
            close(myFigure)
        end
    end
end