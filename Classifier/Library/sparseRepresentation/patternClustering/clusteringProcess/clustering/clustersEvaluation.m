function [ base_major, base_secondary ] = clustersEvaluation( base, config, info )
% CLUSTEREVALUATION fun

majorMask = zeros(numel(base),1);
for cli = 1:numel(base)
    majorMask(cli,1) = nnz(arrayfun(@(x) x.major, base{cli,1}));
end

clust_num = numel(base);
class_list = mat2cell(linspace(1,clust_num, clust_num)',ones(clust_num,1),1);
config.clustering.cluster.list = cellfun(@(x) strcat('cl',num2str(x)), class_list,'UniformOutput',false);

base_major = base(majorMask>0);
base_secondary = base(majorMask0);


cluster_size = cell2mat(cellfun(@(x) size(x,1), base, 'UniformOutput',false));
figure('Color','w'), plot(cluster_size);
ylabel('Size'); xlabel('Cluster'); 
xticks(linspace(1, numel(base), numel(base)));
xticklabels(config.clustering.cluster.list);
title('Clusters Size');
set(gca, 'FontSize', 8)

