classdef patternExtractor
    %PATTERNEXTRACTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        
        % Configuration
        plotEnable  % 1/0f
        plotVisible % on/off
        plotTitle % on/off
        printPlotsEnable  % 1/0
        debugModeEnable   % 1/0
        saveDataEnable  % 1/0   Enable to save .mat files for cl. training 
        id
        
        plotParameters
        translations
        
        % Input:
        waveletType
        waveletCentralFrequency
        resonantFrequency   % Frequency from scalogram (~1/T0)
        periodFrequency     % The main frequency of the signal (~1/Tp)
        
        basis
        
        % A structure containing the results of three stages: rough, normal, accurate. 
        % decomposition (0.6rms, 0.75rms, 0.9 rms)
        swdData 
        
        signal
		Fs
        
		BFSpectrum 
		
        % Device:
        deviceType % bearingShaft, gearing, shaft, belting and etc
        
        % Configuration: 
        patternNumber
        patternPeakThreshold
        
        % Output:
        patternTable
        equipmentData
        basicWavelet
%         pattern
    end
    
    methods (Access = public)
        
        function [myExtractor] = patternExtractor(file, parameters)
            
            % Initialization ...
            myExtractor.plotEnable = str2double(parameters.Attributes.plotEnable);
            myExtractor.plotVisible = parameters.Attributes.plotVisible;
            myExtractor.plotTitle = parameters.Attributes.plotTitle;
            myExtractor.printPlotsEnable = str2double(parameters.Attributes.printPlotsEnable);
            myExtractor.debugModeEnable = str2double(parameters.Attributes.debugModeEnable);
            myExtractor.saveDataEnable = str2double(parameters.Attributes.saveTrainingDataEnable);
            myExtractor.id = parameters.id;
            
            myExtractor.translations = parameters.translations;
            myExtractor.plotParameters = parameters.plots;
            
            myExtractor.resonantFrequency = file.resonantFrequency;
            
            myExtractor.basis = file.basis;
            myExtractor.swdData = file.swdData;
            
            myExtractor.signal = file.signal;
            myExtractor.Fs = file.Fs;
            
            if isempty(file.periodFrequency)
                myExtractor.periodFrequency = inf;
            else
                myExtractor.periodFrequency = file.periodFrequency;
            end
            myExtractor.patternNumber = 500;
            myExtractor.patternPeakThreshold = 0.1;
            
%             [myExtractor] = createBasicWavelet(myExtractor);
        end
                
        function [myPatternData] = getPatternData(myExtractor)
           [myPatternData] = myExtractor.patternTable; 
        end
        
        function [myEquipmentData] = getEquipmentData(myExtractor)
            [myEquipmentData] = myExtractor.equipmentData;
        end
        
        % SELECTPATTERN function ...
        function [myExtractor] = selectPattern(myExtractor)
                
            tags = {'major', 'rough', 'accurate'};
            patternFramesData = cell(size(tags));
            for i = 1:numel(tags)
                patternFramesData{i} = findPatternFramesNew(myExtractor,tags{i});
            end
            patternFramesData = cell2mat(patternFramesData);
            
            [ myExtractor ] = createPatternTable(myExtractor,patternFramesData);
            [ myExtractor ] = fillInPatternTable(myExtractor);
            myPatternTable = myExtractor.patternTable;
            
            if myExtractor.debugModeEnable && myExtractor.saveDataEnable
                filepath = fullfile(pwd,'Out',['PATTERNs_SVM_data',myExtractor.id,'.mat']);
                save(filepath,'myPatternTable');
            end

            
