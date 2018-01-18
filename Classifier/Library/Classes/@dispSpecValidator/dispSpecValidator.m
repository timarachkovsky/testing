classdef dispSpecValidator < validator
    %VELSPECVALIDATOR class is validated frequency with tags 
    % and numbers of harmonics into displacement domain
    
    properties (Access = protected)
        trueValidTable
    end
    
    methods (Access = public)
        
        % Constructor function ... 
        function [myValidator] = dispSpecValidator(statusStruct,peakTable,mainFreqStruct,informativeTagsStruct,myConfig,validatorType)
            
            if nargin == 5
                validatorType = 'displacementSpectrum';
            end

            myValidator = myValidator@validator(statusStruct,peakTable,mainFreqStruct,informativeTagsStruct,myConfig,validatorType);
            
        end
        
        % Getters / Setters ...
        
        function [myTrueValidTable] = getTrueValidTable(myValidator)
           myTrueValidTable = myValidator.trueValidTable; 
        end
        function [myValidator] = setTrueValidTable(myValidator,myTrueValidTable)
           myValidator.trueValidTable = myTrueValidTable; 
        end
        
        % ... Getters / Setters 
        
        % VALIDATIONPROCESSING function ...
        function [ myValidator ] = validationProcessing(myValidator)
                        
            [ preContainer ] = myValidator.createPreValidationContainer();
            [ myValidator ] = preValidation(myValidator, preContainer);
             
            [ myValidStruct ] = addValidData2ValidStruct(myValidator);            
            myValidator.validStruct = myValidStruct;
            
            myValidator = createTrueValidTable(myValidator);

            validPeaks = addColumn(myValidator);
            myValidator.filledPeakTable(:,end+1) = validPeaks;
            
            myValidator.nonValidPeaksNumbers = nnz(~validPeaks);
        end
    end
    
    methods (Access = protected)
        
        % PREVALIDATION the function is validated each frequency, 
        % relative to other frequency in one defect, without modulation, modulation 
        % frequency validate how "invalid"
        function [ myValidator ] = preValidation( myValidator, fuzzyContainer )
            
            [rowNumber,columnNumber] = size(myValidator.tagTable);
            maskTable = zeros(rowNumber,columnNumber, 'int8');

            priorityColumn = [myValidator.validStruct.priority];
            positionFindPeaks = logical(sum(myValidator.numTable, 1));
            posWithFreq = int16(find(bsxfun(@and, priorityColumn, positionFindPeaks)));
            for currentColumn = posWithFreq

                tagColumn = myValidator.tagTable(:,currentColumn);
                numColumn = myValidator.numTable(:,currentColumn);
%                 nameColum = myValidator.nameTableMod(:,currentColumn);  
                relevantColum = myValidator.freqTableRelevantPeakTable(:,currentColumn);
                
                pos = int16(find(numColumn));
                for i = 1:1:length(pos)
                    currentRow = pos(i,1);

                    isModFlag = isModulationTag(tagColumn(currentRow,1));
                    statusTags = checkSameTag(myValidator.filledPeakTable(relevantColum(currentRow,1), 5), tagColumn{currentRow,1});
                    if ~isModFlag && statusTags                           

                        % Find the location (start/middle/end) we stand on, the whole
                        % number of similar tags and their positions
                        location = tagLocation(tagColumn, currentRow);
                        [tagsNumber, positions] = numOfTags(tagColumn, currentRow);

                        % Find the firs non-empty tag row starts from and and number of the
                        % current one (harmonic degree)
                        firstNumber = numColumn(positions(1,1),1);
                        currentNumber = numColumn(currentRow,1);

                        % Find the nearest distance of the similar tags (before/after
                        % current) to consider of validity of the current one
                        [distToLatestTruePos, distToLatestPotPos, distAfter] = ...
                            tagDistance(numColumn,positions,currentRow, maskTable(:, currentColumn));

                        % Set input arguments for fuzzy calculations
                        inputArgs = double([location, tagsNumber, firstNumber, currentNumber, ...
                                     distToLatestTruePos, distToLatestPotPos, distAfter]);

                        % Fill maskMatix with fuzzy-result
                        maskTable(currentRow, currentColumn) = int8(evalfis(inputArgs, fuzzyContainer));
