classdef timeFrequencyClassifier
    % TIMEFREQUENCYCLASSIFIER class enable processing of shemeClassifier 
    % with filtered signal. Signal has been based to scalogram processing.
    
    properties
        % Config parameters
        config 
        informativeTags
        translations
        parameters
        
        % Entrance data
        scalogramData
        originalSignal
        classifierStruct
        periodicityTable
        peaksTablesForProcessing % Table peaks with scalogram data
        signalForProcessing % Signal with scalogram data (filtering cwt or BPF)
        allPeakTables % All peaks table of current original signal
        
        % Temporary
        envSpecStruct
        
        % Result struct
        objectsStruct % objects of schemeClassifier class
    end
    
    methods(Access = public)
        
        % TIMRFREQUENCYCLASSIFIER constructor is initialisation of object
        function myTimeFrequencyClassifier = timeFrequencyClassifier(Data, Config)
            
            myTimeFrequencyClassifier.parameters = Config.config.parameters.evaluation.timeFrequencyDomainClassifier.Attributes;
            
            myTimeFrequencyClassifier.config = Config;
            myTimeFrequencyClassifier.informativeTags = Data.File.informativeTags;
            myTimeFrequencyClassifier.translations = Data.File.translations;
            myTimeFrequencyClassifier.scalogramData = Data.scalogramData;
            
            myTimeFrequencyClassifier.originalSignal.signal = Data.File.acceleration.signal;
            myTimeFrequencyClassifier.originalSignal.Fs =  Data.File.Fs;
            
            myTimeFrequencyClassifier.signalForProcessing = chooseSignal(myTimeFrequencyClassifier, Data);            
            
            myTimeFrequencyClassifier.classifierStruct = Data.classifierStruct;
            myTimeFrequencyClassifier.periodicityTable = Data.periodicityTable;
            myTimeFrequencyClassifier.allPeakTables.acceleration = Data.File.acceleration.spectrum.peakTable;
            myTimeFrequencyClassifier.allPeakTables.velocity = Data.File.velocity.spectrum.peakTable;
            myTimeFrequencyClassifier.allPeakTables.displacement = Data.File.displacement.spectrum.peakTable;
            
            myTimeFrequencyClassifier.peaksTablesForProcessing = [];
            
            myTimeFrequencyClassifier.objectsStruct = [];
        end
        
        % PROCESSINGCLASSIFIER function calculation schemeClassifier with
        % scalogram date
        function myTimeFrequencyClassifier = processingClassifier(myTimeFrequencyClassifier)
            
            % Set plotEnable '0' for printing of spectra
            % TEMP PARAMETRS
            myTimeFrequencyClassifier.config.config.parameters.evaluation.spectra.envSpectrum.Attributes.plotEnable = '0';
            myTimeFrequencyClassifier.config.config.parameters.evaluation.spectra.logSpectrum.Attributes.plotEnable = '0';
            myTimeFrequencyClassifier.config.config.parameters.evaluation.frequencyDomainClassifier.Attributes.plotEnable = '0';
            
            % Main calculations
            [myTimeFrequencyClassifier.peaksTablesForProcessing,myTimeFrequencyClassifier.envSpecStruct] = createPeaksTables(myTimeFrequencyClassifier);
            myTimeFrequencyClassifier.objectsStruct = createObjectsStruct(myTimeFrequencyClassifier);
        end
        
        % FILLDOCNODE function adds timeFrequencyClassifier result data to
        % existing docNode element
        function docNode = fillDocNode(myTimeFrequencyClassifier, docNode)
           
            timeFrequencyNode = docNode.createElement('timeFrequencyDomainClassifier');
            
            % If scalogram date is not empty
            if ~isempty(myTimeFrequencyClassifier.scalogramData)
                if ~isempty(myTimeFrequencyClassifier.periodicityTable)
                    periodicityOk = true; % flag that periodicityTable isn't empty
                    
                    % Get value for further processing
                    frequencies = {myTimeFrequencyClassifier.periodicityTable.frequency};
                    resonantPeriodicity = {myTimeFrequencyClassifier.periodicityTable.resonantFrequency};
                    validityPeriodicity = {myTimeFrequencyClassifier.periodicityTable.validity};
                    typePeriodicity = {myTimeFrequencyClassifier.periodicityTable.type};
                else
                    periodicityOk = false; % flag that periodicityTable isn't empty
                end

                % Main processing for filling docNode
                for i = 1:1:length(myTimeFrequencyClassifier.scalogramData) 
                    
                    % Filling scalogram data
                    resonantFrequencyNode = docNode.createElement('resonantFrequency');
                    resonantFrequencyNode.setAttribute('value', ...
                        num2str(myTimeFrequencyClassifier.scalogramData(i).frequencies));
                    resonantFrequencyNode.setAttribute('range', ...
                        [num2str(myTimeFrequencyClassifier.scalogramData(i).lowFrequency) ' ' ...
                        num2str(myTimeFrequencyClassifier.scalogramData(i).highFrequency)]);
                    if isfield(myTimeFrequencyClassifier.scalogramData(i), 'energyContribution')
                        resonantFrequencyNode.setAttribute('energyContribution', ...
                            num2str(round(myTimeFrequencyClassifier.scalogramData(i).energyContribution*10000)/100));
                    else
                        resonantFrequencyNode.setAttribute('energyContribution', []);
                    end
                    
                    periodicityNode = docNode.createElement('periodicity');                    
    
                    % Filing of periodicity data
                    if periodicityOk

                        % To find periodicity data with current resonant
                        % frequency
                        positionResonant = cellfun(@(x) ...
                            (x == myTimeFrequencyClassifier.scalogramData(i).frequencies), resonantPeriodicity)';

                        % To write periodicity data with current resonant
                        % frequency
                        if nnz(positionResonant)

                            frequenciesTemp = strsplit(num2str(round(...
                                    cell2mat(frequencies(positionResonant)).*100)/100));
                            periodicityNode.setAttribute('frequency', strjoin(frequenciesTemp));

                            validityTemp = strsplit(num2str(round(...
                                    cell2mat(validityPeriodicity(positionResonant)).*100)/100));
                            periodicityNode.setAttribute('validity', strjoin(validityTemp));

                            periodicityNode.setAttribute('type', strjoin(typePeriodicity(positionResonant)));
                        else
                            periodicityNode = ...
                            myTimeFrequencyClassifier.createEmptyPeriodicityHalf(periodicityNode);
                        end
                    else
                        periodicityNode = ...
                            myTimeFrequencyClassifier.createEmptyPeriodicityHalf(periodicityNode);
                    end
                    resonantFrequencyNode.appendChild(periodicityNode);
                    
                    % Filling schemeClassifier data
                    [~, spectraClassifierNode] = fillDocNode(myTimeFrequencyClassifier.objectsStruct{i}, docNode);
                    resonantFrequencyNode.appendChild(spectraClassifierNode);

                    timeFrequencyNode.appendChild(resonantFrequencyNode);
                end
            else
                resonantFrequencyNode = docNode.createElement('resonantFrequency');
                resonantFrequencyNode.setAttribute('value', []);
                resonantFrequencyNode.setAttribute('range', []);
                resonantFrequencyNode.setAttribute('energyContribution', []);
                
                periodicityNode = docNode.createElement('periodicity');
                
                periodicityNode = ...
                            myTimeFrequencyClassifier.createEmptyPeriodicityHalf(periodicityNode);
                
                resonantFrequencyNode.appendChild(periodicityNode);

                % Filling schemeClassifier data
                [~, spectraClassifierNode] = fillDocNode(myTimeFrequencyClassifier.objectsStruct{1}, docNode);
                resonantFrequencyNode.appendChild(spectraClassifierNode);
                
                timeFrequencyNode.appendChild(resonantFrequencyNode);
            end
            
            % Create docRoot node
            docRootNode = docNode.getDocumentElement;
            % Set specraClassifier node to docRoot node
            docRootNode.appendChild(timeFrequencyNode);
        end
        
        function myObjectsStruct = getObjectStruct(myTimeFrequencyClassifier)
            myObjectsStruct = myTimeFrequencyClassifier.objectsStruct;
        end
        
        function saveStatusImages(myTimeFrequencyClassifier, file)
            
            if isempty(myTimeFrequencyClassifier.scalogramData)
               return 
            end
            
            myObjectsStruct = myTimeFrequencyClassifier.objectsStruct;
            
            myEnvSpectrumStruct = myTimeFrequencyClassifier.envSpecStruct;
            
            for i = 1:numel(myObjectsStruct)
                file.acceleration.envelopeSpectrum.amplitude = myEnvSpectrumStruct(i).spectrum;
                file.acceleration.frequencyVector = myEnvSpectrumStruct(i).frequencies;
                saveStatusImages(myObjectsStruct{i},file); 
            end
        end
    end
    
    methods(Access = protected)
        
        % CHOOSENSIGNAL function choosing between filtering of signal with 
        % cwt and BPF
        function [choosedSignals] = chooseSignal(myTimeFrequencyClassifier, Data)

            % Use BPF or CWT
            if contains(myTimeFrequencyClassifier.parameters.typeOfFilter, 'BPF')
                choosedSignals = bandpassFiltering(myTimeFrequencyClassifier);
            else
                choosedSignals = Data.filteredSignalCwt;
            end
            
            % If not ranges for filtering, then to create the classical classifier
            if isempty(choosedSignals) 
                choosedSignals(1).signal = myTimeFrequencyClassifier.originalSignal.signal;
                choosedSignals(1).Fs = myTimeFrequencyClassifier.originalSignal.Fs;
            end
        end
        
        % BANDPASSFILTERING function filtering of original signals with
        % scalogram range
        function [filteredSignals] = bandpassFiltering(myTimeFrequencyClassifier)
            
            if ~isempty(myTimeFrequencyClassifier.scalogramData)
                numberSignals = length(myTimeFrequencyClassifier.scalogramData);
                % Initialisation of result table
                filteredSignals(numberSignals).signal = [];
                filteredSignals(numberSignals).Fs = [];

                % Set original signals
                file.signal = myTimeFrequencyClassifier.originalSignal.signal;
                file.Fs = myTimeFrequencyClassifier.originalSignal.Fs;

                tempParameters.Rp = str2double(myTimeFrequencyClassifier.parameters.Rp);
                tempParameters.Rs = str2double(myTimeFrequencyClassifier.parameters.Rs);
 
                % Filtering of signals and filling of result struct
                for i = 1:1:numberSignals
                    tempParameters.lowFrequency = myTimeFrequencyClassifier.scalogramData(i).lowFrequency;
                    tempParameters.highFrequency = myTimeFrequencyClassifier.scalogramData(i).highFrequency; 
                    filteredSignals(i).signal = myTimeFrequencyClassifier.preFilter(file, tempParameters);

                    filteredSignals(i).Fs = file.Fs;
                end
            else
                filteredSignals = [];
            end
        end
        
        % CREATEPEAKSTABLES function create peakTable of filtering signals
        function [peaksTables, FileLog] = createPeaksTables(myTimeFrequencyClassifier)
            signalsNumber = length(myTimeFrequencyClassifier.signalForProcessing);
            
            peaksTables = cell(signalsNumber,1);
            
            % To set config parameters for getting envelope spectrum
            ParametersEnv = ...
                myTimeFrequencyClassifier.config.config.parameters.evaluation.spectra.envSpectrum.Attributes;   %%%%% <<<<< ------------!!
            ParametersEnv.highFrequencyDevice = ...
                myTimeFrequencyClassifier.config.config.parameters.sensor.Attributes.highFrequency;
            ParametersEnv.spectrumRange = ...
                myTimeFrequencyClassifier.config.config.parameters.evaluation.spectra.Attributes.accelerationRange;
            ParametersEnv.plots = ...
                myTimeFrequencyClassifier.config.config.parameters.evaluation.plots.Attributes;
            ParametersEnv.printPlotsEnable = ...
                myTimeFrequencyClassifier.config.config.parameters.common.printPlotsEnable.Attributes.value;
            ParametersEnv.plotVisible = ...
                myTimeFrequencyClassifier.config.config.parameters.common.printPlotsEnable.Attributes.visible;
            ParametersEnv.parpoolEnable = ...
                myTimeFrequencyClassifier.config.config.parameters.common.parpoolEnable.Attributes.value;
            
            %% TEST GAG
            ParametersEnv.plotEnable = '0';
            ParametersEnv.plotVisible = 'off';
            ParametersEnv.printPlotsEnable = '0';
            %% 
            
            Translations = myTimeFrequencyClassifier.translations;
            FileEnv.signal = myTimeFrequencyClassifier.originalSignal.signal;
            
            % To set config parameters for peak tables of filtering
            % signals
            ParametersLog = ...
                myTimeFrequencyClassifier.config.config.parameters.evaluation.spectra.logSpectrum.Attributes;
            ParametersLog.plots = ...
                myTimeFrequencyClassifier.config.config.parameters.evaluation.plots.Attributes;
            ParametersLog.plotVisible = ...
                myTimeFrequencyClassifier.config.config.parameters.common.printPlotsEnable.Attributes.visible;
            ParametersLog.spectrumRange = ...
                myTimeFrequencyClassifier.config.config.parameters.evaluation.spectra.Attributes.accelerationRange;
            
            % Main calculations
            for i=1:1:signalsNumber
                % To get envelope spectrum
                FileEnv.filteredSignal = myTimeFrequencyClassifier.signalForProcessing(i).signal;
                FileEnv.Fs = myTimeFrequencyClassifier.signalForProcessing(i).Fs;
                [~,EnvSpectrumStruct, frequencyVector,~] = ...
                    envSpectrum(FileEnv, ParametersEnv, Translations, 'acceleration', 1);
                
                % To get peakTable
                FileLog(i).signal = myTimeFrequencyClassifier.signalForProcessing(i).signal;
                FileLog(i).spectrum = EnvSpectrumStruct.amplitude;
                FileLog(i).frequencies = frequencyVector;
                FileLog(i).Fs = FileEnv.Fs;
                [~,~,peaksTables{i,1}] = logSpectrum(FileLog(i), ParametersLog, 'acceleration');
            end
        end
        
        % CREATEOBJECTSTRUCT function create different objects 
        % schemeClassifier class corresponsive with scalogram results
        function objectsStruct = createObjectsStruct(myTimeFrequencyClassifier)
            
            signalsNumber = length(myTimeFrequencyClassifier.signalForProcessing);
            objectsStruct = cell(signalsNumber,1);
            
            % Delete not processing elements
