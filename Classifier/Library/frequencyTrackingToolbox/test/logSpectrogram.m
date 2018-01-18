function [ Result ] = logSpectrogram( File, config, tag )
%FREQ2LOG function calculates spectrogram with log frequency-axis.

% ********************************************************************* %

% Developer     : ASLM
% Date          : 29/09/2017
% Version       : 0.1

% ********************************************************************* %
    if nargin == 1
       config = [];
       tag = 'spec';
    end
    


% INPUT:
    % Default Function Parameters
    config = fill_struct(config, 'secPerFrame', '1');
    config = fill_struct(config, 'secOverlap', '0.5');
    config = fill_struct(config, 'lowFrequency', '1');
    config = fill_struct(config, 'highFrequency', '500');
    config = fill_struct(config, 'logBasis', '1.01');
    config = fill_struct(config, 'fLogStep', '0.01');
    config = fill_struct(config, 'interpolationFactor', '1000');
    
    config = fill_struct(config, 'plotEnable', '0');
    
    secPerFrame = str2double(config.secPerFrame);
    secOverlap = str2double(config.secOverlap);
    lowFrequency = str2double(config.lowFrequency);
    highFrequency = str2double(config.highFrequency);
    logBasis = str2double(config.logBasis);
    fLogStep = str2double(config.fLogStep);
    interpolationFactor = str2double(config.interpolationFactor);
    
    plotEnable = str2double(config.plotEnable);

    signal = File.acceleration.signal(:,1);
    Fs = File.Fs;
    
    df = File.Fs/size(File.acceleration.signal,1);
    
    f = lowFrequency:df:highFrequency;
%     f = 0:df:highFrequency;
    
    
% CALCULATION:
    
    % ___________________ Form Log Frequency Vector ____________________ %
    fLog = log2(f)/log2(logBasis);
    f_new = f(fLog>=0);
    fLog_new = fLog(fLog>=0);

    % Gets orignal scalogram properties and form original and
    % interpolated arrays for further interpolation
    fLogOrigin = fLog_new;

    fLogLength = length(fLogOrigin);
    arrayOrigin = 1:fLogLength;
    arrayInterp = 1:1/interpolationFactor:fLogLength;

    % Main properties spline interpolation
    fLogInterp = interp1( arrayOrigin, fLogOrigin, arrayInterp, 'spline')';
    fLogInterp = round(fLogInterp,2);

    
    fLogLinearSrt = ceil(fLogInterp(1)/fLogStep)*fLogStep;
    fLogLinearEnd = floor(fLogInterp(end)/fLogStep)*fLogStep;
    fLogLinearLen = (fLogLinearEnd-fLogLinearSrt)/fLogStep + 1;
    
    fLogLinear = linspace(fLogLinearSrt,fLogLinearEnd, fLogLinearLen);
    fLogLinear = round(fLogLinear,2);
    
%     fLogLinearLen = floor(max(fLogInterp)/fLogStep);
%     fLogLinear = linspace(0,fLogLinearLen*fLogStep, fLogLinearLen+1);
%     fLogLinear = round(fLogLinear,2);

    [~,pos,~] = intersect(fLogInterp,fLogLinear);
            
    % _____________________ Spectrogram Calculation ____________________ %

    T_window = Fs*secPerFrame;
    T_overlap = Fs*secOverlap;
    F = f_new;
    [coeffMat,~,T] = spectrogram(signal,kaiser(T_window,5),T_overlap,F, Fs);
    coeffMat = abs(coeffMat);
%     coeffMat = real(coeffMat);

    coeffMatLog = cell(size(coeffMat,2),1);
    for i = 1:size(coeffMat,2)
        a = interp1( arrayOrigin, coeffMat(:,i), arrayInterp, 'spline');
%         a = interp1( arrayOrigin, coeffMat(:,i), arrayInterp, 'v5cubic');
        coeffMatLog{i} = a(pos);
    end
    coeffMatLog = cell2mat(coeffMatLog)';

    
% OUTPUT:            
    Result.frequency = fLogLinear;
    Result.logBasis = logBasis;
    Result.time = T;
    Result.spectrogram = coeffMatLog;
    Result.frequencyStep = fLogStep;
    Result.secPerFrame = secPerFrame;
    Result.secOverlap = secOverlap;
    
    
    % _______________________ Plot Result ______________________________ %

    
    if plotEnable
%         
%         figure('Color','w'),plot(F,coeffMat(:,1));
%         title(['OriginalSpectrum, lowFrequency=',num2str(lowFrequency),'Hz, highFrequency=', num2str(highFrequency),'Hz']);
%         xlabel('Frequency, Hz');
%         ylabel('Spectrum, m/s^2');
%         grid on;
%         
%         figure('Color','w'),plot(fLogLinear,coeffMatLog(:,1));
%         title(['LogSpectrum, lowFrequency=',num2str(lowFrequency),'Hz, highFrequency=', num2str(highFrequency),'Hz']);
%         xlabel('Frequency, log(Hz)');
%         ylabel('Spectrum, m/s^2');
%         grid on;
        
        
    % Plot parameters
    printPlotsEnable = str2double(config.printPlotsEnable);
    plotVisible = config.plotVisible;
    
    sizeUnits = config.plots.sizeUnits;
    imageSize = str2num(config.plots.imageSize);
    fontSize = str2double(config.plots.fontSize);
    imageFormat = config.plots.imageFormat;
    imageQuality = config.plots.imageQuality;
    imageResolution = config.plots.imageResolution;
    
    Translations = config.translations;
    
    
        
        
        myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
        imagesc(T,fLogLinear,coeffMatLog);
        
        myAxes = myFigure.CurrentAxes;
        % Set axes font size
        myAxes.FontSize = fontSize;
        
        % Figure title
        title(myAxes, [upperCase(Translations.spectrogram.Attributes.name,'first'),'\_',tag]);
                    
        % Figure labels
        xlabel(myAxes, [upperCase(Translations.time.Attributes.name, 'first'), ', ', ...
                        upperCase(Translations.time.Attributes.value, 'first')]);
        ylabel(myAxes, [upperCase(Translations.logarithm.Attributes.shortName, 'first'), ', ',...
                        upperCase(Translations.frequency.Attributes.name, 'first'), ', ',...
                                  Translations.logarithm.Attributes.shortName, '(',...
                        upperCase(Translations.frequency.Attributes.value,'first'), ')']);

        caxis(caxis.*0.5);
        
        if printPlotsEnable
            % Save the image to the @Out directory
            imageNumber = '1';
            fileName = ['spectrogram_',tag,'-LOG-acc-' imageNumber];
            fullFileName = fullfile(pwd, 'Out', fileName);
            print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
        end
        
        % Close figure with visibility off
        if strcmpi(plotVisible, 'off')
            close(myFigure)
        end
    end
    
    


