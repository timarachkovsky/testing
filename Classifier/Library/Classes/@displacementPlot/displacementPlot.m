classdef displacementPlot
    
    properties (SetAccess = protected, GetAccess = public)
        
        Fs
        t
        %Spectral frames of all shaft harmonics with a shaft number.
        spectralFrames
        %Shaft scheme names according 2 their numbers.
        shaftLabels
        %Shaft frequency relations render possible restore their freqs.
        shaftRelations
        %The main shaft's frequency
        baseFrequency
        %Displacement in the X and Y axis make together a complex vector.
        signalOrig
        %Allow to restore initial time and signal.
        signalIni
        %X = 1st channel = real part.
        signalFilted
        config
        %Windowed and filtered two-channel signals - indexes of a signal and time, label.
        traces
        %Structure contain getings out the threshold of a traectory.
        %Status field contain shaft numbers and scheme names and puts next in the common status.
        result
        %Logging
        compStageString
    end
    
    methods(Access = public)
        
        function myDisPlot = displacementPlot(File, config, myFrequencyCorrector)
            %==Set default parameters.==
            if ~exist('config', 'var')
               config = []; 
            end
            if ~exist('myFrequencyCorrector', 'var')
               myFrequencyCorrector = []; 
            end
            %Don't use window default.
            config = fill_struct(config, 'windows', '0');
            %Don't use by phase window default.
            config = fill_struct(config, 'windowLenMin', '0');
            %Phase derivative threshold.
            config = fill_struct(config, 'phaseDerivTresh', '10'); %Rad/sec. 20
            %Rectangular window default.
            config = fill_struct(config, 'windowType', 'Rect');
            %The def freq range.
            config = fill_struct(config, 'range', '4:250');
            %The def filtration method - FFT.
            config = fill_struct(config, 'filtMeth', 'fft');
            %The def time range.
            config = fill_struct(config, 'TimeRange', 'mid');
            %The def time length.
            config = fill_struct(config, 'TimeLength', 'full');
            %Saving mode.
            config = fill_struct(config, 'fullSavingEnable', '0');
            config = fill_struct(config, 'debugModeEnable', '0');
            config = fill_struct(config, 'printEnable', '0');
            config = fill_struct(config, 'plotVisible', 'off');
            if str2double(config.debugModeEnable)
                config = fill_struct(config, 'formats', 'jpg fig');
            else
                config = fill_struct(config, 'formats', config.plots.imageFormat);
            end
            myDisPlot.compStageString = 'Shaft trajectory detection';
            %myDisPlot.fVect = File.acceleration.frequencyVector;
            
            %==Filling a displacement signals.==
            complexSign = File.displacement.signal;
