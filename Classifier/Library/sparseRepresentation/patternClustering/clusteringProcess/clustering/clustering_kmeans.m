function [ result, base ] = clustering_kmeans( base, config )
% CLUSTERING_KMEANS divides the base into several clusters by the k-means
% algorithm
%
% Developer : ASLM
% Date : 27/04/2017

try
    if isempty(base)
       result = []; 
       return;
    else
        class_obs = vertcat(base.class_obs);
    end
catch
    error();
end

switch (config.clustering.kmeans.crossValidation)
    case('zeros')
        class_obs = km_zeros_validation(class_obs);
    case('var')
        class_obs = km_std_validation(class_obs);
    case('zeros+std')
        class_obs = km_zeros_validation(class_obs);
        class_obs = km_std_validation(class_obs);
    otherwise
        class_obs = class_obs;
end

class_val = arrayfun(@(x) repmat({x.class},size(x.class_obs,1),1), base, 'UniformOutput',false);
class_val = vertcat(class_val{:});

% Find optimal number of clusters ...
[clust_num] = best_kmeans(class_obs, config);
if isempty(clust_num)
    clust_num = 1;
    warning('There is only ONE feature for clustering!');
end
% ... Find optimal number of clusters

class_list = mat2cell(linspace(1,clust_num,clust_num)',ones(clust_num,1),1);
config.clustering.cluster.list = cellfun(@(x) strcat('cl',num2str(x)), class_list,'UniformOutput',false);


% Mix all class tags
% if config.clustering.mixclasses
switch(config.clustering.mixclasses)
    case 'generate'
        clusters = config.clustering.cluster.list;
        clust_num = numel(clusters);
        for cli = 1:numel(class_val)
            idx = mod(cli,clust_num);
            if (idx == 0)
                idx = clust_num;
            end
            class_val{cli} = clusters{idx};
        end
    case 'one'
        clusters = unique(class_val);
        clust_num = numel(clusters);
    case 'off'
        clusters = base.clusters;
end



disp('K-mean clustering...');
if config.parpoolEnable
    opts = statset('UseParallel',true,'MaxIter',10000); % options
else
    opts = statset('MaxIter',10000); % options
end
try
    if isempty(class_obs)
        result = [];
        return;
    else
        [model,C, SUMD, D] = kmeans(class_obs,clust_num,'EmptyAction','drop','Replicates',10,'Options',opts);
    end
catch
   error(); 
end

% Rate final model performance
if config.classification.ratemodel
%     classes = clusters;
    class_ind = cellfun(@(x) find(strcmp(clusters,x)), class_val);
	cm = confusionmat(class_ind, model, 'order',1:numel(clusters));
	cmn = cm ./ repmat(sum(cm,2),1,size(cm,2));
	result.ratemodel.confusion.matrix = cm;
	result.ratemodel.confusion.order = clusters;
	result.ratemodel.confusion.accuracy = trace(result.ratemodel.confusion.matrix) / sum(result.ratemodel.confusion.matrix(:));
	result.ratemodel.confusion.average_recall = mean(diag(cmn));
    result.ratemodel.clusters.C = C;
    result.ratemodel.clusters.sumD = SUMD;
    result.ratemodel.clusters.D = D;
end

for i = 1:numel(base)
    base(i).cluster = clusters{model(i)};
end



% Remove features with greate number of zeros ( > threshold)
function [base_valid] = km_zeros_validation(base)

    threshold = 0;

    base_valid = mat2cell(base,size(base,1),ones(size(base,2),1));
    valid_mask = cellfun(@(x) nnz(x)/length(x) > threshold, base_valid);
    
    base_valid = cell2mat(base_valid(valid_mask));
    
% Remove features with great number of zeros and ones ( > threshold)   
function [base_valid] = km_std_validation(base)

    threshold = 0.05;
    
    base_valid = mat2cell(base, size(base,1),ones(size(base,2),1));
    valid_mask = cellfun(@(x) std(x,0,1)/mean(x)>threshold, base_valid);
    
    base_valid = cell2mat(base_valid(valid_mask));