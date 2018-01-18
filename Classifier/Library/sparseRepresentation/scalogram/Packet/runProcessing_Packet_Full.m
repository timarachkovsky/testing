%clc;
%clear all; clearvars;
close all; 
fclose('all');
startup
Root = fileparts(mfilename('fullpath'));
cd(Root);

% Start timer ticing
tStart = tic;

try

%% ______________________ Initialization ______________________________ %%

   [file,config, equipmentProfile,informativeTags,files] = initialization();
   iLoger = loger.getInstance;

	%Load previously calculated data.
	if exist('FileData.mat')==2
		load(fullfile(fileparts(mfilename('fullpath')),'Out','result','FileData.mat'));
	end
   if ~exist('FullCompute','var')  %If we process the same file we don't need
       %to compute full data, scalogram for example, for faster processing.
       FullCompute=true; %Full computation by default.
   end
   if ~FullCompute
        %Disable unnecessary computaitions.
        config.config.parameters.common.parpoolEnable.Attributes.value = '0';
        config.config.parameters.evaluation.decimation.Attributes.processingEnable = '0';
        config.config.parameters.common.frequencyCorrectionEnable.Attributes.value = '0';
        config.config.parameters.common.envelopeClassifierEnable.Attributes.value = '0';

        config.config.parameters.common.metricsEnable.Attributes.value = '0';
        config.config.parameters.common.spmEnable.Attributes.value = '0';
        config.config.parameters.common.spectralMethodEnable.Attributes.value = '0';
        
		%Get finder class from common struct. Scalogram data the same, we only find peaks and decompose with new parameters.
		myPeaksFinder=FileData.myFinder;
		%Get settings.
		parameters = config.config.parameters.evaluation.scalogramHandler.peaksFinder;
		scalogramConfig = config.config.parameters.evaluation.scalogramHandler.scalogram;
		[myPeaksFinder] = setConfig(myPeaksFinder,parameters,scalogramConfig)
   end
   
%% ________________________ Run Parpool _______________________________ %%

    tParpoolStart = tic;

    if str2double(config.config.parameters.common.parpoolEnable.Attributes.value)
        printProgress(iLoger,'0.5', 'Run Parpool ...');
        poolobj = gcp('nocreate');
        if isempty(poolobj)
            myCluster = parcluster('local');
            maxPoolSize = myCluster.NumWorkers;
            poolobj = parpool(maxPoolSize); 
        end
        printProgress(iLoger,'1', 'Run Parpool COMPLETE');
    else
        poolobj = gcp('nocreate');
        if ~isempty(poolobj)
            delete(poolobj);
        end
    end

    tParpool = toc(tParpoolStart);
                
%% ******************************************************************** %%
%% ************************ MAIN_CACLULATIONS ************************* %%
%% ******************************************************************** %%  

%% _________________________ Decimation _______________________________ %%
    
    if str2double(config.config.parameters.evaluation.decimation.Attributes.processingEnable)
        parameters = []; parameters = config.config.parameters.evaluation.decimation.Attributes;
        file = decimation(file,parameters);
    end


    if FullCompute   
%% _________________________ ENVELOPE_SPECTRUM ________________________ %%
 
        tEnvSpectrumStart = tic;

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
        
    end %FullCompute
            
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
    else
        mySchemeClassifier = [];
    end

    tEnvClassifier = toc(tEnvClassifierStart);
        
