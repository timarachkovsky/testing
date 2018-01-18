classdef spectralKurtosisFilter
    
    properties (SetAccess = protected, GetAccess = public)
        config
        signal
        signalOrig
        File
        Fs
        Window
        AFR
        fullResult
        octaveResult
    end
    
    methods (Access = public)
        
        function mySpKurtFilt = spectralKurtosisFilter(mySignal, myConfig)
            %==Set default parameters.==
            if nargin < 2
                myConfig = [];
            end
            mySpKurtFilt.signalOrig = mySignal;
            myConfig = fill_struct(myConfig, 'signalKind', '');
            if isstruct(mySignal)
                mySignal = fill_struct(mySignal, 'fullScalogramData', []);
                mySpKurtFilt.File = mySignal;
                %Choose from acceleration, velocity, displacement signals.
                signalKind = strsplit(myConfig.signalKind);
                if isempty(signalKind{1}), signalKind{1} = 'acceleration'; end
                mySpKurtFilt.signalOrig = mySignal.(signalKind{1}).signal;
                mySpKurtFilt.Fs = mySignal.Fs;
            else
                myConfig = fill_struct(myConfig, 'Fs', '96000');
                mySpKurtFilt.Fs = str2double(myConfig.Fs);
            end
            myConfig = fill_struct(myConfig, 'shortSignalEnable', '0');
            % Cut-off the original signal to speed-up scalogram calculation and evaluation
            if str2double(myConfig.shortSignalEnable)
                parameters = myConfig.shortSignal.Attributes;
                parameters.mono = myConfig.shortSignal.mono.Attributes;
                parameters.multi = myConfig.shortSignal.multi.Attributes;
                mySpKurtFilt.signalOrig = createShortSignal(struct('signal', mySpKurtFilt.signalOrig, 'Fs', mySpKurtFilt.Fs), parameters);
            end
            mySpKurtFilt.fullResult = mySpKurtFilt.emptyResult;
            %There are several parameters that define slide window parameters:
            %window length, number of windows, FFT points number < window length, overlapping.
            %Number of windows with signal length and overlapping has more priority,
            %assign window length default. Window default is a window length.
            %If other window function specified (vector window property), use it.
            myConfig = fill_struct(myConfig, 'winLength', '256'); %'5signPerc' = 5% of signal length.
            %myConfig = fill_struct(myConfig, 'winNumber', '256'); %Use winLen default - winNumber has more priority.
            myConfig = fill_struct(myConfig, 'Noverlap', '75windPerc'); %Percent of window length.
            myConfig = fill_struct(myConfig, 'minSensorFreq', '4'); %Min freq in signal.
            myConfig = fill_struct(myConfig, 'maxSensorFreq', '20000'); %Min freq in signal.
            %Default window parameters.
            myConfig = fill_struct(myConfig, 'windKind', 'hanning'); %Define windowing function.
            myConfig = fill_struct(myConfig, 'winopt', ''); %Optional argument for the most of windows, see 'help window'.
            %Signal valuable frequency ranges detachment threshold 4 spectralKurtosis function.
            myConfig = fill_struct(myConfig, 'filtThreshold', '4.5');
            %Reserve filtration range expanding.
            myConfig = fill_struct(myConfig, 'filtrationRangeReservePercent', '5');
            %Kurtosis bias removing.
            myConfig = fill_struct(myConfig, 'kurtBiasRemove', '0');
            %Octave calculating defaults.
            myConfig = fill_struct(myConfig, 'lowFrequency', num2str(myConfig.minSensorFreq)); % low frequency range margin
            myConfig = fill_struct(myConfig, 'highFrequency', num2str(myConfig.maxSensorFreq)); % high frequency range margin
            %Filter in each window band ('narrBand') or the whole band, where SK more than threshold ('commBand').
            myConfig = fill_struct(myConfig, 'filterMode', 'commBand');
            %Turn on spectral windows division by global SK minimums.
            myConfig = fill_struct(myConfig, 'windMinDiv', '1');
            %myConfig = fill_struct(myConfig, 'roundingEnable', '1'); % Enable rounding to the nearest 2^i value
            %Define calculation approach: octave filtrating and calculating octave kurtosis or window kurtosis.
            myConfig = fill_struct(myConfig, 'calculating', 'octave specWind'); %'octave' or 'specWind'
            %Define approach 4 band filtering.
            myConfig = fill_struct(myConfig, 'bandFilteringMethod', 'fft'); %'fft' or 'decimFilt' or 'AFR'
            %Min SK value necessary for saving filtered signal.
            myConfig = fill_struct(myConfig, 'saveSignalThreshold', '4.5');
            %Plots def settings.
            myConfig = fill_struct(myConfig, 'fullSavingEnable', '0');
            myConfig = fill_struct(myConfig, 'debugModeEnable', '0');
            myConfig = fill_struct(myConfig, 'plotVisible', 'on');
            if str2double(myConfig.plotEnable)
                myConfig.printPlotsEnable = myConfig.plots.printPlotsEnable;
                myConfig.plotVisible = myConfig.plots.plotVisible;
            else
                myConfig.printPlotsEnable = '0';
                myConfig.plotVisible = 'off';
            end
            %==Set necessary properties.==
            %Set window from config parameters as a single number that assigns window length in samples.
            winLen = str2double(myConfig.winLength);
            if isfield(myConfig, 'winNumber')
                if ~isempty(myConfig.winNumber)
                    winLen = floor( length(mySignal)/str2double(myConfig.winNumber) );
                end
            end
            myWindow = getSamplesNum(mySpKurtFilt, num2str(winLen));
            %FFT samples number is equal to window length default. Nfft >= winLen.
            myConfig = fill_struct(myConfig, 'FFTlength', num2str(2*myWindow)); %TEST
            mySpKurtFilt.config = myConfig;
            %Compute window of assigned type.
            mySpKurtFilt = setWindow(mySpKurtFilt, myWindow);
        end
        
        function mySpKurtFilt = setWindow(mySpKurtFilt, myWindow)
            if length(myWindow) == 1
                if ~isempty(mySpKurtFilt.config.winopt)
                    myWindow = window(mySpKurtFilt.config.windKind, myWindow, mySpKurtFilt.config.winopt);
                else
                    myWindow = window(mySpKurtFilt.config.windKind, myWindow);
                end
            end
            mySpKurtFilt.Window = myWindow;
        end
        
        function mySpKurtFilt = setConfig(mySpKurtFilt, myConfig)
            mySpKurtFilt.config = myConfig;
        end
        
        function mySpKurtFilt = setSignal(mySpKurtFilt, mySignal)
            mySpKurtFilt.signalOrig = mySignal;
        end
        
        function myResult = getResult(mySpKurtFilt)
            fN = {'kurtosis', 'frequencies', 'filtedSignals', 'range', 'label'};
            idxs = mySpKurtFilt.fullResult.indexes; myResult = [];
            for i = 1:numel(fN)
                myResult = setfield( myResult, fN{i}, mySpKurtFilt.fullResult.(fN{i})(idxs) );
            end
        end
        
        
        function mySpKurtFilt = filtSignal(mySpKurtFilt)
            if ~isempty(mySpKurtFilt.config.signalKind)
                signalKind = strsplit(mySpKurtFilt.config.signalKind);
                myConfig = mySpKurtFilt.config;
                if numel(signalKind) > 1
                    for i = 1:numel(signalKind)
                        mySpKurtFilt.config.signalKind = signalKind{i};
                        mySpKurtFilt = filtSignal(mySpKurtFilt);
                    end
                    mySpKurtFilt.config = myConfig;
                    return;
                end
            end
            %Each method add it's data to the common result that validates later.
            if strfind(mySpKurtFilt.config.calculating, 'specWind')
                mySpKurtFilt = spectralKurtosis(mySpKurtFilt);
                mySpKurtFilt = AFRfiltration(mySpKurtFilt); %Wiener filtration.
                mySpKurtFilt = filtSpecKurt(mySpKurtFilt);
            end
            if strfind(mySpKurtFilt.config.calculating, 'octave')
                mySpKurtFilt = octaveKurtosis(mySpKurtFilt);
            end
            mySpKurtFilt = validateResults(mySpKurtFilt);
            if strcmp(mySpKurtFilt.config.plotVisible, 'on') || str2double(mySpKurtFilt.config.plotEnable)
                plotSpectrumKurtosis(mySpKurtFilt);
            end
        end
        
        function mySpKurtFilt = octaveKurtosis(mySpKurtFilt)
            Config = mySpKurtFilt.config;
            signalLength = length(mySpKurtFilt.signalOrig);
            df = mySpKurtFilt.Fs/signalLength;

            % Form frequencies array with several points per octave and recalculate it
            % to the position format.
            [frequencies, ranges] = createScales(mySpKurtFilt);
            lowPosition = reshape(ranges(:, 1), 1, []);
            highPosition = reshape(ranges(:, end), 1, []);
            centralFrequencies = frequencies(1,1:end-1) + diff(frequencies)/2;

            kurtFramesNumber = length(highPosition);

            % Calculate the kurtosis of each spectrum octave band.
            myOctaveKurt = zeros(1,kurtFramesNumber);
            kurtosVect = ones(size(mySpKurtFilt.signalOrig));
            myFiltedSign = cell(size(myOctaveKurt));
            range = cell(size(myOctaveKurt));
            for i = 1:1:kurtFramesNumber
                [~, myFiltedSign{i}] = filtrationProcessing(mySpKurtFilt, [lowPosition(1,i) highPosition(1,i)]);
                myOctaveKurt(:,i) = kurtosis(myFiltedSign{i}, ~str2double(Config.kurtBiasRemove));
                kurtosVect( lowPosition(1,i)+1:highPosition(1,i) ) = ones(size( lowPosition(1,i)+1:highPosition(1,i) ))*myOctaveKurt(:,i);
                range{i} = [lowPosition(1,i)+1 highPosition(1,i)];
            end

            mySpKurtFilt.octaveResult.kurtosis = myOctaveKurt;
            mySpKurtFilt.octaveResult.kurtosVect = kurtosVect;
            mySpKurtFilt.octaveResult.frequencies = centralFrequencies;
            mySpKurtFilt.octaveResult.filtedSignals = myFiltedSign;
            mySpKurtFilt.octaveResult.range = range;
            mySpKurtFilt.octaveResult.indexes = myOctaveKurt > str2double(mySpKurtFilt.config.saveSignalThreshold);
            mySpKurtFilt.fullResult.bandWindowResult = mySpKurtFilt.octaveResult; %Result of overlapping bands filtering.
            
            if ~strcmp(mySpKurtFilt.config.filterMode, 'commBand')
                return;
            end
            
            [mySpKurtFilt, ~] = filtrateScalogramRanges(mySpKurtFilt);
            rangesSam = getFiltRanges(mySpKurtFilt, 'octaveResult');
            centralFrequencies = zeros(1, size(rangesSam, 1)); myOctaveKurt = centralFrequencies; myFiltedSign = cell(size(myOctaveKurt));
            for i = 1:1:numel(rangesSam)
                [~, myFiltedSign{i}] = filtrationProcessing(mySpKurtFilt, rangesSam{i});
                myOctaveKurt(:,i) = kurtosis(myFiltedSign{i}, ~str2double(Config.kurtBiasRemove));
                centralFrequencies(i) = mean(rangesSam{i});
            end
            mySpKurtFilt.octaveResult.kurtosis = myOctaveKurt;
            mySpKurtFilt.octaveResult.frequencies = centralFrequencies;
            mySpKurtFilt.octaveResult.filtedSignals = myFiltedSign;
            mySpKurtFilt.octaveResult.range = rangesSam;
            mySpKurtFilt.octaveResult.indexes = 1:1:numel(rangesSam);
            mySpKurtFilt.fullResult.octaveResult = mySpKurtFilt.octaveResult;
            %Get separate ranges, that divided by less kurtosis.
            if str2double(mySpKurtFilt.config.windMinDiv)
                dividedRangesSam = divideWindows(mySpKurtFilt, 'octaveResult');
                centralFrequencies = zeros(1, size(dividedRangesSam, 1)); myOctaveKurt = centralFrequencies; myFiltedSign = cell(size(dividedRangesSam));
                for i = 1:1:numel(dividedRangesSam)
                    [~, myFiltedSign{i}] = filtrationProcessing(mySpKurtFilt, dividedRangesSam{i});
                    myOctaveKurt(:,i) = kurtosis(myFiltedSign{i}, ~str2double(Config.kurtBiasRemove));
                    centralFrequencies(i) = mean(dividedRangesSam{i});
                end
                mySpKurtFilt.octaveResult.kurtosis = [mySpKurtFilt.octaveResult.kurtosis myOctaveKurt];
                mySpKurtFilt.octaveResult.frequencies = [mySpKurtFilt.octaveResult.frequencies centralFrequencies];
                mySpKurtFilt.octaveResult.filtedSignals = [mySpKurtFilt.octaveResult.filtedSignals myFiltedSign];
                mySpKurtFilt.octaveResult.range = [mySpKurtFilt.octaveResult.range dividedRangesSam];
                mySpKurtFilt.octaveResult.indexes = 1:1:numel(mySpKurtFilt.octaveResult.range);
            end
            signalKind = mySpKurtFilt.config.signalKind; if ~isempty(signalKind), signalKind = ['_', signalKind]; end
            lbl = ['Band_' mySpKurtFilt.config.calculating '_' mySpKurtFilt.config.bandFilteringMethod];
            mySpKurtFilt.octaveResult.label = repmat({[lbl signalKind]}, size(rangesSam));
            lbl = ['Band_' mySpKurtFilt.config.calculating '_' mySpKurtFilt.config.bandFilteringMethod '_windowDiv'];
            mySpKurtFilt.octaveResult.label = [mySpKurtFilt.octaveResult.label repmat({[lbl signalKind]}, size(dividedRangesSam))];
            mySpKurtFilt = addResult(mySpKurtFilt, mySpKurtFilt.octaveResult);
        end
        
        function mySpKurtFilt = addResult(mySpKurtFilt, myResult, overwrite)
            if ~exist('overwrite', 'var')
                overwrite = false;
            end
            if ~nnz(myResult.frequencies), return; end
            if overwrite || isempty(mySpKurtFilt.fullResult)
                mySpKurtFilt.fullResult = mySpKurtFilt.emptyResult;
            end
            idxs = myResult.frequencies > 0;
            mySpKurtFilt.fullResult.kurtosis = [mySpKurtFilt.fullResult.kurtosis myResult.kurtosis(idxs)];
            mySpKurtFilt.fullResult.frequencies = [mySpKurtFilt.fullResult.frequencies myResult.frequencies(idxs)];
            mySpKurtFilt.fullResult.filtedSignals = [mySpKurtFilt.fullResult.filtedSignals myResult.filtedSignals(idxs)];
            mySpKurtFilt.fullResult.range = [mySpKurtFilt.fullResult.range myResult.range];
            mySpKurtFilt.fullResult.label = [mySpKurtFilt.fullResult.label myResult.label];
            mySpKurtFilt.fullResult.indexes = 1:1:numel(mySpKurtFilt.fullResult.range);
        end
        
       
        function [mySpKurtFilt, SK, M4, M2, f, myAFR] = spectralKurtosis(mySpKurtFilt, x, Nfft, Noverlap, myWindow)
            % [SK,M4,M2,f] = SK_W(x,Nfft,Noverlap,Window) 
            % Welch's estimate of the spectral kurtosis       
            %       SK(f) = M4(f)/M2(f)^2 - 2 
            % where M4(f) = E{|X(f)|^4} and M2(f) = E{|X(f)|^2} are the fourth and
            % second order moment spectra of signal x, respectively.
            % Signal x is divided into overlapping blocks (Noverlap taps), each of which is
            % detrended, windowed and zero-padded to length Nfft. Input arguments nfft, Noverlap, and Window
            % are as in function 'PSD' or 'PWELCH' of Matlab. Denoting by Nwind the window length, it is recommended to use 
            % nfft = 2*NWind and Noverlap = 3/4*Nwind with a hanning window.
            % (note that, in the definition of the spectral kurtosis, 2 is subtracted instead of 3 because Fourier coefficients
            % are complex circular)
            %
            % --------------------------
            % References: 
            % J. Antoni, The spectral kurtosis: a useful tool for characterising nonstationary signals, Mechanical Systems and Signal Processing, Volume 20, Issue 2, 2006, pp.282-307.
            % J. Antoni, R. B. Randall, The spectral kurtosis: application to the vibratory surveillance and diagnostics of rotating machines, Mechanical Systems and Signal Processing, Volume 20, Issue 2, 2006, pp.308-331.
            % --------------------------
            % Author: J. Antoni
            % Last Revision: 12-2014
            % --------------------------

            
            if nargin < 2
                x = mySpKurtFilt.signalOrig;
            end
            if nargin < 2
                %Use params from config and specified window.
                myWindow = mySpKurtFilt.Window;
                Nfft = getSamplesNum(mySpKurtFilt, mySpKurtFilt.config.FFTlength);
                Noverlap = getSamplesNum(mySpKurtFilt, mySpKurtFilt.config.Noverlap);
            end
            
            myWindow = myWindow(:)/norm(myWindow);		% window normalization
            n = length(x);							% number of data points
            nwind = length(myWindow); 				% length of window

            % check inputs
            if nwind <= Noverlap,error('Window length must be > Noverlap');end
            if Nfft < nwind,error('Window length must be <= Nfft');end

            x = x(:);		
            k = fix((n-Noverlap)/(nwind-Noverlap));	% number of windows


            % Moment-based spectra
            index = 1:nwind;
            f = (0:Nfft-1)*(mySpKurtFilt.Fs/2)/Nfft;
            M4 = 0;
            M2 = 0;

            for i=1:k
                xw = myWindow.*x(index);
                Xw = fft(xw,Nfft);		        
                M4 = abs(Xw).^4 + M4;   
                M2 = abs(Xw).^2 + M2;  
                index = index + (nwind - Noverlap);
            end

            % normalize
            M4 = M4/k;   
            M2 = M2/k; 

            % spectral kurtosis 
            SK = M4./M2.^2 - 2;

            % reduce bias near f = 0 mod(1/2)
            W = abs(fft(myWindow.^2,Nfft)).^2;
            Wb = zeros(Nfft,1);
            for i = 0:Nfft-1
               Wb(1+i) = W(1+mod(2*i,Nfft))/W(1);
            end;
            SK = SK - Wb;
            mySpKurtFilt.fullResult.kurtosVect = SK;
            mySpKurtFilt.fullResult.M2 = M2;
            mySpKurtFilt.fullResult.M4 = M4;
            df = mySpKurtFilt.Fs/length(mySpKurtFilt.signalOrig); fVect = 0:df:mySpKurtFilt.Fs/2-df;
            [d, f] = arrayfun(@(x) min(abs(fVect - x)), f); %Samples of frequency vector.
            mySpKurtFilt.fullResult.f = reshape(f, [], 1);
            
            %Compute filter's AFR as sqrt of SK in range, where it's higher threshold.
            zeroIdxs = SK < str2double(mySpKurtFilt.config.filtThreshold);
            SK(zeroIdxs) = zeros(size( SK(zeroIdxs) ));
            myAFR = sqrt(SK);
            mySpKurtFilt.AFR = myAFR;

        end
        
        function [mySpKurtFilt, myFiltedSign] = filtSpecKurt(mySpKurtFilt)
            myIdxs = mySpKurtFilt.AFR > 0; accSampls = mySpKurtFilt.fullResult.f;
            df = mySpKurtFilt.Fs/length(mySpKurtFilt.signalOrig); F = 0:df:mySpKurtFilt.Fs/2-df;
            %Indexes of Nfft freq vector of border of AFR ones ranges.
            borderIdxs = takeOneByOneBands(double(~myIdxs), struct('succession', 'zero'));
            %Indexes in the full frequency range.
            myFreqBorderIdxs = cellfun(@(x) accSampls(x), borderIdxs, 'UniformOutput', false);
            minSensorFreq = str2double(mySpKurtFilt.config.minSensorFreq); maxSensorFreq = str2double(mySpKurtFilt.config.maxSensorFreq);
            inBandIdxs = cellfun(@(x) (F(x(1)) > minSensorFreq)&&(F(x(2)) < maxSensorFreq), myFreqBorderIdxs); myFreqBorderIdxs = myFreqBorderIdxs(inBandIdxs);
            notNarrowIdxs = cellfun(@(x) x(2)-x(1) > 100, myFreqBorderIdxs); myFreqBorderIdxs = myFreqBorderIdxs(notNarrowIdxs);
            if isempty(myFreqBorderIdxs), return; end
            %Indexes of necessary freqs to filtrate.
            myFreqIdxs = zeros(size(mySpKurtFilt.signalOrig));
            %Put in necessary to filtrate ranges.
            for i = 1:numel(myFreqBorderIdxs)
                theCurrIdxs = myFreqBorderIdxs{i}(1):myFreqBorderIdxs{i}(2);
                myFreqIdxs(theCurrIdxs) = ones(size( myFreqIdxs(theCurrIdxs) ));
            end
            mySpKurtFilt.fullResult.indexes = myFreqIdxs';
