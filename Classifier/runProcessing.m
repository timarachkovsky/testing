function runProcessing

clear all; clearvars;
% Start timer ticing

tStart = tic;
clc; 
close all; 
fclose('all');

if ~isdeployed % Developer mode
    Root = fileparts(mfilename('fullpath'));
    cd(Root);
    startup
end

try
%% ______________________ Initialization ______________________________ %%
   
   tInitializationStart = tic;

   [File,config,equipmentProfile,informativeTags,Translations,files,signalStates] = initialization();
   iLoger = loger.getInstance;
   myStatusWriter = statusWriter.getInstance;
   
   timeData.initialization = toc(tInitializationStart);
   
%% ________________________ Run Parpool _______________________________ %%
    
    tParpoolStartup = tic;

    if str2double(config.config.parameters.common.parpoolEnable.Attributes.value)
        
        printProgress(iLoger, 'Parpool Start-up');
        
        poolobj = gcp('nocreate');
        if isempty(poolobj)
            myCluster = parcluster('local');
            maxPoolSize = myCluster.NumWorkers;
            poolobj = parpool(maxPoolSize); 
        end
        
        iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.parpoolEnable.Attributes.weight));
        printComputeInfo(iLoger, 'Parpool Start-up', 'Parpool Start-up COMPLETE.');
        
    else
        poolobj = gcp('nocreate');
        if ~isempty(poolobj)
            delete(poolobj);
        end
    end
    
    timeData.parpoolStartup = toc(tParpoolStartup);
    
%% ____________ Frequency Tracking & Signal Resampling _______________ %%

    
    if str2double(config.config.parameters.common.frequencyTrackingEnable.Attributes.value)
        
        tFrequencyTracking = tic;
        
        printProgress(iLoger, 'Frequency Tracking');
        
        Parameters = [];
        Parameters = config.config.parameters.evaluation.frequencyTracking;
        Parameters.printPlotsEnable = config.config.parameters.common.printPlotsEnable.Attributes.value;
        Parameters.plotVisible = config.config.parameters.common.printPlotsEnable.Attributes.visible;
        Parameters.plotTitle = config.config.parameters.common.printPlotsEnable.Attributes.title;
        Parameters.parpoolEnable = config.config.parameters.common.parpoolEnable.Attributes.value;
        Parameters.translations = Translations;
        Parameters.plots = config.config.parameters.evaluation.plots.Attributes;
        Parameters.debugModeEnable = config.config.parameters.common.debugModeEnable.Attributes.value;
        Parameters.filtering = config.config.parameters.evaluation.spectra.envSpectrum.Attributes;
        [File, frequencyTrack] = frequencyTracking(File, Parameters);
%         [File] = test_frequencyTracking(File, Parameters);
        
        testReportTagWriter.frequencyTrackingResultexist(File, iLoger)  %A. Bourak added for autotesting 02.11.2017
        
        iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.frequencyTrackingEnable.Attributes.weight));
        printComputeInfo(iLoger, 'Frequency Tracking', 'Frequency Tracking COMPLETE.');
        
        timeData.frequencyTracking = toc(tFrequencyTracking);
        
    end
    
    
%% _________ Acceleration, velocity & displacement calculation ________ %%
    
    tSpectraCalculationStart = tic;
    printProgress(iLoger, 'Filling File-structure');
    
    Parameters = [];
    Parameters.printPlotsEnable = config.config.parameters.common.printPlotsEnable.Attributes.value;
    Parameters.plotVisible = config.config.parameters.common.printPlotsEnable.Attributes.visible;
    Parameters.plotTitle = config.config.parameters.common.printPlotsEnable.Attributes.title;
    Parameters.parpoolEnable = config.config.parameters.common.parpoolEnable.Attributes.value;
    Parameters.lowFrequency = config.config.parameters.sensor.Attributes.lowFrequency;
    Parameters.highFrequency = config.config.parameters.sensor.Attributes.highFrequency;
    Parameters.spectra = config.config.parameters.evaluation.spectra;
    Parameters.metrics = config.config.parameters.evaluation.metrics;
    Parameters.equipmentClass = equipmentProfile.equipmentProfile.Attributes.equipmentClass;
    Parameters.historyEnable = config.config.parameters.common.historyEnable.Attributes.value;
    Parameters.octaveSpectrumEnable = config.config.parameters.common.octaveSpectrumEnable.Attributes.value;
    Parameters.plots = config.config.parameters.evaluation.plots;
    
    File = fillFileStruct(File, Parameters, Translations);
    File.informativeTags = informativeTags;
    File.translations = Translations;
    
    testReportTagWriter.commonSpectrumsResultexist(File, iLoger);
    testReportTagWriter.octaveSpectrumResultexist(File, iLoger);
    testReportTagWriter.metricsResultexist(File, iLoger);
    
    iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.commonFunctions.Attributes.fillFileStructWeight));
    printComputeInfo(iLoger, 'Filling File-structure', 'Filling File-structure COMPLETE.');
    timeData.spectraCalculation = toc(tSpectraCalculationStart);
    
