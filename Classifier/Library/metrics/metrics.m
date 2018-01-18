% METRICS function calculates and evaluates metrics of input signal
% 
% INPUT:
% 
% File - structure which contain signal and sampling frequency
% 
% Config - configuration structure
%
% OUTPUT:
% 
% Result - structure which contain metrics values and status (rms, peak,
% peak2peak, peakFactor, crestFactor, kurtosis, excess)
% 
% Developer:              P. Riabtsev
% Development date:       06-01-2017
% 
% Modified by:            P. Riabtsev
% Modification date:      16-01-2017

% Modified by:            K. Kosmach % Added new metrics (unidentifiedPeaksNumbers)
% Modification date:      22-12-2017
function [Result] = metrics(File, Config)

%% ____________________ DEFAULT PARAMETERS _____________________________ %%

if nargin < 2
    Config = [];
end

Config = fill_struct(Config, 'firstSampleNumber', '10');
commonFieldsNames = fieldnames(Config);
for fieldNum = 1 : 1 : length(commonFieldsNames)
    if isfield(Config.(commonFieldsNames{fieldNum, 1}), 'Attributes')
%         Config.(commonFieldsNames{fieldNum, 1}).Attributes = fill_struct(Config.(commonFieldsNames{fieldNum, 1}).Attributes, 'enable', '0');
        Config.(commonFieldsNames{fieldNum, 1}).Attributes = fill_struct(Config.(commonFieldsNames{fieldNum, 1}).Attributes, 'frequencyRange', '');
        Config.(commonFieldsNames{fieldNum, 1}).Attributes = fill_struct(Config.(commonFieldsNames{fieldNum, 1}).Attributes, 'thresholds', '');
    end
end

firstSampleNumber = str2double(Config.firstSampleNumber);

signal = File.signal;
Fs = File.Fs;

%% ____________________ METRICS CALCULATION ____________________________ %%

% ____________________ RMS ____________________ %
% if isfield(Config, 'rms')
%     if str2double(Config.rms.Attributes.enable)
        % Get the frequency ranges to calculate the rms value
        rmsRanges = strsplit(Config.rms.Attributes.frequencyRange, ':');
        if isempty(rmsRanges{1})
            rmsLowFreq = 0;
        else
            rmsLowFreq = str2double(rmsRanges{1});
        end
        if length(rmsRanges) > 1
            if strcmp(rmsRanges{2}, 'Fs')
                rmsHighFreq = Fs;
            else
                rmsHighFreq = str2double(rmsRanges{2});
            end
        else
            rmsHighFreq = Fs;
        end
        % Cut spectrum of the signal
        spectrum = fft(signal);
        df = Fs / length(signal);
        lowPosition = round(rmsLowFreq / df);
        highPosition = round(rmsHighFreq / df);
        spectrum(1 : (lowPosition - 1), : ) = 0;
        spectrum((end - lowPosition + 1) : end, : ) = 0;
        spectrum((highPosition + 1) : (end - highPosition - 1), : ) = 0;
        cutSignal = ifft(spectrum, 'symmetric');
        % Calculate rms
        Result.rms.value = rms(cutSignal(firstSampleNumber : end, 1));
        if isempty(Config.rms.Attributes.thresholds)
            Result.rms.status = [];
        else
            Result.rms.status = metricStatus(Result.rms.value, Config.rms.Attributes.thresholds);
        end
%     else
%         Result.rms.value = [];
%         Result.rms.status = [];
%     end
% else
%     Result.rms.value = [];
%     Result.rms.status = [];
% end

% ____________________ PEAK ____________________ %
% if isfield(Config, 'peak')
%     if str2double(Config.peak.Attributes.enable)
        % Find max and min peaks
        maxPeak = max(signal);
        minPeak = min(signal);
        % Compare max and min peaks
        if abs(maxPeak) < abs(minPeak)
            Result.peak.value = abs(minPeak);
        else
            Result.peak.value = maxPeak;
        end
        if isempty(Config.peak.Attributes.thresholds)
            Result.peak.status = [];
        else
            Result.peak.status = metricStatus(Result.peak.value, Config.peak.Attributes.thresholds);
        end