%             rangesSam = getFiltRanges(mySpKurtFilt, 'fullResult');
            [~, myFiltedSign] = cellfun(@(x) filtrationProcessing(mySpKurtFilt, x), myFreqBorderIdxs, 'UniformOutput', false);
            kurt = cellfun(@(x) kurtosis(x, ~str2double(mySpKurtFilt.config.kurtBiasRemove)), myFiltedSign);
            mySpKurtFilt.fullResult.filtedSignals = myFiltedSign;
            mySpKurtFilt.fullResult.kurtosis = kurt;
            mySpKurtFilt.fullResult.range = myFreqBorderIdxs;
            mySpKurtFilt.fullResult.frequencies = cellfun(@(x) mean(x), myFreqBorderIdxs);
            mySpKurtFilt.fullResult.indexes = numel(myFreqBorderIdxs);
            lbl = ['Moment_' mySpKurtFilt.config.calculating '_' mySpKurtFilt.config.bandFilteringMethod];
            signalKind = mySpKurtFilt.config.signalKind; if ~isempty(signalKind), signalKind = ['_', signalKind]; end
            mySpKurtFilt.fullResult.label = repmat({[lbl signalKind]}, size(myFreqBorderIdxs));
        end
        
        function mySpKurtFilt = validateResults(mySpKurtFilt)
            myFiltedSign = mySpKurtFilt.fullResult.filtedSignals;
            if isempty(myFiltedSign), return; end
            myLabels = mySpKurtFilt.fullResult.label;
            if isempty(myFiltedSign{1}), myFiltedSign = []; end
            if isfield(mySpKurtFilt.fullResult, 'scalogramFilt')
                myFiltedSign = [myFiltedSign mySpKurtFilt.fullResult.scalogramFilt.signals];
                myLabels = [myLabels arrayfun(@(x) sprintf('Scalogram point #%i', x), 1:numel(mySpKurtFilt.fullResult.scalogramFilt.signals), 'UniformOutput', false)];
            end
            if isempty(myFiltedSign), return; end
            %valIdxs = zeros(size(myFiltedSign));
            %=====Compute envelope and find optimal peaks table.=====
            %Make decision about filtered signal validity by width, height and a sequence stability factors.
            envels = cellfun(@(x) envelope(x), myFiltedSign, 'UniformOutput', false); mySpKurtFilt.fullResult.envels = envels;
            kurts = cellfun(@(x) kurtosis(x), envels, 'UniformOutput', true); mySpKurtFilt.fullResult.kurts = kurts;
            rmses = cellfun(@(x) rms(x), envels, 'UniformOutput', true); mySpKurtFilt.fullResult.rmses = rmses;
            %-=Get the best peaks wich will represent pulses sequence.=-