%             if myExtractor.plotEnable && myExtractor.debugModeEnable
%                 
%                 dt = 1/myExtractor.Fs;
%                 t = 0:dt:dt*(length(patternFramesData(1).patternFramesMask)-1);
%                 
%                 figure,set(gcf,'color','w','Visible',myExtractor.plotVisible);
%                 plot(t,patternFramesData(1).patternFramesMask);
%                 hold on, plot(t,patternFramesData(2).patternFramesMask*1.5)
%                 hold on, plot(t,patternFramesData(3).patternFramesMask*2.0)                
%                 ylabel('Pattern Frames');
%                 xlabel('Time, s');
%                 ylim([0 2.5]);
%                 legend({'Pattern60','Pattern75','Pattern90'});
%                 title(['Pattern Frames, scalNo = ', myExtractor.id]);
%                
%                 if myExtractor.printPlotsEnable == 1
%                     fileName = ['PatternPositions_scalNo',myExtractor.id];
%                     fullFilePath = fullfile(pwd,'Out');
%                     fullFileName = fullfile(fullFilePath,fileName);
%                     print(fullFileName,'-djpeg91', '-r180');
%                 end
% 
%                 if strcmpi(myExtractor.plotVisible, 'off')
%                     close
%                 end
% 
%             end
            
			
			[myExtractor] = calculateEquipmentParameters(myExtractor);
			
        end
 
        function [Result] = calculateSWDParameters(myExtractor, data)
            
            BF = myExtractor.basis.basisFuncList; %basis functions list
            BFTypes = myExtractor.basis.waveletType;
            BFTypesNumber = length(BFTypes);
            FFNumber = numel(BF)/BFTypesNumber; % the number of formFactor coefficients per 1 type of basis function 
            if ~mod(FFNumber,2)
                shortFFNumber = FFNumber/2;
            else
                shortFFNumber = (FFNumber+1)/2;
            end
            
            BFDurationTypes = [{'short'};{'average'};{'long'};{'continuous'}];
            durationNum = FFNumber/numel(BFDurationTypes);

            mySparseModes = data.sparseModes;
            mySparsePeaks = data.sparsePeaks;
            mySparseSignal = data.sparseSignal;

            
            sparseModesEnergy = sum((mySparseModes).^2,1);
            sparseSignalEnergy = sum((mySparseSignal).^2,1);
            
            BFModesEnergy = sparseModesEnergy/sparseSignalEnergy;
            
            
            BFModesEnergy = BFModesEnergy/sum(BFModesEnergy)*100;
            BFModesEnergy(BFModesEnergy<0.5) = 0;
            
            BFModesIntensity = sum(abs(mySparsePeaks)>0,1);
            BFModesEfficiency = BFModesEnergy./BFModesIntensity;
            
            nanVector = isnan(BFModesEfficiency);
            BFModesEfficiency(nanVector) = 0;
            
            modesNumber = size(mySparseModes,2);
            
            BFTypeEnergy = zeros(1,BFTypesNumber); %Energy distribution with respect of basis functions
            BFTypeIntensity = zeros(1,BFTypesNumber); %Distribution of response intensity with respect of basis functions
            BFTypeEfficiency = zeros(1,BFTypesNumber); % Efficiency of SWD with respect of the type of basis functions

%             BFDurationEnergy = zeros(1,FFNumber); %Energy distribution with respect of duration of basis functions 
%             BFDurationIntensity = zeros(1,FFNumber); %Distribution of response intensity with respect of duration of basis functions
%             BFDurationEfficiency = zeros(1,FFNumber); % Efficiency of SWD with respect of duration of basis functions

            BFDurationEnergy = zeros(1,numel(BFDurationTypes)); %Energy distribution with respect of duration of basis functions 
            BFDurationIntensity = zeros(1,numel(BFDurationTypes)); %Distribution of response intensity with respect of duration of basis functions
            BFDurationEfficiency = zeros(1,numel(BFDurationTypes)); % Efficiency of SWD with respect of duration of basis functions

           
            for i = 1:1:modesNumber

                BFTypeEnergy(1, ceil(i/FFNumber)) = BFTypeEnergy(1, ceil(i/FFNumber)) + BFModesEnergy(i);
                BFTypeIntensity(1, ceil(i/FFNumber)) = BFTypeIntensity(1, ceil(i/FFNumber)) + BFModesIntensity(i);
                BFTypeEfficiency(1, ceil(i/FFNumber)) = BFTypeEfficiency(1, ceil(i/FFNumber)) + BFModesEfficiency(i);

%                 idx = mod(i,FFNumber);
                idx = ceil(floor(i/durationNum) + mod(i,durationNum)/10);
                if idx == 0
                    idx = durationNum;
                end

                idx = mod(idx,durationNum);
                if idx == 0
                   idx = durationNum; 
                end
                
                BFDurationEnergy(1,idx) = BFDurationEnergy(1,idx) + BFModesEnergy(i);
                BFDurationIntensity(1,idx) = BFDurationIntensity(1,idx) + BFModesIntensity(i);
                BFDurationEfficiency(1,idx) = BFDurationEfficiency(1,idx) + BFModesEfficiency(i);
            end
                
%             if myExtractor.plotEnable == 1
%                 figure, set(gcf,'color','w','Position',[0 ,0 ,1605,1080],'Visible',myExtractor.plotVisible);
%                 subplot(modesNumber,1,1), title (['Sparse Wavelet Modes, scalNo = ',myExtractor.id,', part=',num2str(data.rmsPart),'%'])
%                 
%                 for i = 1:1:modesNumber
%                     subplot(modesNumber,1,i), plot(mySparseModes(:,i));
%                     ylabel(BF{i,1});
%                     set(gca,'FontSize',5);
%                 end
%                 
%                 if myExtractor.printPlotsEnable
%                     
%                     fileName = ['SparseModes_scalNo',myExtractor.id, ', part=',num2str(data.rmsPart),'%'];
%                     fullFilePath = fullfile(pwd,'Out');
%                     fullFileName = fullfile(fullFilePath,fileName);
%                     print(fullFileName,'-djpeg91', '-r180');
%                 end
%
%                 if strcmpi(myExtractor.plotVisible, 'off')
%                     close
%                 end
%
%             end
            
            BFTypeEnergy = BFTypeEnergy/sum(BFTypeEnergy)*100;
            BFTypeEfficiency = BFTypeEfficiency/sum(BFTypeEfficiency)*100;
            
            BFDurationEnergy = BFDurationEnergy/sum(BFDurationEnergy)*100;
            BFDurationEfficiency = BFDurationEfficiency/sum(BFDurationEfficiency)*100;
            
            if ~nnz(isnan([BFTypeEnergy,BFTypeIntensity,BFTypeEfficiency,BFModesEnergy,BFModesIntensity,BFModesEfficiency])) || ~nnz(isinf([BFModesEnergy,BFModesIntensity,BFModesEfficiency]))
            
                % fill swdData structure...
                Result.BFModesEnergy = BFModesEnergy/sum(BFModesEnergy)*100;
