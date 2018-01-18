% Developer : ASLM
% Date      : 28/10/2016
% Version   : 1.0

function [File,config,equipmentProfile,informativeTags,Translations,files,signalStates] = initialization()
% INITIALIZATION funciton description goes here...   

%% __________________ Clean 'Out' directory ___________________________ %%
    
    fclose('all');
    dirName = fullfile(pwd,'Out');
    if ~exist(dirName, 'dir')
        mkdir(dirName)
    end
    dirData = dir(dirName);	% Get the data for the current directory
    dirIndex = [dirData.isdir];	% Find the index for directories
    fileList = {dirData(~dirIndex).name}';	% Get a list of the files
    if ~isempty(fileList)
        fileList = cellfun(@(x) fullfile(dirName,x),fileList,'UniformOutput',false);
        cellfun(@delete, fileList);
    end
  
%% ________________________ Start logging _____________________________ %%
    
    iLoger = loger.getInstance;
    iLoger = init(iLoger);
    
    printProgress(iLoger, 'Initialization');
    printComputeInfo(iLoger, 'Initialization', 'Start logging.');
    
%% ___________________ Check @In directory file _______________________ %%
    
    printComputeInfo(iLoger, 'Initialization', '@In directory files checking.');

    dirName = fullfile(pwd,'In');
    if ~(exist(dirName,'dir') == 7)
        error('There is no @In directory! \n');
    end
    
    % CONFIG file checking
    configPath = fullfile(pwd,'In','config.xml');
    if ~exist(configPath,'file')
        error('There is no @config.xml file in the @In directory!'); 
    else
        config = xml2struct(configPath);
    end
    
    %% _____________________ Loger initialization _____________________ %%
    
    tcpipSocketEnable = str2double(config.config.parameters.evaluation.loger.Attributes.tcpipSocketEnable);
    localhost = config.config.parameters.evaluation.loger.Attributes.localhost;
    localport = str2double(config.config.parameters.evaluation.loger.Attributes.localport);
    outputBufferSize = str2double(config.config.parameters.evaluation.loger.Attributes.outputBufferSize);
    attempts = str2double(config.config.parameters.evaluation.loger.Attributes.attempts);
    timeout = str2double(config.config.parameters.evaluation.loger.Attributes.timeout);
    logEnable = str2double(config.config.parameters.evaluation.loger.Attributes.logEnable);
    consoleEnable = str2double(config.config.parameters.evaluation.loger.Attributes.consoleEnable);
    
    if str2double(config.config.parameters.common.debugModeEnable.Attributes.value) && tcpipSocketEnable
        % Open the app 'server.exe'
        system(fullfile(pwd, 'Library', 'commonFunctions', 'server.exe &'));
    end
    
    iLoger = setAttempts(iLoger, attempts);
    iLoger = setTimeout(iLoger, timeout);
    iLoger = setTcpipParameters(iLoger, localhost, localport, outputBufferSize);
    iLoger = initWithParameters(iLoger, tcpipSocketEnable, logEnable, consoleEnable);
    
    %% ____ @In directory existence checking (A.Bourak 12.01.2017) ____ %%
    
    dirName = fullfile(pwd,'In');
    if (exist(dirName,'dir') == 7)
        printComputeInfo(iLoger, 'Initialization', 'The @In directory successfully found.');
    end
    if exist('config', 'var') == 1
        printComputeInfo(iLoger, 'Initialization', '@config.xml successfully found and loaded.');
    end
    
    %% ________ Calculate and set the total weight of the stages ______ %%
    
    totalWeight = 0;
    commonFieldsNames = fieldnames(config.config.parameters.common);
    for fieldNum = 1 : 1 : length(commonFieldsNames)
        % Exclude 'Attributes' field
        if ~strcmp(commonFieldsNames{fieldNum, 1}, 'Attributes')
            currentField = config.config.parameters.common.(commonFieldsNames{fieldNum, 1});
            fieldAttributes = fieldnames(currentField.Attributes);
            % Indices of attributes that contain the weight of functions
            weightIndex = contains(fieldAttributes, 'weight', 'IgnoreCase', true);
            % Attributes that contain the weight of functions
            weightAttributes = fieldAttributes(weightIndex);
            % Find fields with weight
            if ~isempty(weightAttributes)
                % Check the possibility of turn on/off function
                if isfield(currentField.Attributes, 'value')
                    % Check state of function (enable/disable)
                    if str2double(currentField.Attributes.value)
                        % Add weight enabled function
                        totalWeight = totalWeight + sum(cellfun(@(x) str2double(currentField.Attributes.(x)), weightAttributes));
                    end
                else
                    % Add weight permanently enabled function
                    totalWeight = totalWeight + sum(cellfun(@(x) str2double(currentField.Attributes.(x)), weightAttributes));
                end
            end
        end
    end
    iLoger = setTotalWeight(iLoger, totalWeight);
    
    printComputeInfo(iLoger, 'Initialization', 'Loger initialization COMPLETE.');
    
    %% ____________________ PLOTS parameters checking _________________ %
    % Check attributes config.config.parameters.common: printPlotsEnable,
    % parpoolEnable, debugModeEnable
    if checkField(config.config.parameters.common, 'printPlotsEnable', 'Attributes', 'value') && ...
            checkField(config.config.parameters.common, 'printPlotsEnable', 'Attributes', 'visible') && ...
            checkField(config.config.parameters.common, 'printPlotsEnable', 'Attributes', 'title') && ...
            checkField(config.config.parameters.common, 'parpoolEnable', 'Attributes', 'value') && ...
            checkField(config.config.parameters.common, 'debugModeEnable', 'Attributes', 'value')
        
        if any(strcmp(config.config.parameters.common.printPlotsEnable.Attributes.value, {'0', '1'})) && ...
                any(strcmp(config.config.parameters.common.parpoolEnable.Attributes.value, {'0', '1'})) && ...
                any(strcmp(config.config.parameters.common.debugModeEnable.Attributes.value, {'0', '1'})) && ...
                any(strcmp(config.config.parameters.common.printPlotsEnable.Attributes.visible, {'off', 'on'})) && ...
                any(strcmp(config.config.parameters.common.printPlotsEnable.Attributes.title, {'off', 'on'}))
            
            printComputeInfo(iLoger, 'Initialization', 'Common plotting parameters are correct.');
        else
