% Developer:              Kosmach N.
% Development date:       11.05.2017
% Modified by:            Kosmach N.
% Modification date:      21-09-2017 

% EVALUATIONMODULATIONHISTORY function evaluate modulation of history,
% result is structure with filed: 
%           resultStruct.status - evaluation of modulation near the main peak
%           resultStruct.main - name of the main peka
%           resultStruct.sideBand - name of the sideband peak
%           resultStruct.weightMainPeak - weight main peak
% 
function [ resultStruct ] = evaluationModulationHistory( domain, myFiles )

    % Get vector of weights
    weight = str2num(domain.defectiveWeights{1, 1});
    initialPeaks = domain.trainingPeriodInitialTagNames;
    currentlyPeaks = domain.nameTable(:,1);
    currentlyTags = domain.tagTable(:,1);
    magnitudesTable = domain.dataCompression(:,1);
    
    if ~isempty(initialPeaks)
        initialPeaks = strsplit(initialPeaks);
    end

    % Delete empty space
    currentlyPeaks = strtrim(currentlyPeaks);
    
    [posSideNumCurrents, mainUniqCurrents, sideVectorCurrents, sideUniqCurrents, splitMainCurrents, ...
        tagMainUniq, tagSideUniq, magnitudesMain] = findModulationAndMain(currentlyPeaks, currentlyTags, magnitudesTable);
    [posSideNumInit, ~, sideVectorInit, ~, splitMainInit] = ...
        findModulationAndMain(initialPeaks);
    if ~isempty(mainUniqCurrents)
        % Initialisation for modulation
        sizeOfStatusModulation = length(mainUniqCurrents) * length(sideUniqCurrents);
        resultStruct.status = zeros(sizeOfStatusModulation,1);
        resultStruct.main = cell(sizeOfStatusModulation,1);
        resultStruct.sideBand = resultStruct.main;
        resultStruct.weightMainPeak = resultStruct.status;
        resultStruct.mainTag = resultStruct.status;
        resultStruct.sideBandTag = resultStruct.status;
        resultStruct.position = resultStruct.status;
        resultStruct.magnitudes = resultStruct.status;
        numberStatusSide = 1;
        
        % Main loop
        for i = 1:1:length(mainUniqCurrents)
            % To find main peak
            positionMainTempCurrents = ismember(splitMainCurrents, mainUniqCurrents(i));
            if ~isempty(splitMainInit)
                positionMainTempInitials = ismember(splitMainInit, mainUniqCurrents(i))';
            else
                nameInit = [];
            end
            posMainPeak = ismember(currentlyPeaks,mainUniqCurrents(i));
            mainStruct.trendPeaks = domain.trendResult(posMainPeak);
            mainStruct.thresholdVector = domain.statusCurrentThreshold(posMainPeak);
            mainStruct.magnitudes = domain.dataCompression(posMainPeak,:);
            mainStruct.intensity = domain.intensivityResultVector(posMainPeak,:);
            % Loop for different sideband
            for j = 1:1:length(sideUniqCurrents)
                % To find current sideband for one main peak
                positionSideTempCurrents = ismember(sideVectorCurrents, sideUniqCurrents(j));
                positionSideAllCurrents = posSideNumCurrents(positionSideTempCurrents);
                positionVectorSideCurrents = zeros(length(currentlyPeaks),1);
                positionVectorSideCurrents(positionSideAllCurrents) = 1;
                posAllModCurrents = bsxfun(@and,positionVectorSideCurrents,positionMainTempCurrents);
                % To find initial peak for current sideband
                if ~isempty(splitMainInit)
                    if nnz(contains(initialPeaks, 'NaN'))
                        nameInit = initialPeaks;
                    else
                        positionSideTempInit = ismember(sideVectorInit, sideUniqCurrents(j));
                        positionSideAllInit = posSideNumInit(positionSideTempInit);
                        positionVectorSideInit = zeros(length(initialPeaks),1);
                        positionVectorSideInit(positionSideAllInit) = 1;
                        posAllModInitial = bsxfun(@and,positionVectorSideInit,positionMainTempInitials);
                        if nnz(posAllModInitial)
                            nameInit = initialPeaks(posAllModInitial);
                        else
                            nameInit = [];
                        end
                    end
                end
                    
                % To filing structure for evaluating modulations
                sideStructCurrents.trendPeaks = domain.trendResult(posAllModCurrents);
                sideStructCurrents.thresholdVector = domain.statusCurrentThreshold(posAllModCurrents);
                sideStructCurrents.magnitudes = domain.dataCompression(posAllModCurrents,:);
                sideStructCurrents.name = currentlyPeaks(posAllModCurrents);
                sideStructCurrents.intensity = domain.intensivityResultVector(posAllModCurrents);
                if ~isempty(sideStructCurrents.name)
                    % To evaluate modulations and push to report structure
                    resultStruct.status(numberStatusSide) = ...
                    evaluateOneModulationOfHistory(mainStruct, sideStructCurrents, nameInit, myFiles);
                    resultStruct.main(numberStatusSide) = mainUniqCurrents(i);
                    resultStruct.sideBand(numberStatusSide) = sideUniqCurrents(j);
                    resultStruct.weightMainPeak(numberStatusSide) = weight(posMainPeak);
                    
                    tempPosTag = strsplit(tagMainUniq{i}, '*');
                    resultStruct.mainTag(numberStatusSide) = str2double(tempPosTag{2});
                    resultStruct.sideBandTag(numberStatusSide) = tagSideUniq(j);
                    resultStruct.position(numberStatusSide) = str2double(tempPosTag{1});
                    resultStruct.magnitudes(numberStatusSide) = magnitudesMain(i);
                end
                
                numberStatusSide = numberStatusSide + 1;
            end
        end
    else
        resultStruct.status = 0;
        resultStruct.main = [];
        resultStruct.sideBand = [];
        resultStruct.weightMainPeak = [];
        resultStruct.mainTag = [];
        resultStruct.sideBandTag = [];
        resultStruct.position = [];
        resultStruct.magnitudes = [];
    end
    
