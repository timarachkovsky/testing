% Creator   Kosmach N.
% Date       24.01.2017 

% Description:
% function of finding parameters for automatic thresholds
% input:
% trainingPeriodStd - std in training period (vector double or cell) ([current time  current time-1 ...  last time])
% trainingPeriodMean - mean in training period (vector double or cell) ([current time  current time-1 ...  last time])
% myFiles - structure to files.xml
% timeVector - time vector after history compression (last time  ...  current time-1  current time)
% vectorData - data vector after history compression (last time  ...  current time-1  current time)
% strMetricStatus - current status (isempty or ~isempty) example: 'green', ''.

% Function have 2 mode:
% 1) training (trainingPeriodStd, trainingPeriodMean) and calculate status(strMetricStatus)
% 2) calculate status(strMetricStatus)
function [strMetricStatus, trainingPeriodMain, trainingPeriodAdditional, thresholds] = getTrainingPeriodAndStatus( ...
    trainingPeriodAdditional, trainingPeriodMain, myFiles, timeVector, dataVector, strMetricStatus, rawTime, varargin)

    if nargin == 5
        strMetricStatus = [];
    end

    if nargin == 6
        rawTime = [];
    end

    thresholds = nan(3,1);
    iLoger = loger.getInstance;
    if length(timeVector) > 3
        if iscell(trainingPeriodMain)
            trainingPeriodMain = trainingPeriodMain{2,1};
            trainingPeriodAdditional = trainingPeriodAdditional{2,1};
        else
            trainingPeriodMain = trainingPeriodMain(2,1);
            trainingPeriodAdditional = trainingPeriodAdditional(2,1);
        end
        if ~isempty(trainingPeriodAdditional) || ~isempty(trainingPeriodAdditional)
            if isnan(trainingPeriodMain) || isnan(trainingPeriodAdditional)
                trainingPeriodMain = [];
                trainingPeriodAdditional = [];
            end
        end
        if str2double(myFiles.files.history.Attributes.trainingPeriodEnable) && isempty(strMetricStatus)       

            % get parametrs training period
            trainingPeriodLastDate = myFiles.files.history.Attributes.trainingPeriodLastDate;  
            trainingPeriod = str2double(myFiles.files.history.Attributes.trainingPeriod);

            % convert char  data to number data
            if strcmp(myFiles.files.history.Attributes.compressionPeriodTag, 'day')     
                trainingDate = datenum(str2double(trainingPeriodLastDate(7:10)), str2double(trainingPeriodLastDate(4:5)), ...
                    str2double(trainingPeriodLastDate(1:2)));

                timeVectorNum = datenum(cellfun(@(x) str2double(x(7:10)),timeVector), cellfun(@(x) str2double(x(4:5)),timeVector), ...
                    cellfun(@(x) str2double(x(1:2)),timeVector));

                rawTime = datenum(cellfun(@(x) str2double(x(7:10)),rawTime), cellfun(@(x) str2double(x(4:5)),rawTime), ...
                    cellfun(@(x) str2double(x(1:2)),rawTime));

            elseif strcmp(myFiles.files.history.Attributes.compressionPeriodTag, 'hour')
                trainingDate = datenum(str2double(trainingPeriodLastDate(7:10)), str2double(trainingPeriodLastDate(4:5)), ...
                    str2double(trainingPeriodLastDate(1:2)), str2double(trainingPeriodLastDate(12:13)), 0, 0);

                timeVectorNum = datenum(cellfun(@(x) str2double(x(7:10)),timeVector), cellfun(@(x) str2double(x(4:5)),timeVector), ...
                    cellfun(@(x) str2double(x(1:2)),timeVector), cellfun(@(x) str2double(x(12:13)),timeVector), 0, 0);

                rawTime = datenum(cellfun(@(x) str2double(x(7:10)),rawTime), cellfun(@(x) str2double(x(4:5)),rawTime), ...
                    cellfun(@(x) str2double(x(1:2)),rawTime), cellfun(@(x) str2double(x(12:13)),rawTime), 0, 0);

            elseif strcmp(myFiles.files.history.Attributes.compressionPeriodTag, 'month')
                trainingDate = datenum(str2double(trainingPeriodLastDate(7:10)), str2double(trainingPeriodLastDate(4:5)), 0);

                timeVectorNum = datenum(cellfun(@(x) str2double(x(7:10)),timeVector), cellfun(@(x) str2double(x(4:5)),timeVector), 0);

                rawTime = datenum(cellfun(@(x) str2double(x(7:10)),rawTime), cellfun(@(x) str2double(x(4:5)),rawTime), 0);

            else
                printComputeInfo(iLoger, 'Training period', 'Incorrect input tag of history, it should be day/hour/month in filed compressionPeriodTag');
                error('Incorrect input tag of history, it should be day/hour/month in filed compressionPeriodTag')
            end   

            if isempty(rawTime)
                trainingPeriodEnable = ((timeVectorNum(end) - trainingDate) >= 0);
            else
    %                 posPrevious =  find(rawTime < tariningDate,1);
                posCurrnet = find(rawTime == trainingDate,1);
    %                 posNext = find(rawTime > tariningDate,1);
                trainingPeriodEnable = ((timeVectorNum(end) - trainingDate) >= 0);
                if (~isempty(posCurrnet) && ~trainingPeriodEnable)
                    trainingPeriodEnable = 2;
                end
            end

            % To determine of main and additional metrics of training period
            if trainingPeriodEnable
                if trainingPeriodEnable == 2
                    posTraining = length(dataVector);
                else
                    posTraining = find(timeVectorNum <= trainingDate, 1, 'last');
                end
                if posTraining >= trainingPeriod

                    % To get input data vector
                    trueVectorData = dataVector((posTraining-trainingPeriod)+1:posTraining);

                    % To calculate current metrics for main
                    positionDivided = strfind(myFiles.files.history.Attributes.traningPeriodFormulaMin, '/');
                    [trainingPeriodMain, nameFunctionMain]= ...
                        findFunctionName(positionDivided, myFiles.files.history.Attributes.traningPeriodFormulaMin, ...
                                         trueVectorData, 'Main');

                    % To calculate current metrics for additional
                    [trainingPeriodAdditional, nameFunctionAdditional] = ...
                        findFunctionName(positionDivided, myFiles.files.history.Attributes.traningPeriodFormulaMin, ...
                                         trueVectorData, 'Additional');

                    % To check current input formula for thresholds
                    checkFormula(nameFunctionMain, nameFunctionAdditional, myFiles.files.history.Attributes);
                end
            else
                trainingPeriodMain = [];
                trainingPeriodAdditional = [];
            end
        else
            trainingPeriodMain = [];
            trainingPeriodAdditional = [];
        end

        % To evaluate state metrics
        if ~isempty(trainingPeriodMain) && ~isempty(trainingPeriodAdditional)

            tresholdLow = createThresholds(trainingPeriodMain, trainingPeriodAdditional, ...
                                           myFiles.files.history.Attributes.traningPeriodFormulaMin);
            tresholdAverage = createThresholds(trainingPeriodMain, trainingPeriodAdditional, ...
                                           myFiles.files.history.Attributes.traningPeriodFormulaAverage);
            tresholdHigh = createThresholds(trainingPeriodMain, trainingPeriodAdditional, ...
                                           myFiles.files.history.Attributes.traningPeriodFormulaMax);
    %             tresholdLow = abs(trainingPeriodMain)*1.01 + abs(trainingPeriodAdditional)*1.2;
    %             tresholdAverage = abs(trainingPeriodMain)*1.05 + abs(trainingPeriodAdditional)*1.75;
    %             tresholdHigh = abs(trainingPeriodMain)*1.1 + abs(trainingPeriodAdditional)*2;

            thresholds(1,1) = tresholdLow;
            thresholds(2,1) = tresholdAverage;
            thresholds(3,1) = tresholdHigh;

            if tresholdLow >= dataVector(end)
                strMetricStatus = 'GREEN';
    %                 strMetricStatus = 0.25;
            elseif tresholdLow < dataVector(end) && tresholdAverage >= dataVector(end) 
                strMetricStatus = 'YELLOW';
    %                 strMetricStatus = 0.5;
            elseif tresholdAverage < dataVector(end) && tresholdHigh >= dataVector(end) 
                strMetricStatus = 'ORANGE';
    %                 strMetricStatus = 0.75;                
            else
                strMetricStatus = 'RED';
    %                 strMetricStatus = 1;
            end
        end
    else
        trainingPeriodMain = [];
        trainingPeriodAdditional = [];
    end