%             myDisPlot.signalX = File.acceleration.signal;
            myResult = [];
            myDisPlot.shaftRelations = 1;
            if ~isempty(myFrequencyCorrector)
                myResult = getResult(myFrequencyCorrector);
                if isempty(myResult)
                    myFrequencyCorrector = frequencyCorrection(myFrequencyCorrector);
                    myResult = getResult(myFrequencyCorrector);
                end
                %Set a shafts frequency relations.
                myProfileParser = getKinematicsParser(myFrequencyCorrector);
                estimFreqVect = getShaftVector(myProfileParser);
                myDisPlot.baseFrequency = estimFreqVect.freq(1); %Estimated or initial shaft frequency.
                estimFreqVect = estimFreqVect.freq/estimFreqVect.freq(1);
                myDisPlot.shaftRelations = estimFreqVect; %Save a shaft freqs relations.
            end
            if ~isfield(File, 'secondaryFile')
                if ~isfield(File.acceleration, 'secondarySignal')
                    printWarningLog(myDisPlot, 'There is no secondary channel!');
                    return;
                end
                FileY.Fs = File.Fs;
                FileY.acceleration.signal = File.acceleration.secondarySignal;
    %             %Getting displ from acc.
                [FileY] = acc2velocity(FileY, []);
                [FileY] = velocity2disp(FileY, []);
            else
                %If it was computed a secondary channel full.
                FileY = File.secondaryFile;
                if ~isempty(myFrequencyCorrector)
                    [ myFrequencyCorrector ] = setFile(myFrequencyCorrector, FileY);
                    myFrequencyCorrector = frequencyCorrection(myFrequencyCorrector);
                    myResultY = getResult(myFrequencyCorrector);
                end
            end
            %=====Recompute filtering ranges according 2 shaft spectral frames data.=====
            %Put in default data.
            rangeLimit = str2num(config.range);
            accShaftSchemeName = {'shaft'};
            accShaftNumber = 1;
            myDisPlot.spectralFrames = [{[rangeLimit(1) rangeLimit(end)]}; num2cell(accShaftNumber)]; % accShaftSchemeName;
            %Compute ranges.
            baseFreqIdx = [];
            if ~isempty(myResult)
                baseFreqIdx = myResult.displacement.validFreqIdx;
            end
            if ~isempty(baseFreqIdx)
                baseFreq = myResult.displacement.frequencies(baseFreqIdx);
                baseFreqIdxData = find(myResult.displacement.frequencies == baseFreq);
                %A numbers of spectral windows, from wich the current base frequency was gotten.
                accordingFrames = myResult.displacement.accordingFrames(baseFreqIdxData);
                if ~isempty(accordingFrames)
                    %Getting shaft data.
                    accShaftSchemeName = myResult.displacement.accShaftSchemeName(baseFreqIdxData);
                    accShaftNumber = myResult.displacement.accShaftNumber(baseFreqIdxData);
                    %Getting ranges from the central freqs.
                    baseFreq = myDisPlot.shaftRelations(accShaftNumber)*baseFreq; %Vector of base freqs of each frame accord to the sh. numb.
                    frequencies = baseFreq.*accordingFrames;
                    %Exclude repeations - similar frames gotten by different way.
                    [frequencies, IA] = unique(frequencies);
                    accShaftSchemeName = accShaftSchemeName(IA); accShaftNumber = accShaftNumber(IA);
                    ranges = arrayfun(@(x) [x*0.95 x*1.05], frequencies, 'UniformOutput', false);
                    disp('Ranges:');
                    disp(ranges);
                    %Sum a shaft frames samples outside the band.
                    lowerRange = cellfun(@(x) sum(x < rangeLimit(1)), ranges, 'UniformOutput', true);
                    higherRange = cellfun(@(x) sum(x > rangeLimit(end)), ranges, 'UniformOutput', true);
                    excludeFrames = lowerRange + higherRange;
                    ranges = ranges(~excludeFrames);
                    
                    accShaftSchemeName = accShaftSchemeName(~excludeFrames); accShaftNumber = accShaftNumber(~excludeFrames);
                    myDisPlot.spectralFrames = [ranges; num2cell(accShaftNumber)]; % accShaftSchemeName;
                    %Prepare for status.
                    [accShaftNumber, IA, ~] = unique(accShaftNumber); %Indexes of sorted unique numbers.
                    accShaftSchemeName = accShaftSchemeName(IA); %Put scheme names accord 2 numbers.
                    %Out ranges.
                    ranges = cellfun(@(x) num2str(x), ranges, 'UniformOutput', false);
                    ranges = strjoin(ranges, sprintf(';\t'));
                    disp(ranges);
%                     config.range = ranges;
                else %There is no any valid shaft frequency peak. Rest range original.
                    printWarningLog(myDisPlot, 'There is no any valid shaft frequency peak!');
                    accShaftSchemeName = {'shaft'};
                    accShaftNumber = 1;
                end
            else %Use default names. Rest range original.
                accShaftSchemeName = {'shaft'};
                accShaftNumber = 1;
            end
            myDisPlot.shaftLabels = accShaftSchemeName; %Remenber a scheme names according 2 numbers.
            myDisPlot.config = config;
            complexSign = complexSign + 1i*FileY.displacement.signal;
            myDisPlot.signalOrig = complexSign;
%             myDisPlot.signalY = FileY.acceleration.signal;
            myDisPlot.Fs = File.Fs;
            %Triming them.
            timeSamples = getTimeRange(myDisPlot, config.TimeRange);
            timeSamples(2) = getTimeRange(myDisPlot, config.TimeLength);
            timeSamples(2) = timeSamples(2) + timeSamples(1);
            if timeSamples(2) > length(myDisPlot.signalOrig)
                timeSamples(2) = length(myDisPlot.signalOrig);
            end
            timeSamples = timeSamples(1):timeSamples(2);
            myDisPlot.signalOrig = complexSign(timeSamples);
            myDisPlot.t = File.displacement.timeVector(timeSamples);
            exclElemsIdxs = setxor(1:numel(complexSign), timeSamples); %Elems, that are not included.
            myDisPlot.signalIni = [complexSign(exclElemsIdxs) File.displacement.timeVector(exclElemsIdxs)];
            %Filtering signal.
            if strcmp(myDisPlot.config.filtMeth, 'decim')
                myDisPlot.signalFilted = filtSign(myDisPlot, complexSign);
                myDisPlot.signalFilted(1, :) = cellfun(@(x) x(timeSamples), myDisPlot.signalFilted(1, :), 'UniformOutput', false);
            else
                myDisPlot.signalFilted = filtSign(myDisPlot, myDisPlot.signalOrig);
            end
            %===Fill in status structure.===
            %Get a shaft numbers and names.
            status.shaftNumber = accShaftNumber;
            status.shaftSchemeName = accShaftSchemeName;
            status.ellipticity = zeros(size(accShaftSchemeName));
            status.elliptAngle = zeros(size(accShaftSchemeName));
            status.elliptAngleDeg = zeros(size(accShaftSchemeName));
            myDisPlot.result.status = status;
        end
        
        function myDisPlot = compResult(myDisPlot)
            if isempty(myDisPlot.signalFilted)
                printWarningLog(myDisPlot, 'There is no any signal 2 process!');
                return;
            end