%             printException(iLoger, 'error', 'Common plotting parameters are NOT correct!');
            printWarning(iLoger, 'Common plotting parameters are NOT correct!');
        end
    else
%         printException(iLoger, 'error', 'Common plotting parameters are NOT correct!');
        printWarning(iLoger, 'Common plotting parameters are NOT correct!');
    end
    
    % Check attributes config.config.parameters.evaluation.plots
    if checkField(config.config.parameters.evaluation, 'plots', 'Attributes')
        if isfield(config.config.parameters.evaluation.plots.Attributes, 'sizeUnits') && ...
                isfield(config.config.parameters.evaluation.plots.Attributes, 'imageSize') && ...
                isfield(config.config.parameters.evaluation.plots.Attributes, 'fontSize') && ...
                isfield(config.config.parameters.evaluation.plots.Attributes, 'imageFormat') && ...
                isfield(config.config.parameters.evaluation.plots.Attributes, 'imageQuality') && ...
                isfield(config.config.parameters.evaluation.plots.Attributes, 'imageResolution')
            
            % Get plots parameters
            sizeUnits = config.config.parameters.evaluation.plots.Attributes.sizeUnits;
            imageSize = str2num(config.config.parameters.evaluation.plots.Attributes.imageSize);
            fontSize = str2double(config.config.parameters.evaluation.plots.Attributes.fontSize);
            imageFormat = config.config.parameters.evaluation.plots.Attributes.imageFormat;
            imageQuality = str2double(config.config.parameters.evaluation.plots.Attributes.imageQuality);
            imageResolution = str2double(config.config.parameters.evaluation.plots.Attributes.imageResolution);
            if isa(sizeUnits, 'char') && ...
                    isa(imageFormat, 'char') && ...
                    isa(fontSize, 'double') && ...
                    isa(imageQuality, 'double') && ...
                    isa(imageResolution, 'double') && ...
                    isa(imageSize, 'numeric')
                
                % Acceptable data
                sizeUnitsList = {'points', 'pixels'};
                imageFormatList = {'jpeg'};
                if any(strcmp(sizeUnits, sizeUnitsList)) && ...
                        any(strcmp(imageFormat, imageFormatList)) && ...
                        (fontSize > 0) && ...
                        (imageQuality > 0) && (imageQuality <= 100) && ...
                        (imageResolution >= 0) && ...
                        (imageSize(3) > 0) && (imageSize(4) > 0)
                    
                    printComputeInfo(iLoger, 'Initialization', 'Plotting parameters are correct.');
                else
