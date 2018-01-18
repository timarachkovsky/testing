classdef peaksFinder
    %PEAKSFINDER class is used to find and validate signal peaks
    %   
    % Developer : ASLM
    % Version : v1.0
    % Date : 21.10.2016
    
    % Version : v2.1 Rewritten on Fuzzy logic. 
    % Ratgor, Kechik, Loschinin    % 2016-11-18
    
    properties (Access = private)
        % @signal property is the structure contains coefficients and 
        % positions fields
        signal
        signalType
        
        % Configuration structure
        config
        plotEnable
        plotVisible
        printPlotsEnable
        
        translations
        
        iLoger
        
        % @fuzzyContainer property contains the set of fuzzy-logic rules to
        % make decision about the most informative peaks in the signal
        rulesContainer
        
        % @result property contains all found peaks with the tag: global,
        % local, none
        result
        
        %Contains data about all peaks for setup parameters.
		allPeaks 
		
    end
    
    methods (Access = public)
        
        % Constructor method
        function [myFinder] = peaksFinder(mySignal, myConfig, mySignalType)
            
            if nargin < 3
                myFinder.signalType = ' ';
            else
                myFinder.signalType = mySignalType;
            end
            
            myFinder.signal = mySignal;
            myConfig.Attributes = fill_struct(myConfig.Attributes, 'waveletName', '');
            myFinder.config = myConfig;
            myFinder.plotEnable = str2double(myConfig.Attributes.plotEnable);
            myFinder.plotVisible = myConfig.Attributes.plotVisible;
            myFinder.printPlotsEnable = str2double(myConfig.Attributes.printPlotsEnable);
            myFinder.translations = mySignal.translations;
            myFinder.iLoger = loger.getInstance;
        end
        
        % Getters / Setters ...
        
        function [mySignal] = getSignal(myFinder)
            mySignal = myFinder.signal;
        end
        function [myFinder] = setSignal(myFinder,mySignal)
           myFinder.signal = mySignal; 
        end
        
        function [myConfig] = getConfig(myFinder)
            myConfig = myFinder.config;
        end
        function [myFinder] = setConfig(myFinder,myConfig,myScalogramConfig)
            myConfig.Attributes = fill_struct(myConfig.Attributes, 'waveletName', '');
            myFinder.config = myConfig; 
            % myScalogramConfig is optional:
			%we can set new scalogram config after loading new parameters.
            if nargin==3
				myFinder.signal.scalogramConfig = myScalogramConfig;
            end
        end
        
        function [myResult] = getResult(myFinder)
            myResult = myFinder.result;
        end
        function [myFinder] = setResult(myFinder, myResult)
            myFinder.result = myResult;
        end
		        
        function [myAllPeaks] = getAllPeaks(myFinder) % Kechik test
            myAllPeaks = myFinder.allPeaks;
        end
		
        %Return full information about scalogram - coefficients, peaks, configs
		function [myScalogramData] = getFullScalogramData(myFinder)
            myScalogramData.scalogramConfig = myFinder.signal.scalogramConfig;
            myScalogramData.coefficients = myFinder.signal.coefficients;
            myScalogramData.frequencies = myFinder.signal.frequencies;
            myScalogramData.scales = myFinder.signal.scales;
            myScalogramData.signalType = myFinder.signalType;
            myScalogramData.peakFinderConfig = myFinder.config;
            myScalogramData.translations = myFinder.translations;
            myScalogramData.validPeaks = myFinder.result;
            myScalogramData.allPeaks = myFinder.allPeaks;
        end
        
        % ... Getters / Setters
        
        % FINDPEAKS function looks for all peaks in the @signal;
        % validates found peaks based on their main parameters and returns
        % @result struct with true peaks info
        function [myFinder] = findPeaks(myFinder)
            
            peakFindConfig = myFinder.config.Attributes;
            % New field "allPeaks" with all peaks found with not normalized parameters.
            myFinder = createPeaksTable(myFinder);
           
            % -= Validity estimation methods =-
            %Fuzzy processing: File FIS if peakValidationMethod = 'FileFIS': RMS
            %normalization and container from file. If 'CodeFIS' -
            %validity thresholds assign relative to RMS and STD, max normalized.
            %For both fuzzies labels give for all peaks, result fills by valid 
            %peaks and exclude close if it's need and rest number of them.
			%Peak processing realised by different methods.
            switch (peakFindConfig.peakValidationMethod)
                case 'FileFIS'
                % Fine peak validation (based on fuzzy logic container files)
				% It use RMS normalization and constant validity thresholds.
					myFinder = evaluateFileFIS(myFinder);
                    myFinder = validationFuzzy(myFinder);
                    %Create peaks table; read FIS and it's parameters from file,
                    %set thresholds; evaluating FIS, getting validity - normalization in
                    %temp copy; validationFuzzy - assign validity labels;
                    %throw out "waste" peaks, write valid to result; draw graphics.
                case 'CodeFIS'
                % Fine peak validation (based on fuzzy logic code-tunable container)
				% It use maximum scalogram normalization and additional parameter "globality".
				% Validity thresholds assign by STD and RMS.
					myFinder = NormaliseToMAX(myFinder);
                    myFinder.rulesContainer = createRulesContainer(myFinder);
					myFinder = evaluateCodeFIS(myFinder);
                    myFinder = validationFuzzy(myFinder);
				% Both fuzzies exclude not prominent peaks, can exclude
				% close peaks and rest necessary number of them;  
				% give labels to all peaks according their validity.
                
                %Create peaks table; normalization; creation rules container;
                %evaluation FIS, getting validity, set thresholds from config.xml file;
                %validationFuzzy - assign validity labels;
                %throw out "waste" peaks, write valid to result; draw graphics.
                case 'Coarse'
                % Coarse peak validation (without fuzzy logic)
				% Use normalization to scalogram maximum
				% Validation - leave amount of max prominent peaks
					myFinder = NormaliseToMAX(myFinder);
                    myFinder = coarsePeaksFind(myFinder);

                case 'CoarseEnergy'
                % Coarse peak validation (without fuzzy logic)
                % Energy estimation with threshold may be used for validation
					myFinder = NormaliseToMAX(myFinder);
                    if (myFinder.config.energyEstimation.Attributes.scalogramEnergyEstimation == '1')
                        myFinder = coarseEnergyPeaksFind(myFinder);
                    else
                        myFinder = coarsePeaksFind(myFinder);
                    end    
                    %Normalize peaks and process them without assign validity.
                otherwise
					error('Unknown peak validation method');
            end
            
            % -= Result plotting =-