%         %Cet 30 the best peaks by prominence and set threshold relative 2 their mean.
%         Attribs = struct('detrend4peaksFinding', '0', 'theBextPeaksNum', '30prom');
%         myConfAve = struct('span', '3', 'Attributes', Attribs); myConfAve.windowAveraging.saveSampling = '1';
%         myHandler = cellfun(@(x) signalAveragingHandler(x, myConfAve), envels, 'UniformOutput', false);
%         [~, locs, pks, w, proms] = cellfun(@(x) getSpanAuto(x), myHandler, 'UniformOutput', false);
%         idxs = cellfun(@(x, y) x > 2*y, pks, num2cell(rmses), 'UniformOutput', false);
%         locs = cellfun(@(x, y) x(y), locs, idxs, 'UniformOutput', false); pks = cellfun(@(x, y) x(y), pks, idxs, 'UniformOutput', false);
%         w = cellfun(@(x, y) x(y), w, idxs, 'UniformOutput', false); proms = cellfun(@(x, y) x(y), proms, idxs, 'UniformOutput', false);
            [pks, locs, ~, ~] = cellfun(@(x, y) findpeaks(x, 'MinPeakHeight', 2*y), envels, num2cell(rmses), 'UniformOutput', false);
%         threshold = cellfun(@(x) mean(x)*0.6, pks, 'UniformOutput', true);  mySpKurtFilt.fullResult.threshold = threshold;
            threshold = cellfun(@(x) 2*x, num2cell(rmses), 'UniformOutput', true);  mySpKurtFilt.fullResult.threshold = threshold;
