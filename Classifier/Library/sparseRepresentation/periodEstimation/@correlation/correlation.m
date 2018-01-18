classdef correlation
    %CORRELATION class calculates and stores correlation function of the
    %input signal.
    
    properties (Access = private)
        
    % Input:
        config % Configuration structure
        origSignal
        
    % Output:
        coefficients 
        positions  
        Fs   % Samples frequency
        
        correlationDegree
    end
    
    methods (Access = public)
        
        % Constructor method. Parameter @file = {signal,Fs}
        function [myCorrelation] = correlation(file, myConfig)
           myCorrelation.config = myConfig;
           myCorrelation = create(myCorrelation,file);
           myCorrelation.correlationDegree = isHighCorrelated(myCorrelation);
        end
        
        % Getters / Setters ...
        
        function [myConfig] = getConfig(myCorrelation)
           myConfig = myCorrelation.config;
        end
        function [myCorrelation] = setConfig(myCorrelation, myConfig)
           myCorrelation.config = myConfig;
        end
        
        function [myFs] = getFs(myCorrelation)
           myFs = myCorrelation.Fs;
        end
        function [myCorrelation] = setFs(myCorrelation, myFs)
           myCorrelation.Fs = myFs;
        end
        
        function [myCoefficients] = getCoefficients(myCorrelation)
           myCoefficients = myCorrelation.coefficients;
        end
        function [myPositions] = getPositions(myCorrelation)
           myPositions = myCorrelation.positions;
        end
        function [mySignal] = getOrigSignal(myCorrelation)
           mySignal = myCorrelation.origSignal;
        end
        
        function [myCoefficients, myPositions] = getParameters(myScalogram)
            myCoefficients = myScalogram.coefficients;
            myPositions = myScalogram.positions;
        end
        
        % ... Getters / Setters
        
        % CREATE function calculates correlation coefficients of the input
        % signal with dimentions [-tmax: tmax], where tmax - signal length.
        function [myCorrelation] = create(myCorrelation, file)
            
            minFreq = str2double(myCorrelation.config.Attributes.minFreq);
            minFreqPeriods = str2double(myCorrelation.config.Attributes.minFreqPeriods);
            signal = single(file.signal);
            if ~isnan(minFreqPeriods) && (minFreqPeriods ~= Inf)  %If min freq is assigned.
                minFreq = minFreq/minFreqPeriods;
                maxSample = min([numel(signal) round(file.Fs/minFreq)]);
                signal = signal(1:maxSample);
            end
            signalLength = length(signal)-1;
            myCorrelation.origSignal = signal;
            
            envelopeEnable = str2double(myCorrelation.config.Attributes.envelopeEnable);
            normalizationEnable = str2double(myCorrelation.config.Attributes.normalizationEnable);
%             maxFreq = str2double(myCorrelation.config.Attributes.maxFreq);
            
            if envelopeEnable == 1
%                 % Create low-pass filter to remove pulsations from ACF.
%                 Rp = 1; Rs = 12; % default parameters
%                 Wp = maxFreq*(2/file.Fs);
%                 Ws = (maxFreq*1.2)*(2/file.Fs);  
%                 [~, Wn] = buttord(Wp, Ws, Rp, Rs);
%                 [b, a] = butter(4, Wn, 'low');
%                 %Use filter in case of limited max freq. In other case use
%                 %usual envelope calculation function.
%                 if maxFreq ~= Inf
%                     signal = filtfilt(b, a, file.signal);
%                     myCoefficients = abs(xcorr(signal));
%                 else
%                     myCoefficients = envelope(real(xcorr(signal)));
%                 end
                myCoefficients = envelope(real(xcorr(signal)));
            else
                myCoefficients = abs(xcorr(signal));
            end
            
            if normalizationEnable == 1
                myCoefficients = myCoefficients/max(myCoefficients);
            end
            
            dt = 1/file.Fs;
            myPositions = linspace(-signalLength,signalLength,2*signalLength+1)'*dt;
            
            myCorrelation.coefficients = myCoefficients;
            myCorrelation.positions = myPositions;
            myCorrelation.Fs = file.Fs;
        end
        
        % GETONESIDEPARAMETERS function returns only one side of
        % correlation coefficients, i.m. [0:tmax] instead [-tmax: tmax].
        function [oneSideCoefficients,oneSidePositions, myFs] = getOneSideParameters(myCorrelation)
            
            if isempty(myCorrelation.coefficients)
               myCorrelation = create(myCorrelation); 
            end
            
            myCoefficients = myCorrelation.coefficients;
            myCoefficients = reshape(myCoefficients, numel(myCoefficients), []);
            myPositions = myCorrelation.positions;
            
            originLength = length(myCoefficients);
            start = (originLength-1)/2;
            
            oneSideCoefficients = myCoefficients(start:end,1);
            oneSidePositions = myPositions(start:end,1);
            myFs = myCorrelation.Fs;
        end
        
        % Test gag. Mb it would be useful;
        function [ myCorrelationDegree ] = isHighCorrelated(myCorrelation)
           
           [myCoefficients] = getOneSideParameters(myCorrelation);
           
           rmsHigh = rms(myCoefficients(1:200,1));
           rmsLow = rms(myCoefficients(201:5000,1));
           rmsRatio = rmsHigh/rmsLow;
           
           % Here should be fuzzy-logic
           if rmsRatio > 30
               myCorrelationDegree = 'low';
           else
               myCorrelationDegree = 'high';
           end
        end
    end
    
end