%% ______________________ SPARSE_DECOMPOSITION_METHODs ________________ %%  

    tSparseDecompositionFullStart = tic;

    tScalogram = 0;
    tSparseProcessing = 0;
    %
    if str2double(config.config.parameters.common.sparseDecompositionEnable.Attributes.value)
        
        %% ___________________ Scalogram Calculations _________________ %%
        
        if str2double(config.config.parameters.evaluation.scalogramHandler.Attributes.processingEnable)
            tScalogramStart = tic;

			if ~FullCompute
				parameters = [];
				parameters = config.config.parameters.evaluation.scalogramHandler;
				parameters.Attributes.parpoolEnable = config.config.parameters.common.parpoolEnable.Attributes.value;
				myScalogramHandler = scalogramHandler(file, parameters);
				%Peaksfinder works here.
				[scales, myPeaksFinder] = getMaxCoefficients(myScalogramHandler);
				scales = scales'; %scales is a 'result' field - valid elements of a peaktable.
				
			else
				myPeaksFinder = peaksFinder(file,parameters);
				[myPeaksFinder] = findPeaks(myPeaksFinder);
			end
            
            tScalogram = toc(tScalogramStart);
        end
        %% ____________________ Sparse Calculation _____________________%%
        
        
        %Scales are peaks that were found by PeakFinder.
        if str2double(config.config.parameters.evaluation.sparseProcessing.Attributes.processingEnable)
                   
            tSparseProcessingStart = tic;
            
            parameters = config.config.parameters.evaluation.sparseProcessing;
            SparseRepresentation = sparseProcessing (file, scales, parameters);
			
			save(fullfile(fileparts(mfilename('fullpath')),'Out','result','data.mat'),'myPeaksFinder','SparseRepresentation');

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

%% ________________________ Sparse Classifier ________________________ %%

    % Create time-domain analysis (combine with freqeuncy-domain analysis)
    if str2double(config.config.parameters.common.sparseClassifierEnable.Attributes.value) == 1
        [mySparseClassifier] = sparseClassifier(result,config);
        if ~isempty(mySchemeClassifier)
            [mySparseClassifier] = initWithEnvelopeClassifier(mySparseClassifier,mySchemeClassifier);
        end
        [mySparseClassifier] = createStatusStruct(mySparseClassifier);
        [docNode] = fillDocNode(mySparseClassifier, docNode);
        [mySparseStatusStruct] = getStatusStruct(mySparseClassifier);
    end

%% ________________________ CALCULATE_METRICS _________________________ %%
    
        tMetricsStart = tic;
        if str2double(config.config.parameters.common.metricsEnable.Attributes.value)

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
        if str2double(config.config.parameters.common.spmEnable.Attributes.value)
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
        if str2double(config.config.parameters.common.spectralMethodEnable.Attributes.value)
            parameters = [];
            if (isfield(config.config.parameters.evaluation, 'spectralMethod'))
                parameters = config.config.parameters.evaluation.spectralMethod.Attributes;
            end
            [vRms1Log, vRms2Log, vRms3Log] = spectralMethodProcessing(file, parameters);
            
        end
            
%% _________________________ SPECTAL_METHOD ___________________________ %%

        if str2double(config.config.parameters.common.spectralMethodEnable.Attributes.value)
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
        xmlFileName = [fullfile(pwd,'Out', fileName),'.xml'];
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
        xmlFileName = [fullfile(pwd,'Out', fileName),'.xml'];
        xmlwrite(xmlFileName,docNode);
        
%% _____________________ Merge status.xml files _______________________ %%
   % Creation of the result status file over the whole device
        if str2double(config.config.parameters.common.mergeFilesEnable.Attributes.value)
            devicesNumber = numel(config.config.history.device);
            statusFiles{1,1} = fullfile(pwd, 'Out','status.xml');
            if (devicesNumber == 1)
                equipmentDataPointId = str2num(config.config.history.device.Attributes.id);
                if(equipmentDataPointId ~= str2double(config.config.file.Attributes.deviceId))
                    statusFiles{2,1} =  getLastHistoryFilePath(equipmentDataPointId, config);
                    mergeHistory(statusFiles);
                else
                    fileName = 'equipmentStatus';
                    xmlFileName = [fullfile(pwd,'Out', fileName),'.xml'];
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

catch exception
    errorLog = exception.getReport('extended', 'hyperlinks', 'off');
    errorFileName = 'errors';
    errorFilePath = [fullfile(pwd,'Out',errorFileName),'.log'];
    fileId = fopen(errorFilePath,'w');
    fprintf(fileId,'%s\n', errorLog);
    fclose(fileId);
    
    iLoger = loger.getInstance;
    printException(iLoger, 'error', exception.message);
%     fprintf('[Framework] ERROR!\n');
end

tFinish = toc(tStart);
fprintf('[Framework] Elapsed time is %5.3f sec.\n', tFinish);

fprintf('[Framework] Finish logging.\n');
fprintf('Out <<< Framework\n');

diary off;