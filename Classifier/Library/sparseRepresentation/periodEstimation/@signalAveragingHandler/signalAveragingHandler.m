classdef signalAveragingHandler

	properties (SetAccess = protected, GetAccess = public)
		signal
		config
		resultSignal
		%Peaks tables of initial signal: original and after processing.
		originPT
		%This PT is also PT of initial signal, it's need for further signal processing.
		procPT
	end

	methods(Access = public)
		
		function myHandler = signalAveragingHandler(mySignal, myConfig)
			myHandler.signal = mySignal;
            myHandler = setConfig(myHandler, myConfig);
        end
        
        %Set parameters and configuration struct. It's necessary to not recompute original PT for the same signal.
		function myHandler = setConfig(myHandler, myConfig)
            myConfig = fill_struct(myConfig, 'Attributes', []);
            myConfig.Attributes = fill_struct(myConfig.Attributes, 'detrend4peaksFinding', '0');
            myConfig = fill_struct(myConfig, 'setPeaksTable', '0'); %Don't check original PT for increasing performance.
			myHandler.config = myConfig;
			myHandler.procPT = []; %Old processed PT is not actual.
            if str2double(myConfig.setPeaksTable), myHandler = checkPT(myHandler); end
            if nnz(strfind(myConfig.span, 'dist')) || nnz(strfind(myConfig.span, 'width'))
                %Assign span and it's entities - global peaks distancies or widths.
                [span, myHandler] = getSpanAuto(myHandler, myConfig.span);
                myConfig.span = strrep(myConfig.span, 'dist', '');
                myConfig.span = strrep(myConfig.span, 'width', '');
                mul = str2double(myConfig.span);  %Pointed in widths/dist entities.
                myConfig.span = num2str(span*mul);
            end
            myConfig = fill_struct(myConfig, 'windowAveraging', []); myConfig.windowAveraging = fill_struct(myConfig.windowAveraging, 'saveSampling', '0');
            if ((str2double(myConfig.span) < 3) && str2double(myConfig.windowAveraging.saveSampling)) || isnan(str2double(myConfig.span))
                myConfig.span = '3';
            end
			myHandler.config = myConfig;
			%myHandler = signalAveragingHandler(myHandler.signal, myConfig);
        end
        
		function myHandler = setSignal(myHandler, mySignal)
			myHandler.signal = mySignal;
			myHandler.originPT = []; %myHandler.originPT = peaksFilter(mySignal);
			myHandler.procPT = [];
        end
        
        %Function checkPT fills initial peaks table if it's empty.
        %Fill PT once and only if it will be used for increasing performance.
		function myHandler = checkPT(myHandler)
            if isempty(myHandler.originPT) %Check peaks table. Checking PT removed 
                myConfig = myHandler.config; mySignal = myHandler.signal; %here for increasing performance.
                if str2double(myConfig.Attributes.detrend4peaksFinding), [~, mySignal] = detrendACF(myHandler, mySignal); end
                myHandler.originPT = peaksFilter(mySignal);
            end
        end
        
		function [myTable, pks, locs, widths, proms] = getTable(myHandler, mode)
            if ~exist('mode', 'var') 
                mode = '';
            end
            myHandler = checkPT(myHandler);
			myTable = myHandler.procPT;
			if strfind(mode, 'orig')
				myTable = myHandler.originPT; mode = strrep(mode, 'orig', '');
			end
			md = strsplit(mode); sortIdx = cellfun(@(x) strfind(x, 'cend'), md, 'UniformOutput', false);
            sortIdx = find(cellfun(@(x) ~isempty(x), sortIdx));
			if nnz(sortIdx)
				[myTable.magnitudes, idxs] = sort(myTable.magnitudes, md{sortIdx}); myTable.proms = myTable.proms(idxs);
				myTable.widths = myTable.widths(idxs); myTable.indexes = myTable.indexes(idxs);
                mode = strrep(mode, 'ascend', ''); mode = strrep(mode, 'descend', '');
            end
            if isempty(myTable)
                warning('Result peaks table is empty!');
                pks = []; locs = []; widths = []; proms = [];
                return;
            end
            rangeOfLocs = str2num(mode);
            if ~isempty(rangeOfLocs)
                idxs2get = (myTable.indexes > rangeOfLocs(1)) & (myTable.indexes < rangeOfLocs(end));
                myTable = trimFields(myTable, idxs2get);
            end
			pks = myTable.magnitudes; locs = myTable.indexes;
			widths = myTable.widths; proms = myTable.proms;
        end
        
		function [myHandler] = setTable(myHandler, pks, locs, widths, proms, mode)
            if ~exist('mode', 'var') 
                mode = '';
            end
			myTable.magnitudes = pks; myTable.indexes = locs;
			myTable.widths = widths; myTable.proms = proms;
			if ~nnz(strfind(mode, 'orig'))
				myHandler.procPT = myTable;
			else
				myHandler.originPT = myTable;
			end
        end
		
		function [myHandler, myResultSignal] = windowAveraging(myHandler, span, mode)
            if ~exist('span', 'var') 
                span = [];
            end
            if isempty(span) 
                span = round(str2double(myHandler.config.span));
            end
            if (span < 3) && (str2double(myHandler.config.windowAveraging.saveSampling))
                warning('Can''t process span less 3!'); span = 3;
            end
            if ~exist('mode', 'var') 
                mode = '';
            end
            if strfind(mode, 'bothSide')
               %Make averagig in right and left direction 2 save a peaks positions.
               span1 = span;
               if span1 >= 6
                  if rem(span1, 2) %Make even span to divide it.
                      span1 = span1 + 1;
                  end
                  span1 = span1/2;
               end
               myOrigSignal = myHandler.signal;
               myHandler = signalReflection(myHandler);
               myHandler = windowAveraging(myHandler, span1, 'resultSign');
               myHandler.signal = myHandler.resultSignal;
               myHandler = signalReflection(myHandler);
               myHandler = windowAveraging(myHandler, span1, 'resultSign');
               myHandler.signal = myOrigSignal;
               myResultSignal = myHandler.resultSignal;
               return;
            end
            if strfind(mode, 'inversionAver')
               %Average signal and it's inversion with span, and average them.
               [~, myResultSignal1] = windowAveraging(myHandler, span);
               myHandler.signal = -myHandler.signal;
               [~, myResultSignal2] = windowAveraging(myHandler, span);
               myResultSignal = (myResultSignal1 - myResultSignal2)/2;
               myHandler.resultSignal = myResultSignal;
               return;
            end
			myData = myHandler.signal;
            if strfind(mode, 'resultSign')
                myData = myHandler.resultSignal;
            end
            framesNumber = floor(length(myData)/span);
            if framesNumber < 1
                warning('There is too wide span for this signal.');
                myResultSignal = myHandler.signal; myHandler.resultSignal = myResultSignal;
                return;
            end
            remData = myData(framesNumber*span+1:end);
            myData = myData(1:framesNumber*span);
            myResultSignal = reshape(myData, span, []);
            myResultSignal = sum(myResultSignal, 1)/span;
            if str2double(myHandler.config.windowAveraging.saveSampling)
                % Signal interpolation  
                interpStep = 1/span;
                originalSamples = [0.5+interpStep, 1:length(myResultSignal), length(myResultSignal)+0.5];
                interpolateSampels = 0.5+interpStep:interpStep:length(myResultSignal)+0.5;
                averSam = 1:floor(span/2);
                firstSam = mean(myData(averSam));
                lastSam = mean(myData(end-averSam+1));
                myResultSignal = [firstSam myResultSignal lastSam];
                myResultSignal = interp1(originalSamples, myResultSignal, interpolateSampels, 'pchip');
                if numel(remData) > 3 %It's sh. b. more than 3 samples 4 interpolation.
                    interpolateSampels = linspace(1, 3, length(remData));
                    remData = [remData(1) mean(remData) remData(end)];
                    originalSamples = 1:length(remData);
