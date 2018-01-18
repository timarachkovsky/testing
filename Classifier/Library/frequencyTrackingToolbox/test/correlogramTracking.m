function [ File, STATUS ] = correlogramTracking( File, config, tag)
%CORRELOGRAMTRACKING evaluates shift of frequency with respect to initial
%value
  
% Developer     : ASLM
% Version       : v1.0
% Date          :02/10/2017

if nargin == 0
   error('Not enough input arguments!') ;
end

STATUS = 'false';

if nargin ==1
    config = [];
end
    
% Default parameters
%     config = fill_struct(config, 'maxPercentDeviationError', '1');
%     config = fill_struct(config, 'maxPercentDeviation', '10');

    config = fill_struct(config, 'plotEnable', '0');
    config = fill_struct(config, 'debugModeEnable', '0');
    config = fill_struct(config, 'printPlotEnable', '0');
    config = fill_struct(config, 'plotVisible', 'off');
    config = fill_struct(config, 'baseFramesNumber', '5');
    
    baseFramesNumber = str2double(config.baseFramesNumber);
    
    plotEnable = str2double(config.plotEnable);
    printPlotsEnable = str2double(config.printPlotsEnable);
    plotVisible = config.plotVisible;
    
    sizeUnits = config.plots.sizeUnits;
    imageSize = str2num(config.plots.imageSize);
    fontSize = str2double(config.plots.fontSize);
    imageFormat = config.plots.imageFormat;
    imageQuality = config.plots.imageQuality;
    imageResolution = config.plots.imageResolution;
    
    Translations = config.translations;
    
%  INPUT:
    File.shift = [];
    logBasis = File.logBasis;
    t = File.time;
    spectrogramTable = File.spectrogram;
    fStep = File.frequencyStep;
    
    
% CALCULATION:    
%     % Estimate percent shift for each period of time
%     [baseFrameIdx, baseFrame] = findBaseFrameIdx(spectrogramTable, config);
    
%     figure('Color','w');
%     hold on;
    shiftMat = cell(1,baseFramesNumber);
%     corrValidityMat = cell(1,baseFramesNumber);
    shiftValidityMat = cell(1,baseFramesNumber);
%     corrCoeffValidityMat = cell(1,baseFramesNumber);
    status = zeros(size(1,baseFramesNumber));
    for j = 1:baseFramesNumber
    
        [diffShift] = NaN(size(spectrogramTable,2),1); 
%         [validity] = zeros(size(spectrogramTable,2),1); 
%         [corrCoeffValidity] = zeros(size(spectrogramTable,2),1); 
%         for i = 1:size(spectrogramTable, 2)-1
        for i = 1:size(spectrogramTable, 2)
    %         [diffShift(i+1)] = shiftEvaluation(spectrogramTable(:,1), spectrogramTable(:,i+1));
%             [diffShift(i+1),validity(i+1)] = shiftEvaluation(spectrogramTable(:,baseFrameIdx), spectrogramTable(:,i+1));
                [diffShift(i)] = shiftEvaluation(spectrogramTable(:,j), spectrogramTable(:,i));
        end
    %     diffShift(1) = 0;
%         validity(1) = 0;

        % Shift vector validation and interpolation
        shift = logBasis.^(diffShift*fStep);
        shift = (shift -1)*100; % recalculate to "%"
        [shift, status(j), lowValidity] = shiftValidation(shift,t,config);
%         plot(t,shift);
        
        shiftMat{j} = shift;
%         corrValidityMat{j} = validity;
        shiftValidityMat{j} = lowValidity;
%         corrCoeffValidityMat{j} = corrCoeffValidity;
    end

    
    % Check validity of the shift estimation
%     corrValidityMat = cell2mat(corrValidityMat);
    shiftValidityMat = cell2mat(shiftValidityMat);
    
    % Test
%     corrCoeffValidityMat = cell2mat(corrCoeffValidityMat);
    
%     corrValidityVector = rms(corrValidityMat,2);
    shiftValidityVector = sum(shiftValidityMat,2)/size(shiftValidityMat,2);
    weightVector = sum(shiftValidityMat,1)/size(shiftValidityMat,1);
%     corrCoeffValidityVector = rms(corrCoeffValidityMat,2);
    %
%     corrValiditySTATUS = (nnz(corrValidityVector>0.3)/size(corrValidityVector,1))>=0.6;
    shiftValiditySTATUS = (nnz(shiftValidityVector>0.33)/size(shiftValidityVector,1))<0.5;
%     
%     if ~shiftValiditySTATUS
%         STATUS = 'false';
%         File.shift = [];
% %         return 
%     else
%         STATUS = 'true';
%     end
    
    shiftMat = cell2mat(shiftMat);
    
    % TEST ...
    framesShiftDelta = shiftMat(1,:);
    shiftMat = shiftMat - framesShiftDelta;
    % ... TEST
    
    weightVector = zeros(size(weightVector));
    shift = pathMinimization(shiftMat, weightVector, config);
    
    [shift,statusValidity, approximationValidityVector] = shiftValidation(shift, t, config);
    
    if statusValidity && shiftValiditySTATUS
        STATUS = 'true';
    else
        STATUS = 'false';
