function fullCorrespondenceTable = createFullCorrespondenceTable(file)
%   Developer:              Kosmach
%   Development date:       03-08-2016

% The function fills the cells in shaftCorrespondenceTable
% That is, it fills in the table connection 

 %% _______________________Parametrs___________________________________ %%
 % The number of elements in the device
elementNumber = length(file.shaftVector.freq); 
fullCorrespondenceTable.matrix = zeros(elementNumber);

 %% _____________Creation of a full correspondences tables_____________ %%
for i=1:1:elementNumber
    fullCorrespondenceTable.matrix(:,i) = bsxfun(@rdivide,file.shaftVector.freq(i,1),file.shaftVector.freq);
end
    % entry names, respectively     
    fullCorrespondenceTable.name = file.shaftVector.name;
end

