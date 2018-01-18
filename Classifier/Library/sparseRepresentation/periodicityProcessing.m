function [ result, resultForDocNode, data ] = periodicityProcessing( file, scalogramData, config, LogerObj )
%PERIODICITIESSEARCH function estimates the periodicities of the signal in
%the time domain

% Developer : ASLM
% Date :      29/05/2017

% Modified:   Kosmach 31/05/2017

    result = [];
    data = [];
    correctFlag = 1;
    %c = onCleanup(@()printFormatChecking(correctFlag, LogerObj));
    if isempty(scalogramData) || ~isfield(scalogramData,'frequencies')
        resultForDocNode = prepareTableForDocNode(result);
        return;
    end

    signal = file.signal;
    Translations = file.translations;
    parameters = repmat(config.correlationHandler, size(scalogramData));
    data = repmat(file,size(scalogramData));
    scales = 20*file.Fs./[scalogramData.frequencies];
    visStr = config.Attributes.plotVisible;
    if str2double(config.Attributes.printPlotsEnable)
        visStr = [visStr ', print'];
    end
    
    result = cell(size(scalogramData));
    
    % Use standard wavelet filtering instead of SWD to speed-up
    for si = 1:numel(scalogramData)  
        data(si).signal = cwt(signal, scales(si) ,'morl2')';
        parameters(si).pointNumber = si;
        parameters(si).pointFreq = scalogramData(si).frequencies;
        parameters(si).Attributes.plotEnable = config.Attributes.plotEnable;
        parameters(si).Attributes.printPlotsEnable = config.Attributes.printPlotsEnable;
        parameters(si).Attributes.plotVisible = config.Attributes.plotVisible;
        parameters(si).Attributes.plotTitle = config.Attributes.plotTitle;
        parameters(si).loger = config.loger;
        parameters(si).debugModeEnable = config.debugModeEnable;
        parameters(si).plots = config.plots;
        
        myCorrelationHandler = multiInterfCorrelationHandler(data(si), parameters(si), Translations);
        myCorrelationHandler = periodEstimation(myCorrelationHandler);

        result{si} = getResult(myCorrelationHandler);
        if ( ~isempty(result{si}) ) && ( ~isfield(result{si}, 'signalTypeLabel') )
            result{si} = arrayfun(@(x) setfield(x, 'type', 'unknown'), result{si});
        end
        if ( ~isempty(result{si}) )
            lblCells = repmat({myCorrelationHandler.signalTypeLabel}, size(result{si}));
            result{si} = arrayfun( @(x, y) setfield( x, 'type', reshape(y{:}, [], length(y{:})) ), result{si},  lblCells);
        end
        %Field number checking.
        if (numel(fieldnames(result{si})) ~= 18)
            correctFlag = 0;
        end
        if ~correctFlag
           printComputeInfo(LogerObj, 'Time-domain correlation periods finding', 'Result fields number mismatch.'); 
        end
        %Positive numbers checking - all results are positive numbers.
