function [ Result ] = linearPredictionTracking( File, config )
%LINEARPREDICTIONTRACKING Summary of this function goes here

    if nargin == 1
       config = []; 
    end

    
    
    plots = config.plots;
    sizeUnits = plots.sizeUnits;
    imageSize = str2num(plots.imageSize);
    fontSize = str2double(plots.fontSize);
    imageFormat = plots.imageFormat;
    imageQuality = plots.imageQuality;
    imageResolution = plots.imageResolution;
    
    
% INPUT:
    signal = File.acceleration.signal;
    Fs = File.Fs;
    
    interpolationFactor = 10000;
    secPerFrame = 0.25; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    framesNumber = floor(size(signal,1)/(secPerFrame*Fs));
    
%     figure('Color','w');
    myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Color', 'w');

    hold on;
%     interpolationFactor = 1000;
    startSecCollection = [22, 46, 71]; % Signal #2
%     startSecCollection = [31, 56, 80]; % Signal #1
% startSecCollection = [1];  

% startSecCollection = [1, 29, 58]; % Generated sin
    
    x_est = cell(size(startSecCollection));
    x_origin = cell(size(startSecCollection));
    
    H_est = cell(size(startSecCollection));
    for i = 1:length(startSecCollection)
%         startSec = 40*(i-1)+1;
%         if startSec>120
%             startSec = 119;
%         end
        startSec = startSecCollection(i);
        x = signal(startSec*secPerFrame*Fs:(startSec+1)*secPerFrame*Fs);
        x_origin{i} = x;
%         x = signal;
        [d,p] = lpc(x,32);
        x_est{i} = filter(-d(2:end),1,x);
        
        
        [H,w] = freqz(sqrt(p),d);
        
        % Interpolation
        wLength = length(w);
        arrayOrigin = 1:wLength;
        arrayInterp = 1:1/interpolationFactor:wLength;

        % Main properties spline interpolation
        wInterp = interp1( arrayOrigin, w, arrayInterp, 'spline')';
        HInterp = interp1( arrayOrigin, H, arrayInterp, 'spline')';
        H_est{i} = 20*log10(2*abs(HInterp)/Fs);
        
%         hp = plot(wInterp/pi*Fs/2,20*log10(2*abs(HInterp)/(2*pi))); % Scale to make one-sided PSD
        hp = plot(wInterp/pi*Fs/2/1000,20*log10(2*abs(HInterp)/Fs)); % Scale to make one-sided PSD
        hp.LineWidth = 2;
        
%         save('beforeRe.mat','wInterp','HInterp');
        
        
%         spectrumLength = length(x_est);
%         x_est_long = [x_est; zeros(spectrumLength*9,1)];
%         
%         spectrum = abs(fft(x_est_long));
%         
%         spectrum = spectrum/length(spectrum);
%         sp{i} = spectrum;
%         
% %         sp{i} = interp1( arrayOrigin, spectrum, arrayInterp, 'spline')';
    end
    
    title('PSD before resampling');
    xlabel('Frequency, kHz');
    xlim([0 30]);
%     ylabel('One-sided PSD (dB/rad/sample)');
    ylabel('One-sided PSD (dB/Hz)');
%     legend('RPM = 750','RPM = 850','RPM = 600','RPM = 900');
%     legend('RPM = 750','RPM = 900','RPM = 600','RPM = 900','RPM = 900');
%     legend('RPM = 750','RPM = 900','RPM = 750','RPM = 600','RPM = 750', 'RPM = 900');
    legend('RPM = 900','RPM = 750','RPM = 600');
    grid on;
    myAxes = myFigure.CurrentAxes;
    myAxes.FontSize = fontSize;
%     figure('Color','w');
%     [H1,w1] = freqz(sqrt(p),d);
%     hold on;
%     hp = plot(w1/pi*Fs/2,20*log10(2*abs(H1)/(2*pi)),'r'); % Scale to make one-sided PSD
%     hp.LineWidth = 2;
%     xlabel('Frequency, Hz');
%     ylabel('One-sided PSD (dB/rad/sample)');
%     legend('PSD estimate of x','PSD of model output');
    

% figure('Color','w'), grid on;
% % corrCoeff = cell(size(x_origin));
% % lags = cell(size(x_origin));
% for i = 1:numel(x_origin)
%     [corrCoeff, lags] = xcorr(x_origin{i}-x_est{i}, length(x_origin{i}), 'coeff');
%     hold on, plot(lags, abs(corrCoeff));
% end
% xlabel('Lags, samples');
% ylabel('Magnitude');
% title('Correlation Function of 3 RPM');
% legend('1','2','3');


% 
% figure('Color','w');
% hold on;
% 
% for i = 1:numel(sp)
%     df = Fs/ length(sp{i});
%     f = 0:df:Fs-df;
%     plot(f, sp{i});
% end
% xlabel('Frequency, Hz');
% ylabel('Spectrum');
% legend('RPM = 900','RPM = 750','RPM = 600');
% CALCULATION:    
    
    
    
% OUTPUT:    