%                 Result.BFModesIntensity = BFModesIntensity/sum(BFModesIntensity)*100;
                Result.BFModesIntensity = BFModesIntensity;
                Result.BFModesEfficiency = BFModesEfficiency/sum(BFModesEfficiency)*100;

                Result.BFTypeEnergy = BFTypeEnergy;
                Result.BFTypeIntensity = BFTypeIntensity;
                Result.BFTypeEfficiency = BFTypeEfficiency;

                Result.BFDurationEnergy = BFDurationEnergy;
                Result.BFDurationIntensity = BFDurationIntensity;
                Result.BFDurationEfficiency = BFDurationEfficiency;
            else
                Result = [];
            end
                
            % ... fill swdData structure
            
            if myExtractor.plotEnable == 1 && myExtractor.debugModeEnable
                
                figure,set(gcf,'color','w','Position',[0 ,0 ,1605,1080],'Visible',myExtractor.plotVisible); 
                subplot(3,1,1), bar(BFModesEnergy);
                title(['Wavelet Basis Distribution, scalNo = ',myExtractor.id,', rmsPart = ',num2str(data.rmsPart),'%']);

%                 xticklabels(BF);
                set(gca,'XTick',[1:1:numel(BF)]);
                set(gca,'XTickLabel',BF);

                ylabel('Energy Contribution,%');
                subplot(3,1,2), bar(BFModesIntensity);
%                 xticklabels(BF);
                set(gca,'XTick',[1:1:numel(BF)]);
                set(gca,'XTickLabel',BF);
                ylabel('Total Sparse Peaks Number');
                subplot(3,1,3), bar(BFModesEfficiency);