%                     printException(iLoger, 'error', 'Plotting parameters are NOT correct!');
                    printWarning(iLoger, 'Plotting parameters are NOT correct!');
                end
            else
%                 printException(iLoger, 'error', 'Plotting parameters are NOT correct!');
                printWarning(iLoger, 'Plotting parameters are NOT correct!');
            end
        else
%             printException(iLoger, 'error', 'Plotting parameters are NOT correct!');
            printWarning(iLoger, 'Plotting parameters are NOT correct!');
        end
    else
%         printException(iLoger, 'error', 'Plotting parameters are NOT correct!');
        printWarning(iLoger, 'Plotting parameters are NOT correct!');
    end
    
    %% ____________________ Files Checking ____________________________ %%
    
    % EQUIPMENTPROFILE file checking
    equipmentProfilePath = fullfile(pwd,'In','equipmentProfile.xml');
    if ~exist(equipmentProfilePath,'file')
        error('There is no @equipmentProfile.xml file in the @In directory!'); 
    else
        equipmentProfile = xml2struct(equipmentProfilePath);
        if exist('equipmentProfile', 'var') == 1
            printComputeInfo(iLoger, 'Initialization', '@equipmentProfile.xml successfully found and loaded.');
        end
    end
    
    % INFORMATIVETAGS file checking
    informativeTagsPath = fullfile(pwd,'In','informativeTags.xml');
    if ~exist(informativeTagsPath,'file')
        error('There is no @informativeTags.xml file in the @In directory!'); 
    else
        informativeTags = xml2struct(informativeTagsPath);
        % Checking the number of defects for current type of element
        % Write one defect in a cell as well as several defects
        classStructFields = fieldnames(informativeTags.classStruct);
        for fieldNum = 1 : 1 : length(classStructFields)
            if strfind(classStructFields{fieldNum, 1}, 'Classifier')
                currentClassifier = informativeTags.classStruct.(classStructFields{fieldNum, 1});
                classifierFields = fieldnames(currentClassifier);
                for elementNum = 1 : 1 : length(classifierFields)
                    if ~strcmp(classifierFields{elementNum, 1}, 'Attributes')
                        if isstruct(currentClassifier.(classifierFields{elementNum, 1}).defect)
                        informativeTags.classStruct.(classStructFields{fieldNum, 1}).(classifierFields{elementNum, 1}).defect = [];
                        informativeTags.classStruct.(classStructFields{fieldNum, 1}).(classifierFields{elementNum, 1}).defect{1, 1} = currentClassifier.(classifierFields{elementNum, 1}).defect;
                        end
                    end
                end
                clearvars currentClassifier classifierFields;
            end
        end
        clearvars classStructFields;
        if exist('informativeTags', 'var') == 1
            printComputeInfo(iLoger, 'Initialization', '@informativeTags.xml successfully found and loaded.');
        end
    end
    
    % TRANSLATIONS file checking %
    translationsPath = fullfile(pwd,'In','translations.xml');
    if ~exist(translationsPath,'file')
        error('There is no @translations.xml file in the @In directory!'); 
    else
        translations = xml2struct(translationsPath);
        if isfield(translations, 'translations')
            Translations = translations.translations;
            if checkField(Translations, 'envelope', 'Attributes', {'name', 'shortName'}) && ...
                    checkField(Translations, 'frequency', 'Attributes', {'name', 'value'}) && ...
                    checkField(Translations, 'centralFrequency', 'Attributes', 'name') && ...
                    checkField(Translations, 'lowPass', 'Attributes', 'name') && ...
                    checkField(Translations, 'bandPass', 'Attributes', 'name') && ...
                    checkField(Translations, 'highPass', 'Attributes', 'name') && ...
                    checkField(Translations, 'time', 'Attributes', {'name', 'value'}) && ...
                    checkField(Translations, 'actualPeriod', 'Attributes', 'name') && ...
                    checkField(Translations, 'magnitude', 'Attributes', 'name') && ...
                    checkField(Translations, 'value', 'Attributes', {'name', 'value'}) && ...
                    checkField(Translations, 'level', 'Attributes', 'name') && ...
                    checkField(Translations, 'coefficient', 'Attributes', 'name') && ...
                    checkField(Translations, 'modulationCoefficient', 'Attributes', 'name') && ...
                    checkField(Translations, 'result', 'Attributes', 'name') && ...
                    checkField(Translations, 'acceleration', 'Attributes', {'name', 'value'}) && ...
                    checkField(Translations, 'velocity', 'Attributes', {'name', 'value'}) && ...
                    checkField(Translations, 'displacement', 'Attributes', {'name', 'value'}) && ...
                    checkField(Translations, 'spectrum', 'Attributes', 'name') && ...
                    checkField(Translations, 'envelopeSpectrum', 'Attributes', 'name') && ...
                    checkField(Translations, 'directSpectrum', 'Attributes', 'name') && ...
                    checkField(Translations, 'octaveSpectrum', 'Attributes', 'name') && ...
                    checkField(Translations, 'signal', 'Attributes', {'name', 'shortName'}) && ...
                    checkField(Translations, 'timeSynchronousAveraging', 'Attributes', {'name', 'shortName'}) && ...
                    checkField(Translations, 'trend', 'Attributes', 'name') && ...
                    checkField(Translations, 'element', 'Attributes', 'name') && ...
                    checkField(Translations, 'defect', 'Attributes', {'name', 'shortName'}) && ...
                    checkField(Translations, 'method', 'Attributes', 'name') && ...
                    checkField(Translations, 'metrics', 'Attributes', 'name') && ...
                    checkField(Translations, 'shaftSpeedRefinement', 'Attributes', {'name', 'shortName'}) && ...
                    checkField(Translations, 'shaftSpeedTracking', 'Attributes', {'name', 'shortName'}) && ...
                    checkField(Translations, 'shift', 'Attributes', 'name') && ...
                    checkField(Translations, 'percent', 'Attributes', {'name', 'shortName'}) && ...
                    checkField(Translations, 'interference', 'Attributes', 'name') && ...
                    checkField(Translations, 'fuzzyValidator', 'Attributes', 'name') && ...
                    checkField(Translations, 'peaksNumber', 'Attributes', 'name') && ...
                    checkField(Translations, 'defectFrequencies', 'Attributes', 'name') && ...
                    checkField(Translations, 'scalogram', 'Attributes', {'name', 'value'}) && ...
                    checkField(Translations, 'spectrogram', 'Attributes', {'name', 'value'}) && ...
                    checkField(Translations, 'logarithm', 'Attributes', {'name', 'shortName'}) && ...
                    checkField(Translations, 'energyContribution', 'Attributes', 'name') && ...
                    checkField(Translations, 'swd', 'Attributes', 'name') && ...
                    checkField(Translations, 'normalized', 'Attributes', 'name') && ...
                    checkField(Translations, 'periodicity', 'Attributes', 'name') && ...
                    checkField(Translations, 'shaftTrajectoryDetection', 'Attributes', 'name') && ...
                    checkField(Translations, 'correlogram', 'Attributes', {'name', 'value'}) && ...
                    checkField(Translations, 'history', 'Attributes', 'name') && ...
                    checkField(Translations, 'basisFunction', 'Attributes', {'name', 'shortName'}) && ...
                    checkField(Translations, 'point', 'Attributes', 'name') && ...
                    checkField(Translations, 'resonant', 'Attributes', 'name')
            
                printComputeInfo(iLoger, 'Initialization', '@translations.xml successfully found and loaded.');
            else
