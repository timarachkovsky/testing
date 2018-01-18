classdef sparseDecomposer
    %SPARSEDECOMPOSER Summary of this class goes here
    
    properties (Access = public)
        
        % Time-domain singal and its sample frequency
        signal
        Fs
        
        % Scalogram Data
        frequencies
        scales
        energyContribution
        
        lowFrequency
        highFrequency
        
        % The nearest distance between 2 basis function frequencies
        basisStep
        
        config
        plotEnable 
        plotVisible
        printPlotsEnable
%         % Wavelet functions central frequency (resonant frequency)
%         resonantFrequency
        
        % @shortSignal is gotten from the original @signal and is used to
        % speed-up estimation of the optimal iterations number 
        shortSignal
        % The set of basis functions (wavelets) for swd
        basis
        % The set of multi type basis functions for swd
        multiBasis
        multiBasisConfig
        % The set of functions contain only one type of wavelet
        monoBasis
        monoBasisConfig
        
        waveletResonantFrequency
        iterationsPerSecond
        % Tag 
        basisTags
        
        
        interpolationFactor  % Factor for rms graphs evaluation for calculation of the iterationsNumber
        
        
        % Measurement result of the decomposition process (i.e. structure
        % containing the point of intersection of the decomposition curves
        % (e.g. points of intersection of the rms_restored and rms_residue 
        % curves)
        measurementResult
        % Iterations number for optimal sparse decomposition (value
        % calculating based on kurtosis)
        optimalIterationsNumber
        iterationsNumber
        % Type of input signal (pulse,continuous,noisy or unknown)
        signalType
        
    end
    
    methods (Access = public)
        
        % Constructor method
        function [myDecomposer] = sparseDecomposer(file, myConfig)
           
            if nargin < 2 
               myConfig = []; 
            end

            myDecomposer.signal = myDecomposer.preFiltering(file, myConfig);
            myDecomposer.Fs = file.Fs;
            myDecomposer.frequencies = single( file.frequencies);
            myDecomposer.scales = single( file.scales);
            myDecomposer.energyContribution = single( file.energyContribution);
            
            myDecomposer.lowFrequency = single( file.lowFrequency);
            myDecomposer.highFrequency = single( file.highFrequency);
            
            myDecomposer.config = myConfig;
            myDecomposer.plotEnable = str2double(myConfig.Attributes.plotEnable);
            myDecomposer.plotVisible = myConfig.Attributes.plotVisible;
            myDecomposer.printPlotsEnable = str2double(myConfig.Attributes.printPlotsEnable);

            myDecomposer.basisStep = single( file.basisStep);
            
%             myDecomposer.multiBasisConfig.waveletType = {'mexh_morl2'; 'gabor'; 'sin3'};
%             myDecomposer.multiBasisConfig.formFactor = {[0.9291    2.1969    4.5960   10.0184]; [0.4537    1.9022    7.8005   30.2333]; [0.6378    1.4457    2.8904    5.7514]};
%             myDecomposer.monoBasisConfig.waveletType = {'mexh_morl2'; 'gabor'; 'sin3'};
%             myDecomposer.monoBasisConfig.formFactor = {0.9291; 0.4537; 0.6378};

            myDecomposer.multiBasisConfig.waveletType = {'swd_mexh_morl'; 'swd_gabor'; 'swd_sin'};
            myDecomposer.multiBasisConfig.formFactor = {[0.9380,  2.1451, 3.3971, 4.6591, 5.8862, 7.0783, 8.2855, 9.5325, 10.7995, 12.0415, 13.2486,14.5456, 15.8574, 17.2691, 18.7406, 20.4914];...
                                                        [0.4946, 2.0172, 4.4235, 7.8233, 12.2216, 17.1091, 22.9701, 30.2240, 38.6111, 48.2264, 58.1761, 68.6900, 80.1324, 92.9678, 107.5903, 122.9767];...
                                                        [0.6623, 1.3888, 2.1104, 2.8269, 3.5485	, 4.2700, 4.9916, 5.7132, 6.4447, 7.1662, 7.8878, 8.6143, 9.3309, 10.0524, 10.7591, 11.4707]};
            myDecomposer.monoBasisConfig.waveletType = {'swd_mexh_morl'; 'swd_gabor'; 'swd_sin'};
            myDecomposer.monoBasisConfig.formFactor = {0.9380; 0.4946; 0.6623};

            
            myDecomposer.waveletResonantFrequency = 1000;
%             myDecomposer.iterationsPerSecond = round(myDecomposer.Fs/10);
            myDecomposer.iterationsPerSecond = 10000;
            myDecomposer.interpolationFactor = 1000;
            
            myDecomposer = createBasis(myDecomposer);
            myDecomposer = createMonoBasis(myDecomposer);
            myDecomposer = createMultiBasis(myDecomposer);
            
            % Create short signal to speed-up estimation of the optimal 
            % iterations number
            if str2double(myConfig.Attributes.shortSignalEnable)
                parameters = [];
                parameters = myConfig.shortSignal.Attributes;
                parameters.mono = myConfig.shortSignal.mono.Attributes;
                parameters.multi = myConfig.shortSignal.multi.Attributes;
                myDecomposer.shortSignal = createShortSignal(file,parameters);
            else
                 myDecomposer.shortSignal = myDecomposer.signal;
            end
            
            [myDecomposer] = estimateSignalTypeAndIterationsNumber(myDecomposer);
        end
        
        % Getters / Setters ...
        function [mySignal] = getSignal(myDecomposer)
           mySignal =  myDecomposer.signal;
        end
        function [myDecomposer] = setSignal(myDecomposer, mySignal)
           myDecomposer.signal = mySignal; 
        end
        
        function [myFs] = getFs(myDecomposer)
           myFs =  myDecomposer.Fs;
        end
        function [myDecomposer] = setFs(myDecomposer, myFs)
           myDecomposer.Fs = myFs; 
        end
        
        function [myFrequencies] = getFrequencies(myDecomposer)
           myFrequencies =  myDecomposer.frequencies;
        end
        function [myDecomposer] = setFrequencies(myDecomposer, myFrequencies)
           myDecomposer.frequencies = myFrequencies; 
        end
        
        function [myConfig] = getConfig(myDecomposer)
           myConfig =  myDecomposer.config;
        end
        function [myDecomposer] = setConfig(myDecomposer, myConfig)
           myDecomposer.config= myConfig; 
        end
        
        function [mySignalType] = getSignalType(myDecomposer)
           mySignalType =  myDecomposer.signalType;
        end
        
        function [myMeasurementResult] = getMeasurementResult(myDecomposer)
            myMeasurementResult = myDecomposer.measurementResult;
        end
        
        function [myIterationsNumber] = getOptimalIterationsNumber(myDecomposer)
           myIterationsNumber =  myDecomposer.optimalIterationsNumber;
        end
        % ... Getters / Setters
        
        function [myBasis] = getBasis(myDecomposer)
           myBasis =  myDecomposer.basis;
        end
        
        function [myMonoBasis] = getMonoBasis(myDecomposer)
           myMonoBasis =  myDecomposer.monoBasis;
        end
        
        function [myMultiBasis] = getMultiBasis(myDecomposer)
           myMultiBasis =  myDecomposer.multiBasis;
        end
        
        % GETOPTIMALITARATIONSNUMBER function impletents sparse
        % decomposition over the several numbers of iterations, checks
        % kurtosis value of the results by interpolating the form of the 
        % kurtosis graph. An analysis of the kurtosis curve yields an 
        % number of optimal iterations .
        function [myDecomposer] = estimateSignalTypeAndIterationsNumber(myDecomposer)
            
            % Main configuration parameters
%             myConfig = myDecomposer.config;
            file.signal = myDecomposer.shortSignal;
            file.Fs = myDecomposer.Fs;
            
            myBasis = myDecomposer.multiBasis.basis;
            
%             parfor i = 1:1:length(myDecomposer.frequencies)
            for i = 1:1:length(myDecomposer.frequencies)
                file.basis = myBasis{i,1};

                % TEST configuration
                parameters.measurementEnable = '1';
                
%                 iConfig.interpolationFactor = '10';
                parameters.interpolationFactor = num2str(myDecomposer.interpolationFactor);
                parameters.plotEnable = num2str(myDecomposer.plotEnable);
                parameters.printPlotsEnable = num2str(myDecomposer.printPlotsEnable);
                parameters.plotVisible = myDecomposer.plotVisible;
                
                parameters.maxIterationsNumber = num2str(myDecomposer.iterationsPerSecond);
                [~,~,~,~,measurements] = decomposition(file,parameters);
                
                % Find optimal iterations for pattern extraction and signal
                % type
                signalId = num2str(i); % variable for saving images
                [myDetector] = signalTypeDetector(measurements, [], parameters, signalId);
                mySignalType{i,1} = getSignalType(myDetector);
%                 patternOptIterationsNumber{i,1} = getOptimalIterationsNumber(myDetector);
                
                myIterationsNumber{i,1} = calculateIterationsNumber(myDecomposer, measurements, myDecomposer.energyContribution(i),i);
                myDecomposer.measurementResult{i,1} = getMetrics(myDetector);
                
            end
            
%             % Find optimal interation number for signal filtering
%             parameters = []; parameters = myConfig.optimalIterationsNumber.Attributes;
%             kurtosisVector = measurements.restored.kurtosis';
%             iterationsVector = measurements.iterationsVector';
%             [filtrationOptIterationsNumber] = myDecomposer.kurtosisGraphEvaluation( kurtosisVector,iterationsVector,parameters );
%             
%             % TEST ...
%                 myOptimalIterationsNumber = filtrationOptIterationsNumber;
%             % ... TEST
%             myOptimalIterationsNumber = round(myOptimalIterationsNumber*length(myDecomposer.signal)...
%                                                                    /length(myDecomposer.shortSignal)); 
%             
%             myDecomposer.optimalIterationsNumber = myOptimalIterationsNumber;

            myDecomposer.signalType = mySignalType;
            myDecomposer.iterationsNumber = myIterationsNumber;
        end

        % SPARSEDECOMPOSITION function implenets decomposition over the
        % wavelet basis
%         function [sparseSignals, sparsePeaks, sparseMods, restoredSignal] = sparseDecomposition(myDecomposer)
        function [result] = sparseDecomposition(myDecomposer)
            
            result = [];
            parameters = myDecomposer.config.sparseDecomposition.Attributes;
            if isempty(myDecomposer.iterationsNumber)
               myDecomposer = estimateSignalTypeAndIterationsNumber(myDecomposer);
            end
            
            file.signal = myDecomposer.signal;
            file.Fs = myDecomposer.Fs;
%             file.basis = myDecomposer.multiBasis.basis;
            
            
            myIterationsNumber = myDecomposer.iterationsNumber;
            result = cell(numel(myDecomposer.frequencies),1);
            for i = 1:1:length(myDecomposer.frequencies)
%             parfor i = 1:1:length(myDecomposer.frequencies)
                
                file1 = file;
                filterParameters.lowFrequency = myDecomposer.lowFrequency(i);
                filterParameters.highFrequency = myDecomposer.highFrequency(i);
                file1.signal = myDecomposer.filtering(file,filterParameters);
                
                iterationsNumberVector = myIterationsNumber{i,1}.iterationsNumber;
                
                parameters.iterationsVector = num2str(iterationsNumberVector);
                parameters.signalsNumber = num2str(1);
%                 file.basis = myDecomposer.multiBasis.basis{i,1};
%                 result{i,1} = decompositionN(file, parameters);
                file1.basis = myDecomposer.multiBasis.basis{i,1};
                result{i,1} = decompositionN(file1, parameters);

                
                for j = 1:1:length(result{i,1})
                    result{i,1}(j).rmsPart = myIterationsNumber{i,1}.rmsPart(j);
                end
                
                if myDecomposer.plotEnable == 1
                    iterationsNumberVector = round(iterationsNumberVector);
                    dt = 1/myDecomposer.Fs;
                    t = 0:dt:dt*(size(myDecomposer.signal,1)-1);
                    for j = 1:1:length(result{i,1})
                        figure('Visible',myDecomposer.plotVisible), plot(t,myDecomposer.signal);
                        hold on, plot(t, result{i,1}(j).sparseSignal);
                        xlabel('Time, s');
                        ylabel('Signal, m/s^2');
                        title(['Sparse Signal: scalNo = ',num2str(i),', type = ',myDecomposer.signalType{i,1}, ', part = ', num2str(myIterationsNumber{i,1}.rmsPart(j)), '%, Iterations =',num2str(iterationsNumberVector(j)),]);
                        grid on;
                        
                        if myDecomposer.printPlotsEnable == 1
%                             fileName = ['SparseSignal_iter',num2str(iterationsNumberVector(j)),'_scalNo',num2str(i)];
                            fileName = ['SparseSignal_scalNo',num2str(i), ', part= ',num2str(myIterationsNumber{i,1}.rmsPart(j)), '%'];
                            fullFilePath = fullfile(pwd,'Out');
                            fullFileName = fullfile(fullFilePath,fileName);
                            print(fullFileName,'-djpeg91', '-r180'); 
                        end
                        
                        % Close figure with visibility off
                        if strcmpi(myDecomposer.plotVisible, 'off')
                            close
                        end
                       
                    end
                end
                
            end
             
        end
        
        % CALCULATEITERATIONSNUMBER function 
        function [result] = calculateIterationsNumber(myDecomposer,measurements,myEnergyContribution,scalogramNo)
            
            rmsSignal = rms(myDecomposer.signal);
            rmsFinal = rmsSignal*myEnergyContribution;
            myInterpolationFactor = myDecomposer.interpolationFactor;
            
            % interpolation ...
            rmsVector = measurements.restored.rms;
            rmsVector = myDecomposer.interpolate(rmsVector,myInterpolationFactor);
            
            residueRmsVector = measurements.residue.rms;
            residueRmsVector = myDecomposer.interpolate(residueRmsVector,myInterpolationFactor);
            
            
            lowContribution = 5; highContribution = 99; step = 1; pointsNumber = round((highContribution-lowContribution)/step) + 1;
            energyContributionVector = linspace(lowContribution,highContribution,pointsNumber);
            
            % The intersection are estimated by the formula:
            %      100-x
            % B = ------- * A   , A - restoredRmsCurve; B - residueRmsCurve
            %         x         , x - contribution,%
            
            coefficientsVector = (ones(size(energyContributionVector))*100 - energyContributionVector)./energyContributionVector;            
            
            coefficientsNumber = length(coefficientsVector);
            rmsVectorN = repmat(rmsVector,1,coefficientsNumber).* coefficientsVector;
            
            iterationsVector = measurements.iterationsVector;
            iterationsVector = myDecomposer.interpolate(iterationsVector,myInterpolationFactor);
            
            
            energyContributionVector = energyContributionVector/100;
            intersectionVector = zeros(size(energyContributionVector));
            
            % Find intersections between residue curve and rms curves
            for i = 1:1:coefficientsNumber
                intersectionVector(i) = myDecomposer.findIntersection(rmsVectorN(:,i), residueRmsVector, iterationsVector);
            end
            
            
            % Find 3 value of iterationsNumber: 0.25xEC,0.5xEC,0.75xEC
%             rmsPartVector = [0.25, 0.5, 0.75, 0.85, 0.95];
%             rmsPartVector = [0.65, 0.75, 0.85];
            rmsPartVector = [0.5, 0.6, 0.65, 0.7, 0.75, 0.85];
            currentContributionVector = rmsPartVector*myEnergyContribution;
            coefficientsVectorInterp = myDecomposer.interpolate(coefficientsVector,100);
            energyContributionVectorInterp = myDecomposer.interpolate(energyContributionVector,100);
            
            iterationsNumberVector = zeros(size(rmsPartVector));
            for i = 1:1:length(currentContributionVector)
%                 result(i).rmsPart = rmsPart(i);
                currentContribution = currentContributionVector(i);
%                 result(i).rmsContribution = currentContribution;
                
                lowerPoint = find(energyContributionVector<currentContribution,1,'last');
                higherPoint = find(energyContributionVector>currentContribution,1,'first');
                
                % Estimate iterations number by the analisys of the point 
                % of intersection of the residueRmsVector graph and current 
                % rms value
                if ~intersectionVector(higherPoint)
                    lastPoint = find(intersectionVector,1,'last');
                    iterationsNumberVector(i) = intersectionVector(lastPoint);
                else
                    currentContributionLine = ones(size(energyContributionVectorInterp))*currentContribution;
                    [~,currentPosition] = min(abs(currentContributionLine-energyContributionVectorInterp));
                    currentCoefficient = coefficientsVectorInterp(currentPosition);
                    currentRmsCurve = rmsVector*currentCoefficient;
                    iterationsNumberVector(i) = myDecomposer.findIntersection(currentRmsCurve, residueRmsVector, iterationsVector);
                    if iterationsNumberVector(i) == 0 && i == 1
                        iterationsNumberVector(i) = 1;
                    end
                end 
            end
            
            result.rmsPart = rmsPartVector*100;
            result.rmsContribution = currentContributionVector;
%             result.iterationsNumber = iterationsNumberVector;
            result.iterationsNumber = iterationsNumberVector*length(myDecomposer.signal)/length(myDecomposer.shortSignal);
            
            % Construct an efficiency curve
            diffRmsVector = diff(rmsVector)/rmsFinal*100; % [in percent]
            diffIterationsVector = iterationsVector(2:end);
            
            figure, set(gcf,'color','w','Visible',myDecomposer.plotVisible);
            plot(diffIterationsVector,diffRmsVector);
            
            trueIterationsVector = zeros(size(iterationsVector));
            maxDiff = max(diffRmsVector);
            for i = 1:1:length(result.iterationsNumber)
                mask = (iterationsVector == ones(size(iterationsVector))*result.iterationsNumber(i));
                trueIterationsVector(mask) = maxDiff;
            end
            
            if myDecomposer.plotEnable == 1
                hold on, stem(diffIterationsVector,trueIterationsVector(2:end));
                grid on;
                title(['SWD Efficiency Curve, scalogramPoint = ', num2str(scalogramNo)]);
                xlabel('Iterations Number');
                ylabel('Restored Rms,%');
%                 legend('Efficiency Curve','[0.25, 0.5, 0.75, 0.85, 0.95]xRMS');
%                 legend('Efficiency Curve','[0.65, 0.75, 0.85]xRMS');
%                 legend('Efficiency Curve','[0.5, 0.75, 0.85]xRMS');
                legend('Efficiency Curve','[0.5, 0.6, 0.65, 0.7, 0.75, 0.85]xRMS');
                
                if myDecomposer.printPlotsEnable == 1
                    fileName = ['SWD_Efficiency_Curve_scalNo',num2str(scalogramNo)];
                    fullFilePath = fullfile(pwd,'Out');
                    fullFileName = fullfile(fullFilePath,fileName);
                    print(fullFileName,'-djpeg91', '-r180'); 
                end
                
            end
            
            % Close figure with visibility off
            if strcmpi(myDecomposer.plotVisible, 'off')
                close
            end

            % Plot Results
            if myDecomposer.plotEnable
                figure, set(gcf,'color','w','Visible',myDecomposer.plotVisible);
                plot(iterationsVector,residueRmsVector,'LineWidth',2);
                for i = 1:5:coefficientsNumber
                    hold on, plot(iterationsVector,rmsVectorN(:,i),'--');
                end
                grid on;
                title('Search for iterations number');
                xlabel('Iterations Number');
                ylabel('Rms');
    %             legend('Signal','RMS x0.10','RMS x0.20','RMS x0.30','RMS x0.40','RMS x0.50','RMS x0.60','RMS x0.70','RMS x0.80','RMS x0.90');
                legend('Signal','RMS x0.05','RMS x0.10','RMS x0.15','RMS x0.20','RMS x0.25','RMS x0.30','RMS x0.35','RMS x0.40','RMS x0.45','RMS x0.50','RMS x0.55','RMS x0.60','RMS x0.65','RMS x0.70','RMS x0.75','RMS x0.80','RMS x0.85','RMS x0.90','RMS x0.95');
                
                if myDecomposer.printPlotsEnable == 1
                    fileName = 'SWD_Residue_vs_RMS_curves';
                    fullFilePath = fullfile(pwd,'Out');
                    fullFileName = fullfile(fullFilePath,fileName);
                    print(fullFileName,'-djpeg91', '-r180'); 
                end
                
                % Close figure with visibility off
                if strcmpi(myDecomposer.plotVisible, 'off')
                    close
                end
            
            end
     
        end
    end
    
    methods (Access = private)
        
        % CREATEBASIS function creates wavelet basis consisting of 3
        % signals: 1 central wavelet (with resonant frequency = @frequency)
        % and 2 side wavelets (with resonant frequencise = @frequency +-
        % delta)
        function [myDecomposer] = createBasis(myDecomposer)
               
            if ~isempty(myDecomposer.signalType)
                [mySignalType] = myDecomposer.signalType;
            else
                mySignalType = 'UNKNOWN';
            end
                
           % The main resonant frequency of the mexh_morl wavelet
%             waveletResonantFrequency = 1000;

            % Form the set of frequencies to create wavelet basis
            scalogramFrequencies = myDecomposer.frequencies;
            scalogramFrequenciesNumber = numel(scalogramFrequencies);
            % TEST VERSION:

            switch (scalogramFrequenciesNumber)
                case 1
                    scalogramFrequencies = [1,5,10]*myDecomposer.frequencies;
                case 2
                    maxFrequency = max(myDecomposer.frequencies);
                    scalogramFrequencies = myDecomposer.frequencies;
                    scalogramFrequencies(end+1) = maxFrequency * 5;
                otherwise
                    scalogramFrequencies = myDecomposer.frequencies;
            end

            waveletScales = myDecomposer.waveletResonantFrequency*(scalogramFrequencies.^(-1));
            
            % Choose wavelet basis based on signalType
            switch(mySignalType)
                case {'PULSE','UNKNOWN'} 
                    waveletType = 'mexh_morl';
                case 'CONTINUOUS'
                    waveletType = 'sin2';
                case 'NOISY'
                    waveletType = 'gabor';
                otherwise
                    waveletType = 'mexh_morl';
            end
            
            % Form basis with odd length
%             L = length(mexh_morl(max(waveletScales),myDecomposer.Fs));
            formFactor = 1;
            L = length(feval(waveletType,max(waveletScales),myDecomposer.Fs,formFactor));
            if mod(L,2)==0  
                L = L+1;
            end
            if length(waveletScales)>=3
                myBasis = zeros(length(waveletScales),L)';
            else
                myBasis = zeros(3,L)';
            end

            % Fill empty basis matrix with basis wavelet signals
            for i = 1:1:length(waveletScales)
%                 func = mexh_morl(waveletScales(1,i),myDecomposer.Fs)';
                func = feval(waveletType,waveletScales(1,i),myDecomposer.Fs,formFactor)';
                startPos = ceil(L/2-length(func)/2+1);
                endPos = startPos + length(func)-1;
                myBasis(startPos:endPos,i) = func(:,:);
            end
               
            myDecomposer.basis = myBasis;
        end
         
        % CREATEMULTIBASIS function creates basis with 3 type of wavelet
        % function and with several formFactor coefficients for each type
        function [myDecomposer] = createMultiBasis(myDecomposer)

%             waveletType = {'mexh_morl2'; 'gabor'; 'sin3'};
%             formFactor = {[0.6378    1.4457    2.8904    5.7514]; [0.4537    1.9022    7.8005   30.2333]; [0.6378    1.4457    2.8904    5.7514]};
            waveletType = myDecomposer.multiBasisConfig.waveletType;
            formFactor = myDecomposer.multiBasisConfig.formFactor;

            waveletTypeLength = size(waveletType,1);
            formFactorLength = length(formFactor{1,1});
            % dummy...
%                 formFactorType = {'x1','x2','x4','x8'};
%                 formFactorType = {'1','2','4','8'};
                formFactorType = {'1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16'};
            % ... dummy
            
            
           % The main resonant frequency of the mexh_morl wavelet
%             waveletResonantFrequency = 1000;

            % Form the set of frequencies to create wavelet basis
            scalogramFrequencies = myDecomposer.frequencies;

            waveletScales = myDecomposer.waveletResonantFrequency*(scalogramFrequencies.^(-1));
            scalesNumber = length(waveletScales);
            % Form basis with odd length
            for i = 1:1:scalesNumber
                 basisFuncLength(i) = length(feval(waveletType{1,1},waveletScales(i),myDecomposer.Fs,1));
                 if mod(basisFuncLength(i),2)==0  
                    basisFuncLength(i) = basisFuncLength(i)+1;
                 end
            end
            
            subBasisLength = waveletTypeLength*formFactorLength;
            myBasis = cell(scalesNumber,1);
            basisFuncList = cell(subBasisLength,1);
            % Fill empty basis matrix with basis wavelet signals
            cnt = 1; 
            
            
            for i = 1:1:scalesNumber
                for j = 1:1:waveletTypeLength 
                    for k = 1:1:formFactorLength
                        func = feval(waveletType{j,1},waveletScales(1,i),myDecomposer.Fs,formFactor{j,1}(1,k))';
                        startPos = ceil(basisFuncLength(i)/2-length(func)/2+1);
                        endPos = startPos + length(func)-1;
                        myBasis{i,1}(startPos:endPos,cnt) = func(:,:);
%                         basisFuncList{(j-1)*formFactorLength + k} = [waveletType{j,1},'_',num2str(formFactor{j,1}(1,k))];
                        basisFuncList{(j-1)*formFactorLength + k} = [waveletType{j,1}(5),formFactorType{k}];
                        
                        if cnt == subBasisLength
                            cnt = 1;
                        else
                            cnt = cnt + 1;
                        end
                    end
                end
            end
               
%             % The normalization of the basis in terms of the energy
            for i = 1:1:scalesNumber
                scales = 1./sqrt(sum(myBasis{i,1}.^2));
                myBasis{i,1} = bsxfun(@times,myBasis{i,1},scales);
            end
%             
            myDecomposer.multiBasis.basis = myBasis;
            myDecomposer.multiBasis.waveletType = waveletType;
            myDecomposer.multiBasis.formFactor = formFactor;
            myDecomposer.multiBasis.basisFuncList = basisFuncList;

        end
        
        % CREATEMULTIBASIS function creates basis with 3 type of wavelet
        % function and only one formFactor coefficient for each type
        function [myDecomposer] = createMonoBasis(myDecomposer)
               
%             waveletType = {'mexh_morl2'; 'gabor'; 'sin3'};
%             formFactor = {0.6378; 0.4537; 0.6378};
            waveletType = myDecomposer.monoBasisConfig.waveletType;
            formFactor = myDecomposer.monoBasisConfig.formFactor;            

            waveletTypeLength = size(waveletType,1);
            formFactorLength = length(formFactor{1,1});
            
           % The main resonant frequency of the mexh_morl wavelet
%             waveletResonantFrequency = 1000;

            % Form the set of frequencies to create wavelet basis
            scalogramFrequencies = myDecomposer.frequencies;

            waveletScales = myDecomposer.waveletResonantFrequency*(scalogramFrequencies.^(-1));
            scalesNumber = length(waveletScales);
            % Form basis with odd length
            for i = 1:1:scalesNumber
                 basisFuncLength(i) = length(feval(waveletType{1,1},waveletScales(i),myDecomposer.Fs,1));
                 if mod(basisFuncLength(i),2)==0  
                    basisFuncLength(i) = basisFuncLength(i)+1;
                 end
            end
            
            subBasisLength = waveletTypeLength*formFactorLength;
            myBasis = cell(scalesNumber,1);
            basisFuncList = cell(subBasisLength,1);
            % Fill empty basis matrix with basis wavelet signals
            cnt = 1; 
            
            
            for i = 1:1:scalesNumber
                for j = 1:1:waveletTypeLength 
                    for k = 1:1:formFactorLength
                        func = feval(waveletType{j,1},waveletScales(1,i),myDecomposer.Fs,formFactor{j,1}(1,k))';
                        startPos = ceil(basisFuncLength(i)/2-length(func)/2+1);
                        endPos = startPos + length(func)-1;
                        myBasis{i,1}(startPos:endPos,cnt) = func(:,:);
                        basisFuncList{(j-1)*formFactorLength + k} = [waveletType{j,1},'_',num2str(formFactor{j,1}(1,k))];
                        
                        if cnt == subBasisLength
                            cnt = 1;
                        else
                            cnt = cnt + 1;
                        end
                    end
                end
            end
               
            % The normalization of the basis in terms of the energy
            for i = 1:1:scalesNumber
                scales = 1./sqrt(sum(myBasis{i,1}.^2));
                myBasis{i,1} = bsxfun(@times,myBasis{i,1},scales);
            end
            
            myDecomposer.monoBasis.basis = myBasis;
            myDecomposer.monoBasis.waveletType = waveletType;
            myDecomposer.monoBasis.formFactor = formFactor;
            myDecomposer.monoBasis.basisFuncList = basisFuncList;
            
        end
        
        % RECONSTRUCTMULTISIGNAL function .... 
        function [sparseSignal] = reconstructMultiSignal(myDecomposer, sparsePeaks, basis)
            
            basis = basis';
            signalLength = length(myDecomposer.signal);
            sparseSignalsNumber = length(myDecomposer.frequencies);
            sparseSignal = zeros(signalLength,sparseSignalsNumber);
            [~,basisLength] = size(basis);
            
            % Form subbasis for every resonantFrequency (sparse signal) 
            if ~mod(basisLength,sparseSignalsNumber)
                subBasisLength = basisLength/sparseSignalsNumber;
                for i=1:1:sparseSignalsNumber
                    subBasis = basis(:,subBasisLength*(i-1)+1:subBasisLength*i);
                    subSparsePeaks = sparsePeaks(:,subBasisLength*(i-1)+1:subBasisLength*i);
                    sparseSignal(:,i) = myDecomposer.reconstuctSignal(subSparsePeaks,subBasis,signalLength);
                end
            else
               error('Basis functions number doesn"t fit with sparse singals number');  
               return;
            end
        end
    end
    
    methods (Static = true, Access = private)
        
        % GETITERATIONSNUMBER function is used to calculate kurtosis of
        % sparse decomposed signal (with certain iterations number)
        function [myKurtosis,iterationsNumber,myRms,myResKurtosis,myResRms,myPeakFactor,myResPeakFactor,myCrestFactor,myResCrestFactor,myPeak,myResPeak] = getKurtosisForIterationsNumber(file,maxIterationsNumber,config)
            
            config.maxIterationsNumber = maxIterationsNumber;
            [r,ws] = decomposition(file,config);
            myKurtosis = kurtosis(r); 
            myRms = rms(r);
            residue = file.signal - r;
            myResKurtosis = kurtosis(residue);
            myResRms = rms(residue);
            myPeakFactor = max(abs(r))/myRms;
            myResPeakFactor = max(abs(residue))/myResRms;
            myPeak = max(abs(r));
            myResPeak = max(abs(residue));
            
            % TEST...
            file.signal = r;
            file.Fs =96000;
            % ... TEST
            myCrestFactor = crestFactor(file);
            
            file.signal = residue;
            myResCrestFactor = crestFactor(file);
            
            iterationsNumber = nnz(ws(:));
            
        end
        
        % KURTOSISGRAPHEVALUATION function find on the kurtosis graph the
        % most suitable number of iterations. Optimal kurtosis value is
        % calculated by formula : 
        %           kurtosisOpt = kurtosisVector(end)*kurtosisFactor
        function[optIterationsNumber] = kurtosisGraphEvaluation(kurtosisVector,...
                                                                iterationsVector, config)
            
            % Configuration parameters
            config = fill_struct(config, 'plotEnable', '0');
            config = fill_struct(config, 'plotVisible', 'on');
            config = fill_struct(config, 'percentRange', '1'); % percent
            config = fill_struct(config, 'optimalKurtosisCoef', '1.7'); % seeking value ratio
            config = fill_struct(config, 'interpolationFactor', '100');

            plotEnable = str2double(config.plotEnable);
            percentRange = str2double(config.percentRange);
            optimalKurtosisCoef = str2double(config.optimalKurtosisFactor);
            interpolationFactor = str2double(config.interpolationFactor);
            
            % Calculate optimal kurtosis value and interpolate original 
            % kurtosis vector to find it in the specific range
            optimalKurtosis = kurtosisVector(1,end)*optimalKurtosisCoef;
            kurtosisHigh = optimalKurtosis*(1+percentRange/100);
            kurtosisLow = optimalKurtosis*(1-percentRange/100);
            
            original = 1: length(iterationsVector);
            interpolated = 1: 1/interpolationFactor : length(iterationsVector);
            
            iterationsVector = interp1(original,iterationsVector,interpolated,'pchip');
            kurtosisVector = interp1(original,kurtosisVector,interpolated,'pchip');
            
            % Find the min operations number corresponding to search range
            optimalPosition = min(find(bsxfun(@times, bsxfun(@ge,kurtosisVector,kurtosisLow),...
                                                      bsxfun(@le,kurtosisVector,kurtosisHigh))));
            optIterationsNumber = iterationsVector(1,optimalPosition);
            
            % Plot results
            if plotEnable == 1
                figure('Visible',config.plotVisible),hold on
                plot(iterationsVector, kurtosisVector,'-b');
                stem(iterationsVector(optimalPosition), kurtosisVector(optimalPosition), 'r');
                xlabel('Iterations number');
                ylabel('Kurtosis');
                legend(['Optimal Iterations Number = ' num2str(optIterationsNumber)]);
                title('Optimal SWD Iterations Number');
                set(gcf,'color','w');
                hold off
                
                % Close figure with visibility off
                if strcmpi(config.plotVisible, 'off')
                    close
                end
            
            end
            
        end

        [r,ws] = decomposition(file, config);
        [Result] = decompositionN(file, config)
        [mySignal] = reconstructSignal(sparseSignal, baseFunc, signalLength);
        
    end
    
    methods (Static = true)
        
        function [signal] = preFiltering(file, myConfig)

            myConfig = fill_struct(myConfig, 'lowFrequency', '20');
            myConfig = fill_struct(myConfig, 'Rp', '1');
            myConfig = fill_struct(myConfig, 'Rs', '12');
            
            % Cutting-off low shaft frequencies to simplify wavelet decomposition
            lowFrequency = str2double(myConfig.lowFrequency);
            Rp = str2double(myConfig.Rp);
            Rs = str2double(myConfig.Rs); 
            
            Ws = lowFrequency*(2/file.Fs);
            Wp = lowFrequency*2*(2/file.Fs);  
            [n,Wn] = buttord(Wp,Ws,Rp,Rs);
            [b, a] = butter(n , Wn , 'high');
            signal = filter(b,a,file.signal);
        end
        
        function [signal] = filtering(file, filterParameters)
           
            filterParameters = fill_struct(filterParameters, 'Rp', 1);
            filterParameters = fill_struct(filterParameters, 'Rs', 12);
            
            highFrequency = filterParameters.highFrequency;
            lowFrequency = filterParameters.lowFrequency;
            Rp = filterParameters.Rp;
            Rs = filterParameters.Rs;
            Fs = file.Fs;
            
            Wp = [lowFrequency*2/Fs highFrequency*2/Fs];
            Ws=[(lowFrequency-0.1*lowFrequency)*2/Fs (highFrequency+0.1*highFrequency)*2/Fs]; 
            [~,Wn1] = buttord(Wp,Ws,Rp,Rs);
            [b1,a1] = butter(2 ,Wn1);
            signal = filtfilt(b1,a1,file.signal);
            
        end
        
        function [result] = subSparseDecomposition()
            
        end
        
        % RECONSTUCTSIGNAL function restores sparse signal from sparse peak
        % representation
        function [ signal ] = reconstuctSignal( sparsePeaks, basis, originalLength )
            
            [m,n] = size(basis);
            if n>m
                basis = basis';
            end
            
            [basisFuncLength,basisLength] = size(basis);
            signal = zeros(originalLength+2*basisFuncLength,1);

            for i = 1:1:basisLength
                
                peakPosition = find(sparsePeaks(:,i));
                peakPositionNumber = numel(peakPosition);
                
                for j=1:1:peakPositionNumber
                    signal(peakPosition(j):peakPosition(j)+basisFuncLength-1,1) = signal(peakPosition(j):peakPosition(j)+basisFuncLength-1,1)   +    basis(:,i)*sparsePeaks(peakPosition(j),i);
                end
                
            end

            signal = signal(round(basisFuncLength/2):round(basisFuncLength/2)+originalLength-1)';
        end
        
        % FINDINTERSECTION function returns positions of the intersect
        % points between @vector1 and @vector2
        function [iterationNumber] = findIntersection(vector1, vector2, iterationVector)
            
            differenceVector = vector1 - vector2;
            differenceVector(differenceVector > 0) = 1;
            differenceVector(differenceVector < 0) = -1;
            
            strobeVector = diff([differenceVector; NaN]);
            
            
            iterationNumber = iterationVector((strobeVector ~= 0) & (~isnan(strobeVector)));
            if isempty(iterationNumber)
               iterationNumber = 0; 
            elseif numel(iterationNumber) > 1
                iterationNumber = iterationNumber(1,1);
            end
        end
        
        
        function [vectorInterp] = interpolate(vectorOrigin,interpolationFactor)
            
            vectorLength = length(vectorOrigin);
            arrayOrigin = 1:vectorLength;
            arrayInterp = 1:1/interpolationFactor:vectorLength;
            
            % Main properties spline interpolation
            vectorInterp = interp1( arrayOrigin, vectorOrigin, arrayInterp, 'spline')';
            
        end
        
        
    end
end