%             if (peakFindConfig.plotEnable == '1') || (peakFindConfig.printPlotsEnable == '1')
            if (myFinder.plotEnable == 1) || (myFinder.printPlotsEnable == 1)

                 myFinder = myFinder.plotPeaksFound(myFinder);
            end
            
        end % function findPeaks (general)
        
    end % end public methods
    
    methods (Access = private)
        
        %INTERPOLATE function inplements spline interpolation of the all
        %scalogram properties (@coefficients, @frequencies, @scales) by
        %cpecificated in @config interpolation factor
        function [myScalogram] = interpolate(myScalogram)
            
            interpolationFactor = str2double(myScalogram.config.Attributes.interpolationFactor);
            
            % Gets orignal scalogram properties and form original and
            % interpolated arrays for further interpolation
            coefficientsOrigin = myScalogram.signal.coefficients;
            frequenciesOrigin = myScalogram.signal.frequencies;
            scalesOrigin = myScalogram.signal.scales;

            scalogramLength = length(coefficientsOrigin);
            arrayOrigin = 1:scalogramLength;
            arrayInterp = 1:1/interpolationFactor:scalogramLength;
            
            % Main properties spline interpolation
            myScalogram.signal.coefficients = ...
                interp1( arrayOrigin, coefficientsOrigin, arrayInterp, 'spline')';
            myScalogram.signal.frequencies = ...
                interp1( arrayOrigin, frequenciesOrigin, arrayInterp, 'spline')';
            myScalogram.signal.scales = ...
                interp1( arrayOrigin, scalesOrigin, arrayInterp, 'spline')';
        end
        
        % CREATEPEAKSTABLE function ....
        function [myFinder] = createPeaksTable(myFinder)
            
            % Interpolate main scalogram properties
            % for the best analisys accuracy
            interpolationEnable = str2double(myFinder.config.Attributes.interpolationEnable);
            
            if interpolationEnable == 1
                myFinder = interpolate(myFinder);
            end
            
            coefficients = myFinder.signal.coefficients;
            frequencies = myFinder.signal.frequencies;
            scales = myFinder.signal.scales;
            freqencyStep = str2num(myFinder.signal.scalogramConfig.linear.Attributes.frequencyStep);
            
            if interpolationEnable == 1
                interpolationFactor = str2double(myFinder.config.Attributes.interpolationFactor);
            else
                interpolationFactor = 1;
            end
            
            % Find all peaks in the signal
            [heights,peakLocations,widths,prominences] = findpeaks(coefficients);
            
            if ~isempty(peakLocations)
                
                frequency = frequencies(peakLocations);
                scale = scales(peakLocations);
                coefficient = coefficients(peakLocations);
                % normalise width from points to Hz
                widths = widths/interpolationFactor*freqencyStep;
                
                for i =1:1:length(peakLocations)
                    myPeaksTable(i).frequencies = frequency(i);
                    myPeaksTable(i).scales = scale(i);
                    myPeaksTable(i).coefficients = coefficient(i);
                    myPeaksTable(i).height = heights(i);
                    myPeaksTable(i).width = widths(i);
                    myPeaksTable(i).prominence = prominences(i);
                end
                
                % energy estimation for all peaks
                myFinderCopy = myFinder;
                myFinderCopy.allPeaks = myPeaksTable;
                myFinderCopy = NormaliseToMAX(myFinderCopy);
                FullScalogramData = getFullScalogramData(myFinderCopy);
                myEnergyEstimator = energyEstimator( FullScalogramData, myFinderCopy.allPeaks );
                myPeaksTable = getScalogramPointsEnergy(myEnergyEstimator);

                
                % return unnormalized base parameters for peak validation extra methods
                for i =1:1:length(peakLocations)
                    myPeaksTable(i).height = heights(i);
                    myPeaksTable(i).prominence = prominences(i);
                end
                
            else
                printWarning(myFinder.iLoger, 'There no found peaks in the signal!');
                myPeaksTable = [];
            end
            
            myFinder.allPeaks = myPeaksTable;
            
        end % function createPeaksTable
		
		% FileFISsetParameters use FIS file to get rules container,
        % thresholds, labels, and normalise peaks to RMS
		function myFinder = FileFISsetParameters(myFinder)
            
			% Normolized all gotten peaks parameters
            rmsLevel = rms(myFinder.signal.coefficients);
            myFinder.allPeaks = arrayfun(@(x)(setfield(x,'height',x.height/rmsLevel)),myFinder.allPeaks);
            myFinder.allPeaks = arrayfun(@(x)(setfield(x,'prominence',x.prominence/rmsLevel)),myFinder.allPeaks);
			
            %Set validity thresholds.
            %Loading FIS parameters (file name and validity thresholds) to param struct.
			load('FISfiles.dat', '-mat');
			IdFIS = strcmp({FIScontainerFile.name},CurrFISfile);
			myFISfile = FIScontainerFile(IdFIS);
			myFinder.config.Attributes.validityThresholds = myFISfile.thresholds;
			myFinder.config.Attributes.FISfileName = myFISfile.name;
			myFinder.config.Attributes.CurrFISfile = CurrFISfile;
		end
		
		% NormaliseToMAX normalise peaks to scalogram and peaks maximums
		function myFinder = NormaliseToMAX(myFinder)
            
			coefficients = myFinder.signal.coefficients;
            maxCoeff = max(coefficients);
            maxPeaks = max([myFinder.allPeaks.height])/maxCoeff;

            % Normolized all gotten peaks parameters
            myFinder.allPeaks = arrayfun(@(x)( setfield(x,'height',x.height/maxCoeff) ),myFinder.allPeaks);
            myFinder.allPeaks = arrayfun(@(x)( setfield(x,'prominence',x.prominence/maxCoeff) ),myFinder.allPeaks);
			myFinder.allPeaks = arrayfun(@(x)( setfield(x,'globality',x.height/maxPeaks) ),myFinder.allPeaks);
			
            % Set validity thresholds.
			% myFinder.config.Attributes.validityThresholds = str2num(myFinder.config.Attributes.validityThresholds);
		end
		
        % CREATERULESCONTAINER function creates container with set of rules
        % to validate found peaks. Function use peaks @height, @width,
        % @prominence and their @global/@local state in the arrays
        function [container] = createRulesContainer(myFinder)
            
            % Main parameters 
            parameters = myFinder.config.Attributes;

            coefficients = myFinder.signal.coefficients;
            rmsCoeff = rms(coefficients)/max(coefficients);
            peakHeight = [myFinder.allPeaks.height];
            rmsPeaks = rms(peakHeight);
            prominence = [myFinder.allPeaks.prominence];
            rmsPromin = rms(prominence);
            
            heightThresholds = str2num(parameters.heightThresholds);
            heightMax = heightThresholds(3,1)+0.5;
            heightAverage = rmsPeaks; %heightThresholds(2,1)*rmsPeaks;
            heightMin = rmsCoeff; %heightThresholds(1,1)*rmsCoeff;
            heightZero = -0.5;
            heightAscent = 100;
            
            prominenceThresholds = str2num(parameters.prominenceThresholds);
            prominenceMax = prominenceThresholds(3,1)+0.5;
            prominenceAverage = prominenceThresholds(2,1)*rmsPromin;
            prominenceMin = prominenceThresholds(1,1)*rmsPromin;
            prominenceZero = -0.5;
            prominenceAscent = 100;
            
            container = newfis('optipaper'); 
            
            % INPUT:

            % Init 3-state @prominence variable
            container = addvar(container,'input','height',           [heightZero heightMax]);
            container = addmf(container,'input',1,'low','dsigmf',    [heightAscent heightZero heightAscent heightMin]);
            container = addmf(container,'input',1,'average','dsigmf',[heightAscent heightMin heightAscent heightAverage]);
            container = addmf(container,'input',1,'high','dsigmf',   [heightAscent heightAverage heightAscent heightMax]);
            
            % Init 3-state @height variable
            container = addvar(container,'input','prominence',       [prominenceZero prominenceMax]);
            container = addmf(container,'input',2,'low','dsigmf',    [prominenceAscent prominenceZero prominenceAscent prominenceMin]);
            container = addmf(container,'input',2,'average','dsigmf',[prominenceAscent prominenceMin prominenceAscent prominenceAverage]);
            container = addmf(container,'input',2,'high','dsigmf',   [prominenceAscent prominenceAverage prominenceAscent prominenceMax]);

            % Init 3-state @energy variable
            container = addvar(container,'input','energy',           [energyZero energyMax]);
            container = addmf(container,'input',3,'low','dsigmf',    [energyAscent energyZero energyAscent energyMin]);
            container = addmf(container,'input',3,'average','dsigmf',[energyAscent energyMin energyAscent energyAverage]);
            container = addmf(container,'input',3,'high','dsigmf',   [energyAscent energyAverage energyAscent energyMax]);
            
            % OUTPUT:
            % Init 3-state @result variablemodulationTagsNumber3
            container = addvar(container,'output','validity',[-0.375 1.375]);  %[-1.5 1.5]
            container = addmf(container,'output',1,'none','gaussmf', [0.125 0]);  %[-1 -0.7]
            container = addmf(container,'output',1,'mbValid','gaussmf', [0.125 0.5]);  %[-0.3 0.5]
            container = addmf(container,'output',1,'valid','gaussmf', [0.125 1]);  %[0.7 1.4]

            %RULEs:
            % e - in, energy (peakHeight/maxScalogram)
            % h - in, (peakHeight/maxPeakHeight)
            % p - in, (peakProminence/maxPeakProminence)
            % v = out, validity
            % W - rule weight
            % a/o - and/or, e & h & p  or  e | h | p]
        

                    ruleList = [% h  p e    v    w a/o
                                  1  1 1    1    1  1;
                                  2  1 2    1    1  1;
                                  3  1 3    2    1  1;
                                  1  2 1    2    1  1;
                                  2  2 2    2    1  1;
                                  3  2 3    3    1  1;
                                  1  3 1    2    1  1;
                                  2  3 2    3    1  1;
                                  3  3 3    3    1  1;
                                                         ];             
             
            container = addrule(container,ruleList);
        end
		
        % Calculate validity & set labels by direct thresholds
        function [myFinder] = evaluateFileFIS(myFinder)
            
            
            myFinderCopy = FileFISsetParameters(myFinder);
            myFinder.config.Attributes.validityThresholds = myFinderCopy.config.Attributes.validityThresholds;
            myFinderCopy.rulesContainer = readfis(myFinderCopy.config.Attributes.FISfileName);

            myPeaksTable = myFinderCopy.allPeaks;
            myRulesContainer = myFinderCopy.rulesContainer;
            
            for i = 1:1:numel(myPeaksTable)
                
                % Set input arguments for fuzzy calculations
                inputArgs = [
                    myPeaksTable(i).height, ...
                    myPeaksTable(i).prominence];
                
                % Implement fuzzy culculations and fill ruselt property
                % with (valid) or (valid + mbValid) peaks data
                myFinder.allPeaks(i).validity = evalfis(inputArgs,myRulesContainer);
 
            end
        end
		
		% Calculate validity & set labels by RMS & STD relative thresholds
		function [myFinder] = evaluateCodeFIS(myFinder)
            
			peakFinderConfig = myFinder.config.Attributes;
			myPeaksTable = myFinder.allPeaks;
            peaksNumber = length(myPeaksTable);

            % validityThresholds should be used as coefficients for RMS & STD 
            validityThresholds = peakFinderConfig.validityThresholds;
            validityThreshold = validityThresholds(mbValidPeaksEnable + 1);

            coefficients = myFinder.signal.coefficients;
            rmsCoeff = rms(coefficients)/max(coefficients);
            peakHeight = [myFinder.allPeaks.height];
            rmsPeaks = rms(peakHeight);
            prominence = [myFinder.allPeaks.prominence];
            rmsPromin = rms(prominence);
            
            for i = 1:1:peaksNumber
                
                % Set input arguments for fuzzy calculations
                inputArgs = [
                             myPeaksTable(i).height, ...
                             %myPeaksTable(i).globality,...
							 %myPeaksTable(i).width,...
                             myPeaksTable(i).prominence];                

                % Implement fuzzy calculation of peaks validity
                myPeaksTable(i).validity = evalfis(inputArgs,myRulesContainer);
                
               % if myPeaksTable(i).validity > pi*rms(diff([myPeaksTable.validity]))+rms([myPeaksTable.validity])
                if myPeaksTable(i).validity > std([myPeaksTable.validity])*2+rms([myPeaksTable.validity])
                    myPeaksTable(i).label = 'valid';
                elseif myPeaksTable(i).validity > std([myPeaksTable.validity])*1+rms([myPeaksTable.validity])
                    myPeaksTable(i).label = 'mbVal';
                elseif myPeaksTable(i).validity > std([myPeaksTable.validity])*0+rms([myPeaksTable.validity]) 
                    myPeaksTable(i).label = 'mbInt';
                else
                    myPeaksTable(i).label = 'noInt';
                end
            end
            
			myFinder.allPeaks=myPeaksTable;
		end
		
        % validationFuzzy function implements fuzzy rules of @rulesContainer
        % to validate peaks in the @myPeaksTable and forms result struct of
        % true valid peaks
        function [myFinder] = validationFuzzy(myFinder)
            
            %Set thresholds and norm for the current fuzzy container and
            %compute it's output and give labels by according validity threshold,
            %next for both of them fill in result field with valid peaks,
            %exclude close peaks if it's need and peaks with lower validity
            %to rest only number of them if it's specified.

            if ischar (myFinder.config.Attributes.validityThresholds)
                myFinder.config.Attributes.validityThresholds = str2num(myFinder.config.Attributes.validityThresholds);
            end
            peakFinderConfig = myFinder.config.Attributes;
            validityThresholds = peakFinderConfig.validityThresholds;
            mbValidPeaksEnable = str2double(peakFinderConfig.mbValidPeaksEnable);
            minValidPeaksDistance = str2double(peakFinderConfig.minValidPeaksDistance);
            
            peaksNumber = length([myFinder.allPeaks]);
            for i = 1:peaksNumber
                if myFinder.allPeaks(i).validity > validityThresholds(3)
                    myFinder.allPeaks(i).label = 'valid';
                elseif myFinder.allPeaks(i).validity > validityThresholds(2)
                    myFinder.allPeaks(i).label = 'mbVal';
                elseif myFinder.allPeaks(i).validity > validityThresholds(1)
                    myFinder.allPeaks(i).label = 'mbInt';
                else
                    myFinder.allPeaks(i).label = 'noInt';
                end
            end
            
            

            myRulesContainer = myFinder.rulesContainer;
            myPeaksTable = myFinder.allPeaks;
            peaksNumber = length(myPeaksTable);
			
            if str2double(peakFinderConfig.mbValidPeaksEnable)
                validityThreshold = validityThresholds(2);  
            else
                validityThreshold = validityThresholds(1); 
            end
            
            %normalize prom for fileFIS
            coefficients = myFinder.signal.coefficients;
            rmsLevel = rms(coefficients);
            maxCoeff = max(coefficients);
            myPeaksTable = arrayfun(@(x)(setfield(x,'prominence',x.prominence/rmsLevel)),myPeaksTable);
            maxPeaks = max([myPeaksTable.height])/maxCoeff;
            myPeaksTable = arrayfun(@(x)( setfield(x,'height',x.height/maxCoeff) ),myPeaksTable);
            myPeaksTable = arrayfun(@(x)( setfield(x,'prominence',x.prominence/maxCoeff) ),myPeaksTable);
			myPeaksTable = arrayfun(@(x)( setfield(x,'globality',x.height/maxPeaks) ),myPeaksTable);

        	prominenceThresholds = str2num(peakFinderConfig.prominenceThresholds);
            for i = 1:1:peaksNumber %Fill in result field of valid peaks and marking by label.
                %myFinder.allPeaks(i).validity = myPeaksTable(i).validity;
				if myPeaksTable(i).prominence < prominenceThresholds(1)
					myFinder.allPeaks(i).label='noInt'; %Sign not prominent like not interest.
				end
            end

            %Throw out not valid and not prominent.
            resultValidityIndex = find([myPeaksTable.validity] > validityThreshold);
            resultProminenceIndex = find([myPeaksTable.prominence] > prominenceThresholds(1));
            % back to unnormalized prominence
            myPeaksTable = arrayfun(@(x)(setfield(x,'prominence',x.prominence*rmsLevel)),myPeaksTable);
            myResult = myPeaksTable(intersect(resultValidityIndex, resultProminenceIndex));
            
            k = length(myResult);
            if k == 0
                %If there are no valid peaks - put out an empty array. In other case it's cause an error.           
                myFinder.result = [];
                return
            elseif k == 1
                myFinder.result = myResult;
                return
            else
                
                % Exclude valid peaks closer than min distance (in Hz)
                excludeClosePeaksEnable = str2double(myFinder.config.Attributes.excludeClosePeaksEnable);
                if excludeClosePeaksEnable
                    resultIncludeMask = 1:k;
                    for i = 1:(k-1)
                        for j = (i+1):k
                            mw=max([myResult(i).width myResult(j).width]); %Find peak with max width.
                            if excludeClosePeaksEnable == 2 minValidPeaksDistance = mw; end
                            if (resultIncludeMask(i) > 0) && (resultIncludeMask(j) > 0) ...
                                    && (myResult(j).frequencies - myResult(i).frequencies) < minValidPeaksDistance
                                if (myResult(i).validity < myResult(j).validity)
                                    resultIncludeMask(i) = 0;
                                else
                                    resultIncludeMask(j) = 0;
                                end
                            end
                        end
                    end
                    myResult = myResult(find(resultIncludeMask));
                end %ExcludeClose.
                
                % Leave not more than max valid peaks number & sort by validity 
                maxValidPeaksNumber = peakFinderConfig.maxValidPeaksNumber;
                
                if k > maxValidPeaksNumber %Inf if we wanna rest all valid in result.
                    % WARNING: Too much valid peaks found
                    printWarning(myFinder.iLoger, 'Too much valid peaks found')
                    k = maxValidPeaksNumber;
                end
                
                % Leave amount of the most valid peaks.
                [~, validInd] = sort([myResult.validity], 'descend');
                myResult = myResult(validInd(1:k));
                
            end
            
            % Sort by frequency for the next processing.
            [~, freqInd] = sort([myResult.frequencies], 'ascend');
            myResult = myResult( freqInd(1:numel(myResult)) );
                
            myFinder.result = myResult;

        end % validationFuzzy function
        
        % COARSEPEAKFIND function implements simple width peaks exclusion 
        % and height/prominence threshold validation
        function [myFinder] = coarsePeaksFind(myFinder)
            
            %Sign all peaks as not valid and not interest - it's deafult value.
            myFinder.allPeaks=arrayfun(@(x)(setfield(x,'label','noInt')),myFinder.allPeaks);
            myFinder.allPeaks=arrayfun(@(x)(setfield(x,'validity',0)),myFinder.allPeaks);
            
            currentResult = [myFinder.allPeaks];
            peakNumber = length(currentResult);
            myResultSorted = [];
            
            if peakNumber == 0
                % WARNING No peaks at the scalogram
                printWarning(myFinder.iLoger, 'No peaks at the scalogram')
                % If there are no valid peaks - put out an empty array.
                % In other case it's cause an error.
                                
            elseif peakNumber == 1
                % WARNING Only one peak on the scalogram
                printWarning(myFinder.iLoger, 'Only one peak on the scalogram')

                currentResult.label='mbVal';
                myFinder.allPeaks.label='mbVal';
                myFinder.allPeaks.validity=0.5;
            else
                
                peakFinderConfig = myFinder.config.Attributes;
                maxValidPeaksNumber = str2double(peakFinderConfig.maxValidPeaksNumber);
                
                % [1 of 5] Minimal peak energy check
                % Exclude peaks by  height lower than threshold
                                
                peakNumVector = (1:peakNumber);
                resultIncludeMask(peakNumVector) = false;
                
                scalogram = myFinder.signal.coefficients;
                rmsScalogram = rms(scalogram)/max(scalogram);
                
                peakHeight = [currentResult.height]; % is /max(scalogramCoeff) yet
                rmsPeaks = rms(peakHeight);
                stdPeaks = std(peakHeight);
                
                peakPromin = [currentResult.prominence]; % is /max(scalogramCoeff) yet
                rmsPromin = rms(peakPromin);
                
                energyThresholdMethod = str2double(peakFinderConfig.energyThresholdMethod);
                energyThresholds = str2num(peakFinderConfig.energyThresholds);
                energyHeightThreshold = 0;
                energyProminThreshold = 0;

                % upper than: 
                % 1 = both, High AND Prominent
                % 0 = any, High OR Prominent
                energyThresholdsAND = true;

                switch energyThresholdMethod
                    
                    case 1 % Upper than any of Direct numeric thresholds
                        energyHeightThreshold = energyThresholds(1,1);
                        energyProminThreshold = energyThresholds(2,1);
                        energyThresholdsAND = false;

                    case 2 % Upper than both Direct numeric thresholds
                        energyHeightThreshold = energyThresholds(1,1);
                        energyProminThreshold = energyThresholds(2,1);

                    case 3 % Upper than Scalogram RMS threshold only
                        energyHeightThreshold = rmsScalogram * energyThresholds(3,1);

                    case 4 % Upper than Prominence RMS threshold only 
                        energyProminThreshold = rmsPromin * energyThresholds(4,1);

                    case 5 % Upper than Peaks RMS threshold only
                        energyHeightThreshold = rmsPeaks * energyThresholds(5,1);
                        
                    case 6 % Upper than Peaks RMS+STD threshold only
                        energyHeightThreshold = ...
                            rmsPeaks * energyThresholds(5,1) + ...
                            stdPeaks * energyThresholds(6,1);

                    case 7 % Upper than any of scalogram OR prominence RMS thresholds
                        energyHeightThreshold = rmsScalogram * energyThresholds(3,1);
                        energyProminThreshold = rmsPromin * energyThresholds(4,1);
                        energyThresholdsAND = false;

                    case 8 % Upper than any of peaks OR prominence RMS thresholds
                        energyHeightThreshold = rmsPeaks * energyThresholds(5,1);
                        energyProminThreshold = rmsPromin * energyThresholds(4,1);
                        energyThresholdsAND = false;

                    case 9 % Upper than any of peaks RMS+STD OR prominence RMS thresholds
                        energyHeightThreshold = ...
                            rmsPeaks * energyThresholds(5,1) + ...
                            stdPeaks * energyThresholds(6,1);
                        energyProminThreshold = rmsPromin * energyThresholds(4,1);
                        energyThresholdsAND = false;

                    case 10 % Upper than both scalogram AND prominence RMS thresholds
                        energyHeightThreshold = rmsScalogram * energyThresholds(3,1);
                        energyProminThreshold = rmsPromin * energyThresholds(4,1);

                    case 11 % Upper than both peaks AND prominence RMS thresholds
                        energyHeightThreshold = rmsPeaks * energyThresholds(5,1);
                        energyProminThreshold = rmsPromin * energyThresholds(4,1);

                    case 12 % Upper than both peaks RMS+STD AND prominence RMS thresholds
                        energyHeightThreshold = ...
                            rmsPeaks * energyThresholds(5,1) + ...
                            stdPeaks * energyThresholds(6,1);
                        energyProminThreshold = rmsPromin * energyThresholds(4,1);
                end
                
                for i = peakNumVector
                    if (energyThresholdsAND && ... simultaneously upper than both thresholds
                            (currentResult(i).height >= energyHeightThreshold ...
                            && currentResult(i).prominence >= energyProminThreshold)) ...
                    || ... 
                        (~energyThresholdsAND && ... upper than any of thresholds
                            (currentResult(i).height >= energyHeightThreshold ...
                            || currentResult(i).prominence >= energyProminThreshold))
                    % then
                        resultIncludeMask(i) = true;
                    end
                end
                
                currentResult = currentResult(logical(resultIncludeMask));
                peakNumber = length(currentResult);
                
                if peakNumber == 0
                    % WARNING No peaks over energy threshold
                    printWarning(myFinder.iLoger, 'No peaks over energy threshold')
                end
                %                 end
                
                % [2 of 5] Minimal peak distance check
                % Exclude peaks clother than min distance (in Hz) by min height
                if peakNumber > 1
                    
                    peakNumVector = (1:peakNumber);
                    resultIncludeMask = [];
                    resultIncludeMask(peakNumVector) = true;
                    minValidPeaksDistance = str2double(peakFinderConfig.minValidPeaksDistance);
                    
                    %Choose the most higth from neighbour peaks.
                    for i = 1:(peakNumber-1)
                        for j = (i+1):peakNumber
                            if (resultIncludeMask(i)) && (resultIncludeMask(j)) ... both are true
                                    && (currentResult(j).frequencies - currentResult(i).frequencies) < minValidPeaksDistance
                                if (currentResult(i).height < currentResult(j).height)
                                    resultIncludeMask(i) = false;
                                else
                                    resultIncludeMask(j) = false;
                                end
                            end
                        end
                    end
                    
                    currentResult = currentResult(logical(resultIncludeMask));
                end
                                
                % [3 of 5] Local maximums validation
                % Exclude peaks under the width (in Hz) of more prominent
                peakNumber = length(currentResult);
                
                if peakNumber > 1
                    
                    peakNumVector = 1:peakNumber;
                    resultIncludeMask = [];
                    resultIncludeMask(peakNumVector) = true;
                    
                    for i = peakNumVector
                        for j = peakNumVector
                            if (i ~= j) && resultIncludeMask(i) && resultIncludeMask(j)
                                % p(i) < ? <= p(j) - the case of equal p. is rare
                                if currentResult(i).prominence < currentResult(j).prominence ... %The current peak is less prominent.
                                        && currentResult(i).frequencies >= ... Left peak closer (difference of positions lower) then width
                                        (currentResult(j).frequencies - currentResult(j).width) ...
                                        && currentResult(i).frequencies <= ... Right peak
                                        (currentResult(j).frequencies + currentResult(j).width)
                                % then
                                    resultIncludeMask(i) = false;
                                end
                            end
                        end
                    end
                    
                    currentResult = currentResult(logical(resultIncludeMask));
                end
                
                % [4 of 5] Complex validation (fuzzy logic may be here...)
                % Exclude peaks by duplication (max h/w/p/g)
                
                peakNumber = length(currentResult);
                
                if peakNumber > maxValidPeaksNumber
                    
                    peakNumVector = 1:peakNumber;
                    peakPromin = [currentResult.prominence];
                    peaksGlobal = [currentResult.globality];
                    peaksWidth = [currentResult.width];
                    
                    [~, prominInd] = sort(peakPromin, 'descend');
                    [~, globalInd] = sort(peaksGlobal, 'descend');
                    [~, widthInd] = sort(peaksWidth, 'descend');
                    
                    if peakNumber > maxValidPeaksNumber + 1
                        maxPeaksNumber = maxValidPeaksNumber + 2;
                    else
                        maxPeaksNumber = peakNumber;
                    end
                    
                    prominInd = prominInd(1:maxPeaksNumber);
                    globalInd = globalInd(1:maxPeaksNumber);
                    widthInd = widthInd(1:maxPeaksNumber);
                    
                    resultIncludeMask = [];
                    
                    % Include best peaks (Max & Promin & Width, together)
                    resultIncludeMask = (...
                        ismember(peakNumVector, prominInd) & ...
                        ismember(peakNumVector, globalInd) & ...
                        ismember(peakNumVector, widthInd)  );
                    
                    % If there isn't enough, include more good peaks
                    if nnz(resultIncludeMask) < maxValidPeaksNumber + 1
                        resultIncludeMask = resultIncludeMask  | (...
                            ismember(peakNumVector, prominInd) & ...
                            ismember(peakNumVector, globalInd) );
                    end
                    
                    % If there isn't enough, include the most prominent
                    if nnz(resultIncludeMask) < maxValidPeaksNumber
                        resultIncludeMask = resultIncludeMask  | ...
                            ismember(peakNumVector, prominInd) ;
                    end
                    
                    currentResult = currentResult(resultIncludeMask);
                    
                end
                
                % [5 of 5] Sort by validity
                % Leave <= max valid peaks number & sort by prominence
                
                peakNumber = length(currentResult);
                
                if peakNumber > maxValidPeaksNumber
                    % WARNING: Too many valid peaks found
                    printWarning(myFinder.iLoger, 'Too many valid peaks found (coarse)')
                    peakNumber = maxValidPeaksNumber;
                end
                
                % sort output by validity or energy or prominence or frequency
                [~, validInd] = sort([currentResult.frequencies], 'ascend');
                myResultSorted = currentResult(validInd(1:peakNumber));
                
                %Sign valid peaks as 'valid'.
                myResultSorted=arrayfun(@(x)(setfield(x,'label','valid')),myResultSorted);
                myResultSorted=arrayfun(@(x)(setfield(x,'validity',1)),myResultSorted);
                
                %Getting peaks table with 'valid' label.
                allPeaksValidLabel=arrayfun(@(x)(setfield(x,'label','valid')),myFinder.allPeaks); %myResultSorted
                allPeaksValidLabel=arrayfun(@(x)(setfield(x,'validity',1)),allPeaksValidLabel); %myResultSorted
                
                %Find valid elements in the common table and getting them by matching frequency.
                IdVal = arrayfun(@(x)(find([allPeaksValidLabel.frequencies]==x)),[currentResult.frequencies]);
                %IdVal=find([allPeaksValidLabel.frequencies]==[currentResult.frequencies]);
                %Change elements in myFinder peak table to the same with 'valid' label.
                myFinder.allPeaks(IdVal) = allPeaksValidLabel(IdVal);
            end
            
            myFinder.result = myResultSorted;
            
        end % end of coarsePeaksFind function
  
        
        % COARSEENERGYPEAKFIND function
        % energy estimation is used to validate peaks
        function [myFinder] = coarseEnergyPeaksFind(myFinder)
            
            peakFinderConfig = myFinder.config.Attributes;
            maxValidPeaksNumber = str2double(peakFinderConfig.maxValidPeaksNumber);
            energyThreshold = str2num(peakFinderConfig.coarseEnergyValodationThreshold);
                
            currentResult = [myFinder.allPeaks];
            peakNumber = length(currentResult);
            
            % -= No peaks processing =-
            if peakNumber == 0
                % WARNING No peaks at the scalogram
                printWarning(myFinder.iLoger, 'No peaks at the scalogram')
                
                % Put out an empty array, in other case it cause an error
                myFinder.result = [];
                return
            end
                
            % Assign validity values & labels
            maxPeakEnergy = max([currentResult.energy]);
            for i = 1 : peakNumber
                myFinder.allPeaks(i).validity = currentResult(i).energy/maxPeakEnergy;
                switch (currentResult(i).energyLabel)
                    case 'High'
                        myFinder.allPeaks(i).label = 'valid';
                    case 'Medium'
                        myFinder.allPeaks(i).label = 'mbVal';
                    case 'Low'
                        myFinder.allPeaks(i).label = 'mbInt';
                    case 'Insign'
                        myFinder.allPeaks(i).label = 'noInt';
                    otherwise
                        error('Unknown peak energy label');
                end
            end
            currentResult = [myFinder.allPeaks];

            % -= One peak processing =-
            if peakNumber == 1
                % WARNING Only one peak on the scalogram
                printWarning(myFinder.iLoger, 'Only one peak on the scalogram')
                
                if (currentResult(1).energy < energyThreshold)
                    % WARNING No peaks over energy threshold
                    printWarning(myFinder.iLoger, 'No peaks over energy threshold')
                    
                    currentResult = [];
                end
                
                myFinder.result = currentResult;
                return
            end
            
            % -= Multiple peaks processing (till the function end) =-
            % [1 of 4] Minimal peak distance check
            % Leave the most hight peak of closer than min distance (in Hz)
            
            peakNumVector = (1:peakNumber);
            resultIncludeMask = [];
            resultIncludeMask(peakNumVector) = true;
            minValidPeaksDistance = str2double(peakFinderConfig.minValidPeaksDistance);
            
            for i = 1:(peakNumber-1)
                for j = (i+1):peakNumber
                    if (resultIncludeMask(i)) && (resultIncludeMask(j)) ... both are true
                            && (currentResult(j).frequencies - currentResult(i).frequencies) < minValidPeaksDistance
                        if (currentResult(i).height < currentResult(j).height)
                            resultIncludeMask(i) = false;
                        else
                            resultIncludeMask(j) = false;
                        end
                    end
                end
            end
            
            currentResult = currentResult(logical(resultIncludeMask));
            
            % [2 of 4] Local maximums validation
            % Exclude peaks under the width (in Hz) of more prominent
            
            peakNumber = length(currentResult);
            peakNumVector = 1:peakNumber;
            resultIncludeMask = [];
            resultIncludeMask(peakNumVector) = true;
            
            for i = peakNumVector
                for j = peakNumVector
                    if (i ~= j) && resultIncludeMask(i) && resultIncludeMask(j)
                        % p(i) < ? <= p(j) - the case of equal p. is rare
                        if currentResult(i).prominence < currentResult(j).prominence ... %The current peak is less prominent.
                                && currentResult(i).frequencies >= ... Left peak closer (difference of positions lower) then width
                                (currentResult(j).frequencies - currentResult(j).width) ...
                                && currentResult(i).frequencies <= ... Right peak
                                (currentResult(j).frequencies + currentResult(j).width)
                            % then
                            resultIncludeMask(i) = false;
                        end
                    end
                end
            end
            
            currentResult = currentResult(logical(resultIncludeMask));
            
            % [3 of 4] Coarse energy validation (fuzzy logic may be here...)
            % Exclude peaks lower than threshold (validity = energy here)
            
            peakNumber = length(currentResult);
            peakNumVector = (1:peakNumber);
            resultIncludeMask = [];
            resultIncludeMask(peakNumVector) = true;
            resultIncludeMask(find([currentResult.energy] < energyThreshold)) = false;
            
            currentResult = currentResult(logical(resultIncludeMask));
            
            % [4 of 4] Sort by validity
            % And leave not more than max valid peaks number
            
            peakNumber = length(currentResult);
            
            if peakNumber == 0
                % WARNING No peaks over energy threshold
                printWarning(myFinder.iLoger, 'No peaks over energy threshold')
                
            elseif peakNumber > maxValidPeaksNumber
                % WARNING: Too many valid peaks found
                printWarning(myFinder.iLoger, 'Too many valid peaks found (coarse)')
                peakNumber = maxValidPeaksNumber;
            end
            
            % sort output by validity or energy or prominence or frequency
            [~, validInd] = sort([currentResult.frequencies], 'ascend');
            currentResult = currentResult(validInd(1:peakNumber));
            
            myFinder.result = currentResult;
            
        end % end of coarseEnergyPeaksFind function
        
        %%
        % -= DRAWING FUNCTIONS =-
        

        % Draw Graphics for coarse peakFinder
        function [myFinder] = plotCoarsePeaksFound(myFinder)
            
            % If plot diable, we can print, but not show.
            plotConfig = myFinder.config.Attributes;
            
            freqPlot = myFinder.signal.frequencies;
            xLength = numel(freqPlot);
            
            peaksFreq = [myFinder.allPeaks.frequencies];
            peaksHeight = [myFinder.allPeaks.height];
            maxPeak = max(peaksHeight);
            rmsPeaks = rms(peaksHeight);
            rmsPeaksZoom = rmsPeaks/maxPeak;
            stdPeaks = rmsPeaks + std(peaksHeight);
            stdPeaksZoom = stdPeaks/maxPeak;
            
            peasksPromin = [myFinder.allPeaks.prominence];
            rmsProminence = rms(peasksPromin);
            peasksProminNormal = peasksPromin/max(peasksPromin);
            
            coefPlot = myFinder.signal.coefficients;
            coefPlot = coefPlot/max(coefPlot);
            rmsCoeff = rms(coefPlot);
            rmsCoeffZoom = rmsCoeff/maxPeak;
            
            coefZoom = coefPlot;
            coefZoom(coefPlot > maxPeak) = rmsCoeff;
            coefZoom = coefZoom/maxPeak;
            