%                     else
%                         maskTable(currentRow, currentColumn) = int8(0);
                    end
                end
                
            end

            % ___________________________ Results _________________________________%

            posNotValid = maskTable(:,:) < 30;
            
            maskTable(posNotValid) = 0;
            myValidator.tagTable(posNotValid) = cell(1,1);
            myValidator.numTable(posNotValid) = 0;
            myValidator.freqTableRelevantPeakTable(posNotValid) = 0;
            myValidator.nameTableMod(posNotValid) = cell(1,1);
            myValidator.magTable(posNotValid) = 0;
            
            myValidator.maskTable = maskTable;
            
        end
        
        function [ myValidator ] = postValidation( myValidator, fuzzyContainer ) 
            % dummy ... 
            validTagTable = [];
            validNumTable = [];
            maskTable = [];
            % ... dummy
        end
        
        % CREATETRUEVALIDTABLE function fill table with true valid peaks
        % position (i.g. peaks with great logarithmic prominence and high
        % validity;
        function [ myValidator ] = createTrueValidTable(myValidator)
            %  Set logarithmic prominence thresholds (above noise level)
            veryLowProminenceLevel = 1; % [dB]
            lowProminenceLevel = 3;     % [dB]
            averageProminenceLevel = 6; % [dB]
            highProminenceLevel = 12;   % [dB]
            veryHighProminenceLevel = 18;% [dB]
            
            trueValidityLevel = 0.7;
            
            % dummy ... 
            myValidStruct = myValidator.validStruct;
            myLogProminenceTable = myValidator.magTable;
            myMagTable = myValidator.magTable;
            myMaskTable = myValidator.maskTable;
            
            trueValidMaskTable = myMaskTable(:,:) > trueValidityLevel;
            
            trueValidMagTable = zeros(size(myMagTable), 'int8');
            trueValidMagTable(myMagTable(:,:) < averageProminenceLevel) = 0;
            trueValidMagTable(myMagTable(:,:) >= averageProminenceLevel) = 70;
            trueValidMagTable(myMagTable(:,:) > highProminenceLevel) = 90;
            trueValidMagTable(myMagTable(:,:) > veryHighProminenceLevel) = 100;
            
            myValidator.trueValidTable = myMaskTable.*trueValidMagTable;
            % ...dummy
            
        end
        
    end
    
    methods (Static = true, Access = protected)
        
        % CREATEPREVALIDATIONCONTAINER function builds the structure of the
        % decision maker (fuzzy container) to validate informative features
        % of the one certain defect.
        function [ container ] = createPreValidationContainer()

            container = newfis('optipaper'); 

            % INPUT:
            % Init 3-state @position variable
            container = addvar(container,'input','position',[-0.5 2.5]);
            container = addmf(container,'input',1,'start','trimf',[-0.5 0 0.5]);
            container = addmf(container,'input',1,'middle','trimf',[0.5 1 1.5]);
            container = addmf(container,'input',1,'end','trimf',[1.5 2 2.5]);

            % Init 4-state @tagsNumber  variable
            container = addvar(container,'input','tagsNumber',[-0.5 100.5]);
            container = addmf(container,'input',2,'few','dsigmf',[20.5 0.5 20.5 2.5]);
            container = addmf(container,'input',2,'average','dsigmf',[20.5 2.5 20.5 4.5]);
            container = addmf(container,'input',2,'many','dsigmf',[20.5 4.5 20.5 100.5]);
            container = addmf(container,'input',2,'no','dsigmf',[20.5 -0.5 20.5 0.5]);

            % Init 3-state @startValue variable
            container = addvar(container,'input','startValue',[0.5 100.5]);
            container = addmf(container,'input',3,'low','dsigmf',[20.5 0.5 20.5 2.5]);
            container = addmf(container,'input',3,'average','dsigmf',[20.5 2.5 20.5 4.5]);
            container = addmf(container,'input',3,'high','dsigmf',[20.5 4.5 20.5 100.5]);

            % Init 3-state @currentValue variable
            container = addvar(container,'input','currentValue',[0.5 100.5]);
            container = addmf(container,'input',4,'low','dsigmf',[20.5 0.5 20.5 2.5]);
            container = addmf(container,'input',4,'average','dsigmf',[20.5 2.5 20.5 4.5]);
            container = addmf(container,'input',4,'high','dsigmf',[20.5 4.5 20.5 100.5]);

            % Init 5-state @distToLatestTruePos variable
            container = addvar(container,'input','distToLatestTruePos',[-0.5 100.5]);
            container = addmf(container,'input',5,'close','dsigmf',[20.5 0.5 20.5 2.5]);
            container = addmf(container,'input',5,'notFar','dsigmf',[20.5 2.5 20.5 4.5]);
            container = addmf(container,'input',5,'far','dsigmf',[20.5 4.5 20.5 6.5]);
            container = addmf(container,'input',5,'enormous','dsigmf',[20.5 6.5 20.5 100.5]);
            container = addmf(container,'input',5,'no','dsigmf',[20.5 -0.5 20.5 0.5]);

            % Init 5-state @distToLatestPotPos variable
            container = addvar(container,'input','distToLatestPotPos',[-0.5 100.5]);
            container = addmf(container,'input',6,'close','dsigmf',[20.5 0.5 20.5 2.5]);
            container = addmf(container,'input',6,'notFar','dsigmf',[20.5 2.5 20.5 4.5]);
            container = addmf(container,'input',6,'far','dsigmf',[20.5 4.5 20.5 6.5]);
            container = addmf(container,'input',6,'enormous','dsigmf',[20.5 6.5 20.5 100.5]);
            container = addmf(container,'input',6,'no','dsigmf',[20.5 -0.5 20.5 0.5]);

            % Init 5-state @nextDistance variable
            container = addvar(container,'input','nextDistance',[-0.5 100.5]);
            container = addmf(container,'input',7,'close','dsigmf',[20.5 0.5 20.5 2.5]);
            container = addmf(container,'input',7,'notFar','dsigmf',[20.5 2.5 20.5 4.5]);
            container = addmf(container,'input',7,'far','dsigmf',[20.5 4.5 20.5 6.5]);
            container = addmf(container,'input',7,'enormous','dsigmf',[20.5 6.5 20.5 100.5]);
            container = addmf(container,'input',7,'no','dsigmf',[20.5 -0.5 20.5 0.5]);

            % OUTPUT:
            % Init 3-state @result variablemodulationTagsNumber3
            container = addvar(container,'output','result',[-25 125]);
            container = addmf(container,'output',1,'false','trimf',[-25 0 25]);
            container = addmf(container,'output',1,'mb','trimf',[25 50 75]);
            container = addmf(container,'output',1,'true','trimf',[75 100 125]);

            %RULEs:
            % position3; tagsNumber4, startValue3, currentValue3, distToLatestTruePos5, distToLatestPosPos5, nextDist4, result and etc]

            %start position
            ruleList = [
                        1  1  0  1  0  0  0    3  1  1;               
                        1  2  0  1  0  0  0    3  1  1;   
                        1  3  0  1  0  0  0    3  1  1;
                        1  4  0  1  0  0  0    1  1  1;
                        1  0  0  3  0  0  0    1  1  1;
                        1  0  3  0  0  0  0    1  1  1;

                        1  4  0  2  0  0  0    1  1  1;
                        1  0  0  2  0  0  4    1  1  1;
                        1  0  0  2  0  0  3    1  1  1;
                        1  1  0  2  0  0  1    2  1  1; 
                        1  1  0  2  0  0  2    1  1  1;            
                        1  2  0  2  0  0  1    2  1  1;
                        1  2  0  2  0  0  2    1  1  1;
                        1  3  0  2  0  0  1    3  1  1;
                        1  3  0  2  0  0  2    3  1  1;                                                                 

            %middle position

                        2  4  0  0  0  0  0    1  1  1;

                        2 -4 -3  0  1  0  0    3  1  1;

                        2 -4 -3  0  2  0  0    3  1  1;

                        2 -4 -3  0  3  1  0    2  1  1;
                        2 -4 -3  0  3  2  0    2  1  1;
                        2 -4 -3  0  3  3  0    1  1  1;
                        2 -4 -3  0  3  4  0    1  1  1;
                        2 -4 -3  0  3  5  1    2  1  1;
                        2 -4 -3  0  3  5  2    2  1  1;
                        2 -4 -3  0  3  5  3    1  1  1;
                        2 -4 -3  0  3  5  4    1  1  1;

                        2 -4 -3  0  4  1  0    2  1  1;
                        2 -4 -3  0  4  2  0    2  1  1;
                        2 -4 -3  0  4  3  0    1  1  1;
                        2 -4 -3  0  4  4  0    1  1  1;
                        2 -4 -3  0  4  5  0    1  1  1;

                        2 -4 -3  0  5  5  0    1  1  1;
                        2 -4 -3  0  5  4  0    1  1  1;
                        2 -4 -3  0  5  3  0    1  1  1;
                        2 -4 -3  0  5  2  0    2  1  1;
                        2 -4 -3  0  5  1  0    2  1  1;

                        0  0  3  0  0  0  0    1  1  1; 

            %end position

                        3  1  0  1  0  0  0    3  1  1; 
                        3  1  0  3  5  5  0    1  1  1;

                        3  0 -3 -1  1  0  0    3  1  1;
                        3  0 -3 -1  2  0  0    3  1  1;

                        3  0 -3 -1  3  5  0    1  1  1;
                        3  0 -3 -1  3  4  0    1  1  1;
                        3  0 -3 -1  3  3  0    1  1  1;
                        3  0 -3 -1  3  2  0    2  1  1; %?
                        3  0 -3 -1  3  1  0    2  1  1;

                        3  0 -3 -1  4  5  0    1  1  1;
                        3  0 -3 -1  4  4  0    1  1  1;
                        3  0 -3 -1  4  3  0    1  1  1;
                        3  0 -3 -1  4  2  0    1  1  1; %?
                        3  0 -3 -1  4  1  0    2  1  1;            

                        3  0 -3 -1  5  1  0    2  1  1;
                        3  0 -3 -1  5  2  0    2  1  1;
                        3  0 -3 -1  5  3  0    1  1  1;
                        3  0 -3 -1  5  4  0    1  1  1;
                        3  0 -3 -1  5  5  0    1  1  1;
                        
                        ];

            container = addrule(container,ruleList);

        end
       
        function [ container ] = createPostValidationContainer()
            % dummy ... 
           container = []; 
           % ... dummy
        end 
    end
end

