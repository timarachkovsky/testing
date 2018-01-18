classdef timeSynchronousAveraging
    % TIMESYNCHRONOUSAVERAGING 
    
    properties
        
        % Parameters 
        config
        
        % INPUT:
        signalAcceleration
        timeVector
        Fs
        spectrumAcceleration
        peakTable
        frequencyVector
        classifierStruct
        mainFreqStruct
        
        % OUTPUT:
        resultTable
    end
    
    methods(Access = public)
        
        % Constructor, TSA is abbreviation of time synchronous averaging
        function myTSA = timeSynchronousAveraging(File, config)
            
            % To set parameters for processing
            myTSA.config.numberMainPeaks = str2double(config.numberMainPeaks);
            myTSA.config.numberSideBandPeaks = str2double(config.numberSideBandPeaks);
            myTSA.config.limitSpectrumInShaftHarmonics = str2double(config.limitSpectrumInShaftHarmonics);
            myTSA.config.deviationThreshold = str2double(config.deviationThreshold);
            myTSA.config.lineCoef = str2num(config.lineCoef);
            myTSA.config.plotEnableAll = str2double(config.plotEnableAll);
            
            myTSA.config.plotEnable = str2double(config.plotEnable);
            myTSA.config.printPlotsEnable = str2double(config.printPlotsEnable);
            myTSA.config.plotVisible = config.visible;
            myTSA.config.plotTitle = config.title;
            
            myTSA.config.plots.sizeUnits = config.plots.sizeUnits;
            myTSA.config.plots.imageSize = str2num(config.plots.imageSize);
            myTSA.config.plots.fontSize = str2double(config.plots.fontSize);
            myTSA.config.plots.imageFormat = config.plots.imageFormat;
            myTSA.config.plots.imageQuality = config.plots.imageQuality;
            myTSA.config.plots.imageResolution = config.plots.imageResolution;
            myTSA.config.plots.translations = config.plots.translations;
            
            myTSA.config.peakComparison = config.peakComparison;
            
            myTSA.config.logSpectrum = config.logSpectrum;
            
            myTSA.config.filtration.Rp = str2double(config.Rp);
            myTSA.config.filtration.Rs = str2double(config.Rs);
            
            % To set input arguments for processing
            myTSA.signalAcceleration = File.signalAcceleration;
            myTSA.timeVector = File.timeVector;
            myTSA.Fs = File.Fs;
            myTSA.spectrumAcceleration = File.spectrumAcceleration;
            myTSA.peakTable = File.peakTable;
            myTSA.frequencyVector = File.frequencyVector;
            myTSA.classifierStruct = File.classifierStruct;
            myTSA.mainFreqStruct = File.mainFreqStruct;
            
            % To set output arguments
            myTSA.resultTable = [];
        end
        
        % TIMESYNCHRONOUSAVERAGINGCALCULATE function calculate TSA 
        function myTSA = timeSynchronousAveragingCalculate(myTSA)
            
            % Check gearing in the scheme and find more close location
            [checkingStatus, gearingsName] = myTSA.checkGearingInScheme(myTSA.classifierStruct.connectionStruct);
            
            if checkingStatus
                
                numberGearings = int16(length(gearingsName));
                
                file.mainFreqStruct = myTSA.mainFreqStruct.element;
                file.peakTable = myTSA.peakTable;
                file.signalAcceleration = myTSA.signalAcceleration;
                file.timeVector = myTSA.timeVector;
                file.Fs = myTSA.Fs;

                structRange = cell(numberGearings, 1);
                numberRangeAll = 0;
                for i = 1:1:numberGearings
                    structRange{i, 1} = myTSA.findRangeForEachGearing(gearingsName{i}, file, myTSA.config);
                    numberRangeAll = numberRangeAll + length(structRange{i, 1});
                end
                
                if numberRangeAll
                    
                    % Delete all empty cell
                    structRange = structRange(~cellfun(@isempty, structRange), 1);
                    
                    myResultTable = myTSA.createEmptyResultTable(numberRangeAll);

                    % Add to new struct
                    startPos = 1;
                    numberRange = 0;
                    for i = 1:1:numberGearings

                        numberRange = numberRange + length(structRange{i, 1});
                        [myResultTable(startPos:1:numberRange).gearingsNames] = structRange{i, 1}.gearingsNames;
                        [myResultTable(startPos:1:numberRange).shaftsNames] = structRange{i, 1}.shaftsNames;
                        [myResultTable(startPos:1:numberRange).shaftsFrequencies] = structRange{i, 1}.shaftsFrequencies;
                        [myResultTable(startPos:1:numberRange).range] = structRange{i, 1}.range;
                        [myResultTable(startPos:1:numberRange).validGM] = structRange{i, 1}.validGM;
                        [myResultTable(startPos:1:numberRange).harmonicNumber] = structRange{i, 1}.harmonicNumber;
                        
                        startPos = numberRange + 1;
                    end

                    file = rmfield(file, 'mainFreqStruct');
                    file = rmfield(file, 'peakTable');

                    % Evaluate TSA method
                    for i = 1:1:numberRangeAll
                        myResultTable(i) = myTSA.evaluateRange(myResultTable(i), file, myTSA.config);
                    end

                    % Set result
                    myTSA.resultTable = myResultTable;
                    
                    % Plot result
                    if myTSA.config.plotEnable

                        configTemp = myTSA.config.plots;
                        configTemp.printPlotsEnable = myTSA.config.printPlotsEnable;
                        configTemp.plotVisible = myTSA.config.plotVisible;
                        configTemp.plotTitle = myTSA.config.plotTitle;

                        for i = 1:1:numberRangeAll
                            myTSA.plotTsaResult(myResultTable(i), file, i, configTemp);
                        end
                    end
                end
            end
            
        end
        
        % GETRESULTTABLE
        function myResultTable = getResultTable(myTSA)
            myResultTable = myTSA.resultTable;
        end
        
    end
    
    methods(Static)
        
        % CHECKGEARINGINSCHEME function checks enable of method
        function [status, gearingsName] = checkGearingInScheme(connectionStruct)
            
            status = false;
            gearingsName = [];
            
            % If scheme have connection
            if ~isempty(connectionStruct)
                
                priority = logical(cell2mat({connectionStruct.connection.priority}));
                elementEnable = logical(cell2mat({connectionStruct.connection.enable}));
                classType = ~cellfun(@isempty,(strfind({connectionStruct.connection.classType}, 'gearing')));
                
                elementProcessing = bsxfun(@and, priority, elementEnable);
                elementProcessing = bsxfun(@and, elementProcessing, classType);
                
                % If connection is gearing, currect euipmentDataPoint ==
                % euipmentDataPoint of gearing, elementProcessingEnable ==
                % 1
                if any(elementProcessing)
                    status = true;
                    gearingsName = {connectionStruct.connection(elementProcessing).name};
                end
            end
            
        end
        
        % CREATEEMPTYRESULTTABLE function create empty result table
        function resultTable = createEmptyResultTable(numberFields)
            
            resultTable(numberFields).gearingsNames = [];
            resultTable(numberFields).shaftsNames = [];
            resultTable(numberFields).shaftsFrequencies = [];
            resultTable(numberFields).range = [];
            resultTable(numberFields).harmonicNumber = [];
            resultTable(numberFields).validGM = [];
            
            resultTable(numberFields).validShaftFreq = [];
            resultTable(numberFields).tsaSignal = [];
            resultTable(numberFields).deltaEnds = [];
            resultTable(numberFields).modulationCoef = [];
            resultTable(numberFields).tsaMean = [];
            
            resultTable(numberFields).status = [];
        end
        
        % CREATESTRUCTRANGEEMPTY function create empty result sturct 
        function structRange = createStructRangeEmpty(numberFields)
            
            structRange(numberFields).gearingsNames = [];
            structRange(numberFields).shaftsNames = [];
            structRange(numberFields).shaftsFrequencies = [];
            structRange(numberFields).range = [];
            structRange(numberFields).validGM = [];
            structRange(numberFields).harmonicNumber = [];
            
        end
        
        % FINDFOREACHGEARNG function find gearing frequency and create 
        % ranges of filtration for TSA method based on shaft frequencies
        function structRange = findRangeForEachGearing(gearingsName, file, config)
            
            % Get basic frequency list for current gearing
            basicFreqs = file.mainFreqStruct(~cellfun(@isempty, ...
                     strfind({file.mainFreqStruct.name}, gearingsName))).basicFreqs;
                 
            % Get teeth frequency ('19' is tag for teeth frequnecy)
            teethFreq = basicFreqs{cellfun(@(x) x == 19, basicFreqs(:, 1)), 2};
            
            % Get and validate teeth frequency in spectrum (peakTable)
            vectorHarmonicNumber = 1:1:config.numberMainPeaks;
            gearMeshVector = vectorHarmonicNumber * teethFreq;
            gearMeshVectorValid = nan(config.numberMainPeaks, 1);
            for i = 1:1:config.numberMainPeaks
                
                peaksFound = getSimilarElements(gearMeshVector(i), file.peakTable, config.peakComparison);
                
                if length(peaksFound) == 1 
                    
                    gearMeshVectorValid(i) = peaksFound;
                    
                elseif length(peaksFound) > 1
                    
                    peakTableFinding = file.peakTable(ismember(file.peakTable(:, 1), peaksFound), :);
                    
                    % Tag 2 is energy peak (more often is gearing)
                    magnitides = peakTableFinding(:, 2);
                    posGearing = peakTableFinding(:,5) == 2;
                    if any(posGearing)
                        
                        tempFindingGearingTag = peakTableFinding(posGearing ,:);
                        
                        [~, indexMax] = max(tempFindingGearingTag(:, 2));
                        gearMeshVectorValid(i) = tempFindingGearingTag(indexMax, 1);

                    else
                        [~, indexMax] = max(magnitides);
                        gearMeshVectorValid(i) = peakTableFinding(indexMax, 1);
                    end
                end
            end
            posNonNan = ~isnan(gearMeshVectorValid);
            gearMeshVectorValid = gearMeshVectorValid(posNonNan);
            vectorHarmonicNumber = vectorHarmonicNumber(posNonNan);
            
            % Get shaft1 frequency ('17' is tag for shaft1 frequnecy) and
            % create range
            shaft1Frequency = basicFreqs{cellfun(@(x) x == 17, basicFreqs(:, 1)), 2};
            
            rangeShaft1 = nan(length(gearMeshVectorValid), 2);
            shaft1FrequencyBand = (shaft1Frequency * config.numberSideBandPeaks);
            rangeShaft1(:, 1) = gearMeshVectorValid - shaft1FrequencyBand;
            rangeShaft1(:, 2) = gearMeshVectorValid + shaft1FrequencyBand;
            
            % Get shaft2 frequency ('18' is tag for shaft1 frequnecy) and 
            % create range
            shaft2Frequency = basicFreqs{cellfun(@(x) x == 18, basicFreqs(:, 1)), 2};
            
            rangeShaft2 = nan(length(gearMeshVectorValid), 2);
            shaft2FrequencyBand = (shaft2Frequency * config.numberSideBandPeaks);
            rangeShaft2(:, 1) = gearMeshVectorValid - shaft2FrequencyBand;
            rangeShaft2(:, 2) = gearMeshVectorValid + shaft2FrequencyBand;
            
            % Set range to result struct
            numberGearMesh = length(gearMeshVectorValid);
            numberShaft = 2;
            numberFields = numberGearMesh * numberShaft;
            
            if numberGearMesh
            
                structRange = timeSynchronousAveraging.createStructRangeEmpty(numberFields);

                tempGearings = cell(numberFields, 1);
                tempGearings(:) = {gearingsName};
                [structRange.gearingsNames] = tempGearings{:};

                % Set for first shaft
                for i = 1:1:numberGearMesh
                    structRange(i).shaftsNames = 'shaft1';
                    structRange(i).range = rangeShaft1(i, :);
                    structRange(i).validGM = ...
                        timeSynchronousAveraging.validateGearMesh(file.peakTable, rangeShaft1(i, :), gearMeshVectorValid(i));
                    structRange(i).shaftsFrequencies = shaft1Frequency;
                    structRange(i).harmonicNumber = vectorHarmonicNumber(i);
                end

                % Set for second shaft
                for i = numberGearMesh+1:1:numberFields
                    structRange(i).shaftsNames = 'shaft2';
                    structRange(i).range = rangeShaft2(i - numberGearMesh, :);
                    structRange(i).validGM = ...
                        timeSynchronousAveraging.validateGearMesh(file.peakTable, rangeShaft2(i - numberGearMesh, :), gearMeshVectorValid(i - numberGearMesh));
                    structRange(i).shaftsFrequencies = shaft2Frequency;
                    structRange(i).harmonicNumber = vectorHarmonicNumber(i - numberGearMesh);
                end
                
            else
                structRange = [];
            end
                        
        end
        
        % EVALUATETSASHAFT function evaluate each ranges of the shaft
        function resultStruct = evaluateTSAShaft(shaftStruct, file, config)
            
            numberRange = length(shaftStruct.range(:,1));
            
            resultStruct = shaftStruct;
            resultStruct.resultRanges = cell(numberRange, 1);
            
            for i = 1:1:numberRange
                resultStruct.resultRanges{i, 1} = ...
                    timeSynchronousAveraging.evaluateRange(shaftStruct.range(i,:), file, config);
            end
            
        end
        
        % EVALUATERANGE function evaluate one range of the shaft and create
        % TSA signal and metrics of the TSA signal
        function statusRange = evaluateRange(statusRange, file, config)
            
            % Filtration
            filteredSignal = timeSynchronousAveraging.TSAfiltration(file.signalAcceleration, file.Fs, statusRange.range(1), ...
                                                                    statusRange.range(2), config.filtration);
                                                                            
            % Get envelope of filtered signal
            envelopeSignal = envelope(filteredSignal);
            
            % Calculate spectrum of envelope signal
            configTempSpectrum.logSpectrum = config.logSpectrum;
            configTempSpectrum.limitFrequency = config.limitSpectrumInShaftHarmonics * statusRange.shaftsFrequencies;
            configTempSpectrum.plotEnableAll = config.plotEnableAll;
            configTempSpectrum.plotVisible = config.plotVisible;
            configTempSpectrum.range = statusRange.range;
            configTempSpectrum.gearingName = statusRange.gearingsNames;
            modeCheckPhase = 0;
            [~, frequency, phaseSpectrum, peakTable] = ...
                timeSynchronousAveraging.calculateSpectra(envelopeSignal, file.Fs, configTempSpectrum, modeCheckPhase);
            
            % To correct shaft frequency
            configTemp.peakComparison = config.peakComparison;
