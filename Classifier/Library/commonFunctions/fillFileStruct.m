% FILLFILESTRUCT function ...

function [ File ] = fillFileStruct( File, Config, Translations )

%% ____________________ Decimation _____________________________________ %%

% if str2double(Config.decimation.Attributes.processingEnable)
%     Parameters = [];
%     Parameters = Config.decimation.Attributes;
%     File = decimation(File, Parameters);
% end

%% ____________________ Acceleration, Velocity & Displacement __________ %%

Parameters = [];
Parameters.lowFrequency = Config.lowFrequency;
Parameters.rmsFrequencyRange = Config.metrics.velocity.rms.Attributes.frequencyRange;
[File] = acc2velocity(File, Parameters);

Parameters = [];
Parameters.lowFrequency = Config.lowFrequency;
Parameters.rmsFrequencyRange = Config.metrics.displacement.rms.Attributes.frequencyRange;
[File] = velocity2disp(File, Parameters);

%% ____________________ All Spectra Calculation ________________________ %%

File = getAllSpectra(File, Config, Translations);

%% ____________________ Metrics Calculation ____________________________ %%

signalType = {
                'acceleration';
                'velocity';
                'displacement';
             };

for i = 1:numel(signalType)
    File.(signalType{i}).metrics = metricsCalculations(File, Config, signalType{i});
end
         
         
% Calculation of the metrics of the @signalType
function [Result] = metricsCalculations(File, Config, signalType)

    Data.peaksTable = File.(signalType).spectrum.peakTable;
    if strcmpi(signalType, 'acceleration')
        Data.peaksTableEnv = File.acceleration.envelopeSpectrum.peakTable;
    end
    Data.signal = File.(signalType).signal;
    Data.Fs = File.Fs;
    Data.noiseLog = File.(signalType).logSpectrum.noiseLevelLog;
    Data.noiseLinear = File.(signalType).logSpectrum.noiseLevelLinear;
    if isfield(File.(signalType), 'logEnvelopeSpectrum')
        Data.envelopeNoiseLog = File.(signalType).logEnvelopeSpectrum.noiseLevelLog;
        Data.envelopeNoiseLinear = File.(signalType).logEnvelopeSpectrum.noiseLevelLinear;
    end
    
    Parameters = Config.metrics.(signalType);
    Parameters.firstSampleNumber = Config.metrics.Attributes.firstSampleNumber;
    Parameters.secPerFrame = Config.metrics.Attributes.secPerFrame;
    Parameters.secOverlapValue = Config.metrics.Attributes.secOverlapValue;
    Result = metrics(Data, Parameters);