%             %Find necessary minimum peaks distance as average width of good peaks of smoothed signals.
%             [~, myResultSignal] = cellfun(@(x, y) windowAveraging(x, round(2.5*y), 'bothSide'), myHandler, span, 'UniformOutput', false);
%             [~, ~, widthAve] = cellfun(@(x, y) findpeaks(x, 'MinPeakHeight', y), myResultSignal, num2cell(threshold), 'UniformOutput', false);
%             minDists = cellfun(@(x) mean(x), widthAve, 'UniformOutput', false);  mySpKurtFilt.fullResult.minDists = cell2num(minDists);
            %Find all peaks upper threshold with minimum distance.
            %[pks, locs, w, proms] = cellfun(@(x, y, z) findpeaks(x, 'MinPeakHeight', y,'MinPeakDistance', z), envels, num2cell(threshold), minDists, 'UniformOutput', false);
            minDists = cellfun(@(x) round(mean(diff(x))/2), locs, 'UniformOutput', true); idxs = isnan(minDists);
            minDists(idxs) = ones( size(minDists(idxs)) ); mySpKurtFilt.fullResult.minDists = minDists;
            [pks, locs, w, proms] = cellfun(@(x, y, z) findpeaks( x, 'MinPeakHeight', y,'MinPeakDistance', z ), envels, num2cell(threshold), num2cell(minDists), 'UniformOutput', false);
            distVects = cellfun(@(x) diff(x), locs, 'UniformOutput', false); mySpKurtFilt.fullResult.locs = locs;
            dists = cellfun(@(x) mean(x), distVects, 'UniformOutput', true); mySpKurtFilt.fullResult.dists = dists;
            stabibity = dists./cellfun(@(x) std(x), distVects, 'UniformOutput', true); mySpKurtFilt.fullResult.stabibity = stabibity;
            widthFactor = mean(dists)*(1./cellfun(@(x) mean(x), w, 'UniformOutput', true)); mySpKurtFilt.fullResult.widthFactor = widthFactor;
            heiFactor = cellfun(@(x) mean(x), pks, 'UniformOutput', true)./rmses; mySpKurtFilt.fullResult.heiFactor = heiFactor;
            promFactor = cellfun(@(x) mean(x), proms, 'UniformOutput', true)./rmses; mySpKurtFilt.fullResult.promFactor = promFactor;
            idxsK = (kurts(1:end-numel(mySpKurtFilt.fullResult.scalogramFilt.signals)) > 4.5);
            idxsS = (stabibity(1:end-numel(mySpKurtFilt.fullResult.scalogramFilt.signals)) > 1.7);
            idxsH = (heiFactor(1:end-numel(mySpKurtFilt.fullResult.scalogramFilt.signals)) > 3);
            idxsW = (widthFactor(1:end-numel(mySpKurtFilt.fullResult.scalogramFilt.signals)) > 20);
            mySpKurtFilt.fullResult.locs = locs; mySpKurtFilt.fullResult.indexes = find(idxsK & idxsS & idxsH & idxsW);
            for i = 1:numel(rmses)
                fprintf('Window #%i: %s\n', i, myLabels{i});
                fprintf('RMS: %1.3f\n', rmses(i));
                fprintf('Stabibity: %1.3f\n', stabibity(i));
                fprintf('widthFactor: %1.3f\n', widthFactor(i));
                fprintf('heiFactor: %1.3f\n', heiFactor(i));
                fprintf('promFactor: %1.3f\n\n\n', promFactor(i));
            end
        end
        
        function plotSpecKurt(mySpKurtFilt)
            %Return if the method was switched off.
            if ~isfield(mySpKurtFilt.fullResult, 'f'), return; end
            if isempty(mySpKurtFilt.fullResult.f), return; end
            visStr = mySpKurtFilt.config.plotVisible;
            mySpKurtFilt.config.formats = 'jpg';
            Nfft = getSamplesNum(mySpKurtFilt, mySpKurtFilt.config.FFTlength);
            noverlap = getSamplesNum(mySpKurtFilt, mySpKurtFilt.config.Noverlap);
            SK = mySpKurtFilt.fullResult.kurtosVect;
            M2 = mySpKurtFilt.fullResult.M2;
            df = mySpKurtFilt.Fs/length(mySpKurtFilt.signalOrig); F = 0:df:mySpKurtFilt.Fs/2-df;
            f = F(mySpKurtFilt.fullResult.f);
                signalKind = mySpKurtFilt.config.signalKind;
                if ~isempty(signalKind), signalKind = [' - ', signalKind]; end
           if str2double(mySpKurtFilt.config.fullSavingEnable)
               figure('units','points','Position',[0 ,0 ,800,600], 'visible', visStr), newplot;
               subplot(211), plot(f(1:Nfft/2), M2(1:Nfft/2)), grid on,
               xlabel('Normalized frequency'), xlim([f(1) f(Nfft/2)]), title('Power spectrum')
               subplot(212), plot(f(1:Nfft/2), SK(1:Nfft/2)), grid on
               xlabel('Frequency'), xlim([f(1) f(Nfft/2)]), title('Spectral Kurtosis')
               savePic(mySpKurtFilt, ['Spectral kurtosis' signalKind ' - PSD and SK']);
               % Close figure with visibility off
               if strcmpi(visStr, 'off'), close, end
               %Initial and filted signals.
               mySpKurtFilt.config.formats = 'jpg fig';
               figure('units','points','Position',[0 ,0 ,800,600], 'visible', visStr);
               dt = 1/mySpKurtFilt.Fs; t = 0:dt:length(mySpKurtFilt.signalOrig)*dt - dt;
               subplot(211), plot(t, mySpKurtFilt.signalOrig), grid on,
               xlabel('Time'), xlim([t(1) t(end)]), title('Initial signal')
               subplot(212), plot(t, mySpKurtFilt.signal), grid on
               xlabel('Time'), xlim([t(1) t(end)]), title('Signal')
               %savePic(mySpKurtFilt, ['Spectral kurtosis' signalKind ' - initial and filted signals']);
               % Close figure with visibility off
               if strcmpi(visStr, 'off'), close, end
               mySpKurtFilt.config.formats = 'jpg';
               %Initial and filted signals amplitude spectrums, AFR of computed filter.
               figure('units','points','Position',[0 ,0 ,800,600], 'visible', visStr);
               SP = abs(fft(mySpKurtFilt.signalOrig)); subplot(311), plot( F, SP(1:numel(F)) ), grid on,
               xlabel('Time'), xlim([F(1) F(end)]), title('Initial signal''s amplitude spectrum')
               SP = abs(fft(mySpKurtFilt.signal)); subplot(312), plot( F, SP(1:numel(F)) ), grid on
               xlabel('Frequency'), xlim([F(1) F(end)]), title('Filtered signal''s amplitude spectrum')
               subplot(313), plot(f, mySpKurtFilt.AFR), grid on
               xlabel('Frequency'), xlim([f(1) f( floor(numel(f)/2) )]), title('Syntesied filter''s AFR')
               savePic(mySpKurtFilt, ['Spectral kurtosis' signalKind ' - initial and filted signals ampltude spectrum and syntesied AFR']);
               % Close figure with visibility off
               if strcmpi(visStr, 'off'), close, end
               %Spectrogram...
               figure('units','points','Position',[0 ,0 ,800,600], 'visible', visStr);
               spectrogram(mySpKurtFilt.signal, mySpKurtFilt.Window, noverlap, Nfft);
               savePic(mySpKurtFilt, ['Spectral kurtosis' signalKind ' - spectrogram']);
               % Close figure with visibility off
               if strcmpi(visStr, 'off'), close, end
           end
        end
        
        function plotFiltedSigns(mySpKurtFilt)
            if isempty(mySpKurtFilt.fullResult.range), return; end
            if str2double(mySpKurtFilt.config.debugModeEnable)
                mySpKurtFilt.config.formats = 'jpg fig';
            end
            visStr = mySpKurtFilt.config.plotVisible;
           df = mySpKurtFilt.Fs/length(mySpKurtFilt.signalOrig); F = 0:df:mySpKurtFilt.Fs/2-df;
                signalKind = mySpKurtFilt.config.signalKind;
                if ~isempty(signalKind), signalKind = [' - ', signalKind]; end
           %Save filtered ranges.
           dt = 1/mySpKurtFilt.Fs; t = 0:dt:length(mySpKurtFilt.signalOrig)*dt - dt;
           for i = mySpKurtFilt.fullResult.indexes %1:numel(mySpKurtFilt.fullResult.filtedSignals)
               figure('units','points','Position',[0 ,0 ,800,600], 'visible', visStr);
               subplot(211); hold on, plot( t, mySpKurtFilt.fullResult.filtedSignals{i} ), grid on,
               findpeaks(mySpKurtFilt.fullResult.envels{i}, t, 'MinPeakHeight', mySpKurtFilt.fullResult.threshold(i),'MinPeakDistance', t(mySpKurtFilt.fullResult.minDists(i)),'Annotate','extents');