%% ******************************************************************** %%
%% ************************ MAIN_CACLULATIONS ************************* %%
%% ******************************************************************** %%  
    
%% _____________________ EQUIPMENT_PROFILE_PARSER______________________ %%
    
    printProgress(iLoger, 'Equipment parser');
    
    equipmentDataPoint = files.files.Attributes.equipmentDataPoint;
    % Parse kinematics
    myProfileParser = equipmentProfileParser(equipmentProfile, equipmentDataPoint);
    % Get nominal shaft frequency
    shaftFreqNominal = getShaftFreq(myProfileParser);
    
    iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.commonFunctions.Attributes.hardwareProfileParserWeight));
    printComputeInfo(iLoger, 'Equipment parser', 'Parsing of kinematics COMPLETE.');
    
%% _________________________ Create base docNode ______________________ %%
    
	classifierStruct = getClassifierStruct(myProfileParser);
    Parameters = [];
    Parameters.nameTempStatusFile = config.config.parameters.evaluation.statusWriter.Attributes.nameTempStatusFile;
    Parameters.version = config.config.Attributes.version;
    Parameters.idEquipmentProfile = equipmentProfile.equipmentProfile.Attributes;
    Parameters.signalStates = signalStates;
    myStatusWriter = addData('createBaseDocNode', myStatusWriter, classifierStruct, Parameters);
    
    if str2double(config.config.parameters.common.frequencyTrackingEnable.Attributes.value)
        myStatusWriter = addData('frequencyTracking', myStatusWriter, frequencyTrack);
    end
    
%% ____________________ EQUIPMENT_STATE_DETECTION _____________________ %%
    
    if str2double(config.config.parameters.common.equipmentStateDetectionEnable.Attributes.value)
        
        printProgress(iLoger, 'Equipment state detection');
        
        % Detect the equipment state by thresholds
        [equipmentState, equipmentStateData] = equipmentStateDetection(File, config);
        
        testReportTagWriter.equipmentStateResulexist(equipmentState, equipmentStateData, iLoger) %A. Bourak added for autotesting 02.11.2017
        
        % Add data to the docNode element
        myStatusWriter = addData('equipmentStateDetection', myStatusWriter, equipmentState, equipmentStateData);
        
        iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.equipmentStateDetectionEnable.Attributes.weight));
        printComputeInfo(iLoger, 'Equipment state detection', 'Equipment state detection COMPLETE.');
    end
    
%% _________________________ FREQUENCY_CORRECTOR ______________________ %%

    if str2double(config.config.parameters.common.frequencyCorrectionEnable.Attributes.value)
        
        tFrequencyRefinementStart = tic;
        
        printProgress(iLoger, 'Frequency refinement');
        origFreqVect = getShaftVector(myProfileParser);
        
        myFrequencyCorrector = frequencyCorrector(File, myProfileParser, struct('config', config.config, 'Translations', Translations));
        myFrequencyCorrector = frequencyCorrection(myFrequencyCorrector);
        myProfileParser = getKinematicsParser(myFrequencyCorrector);
        
        estimFreqVect = getShaftVector(myProfileParser);
        classifierStruct = getClassifierStruct(myProfileParser);
        myResult = getResult(myFrequencyCorrector);
        try
            correctFlag = 1;
            emptiesNum = nnz([isempty(myResult.frequencies) isempty(myResult.validities) isempty(myResult.frequency) isempty(myResult.validity)]);
            if (emptiesNum < 4) && (emptiesNum > 0)
                correctFlag = 0;
            elseif emptiesNum == 0
                %Check numeric fields and fields number.
                numericF = {'frequencies', 'validities', 'frequency', 'validity'};
                correctFlag = resTest(myResult, struct('fieldsNumber', 12, 'numericFields', {numericF}, 'rowFields', {numericF([1 2])}, 'compStageString', 'frequency corrector decision maker'), iLoger);
            end
            %One-valued frequency checking.
            if correctFlag
                if (numel(myResult.frequency) > 1) || (numel(myResult.validity) > 1)
                    correctFlag = 0;
                    printComputeInfo(iLoger, 'Frequency correction', 'One-valued frequency mismatch.');
                end
            end
            if correctFlag
                printComputeInfo(iLoger, 'Frequency correction', 'Result of frequency correction has a correct format.');
            else
                printComputeInfo(iLoger, 'Frequency correction', 'Result of frequency correction has wrong format.');
            end
        catch
            printComputeInfo(iLoger, 'Frequency correction', 'Self-test error.');
        end
        
        [myStatusWriter] = addData ('frequencyCorrector', myStatusWriter,origFreqVect,estimFreqVect,myResult);
		
        iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.frequencyCorrectionEnable.Attributes.weight));
        printComputeInfo(iLoger, 'Frequency correction', 'Frequency correction COMPLETE.');
        
        timeData.frequencyRefinement = toc(tFrequencyRefinementStart);

    end