%             myTimeFrequencyClassifier.classifierStruct.shaftStruct = [];
%             myTimeFrequencyClassifier.classifierStruct.motorStruct = [];
            
            File.informativeTags = myTimeFrequencyClassifier.informativeTags;
            File.acceleration.spectrum.peakTable = myTimeFrequencyClassifier.allPeakTables.acceleration;
            File.velocity.spectrum.peakTable = myTimeFrequencyClassifier.allPeakTables.velocity;
            File.displacement.spectrum.peakTable = myTimeFrequencyClassifier.allPeakTables.displacement;
            
            for i=1:1:signalsNumber
                File.acceleration.envelopeSpectrum.peakTable = myTimeFrequencyClassifier.peaksTablesForProcessing{i,1};
                mySchemeClassifier = ...
                    schemeClassifier(File, myTimeFrequencyClassifier.classifierStruct, myTimeFrequencyClassifier.config,1,i);
                mySchemeClassifier = createStatusStruct(mySchemeClassifier);
                
                objectsStruct{i,1} = mySchemeClassifier;
            end
            
            if isempty(myTimeFrequencyClassifier.scalogramData)
                statusStruct = getStatusStruct(objectsStruct{1,1});
                for i = 1:1:length(statusStruct)
                    statusStruct(i).similarity = 0;
                end
                objectsStruct{1,1} = setStatusStruct(objectsStruct{1,1}, statusStruct);
            end
        end
    end
    
    methods(Static)
        
        % PREFILTER function filtered of signal
        function [signal] = preFilter(file, config)
            Wp = [config.lowFrequency*2/file.Fs config.highFrequency*2/file.Fs];
            Ws = [((1-0.1)*config.lowFrequency)*2/file.Fs ((1+0.1)*config.highFrequency)*2/file.Fs];  
            [~,Wn] = buttord(Wp, Ws, config.Rp, config.Rs);
            [b, a] = butter(2, Wn , 'bandpass');
            signal = filter(b, a, file.signal);
        end
        
        % CREATEEMPTYPERIODICITYHALF filling docNode empty data for
        % periodicity (fields of docNode: frequency, validity, type)
        function periodicityNode = createEmptyPeriodicityHalf(periodicityNode)

            periodicityNode.setAttribute('frequency', []);

            periodicityNode.setAttribute('validity', []);

            periodicityNode.setAttribute('type', []);
        end

    end
end