%             figure('Color', 'w', 'Visible', Visible);
            figure('Color', 'w', 'Visible', myFinder.plotVisible);
            hold on;
            
            plot(freqPlot, coefZoom, 'c');
            plot([freqPlot(1) freqPlot(xLength)], [rmsCoeffZoom rmsCoeffZoom], '*:c');
            plot([freqPlot(1) freqPlot(xLength)], [rmsPeaksZoom rmsPeaksZoom], '*--c');
            plot([freqPlot(1) freqPlot(xLength)], [stdPeaksZoom stdPeaksZoom], '--c');
            
            plot(freqPlot, coefPlot, 'b');
            plot([freqPlot(1) freqPlot(xLength)], [rmsCoeff rmsCoeff], '*:b');
            
            stem(peaksFreq, peasksPromin, '.', 'Color', [0.85 0.15 0.0]);
            plot([freqPlot(1) freqPlot(xLength)], [rmsProminence rmsProminence]*1.00, '*:', 'Color', [0.85 0.15 0.0]);
            
            if ~isempty(myFinder.result)
                plot([myFinder.result.frequencies], [myFinder.result.height]/maxPeak, 'ro');
            end
            title('Scalogram');
            xlabel('Frequency, Hz');
            legend('sclZoom','rmsScZoom','rmsPkZoom','stdPkZoom','sclogram','rmsScl','promin','rmsPromin','validPk');
            hold off;
            
            % Close figure with visibility off
            if strcmpi(myFinder.plotVisible, 'off')
                close
            end
            
        end % end plotCoarsePeaksFound function

        % Draw Graphics for FileFIS peakFinder
        function [myFinder] = plotFileFisPeaksFound(myFinder)
            %It gets scalogram coefficients and not normalized heights and prominences.
            %It draw scalogram, normalized to it's maximum, truncated
            %scalodram, normalized to it's maximum (max peak), signed peaks,
            %norm. to max peak, prominences, valdities and their threshplds;
            %height thresh. are RMS and levels of RMS*(thresholds form config).
            plotConfig = myFinder.config.Attributes;
            
