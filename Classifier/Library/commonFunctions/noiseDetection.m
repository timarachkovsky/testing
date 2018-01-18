function [ resultStatus ] = noiseDetection(File, config)
% NOISEFETECTIONPROCESSING function determines the noise signal

    config = fill_struct(config, 'highThresholdFrequency','1000');
    config = fill_struct(config, 'requiredPeaksNumber','100');
    config = fill_struct(config, 'requiredPeaksProminenceRms','4');
    config = fill_struct(config, 'requiredMaxProminence','4.5');
    config = fill_struct(config, 'lowThresholdFrequency','5');
    config = fill_struct(config, 'requiredPeakFactorEnvelope','20');
    config = fill_struct(config, 'requiredPeakFactorDirect','20');

    % Configure parameters
    highThresholdFrequency = str2double(config.highThresholdFrequency);  
    requiredPeaksNumber = str2double(config.requiredPeaksNumber);
    requiredPeaksProminenceRms = str2double(config.requiredPeaksProminenceRms);
    requiredMaxProminence = str2double(config.requiredMaxProminence);
    lowThresholdFrequency = str2double(config.lowThresholdFrequency);
    
    directSpectrum = File.acceleration.spectrum.amplitude;
    envelopeSpectrum = File.acceleration.envelopeSpectrum.amplitude;
    peakTable = File.acceleration.envelopeSpectrum.peakTable;
    
    df = File.Fs/length(File.acceleration.signal);
    
    % Calculate peak factor for envelope spectrum in default range [1 1000] Gh
    posHigh = round(highThresholdFrequency/df);     
    currentPeakFactorEnvelope = max(envelopeSpectrum(1:posHigh))/rms(envelopeSpectrum(1:posHigh));
    
    % Calculate peak factor for direct spectrum in default range [5 1000] Gh
    posLow = round(lowThresholdFrequency/df);
    currentPeakFactorDirect = max(directSpectrum(posLow :posHigh))/rms(directSpectrum(posLow:posHigh));

    statusEnvelope = currentPeakFactorEnvelope > str2double(config.requiredPeakFactorEnvelope);
    statusDirect = currentPeakFactorDirect > str2double(config.requiredPeakFactorDirect);
    
    if statusEnvelope || statusDirect
        resultStatus = 1;
    elseif isempty(peakTable)
        resultStatus = 0.25;
    else
        currentPeaksNumber = find(peakTable(:,1) > highThresholdFrequency,1,'first');

        if isempty(currentPeaksNumber)
            currentPeaksNumber = nnz(peakTable(:,1));
        end

        currentPeaksProminenceRms = rms(peakTable(peakTable(:,1) <= peakTable(currentPeaksNumber,1),3));
        currentMaxProminence = max(peakTable(peakTable(:,1) <= peakTable(currentPeaksNumber,1),3));

        if isempty(currentPeaksNumber)
            currentPeaksNumber = nnz(peakTable(:,1));
        end

        peaksNumberStatus = requiredPeaksNumber < currentPeaksNumber;
        peaksProminenceRmsStatus = requiredPeaksProminenceRms < currentPeaksProminenceRms;
        maxProminenceStatus = requiredMaxProminence < currentMaxProminence;

        % FIS
        container = newfis('optipaper');

        % INPUT:
        % Init 2-states @peaksNumberStatus variable
        container = addvar(container, 'input', 'peaksNumberStatus', [-0.2 1.2]);
        container = addmf(container, 'input', 1, 'no', 'zmf',[0.4375 0.625]);
        container = addmf(container, 'input', 1, 'yes', 'smf',[0.375 0.5625]);

        % INPUT:
        % Init 2-states @peaksProminenceRmsStatus variable
        container = addvar(container, 'input', 'peaksProminenceRmsStatus', [-0.2 1.2]);
        container = addmf(container, 'input', 2, 'no', 'zmf',[0.4375 0.625]);
        container = addmf(container, 'input', 2, 'yes', 'smf',[0.375 0.5625]);

        % INPUT:
        % Init 2-states @maxProminenceStatus variable
        container = addvar(container, 'input', 'maxProminenceStatus', [-0.2 1.2]);
        container = addmf(container, 'input', 3, 'no', 'zmf',[0.4375 0.625]);
        container = addmf(container, 'input', 3, 'yes', 'smf',[0.375 0.5625]);

        % OUTPUT:
        % Init 2-state @result variable
        container = addvar(container,'output','result',[-0.2 1.2]);
        container = addmf(container,'output',1,'noies','zmf',[0.4375 0.625]);
        container = addmf(container,'output',1,'notNoies','smf',[0.375 0.5625]);

        % RULEs:
        % peaksNumberStatus, peaksProminenceRmsStatus, maxProminenceStatus

        ruleList = [ 1  1  1  1  1  1;
                     2  2  2  2  1  1;

                     1  2  2  2  1  1;
                     1  1  2  2  1  1; 
                     1  2  1  1  1  1;

                     2  1  2  2  1  1;  
                     2  2  1  2  1  1;
                     2  1  1  1  1  1;
                   ];

        container = addrule(container, ruleList);

        % Set input arguments for fuzzy calculations
        inputArgs = [peaksNumberStatus, peaksProminenceRmsStatus, maxProminenceStatus];

        resultStatus = evalfis(double(inputArgs), container);
    end
    if resultStatus > 0.5
 		resultStatus = 'on';
    else
 		resultStatus = 'off';
    end
end