%% ________________________ Shaft Imbalance Detection _________________ %%
    
    myDisPlot.result.status = [];
    if str2double(config.config.parameters.common.shaftTrajectoryDetectionEnable.Attributes.value)
        
        tShaftTrajectoryDetection = tic;
        printProgress(iLoger, 'Shaft trajectory analysis');
        if ~exist('myFrequencyCorrector', 'var')
            myFrequencyCorrector = [];
        end
        
        if (str2double(config.config.parameters.sensor.Attributes.channelsNumber) == 2) && (isfield(File.acceleration, 'secondarySignal'))
            %disPlotParams = struct('windowLenMin', '5maxPer', 'windows', '1:48000;48001:96000;96001:144000', 'filtMeth', 'decim', 'fullSavingEnable', '1');
            Parameters = config.config.parameters.evaluation.shaftTrajectoryDetection.Attributes;
            Parameters.printPlotsEnable = config.config.parameters.common.printPlotsEnable.Attributes.value;
            Parameters.plotVisible = config.config.parameters.common.printPlotsEnable.Attributes.visible;
            Parameters.plots = config.config.parameters.evaluation.plots.Attributes;
            Parameters.debugModeEnable = config.config.parameters.common.debugModeEnable.Attributes.value;
            Parameters.Translations = Translations;
            myDisPlot = displacementPlot(File, Parameters, myFrequencyCorrector);
            myDisPlot = compResult(myDisPlot);
            plotTrace(myDisPlot);
            [myStatusWriter] = addData('shaftTrajectory', myStatusWriter, myDisPlot.result);
        end
        printComputeInfo(iLoger, 'Shaft trajectory detection', 'Shaft trajectory detection COMPLETE.');
        iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.shaftTrajectoryDetectionEnable.Attributes.weight));
        
        timeData.shaftTrajectoryDetection = toc(tShaftTrajectoryDetection);
    end
    
%% _____________________ FREQUENCY-DOMAIN CLASSIFIER __________________ %%
        
    if str2double(config.config.parameters.common.frequencyDomainClassifierEnable.Attributes.value)
        
        tFrequencyDomainClassifierStart = tic;
        
        printProgress(iLoger, 'Frequency-domain classifier');
        
        % Create structure for classifier configuration consisting of
        % scheme elements and their parameters
        mySchemeClassifier = schemeClassifier(File, classifierStruct, config);
        [mySchemeClassifier, unidentifiedPeaksNumbers] = createStatusStruct(mySchemeClassifier);
        [myStatusWriter.docNode] = fillDocNode(mySchemeClassifier,myStatusWriter.docNode);
        if str2double(config.config.parameters.evaluation.frequencyDomainClassifier.Attributes.plotEnable)
            saveStatusImages(mySchemeClassifier, File);
        end
        iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.frequencyDomainClassifierEnable.Attributes.weight));
        printComputeInfo(iLoger, 'Frequency-domain classifier', 'Processing of the Frequency-domain classifier is COMPLETE.');
        
        timeData.frequencyDomainClassifier = toc(tFrequencyDomainClassifierStart);
        
    else
        mySchemeClassifier = [];
        unidentifiedPeaksNumbers = [];
    end
    
%% ________________________ TIME-DOMAIN PROCESSING ____________________ %%  
    
    if isfield(File.acceleration,'signalOrigin')
        File.signal = File.acceleration.signalOrigin;
    else
        File.signal = File.acceleration.signal;
    end
    File.Fs = File.Fs;
    File.translations = Translations;
    File.elementsList = getEquipmentComponentsList(myProfileParser);
    
    periodicityTable = [];
    myTimeFrequencyClassifier = [];
    filteredSignal = [];
    patternResult = [];
    scalogramData = [];
    if str2double(config.config.parameters.common.timeDomainClassifierEnable.Attributes.value) || ...
       str2double(config.config.parameters.common.timeFrequencyDomainClassifierEnable.Attributes.value)
   
        printProgress(iLoger, 'Time-domain Processing');
        
        %% ___________________ Scalogram Calculations _________________ %%
        
        if str2double(config.config.parameters.evaluation.scalogramHandler.Attributes.processingEnable)
            
            tScalogramProcessingStart = tic;
            printProgress(iLoger, 'Scalogram calculation');
            
            Parameters = [];
            Parameters = config.config.parameters.evaluation.scalogramHandler;
            Parameters.Attributes.parpoolEnable = config.config.parameters.common.parpoolEnable.Attributes.value;
            Parameters.Attributes.printPlotsEnable = config.config.parameters.common.printPlotsEnable.Attributes.value;
            Parameters.Attributes.plotVisible = config.config.parameters.common.printPlotsEnable.Attributes.visible;
            Parameters.Attributes.plotTitle = config.config.parameters.common.printPlotsEnable.Attributes.title;
            Parameters.plots = config.config.parameters.evaluation.plots.Attributes;
            Parameters.sensor = config.config.parameters.sensor.Attributes;
            
            myScalogramHandler = scalogramHandler(File, Parameters);
             
            [scalogramData, fullScalogramData, octaveScalogram] = getDecompositionCoefficients(myScalogramHandler);
