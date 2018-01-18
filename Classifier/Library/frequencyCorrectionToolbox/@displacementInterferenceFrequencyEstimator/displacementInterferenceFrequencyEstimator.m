classdef displacementInterferenceFrequencyEstimator < frequencyEstimator
    %INTERFERENCECORRECTOR class is used to estimate real
    %shaft frequency value by smoothing envelope spectrum of the input
    %signal with further over-frame interference. Each frame has the
    %similar size [nominalFrequency-delta; nominalFrequency+delta].
    
    properties (Access = private)
    end
    
    methods (Access = public)
        
        % Constructor method
        function myFrequencyEstimator = displacementInterferenceFrequencyEstimator(File, myConfig)
            if nargin < 2
               myConfig = []; 
            end
            estimatorType = 'displacement';
            myFrequencyEstimator = myFrequencyEstimator@frequencyEstimator(File, myConfig, estimatorType);
            
            myFrequencyEstimator.baseFrequencies = File.baseFrequencies;
            myFrequencyEstimator = createCorrespondenceTable(myFrequencyEstimator);
            printStage(myFrequencyEstimator, 'The displacement frequency estimator was created.')
        end
        
        % Getters/Setters ...
        function myBaseFrequencies = getBaseFrequencies(myFrequencyEstimator)
            myBaseFrequencies = myFrequencyEstimator.baseFrequencies;
        end
        function [myFrequencyEstimator] = setBaseFrequencies(myFrequencyEstimator,myBaseFrequencies)
            myFrequencyEstimator.baseFrequencies = myBaseFrequencies;
        end
        
        function myCorrespondenceTable = getCorrespondenceTable(myFrequencyEstimator)
            myCorrespondenceTable = myFrequencyEstimator.correspondenceTable;
        end
        function [myFrequencyEstimator] = setCorrespondenceTable (myFrequencyEstimator,myCorrespondenceTable )
            myFrequencyEstimator.correspondenceTable = myCorrespondenceTable ;
        end
        % ... Getters/Setters
        
        % GETFREQUENCYESTIMATIONWITHACCURACY function implements only one
        % type of frequency estimatin ('rough' or 'accurate')
        function [result,myFrequencyEstimator] = getFrequencyEstimationWithAccuracy(myFrequencyEstimator, accuracy)
            
            if nargin < 2
               accuracy = 'rough';
            end
            printStage(myFrequencyEstimator, ['Start estimation displacement spectrum interference method with ' accuracy ' accuracy.'])
            
            myBaseFrequencies = myFrequencyEstimator.baseFrequencies;
            frequenciesNumber = length(myBaseFrequencies);
            printStage(myFrequencyEstimator, sprintf('Estimating frequency with %s accuracy.', accuracy));
            
            for i = 1:1:frequenciesNumber
                printStage(myFrequencyEstimator, sprintf('The %d shaft interference. Nominal freequency is %10.5f.', i, myBaseFrequencies(i)));
                myFrequencyEstimator = setNominalFrequency(myFrequencyEstimator, myBaseFrequencies(i));
                interferenceResults(i) = createInterferenceResults(myFrequencyEstimator, accuracy, myBaseFrequencies(i), myFrequencyEstimator.shaftSchemeName{i});
            end
            
            [result] = makeDecision(myFrequencyEstimator, interferenceResults, accuracy);  %Unused
            if strcmp(accuracy,'rough')  %Descision about frequency estimation makes an external method,
                myFrequencyEstimator = setRoughFrequency(myFrequencyEstimator,result.frequency); %so this block
            elseif strcmp(accuracy,'accurate')  %is unused. Set a rough and set/call accurate method will do also
                myFrequencyEstimator = setAccurateFrequency(myFrequencyEstimator,result.frequency); %external descision maker.