end

% FINDFUNCTIONNAME function find name of function for calculate additional
% or main metrics
function [result, mainFunctionName]= findFunctionName(positionDivided, formula, rawData, mode)

    positionMain = strfind(formula, mode);
    if ~isempty(positionMain)
        positionVector = positionMain > positionDivided;
        posStartMain = positionDivided(positionVector);
        posStartMain = posStartMain(end);

        mainFunctionName = formula(posStartMain+1:positionMain-1);
        result = feval(mainFunctionName, rawData);
    else
        result = nan(1);
    end
end

% CREATETHRESHOLDS function create value of threshold
function result = createThresholds(mainData, additionalData, formula)

    % To find main position
    positionMain = findPostionTag(formula, 'Main');
    % To replace main function on x
    formulaXY = [formula(1:positionMain(1)-1) 'x' formula(positionMain(2)+1:end)];
    
    % To find additional position
    positionAdditional = findPostionTag(formulaXY, 'Additional');
    % To replace additional function on y
    formulaXY = ['@(x,y)' formulaXY(1:positionAdditional(1)-1) 'y' formulaXY(positionAdditional(2)+1:end)];
    
    % (formulaXY,'x','y')
    myFunctionFormula = str2func(formulaXY);
    result = myFunctionFormula(mainData, additionalData);