%             save(fullfile(pwd,'scalogramData.mat'),'scalogramData'); % for @batchProcessing
            try
                scalNumericF = {'frequencies', 'scales', 'coefficients', 'height', 'width', 'prominence', 'globality', 'energy', 'validity', 'lowFrequency', 'highFrequency', 'energyContribution'};
                fullNumericF = {'frequencies', 'coefficients', 'scales'}; octvNumericF = fullNumericF(1:2);
                if isempty(scalogramData)
                    scalFlag = 1;
                else
                    scalFlag = arrayfun(@(x) resTest(x, struct('fieldsNumber', 14, 'numericFields', {scalNumericF}, 'compStageString', 'Scalogram calculation'), iLoger), scalogramData);
                end
                if isempty(scalogramData)
                    fullFlag = 0;
                    printComputeInfo(iLoger, 'Scalogram calculation', 'Data format mismatch: full scalogram data is empty.');
                else
                    fullFlag = arrayfun(@(x) resTest(x, struct('fieldsNumber', 9, 'numericFields', {fullNumericF}, 'colFields', {fullNumericF}, 'compStageString', 'Scalogram calculation'), iLoger), fullScalogramData);
                end
                if isempty(scalogramData)
                    octvFlag = 0;
                    printComputeInfo(iLoger, 'Scalogram calculation', 'Data format mismatch: octave scalogram data is empty.');
                else
                    octvFlag = arrayfun(@(x) resTest(x, struct('fieldsNumber', 2, 'numericFields', {octvNumericF}, 'rowFields', {octvNumericF}, 'compStageString', 'Scalogram calculation'), iLoger), octaveScalogram);
                end
                correctFlag = logical(prod(scalFlag)*prod(fullFlag)*prod(octvFlag));
                if correctFlag
                    printComputeInfo(iLoger, 'Scalogram calculation', 'Result of scalogram calculation has a correct format.');
                else
                    printComputeInfo(iLoger, 'Scalogram calculation', 'There is wrong format of result of scalogram calculation.');
                end
            catch
                printComputeInfo(iLoger, 'Scalogram calculation', 'Self test error.');
            end

			[myStatusWriter] = addData ('scalogram', myStatusWriter,myScalogramHandler,octaveScalogram);
            
			iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.timeDomainClassifierEnable.Attributes.scalogramWeight));
            printComputeInfo(iLoger, 'Scalogram calculation', 'Scalogram calculation is COMPLETE.');
            
            timeData.scalogramProcessing = toc(tScalogramProcessingStart);
        end
        
        %% ____________________ Periodicity Checking __________________ %%
        
        if str2double(config.config.parameters.evaluation.periodicityProcessing.Attributes.processingEnable)
            
            tPeriodicityProcessingStart = tic;
            printProgress(iLoger, 'Search for periodicities in time-domain');
            
            File.signal = File.acceleration.signal;
            
            parameters = config.config.parameters.evaluation.periodicityProcessing;
            parameters.Attributes.parpoolEnable = config.config.parameters.common.parpoolEnable.Attributes.value;
            parameters.Attributes.printPlotsEnable = config.config.parameters.common.printPlotsEnable.Attributes.value;
            parameters.Attributes.plotVisible = config.config.parameters.common.printPlotsEnable.Attributes.visible;
            parameters.Attributes.plotTitle = config.config.parameters.common.printPlotsEnable.Attributes.title;
            parameters.plots = config.config.parameters.evaluation.plots.Attributes;
            parameters.loger = config.config.parameters.evaluation.loger;
            parameters.debugModeEnable = config.config.parameters.common.debugModeEnable.Attributes.value;
            
            [periodicityTable, resultForDocNode, filteredSignal] = periodicityProcessing(File, scalogramData, parameters, iLoger);

			[myStatusWriter] = addData ('periodicity', myStatusWriter,resultForDocNode);

            printComputeInfo(iLoger, 'Search for periodicities in time-domain', 'Search for periodicities in time-domain is COMPLETE.');
            timeData.periodicityProcessing = toc(tPeriodicityProcessingStart);
        end
                
        %% ______________ Time-Domain Pattern Classifier ______________ %%
        if str2double(config.config.parameters.common.timeDomainClassifierEnable.Attributes.value) && (~isempty(scalogramData))
            
            tTimeDomainClassifierStart = tic;
            
            printProgress(iLoger, 'Time-domain pattern Classifier');    
            
            if isfield(File.acceleration, 'signalOrigin')
                File.signal = File.acceleration.signalOrigin;
            else
                File.signal = File.acceleration.signal;
            end
            
            parameters = config.config.parameters.evaluation.timeDomainClassifier;
            parameters.Attributes.printPlotsEnable = config.config.parameters.common.printPlotsEnable.Attributes.value;
            parameters.Attributes.plotVisible = config.config.parameters.common.printPlotsEnable.Attributes.visible;
            parameters.Attributes.plotTitle = config.config.parameters.common.printPlotsEnable.Attributes.title;
            parameters.Attributes.parpoolEnable = config.config.parameters.common.parpoolEnable.Attributes.value;
            parameters.Attributes.debugModeEnable = config.config.parameters.common.debugModeEnable.Attributes.value;
            parameters.plots = config.config.parameters.evaluation.plots.Attributes;
            parameters.translations = Translations;
            
