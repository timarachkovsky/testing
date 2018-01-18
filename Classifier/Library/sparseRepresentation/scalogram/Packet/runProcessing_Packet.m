%clc; clear all; clearvars;
%close all;
%startup

% Start timer ticing
tStart = tic;

try
%% _____________ Clean 'Out' directory ________________________________ %%

    dirName = fullfile(fileparts(mfilename('fullpath')),'Out');
    if ~exist(dirName)
        mkdir(dirName)
    end
    dirData = dir(dirName);	% Get the data for the current directory
    dirIndex = [dirData.isdir];	% Find the index for directories
    fileList = {dirData(~dirIndex).name}';	% Get a list of the files
    if ~isempty(fileList)
        fileList = cellfun(@(x) fullfile(dirName,x),...	% Prepend path to files
                      fileList,'UniformOutput',false);

        for i=1:1:numel(fileList)
                if exist(fileList{i,1})
                    delete(fileList{i,1}); 
                end
        end
    end
    
%% _____________ Start logging ________________________________________ %%
    
    % Save command window in 'log.txt'
    %diary(fullfile(fileparts(mfilename('fullpath')), 'Out', 'log.txt'));
    
    fprintf('In >>> Framework\n');
    fprintf('[Framework] Start logging.\n');
    fprintf('[Framework] The output directory is cleared.\n');

%% _____________ Set input parameters _________________________________ %%
    fprintf('[Framework] Proceed to the input parameters setting.\n');

    configFile = fullfile(fileparts(mfilename('fullpath')),'In','config.xml');
    equipmentProfilePath = fullfile(fileparts(mfilename('fullpath')),'In','equipmentProfile.xml');
    informativeTagsPath = fullfile(fileparts(mfilename('fullpath')),'In','informativeTags.xml');
    filesPath = fullfile(fileparts(mfilename('fullpath')),'In','files.xml');
    
    % Framework config,equipmentProfile & informativeTags structures
    config = xml2struct(configFile);
    equipmentProfile = xml2struct(equipmentProfilePath);
    informativeTags = xml2struct(informativeTagsPath);
    files = xml2struct(filesPath);
%     date = datestr(now,'dd-mm-yyyy');
    
    fprintf('[Framework] The input parameters are set.\n');
    
    % Set default parameters
    fprintf('[Framework] Proceed to the default parameters setting.\n');
    
    defaultParametersEn = str2num(config.config.parameters.common.defaultParametersEnable.Attributes.value);
    if (defaultParametersEn)
        config = setDefaultParameters(config);
        fprintf('[Framework] The default parameters are set.\n');
    else
        fprintf('[Framework] The default parameters are disabled!\n');
    end
        
%% _____________ Checking data files in 'IN' directory ________________ %%

if ~exist('PeaksOnly','var') PeaksOnly=false; end  %Full processing is default.