%         File.shift = [];
%         return 
    end
    
    
%     hp = plot(t, shift);
%     hp.LineWidth = 2;
%     grid on;
% 
%     xlabel('Time, sec');
%     ylabel('Shift, %');
%     title('Frequency Tracking. Optimal Trace');
%     labels = [cellfun(@(x) num2str(x), mat2cell(linspace(1, baseFramesNumber, baseFramesNumber)', ones(baseFramesNumber,1),1), 'UniformOutput', false);'optimal'];
%     legend(labels);
%     
% OUTPUT:   
    File.shiftValidity = 1 - nnz(shiftValidityVector>0.33)/size(shiftValidityVector,1);
    File.shift = (shift/100+1);
    File.approximationValidityVector = sum(approximationValidityVector*(-1) + 1)/length(approximationValidityVector);
    File.percentStd = std(shift);
    %  __________________ Plot results _______________________________ %
    if plotEnable
 
        myFigure = figure('Units', sizeUnits, 'Position', imageSize, 'Visible', plotVisible, 'Color', 'w');
        hold on
        for i = 1:size(shiftMat,2)
            plot(t, shiftMat(:,i)); 
        end
        hp = plot(t, shift); grid on;
        hp.LineWidth = 2;
        
        myAxes = myFigure.CurrentAxes;
        % Set axes font size
        myAxes.FontSize = fontSize;
        
        % Figure title
        title(myAxes, [ upperCase(Translations.shaftSpeedTracking.Attributes.name, 'allFirst'),'. ',...
                        upperCase(Translations.correlogram.Attributes.name,'first'),' ', ...
                        upperCase(Translations.method.Attributes.name,'first'), '\_', tag ]);
                    
        % Figure labels
        xlabel(myAxes, [upperCase(Translations.time.Attributes.name, 'first'), ', ', ...
                        upperCase(Translations.time.Attributes.value, 'first')]);
        ylabel(myAxes, [upperCase(Translations.shift.Attributes.name, 'first'), ', ',...
                                  Translations.percent.Attributes.shortName]);

        labels = [cellfun(@(x) num2str(x), mat2cell(linspace(1, baseFramesNumber, baseFramesNumber)', ones(baseFramesNumber,1),1), 'UniformOutput', false);'optimal'];
        legend(labels);
        
        if printPlotsEnable
            % Save the image to the @Out directory
            imageNumber = '1';
            fileName = ['SST-correlogram_',tag,'-acc-' imageNumber];
            fullFileName = fullfile(pwd, 'Out', fileName);
            print(myFigure, fullFileName, ['-d', imageFormat, imageQuality], ['-r', imageResolution]);
        end
        
        % Close figure with visibility off
        if strcmpi(plotVisible, 'off')
            close(myFigure)
        end
    end

    
    
    
    % Calculate delay between 2 vectors with the same length
    function [shift, validity,coef] = shiftEvaluation(A, B)
        
        A = normVect( A, 'max' );
        B = normVect( B, 'max' );
        
        [acor,lag] = xcorr(B,A);
%         base = xcorr(A,'coeff');
%         next = xcorr(B,A,'coeff');
%         
%         [acor,lag] = xcorr(next,base);

        % Find shift of the max corr value
        [~, maxIdx] = max(abs(acor));
        x = corrcoef(B,A);
        coef = x(1,2);

        validity = acor(maxIdx)/sum((A.^2+B.^2)/2);
%         validity = acor(maxIdx)/sum((next.^2+base.^2)/2);
        shift = lag(maxIdx);
        
        
    function [shift_result,status,nanPositions] = shiftValidation(shift, time, config)

        if nargin == 2
           config = []; 
        end

    % INPUT: 
        shift_result = shift;
        nanPositions = zeros(size(shift));
        status = 0;

        config = fill_struct(config, 'maxPercentDeviationPerSec', '1');
        config = fill_struct(config, 'maxPercentDeviation', '10');
        config = fill_struct(config, 'maxInvalidPercent', '40');

        maxPercentDeviation = str2double(config.maxPercentDeviation);
        maxPercentDeviationPerSec = str2double(config.maxPercentDeviationPerSec);
        maxInvalidPercent = str2double(config.maxInvalidPercent);

        % Find out-of-range position and approximate them
%             shift((shift>maxPercentDeviation) | (shift< -maxPercentDeviation)) = NaN;
        
        sampleNumberPerSec = 1/(time(2)-time(1));
        maxPercentDeviationPerSample = maxPercentDeviationPerSec/sampleNumberPerSec;

    % CALCULATION:
        diffShift = [0;diff(shift)];

        posOutOfRange = (shift > maxPercentDeviation) | (shift < -maxPercentDeviation);
        posOutOfError_1 = (diffShift > maxPercentDeviationPerSample) | (diffShift < -maxPercentDeviationPerSample);

        shift_1 = shift;
        shift_1(posOutOfRange) = NaN;
        shift_1_app = inpaint_nans(shift_1);

%         diffShift_1 = [0;diff(shift_1_app)];

%         posOutOfError_2 = (diffShift_1 > maxPercentDeviationPerSample) | (diffShift_1 < -maxPercentDeviationPerSample);

%         shiftErr_1 = shift;
        shiftErr_1 = shift_1_app;
        shiftErr_1(posOutOfError_1) = NaN;
        shiftErr_1_app = inpaint_nans(shiftErr_1);

%         posOutOfError_1_up = diffShift_1 > maxPercentDeviationPerSample;
%         posOutOfError_1_down = (diffShift_1 < -maxPercentDeviationPerSample)*(-1);
%         strob = posOutOfError_1_up + posOutOfError_1_down;
%         
%         for i = 1:length(strob)
%            
%             
%             
%         end
% %         
% %         shiftErr_2 = shift;
% %         shiftErr_2(posOutOfError_2) = NaN;
% %         shiftErr_2_app = inpaint_nans(shiftErr_2);
% % %             diffShift_2 = [0,diff(shift_2)];

    % OUTPUT:
        
        nanPositions = posOutOfRange+posOutOfError_1;
        nanPercent = nnz(nanPositions)/numel(shift)*100;
        shift_result = shiftErr_1_app;
        if nanPercent <= maxInvalidPercent
            status = 1;
        else
            status = 0;
        end
        
            
    function [baseFrameIdx, baseFrame] = findBaseFrameIdx(spectrogramTable, config)

        if nargin == 1
           config = []; 
        end
        baseFrameIdx = 1;
        
    % INPUT: 
        config = fill_struct(config, 'baseFramesNumber', '5');
        baseFramesNumber = str2double(config.baseFramesNumber);
        
    % CALCULATION:
        spectrogramTable = spectrogramTable(:,1:baseFramesNumber);
        value = cell(baseFramesNumber,1);
        pos = cell(baseFramesNumber,1);
        for i = 1:baseFramesNumber
            [value{i}, pos{i}] = findpeaks(spectrogramTable(:,i), 'SortStr', 'descend' ,'NPeaks',3);
        end
        
        validity = cellfun(@(x) rms(x), value);
        [~,baseFrameIdx] = max(validity);
         % or
         
         baseFrame = sum(spectrogramTable,2);
        
    % OUTPUT:
            
     function [path] = pathMinimization(pathTable, weightVector, config)   
         
         if nargin == 2
            config = []; 
         elseif nargin == 1
             config = []; 
             weightVector = ones(pathTable,2);
         end
         
         config = fill_struct(config, 'frameLengthSample','5');
         config = fill_struct(config, 'frameOverlapSample','2');
         
         frameLength = str2double(config.frameLengthSample);
         frameOverlap = str2double(config.frameOverlapSample);
         frameStep = frameLength - frameOverlap;

%          framesNumber1 = (floor(size(pathTable,1)/frameLength)-1)*frameLength/(frameLength-frameOverlap) + 1;
        Length  = size(pathTable,1);
%         LengthNeed = frameLength*floor(Length/frameStep) + frameOverlap;
        LengthNeed = frameStep*floor(Length/frameStep) + frameOverlap;
        if Length == LengthNeed
            framesNumber = floor(Length/frameStep);
            LengthResidue = 0;
        elseif Length < LengthNeed
            framesNumber = floor(Length/frameStep)-1;
            if (Length - (framesNumber*frameStep+frameOverlap)) < 0
                framesNumber = floor(Length/frameStep)-2; 
            end
%             framesNumber = floor(Length/frameStep);
%             framesNumber = floor(Length/frameStep)-2;
            LengthResidue = Length - framesNumber*frameStep;
        end

%          framesNumber = floor(framesNumber1);
%          LengthResidue = round((framesNumber1-framesNumber)*frameLength);
         
         resVector = cell(framesNumber,1);
         lastState = 1;
         for i = 1:framesNumber
             [resVector{i},lastState] = minimizeSubpath(pathTable(1+(i-1)*frameStep:(i-1)*frameStep+frameLength,:), weightVector, lastState, frameLength, frameOverlap );
         end
         
         if LengthResidue > 0
             [resResidue{1}] = minimizeSubpath(pathTable(1+i*frameStep:i*frameStep+LengthResidue,:), weightVector, lastState, LengthResidue );
             path = cell2mat([resVector',resResidue])';
         else
             currentLength = size(resVector{end},2)*size(resVector,1);
             delta = Length - currentLength;
             if (delta) > 0
                [resResidue{1}] = minimizeSubpath(pathTable(1+i*frameStep:i*frameStep+delta,:), weightVector, lastState, delta );
                path = cell2mat([resVector',resResidue])';
             else
                path = cell2mat(resVector')';
             end
             
         end
         
         

     function [vector, lastState] = minimizeSubpath(pathTable, weightVector, srtState, frameLength, frameOverlap)

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
            vector = dataMatrix(pos,1:frameStep);
        elseif nargin < 5
            lastState = combinationMatrix(pos,frameStep+1);
            vector = dataMatrix(pos,1:frameStep+1);
        end
        
        
        
             