%                plot(t, mySpKurtFilt.fullResult.envels{i});
%                stem(t(mySpKurtFilt.fullResult.locs{i}), mySpKurtFilt.fullResult.envels{i}(mySpKurtFilt.fullResult.locs{i}), 'go');
               plot(t, repmat(2*mySpKurtFilt.fullResult.rmses(i), size(t)), 'r:'); plot(t, repmat(mySpKurtFilt.fullResult.threshold(i), size(t)), 'g:');
               if numel(mySpKurtFilt.fullResult.locs{i})
                   numPK = min(15, numel(mySpKurtFilt.fullResult.locs{i})); numSampT = min([floor(mySpKurtFilt.fullResult.locs{i}(numPK)*1.2) numel(t)]); %Plot limited valid peaks number. %myWinLen = sprintf( '500maxPer %d', F(mySpKurtFilt.fullResult.range{i}(1)) ); numSampT = getSamplesNum(mySpKurtFilt, myWinLen);
               else
                   numSampT = numel(t);
               end
               xlabel('Time'), xlim([t(1) t( numSampT )]), tit = sprintf('Window #%i with kurtosis %1.2f filtered signal', i, mySpKurtFilt.fullResult.kurtosis(i)); title(tit)
               SP = abs(fft( mySpKurtFilt.fullResult.filtedSignals{i} )); subplot(212), plot( F, SP(1:numel(F)) ), grid on
               xlabel('Frequency'), xlim( F( floor(mySpKurtFilt.fullResult.range{i}) ) ), title('Amplitude spectrum')
               ttl = strsplit(tit, ' with'); picName = [ttl{1} ' - ' mySpKurtFilt.fullResult.label{i}]; %Use a window number and assigned label.
               savePic(mySpKurtFilt, ['Spectral kurtosis' signalKind ' - ' picName]);
               % Close figure with visibility off
               if strcmpi(visStr, 'off'), close, end
           end
        end
        
        function plotMethodPic(mySpKurtFilt, F, SPk, label)
                %Signal spectrum frequency vector. F - SK's freq vector sampling.
               df = mySpKurtFilt.Fs/length(mySpKurtFilt.signalOrig); spF = 0:df:mySpKurtFilt.Fs/2-df;
                signalKind = mySpKurtFilt.config.signalKind;
                if ~isempty(signalKind), signalKind = [' - ', signalKind]; end
               mySpKurtFilt.config.formats = 'jpg';
               %Check if a signal kind (acceleration, displ., ...) assigned.
                signalKind = mySpKurtFilt.config.signalKind;
                if ~isempty(signalKind), signalKind = [' - ', signalKind]; end
                %Check scalogramm data, if it is.
                n = 2;
                if ~isempty(mySpKurtFilt.File)
                    if ~isempty(mySpKurtFilt.File.fullScalogramData)
                        fullScalogramData = mySpKurtFilt.File.fullScalogramData; n = 3; %Draw also a scalogramm.
                    end
                end
            visStr = mySpKurtFilt.config.plotVisible;
               %Initial signal amplitude spectrum and it's scalogram, if it's exist.
               figure('units','points','Position',[0 ,0 ,800,600], 'visible', visStr);
               SP = abs(fft(mySpKurtFilt.signalOrig)); SP = SP/length(SP); subplot(211), plot( spF, SP(1:numel(spF)) ), grid on,
               xlabel('Frequency'), xlim([spF(1) str2double(mySpKurtFilt.config.highFrequency)]), title('Initial signal''s amplitude spectrum')
               %Signals'kurtosis vector and amplitude spectrum, if it's necessary.
               subplot(212), plot(spF(F), SPk, 'r'), grid on, title(label)
               xlabel('Frequency'), xlim([spF(1) str2double(mySpKurtFilt.config.highFrequency)])
               if n == 3
                   %Spectrum on SK and scalogram.
                   subplot(2, 1, 1), hold on; plot(fullScalogramData.frequencies, fullScalogramData.coefficients*max( SP(1:numel(spF)) )/max(fullScalogramData.coefficients));
                   subplot(2, 1, 2), hold on; plot(spF, SP(1:numel(spF))/max( SP(1:numel(spF)) )*max(SPk), 'b');
               end
               savePic(mySpKurtFilt, ['Spectral kurtosis' signalKind ' - ' label]);
               % Close figure with visibility off
               if strcmpi(visStr, 'off'), close, end
        end
        
        function plotSpectrumKurtosis(mySpKurtFilt)
            visStr = mySpKurtFilt.config.plotVisible;
                signalKind = mySpKurtFilt.config.signalKind;
                if ~isempty(signalKind), signalKind = [' - ', signalKind]; end
           dt = 1/mySpKurtFilt.Fs; t = 0:dt:length(mySpKurtFilt.signalOrig)*dt - dt;
           df = mySpKurtFilt.Fs/length(mySpKurtFilt.signalOrig); F = 0:df:mySpKurtFilt.Fs/2-df;
            %Plot scalogram point signal.
            if str2double(mySpKurtFilt.config.debugModeEnable)
                mySpKurtFilt.config.formats = 'jpg fig';
            end
           if isfield(mySpKurtFilt.fullResult, 'scalogramFilt') && str2double(mySpKurtFilt.config.fullSavingEnable)
               for i = 1:numel(mySpKurtFilt.fullResult.scalogramFilt.signals)
                   figure('units','points','Position',[0 ,0 ,800,600], 'visible', visStr);
                   subplot(211), hold on, plot( t, mySpKurtFilt.fullResult.scalogramFilt.signals{i} ), grid on,
                myWinLen = sprintf( '500maxPer %d', mySpKurtFilt.fullResult.scalogramFilt.ranges(1, i)); numSampT = getSamplesNum(mySpKurtFilt, myWinLen);
                   if isfield(mySpKurtFilt.fullResult, 'envels')
                       scalIdx = numel(mySpKurtFilt.fullResult.envels) - numel(mySpKurtFilt.fullResult.scalogramFilt.signals) + i;
                       findpeaks(mySpKurtFilt.fullResult.envels{scalIdx}, t, 'MinPeakHeight', mySpKurtFilt.fullResult.threshold(scalIdx),'MinPeakDistance', t(mySpKurtFilt.fullResult.minDists(scalIdx)),'Annotate','extents');
                       plot(t, repmat(2*mySpKurtFilt.fullResult.rmses(scalIdx), size(t)), 'r:'); plot(t, repmat(mySpKurtFilt.fullResult.threshold(scalIdx), size(t)), 'g:');
                       numPK = min(15, numel(mySpKurtFilt.fullResult.locs{scalIdx})); numSampT = min([floor(mySpKurtFilt.fullResult.locs{scalIdx}(numPK)*1.2) numel(t)]); %Plot limited valid peaks number.
                   end
                   xlabel('Time'), xlim([t(1) t( numSampT )]), tit = sprintf('Scalogram point #%i with central freq %1.2f filtered signal with kurtosis %1.3f', ...
                       i, sum(mySpKurtFilt.fullResult.scalogramFilt.ranges(:, i))/2, mySpKurtFilt.fullResult.scalogramFilt.bandKurtosis(i)); title(tit)
                   SP = abs(fft( mySpKurtFilt.fullResult.scalogramFilt.signals{i} )); subplot(212), plot( F, SP(1:numel(F)) ), grid on
                   xlabel('Frequency'), xlim(mySpKurtFilt.fullResult.scalogramFilt.ranges(:, i)), title('Amplitude spectrum')
                   savePic(mySpKurtFilt, ['Spectral kurtosis' signalKind ' - ' tit]);
                   % Close figure with visibility off
                   if strcmpi(visStr, 'off'), close, end
               end
           end
            mySpKurtFilt.config.formats = 'jpg';
           %Plot all filtered by all methods signals and moment imgs if it was computed.
           if str2double(mySpKurtFilt.config.fullSavingEnable)
               plotFiltedSigns(mySpKurtFilt);
               plotSpecKurt(mySpKurtFilt);
           end
           %Prepare SK and frequency vectors, labels for each method.
           if ~isempty(mySpKurtFilt.octaveResult)
               df = mySpKurtFilt.Fs/length(mySpKurtFilt.signalOrig); F = 0:df:mySpKurtFilt.Fs/2-df;
               SPk = mySpKurtFilt.octaveResult.kurtosVect(1:numel(F));
               label = 'Band filted SK';
               plotMethodPic(mySpKurtFilt, 1:numel(F), SPk, label);
           end
           if isfield(mySpKurtFilt.fullResult, 'f')
               SPk = mySpKurtFilt.fullResult.kurtosVect;
               label = 'Moment based SK';
               plotMethodPic(mySpKurtFilt, mySpKurtFilt.fullResult.f, SPk, label);
           end
        end
        
        function [mySpKurtFilt, myFiltedSign] = filtrationProcessing(mySpKurtFilt, filtRange)
            if strcmp(mySpKurtFilt.config.bandFilteringMethod, 'fft')
                [mySpKurtFilt, myFiltedSign] = filtByFFT(mySpKurtFilt, [], filtRange);
            end
            if strcmp(mySpKurtFilt.config.bandFilteringMethod, 'decimFilt')
                [mySpKurtFilt, myFiltedSign] = filtByDecimFilt(mySpKurtFilt, [], filtRange);
            end
            if strcmp(mySpKurtFilt.config.bandFilteringMethod, 'AFR')
                [mySpKurtFilt, myFiltedSign] = AFRfiltration(mySpKurtFilt, [], num2str(filtRange), 'decimFilt');
            end