%                 xticklabels(BF);
                set(gca,'XTick',[1:1:numel(BF)]);
                set(gca,'XTickLabel',BF);
                ylabel('EnergyPerPeak,%');
                
                if myExtractor.printPlotsEnable
                    fileName = ['PatternParam1_scalNo',myExtractor.id, ', part=',num2str(data.rmsPart),'%'];
                    fullFilePath = fullfile(pwd,'Out');
                    fullFileName = fullfile(fullFilePath,fileName);
                    print(fullFileName,'-djpeg91', '-r180');
                end
                
                if strcmpi(myExtractor.plotVisible, 'off')
                    close
                end
            
                figure,set(gcf,'color','w','Visible',myExtractor.plotVisible);
                subplot(3,1,1), bar(BFTypeEnergy);
                title(['Wavelet Type Distribution, scalNo = ',myExtractor.id,', rmsPart = ',num2str(data.rmsPart),'%']);
                ylabel('Energy Contribution,%');
                xticklabels(BFTypes);
                subplot(3,1,2), bar(BFTypeIntensity);
                ylabel('BF Intensity,%');
                xticklabels(BFTypes);
                subplot(3,1,3), bar(BFTypeEfficiency);
                ylabel('BF Efficiency,%/unit');
                xticklabels(BFTypes);
                
                if myExtractor.printPlotsEnable
                    fileName = ['PatternParam2_scalNo',myExtractor.id, ', part=',num2str(data.rmsPart),'%'];
                    fullFilePath = fullfile(pwd,'Out');
                    fullFileName = fullfile(fullFilePath,fileName);
                    print(fullFileName,'-djpeg91', '-r180');
                end
                
                if strcmpi(myExtractor.plotVisible, 'off')
                    close
                end
                
                figure,set(gcf,'color','w','Visible',myExtractor.plotVisible);
                subplot(3,1,1), bar(BFDurationEnergy);
                title(['Wavelet Length Distribution, scalNo = ',myExtractor.id,', rmsPart = ',num2str(data.rmsPart),'%']);
                ylabel('Energy Contribution,%');
                xticklabels(BFDurationTypes);
                subplot(3,1,2), bar(BFDurationIntensity);
                ylabel('BF Intensity,%');
                xticklabels(BFDurationTypes);
                subplot(3,1,3), bar(BFDurationEfficiency);
                ylabel('BF Efficiency,%');
                xticklabels(BFDurationTypes);
                
                if myExtractor.printPlotsEnable
                    fileName = ['PatternParam3_scalNo',myExtractor.id, ', part=',num2str(data.rmsPart),'%'];
                    fullFilePath = fullfile(pwd,'Out');
                    fullFileName = fullfile(fullFilePath,fileName);
                    print(fullFileName,'-djpeg91', '-r180');
                end
                
                if strcmpi(myExtractor.plotVisible, 'off')
                    close
                end 
                
            end
        end
   
		
		% CALCULATEEQUIPMENTPATAMETERS function use 60%-signal reconstruction
        % to build basis function spectrum (BFSp)
		function [myExtractor] = calculateEquipmentParameters(myExtractor)
		
			data = myExtractor.swdData(1); 	% low-detailed signal is used
			
			bf_vector = myExtractor.basis.basisFuncList; %basis functions list

			% Form BF-spectrum
            sparseModesEnergy = sum((data.sparseModes).^2,1);
            sparseSignalEnergy = sum((data.sparseSignal).^2,1);
            bf_spectum = sparseModesEnergy/sparseSignalEnergy;
            bf_spectum = bf_spectum/sum(bf_spectum);
            
            myBFSpectrum.spectrum = bf_spectum;
            myBFSpectrum.bf_vector = bf_vector;
			myExtractor.BFSpectrum = myBFSpectrum;
            	
			% Plot Results
            if myExtractor.plotEnable == 1
                
                % plot parameters 
                myPlotParameters = myExtractor.plotParameters;
                sizeUnits = myPlotParameters.sizeUnits;
                imageSize = str2num(myPlotParameters.imageSize);
                fontSize = str2double(myPlotParameters.fontSize);
                
                Translations = myExtractor.translations;
                
                % figure configuration
                myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', myExtractor.plotVisible, 'Color', 'w');
                bar(bf_spectum);
                grid on;
                
                myAxes = myFigure.CurrentAxes;
                myAxes.FontSize = fontSize;
                if strcmp(myExtractor.plotTitle, 'on')
                    title(myAxes, [upperCase(Translations.basisFunction.Attributes.shortName), ' ',...
                                upperCase(Translations.spectrum.Attributes.name, 'first'), ', ',...
                                upperCase(Translations.scalogram.Attributes.name, 'first'), ' ',...
                                upperCase(Translations.point.Attributes.name, 'first'), ' #',...
                                myExtractor.id]);
                end
                
                xticks(myAxes,[1:1:numel(bf_vector)]);
                xticklabels(myAxes, bf_vector);
                set(myAxes,'XTickLabelRotation', 90);
                
                xlabel(myAxes, upperCase(Translations.basisFunction.Attributes.name, 'allFirst'));
                ylabel(myAxes, upperCase(Translations.magnitude.Attributes.name, 'first'));
                
                % save figure as .jpg image
                if myExtractor.printPlotsEnable
                    
                    % .jpg parameters
                    imageFormat = myPlotParameters.imageFormat;
                    imageQuality = myPlotParameters.imageQuality;
                    imageResolution = myPlotParameters.imageResolution; 
                    
                    fileName = ['BF_spectrum-TD-',myExtractor.id];
                    fullFilePath = fullfile(pwd,'Out');
                    fullFileName = fullfile(fullFilePath,fileName);
                    print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
                end
                
                if strcmpi(myExtractor.plotVisible, 'off')
                    close(myFigure)
                end 
                
            end
			
			% Form data for equipment classification
            mySignal = data.sparseSignal;
            
            Ht = max(mySignal); % top max value
            Hb = abs(min(mySignal));
            highFrequency = 20000;
            
            myEquipmentData.BFSpectrum = bf_spectum;
            myEquipmentData.BF = bf_vector;
            myEquipmentData.resonantFrequency = myExtractor.resonantFrequency/highFrequency;
            
            myEquipmentData.kurtosis = kurtosis(mySignal);
            myEquipmentData.Hmax = max(Ht,Hb);
            myEquipmentData.R = rms(mySignal);          % whole pattern rms
            myEquipmentData.peakFactor = myEquipmentData.Hmax/myEquipmentData.R;
            myExtractor.equipmentData = myEquipmentData;
            
            % Test ...
            if myExtractor.debugModeEnable && myExtractor.saveDataEnable
                save(fullfile(pwd,'Out',['BF_spectrum_scalNo_',myExtractor.id,'.mat']),'myEquipmentData');
            end

		end

    end
    
    
    methods (Access = private)
       
        function [ myExtractor ] = createBasicWavelet(myExtractor)

            % Form the set of frequencies to create wavelet basis
            scale = myExtractor.waveletCentralFrequency/myExtractor.resonantFrequency;
            myExtractor.basicWavelet = feval(myExtractor.waveletType,scale,myExtractor.Fs,1)';
        end

        % FINDPATTERNFRAMES function selects places with possible patterns
        % and marks them for further selection of patterns.
        function [ patternFramesParameters, patternFramesMask, framesParameters, framesMask ] = findPatternFrames(myExtractor,frames)
            
            if nargin == 1
                mySwdData = myExtractor.swdData;
%                 sparseSignalsNumber = length(mySwdData);
                if length(mySwdData)>3
                    frames = envelope(mySwdData(3).sparseSignal);
                else
                    frames = envelope(mySwdData(end).sparseSignal);
                end
%                 frames = envelope(myExtractor.sparseSignal);
            end
            
            % Configuration parameters
            truePattenNumber = myExtractor.patternNumber;
            peakThreshold = myExtractor.patternPeakThreshold;
            
            % Find N top peaks and determine the threshold level
            [mag,pos,~,prom] = findpeaks(frames);
            peaks = bsxfun(@times, mag, prom);
            peaksSorted = sort(peaks,'descend');
            peaksSorted = peaksSorted(truePattenNumber:-1:1);
            [~,IA,~] = intersect(peaks,peaksSorted(1:truePattenNumber));
            
            threshold = rms(frames)*peakThreshold;
