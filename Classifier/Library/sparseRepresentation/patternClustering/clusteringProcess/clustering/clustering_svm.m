function [ result, base ] = clustering_svm( base, config )
% CLUSTERING_SVM divides the base into several clusters by the SVM
% cross-validation
%
% Developer : ASLM
% Date : 27/04/2017

class_obs = vertcat(base.class_obs);
class_val = arrayfun(@(x) repmat({x.class},size(x.class_obs,1),1), base, 'UniformOutput',false);
class_val = vertcat(class_val{:});

% Mix all class tags
if config.clustering.mixclasses
    clusters = config.clustering.cluster.list;
    clust_num = numel(clusters);
    for cli = 1:numel(class_val)
        class_val{cli} = clusters{mod(cli,clust_num)+1};
    end
end


% Estimate best train parameters
disp('Estimating best SVM parameters...');
if config.classification.findbest
% 	[~, ~, predict, command] = lib_svm.find_cost_gamma(class_obs, class_val, 'autoweight',config.classification.autoweight);
	[~, ~, predict, command] = lib_svm.find_cost_gamma(class_obs, class_val, 'autoweight',config.classification.autoweight,...
                                                                             'autoscale',config.classification.autoscale,...
                                                                             'fold',config.classification.fold_number);
	[accuracy, average_recall, ~, conf_mat, order] = lib_svm.rate_prediction(class_val, predict);
	if config.classification.autoweight
		[mv, mi] = max(average_recall);
	else
		[mv, mi] = max(accuracy);
	end
	result.findbest = struct('rate',mv, 'confusion',struct('matrix',conf_mat{mi}, 'order',order(mi)));
	result.command = command{mi};
else
	result.command = config.classification.svm_command;
end

disp('SVM Cross-validation. Clustering ... ');
% Build final model
result.model = lib_svm.train(class_obs, class_val, result.command);

% Rate final model performance
if config.classification.ratemodel
	ratemodel = lib_svm.train(class_obs, class_val, [result.command ' -v 10']);
	class_ind = cellfun(@(x) find(strcmp(ratemodel.classes,x)), class_val);
	cm = confusionmat(class_ind, ratemodel.model, 'order',1:numel(ratemodel.classes));
	cmn = cm ./ repmat(sum(cm,2),1,size(cm,2));
	result.ratemodel.confusion.matrix = cm;
	result.ratemodel.confusion.order = ratemodel.classes;
	result.ratemodel.confusion.accuracy = trace(result.ratemodel.confusion.matrix) / sum(result.ratemodel.confusion.matrix(:));
	result.ratemodel.confusion.average_recall = mean(diag(cmn));
end

for i = 1:numel(base)
    base(i).cluster = ratemodel.classes{ratemodel.model(i)};
end