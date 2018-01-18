classdef scalogram
    %SCALOGRAM class is used to create scalogram of the input signal
    %   Scalogram class contains cwtCoefficients, cwtScales and frequencies
    %   calculated using "log2' or "linear" scale types. 
    
    % Developer : ASLM
    % Date : 20.10.2016
    % Version : v1.0

    % Version : v1.1 Interpolation method excluded. Ratgor, 2016-10-25
    % Version : v1.2 The possibility of using various basic wavelet
    %                functions is added. ASLM, 2017-04-04
    
    properties (Access = private)
    % Input:
        config % Configuration structure
        Fs
        waveletName
        waveletFormFactor
    
    % Parameters
    parpoolEnable
    plotEnable
    plotVisible
    printPlotsEnable
    
    iLoger
    
    decimationFactor
    cwtTable
        
    % Output:
        coefficients
        scales
        frequencies
    end
    
    methods (Access = public)
        
        % Constuctor method
        function [myScalogram] = scalogram( file, config)
            
            myScalogram.config = config;
            myScalogram.parpoolEnable = str2double(config.Attributes.parpoolEnable);
            myScalogram.plotEnable = str2double(config.Attributes.plotEnable);
            myScalogram.plotVisible = config.Attributes.plotVisible;
            myScalogram.printPlotsEnable = str2double(config.Attributes.printPlotsEnable);
            
            myScalogram.Fs = file.Fs;
            myScalogram.waveletName = config.Attributes.waveletName;
            myScalogram.waveletFormFactor = config.Attributes.waveletFormFactor;
            
            myScalogram.decimationFactor = 500;
            
            myScalogram.iLoger = loger.getInstance;
            
            myScalogram = create(myScalogram,file);
        end
        
        % Getters/Setters ...
        function [myCoefficients] = getCoefficients(myScalogram)
            myCoefficients = myScalogram.coefficients;
        end
        function [myScalogram] = setCoefficients(myScalogram, myCoefficients)
           myScalogram.coefficients = myCoefficients; 
        end
        
        function [myScales] = getScales(myScalogram)
            myScales = myScalogram.scales;
        end
        function [myScalogram] = setScales(myScalogram, myScales)
           myScalogram.scales = myScales; 
        end
        
        function [myFrequencies] = getFrequencies(myScalogram)
            myFrequencies = myScalogram.frequencies;
        end
        function [myScalogram] = setFrequencies(myScalogram, myFrequencies)
           myScalogram.frequencies = myFrequencies; 
        end
           
        function [myConfig] = getConfig(myScalogram)
            myConfig = myScalogram.config;
        end
        function [myScalogram] = setConfig(myScalogram, myConfig)
           myScalogram.config = myConfig; 
        end
        
        function [myWaveletName] = getWaveletName(myScalogram)
            myWaveletName = myScalogram.waveletName;
        end
        function [myScalogram] = setWaveletName(myScalogram, myWaveletName)
           myScalogram.config = myWaveletName; 
        end
        
        function [myCoefficients, myFrequencies, myScales] = getParameters(myScalogram)
            myCoefficients = myScalogram.coefficients;
            myFrequencies = myScalogram.frequencies;
            myScales = myScalogram.scales;
        end
        

        % ... Getters/Setters
        
        % CREATE function calculates scales/frequencies array 
        % and scalogram coefficients of the original signal on the
        % basis of wavelet ( wavelet type is specified in config property)
        function [myScalogram] = create(myScalogram, file)
           
            parameters = myScalogram.config.Attributes;
            
            % Calculate scales and frequencies array (with "log2" or 
            % "linear" scale types) 
            [myScales, myFrequencies] = createScales(myScalogram, file);
            
            % Implement continuous wavelet transform base on specific 
            % wavelet and form cwt coefficients matrix (@cwtTable) (
            % covariance matrix)
            %cwtTable,SeparateFrames]= dividedCWT(file,myScales,parameters);
            parameters.waveletName = myScalogram.waveletName;
            cwtTable= dividedCWT(file,myScales,parameters);
            
                if str2double(parameters.varianceEnable)
                    myCoefficients = std(cwtTable,[],2);
                else
                    myCoefficients = max(cwtTable,[],2);
                end
                
                myScalogram.coefficients = myCoefficients;
                myScalogram.frequencies = myFrequencies;
                myScalogram.scales = myScales;
                
                waveletCentralFrequency = 1000; % Hz
                myNewScales = waveletCentralFrequency*(myFrequencies.^(-1));
                myWaveletName = myScalogram.waveletName;
                
            decFac = myScalogram.decimationFactor;
            endPosition = ceil(size(cwtTable,2)/decFac)*decFac;
            myScalogram.cwtTable = cwtTable(:,1:decFac:endPosition);

            [~, frequencyFactor] = myScalogram.getCorrectionFactors(myWaveletName);
            myNewScales = myNewScales/frequencyFactor;
            myScalogram.scales = myNewScales;
                
