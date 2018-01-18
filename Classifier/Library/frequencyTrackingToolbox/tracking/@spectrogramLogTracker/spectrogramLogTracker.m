classdef spectrogramLogTracker 
    %SPECTROGRAMLOGTRACKER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        % Input 
        config % Configuration structure
        tag
        
        % Plot Parameters:
        parpoolEnable = 0;
        plotEnable = 0;
        plotVisible = 'off';
        plotTitle = 'on'
        printPlotsEnable = 0;
        debugModeEnable = 0;
        
        baseFramesNumber = 5;
        maxInvalidPercent = 40;
        frameLengthSample = 5;
        frameOverlapSample = 3;
        maxPercentDeviationPerSec = 1;
        maxPercentDeviation = 10;
        
        % Frequency Ranges : [4:16] ;[8:32]; [16:64]; [32:128]; [64:256] [Hz];
        frequencyRange = [4,16; 8,32; 16,64; 32,128; 64,256 ];
        
        logBasis = 1.01;
        accuracyPercent = 0.1;
        % Output 
        
        logSpectrogram = [];
        
    end
    
    methods
        
        % Constructor
        function [myTracker] = spectrogramLogTracker(config, tag)
           
            if nargin == 0
                warning('There is no config structure for spectrogram initialization!')
                config = [];
                tag = 'acc'; 
            elseif nargin == 1
                tag = 'acc'; 
            end
                
            % Common Parameters
            config = fill_struct(config, 'parpoolEnable', '0');
            config = fill_struct(config, 'plotEnable', '0');
            config = fill_struct(config, 'plotVisible', 'off');
            config = fill_struct(config, 'plotTitle', 'on');
            config = fill_struct(config, 'printPlotsEnable', '0');
            config = fill_struct(config, 'debugModeEnable', '0');
            
            myTracker.config = config;
            myTracker.parpoolEnable = str2double(config.parpoolEnable);
            myTracker.plotEnable = str2double(config.plotEnable);
            myTracker.plotVisible = config.plotVisible;
            myTracker.plotTitle = config.plotTitle;
            myTracker.printPlotsEnable = str2double(config.printPlotsEnable);
            myTracker.debugModeEnable = str2double(config.debugModeEnable);
            
            % Tracker Parameters
            config = fill_struct(config, 'baseFramesNumber', '5');
            config = fill_struct(config, 'maxInvalidPercent', '40');
            config = fill_struct(config, 'frameLengthSample', '5');
            config = fill_struct(config, 'frameOverlapSample', '3');
            config = fill_struct(config, 'maxPercentDeviationPerSec', '1');
            config = fill_struct(config, 'maxPercentDeviation', '10');
            config = fill_struct(config, 'accuracyPercent', '0.1');
            
            myTracker.baseFramesNumber = str2double(config.baseFramesNumber);
            myTracker.maxInvalidPercent = str2double(config.maxInvalidPercent);
            myTracker.frameLengthSample = str2double(config.frameLengthSample);
            myTracker.frameOverlapSample = str2double(config.frameOverlapSample);
            myTracker.maxPercentDeviationPerSec = str2double(config.maxPercentDeviationPerSec);
            myTracker.maxPercentDeviation = str2double(config.maxPercentDeviation);            
            myTracker.accuracyPercent = str2double(config.accuracyPercent);   
            
            % Multitrack parameters
            config = fill_struct(config, 'frequencyRange', '4:16; 8:32; 16:64; 32:128; 64:256' );
            frequencyRangeTemp = config.frequencyRange;
            
            frequencyRangeTemp = cellfun(@(x) strsplit(x,':'), strsplit(frequencyRangeTemp,';'), 'UniformOutput', false);
            frequencyRange = cell(size(frequencyRangeTemp));
            for i = 1:numel(frequencyRange)
                frequencyRange{i} = cellfun(@(x) str2num(x), frequencyRangeTemp{i});
            end
            myTracker.frequencyRange = cell2mat(frequencyRange');
            
            myTracker.tag = tag;
            
            
            
            % ----------- Init logSpectrogram ---------------------- %
            
            [dfLog, logBasis] = logSpectrogramParameters(myTracker);
            
            Parameters = myTracker.config;
            if isfield(Parameters, 'filtering')
                field2add = fields(Parameters.filtering);
                for i = 1:numel(field2add)
                    Parameters = setfield(Parameters, field2add{i}, Parameters.filtering.(field2add{i}));
                end
                if isfield(Parameters,'secPerFrame')
                   Parameters = rmfield(Parameters, 'secPerFrame'); 
                end
            end
            if isfield(Parameters, 'logSpectrogram')
                if isfield(Parameters.logSpectrogram, 'Attributes')
                    field2add = fields(Parameters.logSpectrogram.Attributes);
                    for i = 1:numel(field2add)
                        Parameters = setfield(Parameters, field2add{i}, Parameters.logSpectrogram.Attributes.(field2add{i}));
                    end
                end
            end
            Parameters = setfield(Parameters, 'highFrequency', num2str(max(myTracker.frequencyRange(:,2))));
            Parameters = setfield(Parameters, 'lowFrequency', num2str(min(myTracker.frequencyRange(:,1))));
            Parameters = setfield(Parameters, 'dfLog', num2str(dfLog));
            Parameters = setfield(Parameters, 'logBasis', num2str(logBasis));
            
            myTracker.logSpectrogram = spectrogram2Log(Parameters, tag);
        end
        
        
        function [myTracker] = create(myTracker, file)
            
            mySpectrogram = myTracker.logSpectrogram;
            mySpectrogram = create(mySpectrogram, file);
            myTracker.logSpectrogram = mySpectrogram;
            
        end
        
        function [logStep, logBasis] = logSpectrogramParameters(myTracker)
            
            accuracy = myTracker.accuracyPercent/100;
            logBasis = myTracker.logBasis;
            logStep = round(log2(accuracy/10+1)/log2(logBasis), 2);
            
        end
        
        % Create frequency track on the basis of full spectrogram or of
        % spectrogramData
        function [myTrack] = createTrack(myTracker, spectrogramData)
            
        % INPUT: 
            if nargin < 2
                spectrogramData = get(myTracker.logSpectrogram);
            end
            
            spectrogramTable = spectrogramData.coefficients;
            if isempty(spectrogramTable) || size(spectrogramTable,2)<=3 || size(spectrogramTable,2) < myTracker.baseFramesNumber
                warning('Too short signal for frequency tracking!');
                myTrack.shift = [];
                myTrack.time = [];
                myTrack.validity = 0;
                myTrack.std = 0;
                return;
            end
            logBasis = spectrogramData.logBasis;
            dfLogStep = spectrogramData.dfLog;
            
            framesNumber = myTracker.baseFramesNumber;
            
            
        % CALCULATION:
            trackTable = cell(1,framesNumber);
            for j = 1:framesNumber

                [logShift] = NaN(size(spectrogramTable,2),1); 
                for i = 1:size(spectrogramTable, 2)
                    [logShift(i)] = myTracker.estimateShift(spectrogramTable(:,j), spectrogramTable(:,i));
                end
    
                % Transform shift vector from log to linear spece
                shift = logBasis.^(logShift*dfLogStep);
                subTrack.shift = (shift -1)*100; % recalculate to "%"
                subTrack.time = spectrogramData.time;
                
                [trackTable{j}] = validateTrack(myTracker, subTrack);

            end
            
            trackTable = cell2mat(trackTable);
            
            [myTrack] = optimizeTrack(myTracker, trackTable);
            [myTrack] = validateTrack(myTracker, myTrack);

        % OUTPUT:   
            myTrack.std = std(myTrack.shift);
            myTrack.domain = myTracker.tag;
            myTrack.freqRange = 'full';
        end
        
        
        function [myMultiTrack] = createMultiTrack(myTracker)
            
            myFrequencyRange = myTracker.frequencyRange;
            lowFrequencies = myFrequencyRange(:,1);
            highFrequencies = myFrequencyRange(:,2);
            
            myMultiTrack = cell(size(myFrequencyRange,1),1);
            mySpectrogram = myTracker.logSpectrogram;
            
            for i = 1:numel(myMultiTrack)
                spectrogramData = getWithFrequencyRange(mySpectrogram,lowFrequencies(i), highFrequencies(i));
                myMultiTrack{i} = createTrack(myTracker, spectrogramData);
                myMultiTrack{i}.freqRange = strcat(num2str(lowFrequencies(i)),':',num2str(highFrequencies(i)));
            end
            myMultiTrack = cell2mat(myMultiTrack);
            
            if myTracker.plotEnable && myTracker.debugModeEnable
                plotAndPrint(myTracker, myMultiTrack);
            end
            
        end
        
        
        function [myTrack] = validateTrack(myTracker, myTrack)
            
            if nargin < 2
               error('Not enough input arguments!'); 
            end

        % INPUT: 
            shift = myTrack.shift;
            time = myTrack.time;
            
            myTrack.lowValidityPositions = zeros(size(shift));
            myTrack.status = 0;                
            myTrack.approxValidity = 0;
            
            % Find out-of-range position and approximate them

            samplesNumberPerSec = 1/(time(2)-time(1));
            maxPercentDeviationPerSample = myTracker.maxPercentDeviationPerSec/samplesNumberPerSec;

        % CALCULATION:
            diffShift = [0;diff(shift)];

            posOutOfRange = (shift > myTracker.maxPercentDeviation) | ...
                            (shift < -myTracker.maxPercentDeviation);
            R = [0; posOutOfRange(1:end-1)];
            L = [posOutOfRange(2:end);0];
            posOutOfRange = sum([L,posOutOfRange,R],2)>0;
               
            posTooVolatile = (diffShift > maxPercentDeviationPerSample) | (diffShift < -maxPercentDeviationPerSample);
            
            % 1st step)
            shift(posOutOfRange) = NaN;
            shift = inpaint_nans(shift);

            % 2nd step)
            shift(posTooVolatile) = NaN;
            shift = inpaint_nans(shift);


            movingAverage = smooth(shift, 20);
            threshold = std(movingAverage);
            posTooUncertain = abs(shift - movingAverage)>threshold;
            shift(posTooUncertain) = NaN;
            shift = inpaint_nans(shift);
            
            % Calculate statistics
            lowValidityPositions = posOutOfRange + posTooVolatile + posTooUncertain;
            lowValidityPercent = nnz(lowValidityPositions)/numel(shift)*100;
            if lowValidityPercent <= myTracker.maxInvalidPercent
                status = 1;
            else
                status = 0;
            end
            
        % OUTPUT:
            myTrack.shift = shift;
            myTrack.lowValidityPositions = lowValidityPositions;
            myTrack.status = status;
            myTrack.approxValidity = 1 - lowValidityPercent/100;
            
        end

        
        % Create optimal track from the trackTable (track length
        % minimization is a criteria of optimization)
        function [myTrack] = optimizeTrack(myTracker, myTrackTable)
           
        % INPUT:
            myTrack = [];
            
            shiftTable = cell2mat({myTrackTable.shift});
            weightVector = 1-[myTrackTable.approxValidity];
            
            frameLength = myTracker.frameLengthSample;
            frameOverlap = myTracker.frameOverlapSample;
            frameStep = frameLength - frameOverlap;

            Length  = size(shiftTable,1);

        % CALCULATION:
            
            % Decrease shift between 1st and Nth base frame
            framesShiftDelta = shiftTable(1,:);
            shiftTable = shiftTable - framesShiftDelta;
            
            % Implement oprimization of the track of frequency shift 
            [framesNumber, residueLength] = myTracker.estimateFramesNumber(Length, frameLength, frameOverlap);
            
            shiftVector = cell(framesNumber,1);
            lastState = 1;
            for i = 1:framesNumber
                [shiftVector{i},lastState] = myTracker.optimizeSubtrack(shiftTable(1+(i-1)*frameStep:(i-1)*frameStep+frameLength,:), weightVector, lastState, frameLength, frameOverlap );
            end
            
             % If there is some residue after optimization ...
             if residueLength > 0
                 [shiftResidue{1}] = myTracker.optimizeSubtrack(shiftTable(1+i*frameStep:i*frameStep+residueLength,:), weightVector, lastState, residueLength );
                 shift = cell2mat([shiftVector',shiftResidue])';
             else
                 currentLength = size(shiftVector{end},2)*size(shiftVector,1);
                 delta = Length - currentLength;
                 if (delta) > 0
                    [shiftResidue{1}] = myTracker.optimizeSubtrack(shiftTable(1+i*frameStep:i*frameStep+delta,:), weightVector, lastState, delta );
                    shift = cell2mat([shiftVector',shiftResidue])';
                 else
                    shift = cell2mat(shiftVector')';
                 end

             end
            
             % Estimate validity of optimized track
             validityMat = cell2mat({myTrackTable.lowValidityPositions});
             shiftValidityVector = sum(validityMat,2)/size(validityMat,2);
             validity = 1 - nnz(shiftValidityVector>0.33)/size(shiftValidityVector,1);
             
         % OUTPUT:
             
             myTrack.shift = shift;
             myTrack.time = myTrackTable.time;
             myTrack.validity = validity;
            
        end
        
        
        function plotAndPrint(myTracker, myTrack)
            
        % INPUT:
            Config = myTracker.config;
            sizeUnits = Config.plots.sizeUnits;
            imageSize = str2num(Config.plots.imageSize);
            fontSize = str2double(Config.plots.fontSize);
            imageFormat = Config.plots.imageFormat;
            imageQuality = Config.plots.imageQuality;
            imageResolution = Config.plots.imageResolution;

            if numel(myTrack)>1
                type = 'multi';
            else
                type = 'mono';
            end

        % PLOT:
            myFigure = figure(  'Units', sizeUnits, 'Position', imageSize,...
                                'Visible', myTracker.plotVisible,....
                                'Color', 'w');
            hold on;
            for i = 1:numel(myTrack)
                plot(myTrack(i).time, myTrack(i).shift);
            end

            myAxes = myFigure.CurrentAxes;
            myAxes.FontSize = fontSize;

            if strcmp(myTracker.plotTitle, 'on')
                title(myAxes, ['Frequency Tracking, ' myTracker.tag, ' domain']);
            end
            
            xlabel(myAxes, 'Time, sec');
            ylabel(myAxes, 'Shift, %');

            validityVector = [{myTrack.validity}];
            numberLength = num2cell(linspace(1,numel(myTrack), numel(myTrack)));
            freqRange = [{myTrack.freqRange}];
            labels = cellfun(@(x,y,z) strcat('#',num2str(x),' - validity=',num2str(y), ' f=', z, ' Hz'), numberLength, validityVector, freqRange, 'UniformOutput',false);

            legend(labels);
            grid on;

            if myTracker.printPlotsEnable
                % Save the image to the @Out directory
                imageNumber = '1';
                fileName = ['SST-',myTracker.tag, '-',type, '-', imageNumber];
                fullFileName = fullfile(pwd, 'Out', fileName);
                print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
            end
            
            % Close figure with visibility off
            if strcmpi(myTracker.plotVisible, 'off')
                close(myFigure)
            end
        end
        
        
    end
    
    
    methods (Static = true)
        
        % Estimate shift berween two spectrogram frames A and B
        function [shift] = estimateShift(A, B)

            A = normVect( A, 'max' );
            B = normVect( B, 'max' );

            [acor,lag] = xcorr(B,A);

            % Find shift of the max corr value
            [~, maxIdx] = max(abs(acor));
            shift = lag(maxIdx);

        end
        
        function [framesNumber, residueLength] = estimateFramesNumber(totalLength, frameLength, frameOverlapLength)
            
            frameStep = frameLength - frameOverlapLength;
            
            % If total length is too short to form several frames
            if (totalLength - (frameLength+frameStep))<0
                
                framesNumber = floor(totalLength/frameLength);
                if framesNumber == 0
                    residueLength = totalLength;
                else
                    residueLength = totalLength - framesNumber*frameLength + frameOverlapLength;
                end
                return;
            end

            % Estimate frames number and residue length
            LengthNeed = frameStep*floor(totalLength/frameStep) + frameOverlapLength;
            if totalLength == LengthNeed
                framesNumber = floor(totalLength/frameStep);
                residueLength = 0;
            elseif totalLength < LengthNeed
                framesNumber = floor(totalLength/frameStep)-1;
                delta = totalLength - (framesNumber*frameStep+frameOverlapLength);
                if delta < 0
                    framesNumber = floor(totalLength/frameStep) - ceil(abs(delta)/frameStep); 
                    if (totalLength - (framesNumber*frameStep+frameOverlapLength))<0
                        framesNumber = framesNumber-1;
                    end
                end
                residueLength = totalLength - framesNumber*frameStep;
            elseif totalLength > LengthNeed
                framesNumber = floor(totalLength/frameStep);
                residueLength = totalLength - framesNumber*frameStep;
            end
            
        end
        
        
        function [path, lastState] = optimizeSubtrack(pathTable, weightVector, srtState, frameLength, frameOverlap)

            if nargin < 4
                srtState = 1;
            end

            if nargin == 5
                frameStep = frameLength - frameOverlap;
            else
                frameStep = frameLength-1;
            end

            stateNumber = size(pathTable,2);
            stateVector = linspace(1,stateNumber, stateNumber);

            combinationMatrix = round(permn(stateVector,frameLength));
            combinationMatrix(combinationMatrix(:,1)~=srtState,:) = [];

            dataMatrix = zeros(size(combinationMatrix));
            weightMatrix = zeros(size(combinationMatrix));

            for i = 1:numel(stateVector)

                temp = zeros(size(dataMatrix));
                temp(combinationMatrix(:,:)==stateVector(i)) = 1;
                temp_weight = temp;
                temp = temp.*pathTable(:,stateVector(i))'; %%

                dataMatrix = dataMatrix + temp;

                temp_weight = temp_weight.*weightVector(i);
                weightMatrix = weightMatrix + temp_weight;
            end

            [~, pos] = min(sum(sqrt(diff(dataMatrix,1,2).^2 + 1),2));
    %         [~, pos] = min(sum(sqrt(diff(dataMatrix,1,2).^2 + 1 + diff(weightMatrix,1,2)),2));
    %         [~, pos] = min(sum(sqrt(diff(dataMatrix,1,2)).^2 + (weightMatrix(:,2:end).^2),2));

            if nargin == 5
                lastState = combinationMatrix(pos,frameStep+1);
                path = dataMatrix(pos,1:frameStep);
            elseif nargin < 5
                lastState = combinationMatrix(pos,frameStep+1);
                path = dataMatrix(pos,1:frameStep+1);
            end
        end
        
    end
    
end

