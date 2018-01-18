function [ result, base ] = clustering( base, config )
%CLUSTERING implements clustering by
%   1. SVM (support vector machine)
%   2. K-Means 
%
% Developer : ASLM
% Date : 27/04/2017


% base variance validation
% [base, config] = varianceValidation(base, config); 


% clustering
switch(config.clustering.type)
    case 'svm'
        [result, base] = clustering_svm(base, config);
    case 'k-means'
        [result, base] = clustering_kmeans(base, config);
    otherwise
        error('Unknown clustering method!');
end

base = reshapeBase(base,config);