%             myDisPlot.traces = [myDisPlot.traces; cell(1, size(myDisPlot.traces, 2))];
            for i = 1:size(myDisPlot.signalFilted, 2)
                myDisPlot = compResult4shaft(myDisPlot, i);
            end
            disp('Result is ready. Status:'); disp(myDisPlot.result.status);
            try
                checkResult(myDisPlot);
            catch
                printStage(myDisPlot, 'Self test error.');
            end
        end
        
        function myDisPlot = compResult4shaft(myDisPlot, number)
            origTrace = [{[1 numel(myDisPlot.t)]}; {'Orig'}; {number}; {[]}];
            %Add windows and originals.
            myDisPlot.traces = [myDisPlot.traces origTrace];
            %==Getting windows.==
            %By phase
            windowLenMin = myDisPlot.config.windowLenMin;
            windowLenMin = getTimeRange(myDisPlot, windowLenMin);
            phaseDerivTresh = str2num(myDisPlot.config.phaseDerivTresh);
            if windowLenMin
                myFullPhase{1} = getFullPhase(myDisPlot, ['X:' num2str(number)]);
                myFullPhase{2} = getFullPhase(myDisPlot, ['Y:' num2str(number)]);
                myFullPhase{3} = getFullPhase(myDisPlot, ['filted:' num2str(number)]);
                %Find parts of signal, where phase derivative less then threshold.
                dt = myDisPlot.t(2) - myDisPlot.t(1);
                for i = 1:numel(myFullPhase)
                    phaseDrv = diff(myFullPhase{i})/dt;
                    overThreshold = abs(phaseDrv) > phaseDerivTresh;
                    phaseFrames{i} = takeOneByOneBands(double(overThreshold), struct( 'succession', 'zero', 'minInSuccession', num2str(windowLenMin) ));
                end
                k = 0;
                range = cell(0, 0); rangeLbls = cell(0, 0);
                %Find the common phase-stable parts of X and Y signals by searching in both channel ranges.
                for i = 1:numel(phaseFrames{1})
                   for j = 1:numel(phaseFrames{2})
                       %The i-st range (the second bracket {i})  of the X (the first bracket {1}) channel.
                       range1 = phaseFrames{1}{i}(1):phaseFrames{1}{i}(2);
                       %The j-st range (the second bracket {j})  of the Y (the first bracket {2}) channel.
                       range2 = phaseFrames{2}{j}(1):phaseFrames{2}{j}(2);
                       currRange = intersect(range1, range2);
                       if numel(currRange) > windowLenMin
                           k = k + 1;
                           range(k) = {[currRange(1) currRange(end)]};
                           rangeLbls(k) = {'by phase'};
                       end
                   end
                end
               for j = 1:numel(phaseFrames{3})
                   %The j-st range (the second bracket {j})  of the complex XY channel (the first bracket {3}) channel.
                   currRange = phaseFrames{3}{j}(1):phaseFrames{3}{j}(2);
                   if numel(currRange) > windowLenMin
                       k = k + 1;
                       range(k) = {[currRange(1) currRange(end)]};
                       rangeLbls(k) = {'by phaseXY'};
                   end
               end
                if isempty(range)
                    printWarningLog(myDisPlot, 'There is no stable parts on the signal!');
                else
                    for i = 1:numel(range)
                        currTrace = [range(i); rangeLbls(i); {number}; {[]}];
                        myDisPlot.traces = [myDisPlot.traces currTrace];
                    end
                end
            end
            %Assigned by time
            windows = getTimeRange(myDisPlot, myDisPlot.config.windows);
            if windows
                if numel(windows) == 1
                    %Window length was assigned.
                    winNum = floor(numel(myDisPlot.t)/windows)*windows;
                    len = windows;
                    windows = zeros(len, 2);
                    for i = 0:winNum-1
                        windows(i, :) = [i*winNum+1 (i+1)*winNum];
                    end
                end
                for i = 1:size(windows, 1)
                    currTrace = [{[windows(i, 1) windows(i, end)]}; {'by time'}; {number}; {[]}];
                    myDisPlot.traces = [myDisPlot.traces currTrace];
                end
            end
            
            shaftNums = myDisPlot.traces(3, :); shaftNums = cellfun(@(x) x, shaftNums);
            tracesIdxs = find(shaftNums == number);
            
            %=====Averaging windows.=====
            %Divide each trace by periods of according shaft and average.
            for i = tracesIdxs %The current shaft's traces.
                currTr = myDisPlot.traces{1, i};
                shaftFreq = myDisPlot.baseFrequency*myDisPlot.shaftRelations(number);
                if isempty(shaftFreq) %Use the lower band border in case unsuccessfull shaft frequency estimation.
                   shaftFreq = myDisPlot.spectralFrames{1, 1}(1); 
                end
                %Get necessary samples number - length of averaging window = 1 shaft frequency period.
                sampLength = round(myDisPlot.getTimeRange([num2str(1/shaftFreq) 'sec']));
                %Windows number.
                winNum = floor((currTr(end) - currTr(1))/sampLength);
                %Average the whole periods of the current trace.
                aveTr = getWindow(myDisPlot, i, 'filted'); % ['trace:' num2str(number)]
                if winNum
                    aveTr = aveTr(1:winNum*sampLength); %Cut off by the whole periods number.
                    aveTr = reshape(aveTr, sampLength, winNum);
                    aveTr = mean(aveTr, 2);
                end
                myDisPlot.traces{4, i} = aveTr;
            end
            
            %====Computing result.====
            %Finding ellipticity of shaft displacement.
            %Max XY vector length to min length is ellipticity.
            myTrace = myDisPlot.traces{4, tracesIdxs(1)}; %Averaged full trace.
            [maxAmpl, maxIdx] = max(abs(myTrace)); minAmpl = min(abs(myTrace));
            ellipticity = minAmpl/maxAmpl;
            myDisPlot.result.status.ellipticity(number) = 1 - ellipticity;
            %Angle, where displacement is the most.
            ellAng = angle(myTrace);
            myDisPlot.result.status.elliptAngle(number) = ellAng(maxIdx);
            myDisPlot.result.status.elliptAngleDeg(number) = ellAng(maxIdx)/(2*pi)*360;
        end
        
        function status = checkResult(myDisPlot)
            myResult = myDisPlot.result.status;
            %Check fields number, numeric fields, row fields.
            numericF = {'ellipticity', 'elliptAngle', 'elliptAngleDeg', 'shaftNumber'};
            nameF = {'shaftSchemeName'}; allF = [numericF nameF];
            correctFlag = resTest(myResult, struct('fieldsNumber', 5, 'numericFields', {numericF}, ...
                'rowFields', {allF}, 'compStageString', 'Shaft trajectory detection processing'), true);
            %Check result elements number equal 2 shaft labels number.
            numbers = cellfun(@(x) numel(myResult.(x)), allF);
            sumnum = numbers - numel(myDisPlot.shaftLabels);
            correctNum = ~logical(sum(sumnum));
            %Result...
            status = correctFlag&correctNum;
            if status
                printStage(myDisPlot, 'Result of shaft trajectory detection has a correct format.');
            else
                printStage(myDisPlot, 'Result of shaft trajectory detection has a wrong format.');
            end
        end
        
        function printStage(myDisPlot, myMessage)
            try
                iLoger = loger.getInstance;
            catch
                iLoger = [];
            end
            if ~isempty(iLoger) && isvalid(iLoger)
                printComputeInfo(iLoger, myDisPlot.compStageString, myMessage);
            else
                fprintf('%s\n%s\n', myDisPlot.compStageString, myMessage);
            end
        end
        
        function printWarningLog(myDisPlot, myMessage)
            try
                iLoger = loger.getInstance;
            catch
                iLoger = [];
            end
            if ~isempty(iLoger) && isvalid(iLoger)
                printWarning(iLoger, myMessage);
            else
                warning(myMessage);
            end
        end
        
        
        function plotTrace(myDisPlot)
            if isempty(myDisPlot.signalFilted)
                printWarningLog(myDisPlot, 'There is no secondary channel!')
                return;
            end
            visStr = myDisPlot.config.plotVisible;
            printPlotsEnable = myDisPlot.config.printPlotsEnable;
            sizeUnits = myDisPlot.config.plots.sizeUnits;
            imageSize = str2num(myDisPlot.config.plots.imageSize);
            if strcmp([visStr printPlotsEnable], 'off0')
                return; %Don't plot if it's unnecessary 2 image or 2 print.
            end
            fullSavingEnable = str2double(myDisPlot.config.fullSavingEnable);
            for i = 1:size(myDisPlot.signalFilted, 2)
                plotTrace4shaft(myDisPlot, i);
            end
            
            if fullSavingEnable
                %Plot spectrum of the both channels.
                df = myDisPlot.Fs/length(myDisPlot.signalOrig);
                fVect = 0:df:myDisPlot.Fs-df;
                chX = real(myDisPlot.signalOrig); chY = imag(myDisPlot.signalOrig);
                %Get one side spectrums and frequency vector.
                fSpX = fft(chX)/length(chX); fSpY = fft(chY)/length(chY);
                halfIdx = floor(numel(chX)/2); fVect = fVect(1:halfIdx);
                fSpX = fSpX(1:halfIdx); fSpY = fSpY(1:halfIdx);

                figure('units', sizeUnits,'Position', imageSize, 'visible', visStr);
                subplot(2, 1, 1); plot(fVect, abs(fSpX)); axis([0 200 0 max(abs(fSpX))]);
                subplot(2, 1, 2); plot(fVect, abs(fSpY)); axis([0 200 0 max(abs(fSpY))]);
                plotName = 'disPlot channels spectrums'; subplot(2, 1, 1);
                title(plotName); savePic(myDisPlot, plotName);
                % Close figure with visibility off
                if strcmpi(visStr, 'off')
                    close
                end
            end
        end
        
        function plotTrace4shaft(myDisPlot, number)
            visStr = myDisPlot.config.plotVisible;
            sizeUnits = myDisPlot.config.plots.sizeUnits;
            imageSize = str2num(myDisPlot.config.plots.imageSize);
            fullSavingEnable = str2double(myDisPlot.config.fullSavingEnable);
            %Draw all traces.
            shaftNums = myDisPlot.traces(3, :); shaftNums = cellfun(@(x) x, shaftNums);
            tracesIdxs = find(shaftNums == number);
            shaftName = ['shaft number ' num2str(number) ' ' myDisPlot.shaftLabels{number}];
            for i = tracesIdxs
                figure('units', sizeUnits,'Position', imageSize, 'visible', visStr);
                plot(getWindow(myDisPlot, i, 'filted')); axis('equal'); myT = getWindow(myDisPlot, i, 't');
                hold on; plot( myDisPlot.traces{4, i}, 'r');