%                 myFrequencyEstimator.accurateFrequency = result.frequency;
            end
            
            myFrequencyEstimator = recalculateBaseFrequencies(myFrequencyEstimator,result);
            result.frequenciesVector = myFrequencyEstimator.baseFrequencies;  %result = interferenceResults(validPositions);
        end
        
        % GETFREQUENCYESTIMATION function checks true frequency value
        % through rough and accurate channel ( enable parameters are places
        % in config.xml
        function [result,myFrequencyEstimator] = getFrequencyEstimation(myFrequencyEstimator, mode)
              
            if nargin < 2
                mode = 'full';
            end
            
            if strcmp(mode, 'full')
                % Default parameters
                parameters = myFrequencyEstimator.config;
                result.probability = 100;
                % Rough channel
                if str2double(parameters.rough.Attributes.processingEnable)
                    [result,myFrequencyEstimator] = getFrequencyEstimationWithAccuracy(myFrequencyEstimator,'rough');
                end
                % Accurate channel
                if str2double(parameters.accurate.Attributes.processingEnable) && result.probability
                    [result,myFrequencyEstimator] = getFrequencyEstimationWithAccuracy(myFrequencyEstimator,'accurate');
                    if ~result.probability
                       [~, index] = max(result.interference);
                       result.frequency = result.f(index);
                       result.probability = 10;
                    end
                else
                    myFrequencyEstimator.accurateFrequency = result.frequency;
                end
            
            elseif strcmp(mode, 'rough')
                [result,myFrequencyEstimator] = getFrequencyEstimationWithAccuracy(myFrequencyEstimator,'rough');
                
            elseif strcmp(mode, 'accurate')
                [result,myFrequencyEstimator] = getFrequencyEstimationWithAccuracy(myFrequencyEstimator,'accurate');
                
            else
                printWarningLog(myFrequencyEstimator, ['There is no such mode: ', mode, ' to operate!']);
                result.frequency = []; 
                result.probability = 0;
                result.interference = [];
                
            end
                
        end
    end
    
    methods (Access = private)
        
        % CREATEINTERFERENCERESULTS function gets frequency estimation based
        % on interference of the envelope spectrum smoothed frames.
        % Function returns vector of the possible frequencies and vector of
        % their probabilities for one of the base frequencies (property).
        function [result] = createInterferenceResults(myFrequencyEstimator, accuracy, baseFrequency, shaftSchemeName)
            %Interference - element-by-element product of frames - bands
            %which central frequencies are shaft frequency and it's
            %harmonics. If the firsf sharf frequency is approximately
            %right, due multiplication peaks of shaft harmonics will match
            %and will give the bigger one.
            
            % Extract default parameters from config.xml
            if nargin < 2
               accuracy = 'rough'; 
            end
            myConfig = myFrequencyEstimator.config;
            plotEnable = logical(str2double(myConfig.Attributes.plotEnable) * str2double(myConfig.(accuracy).Attributes.plotEnable) * str2double(myConfig.debugModeEnable));
            if ~isfield(myConfig.Attributes, 'validFrames')
                myConfig.Attributes.validFrames = '0';
            end
            myConfig.Attributes.validFrames = str2double(myConfig.Attributes.validFrames);
            myConfig.Attributes.fullSavingEnable = str2double(myConfig.Attributes.fullSavingEnable);
            peaksConf = myConfig.(accuracy).Attributes;
            additionalFramesIndexes = [];
            
            myNominalFrequency = myFrequencyEstimator.nominalFrequency;
            
            % The first N frames of envelope spectrum are main due to 
            % great part of rotor elements (shaft) energy is focused here
            % especially when imbalance defect takes place.
            mainFramesNumber = str2double(myConfig.(accuracy).Attributes.mainFramesNumber);
            additionalFramesNumber = str2double(myConfig.(accuracy).Attributes.additionalFramesNumber);
            totalFramesNumber = mainFramesNumber + additionalFramesNumber;
            
            % ___________________ Main frames __________________________ %
            
            for i=1:1:mainFramesNumber %Getting frames of the shaft frequency and it's harmonics.
                myResult = getSmoothedSpectrumFrame(myFrequencyEstimator, myNominalFrequency*i, accuracy);
                myResults(i) = myResult;
                NotNormalizedFrames(i,:) = myResult.spectrumFrame; %Not normalized spectrum frames to validate frames by peak (harmonic) prominence.
                spectrumFrames(i,:) = myResult.spectrumFrame/ max(myResult.spectrumFrame);
                spectrumFramesOriginal(i,:) = myResult.original.spectrumFrame/ max(myResult.original.spectrumFrame);
                if i == 1
                    f = myResult.f;
                    fOriginal = myResult.original.f;
                end
            end
            shaftFramesTable = {myResults.spectrumFrame}; %For additional validation of result by frames number weights.
            printStage(myFrequencyEstimator, sprintf('%d main frames were computed.', mainFramesNumber));
            str = '';
            mainFramesIndexes = 1:mainFramesNumber;
            %Validation of frames if it's necessary.
            if myConfig.Attributes.validFrames == 1
                myFramesFreqVectors = {myResults.f};
                captionStrings = arrayfun(@(x) sprintf('%10.5f_%d fr_main', myNominalFrequency, x), mainFramesIndexes, 'UniformOutput', false);
                IdxVal = find(myFrequencyEstimator.validateFrames(myFramesFreqVectors, captionStrings)');
                mainFramesIndexes = mainFramesIndexes(IdxVal);
                printStage(myFrequencyEstimator, sprintf('Frames validator: %s are valid of %d total.', num2str(IdxVal), mainFramesNumber));
                str = 'valid_';
            end
            
            if myConfig.Attributes.fullSavingEnable
                close all
                %test plotting
                plotFrameResults(myResults, myNominalFrequency, [str 'DisplacementSpec_'], '', peaksConf)
            end
			
            if nnz(IdxVal)
                interferenceMain = prod(spectrumFrames(IdxVal, :), 1);
            else
                interferenceMain = ones(size( spectrumFrames(i,:) )); %Set result to zero.
            end
				
%             [frequencyMagnitudeMain, frequencyIndexMain] = findpeaks(interferenceMain, 'SortStr','descend','NPeaks', nPeaks, 'MinPeakHeight', minPeakHeight*rms(interferenceMain),'MinPeakDistance',minPeakDistance);
            
            % If interference picture has only one peak its probability
            % should be 100 %, if there are several peak their
            % probabilities calculate over the formula:
            % P(i) = baseProbability + k*Magnitude,
            % where 1)baseProbability = 100%/peaksNumber;
            %                                    ____
            %                                    \      
            %       2)k = baseProbability / [    /___  Magnitudes(i) ]
            %  

            interfPeaksMain = peaksFilter(interferenceMain, peaksConf);
            if ~interfPeaksMain.validities  %If there too many good peaks - result is trash.
                frequencyValueMain = NaN(1);   %Flag of non successful estimation.
            else
                frequencyValueMain = f(interfPeaksMain.indexes);
            end
            printStage( myFrequencyEstimator, sprintf('Main frames: %d probably frequencies.', numel(interfPeaksMain.indexes)) );
            
            % ____________________ Additional Frames ____________________ %
            % If there are several greate peaks on the interference picture
            % of the main frames, form interference of all avalible frames
            % (main + additional). This may be useful when shaft ran-out
            % defect takes place.
            if additionalFramesNumber > 0 && nnz(~isnan(frequencyValueMain))>0
                clear myResults;
                for i = mainFramesNumber+1:1:totalFramesNumber
                    myResult = getSmoothedSpectrumFrame(myFrequencyEstimator, myNominalFrequency*i, accuracy);
                    myResults(i - mainFramesNumber) = myResult;
                    NotNormalizedFrames(i,:) = myResult.spectrumFrame; %Not normalized spectrum frames to validate frames by peak (harmonic) prominence.
                    spectrumFrames(i,:) = myResult.spectrumFrame/ max(myResult.spectrumFrame);
                    spectrumFramesOriginal(i,:) = myResult.original.spectrumFrame/ max(myResult.original.spectrumFrame);
                end
                shaftFramesTable = horzcat(shaftFramesTable, {myResults.spectrumFrame}); %For additional validation of result by frames number weights.
                printStage(myFrequencyEstimator, sprintf('%d additional frames were computed.', additionalFramesNumber));
                %test plotting
                if myConfig.Attributes.fullSavingEnable
                    plotFrameResults(myResults, myNominalFrequency, [str 'DisplacementSpec_Addit_'], '', peaksConf);
                end
            
				%Validation of frames if it's necessary.
                additionalFramesIndexes = 1:additionalFramesNumber;
                IdxVal = 1:additionalFramesNumber;
                if myConfig.Attributes.validFrames == 1
                    myFramesFreqVectors = {myResults.f};
                    captionStrings = arrayfun(@(x) sprintf('%10.5f_%d fr_addit', myNominalFrequency, x), additionalFramesIndexes, 'UniformOutput', false);
                    IdxVal = find(myFrequencyEstimator.validateFrames(myFramesFreqVectors, captionStrings)');
                    additionalFramesIndexes = additionalFramesIndexes(IdxVal);
                    printStage(myFrequencyEstimator, sprintf('Frames validator: %s are valid of %d total.', num2str(IdxVal), totalFramesNumber));
                end
                if nnz(IdxVal)
                    interference = prod(spectrumFrames(IdxVal, :), 1);
                else
                    interference = ones(size( spectrumFrames(1,:) )); %Set result to zero.
                end
                
                interfPeaksAddit = peaksFilter(interference, peaksConf);
                printStage( myFrequencyEstimator, sprintf('Additional frames: %d probably frequencies.', numel(interfPeaksAddit.indexes)) );
                if ~interfPeaksAddit.validities  %If there too many good peaks - result is trash.
                    interference = interferenceMain;
                    interfPeaks = interfPeaksMain;
                    interfPeaksAddit.validities = 0;
                else
                    interfPeaks = interfPeaksAddit;
                end

            else
                interference = interferenceMain;
                interfPeaks = interfPeaksMain;
            end
            
            % ________________________ Result __________________________ %
            
            result.interference = interference;
            result.f = f;
            
            result.shaftFramesTable = shaftFramesTable;
            result.frameIndexes = [mainFramesIndexes additionalFramesIndexes + mainFramesNumber]; %Indexes of valid frames.
            frequencyIndex = interfPeaks.indexes;
            result.magnitudes = interfPeaks.magnitudes;
            result.frequencies = f(frequencyIndex);
            result.probabilities = interfPeaks.validities;
            result.baseFrequency = baseFrequency;
            result.shaftSchemeName = shaftSchemeName;
            
            % _____________________PLOT RESULTS ________________________ %

            %Thresholds for plotting.
            peaksConf = fill_struct(peaksConf, 'minRMSPeakHeight', '0');
            peaksConf = fill_struct(peaksConf, 'minOverMaximumThreshold', '0');
            RMSlev = str2double(peaksConf.minRMSPeakHeight);
            LeadLev = str2double(peaksConf.minOverMaximumThreshold);
            %Caption of the frames that are validated.
            additionalFramesStrings = arrayfun(@(x) sprintf('Additional frame number %d', x), additionalFramesIndexes, 'UniformOutput', false);
            mainFramesStrings = arrayfun(@(x) sprintf('Main frame number %d', x), mainFramesIndexes, 'UniformOutput', false);
            framesCaptions = [mainFramesStrings additionalFramesStrings];
            additionalFramesIndexes = additionalFramesIndexes + mainFramesNumber;
            frameIndexes = [mainFramesIndexes additionalFramesIndexes];
            spectrumFrames = spectrumFrames(frameIndexes,:);
            spectrumFramesOriginal = spectrumFramesOriginal(frameIndexes,:);
            
            if plotEnable == 1
                subplotsNumber = length(spectrumFrames(:,1));
                figure('Name', 'Interference displacement method of frequency estimation', 'NumberTitle', 'off', ...
                    'Units', 'points', 'Position', [0, 0, 800, 600], 'Visible', myFrequencyEstimator.config.plotVisible);
                for i = 1:1:subplotsNumber
                    subplot(subplotsNumber+1,1,i)
                    hold on
                    plot(f,spectrumFrames(i,:)); %Interpolated frames.
                    plot(fOriginal,spectrumFramesOriginal(i,:)); %Original (not interpolated) frames.
                    %Thresholds plotting...
                    RMS = repmat( rms(spectrumFrames(i,:)), size(f) );
                    plot(f, RMS, ':')
                    plot(f, RMS*RMSlev)
                    Lead = repmat( max(spectrumFrames(i,:)), size(f) );
                    plot(f, Lead, ':')
                    plot(f, Lead*LeadLev)
                    %legend('Interpolated frame', 'Original frame', 'RMSlevel', 'RMSthreshold', 'LeaderLevel', 'LeaderThreshold')
                    %...thresholds plotting.
                    hold off
                    %Optimize scales to avoid lifting of graphic and space before.
                    axis([f(1), f(end), 0, max(spectrumFrames(i,:))])
                    xlabel('Frequency, Hz'); ylabel('Magnitude');
                    title(framesCaptions{i});
                end
                subplot(subplotsNumber+1,1,subplotsNumber+1),plot(f,interference);
                %Optimize scales to avoid lifting of graphic and space before.
                axis([f(1), f(end), 0, max(interference)])
                xlabel('Frequency, Hz'); ylabel('Magnitude');
                interfCaption = sprintf('Normolized Interference for the nominal shaft frequency %10.5f', myNominalFrequency);
                title(interfCaption);

                hold on;
                stem(f(frequencyIndex), result.magnitudes)
				%Thresholds plotting...
				RMS = repmat( rms(interference), size(f) );
				plot(f, RMS, ':')
				plot(f, RMS*RMSlev)
				Lead = repmat( max(interference), size(f) );
				plot(f, Lead, ':')
				plot(f, Lead*LeadLev)
                %legend('Interference', 'RMSlevel', 'RMSthreshold', 'LeaderLevel', 'LeaderThreshold')
				%...thresholds plotting.
                hold off;
                
%                 if myConfig.Attributes.fullSavingEnable
%                     Root = fullfile(fileparts(mfilename('fullpath')),'..','..','..');
%                     Root = repathDirUps(Root);
%                     PicName = sprintf('%10.5f_%sDisplacementSpec_%s.jpg', myNominalFrequency, str, 'allFramesAndInterferenceResults');
%                     NameOutFile = fullfile(Root, 'Out', 'interfResults', PicName);  %['interfResults' str]
%                     print(NameOutFile,'-djpeg81', '-r150');
%                 end
                
                % Close figure with visibility off
                if strcmpi(myFrequencyEstimator.config.plotVisible, 'off')
                    close
                end
            end
        end
        
        
        
    end
    
end