fileListValid=[];
    if ~PeaksOnly
        dirName = fullfile(fileparts(mfilename('fullpath')),'In');
        dirData = dir(dirName);	% Get the data for the current directory
        dirIndex = [dirData.isdir];	% Find the index for directories
        fileList = {dirData(~dirIndex).name}';	% Get a list of the files

        if ~isempty(fileList)
            fileList = cellfun(@(x) fullfile(dirName,x),...	% Prepend path to files
                           fileList,'UniformOutput',false);

            k=1;
            for i=1:1:numel(fileList)
                [pathstr,name,ext] = fileparts(fileList{i,1}) ;
                if strcmp(ext, '.wav')	% Cut file type
                    fileListValid{k,1} = fileList{i,1}; 
                    k = k+1;
                end
            end
        end
    end

    if (~isempty(fileListValid))||PeaksOnly %Execute this part if audio is exist or PeaksOnly.
        if ~PeaksOnly %If PeaksOnly it's doesn't important existence of audio. We only execute peakfinder
        %and fill file_info struct by peak information and parameters.
        %If we wanna to process files, PeaksOnly = false.

    %% ________________________ Run Parpool _______________________________ %%

            tParpoolStart = tic;

            if str2double(config.config.parameters.common.parpoolEnable.Attributes.value)
                poolobj = gcp('nocreate');
                if isempty(poolobj)
                    poolobj = parpool;
                end
            end

            tParpool = toc(tParpoolStart);


    %% ******************************************************************** %%
    %% ************************ MAIN_CACLULATIONS ************************* %%
    %% ******************************************************************** %%  
    
    
    %% _________________________ ENVELOPE_SPECTRUM ________________________ %%
                
            tEnvSpectrumStart = tic;
            
            %Reading from audio file and filling the file struct.
            [signal, Fs] = audioread(fileListValid{1,1});
            file.signal = signal; file.Fs = Fs;
            parameters = [];
            parameters = config.config.parameters.evaluation.getEnvSpectrum.Attributes;
            parameters = setfield(parameters, 'printPlotsEnable', config.config.parameters.common.printPlotsEnable.Attributes.value);
            parameters = setfield(parameters, 'parpoolEnable', config.config.parameters.common.parpoolEnable.Attributes.value);
            translations = informativeTags.classStruct.translations;
            file.envelopeSpectrum = getEnvSpectrum(file,parameters,translations);
            file.informativeTags = informativeTags;
            
            tEnvSpectrum = toc(tEnvSpectrumStart);
               
    %% ____________________ HARDWARE_PROFILE_PARSER________________________ %%
                
    %         deviceId = config.config.file.Attributes.deviceId;
            equipmentDataPointId = files.files.Attributes.equipmentDataPoint;
            % Parse kinematics
            myProfileParser = hardwareProfileParser(equipmentProfile, equipmentDataPointId);
            % Get nominal shaft frequency
            shaftFreqNominal = getShaftFreq(myProfileParser);
    
    %         fprintf('[Framework] Nominal shaft speed = %4.2f rpm\n', shaftFreqNominal.freq*60);
            % rpm - revolutions per minute
                
    %% _____________________ Shaft frequency correction algorithms ________ %%
                
                % Find all peaks in signal and fill table
                parameters = config.config.parameters.evaluation.dividedFindpeaks.Attributes;
                [ peakTable ] = dividedFindpeaks(file, parameters);          
                
    %% _________________________ FREQUENCY_CORRECTOR ______________________ %%
                
                tFreqCorrectorStart = tic;
                  
                if str2double(config.config.parameters.common.frequencyCorrectionEnable.Attributes.value)
                    myFrequencyCorrector = frequencyCorrector(file, myProfileParser, config);
                    myFrequencyCorrector = frequencyCorrection(myFrequencyCorrector);
                    myProfileParser = getKinematicsParser(myFrequencyCorrector);
                end
                
                tFreqCorrector = toc(tFreqCorrectorStart);
                
    %% _________________________ Create base docNode ______________________ %%
                
                classifierStruct = getClassifierStruct(myProfileParser);
                docNode = com.mathworks.xml.XMLUtils.createDocument('equipment');
                docRootNode = docNode.getDocumentElement;
                deviceName = classifierStruct.common.equipmentName;
                docRootNode.setAttribute('name',deviceName);       % get device name from equipmentProfile
                
                % Set device state ( on/off )
                zeroLevel = str2double(config.config.parameters.common.equipment.Attributes.zeroLevel);
                currentLevel = rms(file.signal);
                if isempty(zeroLevel) || currentLevel > zeroLevel
                    equipmentState = 'on';
                else
                    equipmentState = 'off';
                end
    
                docRootNode.setAttribute('equipmentState',equipmentState);
                
                %Set current calculation time to status file
                timeNode = docNode.createElement('processingTime');
                docRootNode.appendChild(timeNode);
    
    %% __________________________ SCHEME_CLASSIFIER _______________________ %%
            
            tEnvClassifierStart = tic;
            
            if str2double(config.config.parameters.common.envelopeClassifierEnable.Attributes.value)            
                % Create structure for classifier configuration consisting of
                % scheme elements and their parameters
                mySchemeClassifier =  schemeClassifier(classifierStruct, informativeTags, config, peakTable);
                mySchemeClassifier = createStatusStruct(mySchemeClassifier);
                [docNode] = fillDocNode(mySchemeClassifier,docNode);
                if str2double(config.config.parameters.common.printPlotsEnable.Attributes.value)
                    saveStatusImages ( mySchemeClassifier, file);
                end
            end
            
            tEnvClassifier = toc(tEnvClassifierStart);
            
    end        
    %% ______________________ SPARSE_DECOMPOSITION_METHODs ________________ %%

        tSparseDecompositionFullStart = tic;

        tScalogram = 0;
        tSparseProcessing = 0;
    
        %
        if str2double(config.config.parameters.common.sparseDecompositionEnable.Attributes.value)

            %% ___________________ Scalogram Calculations _________________ %%

            if str2double(config.config.parameters.evaluation.maxCoefScalogram.Attributes.processingEnable)
                tScalogramStart = tic;

    %         SCALOGRAMHANDLER test ...
                load(fullfile(fileparts(mfilename('fullpath')),'Out','result','file_info.mat'));
    if ~PeaksOnly
                parameters = [];
                parameters = config.config.parameters.evaluation.scalogramHandler;
                parameters.Attributes.parpoolEnable = config.config.parameters.common.parpoolEnable.Attributes.value;
                
                myScalogramHandler = scalogramHandler(file,parameters); % Create scalogram object
                myScalogram = getScalogram(myScalogramHandler); % Calculate scalogram
                [FD.coefficients, FD.frequencies, FD.scales] = getParameters(myScalogram);  %FD. %RTG redundant?
                save('scalogram_1.mat');

            % PEAKSFINDER test ...
                load('scalogram_1.mat');
			else
				FD = getFullScalogramData(myPeaksFinder);  %Get signal data that calculated previously. %RTG WHA?
                [myFileInfo] = getFileInfo(myPeaksFinder);  %Get file info to save it. %RTG WHA?
    end
            parameters = [];
            parameters = config.config.parameters.evaluation.scalogramHandler.peaksFinder;
            file.coefficients = FD.coefficients;
            file.frequencies = FD.frequencies;
            file.scalogramConfig = config.config.parameters.evaluation.scalogramHandler.scalogram;
            myPeaksFinder = peaksFinder(file,parameters);
            [myPeaksFinder] = findPeaks(myPeaksFinder);

            if ~PeaksOnly %Write to file if we compute data base.
				FileData_PeaksFinder=[FileData_PeaksFinder myPeaksFinder];
                save(fullfile(fileparts(mfilename('fullpath')),'Out','result','file_info.mat'),'FileData_PeaksFinder');
            else
                myPeaksFinder = myPeaksFinder.setFileInfo(myFileInfo);  %Save file info.
            end
            
            tScalogram = toc(tScalogramStart);
        end
        %% ____________________ Sparse Calculation _____________________%%
        
        if str2double(config.config.parameters.evaluation.sparseProcessing.Attributes.processingEnable)&&(~PeaksOnly)
        
            tSparseProcessingStart = tic;

            file.signal = signal;
            L = length(freqMatrix(:,1));

            fileTest(1,1) = file;
            for i=1:1:L
                fileTest(i,1) = file;
            end
            for i=1:1:L
                fileTest(i,1).frequencies = freqMatrix(i,:);
            end

            parameters = [];
            parameters = config.config.parameters.evaluation.sparseProcessing.Attributes;
            parameters = setfield(parameters, 'getOptIterationsNumber', config.config.parameters.evaluation.sparseProcessing.getOptIterationsNumber);
            parameters = setfield(parameters, 'sparseDecomposition', config.config.parameters.evaluation.sparseProcessing.sparseDecomposition);
            parameters = setfield(parameters, 'dividedFindpeaks', config.config.parameters.evaluation.sparseProcessing.dividedFindpeaks);
            parameters = setfield(parameters, 'periodEstimation', config.config.parameters.evaluation.sparseProcessing.periodEstimation);
            parameters = setfield(parameters, 'getSimilarElements', config.config.parameters.evaluation.sparseProcessing.getSimilarElements);
            parameters = setfield(parameters, 'dividedCorrelogramRough', config.config.parameters.evaluation.sparseProcessing.dividedCorrelogramRough);
            parameters = setfield(parameters, 'dividedCorrelogramAccurate', config.config.parameters.evaluation.sparseProcessing.dividedCorrelogramAccurate);
            parameters = setfield(parameters, 'dividedCorrelogramPattern', config.config.parameters.evaluation.sparseProcessing.dividedCorrelogramPattern);

            if str2double(config.config.parameters.common.parpoolEnable.Attributes.value)
                parfor i=1:1:L
                   result{i,1} = sparseProcessing( fileTest(i,1), parameters );
                end
            else
                for i=1:1:L
                   result{i,1} = sparseProcessing( fileTest(i,1), parameters );
                end
            end
            validResult = notNanResult(result);

            tSparseProcessing = toc(tSparseProcessingStart);
        end
    end
  
    tSparseDecompositionFull = toc(tSparseDecompositionFullStart);
    
