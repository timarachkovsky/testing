% GETALLSPECTRA description
% developer : ASLM
% data      : 01/06/2017

function [ File ] = getAllSpectra( File, Config, Translations )
    
    iLoger = loger.getInstance;
    
    Config = fill_struct(Config, 'parpoolEnable', '0');
    
    signalType = {
                    'acceleration';
                    'velocity';
                    'displacement';
                 };

    Result = cell(size(signalType));
    imagesNames = cell(size(signalType));

    if str2double(Config.parpoolEnable) == 1
        parfor i = 1 : numel(signalType)
            [Result{i}, imagesNames{i}] = spectrumCalculations(File, Config, Translations, signalType{i});
        end
    else
        for i = 1 : numel(signalType)
            [Result{i}, imagesNames{i}] = spectrumCalculations(File, Config, Translations, signalType{i});
        end
    end
    
    allImagesNames = [];
    for i = 1 : numel(signalType)
        File.(signalType{i}) = Result{i}.(signalType{i});
        allImagesNames = [allImagesNames; imagesNames{i}];
    end
    if checkImages(fullfile(pwd, 'Out'), allImagesNames, Config.plots.Attributes.imageFormat)
        printComputeInfo(iLoger, 'getAllSpectra', 'The method images were saved.')
    end
end


% SPECTRUMCALCULATIONS function computes the following data:
%
% acceleration -->  spectrum
%                   logSpectrum
%                   envelopeSpectrum
%                   logEnvelopeSpectrum
%                   octaveSpectrum
%
% velocity     -->  spectrum
% (displacement)    logSpectrum
%
function [Result, imageNames] = spectrumCalculations(File, Config, Translations, signalType)
    
    Result.(signalType) = File.(signalType);
    
    % Calculate SPECTRUM and ENVELOPE SPECTRUM of signalType
    Parameters = [];
    Parameters = Config.spectra.envSpectrum.Attributes;
    Parameters.plots = Config.plots.Attributes;
    Parameters.printPlotsEnable = Config.printPlotsEnable;
    Parameters.plotVisible = Config.plotVisible;
    Parameters.plotTitle = Config.plotTitle;
    Parameters.parpoolEnable = Config.parpoolEnable;
    Parameters.highFrequencyDevice = Config.highFrequency;
    Parameters.spectrumRange = Config.spectra.Attributes.([signalType,'Range']);
    
    
    Data = [];
    Data.signal = File.(signalType).signal;
    Data.Fs = File.Fs;
    
%     [spectrumStruct, envSpectrumStruct, frequencyVector, df, imageNames] = envSpectrum(Data, Parameters, Translations, signalType);
    
    if strcmp(signalType, 'acceleration') && ~isfield(File.(signalType), 'envelopeSignal') % acceleration without resampling
        [spectrumStruct, envSpectrumStruct, frequencyVector, df, imageNames] = envSpectrum(Data, Parameters, Translations, signalType);
        
    elseif strcmp(signalType, 'acceleration') && isfield(File.(signalType), 'envelopeSignal') % acceleration with resampling
        [spectrumStruct, frequencyVector, df, imageNames] = spectrum1(Data, Parameters, Translations, signalType);
        
        Data = [];
        Data.signal = File.(signalType).envelopeSignal;
        Data.Fs = File.Fs;
        [envSpectrumStruct, ~, ~, envImageNames] = spectrum1(Data, Parameters, Translations, 'envelope');
        imageNames = [imageNames; envImageNames];
    else % velocity & displacement
        [spectrumStruct, frequencyVector, df, imageNames] = spectrum1(Data, Parameters, Translations, signalType);
    end
    
    
%     Data = [];
%     Data.signal = File.(signalType).signal;
%     Data.Fs = File.Fs;
%     
    % Write results to File-structure
    Result.(signalType).frequencyVector = frequencyVector;
    Result.(signalType).df = df;
    Result.(signalType).spectrum = spectrumStruct;
    
    % Calculate logarithmic SPECTRUM of acceleration and it noise level
    Data = [];
    Data.signal = Result.(signalType).signal;
    Data.spectrum = Result.(signalType).spectrum.amplitude;
    Data.frequencies = Result.(signalType).frequencyVector;
    Data.Fs = File.Fs;
    Parameters = [];
    Parameters = Config.spectra.logSpectrum.Attributes;
    Parameters.plots = Config.plots.Attributes;
    Parameters.plotVisible = Config.plotVisible;
    Parameters.spectrumRange = Config.spectra.Attributes.([signalType,'Range']);
    [LogSpectrumStruct, noiseLevelVector, peakTable] = logSpectrum(Data, Parameters, signalType);
    % Write results to File-structure
    Result.(signalType).logSpectrum = LogSpectrumStruct;
    Result.(signalType).spectrum.noiseLevelVector = noiseLevelVector;
    Result.(signalType).spectrum.peakTable = peakTable;

    switch(signalType)
        case 'acceleration'
            
            Result.(signalType).envelopeSpectrum = envSpectrumStruct;
    
            % Calculate logarithmic ENVELOPE SPECTRUM of acceleration and it noise level
            Data.signal = Result.(signalType).signal;
            Data.spectrum = Result.(signalType).envelopeSpectrum.amplitude;
            Data.frequencies = Result.(signalType).frequencyVector;
            Data.Fs = File.Fs;
            Parameters = [];
            Parameters = Config.spectra.logSpectrum.Attributes;
            Parameters.plots = Config.plots.Attributes;
            Parameters.plotVisible = Config.plotVisible;
            Parameters.spectrumRange = Config.spectra.Attributes.([signalType,'Range']);
            [LogEnvelopeSpectrumStruct, noiseLevelVector, peakTable] = logSpectrum(Data, Parameters, signalType);
            % Write results to File-structure
            Result.(signalType).logEnvelopeSpectrum = LogEnvelopeSpectrumStruct;
            Result.(signalType).envelopeSpectrum.noiseLevelVector = noiseLevelVector;
            Result.(signalType).envelopeSpectrum.peakTable = peakTable;

            % Calculate octave spectrum of acceleration
            Data = [];
            Data.signal = Result.(signalType).signal;
            Data.Fs = File.Fs;
            Parameters = [];
            Parameters = Config.spectra.octaveSpectrum.Attributes;
            Parameters.octaveSpectrumEnable = Config.octaveSpectrumEnable;
            Parameters.plots = Config.plots.Attributes;
            Parameters.printPlotsEnable = Config.printPlotsEnable;
            Parameters.plotVisible = Config.plotVisible;
            Parameters.plotTitle = Config.plotTitle;
            Parameters.historyEnable = Config.historyEnable;
            Parameters.parpoolEnable = Config.parpoolEnable;
            OctaveSpectrumStruct = octaveSpectrumProcessing(Data, Parameters, Translations);
            % Write results to File-structure
            Result.(signalType).octaveSpectrum = OctaveSpectrumStruct;
            
    end
end