%             configTemp.limitSpectrumInShaftHarmonics = config.limitSpectrumInShaftHarmonics;
            fileTemp.shaftFrequency = statusRange.shaftsFrequencies;
            fileTemp.peakTable = peakTable;
            [correctedShaftFrequency, validFreq] = timeSynchronousAveraging.findShaftFrequency(fileTemp, configTemp);
                 
            allPeriod = file.Fs / correctedShaftFrequency;
            
            % Shaft phase set zero
            if validFreq
                
                positionFrequency = correctedShaftFrequency == frequency;
                envelopeSignalShift = timeSynchronousAveraging. ...
                                     phaseToZero(envelopeSignal, phaseSpectrum(positionFrequency), allPeriod);
            
                % For check phase in plot
                if config.plotEnableAll
                    
                    configTempSpectrum.positionFrequency = positionFrequency;
                    modeCheckPhase = 1;
                    
                    % Add zeros, then spectrum was same the signal envelope
                    % without croping
                    numberSampleShiht = length(envelopeSignalShift);
                    numberSampleFull = length(envelopeSignal);
                    cropSignalWithZeros = zeros(1, numberSampleFull);
                    cropSignalWithZeros(1:1:numberSampleShiht) = envelopeSignalShift;
                    timeSynchronousAveraging.calculateSpectra(cropSignalWithZeros, file.Fs, ...
                                                              configTempSpectrum, modeCheckPhase);
                end
                
                envelopeSignal = envelopeSignalShift;
            end
            
            % Create TSA signal
            [tsaSignal, deltaEnds, modulationCoef, tsaMean] = createTsaSignal(envelopeSignal, allPeriod);
            
            statusRange.validShaftFreq = validFreq;
            statusRange.tsaSignal = tsaSignal;
            statusRange.deltaEnds = deltaEnds;
            statusRange.modulationCoef = modulationCoef;
            statusRange.tsaMean = tsaMean;
            
            % Evaluate tsa signal
            statusRange.status = 0;
            if validFreq && statusRange.validGM
                
                if tsaMean/deltaEnds >= config.deviationThreshold
                    % The experiments identified function of line 
                    % 150*x + 25
                    statusRange.status = config.lineCoef(1)*modulationCoef + config.lineCoef(2);
                end
            end
            
        end
        
        % TSAFILTRATION function filter input signal 
        function filteredSignal = TSAfiltration(signal, Fs, lowFreq, highFreq, config)

            % Set parameters for filtration. And to filter out a signal
            Wp = [lowFreq*2/Fs highFreq*2/Fs];
            Ws = [(lowFreq - 0.1*lowFreq)*2/Fs (highFreq + 0.1*highFreq)*2/Fs]; 

            [k, Wn1] = cheb1ord(Wp, Ws, config.Rp, config.Rs);   
            [b1, a1] = cheby1(2, config.Rp, Wn1);
            filteredSignal = filtfilt(b1, a1, signal);

            % To cut sampels with transient characteristic
            filteredSignal = filteredSignal(5*k:1:end);
            
        end
        
        % VALIDATEGEARMESH function check gear mesh was higher all harmonics
        function statusGearMesh = validateGearMesh(peakTable, ranges, gearMesh)
            
            statusGearMesh = false;
                
            positionsCurrentPeaks = bsxfun(@and, ...
                                            bsxfun(@ge, peakTable(:, 1), ranges(1)), ...
                                            bsxfun(@le, peakTable(:, 1), ranges(2)));

            tempPeakTable = peakTable(positionsCurrentPeaks, :);

            [~, indexMax] = max(tempPeakTable(:, 2));

            if any(tempPeakTable(indexMax, 1) == gearMesh)
                statusGearMesh = true;
            else

                statusEnergyMaxPeak = tempPeakTable(indexMax, 5);
                indexCurrent = find(gearMesh == tempPeakTable(:, 1));

                [~, indexSort] = sort(tempPeakTable(:, 2), 'descend');

                % If gear mesh have second position after max peak and
                % both peaks are energy peaks
                if statusEnergyMaxPeak == 2 && find(indexCurrent == indexSort) <= 2 &&  ...
                   tempPeakTable(indexCurrent, 5) == 2

                    statusGearMesh = true;
                end
            end
                    
        end
        
        % CALCULATESPECTRA function calculate FFT
        function [spectrumAbs, frequency, phaseSpectrum, peakTable] = calculateSpectra(inputSingal, Fs, config, modeCheck)
            
            lengthSignal = length(inputSingal);
            df = Fs/lengthSignal;
            
            if ~isempty(config.limitFrequency)
                
                if length(config.limitFrequency) == 2
                    
                    endFreq = config.limitFrequency(2);
                    startSample = ceil(config.limitFrequency(1) / df);
                    endSample = ceil(endFreq / df);
                    
                else
                    
                    endFreq = config.limitFrequency(1);
                    startSample = 1;
                    endSample = ceil(endFreq / df);
                end
                
            else
                startSample = 1;
                endSample = lengthSignal;
                endFreq = Fs;
            end
                
            spectrum = ifft(inputSingal);
            phaseSpectrum = angle(spectrum);
            frequency = 0:df:Fs-df;
            oneSideFactor = 2;
            spectrumAbs = abs(spectrum) * oneSideFactor;
            
            
            frameLength = str2double(config.logSpectrum.frameLength);
            stepLength = str2double(config.logSpectrum.stepLength);
            if endFreq < (frameLength + stepLength * 2)
                startSample = 1;
                endSample = (frameLength + stepLength * 2) / df;
            end
            
            vectorForCrop = startSample:1:endSample;
            spectrumAbs = spectrumAbs(vectorForCrop);
            phaseSpectrum = phaseSpectrum(vectorForCrop);
            frequency = frequency(vectorForCrop)';
            fileTemp.spectrum = spectrumAbs;
            
            % Get peak table for envelope spectrum
            % ignore
            config.logSpectrum.spectrumRange = ' : : ';
            
            fileTemp.signal = inputSingal;
            
            fileTemp.frequencies = frequency';
            fileTemp.Fs = Fs;
            [~, ~, peakTable] = logSpectrum(fileTemp, config.logSpectrum, 'acceleration');
            
            % Plot Spectrum
            if config.plotEnableAll
                
                % Crop 0.5 Hz for plotting
                cropVector = ceil(0.8/df):1:limitSample;
                
                figure
                
                subplot(2,1,1);
                range = strjoin(strsplit(num2str(ceil(config.range))));
                hold on
                plot(frequency(cropVector), spectrumAbs(cropVector));
                xlabel('Frequencies, Hz')
                ylabel('Magnitude, m/s^2')
                title(['Envelope spectrum of ' config.gearingName ' for range: ' range])
                if modeCheck
                    stem(frequency(config.positionFrequency), spectrumAbs(config.positionFrequency))
                end
                
                subplot(2,1,2);
                plot(frequency(cropVector), phaseSpectrum(cropVector));
                hold on
                xlabel('Frequencies, Hz')
                ylabel('Degree, radian')
                yticks([-pi 0 pi])
                yticklabels({'-\pi','0','\pi'})
                title('Phase spectrum')
                if modeCheck
                    stem(frequency(config.positionFrequency), phaseSpectrum(config.positionFrequency))
                end
                
                % Close figure with visibility off
                if strcmpi(config.plotVisible, 'off')
                    close
                end  
            end
            
        end
        
        % FINDSHAFTFREQUENCY function find and validate shaft frequency
        function [correctedShaftFrequency, validFreq] = findShaftFrequency(file, config)
            
            % Get valid shaft frequency (may be here should be found 1,2,3 harmonics of shaft/
            % The first shaft harmonic find only now)
            peaksFound = getSimilarElements(file.shaftFrequency, file.peakTable, config.peakComparison);
            
            % Validate shaft frequency
            if isempty(peaksFound)
                correctedShaftFrequency = file.shaftFrequency;
                validFreq = false;
            elseif length(peaksFound) == 1
                correctedShaftFrequency = peaksFound;
                validFreq = true;
            else
                magnitides = file.peakTable(ismember(file.peakTable(:, 1), peaksFound), 2);
                [~, indexMax] = max(magnitides);
                correctedShaftFrequency = peaksFound(indexMax, 1);
                
                validFreq = true;
            end

        end
        
        % PHASETOZERO function cut signal, that phase of shaft frequency 
        % become zero
        function envelopeSignal = phaseToZero(envelopeSignal, currentPhase, allPeriod)
            
            if currentPhase < 0
                angleShift = (2 * pi) - abs(currentPhase);
            elseif currentPhase > 0
                angleShift = currentPhase;
            else
                angleShift = 2 * pi;
            end
            
            numberSamplesShift = round(angleShift * allPeriod / (2 * pi));
            envelopeSignal = envelopeSignal(numberSamplesShift:1:end);
        end
        
        % PLOTTSARESULT function plot result of TSA
        function plotTsaResult(resultStruct, file, numberFigure, config)
            
            range = strjoin(strsplit(num2str(ceil(resultStruct.range))));
            
            if resultStruct.validShaftFreq
                validFreqShaft = 'true';
            else
                validFreqShaft = 'false';
            end
            
            if resultStruct.validGM
                validGM = 'true';
            else
                validGM = 'false';
            end
            
            % Plot result TSA
            dtTSA = 1 / file.Fs;
            myFigure = figure('Units', config.sizeUnits, 'Position', config.imageSize, 'Visible', ...
                               config.plotVisible, 'Color', 'w');
            plot(0 : dtTSA : dtTSA * length(resultStruct.tsaSignal) - dtTSA, resultStruct.tsaSignal)
            
            if strcmp(config.plotTitle, 'on')
                title([upperCase(config.translations.timeSynchronousAveraging.Attributes.shortName) ' ' ...
                       resultStruct.gearingsNames '. Shaft frequency: ' num2str(resultStruct.shaftsFrequencies)])
            end
            
            xlabel([upperCase(config.translations.time.Attributes.name, 'first') ', ' config.translations.time.Attributes.value]);
            ylabel([upperCase(config.translations.acceleration.Attributes.name, 'first') ', ' config.translations.acceleration.Attributes.value]);
            
            YLim = max(get(gca, 'YLim'));
            XLim = max(get(gca, 'XLim'));
            
            txt1 = {['range: ' range], ...
                    ['Harmonic number gearing: ' num2str(resultStruct.harmonicNumber)], ...
                    ['validShaftFreq: ' validFreqShaft], ...
                    ['validGM: ' validGM], ...
                    ['deltaEnds: ' num2str(resultStruct.deltaEnds)], ...
                    ['modulationCoef: ' num2str(resultStruct.modulationCoef)], ...
                    ['mean: ' num2str(resultStruct.tsaMean)] ...
                   };

            text(XLim , YLim, txt1, 'HorizontalAlignment', 'right', 'EdgeColor', 'r', 'BackgroundColor', 'w', ...
                                    'VerticalAlignment', 'top')
            
             
            if config.printPlotsEnable
                % Save the image to the @Out directory
                fileName = ['TSA-acc-' strtrim(num2str(numberFigure))];
                fullFileName = fullfile(pwd, 'Out', fileName);
                print(myFigure, fullFileName, ['-d', config.imageFormat, config.imageQuality], ...
                                              ['-r', config.imageResolution]);
            end
            
			% Close figure with visibility off
            if strcmpi(config.plotVisible, 'off')
                close(myFigure)
            end            
            
        end
        
    end
    
end