%     if ~isempty(validResult)
%        file.mainFreqStruct = mainFreqStruct;
%        file.informativeTagsStruct = getInformativeTagsStruct(mySchemeClassifier);
%        file.informativeTagsFile = defConfigFile;
%        file.classifierStruct = classifierStruct;
%        baseStruct = createBaseStruct(file);
%        baseStruct = fillBaseStruct(baseStruct,validResult,file,config);
%     end

%% ________________________ CALCULATE_METRICS _________________________ %%
    
        tMetricsStart = tic;
        if str2double(config.config.parameters.common.metricsEnable.Attributes.value)&&(~PeaksOnly)

            parameters = [];
            parameters = config.config.parameters.evaluation.getMetrics.Attributes;
            [myRms, myExcess, myPeakFactor, myCrestFactor] = getMetrics(file, parameters);

            metricsNode = docNode.createElement('metrics');
            docRootNode.appendChild(metricsNode);

            % Add calculated metrics to docNode
            rmsNode = docNode.createElement('rms');
            rmsNode.setAttribute('value', num2str(myRms));
            excessNode = docNode.createElement('excess');
            excessNode.setAttribute('value', num2str(myExcess));
            peakFactorNode = docNode.createElement('peakFactor');
            peakFactorNode.setAttribute('value', num2str(myPeakFactor));
            crestFactorNode = docNode.createElement('crestFactor');
            crestFactorNode.setAttribute('value', num2str(myCrestFactor));

            metricsNode.appendChild(rmsNode);
            metricsNode.appendChild(excessNode);
            metricsNode.appendChild(peakFactorNode);
            metricsNode.appendChild(crestFactorNode);

        end
        tMetrics = toc(tMetricsStart);
    