%             threshold = mean(mag(IA))*peakThreshold;
            truePosition = pos(IA);
            
            framesMask = zeros(size(frames));
            framesMask(frames > threshold) = 1;

            % Find positions of the true frames by numeric differentiation
            diffSignal = diff(framesMask);
            startFramePos = find(diffSignal>0)-1;
            endFramePos = find(diffSignal<0);
            
            % Check the correct endFramePos and startFramePos
            if isempty(endFramePos) && ~isempty(startFramePos)
                endFramePos = length(diffSignal);
            elseif ~isempty(endFramePos) && isempty(startFramePos)
                startFramePos = 1;
            elseif isempty(endFramePos) && isempty(startFramePos)
                error('PatternExtractor: There is no frames found!');
            end
            
            if(endFramePos(1,1) <= startFramePos(1,1))
                endFramePos(1) = [];
            end
            
            if(startFramePos(end,1) >= endFramePos(end,1))
                startFramePos(end) = [];
            end
            
            % Correct truePosition 
            maskVector = truePosition > min(startFramePos);
            truePosition = truePosition(maskVector);
            maskVector = truePosition < max(endFramePos);
            truePosition = truePosition(maskVector);
            
            frameLength = endFramePos - startFramePos;
            
            framesParameters(:,1) = startFramePos;
            framesParameters(:,2) = endFramePos;
            framesParameters(:,3) = frameLength;
            
            % Find only true pattern frames (N = myExtructor.patternNumber)
            patternFramesMask = zeros(size(framesMask));
            for i = 1:1:length(truePosition)
                stP(i) = startFramePos(find(startFramePos <= truePosition(i),1,'last'));
                endP(i) = endFramePos(find(endFramePos >= truePosition(i),1,'first'));
                patternFramesMask(stP(i):endP(i)) = 1;
            end 
            
            stP = unique(sort(stP,'ascend'));
            endP = unique(sort(endP,'ascend'));
            len = endP - stP;
            
            patternFramesParameters(:,1) = stP;
            patternFramesParameters(:,2) = endP;
            patternFramesParameters(:,3) = len;

        end
        
%         function [ patternFramesParameters, patternFramesMask, framesParameters, framesMask ] = findPatternFramesNew(myExtractor,rmsPart)
        function [ Result ] = findPatternFramesNew(myExtractor,tag)
            
            Result = [];
            frames = [];
            if nargin < 2
                tag = 'rough'; 
            end
            
            for i = 1:1:length(myExtractor.swdData)
                if strcmp(myExtractor.swdData(i).rmsPartTag, tag)
                    rmsPart = myExtractor.swdData(i).rmsPart;
                    mySparseSignal = myExtractor.swdData(i).sparseSignal;
                    frames = envelope(mySparseSignal);
                    break;
                end
            end
            
            if isempty(frames)
               return; 
            end
            % Configuration parameters
            peakThreshold = myExtractor.patternPeakThreshold;
            threshold = rms(frames)*peakThreshold;
            
            % Find N top peaks and determine the threshold level
            [mag,pos,~,prom] = findpeaks(frames,'MinPeakHeight',threshold);
            peaks = bsxfun(@times, mag, prom);
            peaksSorted = sort(peaks,'descend');
            peaksSorted = peaksSorted(end:-1:1);
            [~,IA,~] = intersect(peaks,peaksSorted);

            truePosition = pos(IA);
            
            framesMask = zeros(size(frames));
            framesMask(frames > threshold) = 1;

            % Find positions of the true frames by numeric differentiation
            diffSignal = diff(framesMask);
            startFramePos = find(diffSignal>0)-1;
            endFramePos = find(diffSignal<0);
            
            % Check the correct endFramePos and startFramePos
            if isempty(endFramePos) && ~isempty(startFramePos)
                endFramePos = length(diffSignal);
            elseif ~isempty(endFramePos) && isempty(startFramePos)
                startFramePos = 1;
            elseif isempty(endFramePos) && isempty(startFramePos)
                warning('PatternExtractor: There is no frames found!');
                startFramePos = 1; 
                endFramePos = length(diffSignal);
            end
            
            if(endFramePos(1,1) <= startFramePos(1,1))
                endFramePos(1) = [];