end

% FINDPOSITIONTAG function to find position for main or additional function
function positionTag = findPostionTag(formula, tag)

    % To get position for all separators
    positionDivided = strfind(formula, '/');
    
    % To find positoin current tag (Main, Additional)
    positionMain = strfind(formula, tag);
    
    % To find position
    positionVector = positionMain > positionDivided;
    posStartMain = positionDivided(positionVector);
    posStartMain = posStartMain(end);
    posEndMain = positionDivided(~positionVector);
    posEndMain = posEndMain(1);
    
    positionTag = [posStartMain posEndMain];
end

% CHECKFORMULA function is check of formula on input correctness 
function checkFormula(nameFunctionMain, nameFunctionAdditional, parameters)
    
    myLoger = loger.getInstance();

    nameFunctionMain = [nameFunctionMain 'Main'];
    nameFunctionAdditional = [nameFunctionAdditional 'Additional'];
    
    vectroStateMain = false(3,1);
    vectroStateAdditional = false(3,1);
    
    % To find function in formula for main data
    vectroStateMain(1) = ~isempty(strfind(parameters.traningPeriodFormulaAverage, nameFunctionMain));
    vectroStateMain(2) = ~isempty(strfind(parameters.traningPeriodFormulaMax, nameFunctionMain));
    vectroStateMain(3) = ~isempty(strfind(parameters.traningPeriodFormulaMin, nameFunctionMain));
    
    % To find function in formula for additional data
    vectroStateAdditional(1) = ~isempty(strfind(parameters.traningPeriodFormulaAverage, nameFunctionAdditional));
    vectroStateAdditional(2) = ~isempty(strfind(parameters.traningPeriodFormulaMax, nameFunctionAdditional));
    vectroStateAdditional(3) = ~isempty(strfind(parameters.traningPeriodFormulaMin, nameFunctionAdditional));
    
    if nnz(vectroStateMain) ~= 3 && nnz(vectroStateAdditional) ~= 3
        printWarning(myLoger, 'Not correct input of formulas for thresholds in history, all function for main and additional should be same')
    end
end