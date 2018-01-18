% TIMESYNCHRONOUSAVERAGIN function 

% ********************************************************************** %
% Developer     : Kosmach N.
% Date          : 21.11.2017
% Version       : v1.0
% ********************************************************************** %

function File = timeSynchronousAveragingProcessing(File, classifierStruct, mySchemeClassifier, config)

    if nargin < 2
       error('There is no config file for time synchronous averaging!');
    end
%% ______________________ Time synchronous averaging __________________________ %%

    % Set parameters
    parameters = config.config.parameters.evaluation.timeSynchronousAveraging.Attributes;
    parameters.printPlotsEnable = config.config.parameters.common.printPlotsEnable.Attributes.value;
    parameters.visible = config.config.parameters.common.printPlotsEnable.Attributes.visible;
    parameters.title = config.config.parameters.common.printPlotsEnable.Attributes.title;
    parameters.plots = config.config.parameters.evaluation.plots.Attributes;
    parameters.peakComparison = config.config.parameters.evaluation.timeSynchronousAveraging.peakComparison.Attributes;
    parameters.logSpectrum = config.config.parameters.evaluation.timeSynchronousAveraging.logSpectrum.Attributes;
   
    % Add translations
    parameters.plots.translations = File.translations;
    
    % Check schemeClassifier
    if isempty(mySchemeClassifier)
        mySchemeClassifier = schemeClassifier(File, classifierStruct, config);
    end
    
    % Set file
    file.signalAcceleration = File.acceleration.signal;
    file.timeVector = File.acceleration.signal;
    file.Fs =  File.Fs;
    file.spectrumAcceleration = File.acceleration.spectrum.amplitude;
    file.peakTable = File.acceleration.spectrum.peakTable;
    file.frequencyVector = File.acceleration.frequencyVector;
    file.classifierStruct = classifierStruct;
    file.mainFreqStruct = getMainFreqStruct(mySchemeClassifier);
    
    % Processing of time synchronous averaging
    myTimeSynchronousAveraging = timeSynchronousAveraging(file, parameters);
    myTimeSynchronousAveraging = timeSynchronousAveragingCalculate(myTimeSynchronousAveraging);
    myResultTable = getResultTable(myTimeSynchronousAveraging);
    
    % Set result and add to status.xml
    File.timeSynchronousAveragingResult = myResultTable;
end