end
    
% EVALUATEONEMODULATIONOFHISTORY function evaluate modulations near the main 
% peak
function status = evaluateOneModulationOfHistory(mainStruct, sideStructCurrents, nameInit, myFiles)
    if ~(mainStruct.intensity)
        status = 0;
        return
    end

    % Evaluating threshold and trend
    statusThresholdAndTrend = evaluateThresholdAndTrend(mainStruct, sideStructCurrents);
    
    % Evaluating number appearing modulation peaks
    [currentWeightSide, ~] = evaluateNumberSideband(sideStructCurrents.name, ...
        nameInit, sideStructCurrents.intensity);
    if currentWeightSide < 0.3
        currentWeightStatus = 0;
    elseif currentWeightSide >= 0.3 && currentWeightSide < 0.55 
        currentWeightStatus = 0.375;
    elseif currentWeightSide >= 0.55 && currentWeightSide <  0.68
        currentWeightStatus = 0.625;
    else
        currentWeightStatus = 1;
    end
    
    % Evaluating magnitude near main peak
    statusOfMagnitudes = evaluateMagnitudeOfModulations(mainStruct.magnitudes, ...
        sideStructCurrents.magnitudes, myFiles, sideStructCurrents.intensity);
    
    % Evaluate threshold, trend, number appea modulations
    container = newfis('optipaper');

    % INPUT:
    % Init 4-state @statusThresholdAndTrend variable
    container = addvar(container,'input','statusThresholdAndTrend',[0 1]);
    container = addmf(container,'input',1,'possiblyDangerous','gaussmf',[0.0625  0.375]);
    container = addmf(container,'input',1,'dangerous','gaussmf',[0.0625 0.625]);
    container = addmf(container,'input',1,'critical','gauss2mf',[0.0625 0.875 0.01 1]);
    container = addmf(container,'input',1,'noDangerous','gauss2mf',[0.1 0 0.0625 0.125]);
    
    % INPUT:
    % Init 4-state @currentWeightStatus variable
    container = addvar(container,'input','currentWeightStatus',[0 1]);
    container = addmf(container,'input',2,'possiblyDangerous','gaussmf',[0.0625  0.375]);
    container = addmf(container,'input',2,'dangerous','gaussmf',[0.0625 0.625]);
    container = addmf(container,'input',2,'critical','gauss2mf',[0.0625 0.875 0.01 1]);
    container = addmf(container,'input',2,'noDangerous','gauss2mf',[0.1 0 0.0625 0.125]);
    
    % OUTPUT:
    % Init 4-state @status variable
    container = addvar(container,'output','statusThresholdTrendWeight',[0 1]);
    container = addmf(container,'output',1,'possiblyDangerous','gaussmf',[0.0625  0.375]);
    container = addmf(container,'output',1,'dangerous','gaussmf',[0.0625 0.625]);
    container = addmf(container,'output',1,'critical','gauss2mf',[0.0625 0.875 0.01 1]);
    container = addmf(container,'output',1,'noDangerous','gauss2mf',[0.1 0 0.0625 0.125]);

    % RULEs:
    ruleList = [ 
                     3  0  3  1  1;
                     0  3  3  1  1;
                     
                     1  1  1  1  1;
                     1  2  2  1  1;
                     1  4  1  1  1;
                     
                     2  1  2  1  1;
                     2  2  3  1  1;
                     2  4  1  1  1;
                     
                     4  0  4  1  1;
%                      4  2  2  1  1;
%                      4  4  4  1  1;
                    ];

    container = addrule(container,ruleList);
    
    inputArguments = [statusThresholdAndTrend, currentWeightStatus];
    statusThresholdTrendWeight = evalfis(inputArguments, container);
    
    % Evaluate threshold, trend, number appea modulations, amplitude ratio
    container = newfis('optipaper');

    % INPUT:
    % Init 4-state @statusThresholdTrendWeight variable
    container = addvar(container,'input','statusThresholdTrendWeight',[0 1]);
    container = addmf(container,'input',1,'possiblyDangerous','gaussmf',[0.0625  0.375]);
    container = addmf(container,'input',1,'dangerous','gaussmf',[0.0625 0.625]);
    container = addmf(container,'input',1,'critical','gauss2mf',[0.0625 0.875 0.01 1]);
    container = addmf(container,'input',1,'noDangerous','gauss2mf',[0.1 0 0.0625 0.125]);
    
    % INPUT:
    % Init 4-state @statusOfMagnitudes variable
    container = addvar(container,'input','statusOfMagnitudes',[0 1]);
    container = addmf(container,'input',2,'possiblyDangerous','gaussmf',[0.0625  0.375]);
    container = addmf(container,'input',2,'dangerous','gaussmf',[0.0625 0.625]);
    container = addmf(container,'input',2,'critical','gauss2mf',[0.0625 0.875 0.01 1]);
    container = addmf(container,'input',2,'noDangerous','gauss2mf',[0.1 0 0.0625 0.125]);
    
    % OUTPUT:
    % Init 4-state @status variable
    container = addvar(container,'output','status',[-0.375 1.125]);
    container = addmf(container,'output',1,'possiblyDangerous','trimf',[0.375 0.5 0.625]);
    container = addmf(container,'output',1,'dangerous','trimf',[0.625 0.75 0.875]);
    container = addmf(container,'output',1,'critical','trimf',[0.875 1 1.125]);
    container = addmf(container,'output',1,'noDangerous','trimf',[-0.375 0 0.375]);

    % RULEs:
    ruleList = [ 
                     1 -3  1  1  1;
                     1  3  2  1  1;
                     
                     2 -3  2  1  1;
                     2  3  3  1  1;
                     
                     3  0  3  1  1;
                     
                     4  0  4  1  1;
                    ];

    container = addrule(container,ruleList);
    
    inputArguments = [statusThresholdTrendWeight, statusOfMagnitudes];
    status = round(evalfis(inputArguments, container), 2);