%             [patternResult, BFSpectrumResult] = timeDomainClassification (File, scalogramData, periodicityTable, parameters);
            [patternResult] = timeDomainClassification (File, scalogramData, periodicityTable, parameters);

            [myStatusWriter] = addData ('timeDomainClassifier', myStatusWriter, patternResult);
%             [myStatusWriter] = addData ('BFSpectrum', myStatusWriter, BFSpectrumResult);
            
            iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.timeDomainClassifierEnable.Attributes.weight));
            printComputeInfo(iLoger, 'Time-domain pattern Classifier', 'Time-domain pattern classification is COMPLETE.');
            
            timeData.timeDomainClassifier = toc(tTimeDomainClassifierStart);
            
        end
        
        %% ____________________ Time-Frequency Classifier _____________ %%
        if str2double(config.config.parameters.common.timeFrequencyDomainClassifierEnable.Attributes.value)
            
            tTimeFrequencyDomainClassifierStart = tic;
            
            printProgress(iLoger, 'Time-frequency domain Classifier');    
            
            file = [];
            file.File = File;
            file.classifierStruct = classifierStruct;
            file.periodicityTable = periodicityTable;
            file.filteredSignalCwt = filteredSignal;
            file.scalogramData = scalogramData;

            myTimeFrequencyClassifier = timeFrequencyClassifier(file, config);
            myTimeFrequencyClassifier = processingClassifier(myTimeFrequencyClassifier);
            if str2double(config.config.parameters.evaluation.timeFrequencyDomainClassifier.Attributes.plotEnable)
                saveStatusImages(myTimeFrequencyClassifier, File)
            end
            
            myStatusWriter.docNode = fillDocNode(myTimeFrequencyClassifier, myStatusWriter.docNode);
            
            testReportTagWriter.timeFrequencyClassifierResultexist(myTimeFrequencyClassifier, iLoger)
            
            iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.timeFrequencyDomainClassifierEnable.Attributes.weight));
            printComputeInfo(iLoger, 'Time-frequency domain Classifier', 'Processing of the Time-frequency Classifier is COMPLETE.');
            
            timeData.timeFrequencyDomainClassifier = toc(tTimeFrequencyDomainClassifierStart);
            
        end
        
    end
      
    if ~exist('fullScalogramData', 'var') %Contains scalogram coeffs, freq vectors; scalogramData = validPeaks.
        fullScalogramData = []; octaveScalogram = [];
    end
    if str2double(config.config.parameters.common.spectralKurtosisEnable.Attributes.value)
        printProgress(iLoger, 'Spectral kurtosis computing');
        parameters = config.config.parameters.evaluation.spectralKurtosis.Attributes;
        parameters.plots = config.config.parameters.evaluation.plots.Attributes;
        parameters.translations = Translations;
        parameters.plots.printPlotsEnable = config.config.parameters.common.printPlotsEnable.Attributes.value;
        parameters.plots.plotVisible = config.config.parameters.common.printPlotsEnable.Attributes.visible;
        parameters.debugModeEnable = config.config.parameters.common.debugModeEnable.Attributes.value;
        parameters.minSensorFreq = config.config.parameters.sensor.Attributes.lowFrequency;
        parameters.maxSensorFreq = config.config.parameters.sensor.Attributes.highFrequency;
        parameters.log2 = config.config.parameters.evaluation.spectralKurtosis.log2;
        parameters.linear = config.config.parameters.evaluation.spectralKurtosis.linear;
        parameters.shortSignal = config.config.parameters.evaluation.spectralKurtosis.shortSignal;
        mySpKurtFilt = spectralKurtosisFilter(fill_struct(File, 'fullScalogramData', fullScalogramData), parameters);
        mySpKurtFilt = filtSignal(mySpKurtFilt);
        myResultKurt = getResult(mySpKurtFilt);
        iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.spectralKurtosisEnable.Attributes.weight));
        printComputeInfo(iLoger, 'Spectral kurtosis computing', 'Processing of the spectral kurtosis is COMPLETE.');
    end
        
