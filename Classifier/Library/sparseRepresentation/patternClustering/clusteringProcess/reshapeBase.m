function [ base_res ] = reshapeBase( base, config )
% RESHAPEBASE just reshapes base structure
%
% Developer : ASLM
% Date : 27/04/2017

if isempty(base)
   base_res = [];
   return;
end

if length(base) == 1
    base.cluster = 'cl1';
end

classes = arrayfun(@(x) (x.cluster),base,'UniformOutput',false);
clusters = unique(classes);
% Sort unique clusters
sortVector =  mat2cell(sort(cellfun(@(x) str2double(x), cellfun(@(x) x{1},regexp(clusters,'\d*','match'),'UniformOutput',false))),ones(numel(clusters),1)',1);
sortVector = cellfun(@(x) num2str(x),sortVector,'UniformOutput',false)
clusters = cellfun(@(x,y) strcat(x,y),cellfun(@(y) y{1},regexp(clusters,'\D*','match'),'UniformOutput',false),sortVector,'UniformOutput',false);

try
    base_obs = mat2cell(base, ones(size(classes,1),1), 1);
catch
   error(); 
end
base_res = cell(size(clusters));
for i = 1:numel(clusters)
    base_res{i} = cell2mat(base_obs(cell2mat(cellfun(@(x) find(strcmp(classes,x)),clusters(i),'UniformOutput',false))));
end
