function [ result ] = sparseProcessing( file, scalogramData, config )
%SPARSEPROCESSING function decomposes the signal by the specific wavelet
%basis and impletment patterns extraction


%%% ONLY FOR TESTING!! THIS FUNCTION IS CURRENTLY UNUSED !!! 


%% _____________________ DEFAULT_PARAMETERs ___________________________ %%

    parameters = config.sparseDecomposer;
    parameters.Attributes.plotEnable = config.Attributes.plotEnable;
    parameters.Attributes.plotVisible = config.Attributes.plotVisible;
    parameters.Attributes.printPlotsEnable = config.Attributes.printPlotsEnable;
    parameters.Attributes.parpoolEnable = config.Attributes.parpoolEnable;   
    scalogramPointsNumber = length(scalogramData);
    result = [];
    if isempty(scalogramData)
        return;
    end
    
%     % TEST ...
%     highFrequency = scalogramData(1).highFrequency;
%     lowFrequency = scalogramData(1).lowFrequency;
%     Fs = file.Fs;
%      Wp = [lowFrequency*2/Fs highFrequency*2/Fs];
%         Ws=[(lowFrequency-0.1*lowFrequency)*2/Fs (highFrequency+0.1*highFrequency)*2/Fs]; 
%     [n,Wn1] = buttord(Wp,Ws,0.1,10);
%     [b1,a1] = butter(2 ,Wn1);
%     filteredSignal = filtfilt(b1,a1,file.signal);
%     % ... TEST
    
    
    % Implement wavelet filtering and sparse decomposition 
    file.basisStep = 10;
    for i=1:1:scalogramPointsNumber
        file.frequencies(i) = scalogramData(i).frequencies;
        file.scales(i) = scalogramData(i).scales;
        file.energyContribution(i) = scalogramData(i).energyContribution;
        file.lowFrequency(i) = scalogramData(i).lowFrequency;
        file.highFrequency(i) = scalogramData(i).highFrequency;
    end
    
    % TEST .......................
    %     save('dec1date.mat'); 
    %     load('dec1date.mat');
    myDecomposer = sparseDecomposer(file,parameters);
    [swdData] = sparseDecomposition(myDecomposer);
    myMultiBasis = getMultiBasis(myDecomposer);
    
    
    for i = 1:1:scalogramPointsNumber


        file1.signal = swdData{i,1}(end).sparseSignal;
        file1.Fs = file.Fs;
        parameters = []; parameters = config.correlationHandler;
        parameters.Attributes.printPlotsEnable = config.Attributes.printPlotsEnable.Attributes.value;
        parameters.Attributes.plotVisible = config.Attributes.printPlotsEnable.Attributes.visible;
        parameters.pointNumber = i; 
        parameters.pointFreq = scalogramData(i).frequencies;
        
        myCorrelationHandler = multiInterfCorrelationHandler(file1, parameters);
        [myCorrelationHandler] = periodEstimation(myCorrelationHandler);
        
        [someData] = getResult(myCorrelationHandler);
        
        file2.swdData = swdData{i,1};
        file2.resonantFrequency = file.frequencies(i);
        file2.signal = file.signal;
        
        file2.basis = myMultiBasis;
        file2.basis.basis = myMultiBasis.basis{i,1};
        
        if isempty(someData)
            file2.periodFrequency = [];
        else
            file2.periodFrequency = someData.frequency;
        end
        file2.Fs = file.Fs;
        
%         save('testPatternExtractorData.mat');
%         load('testPatternExtractorData.mat');
            parameters1.Attributes.plotEnable = config.Attributes.plotEnable;
            parameters1.Attributes.plotVisible = config.Attributes.plotVisible;
            parameters1.Attributes.printPlotsEnable = config.Attributes.printPlotsEnable;
            parameters1.Attributes.parpoolEnable = config.Attributes.parpoolEnable;  
            signalId = num2str(i);
            
        [myPatternExtractor] = patternExtractor(file2, parameters1,signalId);
        [myPatternExtractor] = selectPattern(myPatternExtractor);
        [patternData] = getPattern(myPatternExtractor);


    end
end
