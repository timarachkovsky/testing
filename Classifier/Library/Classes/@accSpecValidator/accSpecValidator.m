classdef accSpecValidator < validator
    %ACCENVSPECVALIDATOR class is validated frequency with tags 
    % and numbers of harmonics into acceleration domain
    
    methods (Access = public)
        
        % Constructor function ... 
        function [myValidator] = accSpecValidator(statusStruct,peakTable,mainFreqStruct,informativeTagsStruct,myConfig,validatorType)
            
            if nargin == 5
                validatorType = 'accelerationSpectrum';
            end
            
            myValidator = myValidator@validator(statusStruct,peakTable,mainFreqStruct,informativeTagsStruct,myConfig,validatorType);
            
        end
        
        % Getters / Setters ...
        
        % ... Getters / Setters 
        
        
        % VALIDATIONPROCESSING a function is main for validation of peaks
        function [ myValidator ] = validationProcessing(myValidator)
                        
            [ preContainer ] = myValidator.createPreValidationContainer();
            [ myValidator ] = preValidation(myValidator, preContainer);   

            [ postContainer ] = myValidator.createPostValidationContainer();
            [ myValidator ] = postValidation(myValidator, postContainer);
            
            [ myValidStruct ] = addValidData2ValidStruct(myValidator);            
            myValidator.validStruct = myValidStruct;
            
            validPeaks = addColumn(myValidator);
            myValidator.filledPeakTable(:,end+1) = validPeaks;
            
            myValidator.nonValidPeaksNumbers = nnz(~validPeaks);
        end
    end
    
    methods (Access = protected)
              
        
        % PREVALIDATION the function is validated each frequency, 
        % relative to other frequency in one defect
        function [ myValidator ] = preValidation( myValidator, fuzzyContainer )

            [rowNumber, columnNumber] = size(myValidator.tagTable);
            maskTable = zeros(rowNumber, columnNumber, 'int8');
            
            % _________________________ Calculations _____________________________ %
            
            % Find defect without priority and exclude it
            priorityColumn = [myValidator.validStruct.priority];
            positionFindPeaks = logical(sum(myValidator.numTable, 1));
            
            % Main calculate
            posWithFreq = int16(find(bsxfun(@and, priorityColumn, positionFindPeaks)));
            
            for currentColumn = posWithFreq
                    
                tagColumn = myValidator.tagTable(:, currentColumn);
                numColumn = myValidator.numTable(:, currentColumn);
                nameModColum = myValidator.nameTableMod(:, currentColumn);  
                relevantColum = myValidator.freqTableRelevantPeakTable(:, currentColumn);

                pos = int16(find(numColumn));
               
                posModulation = ~cellfun(@isempty, nameModColum(pos));

                posMainPeaks = pos(~posModulation);
                
                % Evaluate main peaks
                for i = 1:1:length(posMainPeaks)

                    currentRow = posMainPeaks(i, 1);

                    statusTags = checkSameTag(myValidator.filledPeakTable(relevantColum(currentRow, 1), 5), tagColumn{currentRow, 1});

                    if statusTags   
                            maskTable(currentRow, currentColumn) = int8(myValidator.harmonicEvaluation(...
                                tagColumn, currentRow, numColumn, maskTable(:, currentColumn), fuzzyContainer));
                    end
                end
                
                posSideBand = pos(posModulation);
                
                % Evaluate side band peaks
                for i = 1:1:length(posSideBand)
                    
                    currentRow = posSideBand(i, 1);
                    
                    statusTags = checkSameTag(myValidator.filledPeakTable(relevantColum(currentRow, 1), 5), tagColumn{currentRow, 1});

                    if statusTags
                    
                        mainPeakModulationPos = myValidator.findingMainPeakEvaluation(tagColumn, currentRow, numColumn);    

                        if mainPeakModulationPos

                            statusMainPeak = maskTable(mainPeakModulationPos, currentColumn);
                            
                            if statusMainPeak
                                modulationStatus = isTrueModulation(tagColumn, numColumn, nameModColum, currentRow);
                                maskTable(currentRow, currentColumn) = int8(modulationStatus*100);
                            end
                        end
                    end
                end
                
            end
            
            % ___________________________ Results _________________________________%

            posNotValid = maskTable(:, :) < 30;
            
            % Non valid value set to zero or empty
            maskTable(posNotValid) = int16(0);
            myValidator.tagTable(posNotValid) = cell(1, 1);
            myValidator.numTable(posNotValid) = 0;
            myValidator.freqTableRelevantPeakTable(posNotValid) = 0;
            myValidator.nameTableMod(posNotValid) = cell(1, 1);
            myValidator.magTable(posNotValid) = 0;
            
            myValidator.maskTable = maskTable;
        end
        
        % POSTVALIDATION the function is validated each frequency, 
        % relative to same frequency in all defects 
        function [ myValidator ] = postValidation( myValidator, fuzzyContainer )      
           
            % _________________________ Calculations _____________________________ %
            posWithFreq = int16(find(sum(myValidator.numTable, 1)));
            for currentColumn = posWithFreq

                numColumn = myValidator.numTable(:, currentColumn);
                tagColumn = myValidator.tagTable(:, currentColumn);
                relevantColumn = myValidator.freqTableRelevantPeakTable(:, currentColumn);
                
                pos = int16(find(numColumn));
                for i = 1:1:length(pos(:, 1))
                    
                    currentRow = pos(i, 1);

                    % Get value of the current element (harmonic degree) and it
                    % validity
                    currentValue = myValidator.numTable(currentRow, currentColumn);
                    currentValidity = myValidator.maskTable(currentRow, currentColumn);

                    % Create vectors for function "findMinAndCompare"
                    positionElements = relevantColumn(currentRow,1) == myValidator.freqTableRelevantPeakTable;
                    numVector = myValidator.numTable(positionElements);
                    maskVector = myValidator.maskTable(positionElements);
                    [columVectorElem,numerDefectsVector,~] = find(positionElements);
                    currentPos = find(bsxfun(@times,columVectorElem == currentRow,numerDefectsVector == currentColumn));

                    % Find value of the min element in the row and compare with current
                    % one (check similarity); also get min value valid/md_valid status
                    [ minValue, minValidity, distance] = findMinAndCompare(numVector,maskVector,currentPos);

                    [ ~, positions] = numOfTags(tagColumn, currentRow);
                    % Check distance between current element and the nearest one, if
                    % the distance is too high fuzzy validator may interprets it as a
                    % nonvalid element
                    [distToLatestTruePos, distToLatestPotPos, ~] = ...
                        tagDistance(numColumn,positions,currentRow, myValidator.maskTable(:, currentColumn));

                    % Set input arguments for fuzzy calculations
                    inputArgs = double([minValue, distance, minValidity, currentValue, ...
                                        currentValidity, distToLatestTruePos, distToLatestPotPos]);
                             
                    % Fill maskMatix with fuzzy-result
                    myValidator.maskTable(currentRow, currentColumn) = int8(evalfis(inputArgs, fuzzyContainer));
                end
            end

            % ___________________________ Results _________________________________%

            posNotValid = myValidator.maskTable(:,:) < 70;
            
            myValidator.maskTable(posNotValid) = 0;
            myValidator.tagTable(posNotValid) = cell(1, 1);
            myValidator.numTable(posNotValid) = 0;
            myValidator.freqTableRelevantPeakTable(posNotValid) = 0;
            myValidator.nameTableMod(posNotValid) = cell(1, 1);
            myValidator.magTable(posNotValid) = 0;
            
        end
        
    end
    
    methods (Static = true, Access = protected)
        
        % CREATEPREVALIDATIONCONTAINER function builds the structure of the
        % decision maker (fuzzy container) to validate informative features
        % of the one certain defect.
        function container = createPreValidationContainer()

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