% % %           % __________________ Plot results ________________________ %%
% % % 
% % %                 if myScalogram.plotEnable == 1
% % %                     figure('Color', 'w','Visible',myScalogram.plotVisible), grid on;
% % %                     plot(myFrequencies(1:1:length(myCoefficients)), myCoefficients),...
% % %                     title(['SWD Scalogram, wavelet: ',myScalogram.waveletName]); %sprintf('Scalogram of frame number %d',i)
% % %                     xlabel('Frequency, Hz');
% % %                     ylabel('Magnitude, m^2/s^4');
% % %                     grid on;
% % %                     
% % % %                     % Save image to the @Out directory
% % % %                     if myScalogram.printPlotsEnable == 1
% % % %                         fileName = 'SWD_Scalogram_Original';
% % % %                         fullFilePath = fullfile(pwd,'Out');
% % % %                         fullFileName = fullfile(fullFilePath,fileName);
% % % %                         print(fullFileName,'-djpeg91', '-r180');
% % % %                     end
% % % % 
% % % %                         % Close figure with visibility off
% % % %                         if strcmpi(myScalogram.plotVisible, 'off')
% % % %                             close
% % % %                         end
% % % % 
% % % %                 end 

        end
        
        function [myNormalizedScalogram] = normalizeScalogram(myScalogram)
            
           waveletCentralFrequency = 1000; % Hz
           myFrequencies = myScalogram.frequencies;
           myScales = waveletCentralFrequency*(myFrequencies.^(-1));
           
            myCoefficients = myScalogram.coefficients;
            
            myWaveletName = myScalogram.waveletName;
            myFormFactor = str2double(myScalogram.waveletFormFactor);
            myFs = myScalogram.Fs;
%             plotEnable = str2double(myScalogram.config.Attributes.plotEnable);
            
            [amplitudeFactor, frequencyFactor] = myScalogram.getCorrectionFactors(myWaveletName);
            myScales = myScales/frequencyFactor;
            % Create vector of wavelet energy for normalization of the
            % scalogram coefficients
            waveletEnergy = zeros(size(myScales)); 
            for i = 1:1:length(myScales)
                waveletEnergy(i) = sqrt(sum(feval(myWaveletName,myScales(i),myFs,myFormFactor).^2));
            end
            myCoefficients = amplitudeFactor*(myCoefficients./waveletEnergy);
            
            myNormalizedScalogram.coefficients = myCoefficients;
            myNormalizedScalogram.frequencies = myScalogram.frequencies;
            myNormalizedScalogram.scales = myScales;
            
              % __________________ Plot results ________________________ %%
                if myScalogram.plotEnable == 1
%                     figure('Color', 'w','Visible',myScalogram.plotVisible);
%                     plot(myFrequencies, myCoefficients);
%                     title(['Scalogram Normalized, wavelet: ',myScalogram.waveletName]);
%                     xlabel('Frequency, Hz');
%                     ylabel('Magnitude, m/s^2');
%                     grid on;
                    
% %                     % Save image to the @Out directory
% %                     if myScalogram.printPlotsEnable == 1
% %                         fileName = 'Normalized_Scalogram_Original';
% %                         fullFilePath = fullfile(pwd,'Out');
% %                         fullFileName = fullfile(fullFilePath,fileName);
% %                         print(fullFileName,'-djpeg91', '-r180');
% %                     end

% %                         % Close figure with visibility off
% %                         if strcmpi(myScalogram.plotVisible, 'off')
% %                             close
% %                         end

