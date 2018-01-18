%   Developer:      Kosmach
%   Date:              05.04.2017

% MODULATIONSSEARCH function create the grid of frequencies
% and find required frequency into initialPeakTable.
function [mainPeak,  sidebandName, structSideband] = ...
    modulationsSearch(initialPeakTable, structureForPeak, frequencyModulating)
    % Check frequency repeating
    allFreq = [structureForPeak.sidebandFreq' structureForPeak.mainFreq];
    
    if ~(length(unique(allFreq)) == length(allFreq)) && ~isempty(structureForPeak.mainFreq)
        findingSidebandNameLeft = [];
        findingSidebandNameRight = [];

        % Get position of right and left sidebands
        peaksNumberModRight = ...
        cellfun(@(s) strfind(s, '+'), structureForPeak.sidebandName, 'UniformOutput', false);
        peaksNumberModLeft = ...
            cellfun(@(s) strfind(s, '-'), structureForPeak.sidebandName, 'UniformOutput', false);
        [posRight, nameRight] = getPosModulation(peaksNumberModRight, structureForPeak.sidebandName);
        [posLeft, nameLeft] = getPosModulation(peaksNumberModLeft, structureForPeak.sidebandName);
        
        % Default parameters for finding similar elements
        config.freqRange = num2str(frequencyModulating*0.02);

        % Finding left sideband
        if posLeft ~= 0
            gridFreqLeft = structureForPeak.mainFreq - posLeft*frequencyModulating;
            findingSidebandNameLeft = cell(length(gridFreqLeft),1);
            validPromLeft = zeros(length(gridFreqLeft),1);
            posChangedFreqLeft = validPromLeft;
            validMagLeft = validPromLeft;
            validFreqLeft = validPromLeft;
            validLogPromLeft = validPromLeft;
            for i = 1:1:length(posLeft)
                 validFreqVector = getSimilarElements(gridFreqLeft(i), initialPeakTable(:,1), config);
                 if nnz(validFreqVector)
                     [validPromLeft(i), posMax] = max(initialPeakTable(ismember(initialPeakTable(:,1), validFreqVector),3));
                     validMagLeft(i,1) = initialPeakTable(initialPeakTable(:,1) == validFreqVector(posMax),2);
                     validFreqLeft(i,1) = validFreqVector(posMax);
                     validLogPromLeft(i,1) = initialPeakTable(initialPeakTable(:,1) == validFreqVector(posMax),4);
                     findingSidebandNameLeft(i) = nameLeft(i);
                     posChangedFreqLeft(i,1) = 1;
                 end
            end
            validPos = ~cellfun(@isempty, findingSidebandNameLeft);
            findingSidebandNameLeft = findingSidebandNameLeft(validPos,1);
            posChangedFreqLeft = posChangedFreqLeft(validPos,1);
            validMagLeft = validMagLeft(validPos,1);
            validFreqLeft = validFreqLeft(validPos,1);
            validLogPromLeft = validLogPromLeft(validPos,1);
            validPromLeft = validPromLeft(validPos,1);
        end

        % Finding right sideband
        if posRight ~= 0
            gridFreqRight = structureForPeak.mainFreq + posRight*frequencyModulating;
            findingSidebandNameRight = cell(length(gridFreqRight),1);
            validPromRight = zeros(length(gridFreqRight),1);
            posChangedFreqRight = validPromRight;
            validMagRight = validPromRight;
            validFreqRight = validPromRight;
            validLogPromRight = validPromRight;
            for i = 1:1:length(posRight)
                 validFreqVector = getSimilarElements(gridFreqRight(i), initialPeakTable(:,1), config);
                 if nnz(validFreqVector)
                     [validPromRight(i), posMax] = max(initialPeakTable(ismember(initialPeakTable(:,1), validFreqVector),3));
                     validMagRight(i,1) = initialPeakTable(initialPeakTable(:,1) == validFreqVector(posMax),2);
                     validFreqRight(i,1) = validFreqVector(posMax);
                     validLogPromRight(i,1) = initialPeakTable(initialPeakTable(:,1) == validFreqVector(posMax),4);
                     findingSidebandNameRight(i) = nameRight(i);
                     posChangedFreqRight(i,1) = 1;
                 end
            end
            validPos = ~cellfun(@isempty, findingSidebandNameRight);
            findingSidebandNameRight = findingSidebandNameRight(validPos,1 );
            posChangedFreqRight = posChangedFreqRight(validPos,1);
            validMagRight = validMagRight(validPos,1);
            validFreqRight = validFreqRight(validPos,1);
            validLogPromRight = validLogPromRight(validPos,1);
            validPromRight = validPromRight(validPos,1);
        end

        % Push to result
        if ~isempty(findingSidebandNameRight) && ...
                ~isempty(findingSidebandNameLeft)
            sidebandName = cell(length(findingSidebandNameLeft) + ...
                length(findingSidebandNameRight),1);
            structSideband = createEmptyStruct(length(findingSidebandNameLeft) + ...
                length(findingSidebandNameRight));
            
            % Filling left sideband
            positionLeft = 1:length(findingSidebandNameLeft);
            sidebandName(positionLeft) = findingSidebandNameLeft;
            structSideband.posChangedFreq(positionLeft) = posChangedFreqLeft;
            structSideband.validMag(positionLeft) = validMagLeft;
            structSideband.validFreq(positionLeft) = validFreqLeft;
            structSideband.validLogProm(positionLeft) = validLogPromLeft;
            structSideband.validProm(positionLeft) = validPromLeft;
            
            % Filling right sideband
            positionRight = length(findingSidebandNameLeft)+1:1:length(findingSidebandNameLeft) + length(findingSidebandNameRight);
            sidebandName(positionRight) = findingSidebandNameRight;
            structSideband.posChangedFreq(positionRight) = posChangedFreqRight;
            structSideband.validMag(positionRight) = validMagRight;
            structSideband.validFreq(positionRight) = validFreqRight;
            structSideband.validLogProm(positionRight) = validLogPromRight;
            structSideband.validProm(positionRight) = validPromRight;
            
        elseif ~isempty(findingSidebandNameLeft)
            sidebandName = findingSidebandNameLeft;
            structSideband.posChangedFreq = posChangedFreqLeft;
            structSideband.validMag = validMagLeft;
            structSideband.validFreq = validFreqLeft;
            structSideband.validLogProm = validLogPromLeft;
            structSideband.validProm = validPromLeft;
            
        elseif ~isempty(findingSidebandNameRight)
            sidebandName = findingSidebandNameRight;
            structSideband.posChangedFreq = posChangedFreqRight;
            structSideband.validMag = validMagRight;
            structSideband.validFreq = validFreqRight;
            structSideband.validLogProm = validLogPromRight;
            structSideband.validProm = validPromRight;
            
        else
            sidebandName = cell(0,1);
            structSideband = createEmptyStruct(length(structureForPeak.sidebandName));
        end
    else
        sidebandName = structureForPeak.sidebandName;
        structSideband = createEmptyStruct(length(structureForPeak.sidebandName));
    end
    mainPeak = structureForPeak.mainPeak;
end
 
% GETPOSMODULATION function is finding position of one sideband and return it name
function [positionMod, structName] = getPosModulation(peaksNumberModCell, sidebandName)
    if ~isempty(cell2mat(peaksNumberModCell))
        % +/- position
        peaksNumberMod = cell2mat(peaksNumberModCell);
        % estate modulation component to the right/left of the centeral peak
        structName = {sidebandName{cellfun(@(s) ~isempty(s),peaksNumberModCell)}}';
        % position of modulation components
        positionMod = cell2mat(cellfun(@(x) str2num(x(peaksNumberMod(1,1)+1)), structName, 'UniformOutput', false));
    else
        positionMod = 0;
        structName = sidebandName;
    end
end

% CREATEEMPTYSTRUCT function creating the empty structure for finding frequencies
function structSideband = createEmptyStruct(sizeStruct)
    structSideband.posChangedFreq = zeros(sizeStruct,1);
    structSideband.validMag = structSideband.posChangedFreq;
    structSideband.validFreq = structSideband.posChangedFreq;
    structSideband.validLogProm = structSideband.posChangedFreq;
    structSideband.validProm =  structSideband.posChangedFreq;
end