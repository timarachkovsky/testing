classdef fuzzyFrequencyEstimator < frequencyEstimator
    %FUZZYFREQUENCYESTIMATOR implements main shaft frequency estimation and
    %correction.
    %Estimator's work is based on the found frequencies marking, their 
    %validation with main frequency changing in the specific range to find
    %the most suitable frequency (by maximization of the validated freqs)
    %
    
    properties (Access = private)
        
        % kinematicsParser contains all kinematic scheme elements 
        % with their properties and parameters
        kinematicsParser 
        
        % InformativeTags contains the main informative features(tags) for
        % schemeClassifier work (to detect and separate elements defects)
        %informativeTags
        File
        
        % PeakThresholds contains 3 threshold levels in the envelope
        % spectrum peak: high, average and low.
        peakThresholds
        
    end

    methods (Access = public)
        % Constructor function
        function myFrequencyEstimator = fuzzyFrequencyEstimator (File, myKinematicsParser, config)
            
            estimatorType = 'fuzzy';
            myFrequencyEstimator = myFrequencyEstimator@frequencyEstimator(File,config,estimatorType);
            
            myFrequencyEstimator.kinematicsParser = myKinematicsParser;
            myFrequencyEstimator.baseFrequencies = File.baseFrequencies;
            myFrequencyEstimator.File = File;
            
            % Calculate 3 thresholds of envelope spectrum peaks for further
            % frequency estimation by rough (in wide range) and accurate
            % (in narrow range) channels
            myFrequencyEstimator.peakThresholds = createPeakThresholds(myFrequencyEstimator);
            
            myConfig = getConfig(myFrequencyEstimator); accuracy = {'rough', 'accurate'};
            for i = 1:numel(accuracy)
                myConfig.(accuracy{i}) = myConfig.config.parameters.evaluation.frequencyCorrector.fuzzyFrequencyEstimator.(accuracy{i});
            end
            myFrequencyEstimator = myFrequencyEstimator.setConfig(myConfig);
        end
        
        % Getters / Setters ...
        function [ myKinematicsParser ] = getKinematicsParser(myFrequencyEstimator)
            myKinematicsParser = myFrequencyEstimator.kinematicsParser;
        end
        function [ myFrequencyEstimator ] = setKinematicsParser(myFrequencyEstimator,myKinematicsParser)
            myFrequencyEstimator.kinematicsParser = myKinematicsParser;
        end
        
        function [ myFile ] = getFile(myFrequencyEstimator)
            myFile = myFrequencyEstimator.File;
        end
        function [ myFrequencyEstimator ] = setFile(myFrequencyEstimator, File)
            myFrequencyEstimator.File = File;
        end
        
        function [ myPeakThresholds ] = getPeakThresholds(myFrequencyEstimator)
            myPeakThresholds = myFrequencyEstimator.peakThresholds;
        end
        function [ myFrequencyEstimator ] = setPeakThresholds(myFrequencyEstimator,myPeakThresholds)
            myFrequencyEstimator.peakThresholds = myPeakThresholds;
        end
        % ... Getters / Setters
        
        % GETFREQUENCYESTIMATIONWITHACCURACY function implements estimation of the most
        % suitable frequency. Function changes the nominal frequency value
        % in specific range and checks the number of found validated tags 
        % (peak in the envelope spectrum). The greatest numbers are
        % associated with possible accurate frequencies.
        function [result,myFrequencyEstimator] = getFrequencyEstimationWithAccuracy(myFrequencyEstimator, accuracy)
            
            if nargin < 2
               accuracy = 'rough'; 
            end
            printStage(myFrequencyEstimator, ['Start estimation acceleration envelope spectrum peaks method with fuzzy logic with ' accuracy ' accuracy.'])
            
            % Set standard parameters for correct estimation evaluation
            myConfig = getConfig(myFrequencyEstimator);
            parameters = myConfig.config.parameters.evaluation.frequencyCorrector.fuzzyFrequencyEstimator.(accuracy).Attributes;
            myConfig.config.parameters.evaluation.frequencyDomainClassifier.peakComparison.Attributes.freqRange = parameters.peakComparisonFreqRange;
            myConfig.config.parameters.evaluation.frequencyDomainClassifier.peakComparison.Attributes.percentRange = parameters.peakComparisonPercentRange;
            myConfig.config.parameters.evaluation.frequencyDomainClassifier.peakComparison.Attributes.modeFunction = parameters.peakComparisonModeFunction;
            myConfig.config.parameters.evaluation.frequencyDomainClassifier.schemeValidator.Attributes.validLogLevel = '1.5';
            myConfig.config.parameters.evaluation.frequencyCorrector.fuzzyFrequencyEstimator.Attributes.percentRange = parameters.percentRange;
            myConfig.config.parameters.evaluation.frequencyCorrector.fuzzyFrequencyEstimator.Attributes.percentStep = parameters.percentStep;
            myConfig.(accuracy) = myConfig.config.parameters.evaluation.frequencyCorrector.fuzzyFrequencyEstimator.(accuracy);
            %Reset getting frames parameters: percent range is the first number, the rest are fuzzy stepping range.
            percentRange = str2num(myConfig.(accuracy).Attributes.percentRange); myConfig.(accuracy).Attributes.percentRange = num2str(percentRange(1));
            %Reset interpolation factor: use assigned for the current accuracy if it's exist. Set the common interp. factor if it wasn't assigned another.
            myConfig = fill_struct(myConfig, 'interpolationFactor', myConfig.config.parameters.evaluation.frequencyCorrector.Attributes.interpolationFactor);
            myConfig.(accuracy).Attributes = fill_struct(myConfig.(accuracy).Attributes, 'interpolationFactor', myConfig.interpolationFactor);
            myConfig.interpFactFuzzy = myConfig.(accuracy).Attributes.interpolationFactor;
            myConfig.minDistanceInterferenceRules = myConfig.config.parameters.evaluation.frequencyCorrector.Attributes.minDistanceInterferenceRules;
            myFrequencyEstimator = setConfig(myFrequencyEstimator,myConfig);
            plotEnable = logical(str2double(myConfig.config.parameters.evaluation.frequencyCorrector.fuzzyFrequencyEstimator.(accuracy).Attributes.plotEnable) * ...
                str2double(myConfig.config.parameters.evaluation.frequencyCorrector.fuzzyFrequencyEstimator.Attributes.plotEnable) * ...
                str2double(myConfig.debugModeEnable));
            myConfig.Attributes.fullSavingEnable = str2double(myConfig.config.parameters.evaluation.frequencyCorrector.fuzzyFrequencyEstimator.Attributes.fullSavingEnable);
            plotEnable = plotEnable || logical(myConfig.Attributes.fullSavingEnable);
            
            % Get 3 thresholds to create high, average and low prominence
            % groups of found peaks. Change nominal frequency in specific
            % range and check the number of valid peaks correcponding to
            % each frequency value; save result for each group of peaks to
            % the @peaksNumberTable.
            myPeakThresholds = getPeakThresholds(myFrequencyEstimator);
            peaksNumberTable = [];
            defPeakTableData = cell(size(myPeakThresholds)); %Valid defect data for each threshold contain cells with data for each probably frequency.
            
            [peaksNumberTable, fInterp, originalPeaksNumberTable, originalFreq, defPeakTableData]...
                = createPeaksNumberVector(myFrequencyEstimator);
            if isempty(find(originalPeaksNumberTable))
                result.frequency = [];
                result.probability = 0;
                result.frequencies = [];
                result.magnitudes = [];
                result.probabilities = 0;
                result.validities = 0;
                result.f = fInterp; result.interference = ones(size(fInterp));
                printStage(myFrequencyEstimator, sprintf('There is no any valid defect frequency peak for the current %10.5f base main shaft frequency!', myFrequencyEstimator.nominalFrequency));
                return;
            end
            
            f = originalFreq;
            
            % Normolize each peaksNumberTable row to make further
            % interference between them possible.
            normPeaksNumberTableInterp = bsxfun(@rdivide,peaksNumberTable,max(peaksNumberTable,[],2));
            normPeaksNumberTable = bsxfun(@rdivide,originalPeaksNumberTable,max(originalPeaksNumberTable,[],2));
            interference = ones(1,length(normPeaksNumberTable(1,:)));
            for i=1:1:length(normPeaksNumberTable(:,1))
                if find(originalPeaksNumberTable(i,:))
                    interference = bsxfun(@times, interference, normPeaksNumberTable(i,:));
                end
            end
            %Interference and freq vect interpolated to the same as in
            %spectrum frames and interf. samples number.
            interferenceInterp = ones(1,length(normPeaksNumberTableInterp(1,:)));
            for i=1:1:length(normPeaksNumberTableInterp(:,1))
                if find(originalPeaksNumberTable(i,:))
                    interferenceInterp = bsxfun(@times,interferenceInterp,normPeaksNumberTableInterp(i,:));
                end
            end
            
            %=====Get all base freqs which have it's accord unique prominent def freqs.=====
            %Find all freqs with big number of valid defect freqs.
            pt = peaksFilter([0 interference 0], struct('minOverMaximumThreshold', '0.66', 'minRMSPeakHeight', '1'));
            %Zeros added to find the first and the last peaks/plateaus if they are the first or the last samples.
            %Indexes of found peaks are incremented throuth the first added zero sample - restore them.
            pt.indexes = pt.indexes - 1;
            lowTable = defPeakTableData{3}; %Data for the low threshold.
            highTable = defPeakTableData{1};
            pltIdxs = cell(size(pt));
            pltFreqsData = cell(size(pt));
            ptValidDefFreqs = cell(size(pt));
            ptValidDefLabels = cell(size(pt));
            %=====Get info about all base freqs from ranges.=====
            for i = 1:numel(pt.indexes) %Peaks/"plateaus".
                %Find all similar peaks number freqs - "plateaus".
                baseFreqsIdxs = getRangeFromIdx(myFrequencyEstimator, interference, pt.indexes(i));
				pltIdxs{i} = baseFreqsIdxs;
                pltFreqsData{i} = [lowTable{baseFreqsIdxs}];
                %Collect valid defect freqs for each base freq from range.
                validDefFreqs = cell(size(baseFreqsIdxs));
                validDefLabels = cell(size(baseFreqsIdxs));
                for j = 1:numel(baseFreqsIdxs)  %Base freqs in "plateau" and according valid def freqs.
                    validDefFreqs{j} = vertcat(validDefFreqs{j}, lowTable{baseFreqsIdxs(j)}.mainFrequencyValid{:});
                    validDefLabels{j} = vertcat(validDefLabels{j}, lowTable{baseFreqsIdxs(j)}.mainFrequencyNameValid{:});
                end
                ptValidDefFreqs{i} = validDefFreqs;
                ptValidDefLabels{i} = validDefLabels;
            end
            %Result is indexes in interference of base freqs - all valid peaks and plateaus freqs, according
            %data, defect frequencies upper low threshold and according defect labels.
            result.interfPeaksPlateaus = struct('pltIdxs', pltIdxs, 'pltFreqsData', pltFreqsData, 'ptValidDefFreqs', ptValidDefFreqs, 'ptValidDefLabels', ptValidDefLabels);
            k = 0;
            for j = 1:numel(result.interfPeaksPlateaus)  %Base freqs - peaks and plateaus.
                %=====Exclude frequencies form plateau with the similar defect higher frequencies.=====
                valIdxs = zeros(size(result.interfPeaksPlateaus(j).ptValidDefFreqs));
                valIdxs(1) = 1;
                %Find unique defect frequencies vectors for plateau's base frequencies.
                for i = 2:numel(valIdxs)
                    if numel(result.interfPeaksPlateaus(j).ptValidDefFreqs{1}) == numel(result.interfPeaksPlateaus(j).ptValidDefFreqs{i})
                        df = result.interfPeaksPlateaus(j).ptValidDefFreqs{1} - result.interfPeaksPlateaus(j).ptValidDefFreqs{i};
                        valIdxs(i) = nnz(df);
                    else
                        valIdxs(i) = 1;  %The similar number of unique frequencies may be gotten from different number of defect freqs. Why?
                    end
                end
                valIdxs = logical(valIdxs);
                %Rest only frequencies from one "plateau" range which have
                %unique defect frequency set.
                peaksDataStruct = trimFields(result.interfPeaksPlateaus(j), valIdxs);
                %=====Process each frequency in peak or plateau.=====
                for i = 1:numel(peaksDataStruct.ptValidDefFreqs)  %Base freqs in number interference - freqs in the current plateau.
                    k = k+1;  %Number of the all base freqs - all peaks and all freqs from plateaus with unique def freq set.
                    %Index of the current base frequency in interference vector.
                    [d, peaksOfNumberInterference{k}.baseFrequencyIdx] = min(abs(f(peaksDataStruct.pltIdxs(i)) - fInterp));
                    myNominalFrequency = f(peaksDataStruct.pltIdxs(i));
                    %Defect frequencies higher of the current nominal (base) frequency of interference.
                    [peaksOfNumberInterference{k}.defFrequencies, IA, IC] = unique(peaksDataStruct.ptValidDefFreqs{i});
                    %According labels - vectors for similar frequencies from different defects.
                    peaksOfNumberInterference{k}.ptValidDefLabels = peaksDataStruct.ptValidDefLabels{i}(IA);
                    peaksOfNumberInterference{k}.plateauPeakNumb = j;  %Number of the current peak or plateau to which this (i) frequency belong.
                    %Get high threshold data of the current base freq to get high threshold defect freqs.
                    freqVectValid = highTable{peaksDataStruct.pltIdxs(i)}.freqVectValid;
                    peaksOfNumberInterference{k}.highThresholdValid = zeros(size(peaksOfNumberInterference{k}.defFrequencies));
                    frameShift = (fInterp(end)+fInterp(1))/2 - myNominalFrequency; peaksOfNumberInterference{k}.shift = frameShift;
                    peaksOfNumberInterference{k}.shaftFrame = fInterp - frameShift;
                    for m = 1:numel(peaksOfNumberInterference{k}.defFrequencies)
                        myBaseFrequency = peaksOfNumberInterference{k}.defFrequencies(m);
                        highValidity = logical(find(myBaseFrequency == freqVectValid));  %Is this def freq in the high val table.
                        if ~isempty(highValidity) %Else - there is nothing found or vector with valid freqs by high thresh is empty.
                            peaksOfNumberInterference{k}.highThresholdValid(m) = highValidity;
                        end
                        %Get frames of defect frequencies.
                        peaksOfNumberInterference{k}.myResultDefFreqFrame(m) = getSmoothedSpectrumFrame(myFrequencyEstimator, myBaseFrequency, accuracy);
                        if myConfig.Attributes.fullSavingEnable
                            close all
                            str = sprintf('DefectFrequencyFrame_%s', strrep(peaksOfNumberInterference{k}.ptValidDefLabels{m}, '*', '.'));
                            plotFrameResults(peaksOfNumberInterference{k}.myResultDefFreqFrame(m), myNominalFrequency, str, '', myConfig)
                        end
                    end
                end
            end
            
            %=====Defect freqs frames interference=====
            defInterference = cell(size(peaksOfNumberInterference)); defFreqsRes = defInterference;
            for i=1:1:length(peaksOfNumberInterference)  %interf peak/nominal freq.
                defInterference{i} = ones(size(peaksOfNumberInterference{1}.myResultDefFreqFrame(1).f));
                for j = 1:numel(peaksOfNumberInterference{i}.myResultDefFreqFrame)  %Def freq & frame.
                    if peaksOfNumberInterference{i}.highThresholdValid(j)
                        defFreqFrame = peaksOfNumberInterference{i}.myResultDefFreqFrame(j).spectrumFrame;
                        defFreqFrame = defFreqFrame/max(defFreqFrame);
                        defInterference{i} = bsxfun(@times, defInterference{i}, defFreqFrame);
                    end
                end
                %Create interference results for estimators decision maker: form shaft variance
                %from all probable freqs, wich have their own interf peak(s) for further choosing by leader threshold.
                defFreqsRes = peaksFilter(defInterference{i}, myConfig.(accuracy).Attributes); result.defFreqsRes(i) = defFreqsRes;
                interferenceResults(i).frequencies = peaksOfNumberInterference{i}.shaftFrame(defFreqsRes.indexes);
                interferenceResults(i).magnitudes = defFreqsRes.magnitudes;