%                     remData = [remData(1) remData remData(end)];
                    remData = interp1(originalSamples, remData, interpolateSampels, 'pchip');
                else
                    remData = remData';
                end
                myResultSignal = [myResultSignal remData]';
            end
			myHandler.resultSignal = myResultSignal;
		end
		
		%Function implements slide averaging with 'span' samples.
		function [myHandler, myResultSignal] = slideAveraging(myHandler, span)
            if ~exist('span', 'var') 
                span = str2double(myHandler.config.span);
            end
			myData = myHandler.signal;
			myResultSignal = smooth(myData, span);
			myHandler.resultSignal = myResultSignal;
		end
		
		%Function implements slide averaging with 'span' samples.
		%To prevent peaks shifting make averaging in both directions.
		%Use signal reflection for direction changing.
		function [myHandler, myResultSignal] = centralSlideAveraging(myHandler, span)
            if ~exist('span', 'var') 
                span = str2double(myHandler.config.span);
            end
			myHandler = signalReflection(myHandler);
			span = round(span/2);
			myHandler = slideAveraging(myHandler, span);
			myHandler = signalReflection(myHandler);
			[myHandler, myResultSignal] = slideAveraging(myHandler, span);
		end
		
		%Reflect signal vector.
		function [myHandler, myResultSignal] = signalReflection(myHandler)
			mySignal = myHandler.signal;
			idxs = numel(mySignal):-1:1;
			myResultSignal = mySignal(idxs);
			myHandler.resultSignal = myResultSignal;
		end
		
		function [myHandler, myResultSignal] = highPeaksTopsSmoothing(myHandler)
			%=====Carry on envelope of great peaks to divide on windows with different peak levels=====
                [~, peaksPosits] = findpeaks(myHandler.signal);
                myPositions = getTheBestPeaksNum( myHandler, ceil(numel(peaksPosits)/10) );
                globalLocs = getGoodPeaks(myHandler, myPositions);
                myResultSignal = myHandler.signal;
                if numel(globalLocs) < 3
                   globalLocs = myPositions;
                end
                if numel(globalLocs) < 3
                   warning('Too low peaks number.');
                   return;
                end
                %Interpolate signal between peaks 2 save original samples number and get their envelope.
                %originalSamples = 1:length(globalLocs);
                originalSamples = globalLocs;
                %Add a signal beginning and end points, if they are not in orig samples.
                %In other case envelope behaving like a usual parabola.
                if originalSamples(1) ~= 1
                    originalSamples = [1; originalSamples];
