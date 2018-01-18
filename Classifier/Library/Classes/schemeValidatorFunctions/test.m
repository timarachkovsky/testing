clc; clear all; close all;

load('tableData.mat');
[ preContainer ] = createPreValidationContainer();


%% ________________ Test calculations... _________
% currentColumn = 1;
% [pos,~] = find(~cellfun(@isempty,tagTable(:,currentColumn)));
% 
% tagColumn = tagTable(:,currentColumn);
% numColumn = numTable(:,currentColumn);
% 
% currentRow = pos(1,1);
% [ location ] = tagLocation( tagColumn, currentRow );
% 
% [ tagsNumber, positions] = numOfTags( tagColumn, currentRow );
% 
% firstNumber = numColumn(positions(1,1),1);
% currentNumber = numColumn(currentRow,1);
% 
% [ distBefore, distAfter ] = tagDistance(numColumn,positions,currentRow);

% [ inputArgs ] = [location, tagsNumber,firstNumber,currentNumber,distBefore, distAfter];
% [ result ] = evalfis(inputArgs,container);
%% ________________ ...Test calculations ______________________________ %%

% rowNum = 1;
% colNum = 1;
% [ minValue, minPosition, distance] = findMinAndCompare(numTable,rowNum,colNum);



[ tagTable,numTable,maskTable] = preValidation(tagTable,numTable,preContainer);

config.showRules = 1;
[ postContainer ] = createPostValidationContainer(config);

[ tagTable,numTable,maskTable] = postValidation(tagTable,numTable,postContainer,maskTable);
maskTable;