%             myFiltedSign = myFiltedSign(floor(numel(myFiltedSign)/2):end);
        end
        
        function [mySpKurtFilt, myFiltedSign] = filtrateScalogramRanges(mySpKurtFilt)
            myFiltedSign = [];
            if isempty(mySpKurtFilt.File)
                return;
            end
            if isempty(mySpKurtFilt.File.fullScalogramData)
                return;
            end
            scalData = mySpKurtFilt.File.fullScalogramData.validPeaks;
            if isempty(scalData)
                warning('There is no valid scalogram peaks.');
                return;
            end
            hiFreqs = [scalData.highFrequency];
            lowFreqs = [scalData.lowFrequency];
            ranges = [lowFreqs; hiFreqs]; myFiltedSign = cell(1, size(ranges, 2));
            myScalKurt = zeros(size(myFiltedSign));
            for i = 1:size(ranges, 2)
                rg = round(ranges(:, i)/mySpKurtFilt.Fs*length(mySpKurtFilt.signalOrig)); %Translate to samples.
                [~, myFiltedSign{i}] = filtrationProcessing(mySpKurtFilt, rg);
                myScalKurt(:,i) = kurtosis(myFiltedSign{i}, ~str2double(mySpKurtFilt.config.kurtBiasRemove));
            end
            mySpKurtFilt.fullResult.scalogramFilt.signals = myFiltedSign;
            mySpKurtFilt.fullResult.scalogramFilt.ranges = ranges;
            mySpKurtFilt.fullResult.scalogramFilt.bandKurtosis = myScalKurt;
        end
        
        function [mySpKurtFilt, filtedSign, pulseResponse] = AFRfiltration(mySpKurtFilt, mySignal, AFRvect, mode, Fs)
            if ~exist('mySignal', 'var')
                mySignal = [];
            end
            if isempty(mySignal)
                mySignal = mySpKurtFilt.signalOrig;
            end
            if ~exist('AFRvect', 'var')
                AFRvect = mySpKurtFilt.AFR;
            end
            if ~exist('mode', 'var')
                mode = '';
            end
            if ~exist('Fs', 'var')
                Fs = [];
            end
            df = mySpKurtFilt.Fs/length(mySignal);
            fVect = 0:df:mySpKurtFilt.Fs-df;
            mySignal = reshape(mySignal, 1, []);
            lastSamp = []; %Restore samples number next time.
            if rem(numel(mySignal), 2)
                lastSamp = numel(mySignal);
                mySignal = mySignal(1:end-1);
            end
            if ischar(AFRvect)
                ranges = str2num(AFRvect);
            end
            if strfind(mode, 'lowFr')
               %=====Frequency translation to zero to filter by LPF.=====
                %Computing an interpolation step 2 carry a lower frequency to one Herz.
                interpStep = 1/ranges(1);
                %Compute a sampling...
                averSam = 1:floor(ranges(1)/2);
                firstSam = mean(mySignal(averSam));
                lastSam = mean(mySignal(end-averSam+1));
                originalSamples = [0.5+interpStep, 1:length(mySignal), length(mySignal)+0.5];
                interpolateSampels = 0.5+interpStep:interpStep:length(mySignal)+0.5;
                mySignal = [firstSam mySignal lastSam];
                %Interpolate 2 carry frequency.
                mySignal = interp1(originalSamples, mySignal, interpolateSampels, 'pchip');
                %Assign a new range 2 filter.
                ranges(2) = ranges(2) - ranges(1);
                ranges(1) = 0;
            end
            if exist('ranges', 'var')
                span = floor( mySpKurtFilt.Fs/( fVect(ranges(2))*2*1.2 ) );
            end
            if strfind(mode, 'decimFilt')
                %=====Expand frequency vector and translate 2 high freqs 4 better filtration.=====
                %Filter a high freqs 2 avoid alizing.
                passbandF = max(60, ranges(2)*1.2); stopbandF = max(100, ranges(2)*1.7); %Limit a lpf's freqs 2 make it stable.
                passbandF = min(passbandF, mySpKurtFilt.Fs/2.2); stopbandF = min(stopbandF, mySpKurtFilt.Fs/2.1);
            lpf = designfilt('lowpassiir', 'PassbandFrequency', passbandF, 'StopbandFrequency', stopbandF, 'PassbandRipple', 1, 'StopbandAttenuation', 60, 'SampleRate', 96000);
            mySignal = filtfilt(lpf, mySignal);
                idxs = linspace(0, numel(mySignal), numel(mySignal)/span+1);
                idxs = round(idxs(2:end)); mySignal = mySignal(idxs);
            if numel(mySignal)*span < numel(mySpKurtFilt.signalOrig)
                %Add one more sample if there rested a part of window.
                %In other case interpolated signal will be shorter than original.
                %Excess samples will be truncated.
                mySignal = [mySignal mySpKurtFilt.signalOrig(end)];
            end
                %Recompute ranges.
                ranges = ranges*span;
                %Check that range wide enougth.
                rel = diff(fVect(ranges))/(mySpKurtFilt.Fs*2/1000); %Relation range to minimum possible.
                if rel < 1
                    ranges = ranges/rel; %Restrict to min possible range.
                end
            end
            if ischar(AFRvect)
                AFRvect = zeros(size(mySpKurtFilt.signalOrig, 1), ceil(size(mySpKurtFilt.signalOrig, 2)/2));
                for i = 1:size(ranges, 1)
                   rg = ranges(i,:); %round(ranges(i,:)/span);
                    filtRange = rg(1):rg(end);
                   AFRvect(filtRange) = ones(size( AFRvect(filtRange) ));
                end
                mode = [mode 'flip'];
            end
            AFRvect = reshape(AFRvect, 1, []);
            if isreal(AFRvect)
                AFRvect = complex(AFRvect);
            end
            %Default return only part of signal without transient response.
            convMode = 'same';
            if strfind(mode, 'full')
                convMode = 'full';
            end
            if strfind(mode, 'valid')
                convMode = 'valid';
            end
            if strfind(mode, 'flip')
                fSp = zeros(1, size(AFRvect, 2)*2); fSp = complex(fSp);
                midSamp = numel(fSp)/2+1;
                fSp(1:numel(AFRvect)) = AFRvect;
                fSp(1:10) = complex(zeros(size( fSp(1:10) )));
                fSp(midSamp-10:midSamp) = complex(zeros(size( fSp(midSamp-10:midSamp) )));
                fSp(midSamp:end) = conj(fliplr(fSp(2:midSamp)));
                AFRvect = fSp;
                AFRvect(midSamp) = conj(AFRvect(1));
            end
            pulseResponse = ifft(AFRvect)*length(AFRvect);
            if strfind(mode, 'filtfilt')
                flippedSign = fliplr(mySignal);
                flippedSign = conv(flippedSign, pulseResponse(1:numel(pulseResponse)/2), convMode);
                mySignal = fliplr(flippedSign);
            end
            filtedSign = conv(mySignal, pulseResponse(1:numel(pulseResponse)/2), convMode);
            if strfind(mode, 'full')
                filtedSign = filtedSign(1:numel(filtedSign)/2);
            end
            if strfind(mode, 'decimFilt')
                interpStep = 1/span;
                averSam = 1:floor(span/2);
                firstSam = mean(filtedSign(averSam));
                lastSam = mean(filtedSign(end-averSam+1));
                originalSamples = [0.5+interpStep, 1:length(filtedSign), length(filtedSign)+0.5];
                interpolateSampels = 0.5+interpStep:interpStep:length(filtedSign)+0.5;
                filtedSign = [firstSam filtedSign lastSam];
                filtedSign = interp1(originalSamples, filtedSign, interpolateSampels, 'pchip');
            end
                if numel(mySpKurtFilt.signalOrig) - numel(filtedSign) == 1
                    filtedSign = [filtedSign filtedSign(end)]; %Make numel equal.
                end
                if numel(mySpKurtFilt.signalOrig) < numel(filtedSign)
                    filtedSign = filtedSign(1:numel(mySpKurtFilt.signalOrig)); %Make numel equal.
                end
            mySpKurtFilt.signal = reshape(filtedSign, size(mySpKurtFilt.signalOrig));
        end
        
        function [mySpKurtFilt, myFiltedSign] = filtByFFT(mySpKurtFilt, mySign, filtRangeSamp)
            if isempty(mySign)
                mySign = mySpKurtFilt.signalOrig;
            end
            oddSamp = [];
            if mod(length(mySign), 2) %Gag: make an even samples number.
                oddSamp = numel(mySign) - 1;
                mySign = mySign(1:end-1);
            end
            
            fSp = fft(mySign)/length(mySign);
            
            lowSamp = filtRangeSamp(1)-1;
            midSamp = numel(fSp)/2+1;
            fSp(1:lowSamp) = zeros(size( fSp(1:lowSamp) ));
            fSp(filtRangeSamp(end):midSamp) = zeros(size( fSp(filtRangeSamp(end):midSamp) ));
            fSp(midSamp:end) = conj(flipud(fSp(2:midSamp)));
            
            myFiltedSign = (ifft(fSp))*length(fSp);
            myFiltedSign = [myFiltedSign; myFiltedSign(oddSamp)]; %2 make a sample number equal.
            
            mySpKurtFilt.signal = myFiltedSign;
        end
        
        function [mySpKurtFilt, myFiltedSign] = filtByDecimFilt(mySpKurtFilt, mySign, filtRange)
            if isempty(mySign)
                mySign = mySpKurtFilt.signalOrig;
            end
            %Compute span as relation of the current Fs to the min. possible. Fs according 2 Nyquist zone, then translate freq back - think again.
            df = mySpKurtFilt.Fs/length(mySign); fVect = 0:df:mySpKurtFilt.Fs/2-df;
            span = floor( mySpKurtFilt.Fs/( fVect(filtRange(2))*2*2 ) );
            %=====Decimate signal 2 lower sample rate 2 expand frequency vector.=====
            if span > 2
                %Windowing for runouts reduction.
                mySign = mySign.*window('kaiser', numel(mySign), 2.5);
                %Filter a high freqs 2 avoid alizing.
                passbandF = max(60, filtRange(2)*1.2); stopbandF = max(100, filtRange(2)*1.7); %Limit a lpf's freqs 2 make it stable.
                passbandF = min(passbandF, mySpKurtFilt.Fs/2.2); stopbandF = min(stopbandF, mySpKurtFilt.Fs/2.1);
            lpf = designfilt('lowpassiir', 'PassbandFrequency', passbandF, 'StopbandFrequency', stopbandF, 'PassbandRipple', 1, 'StopbandAttenuation', 60, 'SampleRate', 96000);
            mySign = filtfilt(lpf, mySign);
                idxs = round(linspace(0, numel(mySign), numel(mySign)/span+1));
                idxs = idxs(2:end); sign2filt = mySign(idxs);
            else
                 sign2filt = mySign; span = 1;
            end
            if numel(sign2filt)*span < numel(mySign)
                %Add one more sample if there rested a part of window.
                %In other case interpolated signal will be shorter than original.
                %Excess samples will be truncated.
                sign2filt = [sign2filt; mySign(end)];
            end
            %-=Close freqs far now. Calculate range and passband freqs.=-
            filtRangeExp = fVect(filtRange*span); %Expanded by decimation range.
            fMid = (filtRangeExp(1) + filtRangeExp(end))/2;
            %Minimum range.
            passB(1) = fMid - mySpKurtFilt.Fs/1000;
            passB(2) = fMid + mySpKurtFilt.Fs/1000;
            %Assigned expanded range, that should be outside minimum range.
            [passB(1), mInd(1)] = min([filtRangeExp(1), passB(1)]);
            [passB(2), mInd(2)] = max([filtRangeExp(end), passB(2)]);
            passB(2) = min([passB(2), (mySpKurtFilt.Fs/2-1)/1.2]);
            if passB(2) < passB(1)
                warning('Too high frequency assigned.');
                myFiltedSign = mySpKurtFilt.signalOrig;
                return; %GAG.
            end
            if passB(1) <= 0
                passB = passB - passB(1) + 5;
            end
            %Check if assigned range was inside minimum, warn about too narrow range if it is.
            if sum(mInd) > 3
               warning('There is too narrow range assigned for stable filtration.');
            end
            stopB(1) = passB(1)*0.98; stopB(2) = passB(2)*1.02; %Stopband freqs.
            
            %=====Filter a signal in estimated range.=====
            bpf = designfilt('bandpassiir', 'StopbandFrequency1', stopB(1), 'PassbandFrequency1', passB(1), 'PassbandFrequency2', passB(2), 'StopbandFrequency2', stopB(2), 'StopbandAttenuation1', 20, 'PassbandRipple', 1, 'StopbandAttenuation2', 20, 'SampleRate', mySpKurtFilt.Fs);
            cleanS = filtfilt(bpf, sign2filt);

            %=====Restore orig Fs and freq vector.=====
            interpStep = 1/span;
            averSam = 1:floor(span/2);
            firstSam = mean(cleanS(averSam));
            lastSam = mean(cleanS(end-averSam+1));
            originalSamples = [0.5+interpStep, 1:length(sign2filt), length(sign2filt)+0.5];
            interpolateSampels = 0.5+interpStep:interpStep:length(sign2filt)+0.5;
            cleanS = [firstSam reshape(cleanS, 1, []) lastSam];
            if span > 2
                myFiltedSign = interp1(originalSamples, cleanS, interpolateSampels, 'pchip');
            else
                myFiltedSign = cleanS;
            end
            myFiltedSign(isnan(myFiltedSign)) = zeros(size( myFiltedSign(isnan(myFiltedSign)) ));
            if numel(mySpKurtFilt.signalOrig) - numel(myFiltedSign) == 1
                myFiltedSign = [myFiltedSign myFiltedSign(end)]; %Make numel equal.
            end
            if numel(mySpKurtFilt.signalOrig) < numel(myFiltedSign)
                myFiltedSign = myFiltedSign(1:numel(mySpKurtFilt.signalOrig)); %Make numel equal.
            end
            myFiltedSign = reshape(myFiltedSign, [], 1);
        end
        
        function num = getSamplesNum(mySpKurtFilt, myWinLen, mySign)
            %Window length mb assigned relative to signal samples number, in samples,
            %in seconds, in periods number of minimum frequency.
            if ~exist('mySign', 'var')
               mySign = mySpKurtFilt.signalOrig;
            end
            if strcmp(myWinLen, 'mid')
                num = floor(numel(mySign)/2);
                return;
            end
            if strcmp(myWinLen, 'full')
                num = numel(mySign);
                return;
            end
            if strfind(myWinLen, 'signPerc')
                myWinLen = strrep(myWinLen, 'signPerc', '');
                num = floor( numel(mySign)*str2double(myWinLen)/100 );
                return;
            end
            if strfind(myWinLen, 'windPerc')
                myWinLen = strrep(myWinLen, 'windPerc', '');
                num = floor( numel(mySpKurtFilt.Window)*str2double(myWinLen)/100 );
                return;
            end
            if strfind(myWinLen, 'sec')
                myWinLen = strrep(myWinLen, 'sec', '');
                myWinLen = str2num(myWinLen);
                dt = 1/mySpKurtFilt.Fs;
                num = myWinLen/dt; %Translate 2 samples.
                if num > length(mySign)
                    warning('Range exceeds a signal length.');
                   num = length(mySign) ;
                end
                num = round(num);
                return;
            end
            %First num - periods number, the second is optional, it assigns min freq.
            if strfind(myWinLen, 'maxPer')
                myWinLen = strrep(myWinLen, 'maxPer', '');
                myWinLen = str2num(myWinLen);
                minFr = str2num(mySpKurtFilt.config.minSensorFreq);
                if numel(myWinLen) == 2
                    minFr = myWinLen(2); myWinLen = myWinLen(1);
                end
                maxPer = 1/minFr(1, 1);
                myWinLen = myWinLen*maxPer; %Translate 2 seconds.
                myWinLen = [num2str(myWinLen) 'sec'];
                num = getSamplesNum(mySpKurtFilt, myWinLen, mySign);
                return;
            end
            %Else - assigned in samples.
            num = str2double(myWinLen);
            if num > length(mySign)
                warning('Window exceeds a signal length.');
               num = length(mySign) ;
            end
        end

    end
    
    methods (Access = protected)
        
        function savePic(mySpKurtFilt, picName)
            myFigure = gcf;