end

% FINDMODULATIONANDMAIN function find modulations
function [positionModulationNumeric, mainVectorUniq, sideVectorCurrents, sideVectorUniq, splitMain,  ...
    tagMainUniq, tagSideUniq, magnitudesMain] = findModulationAndMain(namePeaks, tags, magnitudes)
    
    if ~isempty(namePeaks)
        if nnz(~cellfun(@isempty ,namePeaks))
            splitPeaks = cellfun(@(x) strsplit(x, {'+','-'}), namePeaks, 'UniformOutput', false);
            numberSidePos = cellfun(@(x) length(x), splitPeaks, 'UniformOutput', true) == 2;
            positionModulationNumeric = find(numberSidePos);
            mainVectorUniq = unique(cellfun(@(x) x{1,1}, splitPeaks(numberSidePos), 'UniformOutput', false));
            sideVectorCurrents = cellfun(@(x) x{1,2}, cellfun(@(x) ...
                strsplit(x{1,2}, '*'), splitPeaks(numberSidePos), 'UniformOutput', false), 'UniformOutput', false);
            sideVectorUniq = unique(sideVectorCurrents);

            splitMain = cellfun(@(x) x{1,1}, splitPeaks, 'UniformOutput', false);
            
            if nargin == 1
                tagMainUniq = [];
                tagSideUniq = [];
                magnitudesMain = [];
            else
                splitTags = cellfun(@(x) strsplit(x, '_'), tags, 'UniformOutput', false);
                numberSidePosTags = cellfun(@(x) length(x), splitTags, 'UniformOutput', true) == 2;
                tagMainUniq = unique(cellfun(@(x) x{1,1}, splitTags(numberSidePosTags), 'UniformOutput', false));
                sideVectorTags = cellfun(@(x) str2double(x{1,2}), cellfun(@(x) ...
                    strsplit(x{1,2}, '*'), splitTags(numberSidePosTags), 'UniformOutput', false));
                tagSideUniq = unique(sideVectorTags);
                
                % To get vector of magnitudes of main peaks
                magnitudesAllMod = magnitudes(~numberSidePos);
                magnitudesMain = magnitudesAllMod(ismember(namePeaks(~numberSidePos), mainVectorUniq)); 
            end
        else
            positionModulationNumeric = [];
            mainVectorUniq = [];
            sideVectorCurrents = [];
            sideVectorUniq = [];
            splitMain = [];
            tagMainUniq = [];
            tagSideUniq = [];
            magnitudesMain = [];
        end
    else
        positionModulationNumeric = [];
        mainVectorUniq = [];
        sideVectorCurrents = [];
        sideVectorUniq = [];
        splitMain = [];
        tagMainUniq = [];
        tagSideUniq = [];
        magnitudesMain = [];
    end
