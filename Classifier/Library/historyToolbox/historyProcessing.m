function  Data = historyProcessing( Data, files, config, nameStatusFile )
% HISTORYPROCESSING performs trend analysis in different methods to make
%condition monitoring results more proper and accurate
%
% Developer : Kosmach, ASML
% version   : 1.1

    myStatusWriter = statusWriter.getInstance;
    iLoger = loger.getInstance;
    
    Translations = Data.translations;

    % Add history parameters from files.xml to trend parameters
    nameAddField = fieldnames(files.files.history.Attributes);
    for i=1:1:length(nameAddField) 
        config.config.parameters.evaluation.history.trend.Attributes.(nameAddField{i}) = ...
            files.files.history.Attributes.(nameAddField{i});
    end
    
    % Add history parameters from config.xml to files.xml parameters
    nameAddField = fieldnames(config.config.parameters.evaluation.history.Attributes);
    if ismember('plotEnable',nameAddField)
        nameAddField(ismember(nameAddField,'plotEnable')) = [];
    end
    for i=1:1:length(nameAddField) 
        config.config.parameters.evaluation.history.trend.Attributes.(nameAddField{i}) = ...
            config.config.parameters.evaluation.history.Attributes.(nameAddField{i});
        % dummy...
        files.files.history.Attributes.(nameAddField{i}) = ...
            config.config.parameters.evaluation.history.Attributes.(nameAddField{i});
        % ... dummy
    end

    % *.xml to structure all history and current data
    [myXmlToStructHistory] = xmlToStructHistory(files, config);
    
    % Add information for decisionMakerHistory plotting
    if (config.config.parameters.common.decisionMakerEnable.Attributes.value)
        Data.statusesDecisionMaker = parserDecisionMakerHistory(myXmlToStructHistory, config);
    end
    
    % ____________________ Equipment state detection ___________________ %
    if str2double(config.config.parameters.common.equipmentStateDetectionEnable.Attributes.value)
        myEquipmentStateHistoryHandler = equipmentStateHistoryHandler(config, files, Translations, myXmlToStructHistory);
        myStatusWriter.docNode = fillDocNode(myEquipmentStateHistoryHandler, myStatusWriter.docNode);
    end
    
    % ____________________ Frequency corrector method __________________ %
    if str2double(config.config.parameters.common.frequencyCorrectionEnable.Attributes.value)
        [myFrequencyCorrectorHistoryHandler] = frequencyCorrectorHistoryHandler(config, files, Translations, myXmlToStructHistory);
        myStatusWriter.docNode = fillDocNode(myFrequencyCorrectorHistoryHandler, myStatusWriter.docNode);
    end

    % ____________________ Frequency domain classifier method __________ %
    if str2double(config.config.parameters.common.frequencyDomainClassifierEnable.Attributes.value)
        [myFrequencyDomainHistoryHandler] = frequencyDomainHistoryHandler(config, files, Translations, myXmlToStructHistory);
        myStatusWriter.docNode = fillDocNode(myFrequencyDomainHistoryHandler, myStatusWriter.docNode);
    end

    if str2double(config.config.parameters.common.timeDomainClassifierEnable.Attributes.value) || ...
          str2double(config.config.parameters.common.timeFrequencyDomainClassifierEnable.Attributes.value)
    % ____________________ Scalogram method ____________________________ %
        if str2double(config.config.parameters.evaluation.scalogramHandler.Attributes.processingEnable)
            [myScalogramHistoryHandler] = scalogramHistoryHandler(config, files, Translations, myXmlToStructHistory);
            myStatusWriter.docNode = fillDocNode(myScalogramHistoryHandler, myStatusWriter.docNode);
        end
        
    % ____________________ Periodicity method __________________________ %   
        if str2double(config.config.parameters.evaluation.periodicityProcessing.Attributes.processingEnable)
            [myPeroiodicityHistoryHandler] = peroiodicityHistoryHandler(config, files, Translations, myXmlToStructHistory);
            myStatusWriter.docNode = fillDocNode(myPeroiodicityHistoryHandler, myStatusWriter.docNode);
        end
    end

    % ____________________ Time domain classifier method _______________ %
    if str2double(config.config.parameters.common.timeDomainClassifierEnable.Attributes.value)
        [myTimeDomainHandler] = timeDomainHistoryHandler(config, files, Translations, myXmlToStructHistory);
        myStatusWriter.docNode = fillDocNode(myTimeDomainHandler, myStatusWriter.docNode);
    end

    if str2double(config.config.parameters.common.spmEnable.Attributes.value)
    % ____________________ SPM: dBc/dBm method _________________________ %  
        if str2double(config.config.parameters.evaluation.spm.spmDBmDBc.Attributes.processingEnable)        
            [mySpmDBmDBcHistoryHandler] = spmDBmDBcHistoryHandler(config, files, Translations, myXmlToStructHistory);
            myStatusWriter.docNode = fillDocNode(mySpmDBmDBcHistoryHandler, myStatusWriter.docNode); 
        end

    % ____________________ SPM: HR/LR method ___________________________ %
        if str2double(config.config.parameters.evaluation.spm.spmLRHR.Attributes.processingEnable)
            [mySpmLRHRHistoryHandler] = spmLRHRHistoryHandler(config, files, Translations, myXmlToStructHistory);
            myStatusWriter.docNode = fillDocNode(mySpmLRHRHistoryHandler, myStatusWriter.docNode);
        end
    end

    % ____________________ ISO15242 method _____________________________ %
    if str2double(config.config.parameters.common.iso15242Enable.Attributes.value)
        [myIso15242HistoryContainer] = iso15242HistoryHandler(config, files, Translations, myXmlToStructHistory);
        myStatusWriter.docNode = fillDocNode(myIso15242HistoryContainer, myStatusWriter.docNode);
    end

    % ____________________ Metrics method ______________________________ %
    if str2double(config.config.parameters.common.metricsEnable.Attributes.value)
        myMetricsHistoryHandler = metricsHistoryHandler(config, files, Translations, myXmlToStructHistory);
        myStatusWriter.docNode = fillDocNode(myMetricsHistoryHandler, myStatusWriter.docNode);
    end

    % ____________________ Octave Spectrum method ______________________ %
    if str2double(config.config.parameters.common.octaveSpectrumEnable.Attributes.value)           
       myOctaveSpectrumHandler = octaveSpectrumHistoryHandler(config, files, Translations, myXmlToStructHistory);
       myStatusWriter.docNode = fillDocNode(myOctaveSpectrumHandler, myStatusWriter.docNode);
    end

    % ____________________ Time-frequency classifier method ____________ %
    if str2double(config.config.parameters.common.timeFrequencyDomainClassifierEnable.Attributes.value)
        [myTimeFrequencyDomainHandler] = timeFrequencyDomainHistoryHandler(config, files, Translations, myXmlToStructHistory);
        myStatusWriter.docNode = fillDocNode(myTimeFrequencyDomainHandler, myStatusWriter.docNode);
    end
    
    % ______________________ Time synchronous averaging _________________ %
    if str2double(config.config.parameters.common.timeSynchronousAveragingEnable.Attributes.value)
        [mytimeSynchronousAveragingHandler] = timeSynchronousAveragingHistoryHandler(config, files, Translations, myXmlToStructHistory);
        myStatusWriter.docNode = fillDocNode(mytimeSynchronousAveragingHandler, myStatusWriter.docNode);
    end
    
    %Checked update status.xml
    if exist(fullfile(pwd, 'Out', nameStatusFile), 'file') == 2
        printComputeInfo(iLoger, 'Framework', '@status.xml file was successfully updated by history.');
    else
        error('@status.xml file was not update by history! \n');
    end
    
end