%% _________________________ Time synchronous averaging __________________________ %%
    
    if str2double(config.config.parameters.common.timeSynchronousAveragingEnable.Attributes.value)
        
        tTimeSynchronousAveraging = tic;
        printProgress(iLoger, 'Time Synchronous Averaging');
        
        File = timeSynchronousAveragingProcessing(File, classifierStruct, mySchemeClassifier, config);
        myStatusWriter = addData('timeSynchronousAveraging', myStatusWriter, File.timeSynchronousAveragingResult);
        
        iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.timeSynchronousAveragingEnable.Attributes.weight));
        printComputeInfo(iLoger, 'Time Synchronous Averaging', 'Time synchronous averaging COMPLETE.');
        timeData.timeSynchronousAveraging = toc(tTimeSynchronousAveraging);
        
    end
    
%% _________________________ ISO10816_METHOD __________________________ %%
    
    structureIso10816.enable = str2double(config.config.parameters.common.iso10816Enable.Attributes.value);
    if structureIso10816.enable
        tiso10816Start = tic;
        printProgress(iLoger, 'ISO10816 method');
        structureIso10816.equipmentClass = equipmentProfile.equipmentProfile.Attributes.equipmentClass;
        [structureIso10816.status, structureIso10816.thresholds] = iso10816(File.velocity.metrics.rms.value, structureIso10816.equipmentClass);
        structureIso10816.value = File.velocity.metrics.rms.value;
        testReportTagWriter.iso10816Resultexist(structureIso10816, iLoger);
        
        iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.iso10816Enable.Attributes.weight));
        printComputeInfo(iLoger, 'Filling metrics', 'ISO10816 method calculation is COMPLETE.'); %RTG: Used for auto-testing
        timeData.iso10816 = toc(tiso10816Start);
    else
        structureIso10816.status = [];
    end
    
%% ____________________ ISO7919_METHOD ________________________________ %%
    
    if str2double(config.config.parameters.common.iso7919Enable.Attributes.value)
        tiso7919Start = tic;
        printProgress(iLoger, 'ISO7919 method');
        dispPeak2PeakValue = File.displacement.metrics.peak2peak.value;
        standardPart = [];
        if isfield(config.config.parameters.evaluation.iso7919.Attributes, 'standardPart')
            standardPart = config.config.parameters.evaluation.iso7919.Attributes.standardPart;
        end
        structureIso7919 = iso7919Processing(classifierStruct.shaftStruct.shaft, dispPeak2PeakValue, standardPart);
        if ~isempty(structureIso7919)
            [myStatusWriter] = addData('iso7919', myStatusWriter, structureIso7919);
        end
        testReportTagWriter.iso7919ResultExist(structureIso7919, iLoger) %A. Bourak added for autotesting 02.11.2017
        iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.iso7919Enable.Attributes.weight));
        printComputeInfo(iLoger, 'ISO7919 method', 'ISO7919 method calculation is COMPLETE.');
        timeData.iso7919 = toc(tiso7919Start);
    else
        structureIso7919 = [];
    end
    
%% _________________________ VDI3834_1_METHOD _________________________ %%
    
    if str2double(config.config.parameters.common.vdi3834Enable.Attributes.value)
        tVDI3834_1 = tic;
        printProgress(iLoger, 'VDI3834 method');
        
        classifierStruct = getClassifierStruct(myProfileParser);
        equipmentGroupsList = getEquipmentGroupsList(myProfileParser);
        equipmentClass = equipmentProfile.equipmentProfile.Attributes.equipmentClass;
        structureVdi3834 = vdi3834(File, classifierStruct, equipmentGroupsList, equipmentClass);
        if ~isempty(structureVdi3834)
            myStatusWriter = addData('vdi3834', myStatusWriter, structureVdi3834);
        end
        
        iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.vdi3834Enable.Attributes.weight));
        printComputeInfo(iLoger, 'VDI3834 method', 'VDI3834 method calculation is COMPLETE.');
        timeData.VDI3834_1 = toc(tVDI3834_1);
    else
        structureVdi3834 = [];
    end
    
%% ________________________ FILL_METRICS_RESULT _______________________ %%
    
    if str2double(config.config.parameters.common.metricsEnable.Attributes.value)
        
        tMetricsStart = tic;
        printProgress(iLoger, 'Filling metrics');
        
        Parameters = [];
        if isfield(config.config.parameters.evaluation, 'metrics')
            Parameters = config.config.parameters.evaluation.metrics;
        end
        myStatusWriter.docNode = fillMetricsDocNode(File, Parameters, myStatusWriter.docNode, structureIso10816, unidentifiedPeaksNumbers);
        iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.metricsEnable.Attributes.weight));
        printComputeInfo(iLoger, 'Filling metrics', 'Filling metrics is COMPLETE.');
        timeData.metrics = toc(tMetricsStart);
        
    end
    