%% ___________________________ SPM_METHOD _____________________________ %%
            
        tSpmStart = tic;
        if str2double(config.config.parameters.common.spmEnable.Attributes.value)&&(~PeaksOnly)
            parameters = [];
            if (isfield(config.config.parameters.evaluation, 'spm'))
                parameters = config.config.parameters.evaluation.spm.Attributes;
            end
            [lowLevel, highLevel, firstLevel, currentlowlevel, currentHighLevel] = SPMProcessing(file, equipmentDataPointId, parameters);

            % Set SPM levels to docNode element
            SPMNode = docNode.createElement('spm');
            docRootNode.appendChild(SPMNode);

            lowLevelNode = docNode.createElement('lowLevel');
            lowLevelNode.setAttribute('value',num2str(lowLevel));
            lowLevelNode.setAttribute('status',num2str(currentlowlevel));   % state level to the specified level       
            highlevelNode = docNode.createElement('highLevel');
            highlevelNode.setAttribute('value',num2str(highLevel));
            highlevelNode.setAttribute('status',num2str(currentHighLevel)); % state level to the specified level
            zeroLvlNode = docNode.createElement('zeroLevel');
            zeroLvlNode.setAttribute('value',num2str(firstLevel));

            SPMNode.appendChild(lowLevelNode);
            SPMNode.appendChild(highlevelNode);
            SPMNode.appendChild(zeroLvlNode); 

        end
        tSpm = toc(tSpmStart); 
        
