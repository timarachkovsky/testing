classdef multiCorrelationHandler < correlationHandler
    %multiCorrelationHandler class implements time-domain period estimation
    %based on the correlation function analysis by different ways - linear
    %and logarithmic scales with cut noise or not; periods tables
    %comparison, 
    
    properties (Access = protected)
        
        periodsTable  %All periods tables - validated or not.
        %FullData contain all original periodicies, before comparison, including close.
        
    end
    
    methods (Access = public)
        
        % Constructor function
        function [myHandler] = multiCorrelationHandler(file, myConfig, myTranslations)
           if ~exist('myTranslations', 'var')
               myTranslations = [];
           end
           myHandler = myHandler@correlationHandler(file, myConfig, myTranslations);
        end
        
        function [myHandler] = addResult(myHandler, myResult, reset)
            if ~exist('reset', 'var')
                reset = false;
            end
            if isempty(myResult)
                outLog(myHandler, 'There is no data to add!');
                return;
            end
            if ~reset && (~isempty(myHandler.FullData))
                myResult = [myHandler.FullData myResult];  %Find similars in all data set. If reset - only in new periods table.
            end
            %Find a similar periodicies and choose the best of similars.
            periodicy = [myResult.period];
            [ similarValue, ~, similarIndexes ] = getSimilars( periodicy' );
            aloneIdxs = 1:numel(myResult);
            myPeriodsTable = myResult([]);
            for i = 1:numel(similarValue)
               theCurrPeriodIdxs = find(similarIndexes{i});
               theCurrPeriod = myResult(theCurrPeriodIdxs);
               [~, idx] = myHandler.maxValidPeriodTable(theCurrPeriod);
               myPeriodsTable(i) = theCurrPeriod(idx);
               aloneIdxs(theCurrPeriodIdxs) = zeros(size(theCurrPeriodIdxs));
            end
            aloneIdxs = logical(aloneIdxs);
            myPeriodsTable = [myPeriodsTable myResult(aloneIdxs)];
            %Choose and set valid result. Rewrite because result taken from the full data set.
            [myHandler] = addResult@correlationHandler(myHandler, myPeriodsTable, 1);
            %Set a full data and a unique periods table. Rewrite because result taken from the full data set.
            myHandler.periodsTable = myPeriodsTable;
            myHandler.FullData = myResult;
        end
        
        function [myHandler] = periodEstimation(myHandler)
            outLog(myHandler, ['\n\n\n\n===========' myHandler.picNmStr '===========\n\n'], 'Loger');
            if str2double(myHandler.config.peaksDistanceEstimation.cutNoiseAndRescaling.Attributes.originalProcessingEnable)
                [myHandler] = periodEstimation@correlationHandler(myHandler);
            end
            
            outLog(myHandler, '\n\n\n\nLinear scale with cut noise period estimation.\n')
            if str2double(myHandler.config.peaksDistanceEstimation.cutNoiseAndRescaling.Attributes.linearProcessingEnable)
                outLog(myHandler, 'Linear scale with cut noise period estimation', 'Loger');
                windWidth = str2num(myHandler.config.peaksDistanceEstimation.cutNoiseAndRescaling.Attributes.linearWindWidth);
            else
                windWidth = []; outLog(myHandler, 'Disabled.\n');
            end
            parameters.scale = 'ThresholdLin';
            for i = 1:numel(windWidth)
                outLog(myHandler, '\n\n');
                parameters.windWidth = windWidth(i);
                myHandler = cutNoiseAndRescale(myHandler, parameters);
                [myHandler] = periodEstimation@correlationHandler(myHandler);
            end
            
            outLog(myHandler, '\n\n\n\nLog scale period estimation.\n')
            if str2double(myHandler.config.peaksDistanceEstimation.cutNoiseAndRescaling.Attributes.logProcessingEnable)
                outLog(myHandler, 'Log scale period estimation', 'Loger');
                windWidth = str2num(myHandler.config.peaksDistanceEstimation.cutNoiseAndRescaling.Attributes.logWindWidth);
            else
                windWidth = []; outLog(myHandler, 'Disabled.\n');
            end
            parameters.scale = 'ThresholdLog';
            for i = 1:numel(windWidth)
                outLog(myHandler, '\n\n');
                parameters.windWidth = windWidth(i);
                myHandler = cutNoiseAndRescale(myHandler, parameters);
                [myHandler] = periodEstimation@correlationHandler(myHandler);
            end
            
            outResultTable(myHandler, [], '\n\nAll periods gotten all peaks table periods finding methods:');
            %The common peaks table.
            if str2double(myHandler.config.Attributes.periodsTableComparisonEnable)
                [~, fullPeriodsTable] = periodsTableComparison(myHandler);
                %Set a result - only the best of similars.
                [myHandler] = addResult(myHandler, fullPeriodsTable, 1);
                outResultTable(myHandler, myHandler.periodsTable, '\n\nThe best of similars periods with periods table comparison:');
            end
            
            %=====Make decision about probably side leafs and resonant periods in the ACF.===== 
            %Side leafs overlays with the main sequence and it's frequency is higher;
            %resonant (filling) frequency also may present in ACF.
            if str2double(myHandler.config.periodsValidation.Attributes.validationEnable)
                 myResult = validateSequencies(myHandler);
                [myHandler] = addResult(myHandler, myResult, 1);
            end
            
            %Compare periods with the current scalogramm point resonance.
            if str2double(myHandler.config.periodsValidation.Attributes.resonantPeriodsEnable)
                findResonantPeriods(myHandler);
            end
            
            
            if str2double(myHandler.config.peaksDistanceEstimation.absoleteThresholdFinding.Attributes.processingEnable)
                outLog(myHandler, 'Absolete threshold finding.\n')
                myHandler = absoleteThresholdFinding(myHandler);
            end
        end
        
        
		function [myResult, periodicySimilarsRates, sequeciesIdxs] = findIntersectPeriods(myHandler, myResult, parameters)
            %Find overlayings in the peaks tables, find periods with great overlay.
            %If sequence intersects with other which frequency is higher, it's probably side leafs of ACF.
            %Sensible part of peaks mb loss using greater thresholds or other way, in this case
            %degree of intersection is great, and lower sequecne is false.
            outLog(myHandler, '\n\n==Main - side leaf and lower false periodicies checking.==\n');
            if ~exist('myResult', 'var')
                myResult = [];
            end
            if isempty(myResult)
                myResult = myHandler.FullData;
            end
            periodicySimilarsRates = [];
            sequeciesIdxs = [];
            deleteIdxs = [];
            if numel(myResult) < 2
                return;
            end
            if ~exist('parameters', 'var')
                parameters = myHandler.config.periodsValidation.Attributes;
            end
            sideLeafDelete = str2double(parameters.sideLeafDelete);
            sideLeafMem = str2double(parameters.sideLeafMem);
            lowFalseDelete = str2double(parameters.lowFalseDelete);
            lowFalseMem = str2double(parameters.lowFalseMem);
            myResult = sortPeriodsTableByFreq(myHandler, myResult);
            HFinLFsideLeafThreshold = 0.1;  %Percent level of sequences intersection relative to possibly main's peaks number.
            LFinHFsideLeafThreshold = 0.6;
            lowFreqSimilarThreshold = 0.8;  %Percent level of sequences intersection relative to possibly main's peaks number.
            lowFreqHFinLFtresh = 0.25; %Maximum of HF in LF 2 be a low false, not side leaf.
            closeThreshold = 0.1;  %Don't take into account similars.
            k = 0;
            similarPeriodsMask = [];
            periodicySimilarsLFinHFRates = [];
            periodicySimilarsHFinLFRates = [];
            %===Find sequencies overlaying and make decision about sequencies falsity.===
            %If the most (> 80%) peaks of lower frequency are enter in high
            %frequency sequence, it's probably low frequency false sequence.
            %It's can be explain by outstanding from the main HF seq peaks or interf periods finding.
            %The side leafs are HF seqs, which partically (> 10% - part of HF) enter in the main LF seq,
            %the sensetive part (>60%) of the LF sequence peaks enter in the HF seq.
            %For sequencies with high intersection: if too many (25%) HF peaks are in low seq, it's not a low false, mb side leaf.
            for i = 1:numel(myResult)
               myPeaksTable = myResult(i).PeriodicyData.PeaksPositions;  %Potential main freq - lower.
                for j = i+1:numel(myResult)  %The higher freqs mb a side leaf (modulation) sequences.
                    k = k + 1;
                    myOverlayedPeaksTable = intersect(myPeaksTable, myResult(j).PeriodicyData.PeaksPositions);
                    LFinHF = numel(myOverlayedPeaksTable)/numel(myPeaksTable); %Low frequency elements in high frequency sequence.
                    periodicySimilarsLFinHFRates = [periodicySimilarsLFinHFRates LFinHF];
                    HFinLF = numel(myOverlayedPeaksTable)/numel(myResult(j).PeriodicyData.PeaksPositions);
                    periodicySimilarsHFinLFRates = [periodicySimilarsHFinLFRates HFinLF];
                    sequeciesIdxs{k} = [i j];  %Lower and higher freqs, indexes of the main and side (low false & higher) sequences properly.
                    similarPeriodsMask(k) = abs(myResult(i).frequency - myResult(j).frequency)/myResult(i).frequency < closeThreshold;
					MainSideValidationMask(k) = myResult(i).validity > 0.495; %If low (base) freq has enough validity.
					lowFalseValidationMask(k) = myResult(j).validity > 0.495; %If high (base) freq has enough validity.
                    if similarPeriodsMask(k)
                       continue; 
                    end
                    outLog( myHandler, sprintf('\nThe lower frequency: %10.5f; the higher frequency: %10.5f\n', myResult(i).frequency, myResult(j).frequency) );
                    outLog( myHandler, sprintf('The low freq periodicy number: %d; the high number: %d; overlay: %d; LFinHFRate: %10.5f; HFinLFRate: %10.5f.\n', numel(myPeaksTable), ...
                        numel(myResult(j).PeriodicyData.PeaksPositions), numel(myOverlayedPeaksTable), LFinHF, HFinLF) );
                    %low (potential main; low false) periodycy number: %d; the high (potential side leaf; higher)
                end
            end
            lowerFreqFalseIdxs = (periodicySimilarsLFinHFRates >= lowFreqSimilarThreshold).*(periodicySimilarsHFinLFRates < lowFreqHFinLFtresh).*(~similarPeriodsMask).*double(lowFalseValidationMask);
            lowerFreqFalse = sequeciesIdxs(logical(lowerFreqFalseIdxs));
            mainSideValidIdxs = (periodicySimilarsLFinHFRates >= LFinHFsideLeafThreshold).*(periodicySimilarsHFinLFRates >= HFinLFsideLeafThreshold).*(~lowerFreqFalseIdxs).*double(~similarPeriodsMask).*double(MainSideValidationMask);  %Exclude false low freqs.
            mainSideValid = sequeciesIdxs(logical(mainSideValidIdxs));
            simIdxs = (periodicySimilarsLFinHFRates == 1).*(~similarPeriodsMask); %Check completely similar sequencies.
            lowerSim = sequeciesIdxs(logical(simIdxs)); lowerFreqFalse = [lowerFreqFalse lowerSim];
            myResult = arrayfun(@(x) fill_struct(x, 'secondaryPeriodicies', []), myResult);
                myResult = arrayfun(@(x) setfield(x, 'secondaryPeriodicies', fill_struct(x.secondaryPeriodicies, 'sideLeafs', [])), myResult);
                myResult = arrayfun(@(x) setfield(x, 'secondaryPeriodicies', fill_struct(x.secondaryPeriodicies, 'lowerFreqSimilars', [])), myResult);
            for i = 1:numel(lowerFreqFalse)
                outOneResult( myHandler, myResult(lowerFreqFalse{i}(2)), sprintf('\nThe main period is %d:', lowerFreqFalse{i}(2)) );
                outOneResult( myHandler, myResult(lowerFreqFalse{i}(1)), sprintf('The lower freq false period is %d:', lowerFreqFalse{i}(1)) );
                if lowFalseMem
                    myResult(lowerFreqFalse{i}(2)).secondaryPeriodicies.lowerFreqSimilars = [myResult(lowerFreqFalse{i}(2)).secondaryPeriodicies.lowerFreqSimilars myResult( lowerFreqFalse{i}(1) )];
                end
                if lowFalseDelete
                    deleteIdxs = [deleteIdxs lowerFreqFalse{i}(1)];  %Add low false 2 deletion list.
                end
            end
            for i = 1:numel(mainSideValid)
                if numel(find(mainSideValid{i}(1) == deleteIdxs))
                    continue;  %If lower frequency period is detected like trash, don't process it.
                end
                outOneResult( myHandler, myResult(mainSideValid{i}(1)), sprintf('\nThe main period is %d:', mainSideValid{i}(1)) );
                outOneResult( myHandler, myResult(mainSideValid{i}(2)), sprintf('The side leaf period is %d:', mainSideValid{i}(2)) );
                if sideLeafMem
                    myResult(mainSideValid{i}(1)).secondaryPeriodicies.sideLeafs = [myResult(mainSideValid{i}(1)).secondaryPeriodicies.sideLeafs myResult( mainSideValid{i}(2) )];
                end
                if sideLeafDelete
                    deleteIdxs = [deleteIdxs mainSideValid{i}(2)];  %Add side leaf 2 deletion list.
                end
            end
            deleteIdxs = unique(deleteIdxs);
            if nnz(deleteIdxs)
                myResult(deleteIdxs) = arrayfun(@(x) setfield(x, 'validity', 0), myResult(deleteIdxs)); %Delete false results.
            end
		end
			
		function myResult = validateSequencies(myHandler, myResult, parameters)
            outLog(myHandler, '\n\n==Periods validation.==\n');
            if ~exist('myResult', 'var')
                myResult = [];
            end
            if isempty(myResult)
                myResult = myHandler.FullData;
            end
            deleteIdxs = [];
            if isempty(myResult)
                return;
            end
            if ~exist('parameters', 'var')
                parameters = myHandler.config.periodsValidation.Attributes;
            end
            lowPeaksThreshold = 0.5;
            %Peaks tables validation weights: weights of validities 2 get result validity.
            %Compute validities of each table by set of checking calculations or use validity of each checking result.
            checksNum = 5;
            delWeights = str2double(parameters.trashPeaksTableDeleteWeights);
            trashPeaksTableDelete = isempty(parameters.trashPeaksTableDeleteWeights); %Empty weights means separate deletion.
            if nnz(isnan(delWeights)) %If empty - zero weights - don't count common validity.
                delWeights = zeros(1, checksNum);
            end
            if delWeights == 1 %Equal weights.
                delWeights = repmat(1/checksNum, 1, checksNum);
            end
            %In other case all weights assigned, delete according to the common validity.
            %Validate sequencies by peaks tables and signal averages relations.
            peaksTables = arrayfun(@(x) getfield(x, 'PeaksPositions'), [myResult.PeriodicyData], 'UniformOutput', false);
            myCoefficients = double(myHandler.signalProcessed.myCoefficients);
            [~, myCoefficients] = detrendACF(myHandler, myCoefficients);
            peaksHeightRMSes = cellfun(@(x) rms(myCoefficients(x)), peaksTables);
            peaksHeightValidities = peaksHeightRMSes/rms(myCoefficients);
            peaksHeightValidities = restrictDynamicalRange([0 1], [1 2.3], peaksHeightValidities);
            lowIdxs = find(peaksHeightValidities < lowPeaksThreshold);
            if nnz(lowIdxs)
                outResultTable(myHandler, myResult(lowIdxs), 'Low peaks (trash) sequences:');
            end
            highPeaksNumRel = cellfun(@(x) sum(myCoefficients(x) > rms(myCoefficients))/numel(x), peaksTables);
            lowGoodPeaksNumIdxs = find(highPeaksNumRel < lowPeaksThreshold);
            if nnz(lowGoodPeaksNumIdxs)
                outResultTable(myHandler, myResult(lowGoodPeaksNumIdxs), 'Low good peaks number (trash) sequences:');
            end
            [~, locs, ~, proms] = findpeaks(myCoefficients);
            %Indexes of each element of sequence peaks table in the cmmon PT.
            for i = 1:numel(peaksTables)
                %Index of the closest of the common PT element to each PeaksPosition's elem.
                [~, idxsProm{i}] = arrayfun(@(x) min(abs(locs-x)), peaksTables{i});
            end
            %Validate periodicies by average sequences peaks prominences and signal std and all peaks average proms.
            promTables = cellfun(@(x) proms(x), idxsProm, 'UniformOutput', false);
            promsAv = cellfun(@(x) mean(x), promTables);
            promValidities = promsAv/std(myCoefficients);
            promValidities = restrictDynamicalRange([0 1], [1 2], promValidities);
            lowPromIdxs = find(promValidities < lowPeaksThreshold);
            promValidsMean = promsAv/mean(proms);
            promValidsMean = restrictDynamicalRange([0 1], [1 2], promValidsMean);
            lowMeanIdxs = find(promValidsMean < lowPeaksThreshold);
            if nnz(lowPromIdxs)
                outResultTable(myHandler, myResult(lowPromIdxs), 'Low prominent (std) peaks (trash) sequences:');
            end
            if nnz(lowMeanIdxs)
                outResultTable(myHandler, myResult(lowMeanIdxs), 'Low prominent (pks mean) peaks (trash) sequences:');
            end
            outLog( myHandler, sprintf('Sequencieses freqs:  %s.\n', num2str([myResult.frequency], '%3.4f ')) );
            outLog( myHandler, sprintf('RMSes:               %s; \nRMSvalids:           %s.\n', num2str(peaksHeightRMSes, ' %3.4f '), num2str(peaksHeightValidities, '%3.4f ')) );
            outLog( myHandler, sprintf('Good peaks part:     %s.\nSignal RMS: %2.5f.\n', num2str(highPeaksNumRel, ' %3.4f '), rms(myCoefficients)) );
            outLog( myHandler, sprintf('Prominencies:        %s; \nPromValids:          %s.\nRMSmeanValids:       %s;\n', num2str(promsAv, ' %3.4f '), num2str(promValidities, ' %3.4f '), num2str(promValidsMean, ' %3.4f ')) );
            outLog( myHandler, sprintf('Signal STD: %2.5f, peaks prominences mean: %2.5f.\n', std(myCoefficients), mean(proms)) );
            lowPromIdxs = unique([lowPromIdxs lowMeanIdxs]);
            if trashPeaksTableDelete
                deleteIdxs = [deleteIdxs lowIdxs lowGoodPeaksNumIdxs lowPromIdxs];  %Add low prominent peaks (trash) sequencies 2 deletion list.
            end
            %-=Periods stability validation Delete non stable seqs and "torn" sequencies.=-
            %-Distance STD in frames.-
            PeaksDistSTDwind = arrayfun(@(x) getfield(x, 'PeaksDistSTD'), [myResult.PeriodicyData], 'UniformOutput', true);
            distRelW = [myResult.distance]./PeaksDistSTDwind;
            distValidW = restrictDynamicalRange([0 1], [3 10], distRelW);
            distStabIdxsW = find(distValidW < lowPeaksThreshold);
            %-General distance STD.-
            PeaksDistSTD = cellfun(@(x) std(diff(x)), peaksTables, 'UniformOutput', true);
            nanDstIdxs = isnan(PeaksDistSTD); PeaksDistSTD(nanDstIdxs) = zeros(size( PeaksDistSTD(nanDstIdxs) ));
            distRel = [myResult.distance]./PeaksDistSTD;
            distValid = restrictDynamicalRange([0 1], [3 10], distRel);
            distStabIdxs = find(distValid < lowPeaksThreshold);
            %-Valid windows position STD.-
            validFrames = arrayfun(@(x) getfield(x, 'validFrames'), [myResult.PeriodicyData], 'UniformOutput', false);
            %Relation of number valid windows and the last window number.
            %If there low numb of valid and many non-valid frames, relation became low.
            distRelVF = cellfun(@(x) std(diff(x)), validFrames, 'UniformOutput', false);
            nanDstIdxs = cellfun(@(x) isnan(x), distRelVF); distRelVF(nanDstIdxs) = cellfun(@(x) zeros(size(x)), distRelVF(nanDstIdxs), 'UniformOutput', false);
            distValidVF = cellfun(@(x) restrictDynamicalRange([0 1], [5 1], x), distRelVF, 'UniformOutput', true);
            distStabIdxsVF = find(distValidVF < lowPeaksThreshold);
            %-Validation by number of large distancies.-
            %Sequence shifting and missing of peaks (fading, noise) lead to peaks distancies
            %became small or large, that leads to big distances STD, but sequence still valid.
            %But if sequence is "torn" - contain a few casual periods, their distances will
            %be much more than sequences distance; also non-valid periods mb started in the middle of signal - 
            %the most strong periods peaks are situated in the beginning of the signal.
            periodsDistancies = cellfun(@(x) diff([0 x]), peaksTables, 'UniformOutput', false); %All peaks distances.
            beginningDistances = cellfun(@(x) x(1), periodsDistancies, 'UniformOutput', true);
            periodsDistancies = cellfun(@(x) diff(x), peaksTables, 'UniformOutput', false); %All peaks distances.
            emptDstIdxs = cellfun(@(x) isempty(x), periodsDistancies); periodsDistancies(emptDstIdxs) = cellfun(@(x) zeros(1, 1), periodsDistancies(emptDstIdxs), 'UniformOutput', false);
            distancesNumb = cellfun(@(x) numel(x), periodsDistancies, 'UniformOutput', true); %General distances number.
            largeDistTresh = 2*[myResult.distance];
            largeDistNumb = cellfun(@(x, y) nnz(x > y), periodsDistancies, arrayfun(@(x) x, largeDistTresh, 'UniformOutput', false), 'UniformOutput', true); %Large distances number.
            distRelPK = distancesNumb./largeDistNumb;
            distValidPK = restrictDynamicalRange([0 1], [3 10], distRelPK);
            distStabIdxsPK = find(distValidPK < lowPeaksThreshold);
            distStabIdxsBGvalid = arrayfun(@(x, y) x > y, beginningDistances, 2.5*largeDistTresh, 'UniformOutput', true);
            distStabIdxsBG = find(distStabIdxsBGvalid);
            outLog( myHandler, sprintf('Stability wind rels: %s; \nStability wind vals: %s.\n', num2str(distRelW, '%3.4f '), num2str(distValidW, '%3.4f ')) );
            outLog( myHandler, sprintf('Stability peak rels: %s; \nStability peak vals: %s.\n', num2str(distRel, '%3.4f '), num2str(distValid, '%3.4f ')) );
            outLog( myHandler, sprintf('Stability frms rels: %s; \nStability frms vals: %s.\n', num2str(distRel, '%3.4f '), num2str(distValidVF, '%3.4f ')) );
            outLog( myHandler, sprintf('Stability dist rels: %s; \nStability dist vals: %s.\n', num2str(distRelPK, '%3.4f '), num2str(distValidPK, '%3.4f ')) );
            outLog( myHandler, sprintf('Beginning distances: %s; \nPeriods distancies:  %s.\n', num2str(beginningDistances, '%3.4f '), num2str([myResult.distance], '%3.4f ')) );
            if nnz(distStabIdxsW)
                outResultTable(myHandler, myResult(distStabIdxsW), 'Non stable (wind - info only) sequencies:');
            end
            if nnz(distStabIdxs)
                outResultTable(myHandler, myResult(distStabIdxs), 'Non stable peak (info only) sequencies:');
            end
            if nnz(distStabIdxsVF)
                outResultTable(myHandler, myResult(distStabIdxsVF), 'Non stable (valid frames positions - info only) sequencies:');
            end
            if nnz(distStabIdxsPK)
                outResultTable(myHandler, myResult(distStabIdxsPK), 'Non stable (large distances number) sequencies:');
            end
            if nnz(distStabIdxsBG)
                outResultTable(myHandler, myResult(distStabIdxsBG), 'Non stable (far form beginning) sequencies:');
            end
            %Make exceptions for sequencies with assigned number of stable peaks higher RMS threshold and average
            %height of peaks higher RMS at least, exclude seqs with low by peaks average threshold elements.
            %Previous factors were for the whole tables, estimate them by window factors.
            %-=Get low distributed windows.=-
            numTreshs = str2num(parameters.peaksNumTresholds);
            periodsDistancies = cellfun(@(x, y) x-y, periodsDistancies, num2cell([myResult.distance]), 'UniformOutput', false);
            %Get indexes of peaks wich distances to next is in corridor +-0.5period.
            lowerThresholdDistributedIdxs = cellfun(@(x, y) x<y, periodsDistancies, num2cell(0.5*[myResult.distance]), 'UniformOutput', false);
            higherThresholdDistributedIdxs = cellfun(@(x, y) x>y, periodsDistancies, num2cell(-0.5*[myResult.distance]), 'UniformOutput', false);
            stablePeaksIndexes = cellfun(@(x, y) x&y, lowerThresholdDistributedIdxs, higherThresholdDistributedIdxs, 'UniformOutput', false);
            %Find valid windows, choose the biggest of them, check peaks number.
            for l = 1:numel(stablePeaksIndexes)
                stablePeaksIndexes{l} = takeOneByOneBands(double(~stablePeaksIndexes{l}), struct( 'succession', 'zero', 'minInSuccession', '1' )); %num2str(numTreshs(1))
                stablePeaksIndexes{l} = cellfun(@(x) x(1):x(end), stablePeaksIndexes{l}, 'UniformOutput', false);
                peaksNumbInWind{l} = cellfun(@(x) numel(x), stablePeaksIndexes{l}, 'UniformOutput', true);
            end
            empties = cellfun(@(x) isempty(x), peaksNumbInWind); peaksNumbInWind(empties) = repmat({0}, nnz(empties), 1);
            [peaksNums, windowIdxs] = cellfun(@(x) max(x), peaksNumbInWind); %Get the longest window.
            valTblsIdxs = peaksNums >= numTreshs(2); %Valid tables indexes by window peaks distance stablility.
            stablePeaksIndexes(valTblsIdxs) = cellfun( @(x, y) x(y), stablePeaksIndexes(valTblsIdxs), num2cell(windowIdxs(valTblsIdxs)) ); %Get the longest window cell.
            %-=Validate by RMS thresholds gotten stable sequencies.=-
            stablePTs = cell(size(peaksTables)); %Get peaks heights of the most stable windows of each periodicity.
            stablePTs(valTblsIdxs) = cellfun(@(x, y) y(x), stablePeaksIndexes(valTblsIdxs), peaksTables(valTblsIdxs), 'UniformOutput', false);
            stableSignals = cell(size(peaksTables)); %Get windows of signals, get RMSes.
            ranges = cell(size(valTblsIdxs)); windowRMSes = ranges; RMSthresholds = ranges;
            ranges(valTblsIdxs) = cellfun(@(x) [max([round(x(1)*0.95), 1]) min([round(x(end)*1.05), numel(myCoefficients)])], stablePTs(valTblsIdxs), 'UniformOutput', false );
            stableSignals(valTblsIdxs) = cellfun(@(x) myCoefficients(x(1):x(end)), ranges(valTblsIdxs), 'UniformOutput', false);
            windowRMSes(valTblsIdxs) = cellfun(@(x) rms(x), stableSignals(valTblsIdxs), 'UniformOutput', false);
            RMSthresholds(valTblsIdxs) = cellfun(@(x) max([x, rms(myCoefficients)]), windowRMSes(valTblsIdxs), 'UniformOutput', false);
            %-=Get peaks of signal windows over RMS threshold, comp. their average.=-
            %Get full peaks tables of stable window ranges: get PT from handlerAve, get aver. hei. of peaks over RMS thresh.
            highPTs = cell(size(valTblsIdxs)); highPTsIdxs = highPTs; stableFullPTs = highPTs; highRMSes = highPTs;
            myConfAve.span = '1width'; myConfAve.theBextPeaksNum = 'glob'; myConfAve.windowAveraging.saveSampling = '1'; myConfAve.Fs = num2str(myHandler.signal.Fs);
            if isempty(myHandler.handlerAve),  myHandlerAver = signalAveragingHandler(myCoefficients, myConfAve); myHandler.handlerAve = myHandlerAver; end
            stableFullPTs(valTblsIdxs) = cellfun(@(x) myHandler.handlerAve.getTable([ 'orig' num2str([x(1) x(end)]) ]), ranges(valTblsIdxs), 'UniformOutput', false);
            highPTsIdxs(valTblsIdxs) = cellfun(@(x, y) x.indexes(myCoefficients(x.indexes) > 1.2*y), stableFullPTs(valTblsIdxs), RMSthresholds(valTblsIdxs), 'UniformOutput', false);
            highPTs(valTblsIdxs) = cellfun(@(x) myCoefficients(x), highPTsIdxs(valTblsIdxs), 'UniformOutput', false );
            highRMSes(valTblsIdxs) = cellfun(@(x) rms(x), highPTs(valTblsIdxs), 'UniformOutput', false );
            RMSthresholds(valTblsIdxs) = cellfun(@(x, y) max([x,y]), RMSthresholds(valTblsIdxs), highRMSes(valTblsIdxs), 'UniformOutput', false );
            %-=Compare with signal RMS, window RMS, peaks average thresholds, get PTs with enough stable great peaks number.=-
            valTblsIdxs = peaksNums >= numTreshs(1); %Valid tables indexes by window peaks distance stablility - redefine for window RMS comparison 2 rest small tables.
            stablePTs(valTblsIdxs) = cellfun(@(x, y) x(myCoefficients(x) > y), stablePTs(valTblsIdxs), RMSthresholds(valTblsIdxs), 'UniformOutput', false );
            %Fill missed positions: let tables with 1 missed on at least 3 peaks, but not more then 10%.
            valTblsIdxs = cellfun(@(x) numel(x) >= numTreshs(2), stablePTs); %intersect( find(peaksNums >= numTreshs(2)), find(cellfun(@(x) ~isempty(x), stablePTs)) ); %Valid non-empties.
            myConfIntf.widthEntity = 'samples'; myConfIntf.windWidth = '2000'; myConfIntf.framesValidation.Attributes.validityThreshold = '45'; myConfIntf.printEnable = '0';
            myConfIntf.peaksFinding.Attributes = struct('SortStr', 'descend', 'maxPeaksInResult', '4', 'minOverMaximumThreshold', '0.66', 'minOverMaxPromThreshold', '0.5', 'baseVal', '0');
            myConfIntf.PTfilling.Attributes = struct('missNumPerOnes', '1/3', 'numThreshold', '0.1', 'trustedInterval', '0.5dist');
            Attributes = arrayfun(@(x) setfield(myConfIntf.PTfilling.Attributes, 'distance', num2str(x.distance)), myResult, 'UniformOutput', false);
            configs = cellfun(@(x) setfield(myConfIntf, 'PTfilling', setfield(myConfIntf.PTfilling, 'Attributes', x)), Attributes, 'UniformOutput', false);
            myInterfObj = cellfun(@(x, y) interferenceClass(y, myHandler.handlerAve, [], x), stablePTs(valTblsIdxs), configs(valTblsIdxs), 'UniformOutput', false );
            [~, fullTable, ~, missedTable] = cellfun(@(x) fillMissedIdxs(x, 'orig'), myInterfObj, 'UniformOutput', false );
            %Replace PTs by valid filled tables.
            stablePTs(valTblsIdxs) = fullTable;
            validIdxs = cellfun(@(x) numel(x) >= numTreshs(1), stablePTs); %Indexes of valid PTs with enough great and stable peaks.
            nonValidIdxs = find(~validIdxs); validIdxs = find(validIdxs);
            %-=Check low number tables. Rest tables which have prominent peaks, have no misses and situated near begin.=-
            fulls = false(size(stablePTs)); semiValidIdxs = fulls; highs = fulls; %Get indexes of semivalid and non-miss tables among valid tables, then get thier idxs.
            semiValsOfStables = cellfun(@(x) (numel(x) < numTreshs(1)) && (numel(x) >= numTreshs(2)), stablePTs(valTblsIdxs)); %Low stable PTs.
            fullMisses = false(size(semiValsOfStables)); fullMisses(semiValsOfStables) = cellfun(@(x) isempty(x), missedTable(semiValsOfStables));
            fulls(valTblsIdxs) = fullMisses; semiValidIdxs(valTblsIdxs) = semiValsOfStables;
            %Semivalid sequencies should start from the first-second positions.
            %closes = arrayfun(@(x, y) x < y, beginningDistances, largeDistTresh, 'UniformOutput', true);
            closes = false(size(stablePTs)); closes(valTblsIdxs) = beginningDistances(valTblsIdxs) < largeDistTresh(valTblsIdxs);
            %Minimum height of their peaks is 2*rms.
            highs(valTblsIdxs) = cellfun(@(x) nnz(myCoefficients(x) >= 2*rms(myCoefficients)) >= numTreshs(2), stablePTs(valTblsIdxs));
            fullSemiValIdxs = semiValidIdxs & fulls & closes & highs;
            %-=Except approved tables from del list and delete non-valids=-
            excList = intersect(validIdxs, distStabIdxsBG); if (~isempty(excList)) && (~isempty(distStabIdxsBG)), distStabIdxsBG = setxor(distStabIdxsBG, excList); end
            if trashPeaksTableDelete
                deleteIdxs = [deleteIdxs distStabIdxsPK distStabIdxsBG nonValidIdxs];  %Add non stable sequencies 2 deletion list.
            end
            
            %Compute the common validity.
            if nnz(delWeights)
                validMx = vertcat(double(distStabIdxsBGvalid), distValidPK, promValidsMean, promValidities, peaksHeightValidities);
                validWeightMx = (delWeights').*validMx;
                commonTablesValids = sum(validWeightMx, 1);
                commValDelIdxs = find(commonTablesValids < lowPeaksThreshold);
                if nnz(commValDelIdxs)
                    outResultTable(myHandler, myResult(commValDelIdxs), 'Full validation trash sequencies:');
                end
                deleteIdxs = [deleteIdxs commValDelIdxs];
            end
            if nnz(fullSemiValIdxs), deleteIdxs = setxor(deleteIdxs, find(fullSemiValIdxs), 'stable'); end
            %Delete sequencies which freqs exceed frequency range.
            outFreqIdxs = find([myResult.frequency] < str2double(myHandler.config.Attributes.minFrequency));
            if nnz(outFreqIdxs)
                outResultTable(myHandler, myResult(outFreqIdxs), 'Low frequency (trash) sequences:');
            end
            if str2double(parameters.freqRangeLimit)
                deleteIdxs = [deleteIdxs outFreqIdxs];  %Add outside frequency range sequencies 2 deletion list.
            end
            deleteIdxs = unique(deleteIdxs);
            if nnz(deleteIdxs)
                myResult(deleteIdxs) = arrayfun(@(x) setfield(x, 'validity', 0), myResult(deleteIdxs)); %Delete false results.
            end
			myResult = findIntersectPeriods(myHandler, myResult, parameters);
            %===Remember some validation data.===
            myResult = arrayfun( @(x, y) setfield(x, 'validationData', setfield(x.validationData, 'peakSequenceHeightRMS', y)), myResult, peaksHeightRMSes );
            myResult = arrayfun( @(x, y) setfield(x, 'validationData', setfield(x.validationData, 'peakSequenceHeightRMSvalidity', y)), myResult, peaksHeightValidities );
            myResult = arrayfun( @(x, y) setfield(x, 'validationData', setfield(x.validationData, 'peakSequencePromsAverage', y)), myResult, promsAv );
            myResult = arrayfun( @(x) setfield(x, 'validationData', setfield( x.validationData, 'signalRMS', rms(myCoefficients) )), myResult );
            myResult = arrayfun( @(x) setfield(x, 'validationData', setfield( x.validationData, 'signalMeanProminence', mean(proms) )), myResult );
        end
        
        function resonantFreqIdx = findResonantPeriods(myHandler, myResult)
            outLog(myHandler, '\n\n==Resonant periodicies checking.== \n');
            if ~exist('myResult', 'var')
                myResult = [];
            end
            if isempty(myResult)
                myResult = myHandler.FullData;
            end
            if isempty(myResult)
                outLog(myHandler, 'There is no any resonant frequency sequence.\n'); return;
            end
            resonantClosenessThresh = 0.1;  % Percent range where seek possibly resonant frequency sequence.
            if isfield(myHandler.config, 'pointFreq')
                freqs = [myResult.frequency];
                [~, resonantFreqIdx] = min(abs(freqs - myHandler.config.pointFreq)); % The closest element to res freq.
                resonantFreqPeriodicy = freqs(resonantFreqIdx);
                if (myHandler.config.pointFreq - resonantFreqPeriodicy)/myHandler.config.pointFreq < resonantClosenessThresh
                    outOneResult( myHandler, myResult(resonantFreqIdx), '\nResonant frequency sequence:' );
                else
                    outLog( myHandler, sprintf('The closest sequence frequency %10.5f, scalogram point freq %10.5f.\n', resonantFreqPeriodicy, myHandler.config.pointFreq) );
                    outLog(myHandler, 'There is no any resonant frequency sequence.\n');
                end
            end
        end
        
        %Find a similar periodicies, make a commons from them - the common
        %peaks table, estimate period by the common table; add new tables
        %to FullData and fill in periodsTable with only unique and valid
        %tables; make a common periods table and find periods in.
        function [theCommonPeriodTable, fullPeriodsTable] = periodsTableComparison(myHandler, myBaseTable)
            if ~exist('myBaseTable', 'var')
                myBaseTable = myHandler.FullData;
            end
            myBaseTable = arrayfun(@(x) fill_struct(x, 'secondaryPeriodicies',[]), myBaseTable);
            %Make period tables for all peaks.
            myHandler.peaksTable = [myBaseTable.PeriodicyData];
            myHandler = myHandler.peakTableComparison;
            theCurrPeaksTable = myHandler.peaksTable;
            %ThresholdKind in base (period) table characterises the way which the table was gotten,
            %in PeriodicyData field (peaks table) - which way(s) validated each peak.
            %So, rest peak's threshold kinds, because they were gotten earlier, but assign to table comparison label.
            bigPeriodTable = peaks2PeriodTable(myHandler, theCurrPeaksTable);
            bigPeriodTable = arrayfun( @(x) setfield(x, 'ThresholdKind', 'allPeaksComparison'), bigPeriodTable );
            bigPeriodTable = arrayfun(@(x) fill_struct(x, 'secondaryPeriodicies', []), bigPeriodTable);
            outResultTable(myHandler, bigPeriodTable, '\n\nAll peaks comparison.', 'fullForbid');
            myBaseTable = [myBaseTable bigPeriodTable];
            periodicy = [myBaseTable.period];
            %Find tables computed by different methods with similar periods 4 getting a common peaks table.
            [ ~, ~, similarIndexes ] = getSimilars( periodicy' );
            k = 0;
            similarsPeriodsTables = myBaseTable([]);
            for i = 1:numel(similarIndexes)
                if ~iscell(similarIndexes)  %There is no any simlars.
                    break
                end
                %Get peaks tables of similar periodicies, make a common of them and find periods in it (similars).
                currIdx = find(similarIndexes{i});
                myHandler.peaksTable = [myBaseTable(currIdx).PeriodicyData];
                myHandler = myHandler.peakTableComparison;
                %Find periods by joined peaks table.
                theCurrPeaksTable = myHandler.peaksTable;
                %Divide on three thresholds, find and validate periods.
                theCurrPeriodTable = peaks2PeriodTable(myHandler, theCurrPeaksTable);
                theCurrPeriodTable = arrayfun(@(x) fill_struct(x, 'secondaryPeriodicies', []), theCurrPeriodTable);
                theCurrPeriodTable = arrayfun( @(x) setfield(x, 'ThresholdKind', 'similarPeriodPeaksComparison'), theCurrPeriodTable );
                if ~isempty(theCurrPeriodTable)
                    %Periods tables gotten from similars.
                    similarsPeriodsTables(k + 1:k + numel(theCurrPeriodTable)) = theCurrPeriodTable;
                end
                k = k + numel(theCurrPeriodTable);
                %theCommonPeriodTable(i).similarTables = myBaseTable(currIdx);
            end
            theCommonPeriodTable = [similarsPeriodsTables bigPeriodTable];
            outResultTable(myHandler, theCommonPeriodTable, '\n\nSimilar periodisies the common peaks table period finding.', 'fullForbid');
            fullPeriodsTable = [similarsPeriodsTables myBaseTable];  %All periods tables - initial and similars.
            %Find tables computed by different methods with similar periods 4 writind a similars.
            periodicy = [fullPeriodsTable.period];
            [ ~, ~, similarIndexes ] = getSimilars( periodicy' );
            for i = 1:numel(similarIndexes)
                if ~iscell(similarIndexes)  %There is no any simlars.
                    similarsPeriodsTables = myBaseTable([]);
                    break
                end
                currIdx = find(similarIndexes{i});
                for j = 1:numel(currIdx)
                    %Write indexes in the full data of similar periods except the current.
                    fullPeriodsTable(currIdx(j)).secondaryPeriodicies.similars = currIdx( currIdx~=currIdx(j) );
                end
            end
        end
        
        %Return a period tables of found in the peaks table periodicies.
        function theCommonPeriodTable = peaks2PeriodTable(myHandler, myPeaksTable)
                [peaksTablesThresholds] = myHandler.peaksTable2thresholds(myPeaksTable);
                for i = numel(peaksTablesThresholds):-1:1 %Order chosen to rest mainCoeffs according 2 low peaks table.
                    [ baseTablesThresholds{i}, mainCoefficients ] = findPeriods4PeaksTable(myHandler, peaksTablesThresholds(i));
                end
                [theCommonPeriodTable] = compareBaseTables(myHandler, baseTablesThresholds{1}, baseTablesThresholds{2}, baseTablesThresholds{3});

                [theCommonPeriodTable] = validateBaseTable(myHandler,theCommonPeriodTable,mainCoefficients);
        end
        
        function myHandler = cutNoiseAndRescale(myHandler, parameters)
            Root=fullfile(fileparts(mfilename('fullpath')),'..','..','..','..');
            myConfig = myHandler.config;
            windWidth = num2str(parameters.windWidth);
            %=====Make a log scale correlogramm and cut off the noise.=====
            mode = '';
            %Prepare a signal for log noise detection.
            if myHandler.signal.cutNoiseLevel||(strcmp(parameters.scale, 'ThresholdLog'))
                %Subtraction a low peaks trend 4 log scale without noise cutting.
                %The first zero sample in detrended signals makes the rest peaks too high.
                %If we cut off noise level, all low samples are delete.
                if parameters.windWidth == 0
                    mode = 'lowTrend, renewForbidd';
                end
            end
            %Restore original data.
            myHandler = acfPreProcess(myHandler, 0, mode);
            myPositions = myHandler.signal.myPositions;
            myCoefficients = double(myHandler.signal.myCoefficients);
            if strcmp(parameters.scale, 'ThresholdLog') && (parameters.windWidth == 0)
                baseValue = min(myCoefficients); % [m/s^2]
                baseValue = max([baseValue 1e-24]);
                logScale = abs(20 * log10((myCoefficients+myCoefficients(end)/2) / baseValue));
                logScale = logScale - min(logScale);
                myHandler.signal.myCoefficients = single(logScale);
                myHandler.signal.cutNoiseLevel = false;
                myHandler.signal.windowWidth = 0;
                myHandler.signal.scale = parameters.scale;
                if str2double(myConfig.Attributes.fullSavingEnable)
                    figure('units','points','Position',[0, 0, 1000, 800]);
                    hold on
                    plot(myPositions, logScale/max(logScale)*max(myCoefficients), 'r');
                    plot(myPositions, myCoefficients, 'c');
                    saveas(gcf, fullfile(Root, 'Out', [myHandler.picNmStr 'Correlogramm ' upper(parameters.scale) sprintf(' %4.2f widths', str2double(windWidth)) '.jpg']), 'jpg');
                    hold off
                    close gcf;
                end
                return
            end
            file.frequencies = myPositions;
            file.spectrum = myCoefficients;
            file.Fs = myHandler.signal.Fs;
            %Compute noise level by window averaging in log scale and cut it off on pointed scale.
            logConf.frameLength = windWidth;
            logConf.cutoffLevel = num2str(-1);
            logConf.plotEnable = myConfig.Attributes.fullSavingEnable;
            printEnable = double(strcmp(myConfig.printEnable, '1') || strcmp(myConfig.printEnable, '2'));
            logConf = fill_struct(logConf, 'printEnable', num2str(printEnable));
            [Result, ~, ~] = logScalingData(file, logConf, '');
            if strcmp(parameters.scale, 'ThresholdLin')
                %Get noise level in linear scale from log data.
                noiseLevelVector = Result.noiseLevelVector;
                baseValue = max([min(myCoefficients) 1e-24]);
                noiseLevelVector = baseValue*10.^(noiseLevelVector/20);
                cutPeaksData = myCoefficients - noiseLevelVector;
                cutPeaksData(cutPeaksData < 0) = zeros(size( cutPeaksData(cutPeaksData < 0) ));
            else
                %Signal was translated to log scale.
                cutPeaksData = Result.cutPeaksData;
            end
            if sum(cutPeaksData) == 0
               cutPeaksData = cutPeaksData + 1e-24; 
            end
            myHandler.signal.scale = parameters.scale;
            if str2double(myConfig.Attributes.fullSavingEnable)
                figure('units','points','Position',[0, 0, 1000, 800]);
                hold on
                plot(myPositions, cutPeaksData/max(cutPeaksData)*max(myCoefficients), 'r');
                plot(myPositions, myCoefficients, 'c');
                axis( [ 0, ceil(0.05*max(myPositions)), 0, max(myCoefficients) ] );
                plot(myPositions, Result.noiseLevelVector/max(Result.noiseLevelVector)*max(myCoefficients));
                plot(myPositions, Result.amplitude/max(Result.amplitude)*max(myCoefficients));
                %axis( [ 0, ceil(0.008*max(myPositions)), 0, max(myCoefficients) ] );
                %saveas(gcf,fullfile(Root, 'Out', [myHandler.picNmStr 'CorrelogrammLog4' thresholdLevel 'ThresholdLevel.jpg']),'jpg');
                %saveas(gcf, fullfile(Root, 'Out', [myHandler.picNmStr 'CorrelogrammLog' sprintf(' %10.1f widths, %10.5f sec', i, windWidth) '.eps']), 'epsc');
%                     saveas(gcf, fullfile(Root, 'Out', [myHandler.picNmStr 'CorrelogrammLog' sprintf(' %10.1f widths', i) '.eps']), 'epsc');
                     saveas(gcf, fullfile(Root, 'Out', [myHandler.picNmStr 'Correlogramm ' upper(parameters.scale) sprintf(' %4.2f widths', str2double(windWidth)) '.jpg']), 'jpg');
                hold off
                close gcf;
                
                figure('units','points','Position',[0, 0, 1000, 800]);
                hold on
                plot(myPositions, Result.cutPeaksData);
                plot( myPositions, repmat(str2double(myConfig.peaksDistanceEstimation.(parameters.scale).Attributes.low), size(myPositions)) );
                plot( myPositions, repmat(str2double(myConfig.peaksDistanceEstimation.(parameters.scale).Attributes.average), size(myPositions)) );
                plot( myPositions, repmat(str2double(myConfig.peaksDistanceEstimation.(parameters.scale).Attributes.high), size(myPositions)) );
                axis( [ 0, ceil(0.05*max(myPositions)), 0, max(cutPeaksData) ] );
                hold off
                saveas(gcf, fullfile(Root, 'Out', [myHandler.picNmStr 'Correlogramm' upper(parameters.scale) sprintf('Peaks %4.2f widths', str2double(windWidth)) '.jpg']), 'jpg');
                close gcf;
                outLog( myHandler, sprintf('Log peak std: %10.5f; norm std: %10.5f; mean: %10.5f.\n', std(cutPeaksData), std(cutPeaksData)/mean(cutPeaksData), mean(cutPeaksData)) );
            end
            myHandler.signal.myCoefficients = single(cutPeaksData);
            myHandler.signal.cutNoiseLevel = true;
            myHandler.signal.windowWidth = str2double(windWidth);
        end
        
        function myHandler = absoleteThresholdFinding(myHandler)
            Root=fullfile(fileparts(mfilename('fullpath')),'..','..','..','..');
            outLog(myHandler, 'Absolete threshold periods finding', 'Loger');
            %Weak modulation can appear like one-two great peaks in the beginning.
            myHandler = acfPreProcess(myHandler);
            myCF = myHandler.signal.myCoefficients;
            Fs = myHandler.signal.Fs;
            maxFrequency = str2double(myHandler.config.Attributes.maxFrequency);
            minPeaksDictance = Fs/maxFrequency;
            [globalLocs, ~] = myHandler.findGlobalPeaks(minPeaksDictance, 'ThresholdLin', 'high', 'max');
                    myPeaksTable.PeaksPositions = globalLocs;
                    myPeaksTable.heights = myCF(globalLocs);
                    myPeaksTable.thresholdLevel = repmat( 'high', size(globalLocs) );
                    myPeaksTable.thresholdKind = repmat( {'absThreshold'}, size(globalLocs) );
                    [ baseTableHigh ] = findPeriods4PeaksTable(myHandler, myPeaksTable);
                    
                    [ baseTableWeak, mainCoefficientsW ] = findPeriods4PeaksTable(myHandler, myPeaksTable, 1);
            
            %=====Check possibly weak modulation: 1-2 peags close to beginning greater the rest all peaks.=====
            possiblyWeakModylationsValidity = 0;
            %Check a high peaks number.
            if numel(globalLocs) < 3
                possiblyWeakModylationsValidity = 1
            else
                outLog(myHandler, 'There are not weak modulation processes.\n');
            end
            %Check a distance from the beginning, it should be not so big.
            if possiblyWeakModylationsValidity
                diffVect = diff([0 globalLocs'])
                numberOfLowDistancePeaks = numel(find( diffVect < minPeaksDictance*10 ))
                %If the only or the both peaks are close to beginning and each oher - possibly it is.
                if numberOfLowDistancePeaks ~= numel(globalLocs)
                    possiblyWeakModylationsValidity = 0
                end
            end
            
            [globalLocsAver, ~] = myHandler.findGlobalPeaks(minPeaksDictance, 'ThresholdLin', 'average', 'abs');
                    myPeaksTable.PeaksPositions = globalLocs;
                    myPeaksTable.heights = myCF(globalLocs);
                    myPeaksTable.thresholdLevel = repmat( 'high', size(globalLocs) );
                    myPeaksTable.thresholdKind = repmat( {'absThreshold'}, size(globalLocs) );
                    [ baseTableAverage ] = findPeriods4PeaksTable(myHandler, myPeaksTable);
            %Check globality of found peaks: they should be .
            if possiblyWeakModylationsValidity
                outLog(myHandler, sprintf('The average peaks number: %d.\n', numel(globalLocsAver)) );
                if numel(globalLocsAver) < 5 + numel(globalLocs)
                    possiblyWeakModylationsValidity = 0.5
                end
                if numel(globalLocsAver) < 3 + numel(globalLocs)
                    possiblyWeakModylationsValidity = 1
                end
            end
            
            %Make a periods tables and validate them. Find periods by thresholds from the absolete maximum.
            [globalLocsLow] = myHandler.findGlobalPeaks(minPeaksDictance, 'ThresholdLin', 'low', 'abs');
                    myPeaksTable.PeaksPositions = globalLocsLow;
                    myPeaksTable.heights = myCF(globalLocsLow);
                    myPeaksTable.thresholdLevel = repmat( 'low', size(globalLocsLow) );
                    myPeaksTable.thresholdKind = repmat( {'absThreshold'}, size(globalLocsLow) );
                    [ baseTableLow, mainCoefficients ] = findPeriods4PeaksTable(myHandler, myPeaksTable);
            [baseTable] = compareBaseTables(myHandler, baseTableLow, baseTableAverage, baseTableHigh);
            [baseTable] = validateBaseTable(myHandler, baseTable, mainCoefficients);
            baseTable = arrayfun( @(x) setfield(x, 'ThresholdKind', 'Lin_AbsThresholds_'), baseTable );
            outResultTable(myHandler, baseTable, '\n\n Abs base table validation.', 'fullForbid');
            
            %Make a PerTable from the high threshold, make a low-number PerTable, weakModulation method.
            [baseTableWeak] = compareBaseTables(myHandler, baseTableWeak, baseTableWeak, baseTableWeak);
            [baseTableWeak] = validateBaseTable(myHandler, baseTableWeak, mainCoefficientsW);
            baseTableWeak = arrayfun( @(x) setfield(x, 'ThresholdKind', 'WeakMod'), baseTableWeak );
            baseTableWeak = arrayfun( @(x) setfield(x, 'validity', 0.4), baseTableWeak );  %It's not valid periodicy.
            possiblyWeakModylationsValidity = possiblyWeakModylationsValidity/numel(baseTableWeak);
            baseTableWeak = arrayfun( @(x) setfield(x, 'validationData', setfield(x.validationData, 'possiblyWeakModylationsValidity', possiblyWeakModylationsValidity)), baseTableWeak );
            outResultTable(myHandler, baseTableWeak, '\n\n Weak modulation base table validation.', 'fullForbid');
            
            %Find the most close periodicy to High table weak modulation, assign a label.
            if ~isempty(baseTable) && (numel(baseTableWeak) == 1)
                freqs = [baseTable.frequency];
                idxs = abs(freqs - baseTableWeak.frequency)/baseTableWeak.frequency < 0.1;
                if nnz(idxs)
                    [~, maxIndex] = myHandler.maxValidPeriodTable(baseTable(idxs));
                    wModInAbsIdx = idxs(maxIndex);
                    baseTable(wModInAbsIdx).validationData.wModLbl = 1;
                end
            end
            [myHandler] = addResult(myHandler, baseTableWeak);
            
            if str2double(myHandler.config.Attributes.fullSavingEnable)
                %Cut off ACF to save the last high peak + 20%.
                if ~ numel(globalLocs) %To not cause an error.
                    globalLocs = numel(myHandler.signal.myPositions);
                end
                cutCFidx = ceil(globalLocs(end)*1.2);
                if cutCFidx > length(myCF)
                    cutCFidx = length(myCF);
                end
                myCF = myCF(1:cutCFidx);
                figure; hold on
                myPositions = myHandler.signal.myPositions(1:cutCFidx);
                plot(myPositions, myCF)
                stem(myPositions(globalLocs), myCF(globalLocs), 'r+');
                hold off
                saveas(gcf,fullfile(Root, 'Out', [myHandler.picNmStr 'possiblyWeakModulations.jpg']),'jpg');
            end
        end
        
        %Divide peaks table (PeriodicyData) to three thresholds.
        function [resultTables] = peaksTable2thresholds(myHandler, myPeaksTable, mode)
            %Return three peaks tables divided by three levels. Depending on mode
            %result tables contain only their level data ('only') or all peaks higher the threshold (default).
            if ~exist('mode', 'var')
                mode = [];
            end
            resultTables = cell(1, 3);
            thresholdLevel = [myPeaksTable.thresholdLevel];
            thresholdLevNum = myHandler.thresholdLevels2Nums(thresholdLevel);
            for i = 1:numel(resultTables)
                idxs = (thresholdLevNum >= i);
                if strcmp('only', mode)
                    idxs = (thresholdLevNum == i);
                end
                resultTables{i} = myPeaksTable;
                resultTables{i}.PeaksPositions = resultTables{i}.PeaksPositions(idxs);
                resultTables{i}.thresholdKind = resultTables{i}.thresholdKind(idxs);
                resultTables{i}.thresholdLevel = resultTables{i}.thresholdLevel(idxs);
            end
            %lowTable = resultTables{1};  averageTable = resultTables{2}; highTable = resultTables{3};
            resultTables = cellfun(@(x) x, resultTables);  %Cells2arr.
        end
        
        function myPeriodsTable = sortPeriodsTableByFreq(myHandler, myPeriodsTable)
            if ~exist('myPeriodsTable', 'var')
               myPeriodsTable = myHandler.FullData;
            end
            if isempty(myPeriodsTable)
               return; 
            end
            freqs = [myPeriodsTable.frequency];
            [~, I] = sort(freqs);
            myPeriodsTable = myPeriodsTable(I);
        end
        
    end
    
    methods (Access = protected)
        
        %Add possibility to make a periods table for low peaks number for non peaks distance based methods.
        function [ myTable, mainCoefficients ] = findPeriods4PeaksTable(myHandler, myPeaksTable, lowNumberPeriodsEnable)
            if ~exist('lowNumberPeriodsEnable', 'var')
                lowNumberPeriodsEnable = false;
            end
           PP = myPeaksTable.PeaksPositions;
           if ~numel(PP)
               myTable = [];
               mainCoefficients = [];
               return;
           end
            [ myTable, mainCoefficients ] = findPeriods4PeaksTable@correlationHandler(myHandler, myPeaksTable);
            if isempty(myTable) && lowNumberPeriodsEnable
               %Set low-number table.
               mainCoefficients = double(myHandler.signal.myCoefficients);
               mainCoefficients = mainCoefficients(1:PP(end));
               myTable.validity = 0.5;
               dist = diff([0 reshape(PP, [], length(PP))]);
               myTable.distance = mean(dist);
               myTable.periodsNumber = numel(PP);
               myTable.ThresholdKind = 'interfPeriodsFinding';
               PD.thresholdLevel = repmat({'high'}, size(PP));
               PD.thresholdKind = repmat({'interfPeriodsFinding'}, size(PP));
               PD.PeaksPositions = reshape(PP, [], length(PP));
               PD.validFrames = 1;
                PD.PeaksDistancies = dist;
                PD.PeaksDistSTD = std(dist);
                PD.AverageLeaf = [];
                PD.LowLeaf = [];
               myTable.PeriodicyData = PD;
            end
        end
        
    end
    
    methods (Access = public, Static = true)
       
        function [maxValidityTable, maxIndex] = maxValidPeriodTable(myTable)
            if isempty(myTable)
                maxValidityTable = [];
                maxIndex = [];
                return;
            end
            validities = [myTable.validity];
            [ similarValue, ~, similarIndexes, aloneIdxs ] = getSimilars( validities', struct('range','1') );
            if iscell(similarIndexes)
               similarIndexes = cellfun(@(x) find(x), similarIndexes, 'UniformOutput', false); 
            else
                similarIndexes = [];
            end
            if aloneIdxs
                similarIndexes = [similarIndexes' arrayfun(@(x) x, aloneIdxs, 'UniformOutput', false)];
            end
            similarValue = [similarValue' validities(aloneIdxs)];
            [~, theMostValidIdx] = max(similarValue); %Index of similars indexes set or alone idx, that have max validity.
            ptIdxs = similarIndexes{theMostValidIdx};  %Indexes of the most valid tables.
            validPeriodsTable = myTable(ptIdxs);
            peaksNumbers = arrayfun(@(x) numel(x.PeriodicyData.PeaksPositions), validPeriodsTable);
            [~, maxValidityIndex] = max(peaksNumbers);  %Index of the most peaks number in the most valid periodicies vector.
            maxIndex = ptIdxs(maxValidityIndex);  %Index of maximum by peaks number from maxes by validity in the common table.
            maxValidityTable = validPeriodsTable(maxValidityIndex);  %Table with max peaks number from maxes by validity.
        end
        
    end
    
end