%                 startFramePos = [1;startFramePos];
            end
            
            if isempty(endFramePos)
                endFramePos = length(diffSignal);
            end
            
            if(startFramePos(end,1) >= endFramePos(end,1))
                startFramePos(end) = [];
            end
            
            % Correct truePosition 
            truePeaksVector = zeros(size(frames));
            truePeaksVector(truePosition) = 1;
            truePeaksVector = truePeaksVector.*framesMask;
            truePosition = find(truePeaksVector);
            
            maskVector = truePosition > min(startFramePos);
            truePositionSt = truePosition(maskVector);
            maskVector = truePosition < max(endFramePos);
            truePositionEnd = truePosition(maskVector);
            
            frameLength = endFramePos - startFramePos;
            
            framesParameters(:,1) = startFramePos;
            framesParameters(:,2) = endFramePos;
            framesParameters(:,3) = frameLength;
            
            % Frames Length validation
            % if length of the frame is less than 10 samples -- unvalid
            patternFramesParameters = framesParameters;
            lengthMask = framesParameters(:,3) <= 10 ;
            patternFramesParameters(lengthMask,:) = [];
            
            if patternFramesParameters(1,1) == 0
                patternFramesParameters(1,1) = 1;
            end
            
            patternFramesMask = zeros(size(framesMask));
            for i = 1:1:size(patternFramesParameters,1)
                patternFramesMask(patternFramesParameters(i,1):patternFramesParameters(i,2)) = 1;
            end
            
            Result.rmsPart = rmsPart;
            Result.tag = tag;
            Result.patternFramesParameters = patternFramesParameters;
            Result.patternFramesMask = patternFramesMask;
            
            
     % ----------------- Plot Results ---------------------- %
            if myExtractor.plotEnable && myExtractor.debugModeEnable
                
                dt = 1/myExtractor.Fs;
                t = 0:dt:dt*(length(myExtractor.signal)-1);
                
                figure,set(gcf,'color','w','Position',[0 ,0 ,1650,1080],'Visible',myExtractor.plotVisible);
                plot(t, myExtractor.signal);
                hold on, plot(t,mySparseSignal);
                hold on, plot(t,frames);
                hold on, plot(t,patternFramesMask*max(frames)/10,'LineWidth',2);
                title(['Pattern Frames Extraction. scalNo = ',myExtractor.id,', rmsPart = ',num2str(rmsPart),'%']);
                ylabel('Pattern Frames,m/s^2');
                xlabel('Time, s');
                ylim([0 max(abs(myExtractor.signal))]);
                legend({'original','sparseSignal','envelope','patternFrames'});

                if myExtractor.printPlotsEnable
                    fileName = ['PatternFrames_scalNo',myExtractor.id, ', part=',num2str(rmsPart),'%'];
                    fullFilePath = fullfile(pwd,'Out');
                    fullFileName = fullfile(fullFilePath,fileName);
                    print(fullFileName,'-djpeg91', '-r180');
                end
                
                if strcmpi(myExtractor.plotVisible, 'off')
                    close
                end 
                
            end  
        end
        
        % CREATEPATTERNTABLE function generates a table with the found 
        % patterns. Patterns are restored to sparse peaks.
        function [ myExtractor ] = createPatternTable(myExtractor, patternData)
			
			% Mask vector of the major pattern frames
            majorPosition = find(arrayfun(@(x) strcmp(x.tag,'major'), patternData),1,'first');
            roughPosition = find(arrayfun(@(x) strcmp(x.tag,'rough'), patternData),1,'first');
            accuratePosition = find(arrayfun(@(x) strcmp(x.tag,'accurate'), patternData),1,'first');
            
			majorMask = patternData(majorPosition).patternFramesMask;
			roughMask = zeros(size(majorMask));
			
            
            roughFramesParameters = patternData(roughPosition).patternFramesParameters;
            patternsNumber = size(roughFramesParameters,1);
            rmsPart = patternData(roughPosition).rmsPart;
            
            
            roughSparsePeaks = myExtractor.swdData(roughPosition).sparsePeaks;
            accurateSparsePeaks = myExtractor.swdData(accuratePosition).sparsePeaks;
            
            for i = 1:1:patternsNumber
                stP = roughFramesParameters(i,1);
                endP = roughFramesParameters(i,2);
                len = roughFramesParameters(i,3);
                patternPeaks =  accurateSparsePeaks(stP:endP,:);
               
			   roughMask(stP:endP) = i;
            % Expand the pattern framework for more accurate signal recovery
                patternLength = len+1; % dummy
                [ mySparseSignal, accurateModes] = restoreMultiSignal(myExtractor,patternPeaks,'wavelet',patternLength);
                [ ~, roughModes] = restoreMultiSignal(myExtractor,roughSparsePeaks(stP:endP,:),'wavelet',patternLength);
                myPatternTable(i).sparseSignal = mySparseSignal';
                myPatternTable(i).stP = stP;
                myPatternTable(i).endP = endP;
                myPatternTable(i).length = len;
                myPatternTable(i).sparsePeaks = roughSparsePeaks(stP:endP,:);
                myPatternTable(i).sparseModes = roughModes;
                myPatternTable(i).accuratePeaks = accurateSparsePeaks(stP:endP,:);
                myPatternTable(i).accurateModes = accurateModes;
                myPatternTable(i).rmsPart = rmsPart;
                myPatternTable(i).major = 0;
            end
			
			
			% Find major pattern positions
			majorPosition = unique(bsxfun(@times,majorMask,roughMask));
            majorPosition(majorPosition(:) == 0) = [];
            for i = 1:numel(majorPosition)
                myPatternTable(majorPosition(i)).major = 1;
            end
			

            myExtractor.patternTable = myPatternTable;
        end
       
        function [ myExtractor ] = fillInPatternTable(myExtractor)
            
            [ myPatternTable ] = myExtractor.patternTable;
            patternsNumber = length(myPatternTable);
            
            T0 = round(myExtractor.Fs/myExtractor.resonantFrequency); 
            signalRms = rms(myExtractor.signal);
            
            % Calculate common time-domain paremeters of the patterns
            k = 1;
            for i = 1:1:patternsNumber   
                patternSubTable = myExtractor.calculatePatternParameters(myPatternTable(i),T0,signalRms);
                if ~isempty(patternSubTable)
                    iPatternTable(k) = patternSubTable;
                    k = k+1;
                    patternSubTable = [];
                end
            end
            myPatternTable = iPatternTable;
            
            % Calculate common swd parameters of the patterns
            patternsNumber = length(myPatternTable);
            k = 1;
            myExtractor.plotEnable = 0;
            for i = 1:1:patternsNumber   
                patternSubTable = calculateSWDParameters(myExtractor,myPatternTable(i));
                if ~isempty(patternSubTable)
                    iPatternTable(k).BFModesEnergy = patternSubTable.BFModesEnergy;
                    iPatternTable(k).BFModesIntensity = patternSubTable.BFModesIntensity;
                    iPatternTable(k).BFModesEfficiency = patternSubTable.BFModesEfficiency;
                    iPatternTable(k).BFTypeEnergy = patternSubTable.BFTypeEnergy;
                    iPatternTable(k).BFTypeIntensity = patternSubTable.BFTypeIntensity;
                    iPatternTable(k).BFTypeEfficiency = patternSubTable.BFTypeEfficiency;
                    iPatternTable(k).BFDurationEnergy = patternSubTable.BFDurationEnergy;
                    iPatternTable(k).BFDurationIntensity = patternSubTable.BFDurationIntensity;
                    iPatternTable(k).BFDurationEfficiency = patternSubTable.BFDurationEfficiency;
                    k = k+1;
                    patternSubTable = [];
                else
                    iPatternTable(k) = [];
                end
            end
            myExtractor.plotEnable = 1;
            maxResonantFrequency = 20000; % the bound of the HF range (10k...20k)
            myResonantFrequency = myExtractor.resonantFrequency/maxResonantFrequency;
            iPatternTable = arrayfun(@(x) setfield(x,'resonantFrequency',myResonantFrequency), iPatternTable);
            myExtractor.patternTable = iPatternTable;
        end
        
        % CREATERECTBASIS function
        function [myBasis] = createRectBasis(myExtractor)
            
           myWaveletBasis = myExtractor.basis.basis; 
           [basisFuncLength,basisLength] = size(myWaveletBasis);
           myBasis = zeros(basisFuncLength,basisLength);
           
           for i = 1:1:basisLength
           
                baseFunction = abs(myWaveletBasis(:,i));
                baseFunction(baseFunction>0.05) = 1;
                baseFunction(baseFunction<=0.05) = 0;
                positivePositions = find(baseFunction);
                baseFunction(min(positivePositions):max(positivePositions)) = 1;
                myBasis(:,i) = baseFunction;
           end
           
        end
        
        % restoreMultiSignal function .... 
        function [sparseSignal,sparseModes] = restoreMultiSignal(myExtractor,mySparsePeaks,mode,signalLength)
            
            if nargin == 2
                mode = 'wavelet';
                signalLength = length(myExtractor.signal);
            elseif nargin == 3
                signalLength = length(myExtractor.signal);
            end
            
            switch(mode)
                case 'wavelet'
                    myBasis = myExtractor.basis.basis;
                case 'rectangle'
                    myBasis = createRectBasis(myExtractor);
                    scales = 1./sqrt(sum(myBasis.^2));
                    myBasis = bsxfun(@times,myBasis,scales);
                otherwise
                    error('Unknown @mode for signal reconstruction');
            end
               
            [sparseSignal,sparseModes] = myExtractor.restoreSignal(mySparsePeaks,myBasis,signalLength);
        end
    end
    
    methods (Static = true, Access = private)
       
