function [ result ] = timeDomainClassification( file, scalogramData, periodicityTable, config )
% TIMEDOMAINCLASSIFICATION perform time-domain analysis to detect defective
% element of the equeipment.
%
%   TIMEDOMAINCLASSIFICATION function decomposes vibration signal on the basis
%of SWD method, extracts significant parts, perform their clustrering and
%classification to detect defective element of the equeipment.
%
% INPUT:
% - file - original signal and it parameters (Fs, resonant frequencies ...)
% - scalogramData - structure with results of scalogram analysis. It 
%contains major resonant frequencies and energy contribution data
% - periodicityTable - structure with found periodicities for each resonant
%frequency in @scalogramData, it also contains periodicities type and
%validity
% - config - configuration structure
%
% OUTPUT:
% - result - structure containing detected element type and information 
%over the another possibly defective elements
%
% Version   : 1.0
% Developer : ASLM
% Date      : 03.08.2017
%
%
% Copyright (C) 2017 VibroBox



%% _____________________ DEFAULT_PARAMETERs ___________________________ %%

    parameters = config.sparseDecomposition;
    parameters.Attributes.plotVisible = config.Attributes.plotVisible;
    parameters.Attributes.plotTitle = config.Attributes.plotTitle;
    parameters.Attributes.printPlotsEnable = config.Attributes.printPlotsEnable;
    parameters.Attributes.parpoolEnable = config.Attributes.parpoolEnable;   
    parameters.Attributes.debugModeEnable = config.Attributes.debugModeEnable;   
    
    
    scalogramPointsNumber = length(scalogramData);
    result = [];
    if isempty(scalogramData)
        return;
    end
    
    
%% _______________________ Signal Decomposition _______________________ %%
    field2add = {
                    'frequencies';
                    'scales';
                    'energyContribution';
                    'lowFrequency';
                    'highFrequency';
                };   
    for i = 1:numel(field2add)
        file = arrayfun(@(x) setfield(x,field2add{i},[scalogramData.(field2add{i})]), file);
    end
    file.basisStep = 10;
    
    % Create a short signal to speed-up time-domain calculations
    if str2double(config.Attributes.shortSignalEnable)
        parameters1 = config.shortSignal.Attributes;
        parameters1.plotVisible = parameters.Attributes.plotVisible;
        parameters1.mono = config.shortSignal.mono.Attributes;
        parameters1.multi = config.shortSignal.multi.Attributes;
        file.signal = createShortSignal(file,parameters1);
    end
    
    myDecomposer = sparseFiltDecomposer(file,parameters);
    [swdData] = sparseDecomposition(myDecomposer);
    swdBasis = getMultiBasis(myDecomposer);
    
%% ______________ Pattern Extraction and Classification _______________ %%
    
    patternResult = cell(numel(scalogramPointsNumber));
    equipmentResult = cell(numel(scalogramPointsNumber));
    
    if str2double(config.Attributes.parpoolEnable)
        parfor i = 1:scalogramPointsNumber
            [patternResult{i}, equipmentResult{i}] = patternProcessing(file, swdData, swdBasis, config, i );
        end
    else
        for i = 1:1:scalogramPointsNumber
            [patternResult{i}, equipmentResult{i}] = patternProcessing(file, swdData, swdBasis, config, i );
        end
    end
    
    % Make a decision about element and its state
    data.patternData = cell2mat(patternResult);
    data.equipmentData = cell2mat(equipmentResult);
    data.signalTypeData = getSignalType(myDecomposer);
    data.periodicityData = periodicityTable;
    data.scalogramData = scalogramData;
    data.elementsList = file.elementsList;
    
    [myDM] = tdDecisionMaker(data, config);
    [result] = classification(myDM);
end
    
%% ----------------------- Subfunctions ------------------------------ %%
% PATTERNPROCESSING implements pattern extraction and classification
% procedures.
%
% INPUT:
% - signalData - signal parameters: Fs, resonant frequencies
% - swdData - signal decomposition on the basis of sparse wavelet
% decomposition
% - swdBasis - basis fucntion which are used for SWD procedure
% - config - configuration structure
% - id - resonant frequency number
%
% OUTPUT:
% - patternResult - structure contains detected element type by the pattern
% analysis and information over the another possible elements
% - equipmentResult - structure contains detected element type by the full
% BF-spectum analysis with feature selection
% 

function [patternResult, equipmentResult] = patternProcessing(signalData, swdData, swdBasis, config, id )

    patternResult = []; equipmentResult = [];

    if nargin < 5
       error('ptrn:cls: Not enough input arguments'); 
    end

    file.swdData = swdData{id,1};
    file.resonantFrequency = signalData.frequencies(id);
    file.signal = signalData.signal;

    file.basis = swdBasis;
    file.basis.basis = swdBasis.basis{id,1};

    file.periodFrequency = [];
    file.Fs = signalData.Fs;

%         save('testPatternExtractorData.mat');
%         load('testPatternExtractorData.mat');


    % Create features tables for extracted patterns and the whole
    % equipment
    
        parameters = config.patternExtraction;
        parameters.Attributes.plotVisible = config.Attributes.plotVisible;
        parameters.Attributes.plotTitle = config.Attributes.plotTitle;
        parameters.Attributes.printPlotsEnable = config.Attributes.printPlotsEnable;
        parameters.Attributes.parpoolEnable = config.Attributes.parpoolEnable;   
        parameters.Attributes.debugModeEnable = config.Attributes.debugModeEnable;   
        parameters.id = num2str(id);
        parameters.plots = config.plots;
        parameters.translations = config.translations;

    [myPatternExtractor] = patternExtractor(file, parameters);
    [myPatternExtractor] = selectPattern(myPatternExtractor);
    [patternData] = getPatternData(myPatternExtractor);
    [equipmentData] = getEquipmentData(myPatternExtractor);

    
    
    % Perform clustering and classification procedures to estimate
    % pattern and equipment type
        parameters = [];
        parameters = config.patternClassification;
        parameters.Attributes.plotVisible = config.Attributes.plotVisible;
        parameters.Attributes.plotTitle = config.Attributes.plotTitle;
        parameters.Attributes.printPlotsEnable = config.Attributes.printPlotsEnable;
        parameters.Attributes.parpoolEnable = config.Attributes.parpoolEnable;   
        parameters.Attributes.debugModeEnable = config.Attributes.debugModeEnable;   
        parameters.id = num2str(id);
        
    [patternResult] = patternClustering(patternData,parameters);
    [equipmentResult] = equipmentClassification(equipmentData,parameters);
end