%         if ( ~isnumeric(result{si}.frequency) ) || ( isnan(result{si}.frequency) ) || ( (result{si}.frequency) <= 0 )
%             correctFlag = 0;
%         end
        correctFlag = all(arrayfun(@(x) resFieldCheck(x, 'frequency'), result{si}));
        if ~correctFlag
           printComputeInfo(LogerObj, 'Time-domain correlation periods finding', 'Results field of frequency has wrong format.'); 
        end
        correctFlagV = all(arrayfun(@(x) resFieldCheck(x, 'validity'), result{si}));
        if ~correctFlagV
           correctFlag = 0;
           printComputeInfo(LogerObj, 'Time-domain correlation periods finding', 'Results field of validity has wrong format.'); 
        end
        if str2double(config.Attributes.plotEnable)
            myCorrelationHandler.plotPeriodicy('all', 'signOrig');
        end
        % text(50, 50, num2str(scalogramData(si).frequencies)); % Is this command necessary? (From T. Rach)
    end
    
    % Form result structure
    validPositions = find(cellfun(@(x) ~isempty(x), result));
    if ~isempty(validPositions)
        for i = 1:numel(validPositions)
            result{validPositions(i)} = arrayfun(@(x) setfield(x,'energyContribution',scalogramData(validPositions(i)).energyContribution), result{validPositions(i)});
            result{validPositions(i)} = arrayfun(@(x) setfield(x,'resonantFrequency',scalogramData(validPositions(i)).frequencies), result{validPositions(i)});
            result{validPositions(i)} = arrayfun(@(x) setfield(x,'filtrationRange', [scalogramData(validPositions(i)).lowFrequency; scalogramData(validPositions(i)).highFrequency]), result{validPositions(i)});
            result{validPositions(i)} = arrayfun(@(x) orderfields(x), result{validPositions(i)});
        end
    
        if ~isempty(result)
            result = cell2mat(result(validPositions));
            %Parameters number equality checking.
            if numel({result.frequency})+numel({result.validity})+numel({result.type})+numel({result.energyContribution})+numel({result.resonantFrequency}) ~= 5*numel(result)
                correctFlag = 0;
                printComputeInfo(LogerObj, 'Time-domain correlation periods finding', 'Results fields number is not match.'); 
            end
        else
            result = [];
        end
    else
        result = [];
    end
    resultForDocNode = prepareTableForDocNode(result);
    %Field number checking.
    fNm = fieldnames(resultForDocNode);
    if numel(fNm) ~= 7
        correctFlag = 0;
        printComputeInfo(LogerObj, 'Time-domain correlation periods finding', 'DocNode fields number is not match.'); 
    end
    %Orientation and size checking.
    for i = 1:numel(fNm)
        sz = size(resultForDocNode.(fNm{i}));
        if (sz(1) ~= 1) && (sz(1) ~= 0)
            correctFlag = 0;
            printComputeInfo(LogerObj, 'Time-domain correlation periods finding', 'DocNode fields have wrong format.');
        end
    end
    printFormatChecking(correctFlag, LogerObj);
end

% PREPARETABLEFORDOCNODE function prepare of periodicity table for docNode
% structure
function resultForDocNode = prepareTableForDocNode(result)
    if isempty(result)
        resultForDocNode.frequency = [];
        resultForDocNode.validity = [];
        resultForDocNode.type = [];
        resultForDocNode.energyContribution = [];
        resultForDocNode.resonantFrequency = [];
        resultForDocNode.averageAmpl = []; resultForDocNode.filtrationRange = [];
    else
        % Convert to string and deleting empty
        % space in string (strsplit, strjoin)
        valData = arrayfun(@(x) x.validationData, result, 'UniformOutput', false); %Add some periodicys metrics (average amplitude).
        peakSequenceHeightRMS = cellfun(@(x) x.peakSequenceHeightRMSvalidity, valData);
        resultForDocNode.frequency = strjoin(strsplit(num2str(round(cell2mat({result.frequency}).*100)/100)));
        resultForDocNode.validity = strjoin(strsplit(num2str(round(cell2mat({result.validity}).*100)/100)));
        resultForDocNode.type = strjoin({result.type});
        resultForDocNode.energyContribution = strjoin(strsplit(num2str(round(...
            cell2mat({result.energyContribution}).*100)/100)));
        resultForDocNode.resonantFrequency = strjoin(strsplit(num2str(round(...
            cell2mat({result.resonantFrequency}).*100)/100)));
        resultForDocNode.averageAmpl = strjoin(strsplit(num2str(round(cell2mat({peakSequenceHeightRMS}).*100)/100)));
        fR = {result.filtrationRange};
%         filtrationRangeStr = arrayfun(@(x) num2str(round(fR(x, :).*100)/100), 1:2, 'UniformOutput', false);
%         resultForDocNode.filtrationRange = strjoin(cellfun(@(x) strjoin(strsplit(x)), filtrationRangeStr, 'UniformOutput', false), '; '); %Join rows by semicolon.
        resultForDocNode.filtrationRange = ...
            regexprep(strjoin(cellfun(@(x) num2str(round(x*100)'/100), fR, 'UniformOutput', false), ','),' +', ' ');
        
    end
end

function correctFlag = resFieldCheck(result, fieldNm)
    %Positive numbers checking.
    correctFlag = 1;
    if isempty(result)
       return; 
    end
    if ~isnumeric(result.(fieldNm))
        correctFlag = 0;
    else
        if isnan(result.(fieldNm))
            correctFlag = 0;
        else
            if result.(fieldNm) <= 0
                correctFlag = 0;
            end
        end
    end
end

function printFormatChecking(correctFlag, LogerObj)
    if correctFlag
        printComputeInfo(LogerObj, 'Time-domain correlation periods finding', 'Result of time-domain correlation periods finding has a correct format.');
    else
        printComputeInfo(LogerObj, 'Time-domain correlation periods finding', 'There is wrong format of result of time-domain correlation periods finding.');
    end
end