%             fontSize = str2double(mySpKurtFilt.config.plots.fontSize);
%             imageFormat = mySpKurtFilt.config.plots.imageFormat;
%             imageQuality = mySpKurtFilt.config.plots.imageQuality;
%             imageResolution = mySpKurtFilt.config.plots.imageResolution;
%             myAxes = myFigure.CurrentAxes; % Get axes data
%             myAxes.FontSize = fontSize; % Set axes font size
            if ~str2double(mySpKurtFilt.config.printPlotsEnable)
               return; 
            end
            myForms = mySpKurtFilt.config.formats;
            myForms = strsplit(myForms);
            for i = 1:numel(myForms)
                plotName = [picName '.' myForms{i}];
%                 if strcmp(myForms{i}, mySpKurtFilt.config.plots.imageFormat) %Process such way not debugging images.
%                     print( myFigure, fullfile(pwd, 'Out', plotName), ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
%                 else
                    saveas( myFigure, fullfile(pwd, 'Out', plotName), myForms{i} );
%                 end
            end
        end
        
        % CREATESCALES function creates 2 types of scale arrays :
        % logarithmic (with basis of 2) or linear (with specific step)
        function [frequencies, ranges] = createScales(mySpKurtFilt)
            
            myConfig = mySpKurtFilt.config;
            scaleType = myConfig.scaleType;
            sensorHighFrequency = str2double(myConfig.maxSensorFreq);
            sensorLowFrequency = str2double(myConfig.minSensorFreq);
            df = mySpKurtFilt.Fs/length(mySpKurtFilt.signalOrig);
            F = 0:df:mySpKurtFilt.Fs/2-df; FidVect = 1:numel(mySpKurtFilt.signalOrig);
            
            switch (scaleType)
                % Use logarithmic scale
                case 'log2'
                    parameters = myConfig.log2.Attributes;
                    lowFrequency = str2double(parameters.lowFrequency);
                    if isnan(lowFrequency), lowFrequency = sensorLowFrequency; end
                    highFrequency = str2double(parameters.highFrequency);
                    if isnan(highFrequency), highFrequency = sensorHighFrequency; end
                    switch(parameters.frequenciesPerOctave) %Translate from relative units.
                        case '1 octave'
                            frequenciesPerOctave = 1;
                        case '1/3 octave'
                            frequenciesPerOctave = 3;
                        case '1/6 octave'
                            frequenciesPerOctave = 6;
                        case '1/12 octave'
                            frequenciesPerOctave = 6;
                        otherwise
                            frequenciesPerOctave = str2double(parameters.frequenciesPerOctave);
                    end
                    roundingEnable = str2double(parameters.roundingEnable);
                    
                    if highFrequency > sensorHighFrequency
                        warning('Scalogram ''highFrequency'' in config.xml is greater than sensor ''highFrequency'''); 
                        highFrequency = sensorHighFrequency;
                    end
                    
                    frequencies  = quadraspace(lowFrequency, highFrequency, frequenciesPerOctave, roundingEnable, 'pointsPerOctave');
                    
                    positions = round(frequencies/df);
                    lowPosition = reshape(positions(1,1:end-1), [], 1);
                    highPosition = reshape(positions(1,2:end), [], 1);
                    ranges = [lowPosition highPosition];
                    
                % Use linear scale
                case 'linear'
                    parameters = myConfig.linear.Attributes;
                    lowFrequency = str2double(parameters.lowFrequency);
                    if isnan(lowFrequency), lowFrequency = sensorLowFrequency; end
                    highFrequency = str2double(parameters.highFrequency);
                    if isnan(highFrequency), highFrequency = sensorHighFrequency; end
                    if highFrequency > sensorHighFrequency
                        warning('Scalogram ''highFrequency'' in config.xml is greater than sensor ''highFrequency'''); 
                        highFrequency = sensorHighFrequency;
                    end
                    frequencyStep = str2double(parameters.frequencyStep);
                    windOverlapPercent = str2double(parameters.windOverlapPercent);
                    frequenciesNumber = floor((highFrequency-lowFrequency)/df);
                    freqsPerFrame = floor(frequencyStep/df);
                    
                    if isempty(windOverlapPercent)
                        windOverlapPercent = 0;
                    end
                    
                % Create matrix of overlapping frequency ranges. 
                freqsOverlap = floor(windOverlapPercent*freqsPerFrame/100);
                framesNumber = floor((frequenciesNumber-freqsPerFrame)/(freqsPerFrame-freqsOverlap));
                freqIdxsMatrix = zeros(framesNumber, freqsPerFrame);
                increment = freqsPerFrame - freqsOverlap;
                startPosition = 1;

                FidVect = reshape(FidVect, [], 1);
                for i=1:1:framesNumber
                   freqIdxsMatrix(i,:) = FidVect(startPosition:startPosition+freqsPerFrame-1,1);
                   startPosition = startPosition + increment;
                end
%                     frequenciesNumber = frequenciesNumber*(1-windOverlapPercent);
%                     
%                     frequencies = linspace(lowFrequency, highFrequency, frequenciesNumber);
                ranges = [freqIdxsMatrix(:, 1) freqIdxsMatrix(:, end)]; %Rows are ranges.
                fr = arrayfun(@(x) ranges(x, :), 1:size(ranges, 1), 'UniformOutput', false);
                frequencies = F(horzcat(fr{:})); %Stand all border frequencies one-by-one.
                    
                otherwise
                    error(['ERROR! There no such scaleType: ', scaleType, ' to build spectral kurtosis!']);
            end
        end
        
        %Function getFiltRanges returns range including bands where SK bigger threshold.
        function [rangesSam, rangesF] = getFiltRanges(mySpKurtFilt, methodSK)
            if ~nnz(mySpKurtFilt.(methodSK).indexes)
                rangesSam = []; rangesF = []; return;
            end
            ranges = takeOneByOneBands(double(~mySpKurtFilt.(methodSK).indexes), struct('succession', 'zero'));
            rangesSam = [];
            %Get the first and the last bands limits in each range, then get only end borders.
            for i = 1:numel(ranges)
                dataCell = [mySpKurtFilt.(methodSK).range{ranges{i}(1)}; mySpKurtFilt.(methodSK).range{ranges{i}(2)}];
                rg = [dataCell(1, 1) dataCell(2, 2)];
                rangesSam = [rangesSam; rg];
            end
            df = mySpKurtFilt.Fs/length(mySpKurtFilt.signalOrig); F = 0:df:mySpKurtFilt.Fs/2-df;
            rangesF = F(rangesSam); centralFreqs = mean(rangesF, 2);
            %Find narrow and close ranges. Exclude narrows, unite closes.
            closeIdxs = diff(centralFreqs) < 500; closeIdxs = [0; closeIdxs]; %Idxs of freqs close to previous.
            closeRanges = takeOneByOneBands(double(~closeIdxs), struct('succession', 'zero'));
            singIdxs = cellfun(@(x) ~logical(x(2) - x(1)), closeRanges); closeRanges = closeRanges(~singIdxs); %Exclude singles.
            %Take one-by-one closes: low border of the first, high border of the last.
            for i = 1:numel(closeRanges)
                dataCell = [rangesSam(closeRanges{i}(1), :); rangesSam(closeRanges{i}(2), :)];
                rg = [dataCell(1, 1) dataCell(2, 2)];
                rangesSam = [rangesSam; rg];
            end
            rangesF = F(rangesSam); bandwidths = diff(rangesF, 1, 2); narrowIdxs = bandwidths < 250;
            rangesSam = rangesSam(~narrowIdxs, :); rangesF = F(rangesSam);
            rangesSam = arrayfun(@(x) rangesSam(x, :), 1:size(rangesSam, 1), 'UniformOutput', false);
            if ~isempty(rangesSam)
                rangesF = arrayfun(@(x) rangesF(x, :), 1:size(rangesSam, 1), 'UniformOutput', false);
            end
        end
        
        %Function divides wide range by global minimums.
        function [dividedRangesSam, dividedRangesF] = divideWindows(mySpKurtFilt, methodSK)
            SKminFindVect = -mySpKurtFilt.(methodSK).kurtosVect+max(mySpKurtFilt.(methodSK).kurtosVect);
            ranges = takeOneByOneBands(double(~mySpKurtFilt.(methodSK).indexes), struct('succession', 'zero'));
            dividedRangesSam = []; Idxs = 1:numel(SKminFindVect);
            for i = 1:numel(mySpKurtFilt.(methodSK).range)  %(ranges)
                theCurrKurtVect = SKminFindVect(mySpKurtFilt.(methodSK).range{i}(1):mySpKurtFilt.(methodSK).range{i}(2));   %(ranges{i}(1):ranges{i}(2))
                [pks, locs, ~, proms] = findpeaks(theCurrKurtVect);
                %Find indxs of valid (prominent) peaks, take indexes of according sample in
                %signal by translating window indexes to signal idxs.
                currWindIdxs = Idxs(mySpKurtFilt.(methodSK).range{i}(1):mySpKurtFilt.(methodSK).range{i}(2));
                locs = currWindIdxs(locs); goodIdxs = proms./pks > 0.3; divLocs = locs(goodIdxs);
                if isempty(divLocs), continue; end
                divLocs = [mySpKurtFilt.(methodSK).range{i}(1) divLocs mySpKurtFilt.(methodSK).range{i}(2)];
                lowPosition = reshape(divLocs(1,1:end-1), [], 1);
                highPosition = reshape(divLocs(1,2:end), [], 1);
                dividedRangesSam = [dividedRangesSam arrayfun(@(x, y) [x y], lowPosition', highPosition', 'UniformOutput', false)];
            end
            df = mySpKurtFilt.Fs/length(mySpKurtFilt.signalOrig); F = 0:df:mySpKurtFilt.Fs/2-df;
            dividedRangesF = F(cell2mat(dividedRangesSam')); bandwidths = diff(dividedRangesF, 1, 2); narrowIdxs = bandwidths < 250;
            dividedRangesSam = dividedRangesSam(~narrowIdxs); dividedRangesF = F(cell2mat(dividedRangesSam'));
            %dividedRangesSam = arrayfun(@(x) dividedRangesSam(x, :), 1:numel(ranges), 'UniformOutput', false);
            dividedRangesF = arrayfun(@(x) dividedRangesF(x, :), 1:numel(dividedRangesSam), 'UniformOutput', false);
        end
        
        
    end
    
    methods(Access = protected, Static = true)
        
        function myRes = emptyResult
            myRes.kurtosis = []; %Kurtosis of each filtered signal.
            myRes.kurtosVect = []; %Vector of SK length with of signal.
            myRes.frequencies = []; %Central freqs of each filtered signal.
            myRes.filtedSignals = []; %Filtered signals.
            myRes.range = []; %Spectral ranges of each filtered signal.
            myRes.indexes = []; %Indexes of valid spectral frames.
            myRes.label =[]; %Labels of filtered signals gotten different way.
        end
        
    end
end