%             % Init 2-state @isModulationTag variable
%             container = addvar(container,'input','isModulationTag',[-0.5 1.5]);
%             container = addmf(container,'input',8,'false','dsigmf',[20.5 -0.5 20.5 0.5]);
%             container = addmf(container,'input',8,'true','dsigmf',[20.5 0.5 20.5 1.5]);
% 
%             % Init 3-state @isTrueModulation variable
%             container = addvar(container,'input','isTrueModulation',[-0.25 1.25]);
%             container = addmf(container,'input',9,'false','dsigmf',[20.5 -0.25 20.5 0.25]);
%             container = addmf(container,'input',9,'mb','dsigmf',[20.5 0.25 20.5 0.75]);
%             container = addmf(container,'input',9,'true','dsigmf',[20.5 0.75 20.5 1.25]);
% 
%             % Init 3-state @modulationTagsNumber variable
%             container = addvar(container,'input','modulationTagsNumber',[-0.5 20.5]);
%             container = addmf(container,'input',10,'no','dsigmf',[20.5 -0.5 20.5 0.5]);
%             container = addmf(container,'input',10,'one','dsigmf',[20.5 0.5 20.5 1.5]);
%             container = addmf(container,'input',10,'more','dsigmf',[20.5 1.5 20.5 20.5]);
% 
%             % Init 3-state @modulationTagsNumber variable
%             container = addvar(container,'input','mainPeakValid',[-0.5 20.5]);
%             container = addmf(container,'input',11,'no','dsigmf',[20.5 -0.5 20.5 0.5]);
%             container = addmf(container,'input',11,'yes','dsigmf',[20.5 0.5 20.5 1.5]);
            
            % OUTPUT:
            % Init 3-state @result variable
            container = addvar(container,'output','result',[-25 125]);
            container = addmf(container,'output',1,'false','trimf',[-25 0 25]);
            container = addmf(container,'output',1,'mb','trimf',[25 50 75]);
            container = addmf(container,'output',1,'true','trimf',[75 100 125]);

            %RULEs:
            % position3; tagsNumber4, startValue3, currentValue3, distToLatestTruePos5, distToLatestPosPos5, nextDist4,
            % isModulationTag2, isTrueModulation3, modulationTagsNumber3, result and etc]

            %start position
            ruleList = [
                        1  1  0  1  0  0  0  3  1  1;               
                        1  2  0  1  0  0  0  3  1  1;   
                        1  3  0  1  0  0  0  3  1  1;
                        1  4  0  1  0  0  0  1  1  1;
                        1  0  0  3  0  0  0  1  1  1;
                        1  0  3  0  0  0  0  1  1  1;

                        1  4  0  2  0  0  0  1  1  1;
                        1  0  0  2  0  0  4  1  1  1;
                        1  0  0  2  0  0  3  1  1  1;
                        1  1  0  2  0  0  1  2  1  1; 
                        1  1  0  2  0  0  2  1  1  1;            
                        1  2  0  2  0  0  1  2  1  1;
                        1  2  0  2  0  0  2  1  1  1;
                        1  3  0  2  0  0  1  3  1  1;
                        1  3  0  2  0  0  2  3  1  1;                                                                 

            %middle position

                        2  4  0  0  0  0  0  1  1  1;

                        2 -4 -3  0  1  0  0  3  1  1;

                        2 -4 -3  0  2  0  0  3  1  1;

                        2 -4 -3  0  3  1  0  2  1  1;
                        2 -4 -3  0  3  2  0  2  1  1;
                        2 -4 -3  0  3  3  0  1  1  1;
                        2 -4 -3  0  3  4  0  1  1  1;
                        2 -4 -3  0  3  5  1  2  1  1;
                        2 -4 -3  0  3  5  2  2  1  1;
                        2 -4 -3  0  3  5  3  1  1  1;
                        2 -4 -3  0  3  5  4  1  1  1;

                        2 -4 -3  0  4  1  0  2  1  1;
                        2 -4 -3  0  4  2  0  2  1  1;
                        2 -4 -3  0  4  3  0  1  1  1;
                        2 -4 -3  0  4  4  0  1  1  1;
                        2 -4 -3  0  4  5  0  1  1  1;

                        2 -4 -3  0  5  5  0  1  1  1;
                        2 -4 -3  0  5  4  0  1  1  1;
                        2 -4 -3  0  5  3  0  1  1  1;
                        2 -4 -3  0  5  2  0  2  1  1;
                        2 -4 -3  0  5  1  0  2  1  1;

                        0  0  3  0  0  0  0  1  1  1; 

            %end position

                        3  1  0  1  0  0  0  3  1  1; 
                        3  1  0  3  5  5  0  1  1  1;

                        3  0 -3 -1  1  0  0  3  1  1;
                        3  0 -3 -1  2  0  0  3  1  1;

                        3  0 -3 -1  3  5  0  1  1  1;
                        3  0 -3 -1  3  4  0  1  1  1;
                        3  0 -3 -1  3  3  0  1  1  1;
                        3  0 -3 -1  3  2  0  2  1  1; %?
                        3  0 -3 -1  3  1  0  2  1  1;

                        3  0 -3 -1  4  5  0  1  1  1;
                        3  0 -3 -1  4  4  0  1  1  1;
                        3  0 -3 -1  4  3  0  1  1  1;
                        3  0 -3 -1  4  2  0  1  1  1; %?
                        3  0 -3 -1  4  1  0  2  1  1;            

                        3  0 -3 -1  5  1  0  2  1  1;
                        3  0 -3 -1  5  2  0  2  1  1;
                        3  0 -3 -1  5  3  0  1  1  1;
                        3  0 -3 -1  5  4  0  1  1  1;
                        3  0 -3 -1  5  5  0  1  1  1;
                        
            % Modulation tag rules
            %RULEs:
            % position3; tagsNumber4, startValue3, currentValue3, distToLatestTruePos5, distToLatestPosPos5, nextDist4,
            % isModulationTag2, isTrueModulation3, modulationTagsNumber3, result and etc]
                        