%        CALCULATEPATTERNPARAMENTERS function returns the list of pattern
%        parameters (e.g. peakFactor, energyDistribution)
       function [patternStruct] = calculatePatternParameters(patternStruct,T0,Rs)
            
            pattern = patternStruct.sparseSignal;
            
            % pattern parameters ...
            Ht = max(pattern); % top max value
            Hb = abs(min(pattern));
            Hmax = max(Ht,Hb);
            R = rms(pattern);                     % whole pattern rms
            Rt = rms(pattern(pattern>=0));  % pattern top-part rms
            Rb = rms(pattern(pattern<=0));  % pattern bottom-part rms
%             T = length(pattern)*0.8;  % here shld be na effective length !!!
            T = length(pattern);  % here shld be na effective length !!!
            
            patternStruct.T2T0 = T/T0;
            patternStruct.Ht2Hb = Ht/Hb;
            patternStruct.Rt2Rb = Rt/Rb;
            patternStruct.Hmax2Hrms = Hmax/R;  % peakFactor on the pattern RMS
            patternStruct.Hmax2Srms = Hmax/Rs; 
            patternStruct.R2Rs = R/Rs;
            patternStruct.R = R;

            % Horizontal full energy distribution (Horizontal symmetry)
            energyBanksNumber = 7;
            patternEnergy = abs(pattern).^2;
            patternLength = length(pattern);

            frameLength = floor(patternLength/energyBanksNumber);
            margin = floor((patternLength - frameLength*energyBanksNumber)/2);
