classdef interferenceClass
    
    properties (SetAccess = protected, GetAccess = public)
        %Data signal to get windows in and interf.
        signal
        %Signal averaging handler for adaptive peaksfinding, saving PT.
        handlerAve
        %Ox, sampling.
        positions
        %Window central positions.
        winCentres
        winCentresOrig
        %Parameters.
        config
        %Positions and windows of interference frames.
        interferenceFrames
        %Validated frames.
        validFrames
        %Indexes of original frames samples.
        origSamplesIdxs
		%Result with interference and it's position samples, found peaks.
		result
        validFramesIdxs
    end
    
    methods (Access = public)
        
        function myInterfObj = interferenceClass(myConfig, mySignal, myPositions, myCentrSamples)
            myConfig = fill_struct(myConfig, 'printEnable', '0');
            myInterfObj.config = myConfig;
            if ~exist('myPositions', 'var')
                myInterfObj.positions = [];
            end
            if isa(mySignal, 'signalAveragingHandler')
                myInterfObj.handlerAve = mySignal; mySignal = mySignal.signal;
            end
            if isempty(myPositions)
                myPositions = 1:numel(mySignal);
            end
            myPositions = reshape(myPositions, [], 1); myInterfObj.positions = myPositions;
            mySignal = reshape(mySignal, [], 1); myInterfObj.signal = mySignal;
            if isfield(myConfig, 'Attributes')  %'baseSample'
                baseSample = str2double(myConfig.Attributes.baseSample);
                myInterfObj = setBaseWind(myInterfObj, baseSample);
            end
            if exist('myCentrSamples', 'var')  %Rewrite central window samples.
                myInterfObj = setCentralWindSamples(myInterfObj, myCentrSamples);
            end
            if isfield(myConfig, 'maxWindowsNum')
                maxNum = str2double(myConfig.maxWindowsNum);
                if ~isnan(maxNum) && (maxNum ~= Inf)
                    maxWindowsNum = min( [maxNum numel(myInterfObj.winCentres)] );
                    myInterfObj.winCentres = myInterfObj.winCentres(1:maxWindowsNum);
                end
            end
            myInterfObj.winCentresOrig = myInterfObj.winCentres;
            if nnz(myInterfObj.winCentres)
                myInterfObj = firstSampleChecking(myInterfObj);
            end
        end
        
        function myInterfObj = firstSampleChecking(myInterfObj)
            if isempty(myInterfObj.winCentres)
               return; 
            end
            %=====First sample checking.=====
            baseSample = myInterfObj.winCentres(1);
            myWind = getWindowSamples(myInterfObj, baseSample);  %The first window.
            lowSample = myWind(1);
            if lowSample < 1
                warning('The first base samples window exceeds permitted range.')
                if strcmp(myInterfObj.config.widthEntity, 'percent')
                    myInterfObj.config.windDist = '90';  %Percents.
                else
                    myInterfObj.config.widthEntity = 'samples';
                    myInterfObj.config.windWidth = num2str(floor(0.95*baseSample));
                end
            end
        end
		
		function myResult = getResult(myInterfObj)
			myResult = myInterfObj.result;
        end
        
        function myInterfObj = setConfig(myInterfObj, myConfig)
            myInterfObj.config = myConfig;
        end
        
        function myInterfObj = setAverager(myInterfObj, myHandlerAve, reset)
            if ~exist('reset', 'var'), reset = 0; end
            if reset || isempty(myHandlerAve.signal) %Setting signal and making PT.
                myHandlerAve = myHandlerAve.setSignal(myInterfObj.signal);
            end
            myInterfObj.handlerAve = myHandlerAve;
        end
		
		function myInterfWindows = getInterfWindows(myInterfObj, mode)
            if ~exist('mode', 'var')
               mode = [];
            end
            if strfind(mode, 'origSamplesIdxs')
                myInterfWindows = myInterfObj.origSamplesIdxs;
                return;
            end
			myInterfWindows = myInterfObj.validFrames;
            if strfind(mode, 'Orig')
                myInterfWindows = myInterfObj.interferenceFrames;
                mode = strrep(mode, 'Orig', '');
            end
            if isempty(myInterfWindows)
                outLog(myInterfObj, 'There is no any valid interference windows!\n');
                return;
            end
            if strcmp(mode, 'positions')
                myInterfWindows = myInterfWindows(1, :);
            end
            if strcmp(mode, 'coeffs')
                myInterfWindows = myInterfWindows(2, :);
            end
        end
        
        function myWinCentres = getWinCentres(myInterfObj)
            myWinCentres = myInterfObj.winCentres;
        end
        
        function myInterfObj = setBaseWind(myInterfObj, baseSample)
            %Base - the first central sample of sequence.
            if exist('baseSample', 'var')
                myInterfObj.config.Attributes.baseSample = num2str(baseSample);
            end
            myConfig = myInterfObj.config;
            baseSample = str2double(myConfig.Attributes.baseSample);
            %Sequence distance mb equal to the first element distance, of it's mb shift.
            if isfield(myConfig.Attributes, 'windDist')
                windDist = str2double(myConfig.Attributes.windDist);
            else
                windDist = baseSample;
            end
            myWind = getWindowSamples(myInterfObj, baseSample);
            if myWind(1) < 1  %Window is wider than the first sample situated.
                myInterfObj.config.windWidth = num2str( (baseSample - 1)*2 );
                myInterfObj.config.widthEntity = 'samples';
                warning('Your window is wider than the first sample situated.');
            end
            %Sequence elements and their windows - from the first (base) to the last element whose window can be placed in signal.
            maxWinNumb = ceil( (length(myInterfObj.signal) - baseSample)/windDist );
            if ~nnz(maxWinNumb)
                warning('Can''t set any window in signal.');
            end
            maxWinSamp = maxWinNumb*windDist;
            rightSamp = length(myInterfObj.signal) + 1;
            %Window width mb exceed signal vector and mb depending on it's central sample. Rest only windows that can be placed.
            while rightSamp > length(myInterfObj.signal)
                myWind = getWindowSamples(myInterfObj, maxWinSamp);
                rightSamp = myWind(end);
                if rightSamp > length(myInterfObj.signal)
                    maxWinSamp = maxWinSamp - windDist;
                end
            end
            myInterfObj.winCentres = baseSample:windDist:maxWinSamp;
        end
        
        function myInterfObj = setCentralWindSamples(myInterfObj, myCentrSamples)
            %Sequence elements and their windows - from the first (base) to the last element whose window can be placed in signal.
            maxWinNumb = numel(myCentrSamples);
            rightSamp = length(myInterfObj.signal) + 1;
            %Window width mb exceed signal vector and mb depending on it's central sample. Rest only windows that can be placed.
            while rightSamp > length(myInterfObj.signal)
                myWind = getWindowSamples(myInterfObj, myCentrSamples(maxWinNumb));  %Get the last window.
                rightSamp = myWind(end);  %The last sample of the last window.
                if rightSamp > length(myInterfObj.signal)
                    maxWinNumb = maxWinNumb - 1;
                    if ~maxWinNumb %The first window more than signal length.
                        maxWinNumb = 1;  %The only one frame will be from the first central sample to the end.
                        myInterfObj.config.windWidth = num2str( (length(myInterfObj.signal) - myCentrSamples(1))*2 );
                        myInterfObj.config.widthEntity = 'samples';
                        warning('The first window more than signal length.');
                    end
                end
            end
            myInterfObj.winCentres = myCentrSamples(1:maxWinNumb); myInterfObj.winCentresOrig = myInterfObj.winCentres;
        end
        
        function myInterfObj = compInterference(myInterfObj)
            %%Get all window frames and multiply them.
			%Two rows - window positions cells and windows.
            myInterfObj = firstSampleChecking(myInterfObj);
			myInterfObj = getInterferenceFrames(myInterfObj);
            myInterferenceFrames = myInterfObj.validFrames;
            if ~numel(myInterferenceFrames)
                myInterfObj.result.interference = 0;
                myInterfObj.result.positions = 0;
                myInterfObj.result.peaksIdxs = 0;
                myInterfObj.result.peaksPosits = 0;
                myInterfObj.result.peaksHeights = 0;
                myInterfObj.result.peaksWidths = 0;
                myInterfObj.result.validities = 0;
                myInterfObj.result.fullValidities = 0;
                return;
            end
			myInterfObj.result.positions = myInterferenceFrames{1, 1};
			myInterference = ones(size(myInterferenceFrames{1, 1}));
			for i = 1:numel(myInterferenceFrames(2, :))
                mIF = myInterferenceFrames{2, i}/max(myInterferenceFrames{2, i});
				myInterference = myInterference.*mIF;  %myInterferenceFrames{2, i};
			end
			%myInterfObj.interference = myInterference;
			myInterfObj.result.interference = myInterference;
			%Interference peaks finding result
			peaksConf = myInterfObj.config.peaksFinding.Attributes;
            peaksConf.minPeakProminence = num2str(0.1*std(myInterference));
			interfPeaks = peaksFilter(myInterference, peaksConf);
			myInterfObj.result.peaksIdxs = interfPeaks.indexes;
			myInterfObj.result.peaksPosits = myInterferenceFrames{1, 1}(interfPeaks.indexes);
			myInterfObj.result.peaksHeights = myInterference(interfPeaks.indexes);
			myInterfObj.result.peaksWidths = interfPeaks.widths;
			myInterfObj.result.validities = interfPeaks.validities;
            myInterfObj.result.fullValidities = interfPeaks.validities.*myInterference(interfPeaks.indexes)/rms(myInterference)./interfPeaks.widths;
        end
		
		function plotInterf(myInterfObj, fileName)
            Root=fullfile(fileparts(mfilename('fullpath')),'..','..','..');
			figure('units', 'points', 'Position', [0 ,0 ,800,600]);
			hold on
			%plot(myInterfObj.interfWind, myInterfObj.interference);
			plot(myInterfObj.result.positions, myInterfObj.result.interference);
			stem(myInterfObj.result.peaksPosits, myInterfObj.result.peaksHeights);
			if exist('fileName', 'var')
				saveas( gcf, fullfile(Root, 'Out', [fileName 'interfRes.jpg']), 'jpg' );
			end
            %Out frames.
			figure('units', 'points', 'Position', [0 ,0 ,800,600]);
			hold on
            plot(myInterfObj.positions, myInterfObj.signal)
            framesPoses = myInterfObj.validFrames(1, :);
            framesCoeffs = myInterfObj.validFrames(2, :);
			for i = 1:min([100 numel(framesPoses)])
				stem(framesPoses{i}(1), framesCoeffs{i}(1), 'bo'); %Frame start points.
				stem(framesPoses{i}(end), framesCoeffs{i}(end), 'co'); %Frame end points.
                middlePoint = round(numel(framesPoses{i})/2);
				stem(framesPoses{i}(middlePoint), framesCoeffs{i}(middlePoint), 'g*'); %Frame central point.
            end
            stem(myInterfObj.positions(myInterfObj.winCentresOrig), myInterfObj.signal(myInterfObj.winCentresOrig), 'k+')  %All frame centres.
            legend('Signal', 'Frame start points', 'Frame end points', 'Frame central points', 'All frame centres');
            %axis( [ 0, ceil(0.01*max(myInterfObj.positions)), 0, max(myInterfObj.signal) ] );
			if exist('fileName', 'var')
				saveas( gcf, fullfile(Root, 'Out', [fileName 'signalFrames.jpg']), 'jpg' );
			end
		end
        
        function myInterfObj = getInterferenceFrames(myInterfObj, baseSamples)
			if ~exist('baseSamples', 'var')
				baseSamples = myInterfObj.winCentres;
			end
            %Smooth and interpolate a signal window if it's necessary.
            myInterferenceFrames = [];
            myValidInterferenceFrames = [];
            myOrigSamplesIdxs = [];
            if ~numel(baseSamples)
               outLog(myInterfObj, 'There is no base samples.\n');
               return; 
            end
            myConfig = myInterfObj.config;
            myAverConfig.windowAveraging.saveSampling = '0';  %Restore samples number in wider frames.
			for i = 1:numel(baseSamples)
				myWind = getWindowSamples(myInterfObj, baseSamples(i)); %Positions of window samples.
                myOrigSamplesIdxs = [myOrigSamplesIdxs {myWind}];
				myCoeffs = myInterfObj.signal(myWind);
				myWind = myInterfObj.positions(myWind);
				if strcmp(myConfig.widthEntity, 'percent')
					%Smooth by summ in frame, equal samples number in different frames.
                    myAverConfig.span = num2str(i); %Window width grow proportional to base sample.
                    myHandler = signalAveragingHandler(myWind, myAverConfig);
                    [~, myValidWind] = windowAveraging(myHandler);
                    myHandler = signalAveragingHandler(myCoeffs, myAverConfig);
                    [~, myValidCoeffs] = windowAveraging(myHandler);
                    myValidInterferenceFrames = [myValidInterferenceFrames {myValidWind; myValidCoeffs}];
				end
                %myCoeffs = myCoeffs/max(myCoeffs);
				myInterferenceFrames = [myInterferenceFrames {myWind; myCoeffs}];
            end
            myInterfObj.origSamplesIdxs = myOrigSamplesIdxs;
			myInterfObj.interferenceFrames = myInterferenceFrames;
			myInterfObj.validFrames = myValidInterferenceFrames;
            %Make equal samples number.
            myInterfCoeffs = getInterfWindows(myInterfObj, 'coeffs');
            if strcmp(myConfig.widthEntity, 'percent') && iscell(myInterfCoeffs)
                myInterfPoses = getInterfWindows(myInterfObj, 'positions');
                numElems = cellfun(@(x) numel(x), myInterfCoeffs);
                numElems = min(numElems);
                myInterfCoeffs = cellfun(@(x) x(1:numElems), myInterfCoeffs, 'UniformOutput', false);
                myInterfPoses = cellfun(@(x) x(1:numElems), myInterfPoses, 'UniformOutput', false);
                myInterfObj.validFrames = [myInterfPoses; myInterfCoeffs];
            end
            myInterfObj = setValidFrames(myInterfObj);
        end
        
        %Return samples according to the pointed window.
        function myWind = getWindowSamples(myInterfObj, baseSample)
                myConfig = myInterfObj.config;
                relWidth = str2double(myConfig.windWidth);
                %Sample cost.
                ds = abs(myInterfObj.positions(2) - myInterfObj.positions(1));
                %Translate different units to samples.
                if strcmp(myConfig.widthEntity, 'percent')
                    %Percent of window's central sample.
                    windWidth = baseSample*relWidth/100/ds;
                elseif strcmp(myConfig.widthEntity, 'diffPercent')
                    %Percent of distance between central samples.
                    windDist = str2double(myConfig.windDist);
                    windWidth = windDist*relWidth/100;
                elseif strcmp(myConfig.widthEntity, 'sampleUnit')
                    %Width is number in sampling units.
                    windWidth = relWidth;
                elseif strcmp(myConfig.widthEntity, 'span') %Take from existing averager.
                     windWidth = str2double(myInterfObj.handlerAve.config.span)/ds;
                else
                    %Width is number in samples.
                    windWidth = relWidth/ds;
                end
                %Translate from sample units to samples.
                windWidth = windWidth*ds;
                myWind = (baseSample - round(windWidth/2)):(baseSample + round(windWidth/2));
        end
        
        function myInterfObj = setValidFrames(myInterfObj)
            if isempty(myInterfObj.validFrames)
                myInterfObj.validFrames = myInterfObj.interferenceFrames;
            end
            if ~isfield(myInterfObj.config, 'framesValidation')
                return;
            end
            validityThreshold = str2double(myInterfObj.config.framesValidation.Attributes.validityThreshold);
            myInterfCoeffs = getInterfWindows(myInterfObj, 'coeffs');
            if ~iscell(myInterfCoeffs)
                return;
            end
            if numel(myInterfCoeffs{1}) < 3
               warning('Interference frames should contain at least 3 samples!');
               myInterfObj.validFrames = myInterfObj.validFrames(:, []);
               return;
            end
            %myFrameValidities = cellfun(@(x) validateFrame(myInterfObj, x), myInterfCoeffs);
            myFrameValidities = zeros(size(myInterfCoeffs));
            for i = 1:numel(myInterfCoeffs)
                myFrameValidities(i) = validateFrame(myInterfObj, myInterfCoeffs{i});
            end
            validIdxs = myFrameValidities > validityThreshold;
            myInterfObj.validFrames = myInterfObj.validFrames(:, validIdxs);
            myInterfObj.winCentres = myInterfObj.winCentresOrig(validIdxs);
            myInterfObj.validFramesIdxs = find(validIdxs);
        end
        
        function myFrameValidity = validateFrame(myInterfObj, myFrame)
			peaksConf = myInterfObj.config.peaksFinding.Attributes;
            peaksConf.minPeakProminence = num2str(std(myFrame));
            if ~isempty(myInterfObj.handlerAve)
                [~, idx] = arrayfun(@(x) min(abs(myInterfObj.signal - x)), [myFrame(1) myFrame(end)]);
                peaksConf.computePeaksTable = '0'; mode = [ 'orig' num2str([idx(1) idx(end)]) ];
                myFrame = myInterfObj.handlerAve.getTable(mode);
            end
            frameResult = peaksFilter(myFrame, peaksConf);
            [myFrameValidity, idx] = max(frameResult.validities);
            if myFrameValidity
                heiVal = frameResult.magnitudes(idx) > rms(myInterfObj.signal);
                myFrameValidity = myFrameValidity*double(heiVal);
            end
        end
        
        %Function restores PT with missed elements and return full table with restored idxs, valids only, missed only.
        %Restore assigned table, valid interf window centres or full wind table.
        %Table is valid interference window centres default wich are signal peaks indexes.
        function [myInterfObj, fullTable, validTable, missedTable] = fillMissedIdxs(myInterfObj, myTable)
            if ~exist('myTable', 'var'), myTable = 'valid'; end
            if ischar(myTable)
                myTable = myInterfObj.winCentres;
                if strcmp(myTable, 'valid'), myTable = myInterfObj.validFramesIdxs; end
                if strcmp(myTable, 'orig'), myTable = myInterfObj.winCentresOrig; end
            end
            validTable = myTable; fullTable = myTable; missedTable = [];
            if isempty(myTable), return; end
            %====Process a few miss/fill relations.====
            rels = strsplit(myInterfObj.config.PTfilling.Attributes.missNumPerOnes, ',');
            if numel(rels) > 1
                Attributes = arrayfun(@(x) setfield(myInterfObj.config.PTfilling.Attributes, 'missNumPerOnes', x{1}), rels, 'UniformOutput', false);
                configs = cellfun(@(x) setfield(myInterfObj.config, 'PTfilling', setfield(myInterfObj.config.PTfilling, 'Attributes', x)), Attributes, 'UniformOutput', false);
                intObjs = cellfun(@(x) setConfig(myInterfObj, x), configs, 'UniformOutput', false);
                [~, fullTable, validTable, missedTable] = cellfun(@(x) fillMissedIdxs(x, myTable), intObjs, 'UniformOutput', false);
                validTables = cellfun(@(x) ~isempty(x), missedTable);
                if ~nnz(validTables)
                    validTable = myTable; fullTable = myTable; missedTable = [];
                else
                    validTable = unique([validTable{:}]); fullTable = unique([fullTable{:}]); missedTable = unique([missedTable{:}]);
                end
                %Total missed number sh.b. less validity threshold.
                numThreshold = str2double(myInterfObj.config.PTfilling.Attributes.numThreshold);
                if (numel(missedTable)/numel(validTable)) > numThreshold
                    validTable = myTable; fullTable = myTable; missedTable = [];
                    outLog(myInterfObj, 'Too great number of missed peaks.', 'warn'); return;
                end
                myInterfObj = setCentralWindSamples(myInterfObj, fullTable);
                return;
            end
            %Get table of equidistant positions with average distance.
            distAv = str2double(myInterfObj.config.PTfilling.Attributes.distance);
            if isnan(distAv), distAv = mean(diff(validTable)); end
            fullTable = round( linspace(myTable(1), myTable(end), round((myTable(end)-myTable(1))/distAv) + 1) );%round(myTable(1):distAv:myTable(end));
            %=Replace full table by existing peaks in valid table. Define similars as peaks in assigned interval.=
            if nnz(strfind(myInterfObj.config.PTfilling.Attributes.trustedInterval, 'dist'))
                trustedInterval = strrep(myInterfObj.config.PTfilling.Attributes.trustedInterval, 'dist', '');
                trustedInterval = str2double(trustedInterval)*distAv;
            else
                trustedInterval = str2double(myInterfObj.config.PTfilling.Attributes.trustedInterval);
            end
            for i = 1:numel(fullTable) %If exist the current peak in valid table (it's closer then trusted interval),
                [closeDiff, closeIdx] = min(abs( validTable - fullTable(i) )); %replace it by valid table's position.
                if closeDiff < trustedInterval, fullTable(i) = validTable(closeIdx); end
            end
            %Get positions of elements, that are missed in valid table.
            [~, ~, missIdxsInFull] = setxor(validTable, fullTable); missedTable = fullTable(missIdxsInFull);
            %====There are several missed one-by-one positions per sequently standing positions.====
            %====Missed idxs sh.b. less max miss numb, neighbour ones sequences sh.b. longer min numb.====
            threshs = strsplit(myInterfObj.config.PTfilling.Attributes.missNumPerOnes, '/');
            threshs = cellfun(@(x) str2double(x), threshs); %The first is missed max, the sec - min ones neigh. num.
            missIdxs = 1:numel(fullTable); missIdxs = arrayfun(@(x) nnz(x == missIdxsInFull), missIdxs);
            %-=Take missed and filled ranges.=-
            missRanges = takeOneByOneBands(double(~missIdxs), struct('succession', 'zero'));
            if ~numel(missRanges), return; end
            missRanges = cellfun(@(x) x(1):x(end), missRanges, 'UniformOutput', false);
            fillRanges = takeOneByOneBands(double(missIdxs), struct('succession', 'zero'));
            if ~numel(fillRanges), return; end
            fillRanges = cellfun(@(x) x(1):x(end), fillRanges, 'UniformOutput', false);
            nums = cellfun(@(x) numel(x), missRanges); %Choose miss peaks ranges where low number misses.
            valMissesIdxs = nums <= threshs(1); missRanges = missRanges(valMissesIdxs);
            nums = cellfun(@(x) numel(x), fillRanges); %Choose fill peaks ranges where high number filles.
            valFillesIdxs = nums >= threshs(2); fillRanges = fillRanges(valFillesIdxs);
            %-=Exclude from table too long missed and too low filled neighbours number.=-
			%-=Get valid miss and fill ranges borders, get one-by-one fill-miss-fill, rest only misses in centres.=-
            missStarts = cellfun(@(x) x(1), missRanges); missEnds = cellfun(@(x) x(end), missRanges);
            fillStarts = cellfun(@(x) x(1), fillRanges); fillEnds = cellfun(@(x) x(end), fillRanges);
% 			beginDiffMatrix = [fillEnds; missStarts]; %Rows are previous filled ranges ends and the current missed ranges starts.
% 			endDiffMatrix = [missEnds; fillStarts]; %Rows are the current missed ranges ends and the next filled starts.
% 			beginDiffVect = diff(beginDiffMatrix, 1); endDiffVect = diff(endDiffMatrix, 1);
% 			validBegins = (beginDiffVect > 0) & (beginDiffVect < 2); validEnds = (endDiffVect > 0) & (endDiffVect < 2);
% 			validPositions = validBegins & validEnds; %Get ranges with one-by-one standing borders.
            validBegins = zeros(size(missStarts)); validEnds = validBegins;
            for i = 1:numel(missStarts) %Check each miss start and end position and fill start and end.
                validBegins(i) = nnz(missStarts(i) - fillEnds == 1); %Idxs of ranges with valid previous
                validEnds(i) = nnz(missEnds(i) - fillStarts == -1); %and the next filled ranges.
            end
			validPositions = validBegins & validEnds; missRanges = missRanges(validPositions); %Get ranges with one-by-one standing borders.
			if nnz(cellfun(@(x) ~isempty(x), missRanges))
				missedTable = fullTable([missRanges{:}]); fullTable = sort([myTable, missedTable]);
			end
            %Total missed number sh.b. less validity threshold.
            numThreshold = str2double(myInterfObj.config.PTfilling.Attributes.numThreshold);
            if (numel(missedTable)/numel(validTable)) > numThreshold
                validTable = myTable; fullTable = myTable; missedTable = [];
                outLog(myInterfObj, 'Too great number of missed peaks.', 'warn'); return;
            end
            myInterfObj = setCentralWindSamples(myInterfObj, fullTable);
%             figure; plot(myInterfObj.positions, myInterfObj.signal); hold on
%             stem(myInterfObj.positions(fullTable([missRanges{:}])), myInterfObj.signal(fullTable([missRanges{:}])), 'cx');
%             stem(myInterfObj.positions(fullTable([fillRanges{:}])), myInterfObj.signal(fullTable([fillRanges{:}])), 'r+');
        end
        
        function outLog(myInterfObj, str2out, mode)
            if ~exist('mode', 'var'), mode = ''; end
            if ~str2double(myInterfObj.config.printEnable), return; end
            if str2double(myInterfObj.config.printEnable) == 2, mode = strrep(mode, 'Loger', ''); end %If enabling eq. 2, forbidd loger;
            if (str2double(myInterfObj.config.printEnable) == 3) && ~nnz(strfind(mode, 'Loger')), return; end %if 3 - loger output only.
            try
                iLoger = loger.getInstance;
            catch
                iLoger = [];
            end
            if isstruct(str2out), disp(str2out); end %It's possible display structures into command window.
            if ~nnz(strfind(mode, 'Loger'))
                if nnz(strfind(mode, 'warn')), fprintf('\nInterference signal processing: WARNING:\n'); end
                fprintf(str2out);
            else
                try
                    if ~nnz(strfind(mode, 'warn'))
                        printComputeInfo(iLoger, myInterfObj.compStageString, str2out);
                    else
                        printWarning(iLoger, myMessage);
                    end
                catch
                    mode = strrep(mode, 'Loger', ''); outLog(myInterfObj, str2out, mode);
                end
            end
        end
        
    end
    
end