%% _________________________ SPECTAL_METHOD ___________________________ %%
        
        tSpectralStart = tic;
        if str2double(config.config.parameters.common.spectralMethodEnable.Attributes.value)&&(~PeaksOnly)
            parameters = [];
            if (isfield(config.config.parameters.evaluation, 'spectralMethod'))
                parameters = config.config.parameters.evaluation.spectralMethod.Attributes;
            end
            [vRms1Log, vRms2Log, vRms3Log] = spectralMethodProcessing(file, parameters);
            
        end
            
%% _________________________ SPECTAL_METHOD ___________________________ %%

        if str2double(config.config.parameters.common.spectralMethodEnable.Attributes.value)&&(~PeaksOnly)
            parameters = [];
            if (isfield(config.config.parameters.evaluation, 'spectralMethod'))
                parameters = config.config.parameters.evaluation.spectralMethod.Attributes;
            end
            [vRms1Log, vRms2Log, vRms3Log] = spectralMethodProcessing(file, parameters);
            
            % Set spectral method levels to status file
            spectralMethodNode = docNode.createElement('spectralMethod');
            docRootNode.appendChild(spectralMethodNode);
            
            vRmsLogNode = docNode.createElement('vRmsLog');
            vRmsLogNode.setAttribute('vRms1Log',num2str(vRms1Log));
            vRmsLogNode.setAttribute('vRms2Log',num2str(vRms2Log));
            vRmsLogNode.setAttribute('vRms3Log',num2str(vRms3Log));
            
            spectralMethodNode.appendChild(vRmsLogNode);
        end
        
        tSpectral = toc(tSpectralStart);
        
%% _______________ Add TIME to docNode & print STATUS.xml _____________ %%
            
        tStop = toc(tStart);

        parpoolRunTimeNode = docNode.createElement('parpoolRun');
        parpoolRunTimeNode.setAttribute('value',num2str(tParpool));
        timeNode.appendChild(parpoolRunTimeNode);

        envSpectrumTimeNode = docNode.createElement('envSpectrum');
        envSpectrumTimeNode.setAttribute('value',num2str(tEnvSpectrum));
        timeNode.appendChild(envSpectrumTimeNode);

        freqCorrectorTimeNode = docNode.createElement('freqCorrector');
        freqCorrectorTimeNode.setAttribute('value',num2str(tFreqCorrector));
        timeNode.appendChild(freqCorrectorTimeNode);

        envClassifierTimeNode = docNode.createElement('envClassifier');
        envClassifierTimeNode.setAttribute('value',num2str(tEnvClassifier));
        timeNode.appendChild(envClassifierTimeNode);

        tScalogramTimeNode = docNode.createElement('scalogram');
        tScalogramTimeNode.setAttribute('value',num2str(tScalogram));
        timeNode.appendChild(tScalogramTimeNode);

        tSparseProcessingTimeNode = docNode.createElement('sparseProcessing');
        tSparseProcessingTimeNode.setAttribute('value',num2str(tSparseProcessing));
        timeNode.appendChild(tSparseProcessingTimeNode);

        tSparseDecompositionFullTimeNode = docNode.createElement('sparseDecompositionTotal');
        tSparseDecompositionFullTimeNode.setAttribute('value',num2str(tSparseDecompositionFull));
        timeNode.appendChild(tSparseDecompositionFullTimeNode);

        tMetricsTimeNode = docNode.createElement('metrics');
        tMetricsTimeNode.setAttribute('value',num2str(tMetrics));
        timeNode.appendChild(tMetricsTimeNode);

        tSpmTimeNode = docNode.createElement('spm');
        tSpmTimeNode.setAttribute('value',num2str(tSpm));
        timeNode.appendChild(tSpmTimeNode);

        tSpectralTimeNode = docNode.createElement('spectralMethod');
        tSpectralTimeNode.setAttribute('value',num2str(tSpectral));
        timeNode.appendChild(tSpectralTimeNode);

        totalTimeNode = docNode.createElement('total');
        totalTimeNode.setAttribute('value',num2str(tStop));
        timeNode.appendChild(totalTimeNode);

        fileName = 'status';
        xmlFileName = [fullfile(fileparts(mfilename('fullpath')),'Out', fileName),'.xml'];
        xmlwrite(xmlFileName,docNode);

        