%                         0  0  0  0  0  0  0  2  0  0  1  1  1  1;
%                         0  0  0  0  0  0  0  2  3  1  2  1  1  1;
%                         0  1  0  0  0  0  0  2  3 -1  2  2  1  1;
%                         
%                         % true valid modulation
%                         0 -1  0  0  0  0  0  2  3 -1  2  3  1  1;%changed
% 
%                         0  0  3  0  0  0  0  2  3  0  2  1  1  1;
% 
%                         % mb modulation rules...
%                         0  0  0  0  0  0  0  2  2  1  2  1  1  1;
%                         0  1  0  0  0  0  0  2  2 -1  2  2  1  1;
% 
%                         0 -1  0  0  0  0  0  2  2 -1  2  2  1  1;%changed
% 
%                         0  0  3  0  0  0  0  2  2  0  2  1  1  1;
%                         % ... mb modulation rules
% 
% 
%                         % nonvalid modulation
%                         0  0  0  0  0  0  0  2  1  0  0  1  1  1;
                        ];

            container = addrule(container,ruleList);

        end
       
        % CREATEPOSTVALIDATIONCONTAINER function builds the structure of 
        % decision maker (fuzzy container) to validate informative features
        % between different defects.
        function container = createPostValidationContainer()

            container = newfis('optipaper'); 

            % INPUT:
            % Init 4-state @minRowValue variable
            container = addvar(container,'input','minRowValue',[-0.5 100.5]);
            container = addmf(container,'input',1,'low','dsigmf',[20.5 0.5 20.5 2.5]);
            container = addmf(container,'input',1,'average','dsigmf',[20.5 2.5 20.5 4.5]);
            container = addmf(container,'input',1,'high','dsigmf',[20.5 4.5 20.5 100.5]);
            container = addmf(container,'input',1,'no','dsigmf',[20.5 -0.5 20.5 0.5]);

            % Init 4-state @similarity (CV - MV) variable
            container = addvar(container,'input','similarity',[-200.5 200.5]);
            container = addmf(container,'input',2,'greater','dsigmf',[20.5 -200.5 20.5 -4.5]);
            container = addmf(container,'input',2,'similar','dsigmf',[20.5 -4.5 20.5 4.5]);
            container = addmf(container,'input',2,'lower','dsigmf',[20.5 4.5 20.5 200.5]);

            % Init 2-state @minValidity variable
            container = addvar(container,'input','minValidity',[-25 125]);
            container = addmf(container,'input',3,'mb','dsigmf',[20.5 -25 20.5 75]);
            container = addmf(container,'input',3,'valid','dsigmf',[20.5 75 20.5 125]);

            % Init 3-state @currentValue variable
            container = addvar(container,'input','currentValue',[0.5 100.5]);
            container = addmf(container,'input',4,'low','dsigmf',[20.5 0.5 20.5 2.5]);
            container = addmf(container,'input',4,'average','dsigmf',[20.5 2.5 20.5 4.5]);
            container = addmf(container,'input',4,'high','dsigmf',[20.5 4.5 20.5 100.5]);

            % Init 2-state @currentValidity variable
            container = addvar(container,'input','currentValidity',[-25 125]);
            container = addmf(container,'input',5,'mb','dsigmf',[20.5 -25 20.5 75]);
            container = addmf(container,'input',5,'valid','dsigmf',[20.5 75 20.5 125]);

            % Init 5-state @distToLatestTruePos variable
            container = addvar(container,'input','distToLatestTruePos',[-0.5 100.5]);
            container = addmf(container,'input',6,'close','dsigmf',[20.5 0.5 20.5 2.5]);
            container = addmf(container,'input',6,'notFar','dsigmf',[20.5 2.5 20.5 4.5]);
            container = addmf(container,'input',6,'far','dsigmf',[20.5 4.5 20.5 6.5]);
            container = addmf(container,'input',6,'enormous','dsigmf',[20.5 6.5 20.5 100.5]);
            container = addmf(container,'input',6,'no','dsigmf',[20.5 -0.5 20.5 0.5]);

            % Init 5-state @distToLatestPotPos variable
            container = addvar(container,'input','distToLatestPotPos',[-0.5 100.5]);
            container = addmf(container,'input',7,'close','dsigmf',[20.5 0.5 20.5 2.5]);
            container = addmf(container,'input',7,'notFar','dsigmf',[20.5 2.5 20.5 4.5]);
            container = addmf(container,'input',7,'far','dsigmf',[20.5 4.5 20.5 6.5]);
            container = addmf(container,'input',7,'enormous','dsigmf',[20.5 6.5 20.5 100.5]);
            container = addmf(container,'input',7,'no','dsigmf',[20.5 -0.5 20.5 0.5]);

            % OUTPUT:
            % Init 3-state @result variable
            container = addvar(container,'output','result',[-25 125]);
            container = addmf(container,'output',1,'false','trimf',[-25 0 25]);
            container = addmf(container,'output',1,'mb','trimf',[25 50 75]);
            container = addmf(container,'output',1,'true','trimf',[75 100 125]);

            %RULEs:
            % minRowValue4; similarity3; minValidity2; currentValue3; currentValidity2, distToLatestTruePos5, distToLatestPotPos5]

            %RESULT: 3--> true; 2-->mb; 1-->false


            ruleList = [ 
            %start    
                         0  0  0  0  2  0  0  3  1  1;
                         1  3  0  3  1  5  5  1  1  1;
                         1  2  0  2  1  5  5  1  1  1;
                         1  2  0  1  1  5  5  3  1  1;
                         2  2  0  3  1  5  5  1  1  1;
                         2  3  0  3  1  5  5  1  1  1;
                         2  2  0  2  1  5  5  3  1  1;
                         2  2  0  1  1  5  5  3  1  1;
                         3  2  0  3  1  5  5  1  1  1;
                         3  2  0  2  1  5  5  3  1  1;
                         3  1  0  2  1  5  5  3  1  1;
                         3  2  0  1  1  5  5  3  1  1;
                         3  1  0  1  1  5  5  3  1  1;

            % mid & end
                         0  0  0  0  1  1  5  3  1  1;
                         0  0  0  0  1  2  5  3  1  1;
                         0  0  0  0  1  3  5  1  1  1;
                         0  0  0  0  1  4  5  1  1  1;

            %             -1  0  0  1  0  0  3  1  1;
            %     
            %              1  2  0  1  0  0  3  1  1;
            %              1  2  0  2  0 -3  3  1  1;
            %              1  1  0  3  0  3  1  1  1;
            %              1  1  0  3  2  1  3  1  1;
            %              1  0  0  3  0 -1  1  1  1;
            %              1  1  0  3  0  3  1  1  1;
            %              
            %              2  1  0  3  0  3  3  1  1;
            %              3  0  0  0 -1  0  3  1  1;
                       ];

            container = addrule(container,ruleList);
            
        end 
        
        % HARMONICEVALUATION function evaluate tags 
        % of frequency with fuzzy rules
        function [ result ] = harmonicEvaluation(tagColumn, currentRow, numColumn, maskColumn, fuzzyContainer)  
            
            % Find the location (start/middle/end) we stand on, the whole
            % number of similar tags and their positions
            [tagsNumber, positions] = numOfTags( tagColumn, currentRow );
            location = tagLocation( tagColumn, currentRow );

            % Find the firs non-empty tag row starts from and and number of the
            % current one (harmonic degree)
            firstNumber = numColumn(positions(1,1),1);
            currentNumber = numColumn(currentRow,1);
            
            % Find the nearest distance of the similar tags (before/after
            % current) to consider of validity of the current one
            [distToLatestTruePos, distToLatestPotPos, distAfter] = tagDistance(numColumn,positions,currentRow, maskColumn);
            
            % Set input arguments for fuzzy calculations
            inputArgs = double([location, tagsNumber, firstNumber, currentNumber, distToLatestTruePos, ...
                                distToLatestPotPos, distAfter]);
                     
            % Fill maskMatix with fuzzy-result
            result = evalfis(inputArgs,fuzzyContainer);
            
        end
        
        % FINDINGMAINPEAKEVALUATION function finding the position 
        % of main peaks of modulation
        function [ mainPeakPos ] = findingMainPeakEvaluation(tagColumn, currentRow, numColumn)
            
             tagCurrentVector = cellfun(@(x) isequal(x, tagColumn{currentRow}(1)), tagColumn);
             numCurrentVector = numColumn(currentRow) == numColumn;
             mainPeakPos = find(bsxfun(@times, numCurrentVector, tagCurrentVector), 1);
             if isempty(mainPeakPos)
                 mainPeakPos = 0;
             end
        end
    end
    
end