%                 plotName = ['disPlot - ' myDisPlot.traces{2, i} ' ' shaftName];
                plotName = [myDisPlot.traces{2, i} ' ' shaftName];
                plotName = sprintf('%s - %2.3f - %2.3f sec', plotName, myT(1), myT(end));
                myFig = gcf; myAxes = myFig.CurrentAxes; % Get axes data
                % Figure title
                plotName = [upperCase(myDisPlot.config.Translations.shaftTrajectoryDetection.Attributes.name, 'first'), ' - ', plotName];
                % Figure labels
                xlabel(myAxes, [upperCase(myDisPlot.config.Translations.displacement.Attributes.name, 'first'), ', ', ...
                    upperCase(myDisPlot.config.Translations.displacement.Attributes.value, 'first')]);
                ylabel(myAxes, [upperCase(myDisPlot.config.Translations.displacement.Attributes.name, 'first'), ', ', ...
                    myDisPlot.config.Translations.displacement.Attributes.value]);
                title(plotName); savePic(myDisPlot, plotName);
                % Close figure with visibility off
                if strcmpi(visStr, 'off')
                    close(myFig)
                end
            end
            if fullSavingEnable
                %Draw abs and angle of displacement.
                [myFullPhase, drv] = getFullPhase(myDisPlot, ['filted:' num2str(number)]);
                figure('units', sizeUnits,'Position', imageSize, 'visible', visStr);
                subplot(3, 1, 1); plot(myDisPlot.t, abs(myDisPlot.signalFilted{1, number}));
                subplot(3, 1, 2); plot(myDisPlot.t, myFullPhase);
                subplot(3, 1, 3); plot(myDisPlot.t, abs(drv));
                plotName = ['disPlot ' shaftName ' abs-phi']; subplot(3, 1, 1);
                title(plotName); savePic(myDisPlot, plotName);
                % Close figure with visibility off
                if strcmpi(visStr, 'off')
                    close
                end

                %Plot a filtered signals and their full phases.
                figure('units', sizeUnits,'Position', imageSize, 'visible', visStr);
                subplot(3, 1, 1); plot(myDisPlot.t, getWindow(myDisPlot, 1, ['X:' num2str(number)]))
                [myFullPhase, drv] = getFullPhase(myDisPlot, ['X:' num2str(number)]);
                subplot(3, 1, 2); plot(myDisPlot.t, myFullPhase)
                subplot(3, 1, 3); plot(myDisPlot.t, abs(drv));
                plotName = ['channelX ' shaftName]; subplot(3, 1, 1);
                title(plotName); savePic(myDisPlot, plotName);
                % Close figure with visibility off
                if strcmpi(visStr, 'off')
                    close
                end
                figure('units', sizeUnits,'Position', imageSize, 'visible', visStr);
                subplot(3, 1, 1); plot(myDisPlot.t, getWindow(myDisPlot, 1, ['Y:' num2str(number)]))
                [myFullPhase, drv] = getFullPhase(myDisPlot, ['Y:' num2str(number)]);
                subplot(3, 1, 2); plot(myDisPlot.t, myFullPhase)
                subplot(3, 1, 3); plot(myDisPlot.t, abs(drv));
                plotName = ['channelY ' shaftName]; subplot(3, 1, 1);
                title(plotName); savePic(myDisPlot, plotName);
                % Close figure with visibility off
                if strcmpi(visStr, 'off')
                    close
                end
            end
        end
        
        function [myFullPhase, phaseDeriv] = getFullPhase(myDisPlot, mySignal)
            if ~exist('mySignal', 'var')
               mySignal = 'filted'; 
            end
            if ischar(mySignal) %Full default - the first shaft's trace.
               mySignal = getWindow(myDisPlot, 1, mySignal);
            end
            if isreal(mySignal) %Phase of a real signal or angle of complex.
                analytSign = hilbert(mySignal);
            else
                analytSign = mySignal;
            end
            myFullPhase = angle(analytSign);
            myFullPhase = unwrap(myFullPhase);
            myFullPhase = detrend(myFullPhase);         
            if nargout == 2
                dt = myDisPlot.t(2) - myDisPlot.t(1);
                phaseDeriv = [0; diff(myFullPhase)/dt];
            end
        end
        
        %Function return a signal time window. Signal assigned by value2get,
        %window - by myRange. Window mb numeric range or a trace number, 
        %signal - X, Y displacement, filtered common signal, time samples, original,
        %shaft number gets from trace or from value2get through colon, examp. X:1 - 1st shaft, X axis.
        function myWind = getWindow(myDisPlot, myRange, value2get)
            %Signle number in range assigns a trace number. Shaft number gets from trace.
            %If both assigned - use trace number among the current shaft's traces.
            if ~exist('value2get', 'var')
               value2get = 'filted'; 
            end
            if numel(myRange) == 1 %A trace number assigned.
                %Get shaft number, if it's assigned 4 filtered signals.
                divStr = strsplit(value2get, ':');
                if numel(divStr) > 1
                    %Trace num among the current shaft's.
                    shNum = str2double(divStr{2});
                    shaftNums = myDisPlot.traces(3, :); shaftNums = cellfun(@(x) x, shaftNums);
                    tracesIdxs = find(shaftNums == shNum); %Indexes of the curr shaft traces.
                    myRange = tracesIdxs(myRange); %Trace among the current shaft's.
                else
                    shNum = myDisPlot.traces{3, myRange};
                end
                myRange = myDisPlot.traces{1, myRange};
                myRange = myRange(1):myRange(end);
            else
                %Get shaft number, if it's assigned 4 filtered signals.
                divStr = strsplit(value2get, ':');
                if numel(divStr) == 1
                    %Sh. num wasn't assigned - get the first.
                    shNum = 1;
                else
                    shNum = str2double(divStr{2});
                end
            end
            value2get = divStr{:};
            switch value2get
                case 't'
                    myWind = myDisPlot.t(myRange);
                case 'filted'
                    %Get the shaft's signal by sh. number.
                    myWind = myDisPlot.signalFilted{1, shNum}(myRange);
                case 'X'
                    myWind = real(myDisPlot.signalFilted{1, shNum}(myRange));
                case 'Y'
                    myWind = imag(myDisPlot.signalFilted{1, shNum}(myRange));
                case 'trace'
                    %Filted signal + time vector.
                    myWind = myDisPlot.signalFilted{1, shNum}(myRange);
                    myWind = [myWind; myDisPlot.t(myRange)];
                otherwise
                    myWind = myDisPlot.signalOrig(myRange);
            end
        end
        
    end
    
    methods(Access = protected)
        %Function filtrates a several shafts using many ranges, assigned by different way, including complex XY signals.
        function myFiltedSign = filtSign(myDisPlot, mySign, filtRange)
            if ~exist('filtRange', 'var')
                filtRange = myDisPlot.spectralFrames;
            end
            shaftNumVect = {};
            if ischar(filtRange)
                ranges = strsplit(filtRange, ';');
            elseif iscell(filtRange)
                ranges = filtRange(1, :); %Take a ranges - first row.
                if size(filtRange, 1) == 2 %The second is a shaft numbers.
                    shaftNumVect = filtRange(2, :);
                end
            elseif isnumeric(filtRange) %Put in cells 4 the next multirange processing.
                ranges = arrayfun(@(x) filtRange(x, :), 1:size(filtRange, 1), 'UniformOutput', false);
            end
            if numel(shaftNumVect)
                %Divide ranges by shaft number.
                shaftNumVect = cellfun(@(x) x, shaftNumVect);
                numVect = unique(shaftNumVect);
                for i = 1:numel(numVect)
                   currElmIdxs = shaftNumVect == numVect(i);
                   %Get the current shaft's ranges.
                   shaftRanges{i} = ranges(currElmIdxs);
                end
                %Filt each shaft's spectrum frames. Range argument is a cell array, wich will be process in the next block.
                myFiltedSignCells = cellfun(@(x) filtSign(myDisPlot, mySign, x), shaftRanges, 'UniformOutput', false);
                %Result is filtered signals with each shaft's spectral frames.
                myFiltedSign = [myFiltedSignCells; num2cell(numVect)];
                return;
            end
            %Range assignes as a several spectral frames - in argument, from myDisPlot range or splited string.
            if numel(ranges) > 1
                myFiltedSignCells = cellfun(@(x) filtSign(myDisPlot, mySign, x), ranges, 'UniformOutput', false);
                myFiltedSign = zeros(size(myFiltedSignCells{1}));
                for i = 1:numel(myFiltedSignCells)
                    myFiltedSign = myFiltedSign + myFiltedSignCells{i};
                end
                return;
            else
                %One numeric range.
                filtRange = ranges{:};
            end
            if ~isreal(mySign)
                myFiltedSign = filtSign(myDisPlot, real(mySign), filtRange) + 1j*filtSign(myDisPlot, imag(mySign), filtRange);
                return;
            end
            if ischar(filtRange)
                filtRange = str2num(filtRange);
            end
            %===Filtrate by assigned method.===
            switch myDisPlot.config.filtMeth
                case 'fft'
                    myFiltedSign = filtByFFT(myDisPlot, mySign, filtRange);
                case 'decim'
                    myFiltedSign = filtByDecimFilt(myDisPlot, mySign, filtRange);
                otherwise
                    error('Wrong filtration method assigned!');
            end
        end
        
        function myFiltedSign = filtByFFT(myDisPlot, mySign, filtRange)
            oddSamp = [];
            if mod(length(mySign), 2) %Gag: make an even samples number.
                oddSamp = numel(mySign) - 1;
                mySign = mySign(1:end-1);
            end
            df = myDisPlot.Fs/length(mySign);
            fVect = 0:df:myDisPlot.Fs-df;
            [mv, filtRange(1)] = min(abs( fVect - filtRange(1) ));
            [mv, filtRange(end)] = min(abs( fVect - filtRange(end) ));
            filtRange = filtRange(1):filtRange(end);
            if filtRange(1) == 0
               filtRange = filtRange + 1; 
            end
            
            fSp = fft(mySign)/length(mySign);
            
            lowSamp = filtRange(1)-1;
            midSamp = numel(fSp)/2+1;
            fSp(1:lowSamp) = zeros(size( fSp(1:lowSamp) ));
            fSp(filtRange(end):midSamp) = zeros(size( fSp(filtRange(end):midSamp) ));
            fSp(midSamp:end) = conj(flipud(fSp(2:midSamp)));
            
            myFiltedSign = (ifft(fSp))*length(fSp);
            myFiltedSign = [myFiltedSign; myFiltedSign(oddSamp)]; %2 make a sample number equal.
        end
        
        function myFiltedSign = filtByDecimFilt(myDisPlot, mySign, filtRange)
            %=====Decimate signal 2 lower sample rate 2 expand frequency vector.=====
            idxs = round(linspace(0, numel(mySign), numel(mySign)/200+1));
            idxs = idxs(2:end); sign2filt = mySign(idxs);
            %-=Close freqs far now. Calculate range and passband freqs.=-
            filtRangeExp = filtRange*200; %Expanded by decimation range.
            fMid = (filtRangeExp(1) + filtRangeExp(end))/2;
            %Minimum range.
            passB(1) = fMid - myDisPlot.Fs/1000;
            passB(2) = fMid + myDisPlot.Fs/1000;
            %Assigned expanded range, that should be outside minimum range.
            [passB(1), mInd(1)] = min([filtRangeExp(1), passB(1)]);
            [passB(2), mInd(2)] = max([filtRangeExp(end), passB(2)]);
            passB(2) = min([passB(2), (myDisPlot.Fs/2-1)/1.2]);
            %Check if assigned range was inside minimum, warn about too narrow range if it is.
            if sum(mInd) > 3
               printWarningLog(myDisPlot, 'There is too narrow range assigned to stable filtration.');
            end
            stopB(1) = passB(1)*0.98; stopB(2) = passB(2)*1.02; %Stopband freqs.
            
            %=====Filter a signal in estimated range.=====
            bpf = designfilt('bandpassiir', 'StopbandFrequency1', stopB(1), 'PassbandFrequency1', passB(1), 'PassbandFrequency2', passB(2), 'StopbandFrequency2', stopB(2), 'StopbandAttenuation1', 20, 'PassbandRipple', 1, 'StopbandAttenuation2', 20, 'SampleRate', myDisPlot.Fs);
            cleanS = filtfilt(bpf, sign2filt);

            %=====Restore orig Fs and freq vector.=====
            span = 200; interpStep = 1/span;
            averSam = 1:floor(span/2);
            firstSam = mean(cleanS(averSam));
            lastSam = mean(cleanS(end-averSam+1));
            originalSamples = [0.5+interpStep, 1:length(sign2filt), length(sign2filt)+0.5];
            interpolateSampels = 0.5+interpStep:interpStep:length(sign2filt)+0.5;
            cleanS = [firstSam reshape(cleanS, 1, []) lastSam];
            myFiltedSign = interp1(originalSamples, cleanS, interpolateSampels, 'pchip');
            if numel(myDisPlot.t) - numel(myFiltedSign) == 1
                myFiltedSign = [myFiltedSign myFiltedSign(end)]; %Make numel equal.
            end
            myFiltedSign = reshape(myFiltedSign, [], 1);
        end
        
        function timeSamples = getTimeRange(myDisPlot, myRange, mySign)
            %Range mb assigned relative to signal samples number.
            if ~exist('mySign', 'var')
               mySign = myDisPlot.signalOrig;
            end
            if strcmp(myRange, 'mid')
                timeSamples = floor(numel(mySign)/2);
                return;
            end
            if strcmp(myRange, 'full')
                timeSamples = numel(mySign);
                return;
            end
            if strfind(myRange, 'sec')
                myRange = strrep(myRange, 'sec', '');
                myRange = str2num(myRange);
                dt = 1/myDisPlot.Fs;
                timeSamples = myRange/dt; %Translate 2 samples.
                if timeSamples > length(mySign)
                    printWarningLog(myDisPlot, 'Range exceeds a signal length.');
                   timeSamples = length(mySign) ;
                end
                return;
            end
            if strfind(myRange, 'maxPer')
                myRange = strrep(myRange, 'maxPer', '');
                myRange = str2num(myRange);
                minFr = str2num(myDisPlot.config.range);
                maxPer = 1/minFr(1, 1);
                myRange = myRange*maxPer; %Translate 2 seconds.
                myRange = [num2str(myRange) 'sec'];
                timeSamples = getTimeRange(myDisPlot, myRange, mySign);
                return;
            end
            %Else - assigned in samples.
            timeSamples = str2num(myRange);
            if timeSamples > length(mySign)
                printWarningLog(myDisPlot, 'Range exceeds a signal length.');
               timeSamples = length(mySign) ;
            end
        end
        
        function savePic(myDisPlot, picName)
            myFigure = gcf;
            fontSize = str2double(myDisPlot.config.plots.fontSize);
            imageFormat = myDisPlot.config.plots.imageFormat;
            imageQuality = myDisPlot.config.plots.imageQuality;
            imageResolution = myDisPlot.config.plots.imageResolution;
            myAxes = myFigure.CurrentAxes; % Get axes data
            myAxes.FontSize = fontSize; % Set axes font size
            if ~str2double(myDisPlot.config.printEnable)
               return; 
            end
            myForms = myDisPlot.config.formats;
            myForms = strsplit(myForms);
            for i = 1:numel(myForms)
                plotName = [picName '.' myForms{i}]; pcName = [picName '.jpg'];
                if strcmp(myForms{i}, myDisPlot.config.plots.imageFormat) %Process such way not debugging images.
                    print( myFigure, fullfile(pwd, 'Out', pcName), ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
                else
                    saveas( myFigure, fullfile(pwd, 'Out', plotName), myForms{i} );
                end
            end
        end
        
        %Return initial time vector and signal - without processing limits.
        function [sign, tVect] = restorIni(myDisPlot)
            iniParams = myDisPlot.signalIni;
            [tVect, idxs] = sort(real([myDisPlot.t, iniParams(2, :)])); %Restore time sampling - one-by-one samples.
            sign = [myDisPlot.signalOrig iniParams(1, :)]; %Signal samples.
            sign = sign(idxs); %Restore the order.
        end
        
    end
    
end