%% ******************************************************************* %%
%% ******************** HISTORY_EVALUATION *************************** %%
%% ******************************************************************* %%

    if str2double(config.config.parameters.common.historyEnable.Attributes.value)
        
        tHistoryStart = tic;
        if str2double(config.config.parameters.common.envelopeClassifierEnable.Attributes.value)
%             [myEnvHistoryHandler] = envHistoryHandler(config);
            [myEnvHistoryHandler] = envHistoryHandler(config,files);
            myResult = getResult(myEnvHistoryHandler);
 
            docNode = fillDocNode(myEnvHistoryHandler,docNode);
        end
        
        tHistory = toc(tHistoryStart);
        tStop = toc(tStart);
        
        historyTimeNode = docNode.createElement('history');
        historyTimeNode.setAttribute('value',num2str(tHistory));
        timeNode.appendChild(historyTimeNode);
        
        timeNode.removeChild(totalTimeNode);
        totalTimeNode = docNode.createElement('total');
        totalTimeNode.setAttribute('value',num2str(tStop));
        timeNode.appendChild(totalTimeNode);
        
        fileName = 'status';
        xmlFileName = [fullfile(fileparts(mfilename('fullpath')),'Out', fileName),'.xml'];
        xmlwrite(xmlFileName,docNode);
        
%% _____________________ Merge status.xml files _______________________ %%
   % Creation of the result status file over the whole device
        if str2double(config.config.parameters.common.mergeFilesEnable.Attributes.value)
            devicesNumber = numel(config.config.history.device);
            statusFiles{1,1} = fullfile(fileparts(mfilename('fullpath')), 'Out','status.xml');
            if (devicesNumber == 1)
                equipmentDataPointId = str2num(config.config.history.device.Attributes.id);
                if(equipmentDataPointId ~= str2double(config.config.file.Attributes.deviceId))
                    statusFiles{2,1} =  getLastHistoryFilePath(equipmentDataPointId, config);
                    mergeHistory(statusFiles);
                else
                    fileName = 'equipmentStatus';
                    xmlFileName = [fullfile(fileparts(mfilename('fullpath')),'Out', fileName),'.xml'];
                    xmlwrite(xmlFileName,docNode);
                end
            else
                k=1;
                for i=1:1:devicesNumber
                    equipmentDataPointId = str2double(config.config.history.device{i}.Attributes.id);
                    if(equipmentDataPointId~=str2double(config.config.file.Attributes.deviceId))
                        statusFiles{i+k,1} = getLastHistoryFilePath(equipmentDataPointId, config);
                    else
                        k=0;
                    end
                end
                mergeHistory(statusFiles);
            end
        end
    end
        else
            fprintf('[Framework] Data files not found!\n');
        end

catch exception
    errorLog = exception.getReport('extended', 'hyperlinks', 'off');
    errorFileName = 'errors';
    errorFilePath = [fullfile(fileparts(mfilename('fullpath')),'Out',errorFileName),'.log'];
    fileId = fopen(errorFilePath,'w');
    fprintf(fileId,'%s\n', errorLog);
    fclose(fileId);
    fprintf('[Framework] ERROR!\n');
end

% poolobj = gcp('nocreate');
% if ~isempry(poolobj)
%     delete(poolobj);
% end

tFinish = toc(tStart);
fprintf('[Framework] Elapsed time is %5.3f sec.\n', tFinish);

fprintf('[Framework] Finish logging.\n');
fprintf('Out <<< Framework\n');

%diary off;