%     else
%         Result.peak.value = [];
%         Result.peak.status = [];
%     end
% else
%     Result.peak.value = [];
%     Result.peak.status = [];
% end

% ____________________ PEAK2PEAK ____________________ %
% if isfield(Config, 'peak2peak')
%     if str2double(Config.peak2peak.Attributes.enable)
        Result.peak2peak.value = max(signal) - min(signal);
        if isempty(Config.peak2peak.Attributes.thresholds)
            Result.peak2peak.status = [];
        else
            Result.peak2peak.status = metricStatus(Result.peak2peak.value, Config.peak2peak.Attributes.thresholds);
        end
%     else
%         Result.peak2peak.value = [];
%         Result.peak2peak.status = [];
%     end
% else
%     Result.peak2peak.value = [];
%     Result.peak2peak.status = [];
% end

% ____________________ PEAKFACTOR ____________________ %
% if isfield(Config, 'peakFactor')
%     if str2double(Config.peakFactor.Attributes.enable)
        Result.peakFactor.value = max(abs(signal(firstSampleNumber : end, 1))) / Result.rms.value;
        if isempty(Config.peakFactor.Attributes.thresholds)
            Result.peakFactor.status = [];
        else
            Result.peakFactor.status = metricStatus(Result.peakFactor.value, Config.peakFactor.Attributes.thresholds);
        end
%     else
%         Result.peakFactor.value = [];
%         Result.peakFactor.status = [];
%     end
% else
%     Result.peakFactor.value = [];
%     Result.peakFactor.status = [];
% end

% ____________________ CRESTFACTOR ____________________ %
% if isfield(Config, 'crestFactor')
%     if str2double(Config.crestFactor.Attributes.enable)
        Result.crestFactor.value = crestFactor(File, Config);
        if isempty(Config.crestFactor.Attributes.thresholds)
            Result.crestFactor.status = [];
        else
            Result.crestFactor.status = metricStatus(Result.crestFactor.value, Config.crestFactor.Attributes.thresholds);
        end
%     else
%         Result.crestFactor.value = [];
%         Result.crestFactor.status = [];
%     end
% else
%     Result.crestFactor.value = [];
%     Result.crestFactor.status = [];
% end

% ____________________ KURTOSIS ____________________ %
% if isfield(Config, 'kurtosis')
%     if str2double(Config.kurtosis.Attributes.enable)
        Result.kurtosis.value = kurtosis(signal(firstSampleNumber : end, 1));
        if isempty(Config.kurtosis.Attributes.thresholds)
            Result.kurtosis.status = [];
        else
            Result.kurtosis.status = metricStatus(Result.kurtosis.value, Config.kurtosis.Attributes.thresholds);
        end
%     else
%         Result.kurtosis.value = [];
%         Result.kurtosis.status = [];
%     end
% else
%     Result.kurtosis.value = [];
%     Result.kurtosis.status = [];
% end

% ____________________ EXCESS ____________________ %
% if isfield(Config, 'excess')
%     if str2double(Config.excess.Attributes.enable)
        Result.excess.value = kurtosis(signal(firstSampleNumber : end, 1)) - 3;
        if isempty(Config.excess.Attributes.thresholds)
            Result.excess.status = [];
        else
            Result.excess.status = metricStatus(Result.excess.value, Config.excess.Attributes.thresholds);
        end
%     else
%         Result.excess.value = [];
%         Result.excess.status = [];
%     end
% else
%     Result.excess.value = [];
%     Result.excess.status = [];
% end      
        