end

% EVALUATETRESHOLDANDTREND function evaluates the threshold and the trend of
% modulation nearly one peak
function status = evaluateThresholdAndTrend(mainStruct, sideStructCurrents)
    % evaluate right sidebands
    posRightSidebands = cellfun(@(s) ~isempty(strfind(s, '+')), sideStructCurrents.name);
    rightStruct.name = sideStructCurrents.name(posRightSidebands);
    rightStruct.trendPeaks = sideStructCurrents.trendPeaks(posRightSidebands);
    rightStruct.thresholdVector = sideStructCurrents.thresholdVector(posRightSidebands);
    statusRight = evaluateThresholdAndTrendSide(rightStruct);
    
    % evaluate left sidebands
    posLeftSidebands = cellfun(@(s) ~isempty(strfind(s, '+')), sideStructCurrents.name);
    leftStruct.name = sideStructCurrents.name(posLeftSidebands);
    leftStruct.trendPeaks = sideStructCurrents.trendPeaks(posLeftSidebands);
    leftStruct.thresholdVector = sideStructCurrents.thresholdVector(posLeftSidebands);
    statusLeft = evaluateThresholdAndTrendSide(leftStruct);
    
    % evaluate main peaks
    mainPeaksStatus = evaluatorThresholdTrend(mainStruct.trendPeaks, mainStruct.thresholdVector);
    
    container = newfis('optipaper');

    % INPUT:
    % Init 4-state @statusRight variable
    container = addvar(container,'input','statusRight',[0 1]);
    container = addmf(container,'input',1,'possiblyDangerous','gaussmf',[0.0625  0.375]);
    container = addmf(container,'input',1,'dangerous','gaussmf',[0.0625 0.625]);
    container = addmf(container,'input',1,'critical','gauss2mf',[0.0625 0.875 0.01 1]);
    container = addmf(container,'input',1,'noDangerous','gauss2mf',[0.1 0 0.0625 0.125]);
    
    % INPUT:
    % Init 4-state @statusLeft variable
    container = addvar(container,'input','statusLeft',[0 1]);
    container = addmf(container,'input',2,'possiblyDangerous','gaussmf',[0.0625  0.375]);
    container = addmf(container,'input',2,'dangerous','gaussmf',[0.0625 0.625]);
    container = addmf(container,'input',2,'critical','gauss2mf',[0.0625 0.875 0.01 1]);
    container = addmf(container,'input',2,'noDangerous','gauss2mf',[0.1 0 0.0625 0.125]);

    % INPUT:
    % Init 4-state @mainPeaksStatus variable
    container = addvar(container,'input','mainPeaksStatus',[-0.375 1.125]);
    container = addmf(container,'input',3,'possiblyDangerous','trimf',[0.375 0.5 0.625]);
    container = addmf(container,'input',3,'dangerous','trimf',[0.625 0.75 0.875]);
    container = addmf(container,'input',3,'critical','trimf',[0.875 1 1.125]);
    container = addmf(container,'input',3,'noDangerous','trimf',[-0.375 0 0.375]);
    
    % OUTPUT:
    % Init 4-state @status variable
    container = addvar(container,'output','status',[0 1]);
    container = addmf(container,'output',1,'possiblyDangerous','gaussmf',[0.0625  0.375]);
    container = addmf(container,'output',1,'dangerous','gaussmf',[0.0625 0.625]);
    container = addmf(container,'output',1,'critical','gauss2mf',[0.0625 0.875 0.01 1]);
    container = addmf(container,'output',1,'noDangerous','gauss2mf',[0.1 0 0.0625 0.125]);

    % RULEs:
    ruleList = [ 
                    % left & right are possiblyDangerous
                     1  1  1  1  1  1;
                     1  1  2  1  1  1;
                     1  1  3  2  1  1;
                     1  1  4  4  1  1;
                     
                     %  left | right are possiblyDangerous | dangerous
                     1  2  1  1  1  1;
                     2  1  1  1  1  1;
                     1  2  2  2  1  1;
                     2  1  2  2  1  1;
                     1  2  3  3  1  1;
                     2  1  3  3  1  1;
                     1  2  4  1  1  1;
                     2  1  4  1  1  1; 
                     
                     % left | right are possiblyDangerous | critical
                     1  3  1  2  1  1;
                     3  1  1  2  1  1;
                     1  3  2  3  1  1;
                     3  1  2  3  1  1;
                     1  3  3  3  1  1;
                     3  1  3  3  1  1; 
                     1  3  4  1  1  1;
                     3  1  4  1  1  1;
                     
                     % left | right are possiblyDangerous | noDangerous
                     1  4  1  1  1  1;
                     4  1  1  1  1  1;
                     1  4  2  1  1  1;
                     4  1  2  1  1  1;
                     1  4  3  2  1  1;
                     4  1  3  2  1  1;
                     1  4  4  4  1  1;
                     4  1  4  4  1  1;
                     
                     % left & right are dangerous
                     2  2  1  2  1  1;
                     2  2  2  2  1  1;
                     2  2  3  3  1  1;
                     2  2  4  1  1  1;
                     
                     % left | right are dangerous | critical
                     2  3  1  2  1  1;
                     3  2  1  2  1  1;
                     2  3  2  3  1  1;
                     3  2  2  3  1  1;
                     2  3  3  3  1  1;
                     3  2  3  3  1  1;
                     2  3  4  1  1  1;
                     3  2  4  1  1  1;
                     
                     % left | right are dangerous | critical
                     2  4  1  1  1  1;
                     4  2  1  1  1  1;
                     2  4  2  2  1  1;
                     4  2  2  2  1  1;
                     2  4  3  3  1  1;
                     4  2  3  3  1  1;
                     2  4  4  4  1  1;
                     4  2  4  4  1  1;
                     
                     % left & right are critical
                     3  3 -4  3  1  1;
                     3  3  4  2  1  1;
                     
                     % left | right are critical | noDangerous
                     3  4  1  2  1  1;
                     4  3  1  2  1  1;
                     3  4  2  3  1  1;
                     4  3  2  3  1  1;
                     3  4  3  3  1  1;
                     4  3  3  3  1  1;
                     3  4  4  2  1  1;
                     4  3  4  2  1  1;
                     
                     % left & right are noDangerous
                     4  4  0  4  1  1;
                    ];

    container = addrule(container,ruleList);
    
    inputArguments = [statusRight, statusLeft, mainPeaksStatus];
    status = evalfis(inputArguments, container);