%                 printException(iLoger, 'error', 'Translations fields are incomplete!');
                printWarning(iLoger, 'Translations fields are incomplete!');
            end
        else
%             printException(iLoger, 'error', 'Translations fields are incomplete!');
            printWarning(iLoger, 'Translations fields are incomplete!');
        end															
    end
    
    % FILES.XML checking
    filesPath = fullfile(pwd,'In','files.xml');
    if ~exist(filesPath,'file')
        error('There is no @files.xml file in the @In directory!'); 
    else
        files = xml2struct(filesPath);
        if exist('files', 'var') == 1
           printComputeInfo(iLoger, 'Initialization', '@files.xml successfully found and loaded.');
        end
    end
    
 %% _________ Check WAV files and convert [mV] to [m/s^2] _____________ %%
 
    dirName = fullfile(pwd,'In');
    dirData = dir(dirName);	% Get the data for the current directory
    dirIndex = [dirData.isdir];	% Find the index for directories
    fileList = {dirData(~dirIndex).name}';	% Get a list of the files
    
    if isempty(fileList)
       error('The @In directory is empty!'); 
    end
    
    fileList = cellfun(@(x) fullfile(dirName,x),fileList,'UniformOutput',false);
    [~,~,extentions] = cellfun(@fileparts,fileList,'UniformOutput',false);
    wavPositions = find(cellfun(@strcmp,extentions, repmat({'.wav'},size(extentions))));
    wavFilesNumber = length(wavPositions);
    
    if wavFilesNumber == 0
        error('There is no .wav files in the @In directory!');
    elseif wavFilesNumber > 1
        error('Too many .wav files in the @In directory!');
    else
        % Correct sensor sensitivity and  
        g = 9.81;
        nominalSensitivity = g*1000/str2double(config.config.parameters.sensor.Attributes.sensitivity); % [mV/g] --- > [(m/s^2)/V]
        sensitivityCorrection = str2double(config.config.parameters.sensor.Attributes.sensitivityCorrection);
        sensorSensitivity = nominalSensitivity*sensitivityCorrection; % [(m/s^2)/V] (corrected)
        [Y, Fs] = audioread(fileList{wavPositions,1});
        printComputeInfo(iLoger, 'Initialization', '.wav file successfully found in the @In directory.'); 
    end

    % Select channel number 
    % Only 1CH/2CH mode enable
    channelsNumber = str2double(config.config.parameters.sensor.Attributes.channelsNumber);
    primaryChannelNo = str2double(config.config.parameters.sensor.Attributes.primaryChannelNo);
    [m,n] = size(Y);
    maxChannelNumber = min(m,n);
    if primaryChannelNo > maxChannelNumber
        primaryChannelNo = 1;
    end
    if channelsNumber > 1 && maxChannelNumber > 1
        if primaryChannelNo == 1
            secondaryChannelNo = 2;
        else
            secondaryChannelNo = 1;
        end
    else
        secondaryChannelNo = 0;
    end