%                 %Probabitity of interference peaks from their number and magnitudes.
%                 interferenceResults(i).probabilities = defFreqsRes.validities;
                %Validity for choosing frequency from several probably base freqs.
                %It depends on peaks number, their relative to RMS level height, their widhth.
                interferenceResults(i).probabilities = defFreqsRes.validities.*defFreqsRes.magnitudes/rms(defInterference{i})./defFreqsRes.widths;
                interferenceResults(i).f = peaksOfNumberInterference{i}.shaftFrame;
                interferenceResults(i).interference = double(defInterference{i});
                %Frames of the first (main) shaft.
                interferenceResults(i).shaftSchemeName = myFrequencyEstimator.shaftSchemeName{1}; interferenceResults(i).shaftNumber = 1;
                interferenceResults(i).baseFrequency = fInterp(peaksOfNumberInterference{i}.baseFrequencyIdx);
                interferenceResults(i).shaftFramesTable = arrayfun(@(x) x.spectrumFrame, peaksOfNumberInterference{i}.myResultDefFreqFrame, 'UniformOutput', false); %Defect frames.
                %Set frames number according to harmonic number 2 consider decreasing probability
                %or set ones def 4 frames weight equality. Max frames numb = max harmonic num in set.
                %Problem: if some harmonic with high number will appear by chance, it will drop validity of all the rest.
                interferenceResults(i).frameNumbers = ones(size( reshape(interferenceResults(i).shaftFramesTable, 1, []) ));
                if str2double(myConfig.config.parameters.evaluation.frequencyCorrector.fuzzyFrequencyEstimator.Attributes.wieghtDefFrames)
                    defLbls = cellfun(@(x) strsplit(x, '*'), peaksOfNumberInterference{i}.ptValidDefLabels, 'UniformOutput', false);
                    defLbls = cellfun(@(x) x(1), defLbls); defHarmonics = cellfun(@(x) str2num(x), defLbls);
                    interferenceResults(i).frameNumbers = reshape(defHarmonics, 1, []);
                end
                %Indexes of valid frames: all frames are valid.
                interferenceResults(i).frameIndexes = find(interferenceResults(i).frameNumbers);
            end
            interferenceResults = arrayfun(@(x) restrictNumericStruct(x, 'double'), interferenceResults);
            
            % _______________________ Results _____________________ %
            %==Get estimated frequency within potential from number interf.==
            %Set necessary configs 4 decision maker from accel. interference class.
            myFrequencyEstimator.correspondenceTable = ones(numel(interferenceResults)); %Use the main shaft only.
            myFrequencyEstimator.config = myFrequencyEstimator.config.config.parameters.evaluation.frequencyCorrector.interferenceFrequencyEstimator;
            myFrequencyEstimator.config.Attributes.plotEnable = num2str(plotEnable); myFrequencyEstimator.config.debugModeEnable = myConfig.debugModeEnable;
            myFrequencyEstimator.config.Translations = myConfig.Translations; myFrequencyEstimator.config.plots = myConfig.plots;
            myFrequencyEstimator.config.plotVisible = myConfig.plotVisible; myFrequencyEstimator.config.printPlotsEnable = myConfig.printPlotsEnable;
            myFrequencyEstimator.config.validationFrames = myConfig.config.parameters.evaluation.frequencyCorrector.fuzzyFrequencyEstimator.validationFrames;
            %Get result: frequency, probability and shafts frequencies vector.
            fuzzyData = result; [result] = makeDecision(myFrequencyEstimator, interferenceResults, accuracy);
            myFrequencyEstimator = createCorrespondenceTable(myFrequencyEstimator);
            myFrequencyEstimator = recalculateBaseFrequencies(myFrequencyEstimator,result);
            result.frequenciesVector = myFrequencyEstimator.baseFrequencies;
            %Put in some additional data.
            myFrequencyEstimator.config = myConfig; result.additMethodData = fuzzyData;
            result.additMethodData.defInterference = defInterference;
            result.additMethodData.defFrameF = fInterp;
            result.additMethodData.numbInterf = interferenceInterp;  %Samples match with defFrameF.
            result.additMethodData.originalFreq = originalFreq;
            result.additMethodData.numbInterfOrig = interference;  %Samples match with peak data.
            result.additMethodData.defPeakTableData = defPeakTableData;
            result.additMethodData.numbInterfResult = pt;  %Number interference peaks.
            %Full data of base freqs with the most number according unique def freqs - number interf peaks and plateaus.
            result.additMethodData.peaksOfNumberInterference = peaksOfNumberInterference;
            result.additMethodData.defFreqsRes = defFreqsRes;
            
            % Save found results to properties
            if strcmp(accuracy,'rough')
                myFrequencyEstimator = setRoughFrequency(myFrequencyEstimator,result.frequency);
            elseif strcmp(accuracy,'accurate')
                myFrequencyEstimator = setAccurateFrequency(myFrequencyEstimator,result.frequency);
            end
            
            if myConfig.Attributes.fullSavingEnable
                figure('Units', 'points', 'Position', [0, 0, 800, 600], 'Visible', myFrequencyEstimator.config.plotVisible);
                plot(fInterp, interferenceInterp); hold on
                maxes = arrayfun(@(x) max(x.interference), interferenceResults); %Comp. norm. coeff.
                arrayfun(@(x) plot(x.f, x.interference/max(maxes)), interferenceResults);
                saveas(gcf, fullfile(pwd, 'Out', sprintf('fuzzy_est_frq_%1.3f.jpg', myFrequencyEstimator.nominalFrequency)), 'jpg');
                % Close figure with visibility off
                if strcmpi(myFrequencyEstimator.config.plotVisible, 'off')
                    close
                end
            end
            
            % _______________________ Plot Results _____________________ %
            if plotEnable == 1
                
                % Get parameters
                Translations = myFrequencyEstimator.translations;
                
                debugModeEnable = str2double(myFrequencyEstimator.config.debugModeEnable);
                plotVisible = myFrequencyEstimator.config.plotVisible;
                printPlotsEnable = str2double(myFrequencyEstimator.config.printPlotsEnable);
                sizeUnits = myFrequencyEstimator.config.plots.sizeUnits;
                imageSize = str2num(myFrequencyEstimator.config.plots.imageSize);
                fontSize = str2double(myFrequencyEstimator.config.plots.fontSize);
                imageFormat = myFrequencyEstimator.config.plots.imageFormat;
                imageQuality = myFrequencyEstimator.config.plots.imageQuality;
                imageResolution = myFrequencyEstimator.config.plots.imageResolution;
                
                % Number interference
                subplotsNumber = length(peaksNumberTable(:,1));
                thresholdName = {'High';'Average';'Low'};
                figure('Name', 'Fuzzy method of frequency estimation', 'NumberTitle', 'off', ...
                    'Units', 'points', 'Position', [0, 0, 800, 600], 'Visible', plotVisible)
                for i = 1:1:subplotsNumber
                    subplot(subplotsNumber+1,1,i)
                    hold on
                    plot(fInterp, peaksNumberTable(i,:));
                    plot(originalFreq, originalPeaksNumberTable(i,:));
                    hold off
                    xlabel('Frequency, Hz'); ylabel('PeaksNumber');
                    title([thresholdName(i,:),' threshold validated peaks number']);
                end
                subplot(subplotsNumber+1,1,subplotsNumber+1),plot(f,interference);
                xlabel('Frequency, Hz'); ylabel('Magnitude'); 
                title('Normolized Interference Frame');

                hold on;
                %Number interference peaks and plateaus freqs.
                stem(f([result.additMethodData.interfPeaksPlateaus.pltIdxs]), interference([result.additMethodData.interfPeaksPlateaus.pltIdxs]))
                hold off;
                % Close figure with visibility off
                if strcmpi(plotVisible, 'off')
                    close
                end
                
                % Defect freqs frames interference
                % Plot
                myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
                subplot(2, 1, 1);
                hold on;
                plot(fInterp, interferenceInterp);
                % Plot base frequency
                yLimits = ylim;
                stem(myFrequencyEstimator.nominalFrequency, yLimits(2), ...
                    'LineStyle', '--', 'Marker', 'none');
                stem(f([result.additMethodData.interfPeaksPlateaus.pltIdxs]), interference([result.additMethodData.interfPeaksPlateaus.pltIdxs]));
                hold off;
                grid on;
                
                % Get axes data
                myAxes = myFigure.CurrentAxes;
                % Set axes font size
                myAxes.FontSize = fontSize;
                
                % Plot title
                title([upperCase(Translations.shaftSpeedRefinement.Attributes.name, 'all'), ' - ', ...
                    upperCase(Translations.fuzzyValidator.Attributes.name, 'first'), ' : ', ...
                    upperCase(Translations.interference.Attributes.name, 'first'), ' - ', ...
                    upperCase(Translations.peaksNumber.Attributes.name, 'first'), ' : ', ...
                    upperCase(Translations.envelopeSpectrum.Attributes.name, 'allFirst'), ' - ', ...
                    upperCase(Translations.acceleration.Attributes.name, 'first')]);
                % Plot labels
                xlabel([upperCase(Translations.frequency.Attributes.name, 'first'), ', ', ...
                    upperCase(Translations.frequency.Attributes.value, 'first')]);
                ylabel(upperCase(Translations.magnitude.Attributes.name, 'first'));
                % Plot legend
                legend('Interference', 'Nominal frequency', 'Max peak number');
                
                subplot(2, 1, 2); hold on;
                fVects = cellfun(@(x) x.shaftFrame, result.additMethodData.peaksOfNumberInterference, 'UniformOutput', false);
                cellfun(@(x, y) plot(x, y/max(maxes)), fVects, defInterference);
                mins = cellfun(@(x) min(x), fVects); maxs = cellfun(@(x) max(x), fVects); xlim([min(mins), max(maxs)]);
                legendos = arrayfun(@(x) sprintf('Interference of %1.3f Hz', x.baseFrequency), interferenceResults, 'UniformOutput', false);
                % Plot base frequency
                yLimits = ylim;
                stem(myFrequencyEstimator.nominalFrequency, yLimits(2), ...
                    'LineStyle', '--', 'Marker', 'none');
                if ~isempty(result.frequency)
                   stem(result.frequency, result.magnitude(1)/max(maxes))
                end
                hold off;
                grid on;
                
                % Plot title
                title([upperCase(Translations.shaftSpeedRefinement.Attributes.name, 'all'), ' - ', ...
                    upperCase(Translations.fuzzyValidator.Attributes.name, 'first'), ' : ', ...
                    upperCase(Translations.interference.Attributes.name, 'first'), ' - ', ...
                    upperCase(Translations.defectFrequencies.Attributes.name, 'first'), ' : ', ...
                    upperCase(Translations.envelopeSpectrum.Attributes.name, 'allFirst'), ' - ', ...
                    upperCase(Translations.acceleration.Attributes.name, 'first')]);
                % Plot labels
                xlabel([upperCase(Translations.frequency.Attributes.name, 'first'), ', ', ...
                    upperCase(Translations.frequency.Attributes.value, 'first')]);
                ylabel(upperCase(Translations.magnitude.Attributes.name, 'first'));
                % Plot legend
                legend([legendos, 'Nominal frequency', 'Refined frequency']);
                
                if printPlotsEnable
                    imageNumber = '1';
                    fileName = ['SSR-fuzzyValidator-env-', imageNumber];
                    fullFileName = fullfile(pwd, 'Out', fileName);
                    print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
                end
                
                % Close figure with visibility off
                if strcmpi(plotVisible, 'off')
                    close(myFigure)
                end
                
                if checkImages(fullfile(pwd, 'Out'), fileName, imageFormat)
                    printStage(myFrequencyEstimator, 'The method images were saved.', 'fuzzyFrequencyEstimator');
                end
            end
            
        end
        
        % GETFREQUENCYESTIMATION function checks true frequency value
        % through rough and accurate channel ( enable parameters are places
        % in config.xml
        function [result,myFrequencyEstimator] = getFrequencyEstimation(myFrequencyEstimator,mode)
            
            if nargin < 2
                mode = 'rough';
            end
            
            if strcmp(mode, 'full')
                % Default parameters
                parameters = myFrequencyEstimator.config.config.parameters.evaluation.frequencyCorrector.fuzzyFrequencyEstimator;
                result.probability = 100;
                % Rough channel
                if str2double(parameters.rough.Attributes.processingEnable)
                    [result,myInterferenceEstimator] = getFrequencyEstimationWithAccuracy(myFrequencyEstimator,'rough');
                end
                % Accurate channel
                if str2double(parameters.rough.Attributes.processingEnable) && result.probability
                    [result,myInterferenceEstimator] = getFrequencyEstimationWithAccuracy(myInterferenceEstimator,'accurate');
                    if ~result.probability
                       [~, index] = max(result.interference);
                       result.frequency = result.f(index);
                       result.probability = 10;
                    end
                else
                    myFrequencyEstimator.accurateFrequency = result.frequency;
                end
            
            elseif strcmp(mode, 'rough')
                [result,myInterferenceEstimator] = getFrequencyEstimationWithAccuracy(myFrequencyEstimator,'rough');
                
            elseif strcmp(mode, 'accurate')
                [result,myInterferenceEstimator] = getFrequencyEstimationWithAccuracy(myFrequencyEstimator,'accurate');
                
            else
                printWarning(myFrequencyEstimator.iLoger, ['There is no such mode: ', mode, ' to operate!']);
                result.frequency = []; 
                result.probability = 0;
                result.interference = [];
                
            end
        end
    end
    
    methods (Access = private)
        
        % CHECKPEAKSTHRESHOLDS function checks if current peaks parameters
        % are good enough for shaft frequency estimation 
        function [status] = checkPeakThresholds(myFrequencyEstimator)
            
            myConfig = getConfig(myFrequencyEstimator);
            
            %Acceleration envelope spectrum peaks table.
            peakTable = myFrequencyEstimator.File.acceleration.envelopeSpectrum.peakTable;
            
            parameters = []; parameters = myConfig.config.parameters.evaluation.frequencyCorrector.fuzzyFrequencyEstimator.Attributes;
            lowLevel = str2double(parameters.lowLevel); 
            averageLevel = str2double(parameters.averageLevel);
            highLevel = str2double(parameters.highLevel);
            %Search by log peaks table.
            lowPeaksNumberNominal = str2double(parameters.lowNum);
            averagePeaksNumberNominal = str2double(parameters.averageNum);
            highPeaksNumberNominal = str2double(parameters.highNum);
            
            lowPeaksNum = length(find(peakTable(:, 4) > lowLevel));
            averagePeaksNum = length(find(peakTable(:, 4) > averageLevel));
            highPeaksNum = length(find(peakTable(:, 4) > highLevel));

            % Set status for highLevel [ valid(1),mbValid(0.5),nonvalid(0) ]
            if highPeaksNum >= highPeaksNumberNominal
                status.high = 1;
            elseif (highPeaksNum>=round(highPeaksNumberNominal/2)) && (highPeaksNum<highPeaksNumberNominal)
                status.high = 0.5;
            elseif highPeaksNum < round(highPeaksNumberNominal/2)
                status.high = 0;
            end
            
            % Set status for averageLevel [ valid(1),mbValid(0.5),nonvalid(0) ]
            if averagePeaksNum >= averagePeaksNumberNominal
                status.average = 1;
            elseif averagePeaksNum>=round(averagePeaksNumberNominal/2) && averagePeaksNum<averagePeaksNumberNominal
                status.average = 0.5;
            elseif averagePeaksNum < round(averagePeaksNumberNominal/2)
                status.average = 0;
            end
            
            % Set status for lowLevel [ valid(1),mbValid(0.5),nonvalid(0) ]
            if lowPeaksNum >= lowPeaksNumberNominal
                status.low = 1;
            elseif lowPeaksNum >= round(lowPeaksNumberNominal/2) && lowPeaksNum<lowPeaksNumberNominal
                status.low = 0.5;
            elseif lowPeaksNum < lowPeaksNumberNominal
                status.low = 0;
            end
            
            
            % If there  few valid found peaks, set overall status to
            % mbValid/unvalid(0), else set to valid state (1)
            if (status.high*status.average*status.low)>=0.5
                status.overall = 1;
            else 
                status.overall = 0;
            end  
        end
        
        % CREATEPEAKTHRESHOLDS
        function [ myPeakThresholds ] = createPeakThresholds(myFrequencyEstimator)
            
            % Find all peaks with standard parameters. Select the prominanse
            % value of the max one as a high bound and 2*rms value as a
            % low bound
            myConfig = getConfig(myFrequencyEstimator);
            
            %Acceleration envelope spectrum peaks table.
            peakTable = myFrequencyEstimator.File.acceleration.envelopeSpectrum.peakTable;
            
            %Make sure that thresholds of defect peak prominence from config are suitable.
            status = checkPeakThresholds(myFrequencyEstimator);
            parameters = [];
            parameters = myConfig.config.parameters.evaluation.frequencyCorrector.fuzzyFrequencyEstimator.Attributes;
            myFrequencyEstimator.printStage(sprintf('Peak thresholds: high %s, average %s, low %s.', parameters.highLevel, parameters.averageLevel, parameters.lowLevel));
            if status.overall == 1
                myPeakThresholds(1,1) = str2double(parameters.highLevel);
                myPeakThresholds(2,1) = str2double(parameters.averageLevel);
                myPeakThresholds(3,1) = str2double(parameters.lowLevel);
                myFrequencyEstimator.printStage(sprintf( 'Peak thresholds are checked.'));
            else
                %Number of peaks in some threshold is low.
                % Configuration parameters ... 
                maxPeakFrequency = str2double(parameters.maxPeakFrequency);
                lowNum = str2double(parameters.lowNum);
                averageNum = str2double(parameters.averageNum);
                highNum = str2double(parameters.highNum);
                [peakTable2] = peakTable(peakTable(:,1)<maxPeakFrequency,:);
                % ... configuration parameters

                %Check if peaks table is empty. Then rest a default thresholds.
                if isempty(peakTable2)
                    myPeakThresholds(1,1) = str2double(parameters.highLevel);
                    myPeakThresholds(2,1) = str2double(parameters.averageLevel);
                    myPeakThresholds(3,1) = str2double(parameters.lowLevel);
                    myFrequencyEstimator.printStage(sprintf( 'Peak thresholds are checked - peaks table is empty.'));
                    return;
                end
                
                logPeaksVector = sort(peakTable2(:, 4), 1, 'descend');
                %Set threshold like prominence with number equal to necessary peaks number.
                if status.low ~= 1 && status.low ~= 0 % Changed Kosmach 11.06.17
                    lowNum = min([lowNum, numel(logPeaksVector)]);
                    if lowNum > length(logPeaksVector)
                        lowNum = length(logPeaksVector);
                    end
                    myPeakThresholds(3,1) = logPeaksVector(lowNum);
                else
                    myPeakThresholds(3,1) = str2double(parameters.lowLevel);
                end
                if status.average ~=1 && status.average ~= 0 % Changed Kosmach 11.06.17
                    averageNum = min( [averageNum, ceil(lowNum*2/5)] );
                    if averageNum > length(logPeaksVector)
                        averageNum = length(logPeaksVector);
                    end
                    myPeakThresholds(2,1) = logPeaksVector(averageNum);
                else
                    myPeakThresholds(2,1) = str2double(parameters.averageLevel);
                end
                if status.high ~= 1 && status.high ~= 0 %Corrected. % Changed Kosmach 11.06.17
                    highNum = min( [highNum, ceil(lowNum*1/5)] );
                    if highNum > length(logPeaksVector)
                        highNum = length(logPeaksVector);
                    end
                    myPeakThresholds(1,1) = logPeaksVector(highNum);
                else
                    myPeakThresholds(1,1) = str2double(parameters.highLevel);
                end
                myFrequencyEstimator.printStage(sprintf( 'Estimated peak thresholds: high %10.1f, average %10.1f, low %10.1f',  myPeakThresholds(1,1), myPeakThresholds(2,1), myPeakThresholds(3,1) ));
                
                % Set low and high peaks threshold to the peakThreshold vector
    %             myPeakThresholds(1,1) = peaksNumVector(min(find(peaksNumVector(:,2)<=lowNum)),1);
    %             myPeakThresholds(2,1) = peaksNumVector(min(find(peaksNumVector(:,2)<=averageNum)),1);
    %             myPeakThresholds(3,1) = peaksNumVector(min(find(peaksNumVector(:,2)<=highNum)),1);

            end
        end
        
        % Creation of the peaksNumberVector filled with 
        function [peaksNumberVectors, freqVector, originalPeaksNumberVectors, originalFreqVector, defPeakTablesData]...
                = createPeaksNumberVector(myFrequencyEstimator)
           
            % Creation of the peakTable consisting of all found peaks
            % corresponding to current peak threshold
            myConfig = getConfig(myFrequencyEstimator);
            
            % Set interpolate factor
            interpolationFactor = str2double(myConfig.interpFactFuzzy);
            
            % Creation of the frequency variation range (standard [-5;+5]%)
            percentRange = str2num(myConfig.config.parameters.evaluation.frequencyCorrector.fuzzyFrequencyEstimator.Attributes.percentRange);
            percentStep = str2double(myConfig.config.parameters.evaluation.frequencyCorrector.fuzzyFrequencyEstimator.Attributes.percentStep);
            
            nominalFrequency = getRoughFrequency(myFrequencyEstimator);
            if isempty(nominalFrequency)
                nominalFrequency = getNominalFrequency(myFrequencyEstimator);
            end
            
            dFreq = nominalFrequency*percentStep/100;
            rngOrig = percentRange(1); Norig = 2*floor(rngOrig/percentStep) + 1; minFreq = nominalFrequency*(1 - rngOrig/100);
            if numel(percentRange) == 1
                N = 2*floor(percentRange/percentStep) + 1; startFreq = nominalFrequency*(1 - percentRange/100);
            else %If range assigned by start and end frequencies.
                percentRange = percentRange(2:end); %The first number sets spectrum frame wideness. The others are fuzzy nominal frequency stepping range.
                N = round(diff(percentRange)/dFreq); startFreq = percentRange(1); %Min freq is starting of the whole frame, startFreq is processing frame... 
            end %border, where nominal freqs will be setted.
            originalPeaksNumberVector = zeros(Norig, 1); %Save frame length ...
            originalFreqVector = zeros(Norig, 1); %for shorted windows.
            for i = 1:1:Norig
                originalFreqVector(i,1) = minFreq + dFreq*(i-1);
            end
            
            [d, startIdx] = min(abs(startFreq - originalFreqVector)); %Start index - index of frequency to process first.
            
            % Signal original
            % Recomendation : use @parfor instead @for
            defPeakTableData = cell(size(originalPeaksNumberVector));  %Data of every valid defect frequency according each probably main shaft frequency from range.
            if str2double(myFrequencyEstimator.config.config.parameters.common.parpoolEnable.Attributes.value)
                parfor i = startIdx:1:N+startIdx-1
                    defPeakTableData{i} = getPeaksData(myFrequencyEstimator, originalFreqVector(i,1));
                end    
            else
                for i = startIdx:1:N+startIdx-1
                    fprintf( '\nGetting peaks data for base frequency %10.3f.\n', originalFreqVector(i,1) );
                    defPeakTableData{i} = getPeaksData(myFrequencyEstimator, originalFreqVector(i,1));
                end    
            end
            
            myFrequencyEstimator.printStage('Getting peaks number for defect frequencies upper thresholds.');
            threshs = myFrequencyEstimator.peakThresholds;
            defPeakTablesData = cell(size(threshs));
            originalPeaksNumberVectors = zeros(numel(threshs), Norig);
            dirName = fullfile(pwd, 'Out', 'interfResults', 'fuzzyBaseFreqs'); mkdir(dirName);
            frVect = myFrequencyEstimator.File.acceleration.frequencyVector;
            ampl = myFrequencyEstimator.File.acceleration.envelopeSpectrum.amplitude;
            for j = 1:numel(threshs)
                for i = 1:numel(defPeakTableData)
                    if isempty(defPeakTableData{i}), continue; end
                    %Get indexes of defect freqs vector which are valid.
                    freqVectByValidatorIdx = find(defPeakTableData{i}.myFilledPeakTable(:, end));
                    freqVectByLogSpecIdx = find(defPeakTableData{i}.myFilledPeakTable(:, 4) > threshs(j));
                    valIdxs = intersect(freqVectByValidatorIdx, freqVectByLogSpecIdx);
                    %Get valid freqs values.
                    freqVectValid = defPeakTableData{i}.myFilledPeakTable(valIdxs, 1);
                    defPeakTableData{i}.freqVectValid = freqVectValid;
                    originalPeaksNumberVector(i,1) = numel(freqVectValid);
                    %==Save found freqs==
                    Freqz = defPeakTableData{i}.myFilledPeakTable(:, 1);
                    validrFreqz = Freqz(freqVectByValidatorIdx); logFreqz = Freqz(freqVectByLogSpecIdx);
                    fullValFreqz = Freqz(valIdxs); defPeakTableData{i}.freqz{j} = [validrFreqz; logFreqz];
                    [~, defPeakTableData{i}.validrFreqIdxs{j}] = arrayfun(@(x) min(abs(x-frVect)), validrFreqz, 'UniformOutput', true);
                    [~, defPeakTableData{i}.logFreqIdxs{j}] = arrayfun(@(x) min(abs(x-frVect)), logFreqz, 'UniformOutput', true);
                    [~, defPeakTableData{i}.fullVFreqIdxs{j}] = arrayfun(@(x) min(abs(x-frVect)), fullValFreqz, 'UniformOutput', true);
                end
                defPeakTablesData{j} = defPeakTableData;
                originalPeaksNumberVectors(j, :) = originalPeaksNumberVector;
            
                % Signal interpolation  
                originalSamples = 1:length(originalFreqVector);
                interpolateSampels = 1:1/interpolationFactor:length(originalFreqVector);
                freqVector = interp1(originalSamples,originalFreqVector,interpolateSampels,'linear');  %spline makes false peaks in samples where peaks number changed.
                peaksNumberVector = interp1(originalSamples,originalPeaksNumberVector,interpolateSampels,'linear');  %spline makes false peaks in samples where peaks number changed.
                peaksNumberVector(peaksNumberVector<0) = 0;
                peaksNumberVectors(j, :) = peaksNumberVector;
            end
            if str2double(myConfig.config.parameters.evaluation.frequencyCorrector.fuzzyFrequencyEstimator.Attributes.fullSavingEnable)
                try
                    for i = 1:numel(defPeakTableData)
                        fprintf('\n===Base frequency is %1.3f===\n', originalFreqVector(i));
                        for j = 1:numel(threshs)
                            fprintf('-=Threshold is %d dB.\n=-', threshs(j));
                            fprintf('Validator freqz: %s;\n Log freqz: %s;\n Full validated freqz: %s.\n', num2str(defPeakTableData{i}.validrFreqIdxs{j}'), num2str(defPeakTableData{i}.logFreqIdxs{j}'), num2str(defPeakTableData{i}.fullVFreqIdxs{j}'));
                        end
                        myFigure = figure('Units', 'points', 'Position', [0, 0, 800, 600], 'Visible', 'off', 'Color', 'w');
                        plot(frVect, ampl); hold on;
                        cellfun(@(x, y) stem(frVect(x), ampl(x), y), defPeakTableData{i}.validrFreqIdxs(1), {'k+'}); %{'k+', 'c+', 'b+'}
                        cellfun(@(x, y) stem(frVect(x), ampl(x), y), defPeakTableData{i}.logFreqIdxs(1), {'bx'}); %{'kx', 'cx', 'bx'}
                        cellfun(@(x, y) stem(frVect(x), ampl(x), y), defPeakTableData{i}.fullVFreqIdxs(1), {'ro'}); %{'ro', 'go', 'mo'}
                        legend('Envelope spectrum', 'Validator freqs', 'Log freqs', 'Full valid freqs');
                        xlim([0.9*frVect(min(defPeakTableData{i}.fullVFreqIdxs{1})), 1.1*frVect(max(defPeakTableData{i}.fullVFreqIdxs{1}))]);
                        ylim([0 max(ampl(defPeakTableData{i}.fullVFreqIdxs{1}))]);
                        nm = [num2str(i) ' - ' num2str(originalFreqVector(i))]; dname = fullfile(dirName, nm);
                        mkdir(dname); saveas(myFigure, fullfile(dirName, [nm '.jpg']), 'jpg');
                        close(myFigure) % Close figure with visibility off
                        fprintf('-=Defects=-\n');
                        for k = 1:numel(defPeakTableData{i}.defectName)
                            fprintf('Element %s, defect %s. Freqz:\n', defPeakTableData{i}.element{k}, defPeakTableData{i}.defectName{k});
                            cellfun(@(x, y) fprintf('Frequency %1.3f - label %s\n', x, y), num2cell(defPeakTableData{i}.mainFrequencyValid{k}), defPeakTableData{i}.mainFrequencyNameValid{k});
                            myFigure = figure('Units', 'points', 'Position', [0, 0, 800, 600], 'Visible', 'off', 'Color', 'w');
                            plot(frVect, ampl); hold on; freqz = defPeakTableData{i}.mainFrequencyValid{k};
                            [~, freqzIdxs] = arrayfun(@(x) min(abs(x-frVect)), freqz, 'UniformOutput', true);
                            stem(frVect(freqzIdxs), ampl(freqzIdxs), 'ro'); xlim([0.9*min(freqz), 1.1*max(freqz)]);
                            stem(frVect(defPeakTableData{i}.validrFreqIdxs{1}), ampl(defPeakTableData{i}.validrFreqIdxs{1}), 'k+');
                            stem(frVect(defPeakTableData{i}.logFreqIdxs{1}), ampl(defPeakTableData{i}.logFreqIdxs{1}), 'cx');
                            legend('Envelope spectrum', 'Defect freqs', 'Validator freqs', 'Log freqs');
                            saveas(myFigure, fullfile(dname, [nm ' - ' defPeakTableData{i}.defectName{k} '.jpg']), 'jpg');
                            close(myFigure) % Close figure with visibility off
                            close all % not desirable
                        end
                    end
                catch
                    fprintf('Picture output error.\n');
                end
            end
        end
        
        % Counting the number of peaks corresponding to the current
        % frequency
        function defPeakTableData = getPeaksData(myFrequencyEstimator, frequency)  %[ peaksNumber, defPeakTableData ]
            defPeakTableData = [];
            %Acceleration envelope spectrum peaks table.
            peakTable = myFrequencyEstimator.File.acceleration.envelopeSpectrum.peakTable;
            
            myKinematicsParser = getKinematicsParser(myFrequencyEstimator);
            myKinematicsParser = setShaftFreq(myKinematicsParser, frequency);
            myClassifierStruct = getClassifierStruct(myKinematicsParser);
            myFile = getFile(myFrequencyEstimator);
            % Set mode frequencyRefinement for frequency domain classifier
            myFile.frequencyRefinement = true;
            myConfig = getConfig(myFrequencyEstimator);
            mySchemeClassifier = schemeClassifier(myFile, myClassifierStruct, myConfig);
            [validStruct,myFilledPeakTable] = getValidatorStruct(mySchemeClassifier);             %#ok<*ASGLU>
            myFilledPeakTable = double(myFilledPeakTable); %Shift validity vector for log spectrum peak table.
            %Fill in log table.
            for i = 1:numel(myFilledPeakTable(:, end))
                currF = myFilledPeakTable(i, 1);
                [~, ClosIndF] = min(abs(peakTable(:, 1) -  currF));
                ClosValF = peakTable(ClosIndF, 1);
                if (ClosValF - currF) > (0.05 * currF)
                    %If there is a big difference between log peak and validator's one,
                    %the log peak doesn't accord him - set zero log prominence.
                    myFilledPeakTable(i, end - 1) = 0;
                else
                    %Set log prominence from matched frequency.
                    myFilledPeakTable(i, end - 1) = peakTable(ClosIndF, end);
                end
            end
            %peaksNumber = nnz(myFilledPeakTable(:,end));
            %defPeakTableData.validStruct = validStruct;
            defPeakTableData.myFilledPeakTable = myFilledPeakTable;
            %if peaksNumber
            nonEmptyDomain = find(arrayfun(@(x) ...
                ~isempty(validStruct(x).accelerationEnvelopeSpectrum), 1:1:length(validStruct)));
            idxWithEmptyDomain = arrayfun(@(x) ...
                ~isempty(validStruct(nonEmptyDomain(x)).accelerationEnvelopeSpectrum.mainFrequencyValid), ...
                1:1:length(nonEmptyDomain));
            idx = nonEmptyDomain(idxWithEmptyDomain); %Indexes of valid freqs in validStruct - defect frequencies with prominent peaks.
            defPeakTableData.indexes = idx; 
            defPeakTableData.element = arrayfun(@(x) [x.elementType '_' x.class], validStruct(idx), 'UniformOutput', false);
			defPeakTableData.defectName = arrayfun(@(x) x.defectName, validStruct(idx), 'UniformOutput', false);
			defPeakTableData.defectId = arrayfun(@(x) x.defectId, validStruct(idx), 'UniformOutput', false);
			defPeakTableData.baseFreq = arrayfun(@(x) x.basicFreqs, validStruct(idx), 'UniformOutput', false);
			defPeakTableData.mainFrequencyValid = arrayfun(@(x) x.accelerationEnvelopeSpectrum.mainFrequencyValid, validStruct(idx), 'UniformOutput', false);
			defPeakTableData.mainMagnitudeValid = arrayfun(@(x) x.accelerationEnvelopeSpectrum.mainMagnitudeValid, validStruct(idx), 'UniformOutput', false);
			defPeakTableData.mainProminenceValid = arrayfun(@(x) x.accelerationEnvelopeSpectrum.mainProminenceValid, validStruct(idx), 'UniformOutput', false);
			defPeakTableData.mainFrequencyNameValid = arrayfun(@(x) x.accelerationEnvelopeSpectrum.mainFrequencyNameValid, validStruct(idx), 'UniformOutput', false);
			defPeakTableData.mainFrequencyTagValid = arrayfun(@(x) x.accelerationEnvelopeSpectrum.mainFrequencyTagValid, validStruct(idx), 'UniformOutput', false);
			defPeakTableData.mainFrequencyTagNameValid = arrayfun(@(x) x.accelerationEnvelopeSpectrum.mainFrequencyTagNameValid, validStruct(idx), 'UniformOutput', false);
            %end
        end
        
        [ peakTable ] = dividedFindpeaks(File, Parameters);

    end
end

