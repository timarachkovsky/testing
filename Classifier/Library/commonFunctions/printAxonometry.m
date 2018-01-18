% <printAxonometryEnable description="Enable print axonometry of history" value="1" weight="1"/>
% Creator: Kosmach
% Date:     18.02.2017

% Discrition: Finction draw spectra of history, and function also in
% history: currentData save as "axonometry.mat" history data should be
% rename as 1.mat 2.mat ...
% If you want change range. you should be breakpoint line 123 and change
% "config.rangeEnvelope" on your range (example: printFigure(accDirect
% ,accelerationSpectrum, '5 100')) range in Hz
function printAxonometry(config, files, File)

    dirName = fullfile(pwd);
    dirData = dir([dirName '\*.mat']);	% Get the data for the current directory
    fileList = {dirData.name}';	% Get a list of the files
    
    % Delete current file if it exist
    fileList(cellfun(@(x) strcmp(x,'axonometry.mat'), fileList)) = [];
    
    if length(fileList) > 1 && ~str2double(config.modeSaveData)
        
        % Sort of history files
        sortVector =  sort(cellfun(@(x) str2double(x), ...
        cellfun(@(x) x{1},regexp(fileList,'\d*','match'),'UniformOutput',false)));
        fileList = cellfun(@(x) [x '.mat'], arrayfun(@num2str, sortVector, 'unif', 0), 'UniformOutput', false);
        
        % Read files.xml
        numberFileHistory = length(files.files.history.file) + 1;

         listHistoryDate = cell(numberFileHistory, 1);
         listHistoryDate{1,1} = files.files.file.Attributes.date;
         listHistoryDate(2:numberFileHistory)  = arrayfun(@(x) ...
             files.files.history.file{1, x}.Attributes.date, ...
             (1:numberFileHistory - 1), 'UniformOutput', false)';

         listHistoryName = cell(numberFileHistory, 1);
         listHistoryName{1,1} = files.files.file.Attributes.name;
         listHistoryName(2:numberFileHistory) =  arrayfun(@(x) ...
             files.files.history.file{1, x}.Attributes.name, ...
             (1:numberFileHistory - 1), 'UniformOutput', false)';
        
         
         % Prepare for print
        lengthSamplesEnv = length(File.acceleration.envelopeSpectrum.frequencyVectorOriginal);
        lengthSamplesAcc = length(File.acceleration.spectrum.amplitude);
        lengthSamplesVel = length(File.velocity.spectrum.amplitude);
        lengthSamplesDisp = length(File.displacement.spectrum.amplitude);
        %% Create empty fields
       
        
        envelopeSpectrum.vectorTime = zeros(numberFileHistory, lengthSamplesEnv);
        envelopeSpectrum.vectorAmplit = zeros(numberFileHistory, lengthSamplesEnv);
        envelopeSpectrum.vectorFreq = zeros(numberFileHistory, lengthSamplesEnv);
        
        accelerationSpectrum.vectorTime = zeros(numberFileHistory, lengthSamplesAcc);
        accelerationSpectrum.vectorAmplit = zeros(numberFileHistory, lengthSamplesAcc);
        accelerationSpectrum.vectorFreq = zeros(numberFileHistory, lengthSamplesAcc);
        
        velocitySpectrum.vectorTime = zeros(numberFileHistory, lengthSamplesVel);
        velocitySpectrum.vectorAmplit = zeros(numberFileHistory, lengthSamplesVel);
        velocitySpectrum.vectorFreq = zeros(numberFileHistory, lengthSamplesVel);
        
        displacementSpectrum.vectorTime = zeros(numberFileHistory, lengthSamplesDisp);
        displacementSpectrum.vectorAmplit = zeros(numberFileHistory, lengthSamplesDisp);
        displacementSpectrum.vectorFreq = zeros(numberFileHistory, lengthSamplesDisp);
        
        %% Fill in first field of current data
        envelopeSpectrum.vectorTime(1,:) = ones(1, lengthSamplesEnv);
        envelopeSpectrum.vectorAmplit(1,:) = File.acceleration.envelopeSpectrum.amplitudeOrigin;
        envelopeSpectrum.vectorFreq(1,:) = File.acceleration.envelopeSpectrum.frequencyVectorOriginal;
        
        accelerationSpectrum.vectorTime(1,:)  = ones(1, lengthSamplesAcc);
        accelerationSpectrum.vectorAmplit(1,:) = File.acceleration.spectrum.amplitude;
        accelerationSpectrum.vectorFreq(1,:) = File.acceleration.frequencyVector;
        
        velocitySpectrum.vectorTime(1,:)  = ones(1, lengthSamplesVel);
        velocitySpectrum.vectorAmplit(1,:) = File.velocity.spectrum.amplitude;
        velocitySpectrum.vectorFreq(1,:) = File.velocity.frequencyVector;
        
        displacementSpectrum.vectorTime(1,:)  = ones(1, lengthSamplesDisp);
        displacementSpectrum.vectorAmplit(1,:) = File.displacement.spectrum.amplitude;
        displacementSpectrum.vectorFreq(1,:) = File.displacement.frequencyVector;
        
        %% Fill in first field of previous data
        for i = 2:1:numberFileHistory
            tempStruct = load(fileList{i-1});
            
            envelopeSpectrum.vectorTime(i, :) = ones(1,lengthSamplesEnv)*i;
            envelopeSpectrum.vectorAmplit(i,:) = tempStruct.spectra.env.amplit;
            envelopeSpectrum.vectorFreq(i,:) = tempStruct.spectra.env.freq;
            
            accelerationSpectrum.vectorTime(i,:)  = ones(1, lengthSamplesAcc)*i;
            accelerationSpectrum.vectorAmplit(i,:) =  tempStruct.spectra.accDirect.amplit;
            accelerationSpectrum.vectorFreq(i,:) = tempStruct.spectra.accDirect.freq;

            velocitySpectrum.vectorTime(i,:)  = ones(1, lengthSamplesVel);
            velocitySpectrum.vectorAmplit(i,:) = tempStruct.spectra.velDirect.amplit;
            velocitySpectrum.vectorFreq(i,:) = tempStruct.spectra.velDirect.freq;

            displacementSpectrum.vectorTime(i,:)  = ones(1, lengthSamplesDisp);
            displacementSpectrum.vectorAmplit(i,:) = tempStruct.spectra.dispDirect.amplit;
            displacementSpectrum.vectorFreq(i,:) = tempStruct.spectra.dispDirect.freq;
        end
        
        envelopeSpectrum.date = listHistoryDate;
        accelerationSpectrum.date = listHistoryDate;
        velocitySpectrum.date = listHistoryDate;
        displacementSpectrum.date = listHistoryDate;
        % Print 
        env = figure('Name','Envelope spectrum');
        env = printFigure(env ,envelopeSpectrum, config.range);
        
        accDirect = figure('Name', 'Acceleration spectrum');
        accDirect = printFigure(accDirect ,accelerationSpectrum, config.range);
        
        velDirect = figure('Name', 'Velocity spectrum');
        velDirect = printFigure(velDirect ,velocitySpectrum, config.range);
        
        dispDirect = figure('Name' ,'Displacement spectrum');
        dispDirect = printFigure(dispDirect ,displacementSpectrum, config.range);
        
    end
    
    %% Save curent data to .mat file
    spectra.env.amplit = File.acceleration.envelopeSpectrum.amplitudeOrigin;
    spectra.env.freq = File.acceleration.envelopeSpectrum.frequencyVectorOriginal;

    spectra.accDirect.amplit = File.acceleration.spectrum.amplitude;
    spectra.accDirect.freq = File.acceleration.frequencyVector;

    spectra.velDirect.amplit = File.velocity.spectrum.amplitude;
    spectra.velDirect.freq = File.velocity.frequencyVector;

    spectra.dispDirect.amplit = File.displacement.spectrum.amplitude;
    spectra.dispDirect.freq = File.displacement.frequencyVector;

    save('axonometry.mat', 'spectra');

    function figureObf = printFigure(figureObf ,struct, range)
        
        iLoger = loger.getInstance;
        
        range = str2num(range);
        df = struct.vectorFreq(1,2) - struct.vectorFreq(1,1);
        posStart = round(range(1)/df);
        posEnd = round(range(2)/df);
        if length(struct.vectorFreq(1,:)) < posEnd
            printWarning(iLoger, 'Incorrect choosing range, seted max range!')  
        else
            struct.vectorTime = struct.vectorTime(:, posStart:posEnd);
            struct.vectorAmplit = struct.vectorAmplit(:, posStart:posEnd);
            struct.vectorFreq = struct.vectorFreq(:, posStart:posEnd);
        end
       ax = get(figureObf,'CurrentAxes');
       if isempty(ax)
           surf(struct.vectorFreq, struct.vectorTime , struct.vectorAmplit);
       else
           surf(ax, struct.vectorFreq, struct.vectorTime , struct.vectorAmplit);
       end
       xlabel('Frequency'); ylabel('Data of signals'); zlabel('Amplitude');
       
       ax = get(figureObf,'CurrentAxes');
       set(ax,'YTick', struct.vectorTime(: ,1))
       set(ax,'YTickLabel', struct.date)
       set(ax,'YTickLabelRotation', 90)
      
       