end

% EVALUATETRESHOLDANDTRENDSIDE function evaluate right/left harmonics
% sideband with histoty informayion(trends, thresholds)
function status = evaluateThresholdAndTrendSide(sideStructCurrents)
    numberSide = cellfun(@(x) str2double(x(1)),cellfun(@(x) split(x{1,2},'*'),...
        cellfun(@(x) strsplit(x, {'+','-'}), sideStructCurrents.name, 'UniformOutput', false), ...
        'UniformOutput', false));
    
    statusThresholdTrend = evaluatorThresholdTrend(...
        sideStructCurrents.trendPeaks, sideStructCurrents.thresholdVector)';
    
    % Status with first, second harmonics sideband
    if nnz(numberSide <= 2)
        oneTwoStatus = max(statusThresholdTrend(numberSide <= 2));
    else
        oneTwoStatus = 0;
    end
    
    % Status with third and more sideband
    if nnz(numberSide > 2)
        moreTwo = max(statusThresholdTrend(numberSide > 2));

    else
        moreTwo = 0;
    end
    
    container = newfis('optipaper');

    % INPUT:
    % Init 4-state @oneTwoStatus variable
    container = addvar(container,'input','oneTwoStatus',[-0.375 1.125]);
    container = addmf(container,'input',1,'possiblyDangerous','trimf',[0.375 0.5 0.625]);
    container = addmf(container,'input',1,'dangerous','trimf',[0.625 0.75 0.875]);
    container = addmf(container,'input',1,'critical','trimf',[0.875 1 1.125]);
    container = addmf(container,'input',1,'noDangerous','trimf',[-0.375 0 0.375]);
    
     % INPUT:
    % Init 4-state @moreTwo variable
    container = addvar(container,'input','moreTwo',[-0.375 1.125]);
    container = addmf(container,'input',2,'possiblyDangerous','trimf',[0.375 0.5 0.625]);
    container = addmf(container,'input',2,'dangerous','trimf',[0.625 0.75 0.875]);
    container = addmf(container,'input',2,'critical','trimf',[0.875 1 1.125]);
    container = addmf(container,'input',2,'noDangerous','trimf',[-0.375 0 0.375]);

    % OUTPUT:
    % Init 4-state @status variable
    container = addvar(container,'output','status',[0 1]);
    container = addmf(container,'output',1,'possiblyDangerous','gaussmf',[0.0625  0.375]);
    container = addmf(container,'output',1,'dangerous','gaussmf',[0.0625 0.625]);
    container = addmf(container,'output',1,'critical','gauss2mf',[0.0625 0.875 0.01 1]);
    container = addmf(container,'output',1,'noDangerous','gauss2mf',[0.1 0 0.0625 0.125]);

    % RULEs:
    ruleList = [ % oneTwo sideband is possiblyDangerous
                     1  1  1  1  1;
                     1  2  2  1  1;
                     1  3  2  1  1;
                     1  4  1  1  1;
                     
                     % oneTwo sideband is dangerous
                     2  1  2  1  1;
                     2  2  2  1  1;
                     2  3  3  1  1;
                     2  4  2  1  1;
                     
                     % oneTwo sideband is critical
                     3  0  3  1  1;
                     
                     % oneTwo sideband is noDangerous
                     4  1  4  1  1;
                     4  2  1  1  1;
                     4  3  2  1  1;
                     4  4  4  1  1;
                    ];

    container = addrule(container,ruleList);
    
    inputArguments = [oneTwoStatus, moreTwo];
    status = evalfis(inputArguments, container);