%             % If plot diable, we can print, but not show.
%             if plotConfig.plotEnable
%                 Visible = 'on';
%             else 
%                 Visible = 'off';
%             end
            
            % X-scale            
            myPeaksTable = myFinder.allPeaks;
            peaksFreq = [myPeaksTable.frequencies];
            freqPlot = myFinder.signal.frequencies;
            xLength = numel(freqPlot);            
            
            % Scalogram
            coefPlot = myFinder.signal.coefficients;
            coefPlotZoom = coefPlot;
            peaksHeight = [myPeaksTable.height];
            maxPeaksHeight = max(peaksHeight);
            rmsCoeff = rms(coefPlot);
            coefPlotZoom(coefPlot > maxPeaksHeight) = rmsCoeff;
            peasksPromin = [myPeaksTable.prominence]; 

            % Normalize to max of scal.
            maxCoeff = max(coefPlot);
            coefPlot = coefPlot/maxCoeff;
            coefPlotZoom = coefPlotZoom/maxPeaksHeight;
            rmsCoeff = rmsCoeff/maxCoeff;
            peasksPromin = peasksPromin/rmsCoeff;
            
            rmsLevelZoom = rmsCoeff; %Original scalogram's RMS normalized to max peak like zoom scalogram.
            rmsZoomLevel = rms(coefPlotZoom); %RMS of normalized and truncated scalogram.
            