%     Y = Y(:,channelNo);
% 
    % Transform signal from [mV] to [m/s^2]
	Y = Y*sensorSensitivity; % Transform vibroacceleration signal from [V] to [m/s^2] 
    sensorLowFrequency = str2double(config.config.parameters.sensor.Attributes.lowFrequency);
    sensorHighFrequency = str2double(config.config.parameters.sensor.Attributes.highFrequency);

    if sensorHighFrequency > Fs/2
        error('Sensor "highFrequency" in config.xml is greater than Fs/2!');
    end
    
    %% _____________________ Signal Filtering _______________________ %%
    % Adaptive Noise Filtration ...
    if str2double(config.config.parameters.evaluation.preprocessing.adaptiveNoiseFiltering.Attributes.processingEnable)
        file.signal = Y;
        file.Fs = Fs;
        parameters = config.config.parameters.evaluation.preprocessing.adaptiveNoiseFiltering.Attributes;
        parameters.plotVisible = config.config.parameters.common.printPlotsEnable.Attributes.visible;
        Y = adaptFiltration(file, parameters);
    end
    % ... Adaptive Filtration
    
%     % Create high-pass filter to remove false frequency range which is
%     % already filtered by sensor hardware high-pass filter.
%     Rp = 1; Rs = 12; % default parameters
%       
%     Ws = sensorLowFrequency*(2/Fs);
%     Wp = sensorLowFrequency*2*(2/Fs);  
%     [n,Wn] = buttord(Wp,Ws,Rp,Rs);
%     [b, a] = butter(n , Wn , 'high');
%     Y = filter(b,a,Y);
%     
%     % Create low-pass filter to remove accelerometer resonant frequencies
%     Rp = 1; Rs = 12; % default parameters
%       
%     Wp = sensorHighFrequency*(2/Fs);
%     Ws = (sensorHighFrequency+2000)*(2/Fs);  
%     [n,Wn] = buttord(Wp,Ws,Rp,Rs);
%     [b, a] = butter(n , Wn , 'low');
%     Y = filter(b,a,Y);

    %% _______________________ Decimation _____________________________ %%
    
    if str2double(config.config.parameters.evaluation.preprocessing.decimation.Attributes.processingEnable)
        parameters = config.config.parameters.evaluation.preprocessing.decimation.Attributes;
        parameters.plotVisible = config.config.parameters.common.printPlotsEnable.Attributes.visible;
        file.signal = Y; file.Fs = Fs;
        [Y,Fs] = decimation(file,parameters);
        
        if sensorHighFrequency > Fs/2
            config.config.parameters.sensor.Attributes.highFrequency = num2str(Fs/2);
        end
    end
    