end

% EVALUATENUMBERSIDEBAND function determine significance of modulation of history
function [currentWeight, appearedWeight] = evaluateNumberSideband(currentName, initialPeaks, intensity)

    if isempty(currentName)
        processing = 0;
    elseif isempty(initialPeaks)
        processing = 1;
    elseif nnz(contains(initialPeaks, 'NaN')) % NaN - training period will be
        processing = 0;
    else
        processing = 1;
    end
    
    if processing
        currentWeight = evaluateWeightSideband(currentName, intensity);
        if isempty(initialPeaks)
            appearedWeight = currentWeight;
        else
            [positionInit, positionCurrent] = ismember(initialPeaks,currentName);
            intensityInit = zeros(1,length(initialPeaks));
            intensityInit(1,positionInit) = intensity(nonzeros(positionCurrent),1);
            
            initialWeight = evaluateWeightSideband(initialPeaks, intensityInit);
            appearedWeight = currentWeight - initialWeight;
        end
    else
        appearedWeight = 0;
        currentWeight = 0;
    end
end

% EVALUATEWEIGHTSIDEBAND function determining the weight of history modulations
function weight = evaluateWeightSideband(namePeaks, intensity)
    if nnz(intensity)   
        % Get numbers of sideband relativity of main peak
        numberSide = cellfun(@(x) str2double(x(1)),cellfun(@(x) split(x{1,2},'*'),...
                cellfun(@(x) strsplit(x, {'+','-'}), namePeaks, 'UniformOutput', false), ...
                'UniformOutput', false));
        numberSide = numberSide(logical(intensity));
        statusWeight = zeros(length(numberSide),1);
        % The vector of the weights of history
        vectorWeight = [0.17; 0.11; 0.07; 0.05; 0.05; 0.05];
        vectorPosition = (1:6)';
        for i=1:1:length(vectorPosition)
            tempPosTrue = numberSide == vectorPosition(i);
            if nnz(tempPosTrue)
                statusWeight(tempPosTrue) = vectorWeight(i);
            end
        end
        weight = sum(statusWeight);
    else
        weight = 0;
    end