%% ___________________________ SPM_METHOD _____________________________ %%
        
        if str2double(config.config.parameters.common.spmEnable.Attributes.value)
            
            tSpmStart = tic;
            printProgress(iLoger, 'SPM method');
            
            parameters = [];
            parameters.Attributes = [];
            parameters.spmDbmDdc = [];
            parameters.spmLrHr = [];
            if (isfield(config.config.parameters.evaluation, 'spm'))
                parameters = config.config.parameters.evaluation.spm;
                parameters.shortSignal = config.config.parameters.evaluation.spm.shortSignal;
                parameters.spmLRHREnable = config.config.parameters.evaluation.spm.spmLRHR.Attributes.processingEnable;
                parameters.spmDBmDBcEnable = config.config.parameters.evaluation.spm.spmDBmDBc.Attributes.processingEnable;
            end
            parameters.plotVisible = config.config.parameters.common.printPlotsEnable.Attributes.visible;
            parameters.debugModeEnable = config.config.parameters.common.debugModeEnable.Attributes.value;
            parameters.parpoolEnable = config.config.parameters.common.parpoolEnable.Attributes.value;
            [structDBmDBc, structLRHR] = SPMProcessing(File, parameters);
            
            if str2double(config.config.parameters.evaluation.spm.spmDBmDBc.Attributes.processingEnable)
                [myStatusWriter] = addData ('spmDBmDBc', myStatusWriter,structDBmDBc);
            end
            
            if str2double(config.config.parameters.evaluation.spm.spmLRHR.Attributes.processingEnable)
				[myStatusWriter] = addData ('spmLRHR', myStatusWriter,structLRHR);
            end
            
            iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.spmEnable.Attributes.weight));
            printComputeInfo(iLoger, 'SPM method', 'SPM method calculation is COMPLETE.');
            timeData.spm = toc(tSpmStart); 
            
        end
        
%% _________________________ ISO15242_METHOD __________________________ %%
        
        if str2double(config.config.parameters.common.iso15242Enable.Attributes.value)
            
            tIso15242Start = tic;
            printProgress(iLoger, 'ISO15242 method');
            
            parameters = [];
            if (isfield(config.config.parameters.evaluation, 'iso15242'))
                parameters = config.config.parameters.evaluation.iso15242.Attributes;
                parameters.plots = config.config.parameters.evaluation.plots.Attributes;
                parameters.printPlotsEnable = config.config.parameters.common.printPlotsEnable.Attributes.value;
                parameters.plotVisible = config.config.parameters.common.printPlotsEnable.Attributes.visible;
                parameters.plotTitle = config.config.parameters.common.printPlotsEnable.Attributes.title;
                parameters.debugModeEnable = config.config.parameters.common.debugModeEnable.Attributes.value;
                parameters.historyEnable = config.config.parameters.common.historyEnable.Attributes.value;
            end

            [vRms1Log, vRms2Log, vRms3Log, statusRmsLog] = iso15242Processing(File, parameters);
			
			[myStatusWriter] = addData ('iso15242', myStatusWriter,vRms1Log,vRms2Log,vRms3Log,statusRmsLog);
			  
            iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.iso15242Enable.Attributes.weight));
            printComputeInfo(iLoger, 'ISO15242 method', 'ISO15242 method calculation is COMPLETE'); %RTG: Used for auto-testing
            timeData.ISO15242 = toc(tIso15242Start);
            
        end
        
%% _________________________ OCTAVE_SPECTRUM __________________________ %%
        
        if str2double(config.config.parameters.common.octaveSpectrumEnable.Attributes.value)
            
            tOctaveSpectrumStart = tic;
            printProgress(iLoger, 'Filling octave spectrum');
            
			[myStatusWriter] = addData ('octaveSpectrum', myStatusWriter, File);
           
            iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.octaveSpectrumEnable.Attributes.weight));
            printComputeInfo(iLoger, 'Filling octave spectrum', 'Filling octave spectrum is COMPLETE.');
            timeData.octaveSpectrum = toc(tOctaveSpectrumStart);
        end
        
%% _________________________ DECISION_MAKER ___________________________ %%
         
        if str2double(config.config.parameters.common.decisionMakerEnable.Attributes.value) && ...
            str2double(config.config.parameters.evaluation.decisionMaker.decisionMaker.Attributes.processingEnable)
            
            tDecisionMakerStart = tic;
            printProgress(iLoger, 'Decision maker');

            statuses.structureIso10816 = structureIso10816;
            statuses.mySchemeClassifier = mySchemeClassifier;
            statuses.periodicityTable = periodicityTable;
            statuses.myTimeFrequencyClassifier = myTimeFrequencyClassifier;
            statuses.File = File;
            statuses.patternResult = patternResult;
            statuses.structureIso7919 = structureIso7919;
            statuses.shaftTrajectoryStatus = myDisPlot.result.status;
            statuses.structureVdi3834 = structureVdi3834;
            
            myDecisionMaker = decisionMaker(config, statuses);
            myDecisionMaker = processingDecisionMaker(myDecisionMaker);
            
            myStatusWriter.docNode = fillDocNode(myDecisionMaker, myStatusWriter.docNode);

            iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.decisionMakerEnable.Attributes.weight));
            printComputeInfo(iLoger, 'Decision maker', 'Decision maker is COMPLETE');
            timeData.decisionMaker = toc(tDecisionMakerStart);
        end
        