%                     globalVals = [myHandler.signal(1); globalVals];
                end
                if originalSamples(end) ~= numel(myHandler.signal)
                    originalSamples = [originalSamples; numel(myHandler.signal)];
%                     globalVals = [globalVals; myHandler.signal(end)];
                end
                globalVals = myHandler.signal(originalSamples);
                interpolateSampels = 1:length(myHandler.signal);
                %globalLocsInterp = interp1(originalSamples, globalLocs, interpolateSampels, 'pchip');
                globalValsInterp = interp1(originalSamples, globalVals, interpolateSampels, 'pchip');
                myResultSignal = globalValsInterp;
                myHandler.resultSignal = myResultSignal;
        end
        
        function [span, myHandler] = getSpanAuto(myHandler, mode)
            if ~exist('mode', 'var') 
                mode = '';
            end
            myHandler = checkPT(myHandler);
			[~, peaksHeis, peaksPosits, peaksWidths, peaksProms] = getTable(myHandler, 'orig');
            [peaksNum, mi] = max([ceil(numel(peaksPosits)/10) 10]);
            if mi == 2, warning('There is too low peaks number.'); end
            %Get the most high/prom/glob peaks depening on settings.
            myPositions = getTheBestPeaksNum( myHandler, peaksNum );
            %Get the most high and prominent of them by statistic distribution.
            globalLocs = getGoodPeaks(myHandler, myPositions);
            if numel(peaksPosits) < 10
               warning('It''s too low peaks number in your signal.');
               globalLocs = peaksPosits; %Use all peaks in low peaks number signal.
            end
            if numel(globalLocs) < 10
                globalLocs = myPositions;
            end
            %Chosen's (globalLocs) positions in the full peaks positions vector.
            [PT, idxs] = intersect(peaksPosits, globalLocs);
            peaksWidths = peaksWidths(idxs);
			peaksProms = peaksProms(idxs); peaksHeis = peaksHeis(idxs);
            if strfind(mode, 'dist')
                %Peaks distance averaging.
                span = mean(diff(globalLocs));
            else
                %Peaks width averaging.
                span = mean(peaksWidths);
            end
            span = round(span);
			[myHandler] = setTable(myHandler, peaksHeis, PT, peaksWidths, peaksProms);
        end
        
        %The most high and prominent peaks: upper higher distribution border.
        function [myPositions, myHandler] = getGoodPeaks(myHandler, peaksTable)
            myHandler = checkPT(myHandler);
            if ~exist('peaksTable', 'var') 
                peaksTable = [];
            end
            if ischar(peaksTable) 
                peaksTable = getTable(myHandler, peaksTable);
            end
            %Find the most prominent and high peaks.
			[~, promHeights, promLocs, widths, prominences] = getTable(myHandler, 'orig');
            if ~isempty(peaksTable)
                %Indexes of the common (i.e. peaksTables) elems in found peaks table.
                [promLocs, idxs] = intersect(promLocs, peaksTable);
                promHeights = promHeights(idxs);
                prominences = prominences(idxs);
                widths = widths(idxs);
            end
            prominentIdxs = find(prominences > ( mean(prominences) + std(prominences) ));
            highIdx = find(promHeights > ( mean(promHeights) + std(promHeights) ));
            goodIdx = intersect(prominentIdxs, highIdx);
            if numel(goodIdx) < 10
                goodIdx = prominentIdxs;
            end
            myPositions = promLocs(goodIdx); myHeigths = promHeights(goodIdx);
			myWidths = widths(goodIdx); myProms = prominences(goodIdx);
			[myHandler] = setTable(myHandler, myHeigths, myPositions, myWidths, myProms);
        end
		
		function [myPositions, myHandler] = getTheBestPeaksNum(myHandler, theBextPeaksNum)
            globSeach = 0; promSeach = 0;
            myConfig = myHandler.config;
            myHandler = checkPT(myHandler);
            if isfield(myHandler.config, 'theBextPeaksNum')
                if strfind(myHandler.config.theBextPeaksNum, 'glob')
                    globSeach = 1;
                    myConfig.theBextPeaksNum = strrep(myConfig.theBextPeaksNum, 'glob', '');
                end
                if strfind(myHandler.config.theBextPeaksNum, 'prom')
                    promSeach = 1;
                    myConfig.theBextPeaksNum = strrep(myConfig.theBextPeaksNum, 'prom', '');
                end
            end
            if ~exist('theBextPeaksNum', 'var') 
                theBextPeaksNum = str2double(myConfig.theBextPeaksNum);
            end
            %[hei, peaksSort, ~, proms] = findpeaks(mySignal, 'SortStr', 'descend');
			[~, hei, peaksSort, widths, proms] = getTable(myHandler, 'orig descend');
            globs = hei.*proms;
            if globSeach
                [~, peaksLoc] = sort(globs, 'descend');
            end
            if promSeach
                [~, peaksLoc] = sort(proms, 'descend');
            end
            if globSeach || promSeach
                peaksSort = peaksSort(peaksLoc); widths = widths(peaksLoc);
                hei = hei(peaksLoc); proms = proms(peaksLoc);
            end
            myPositions = 1:theBextPeaksNum; %Positions of indexes.
            if numel(peaksSort) < theBextPeaksNum
                myPositions = 1:numel(peaksSort);
            end
            widths = widths(myPositions); proms = proms(myPositions);
            hei = hei(myPositions); myPositions = peaksSort(myPositions);
			[myHandler] = setTable(myHandler, hei, myPositions, widths, proms);
        end
        
        function [myHandler, mySignal] = detrendACF(myHandler, mySignal)
            if ~exist('mySignal', 'var')
                mySignal = myHandler.signal;
            end
            mySignal = detrend(mySignal, 'linear');
            coeffsMin = min(mySignal);
            if coeffsMin < 0
                mySignal = mySignal - coeffsMin;
            end
            if nnz(mySignal == 0)
                mySignal = mySignal + 1e-6;
            end
            myHandler.signal = mySignal;
        end
        
        function plotResult(myHandler)
            Root=fullfile(fileparts(mfilename('fullpath')),'..','..','..','..');
            visStr = 'on';
            fileName = '';
            if isfield(myHandler.config, 'plotting')
                if ~isempty(myHandler.config.plotting.Attributes.visible)
                    visStr = myHandler.config.plotting.Attributes.visible;
                end
                if ~isempty(myHandler.config.plotting.Attributes.fileName)
                    fileName = myHandler.config.plotting.Attributes.fileName;
                end
            end
            figure('units','points','Position',[0, 0, 800, 600], 'visible', visStr);
            plot(myHandler.signal);
            hold on
            plot(myHandler.resultSignal);
            legend('Original signal', 'Processed signal');
            if ~isempty(fileName)
                [~, ~, ext] = fileparts(fileName);
                formatStr = strrep(ext, '.', '');
                saveas(gcf, fullfile(Root, 'Out', fileName), formatStr);
            end
            
            if strcmpi(visStr, 'off')
                close
            end 
            
        end
		
	end


end