end

% EVALUATEMAGNITUDEOFMODULATIONS function evaluate modulation with
% magnitides
function status = evaluateMagnitudeOfModulations(mainMagnitude, sideMagnitudes, myFiles, intensity)
    if nnz(intensity)
        percentMatrix =  bsxfun(@rdivide,sideMagnitudes,mainMagnitude);
        percentMatrix(isnan(percentMatrix)) = 0;
        percentMatrix(percentMatrix == Inf) = 0;
        percentMatrix(percentMatrix > 1) = 0;
        percentMatrix = percentMatrix(intensity,:);
        numberHistoryFiles = length(percentMatrix(1,:));
        vectorStatus = cell(1,numberHistoryFiles);
        for i = 1:1:numberHistoryFiles
            vectorStatus{i} = evaluateMagnitudeForOneSample(percentMatrix(:,i));
        end
        vectorStatus = flip(vectorStatus);
        status = evaluateStatusWithDuration(vectorStatus, myFiles);
        switch(status{1,1})
            case 'critical'
                status = 1;   
            case 'dangerous'   
                status = 0.625;
            case 'mBDangerous'
                status = 0.375;
            case 'no'
                status = 0;
            otherwise 
                status = 0;
        end
    else
        status = 0;
    end
end

% EVALUATEMAGNITUDEFORONESAMPLE function convert numeric status into 
% symbols with the thresholds
function status = evaluateMagnitudeForOneSample(relationshipVector)
    if nnz(relationshipVector < 0.75) && nnz(relationshipVector > 0.4)
        status = 'critical'; % 1 
    elseif nnz(relationshipVector > 0.4) && nnz(relationshipVector < 0.05)
        status = 'dangerous'; % 0.625
    elseif nnz(relationshipVector > 0.05)  && nnz(relationshipVector < 0)
        status = 'mBDangerous'; % 0.375
    else
        status = 'no'; % 0
    end
end