%             figure('units','points','Position',[0 ,0 ,800,600],'Visible', Visible);
            figure('units','points','Position',[0 ,0 ,800,600],'Visible', myFinder.plotVisible);
            hold on;
            heightThresholds = str2num(plotConfig.heightThresholds);
            plot([freqPlot(1) freqPlot(xLength)], [rmsLevelZoom rmsLevelZoom]*heightThresholds(1), '--k');
            plot([freqPlot(1) freqPlot(xLength)], [rmsLevelZoom rmsLevelZoom]*heightThresholds(2), '--k');
            %plot([freqPlot(1) freqPlot(xLength)], [rmsProminence rmsProminence], ':G');
            prominenceThresholds = str2num(plotConfig.prominenceThresholds);
            plot([freqPlot(1) freqPlot(xLength)], [prominenceThresholds(2) prominenceThresholds(2)], '--', 'Color', [0.85 0.15 0.0]);
            plot([freqPlot(1) freqPlot(xLength)], [prominenceThresholds(1) prominenceThresholds(1)], '--', 'Color', [0.85 0.15 0.0]);
            validityThresholds = plotConfig.validityThresholds; %str2num(plotConfig.validityThresholds);
            plot([freqPlot(1) freqPlot(xLength)], [validityThresholds(3) validityThresholds(3)], '--', 'Color', [0.0 0.85 0.15]); %max - valid threshold
            plot([freqPlot(1) freqPlot(xLength)], [validityThresholds(2) validityThresholds(2)], '--', 'Color', [0.0 0.85 0.15]);
            plot([freqPlot(1) freqPlot(xLength)], [validityThresholds(1) validityThresholds(1)], '--', 'Color', [0.0 0.85 0.15]); %Min - mbInt.
            
            
            title('Scalogram');
            xlabel('Frequency, Hz');
            plot(freqPlot, coefPlot, 'b');
            plot(freqPlot, coefPlotZoom, 'c');
            
			validIndex = ~cellfun('isempty',strfind({myPeaksTable.label}, 'valid'));
			mbValidIndex = ~cellfun('isempty',strfind({myPeaksTable.label}, 'mbVal'));
			interestingIndex = ~cellfun('isempty',strfind({myPeaksTable.label}, 'mbInt'));
			
			plot(peaksFreq(validIndex), peaksHeight(validIndex)/maxPeaksHeight,'ro');  %'ro'
			plot(peaksFreq(mbValidIndex), peaksHeight(mbValidIndex)/maxPeaksHeight,'m.');  %'yo'
			plot(peaksFreq(interestingIndex), peaksHeight(interestingIndex)/maxPeaksHeight,'.b');  %'mo'
			
			stem(peaksFreq, [myPeaksTable.validity],'.', 'Color', [0.0 0.85 0.15]);
            stem(peaksFreq, peasksPromin, '.', 'Color', [0.85 0.15 0.0]);
            
            plot([freqPlot(1) freqPlot(xLength)], [rmsCoeff rmsCoeff], ':k');
            plot([freqPlot(1) freqPlot(xLength)], [rmsLevelZoom rmsLevelZoom]*1.00, '--k');
            plot([freqPlot(1) freqPlot(xLength)], [rmsZoomLevel rmsZoomLevel]*1.00, ':k');
            
            hold off
            
            % Close figure with visibility off
            if strcmpi(myFinder.plotVisible, 'off')
                close
            end
            
        end % end plotFileFisPeaksFound function
        
        
        % Draw Graphics for CodeFIS peakFinder %RTG FULL REWRITE!
        function [myFinder] = plotCodeFisPeaksFound(myFinder)
            
            myFinder = plotFileFisPeaksFound(myFinder);
            
        end % plotCodeFisPeaksFound

    end % methods (access = private)
    
    methods (Static, Access = public)
        
        % Draw Graphics for peakFinder
        function [myFinder] = plotPeaksFound(myFinder)
            
            iLoger = loger.getInstance;
            
            plotConfig = myFinder.config.Attributes;
            plotConfig.plots = myFinder.config.plots;
            
            imageFormat = plotConfig.plots.imageFormat;
            imageQuality = plotConfig.plots.imageQuality;
            imageResolution = plotConfig.plots.imageResolution;
            
            if myFinder.plotEnable
                switch (plotConfig.peakValidationMethod)
                    case 'FileFIS'
                        [myFinder] = plotFileFisPeaksFound(myFinder);
                    case 'CodeFIS'
                        [myFinder] = plotCodeFisPeaksFound(myFinder);
                    case {'Coarse', 'CoarseEnergy'}
                        [myFinder] = plotCoarsePeaksFound(myFinder);
                end
            end
            