% ____________________ NOISE ____________________ %        
        Result.noiseLog.value = File.noiseLog;
        if isempty(Config.noiseLog.Attributes.thresholds)
            Result.noiseLog.status = [];
        else
            Result.noiseLog.status = metricStatus(Result.noiseLog.value, Config.noiseLog.Attributes.thresholds);
        end
        
        Result.noiseLinear.value = File.noiseLinear;
        if isempty(Config.noiseLinear.Attributes.thresholds)
            Result.noiseLinear.status = [];
        else
            Result.noiseLinear.status = ...
                metricStatus(Result.noiseLinear.value, Config.noiseLinear.Attributes.thresholds);
        end
        
        if isfield(File, 'envelopeNoiseLog')
            Result.envelopeNoiseLog.value = File.envelopeNoiseLog;
            if isempty(Config.envelopeNoiseLog.Attributes.thresholds)
                Result.envelopeNoiseLog.status = [];
            else
                Result.envelopeNoiseLog.status = ...
                    metricStatus(Result.envelopeNoiseLog.value, Config.envelopeNoiseLog.Attributes.thresholds);
            end
            
            Result.envelopeNoiseLinear.value = File.envelopeNoiseLinear;
            if isempty(Config.envelopeNoiseLinear.Attributes.thresholds)
                Result.envelopeNoiseLinear.status = [];
            else
                Result.envelopeNoiseLinear.status = ...
                    metricStatus(Result.envelopeNoiseLinear.value, Config.envelopeNoiseLinear.Attributes.thresholds);
            end
        end
        
% ____________________ UNIDENTIFIEDPEAKSNUMBERS ____________________ %        
        Result.unidentifiedPeaksNumbers.value = length(File.peaksTable(:, 1));
        if isempty(Config.unidentifiedPeaksNumbers.Attributes.thresholds)
            
            Result.unidentifiedPeaksNumbers.status = [];
        else
            Result.unidentifiedPeaksNumbers.status = metricStatus(Result.unidentifiedPeaksNumbers.value, Config.unidentifiedPeaksNumbers.Attributes.thresholds);
        end
        
        if isfield(File, 'peaksTableEnv')
            
            Result.unidentifiedPeaksNumbersEnvelope.value = length(File.peaksTableEnv(:, 1));
            if isempty(Config.unidentifiedPeaksNumbersEnvelope.Attributes.thresholds)
                Result.unidentifiedPeaksNumbersEnvelope.status = [];
            else
                Result.unidentifiedPeaksNumbersEnvelope.status = ...
                    metricStatus(Result.unidentifiedPeaksNumbersEnvelope.value, Config.unidentifiedPeaksNumbersEnvelope.Attributes.thresholds);
            end
        end
end

% METRICSTATUS function evaluates the value of metric
% 
% INPUT:
% 
% value - value of metric
% 
% thresholdsStr - string of lower, middle and upper thresholds separated
% by character ':'.
% Example: '0.12:2.2:5.4'
% 
% OUTPUT:
% 
% status - status of metric
% status = 'GREEN' | 'YELLOW' | 'ORANGE' | 'RED'
function [status] = metricStatus(value, thresholdsStr)

% Split thresholds into cells
thresholds = strsplit(thresholdsStr, ':');
% Lower threshold
if isempty(thresholds)
    status = [];
    return;
else
    lowerThreshold = str2double(thresholds{1});
end
% Middle threshold
if length(thresholds) < 2
    middleThreshold = [];
else
    middleThreshold = str2double(thresholds{2});
end
% Upper threshold
if length(thresholds) < 3
    upperThreshold = middleThreshold;
    middleThreshold = lowerThreshold;
else
    upperThreshold = str2double(thresholds{3});
end

% Evaluate the value
if value < lowerThreshold
    status = 'GREEN';
elseif (value >= lowerThreshold) && (value < middleThreshold)
    status = 'YELLOW';
elseif (value >= middleThreshold) && (value < upperThreshold)
    status = 'ORANGE';
elseif value >= upperThreshold
    status = 'RED';
else
    status = [];
end

end