%             patternEnergy = patternEnergy(1:frameLength*energyBanksNumber);
            patternEnergy = patternEnergy(1+margin:frameLength*energyBanksNumber+margin);
            energyVector = sum(reshape(patternEnergy,[frameLength,energyBanksNumber]),1);
            patternStruct.energyVector = energyVector/sum(energyVector)*100;
            
            
            % Horizontal short energy distribution (Horizontal symmetry)
            energyBanksNumber = 3;
            patternEnergy = abs(pattern).^2;
            patternLength = length(pattern);

            frameLength = floor(patternLength/energyBanksNumber);
            margin = floor((patternLength - frameLength*energyBanksNumber)/2);
%             patternEnergy = patternEnergy(1:frameLength*energyBanksNumber);
            patternEnergy = patternEnergy(1+margin:frameLength*energyBanksNumber+margin);
            energyVector = sum(reshape(patternEnergy,[frameLength,energyBanksNumber]),1);
            patternStruct.shortEnergyVector = energyVector/sum(energyVector)*100;
            
            % Horizontal symmetry
            energyBanksNumber = 2;
            patternEnergy = abs(pattern).^2;
            patternLength = length(pattern);

            frameLength = floor(patternLength/energyBanksNumber);
            margin = floor((patternLength - frameLength*energyBanksNumber)/2);
%             patternEnergy = patternEnergy(1:frameLength*energyBanksNumber);
            patternEnergy = patternEnergy(1+margin:frameLength*energyBanksNumber+margin);
            symmetryVector = sum(reshape(patternEnergy,[frameLength,energyBanksNumber]),1);
            patternStruct.symmetryVector = symmetryVector/sum(symmetryVector)*100;
            
            
%             if isnan(patternStruct.T2T0) || isnan(Hb) || isnan(Ht) || (Ht==0) || (Hb==0) 
            if nnz(isnan([patternStruct.T2T0, Hb, Ht])) || ~nnz([Ht,Hb]) 
                patternStruct = [];
            elseif (patternStruct.T2T0 <1)
                patternStruct = [];
            end
            
       end 
    
       
       % CURRENTLY UNUSED
       function [type] = estimatePatternType(parameters, container)
           
           % BEARING_PULSE type
           if  ( parameters(1) < 10 && ... 
                parameters(2) > 1.2 && ...
                parameters(4) > 2 && ...
                parameters(5) < 0.5 )
                
                type = 'BEARING_PULSE';
            
            % GEARING_PULSE type
            elseif ( parameters(1) > 6 && ... 
                   (parameters(2) > 0.7 && parameters(2) < 1.3) && ...
                    parameters(4) > 1.5 && ...
                    parameters(5) > 5 )
                
                type = 'GEARING_PULSE';
                
           % GEARING_BELTING type
           elseif ( parameters(1) > 10 && ... 
                   (parameters(2) > 0.7 && parameters(2) < 1.3) && ...
                   (parameters(4) > 1.3 && parameters(4) > 1.5) &&...
                    parameters(5) > 10 )

                type = 'GEARING_OR_BELTING';

           % SHAFT_PULSE type
            elseif ( parameters(1) < 10 && ... 
                    (parameters(2) > 0.7 && parameters(2) < 1.3) && ...
                    (parameters(4) > 1.3 && parameters(4) > 1.5) &&...
                     parameters(5) < 0.5 )
                 
                 type = 'SHAFT_PULSE';
           else
               type = 'UNKNOWN';
           end
       end
       
        % restoreSignal function restores sparse signal from sparse peak
        % representation
        function [ signal, sparseModes ] = restoreSignal( sparsePeaks, basis, originalLength )
            
            [m,n] = size(basis);
            if n>m
                basis = basis';
            end

            [basisFuncLength,basisLength] = size(basis);
            signal = zeros(originalLength,1);
            signal = padarray(signal,basisFuncLength,'both');
            
            sparseModes = zeros(size(sparsePeaks));
            sparseModes = padarray(sparseModes,basisFuncLength,'both');
            for i = 1:1:basisLength
                
                peakPosition = find(abs(sparsePeaks(:,i)));
                peakPositionNumber = numel(peakPosition);
                
                for j=1:1:peakPositionNumber
                    signal(peakPosition(j):peakPosition(j)+basisFuncLength-1,1) = signal(peakPosition(j):peakPosition(j)+basisFuncLength-1,1)   +    basis(:,i)*sparsePeaks(peakPosition(j),i);
                    sparseModes(peakPosition(j):peakPosition(j)+ basisFuncLength-1,i) = sparseModes(peakPosition(j):peakPosition(j)+basisFuncLength-1,i)   +    basis(:,i)*sparsePeaks(peakPosition(j),i);
                end
                
            end

            signal = signal(round(basisFuncLength/2):round(basisFuncLength/2)+originalLength-1)';
            sparseModes = sparseModes(round(basisFuncLength/2):round(basisFuncLength/2)+originalLength-1,:);

        end
       
    end
end