%% _______________________ Create temp.xml status _____________________ %%
            
		printStatus(myStatusWriter, 'temp');
	
        nameStatusFile = [config.config.parameters.evaluation.statusWriter.Attributes.nameTempStatusFile '.xml'];
        if exist(fullfile(pwd, 'Out', nameStatusFile),'file') == 2
            printComputeInfo(iLoger, 'Framework', '@status.xml file was successfully created.');
        else
            error('@status.xml file was not created! \n');
        end	
%% ******************************************************************* %%
%% ******************** HISTORY_EVALUATION *************************** %%
%% ******************************************************************* %%
    
    % Perform history processing to analyse trends of defect development
    if str2double(config.config.parameters.common.historyEnable.Attributes.value)
        
        tHistoryProcessingStart = tic;
        printProgress(iLoger, 'History');
        
        File = historyProcessing( File, files, config, nameStatusFile );
        printStatus(myStatusWriter, 'temp');
        
        iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.historyEnable.Attributes.weight));
        printComputeInfo(iLoger, 'History', 'History processing COMPLETE.');
        timeData.historyProcessing = toc(tHistoryProcessingStart);
    end
    
    if str2double(config.config.parameters.common.printAxonometryEnable.Attributes.value)
        
        printProgress(iLoger, 'Print axonometry');
        
        printAxonometry(config.config.parameters.evaluation.history.printAxonometry.Attributes, files, File);
        
        iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.printAxonometryEnable.Attributes.weight));
        printComputeInfo(iLoger, 'Print axonometry', 'Print axonometry is COMPLETE');
    end
    
%% _____________________ DECISION_MAKER_HISTORY ________________________ %%

    if str2double(config.config.parameters.common.decisionMakerEnable.Attributes.value) && ...
            str2double(config.config.parameters.evaluation.decisionMaker.decisionMakerHistory.Attributes.processingEnable) && ...
            str2double(config.config.parameters.common.historyEnable.Attributes.value)
        
        tDecisionMakerHistoryStart = tic;
        printProgress(iLoger, 'Decision maker of history');

        file.mySchemeClassifier = mySchemeClassifier;
        file.myTimeFrequencyClassifier = myTimeFrequencyClassifier;
        file.decisionMakerCompression = File.statusesDecisionMaker;
        file.translations = File.translations;
        myDecisionMakerHistory = decisionMakerHistory(config, file);    
        myDecisionMakerHistory = processingDecisionMaker(myDecisionMakerHistory);

        myStatusWriter.docNode = fillDocNode(myDecisionMakerHistory, myStatusWriter.docNode);

        iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.decisionMakerEnable.Attributes.historyWeight));
        printComputeInfo(iLoger, 'Decision maker history', 'Decision maker of history is COMPLETE');
        timeData.decisionMakerHistory = toc(tDecisionMakerHistoryStart);
    end
%% ______________________ Stop Processing _____________________________ %%
    
    if (isempty(gcp('nocreate')) == 1)
        printComputeInfo(iLoger, 'Parpool', 'Parpool has left OFF.');
    else
        printComputeInfo(iLoger, 'Parpool', 'Parpool is ON. Shutting down...');
        delete(gcp('nocreate'));
        if (isempty(gcp('nocreate')) == 1)
            printComputeInfo(iLoger, 'Parpool', 'Parpool has been OFF.');
        else
            printComputeInfo(iLoger, 'Parpool', 'Warning: Can''t shut down the parpool!');
        end
    end
    
    timeData.totalTime = toc(tStart);
    [myStatusWriter] = addData ('processingTime', myStatusWriter,timeData);
    printStatus(myStatusWriter, 'status');
    
    printProgress(iLoger, 'Framework calculations');
    printComputeInfo(iLoger, 'Framework', 'All calculations are COMPLETE.');
    
    if strcmpi(config.config.parameters.common.printPlotsEnable.Attributes.visible, 'off')
        close all;
    end

    if exist('myStatusWriter', 'var')
        delete(myStatusWriter);
    end
    delete(iLoger);
    
    if str2double(config.config.parameters.common.debugModeEnable.Attributes.value) && ...
            str2double(config.config.parameters.evaluation.loger.Attributes.tcpipSocketEnable)
        system('taskkill /F /IM server.exe &');
        system('taskkill /IM cmd.exe &');
    end

%% ________________________ Exeption Catch ____________________________ %%
catch exception
    
    errorLog = exception.getReport('extended', 'hyperlinks', 'off');
    errorFileName = 'errors';
    errorFilePath = [fullfile(pwd,'Out',errorFileName),'.log'];
    fileId = fopen(errorFilePath,'w');
    fprintf(fileId,'%s\n', errorLog);
    fclose(fileId);
    
    iLoger = loger.getInstance;
    printException(iLoger, 'error', exception.message);
    
    if exist('myStatusWriter', 'var')
        delete(myStatusWriter);
    end
    delete(iLoger);
    delete(gcp('nocreate'));                        

    rethrow(exception); % RTG: for tests, must be last command as 'break'.
end