%                     
                    parameters = myScalogram.config;
                    sizeUnits = parameters.plots.sizeUnits;
                    imageSize = str2num(parameters.plots.imageSize);
                    fontSize = str2double(parameters.plots.fontSize);
                    imageFormat = parameters.plots.imageFormat;
                    imageQuality = parameters.plots.imageQuality;
                    imageResolution = parameters.plots.imageResolution;


                    myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Color','w','Visible', myScalogram.plotVisible);
                    grid on;
                    % Get axes data
                    myAxes = myFigure.CurrentAxes;
                    % Set axes font size
                    myAxes.FontSize = fontSize;
                    
                    cwtTable = myScalogram.cwtTable;

                    dt = 1/myScalogram.Fs*myScalogram.decimationFactor;
                    t = 0:dt:dt*(size(cwtTable,2)-1);
                    surf(t,myScalogram.frequencies/1000,abs(cwtTable));
                    colormap(jet);
                    colorbar;
                    xlabel('Time, s');
                    ylabel('Frequency, kHz');
                    zlabel('Magnitude, m/s^2')
                    
                    az = 110; el = 60;
                    view(az, el);
                    
                    if myScalogram.printPlotsEnable
                        % Save the image to the @Out directory
                        imageNumber = '1';
                        fileName = ['scalogram-3D-acc-' imageNumber];
                        fullFileName = fullfile(pwd, 'Out', fileName);
                        print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
                    end

                    % Close figure with visibility off
                    if strcmpi(myScalogram.plotVisible, 'off')
                        close(myFigure)
                    end                    
                    
                end 
        end
        
    end
    
    methods (Access = private)
        
        % QUADRASPACE function creates log2-scale frequencies array for
        % further scalogram calculation
        [logSpace] = quadraspace(d1, d2, pointsPerOctave, roundingEnable);
        
        % DIVIDEDCWT function calculates cwt-matrix for specific wavelet,
        % but in contradistinction to standard @cwt this funcion divides
        % time-domain signal on the several pieces to minimaze RAM usage 
        % and speed-up calculations
        [cwtCoefficients] = dividedCWT(file,scales,config);
        
        % CREATESCALES function creates 2 types of scale arrays :
        % logarithmic (with basis of 2) or linear (with specific step)
        function [scales, frequencies] = createScales(myScalogram, file)
            
            myConfig = myScalogram.config;
            scaleType = myConfig.Attributes.scaleType;
            sensorHighFrequency = str2double(myConfig.sensor.highFrequency);
            
            switch (scaleType)
                % Use logarithmic scale
                case 'log2'
                    parameters = myConfig.log2.Attributes;
                    lowFrequency = str2double(parameters.lowFrequency);
                    highFrequency = str2double(parameters.highFrequency);
                    frequenciesPerOctave = str2double(parameters.frequenciesPerOctave);
                    roundingEnable = str2double(parameters.roundingEnable);
                    
                    if highFrequency > sensorHighFrequency
                        printWarning(myScalogram.iLoger, 'Scalogram ''highFrequency'' in config.xml is greater than sensor ''highFrequency'''); 
                        highFrequency = sensorHighFrequency;
                    end
                    
                    frequencies  = quadraspace(lowFrequency,highFrequency,frequenciesPerOctave,roundingEnable,'pointsPerOctave')';
                    
                % Use linear scale
                case 'linear'
                    parameters = myConfig.linear.Attributes;
                    lowFrequency = str2double(parameters.lowFrequency);
                    highFrequency = str2double(parameters.highFrequency);
                    frequencyStep = str2double(parameters.frequencyStep);
                    frequenciesNumber = floor((highFrequency-lowFrequency)/frequencyStep);
                    
                    if highFrequency > sensorHighFrequency
                        printWarning(myScalogram.iLoger, 'Scalogram ''highFrequency'' in config.xml is greater than sensor ''highFrequency'''); 
                        highFrequency = sensorHighFrequency;
                    end
                    
                    frequencies = linspace(lowFrequency,highFrequency,frequenciesNumber)';
                    
                otherwise
                    error(['ERROR! There no such scaleType: ', scaleType, ' to build scalogram!']);
            end
            
            % Calculate scales array by formula:
            % -----------------------------------------------
            % -------- scales = 20*Fs/frequencies -----------
            % -----------------------------------------------
            scales = bsxfun(@ldivide,frequencies,20*file.Fs);
            
            % Scales vector correction for current wavelet type
            myWaveletName = myScalogram.waveletName;
            [~,frequencyFactor] = myScalogram.getCorrectionFactors(myWaveletName);
            scales = scales*frequencyFactor;
            
%             % Normalize to scales of the custom wavelet functions
%             scales = 1000*scales/(20*file.Fs);
        end
        
    end
    
    methods (Access = public, Static = true)
       
        % GETCORRECTIONFACTORS function returns correction factor of the
        % certain wavelet type for correction of the scalogram coefficitens
        % (amplitudeFactor) and frequecy vector (frequencyFactor)
        function [amplitudeFactor,frequencyFactor] = getCorrectionFactors(waveletName)
            
            if nargin == 0
               error('The name of the wavelet function is incorrect'); 
            end
            switch(waveletName)
                case 'mexh_morl'
                    amplitudeFactor = 8^(-.25);
                    frequencyFactor = 1;
                case 'morl2'
%                     amplitudeFactor = 2.5^(-0.5);
%                     amplitudeFactor = 1.6^(-0.5);
%                     amplitudeFactor = 0.8916;
%                     frequencyFactor = 1/1.255; 
                        amplitudeFactor = 1/sqrt(2);
                        frequencyFactor = 1; 
                otherwise
                    error(['Wavelet ',waveletName,' is not supported']); 
            end
        end
        
    end
end