% ********************************************************************* %%
%% ************************* DEBUG_MODE ****************************** %%
    if str2double(config.config.parameters.common.debugModeEnable.Attributes.value)
        if str2double(config.config.parameters.evaluation.debugMode.Attributes.shortSignalEnable)
            
            len = round(str2double(config.config.parameters.evaluation.debugMode.shortSignal.Attributes.lengthSeconds) * Fs);
            startPos = round(str2double(config.config.parameters.evaluation.debugMode.shortSignal.Attributes.startSecond) * Fs);
            singalLength = size(Y,1); 
            if startPos == 0
               startPos = 1; 
            end
            if (len+startPos)<= singalLength
                Y = Y(startPos:startPos+len,:);
            else
                printWarning(iLoger, 'Debug mode: Too short signal to create the shorter one!');
            end
        end
        
        if str2double(config.config.parameters.evaluation.debugMode.Attributes.signalGenerationEnable)
            
            parameters = config.config.parameters.evaluation.debugMode.signalGenerator;
            parameters.Fs = num2str(Fs);
            Y = testSignalGenerator(parameters);
            
        end
    end
% ************************** DEBUG_MODE ******************************* %%
% ********************************************************************* %%


    File.acceleration.signal = Y(:,primaryChannelNo);
    File.Fs = Fs;
    
    if str2double(config.config.parameters.evaluation.debugMode.Attributes.signalGenerationEnable) && ...
            strcmp(config.config.parameters.evaluation.debugMode.signalGenerator.Attributes.mode, 'CH1+CH2')
        maxChannelNumber = 2;
    end
    if (~secondaryChannelNo) && (str2double(config.config.parameters.common.debugModeEnable.Attributes.value))
       secondaryChannelNo = 2; 
    end
    
    if channelsNumber > 1 && maxChannelNumber > 1 && secondaryChannelNo
       File.acceleration.secondarySignal = Y(:,secondaryChannelNo); 
    end
    
    threshold = str2double(config.config.parameters.evaluation.checkSignalSymmetry.Attributes.threshold);
    signalStates = checkSignalSymmetry(File.acceleration, threshold);
    
    printComputeInfo(iLoger, 'Initialization', '@In directory files checking COMPLETE.');
    iLoger = increaseWeight(iLoger, str2double(config.config.parameters.common.commonFunctions.Attributes.initializationWeight));
    printComputeInfo(iLoger, 'Initialization', 'Framework initialization COMPLETE.')
end