%             if myFinder.printPlotsEnable == 1
%                 PicName = fullfile(pwd, 'Out', [myFinder.signalType,' Scalogram.jpg']); %, 'pics'
%                 print(PicName,'-djpeg91', '-r180');
%             end
            
            if str2double(myFinder.config.energyEstimation.Attributes.plotEnable)
                
                fullScalogramData = getFullScalogramData(myFinder);
                finderResult = getResult(myFinder);
                [energyFigure, myResult] = energyEstimator.plotScalogramPointsEnergy(fullScalogramData, finderResult);
                
                if str2double(plotConfig.printPlotsEnable)
                    % Save images to the @Out directory
                    imageNumber = '1';
                    fileName = ['scalogram-', upperCase(fullScalogramData.signalType, 'all'), '-acc-', imageNumber];
                    fullFileName = fullfile(pwd, 'Out', fileName);
                    print(energyFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
                    
                    if checkImages(fullfile(pwd, 'Out'), fileName, imageFormat)
                        printComputeInfo(iLoger, 'peaksFinder', 'The method images were saved.')
                    end
                end
                
                % Close figure with visibility off
                if strcmpi(plotConfig.plotVisible, 'off')
                    close(energyFigure)
                end 
                
%                 myFinder = setResult(myFinder, myResult);
            end
            
%             if myFinder.printPlotsEnable == 1
%                 PicName = fullfile(pwd, 'Out', [myFinder.signalType,' ScalogramEnergy.jpg']); %, 'pics'
%                 print(PicName,'-djpeg91', '-r180');
%             end
        end % function plotPeaksFound
        
    end % end static public methods
    
end