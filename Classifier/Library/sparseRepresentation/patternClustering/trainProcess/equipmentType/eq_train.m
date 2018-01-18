function [ result] = eq_train( base, config, info )

    switch (config.classification.svmType)
        case {'0','1','2'}
            [ result] = tr_svm_train( base, config );
        case {'3','4'}
            [ result] = tr_svr_train( base, config );
        otherwise
            [ result] = tr_svm_train( base, config );
    end

function [ result] = tr_svm_train( base, config, info )

    class_obs = vertcat(base.class_obs);
    class_val = arrayfun(@(x) repmat({x.class},size(x.class_obs,1),1), base, 'UniformOutput',false);
    class_val = vertcat(class_val{:});
    if ~ischar(class_val{1,1})
        class_val = cellfun(@(x) num2str(x),class_val, 'UniformOutput',false);
    end
    
    % Feature selection procedure
    [features_idx] = eq_feature_selection(class_obs,class_val, config);
    class_obs = class_obs(:,features_idx);
    
    % Estimate best train parameters
    disp('Estimating best SVM parameters...');
    if config.classification.findbest
        
    % SVM training
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
%     result.model = lib_svm.train(class_obs, class_val, result.command);
    result.model = lib_svm.train(class_obs, class_val, [result.command, ' -s ',config.classification.svmType,...
                                                                        ' -b ',config.classification.probabilityEnable,...
                                                                        ' -t ',config.classification.kernelType] );
                                                                    
    result.features_idx = features_idx;
    % Rate final model performance
    if config.classification.ratemodel
%         ratemodel = lib_svm.train(class_obs, class_val, [result.command, ' -v 10', ' -s ',config.classification.svmType, ' -b ',config.classification.probabilityEnable] ); % for SVM
        ratemodel = lib_svm.train(class_obs, class_val, [result.command, ' -v 10', ' -s ',config.classification.svmType, ' -b ',config.classification.probabilityEnable, ' -t ',config.classification.kernelType] ); % for SVM
        class_ind = cellfun(@(x) find(strcmp(ratemodel.classes,x)), class_val);     % for SVM
        cm = confusionmat(class_ind, ratemodel.model, 'order',1:numel(ratemodel.classes));
        cmn = cm ./ repmat(sum(cm,2),1,size(cm,2));
        result.ratemodel.confusion.matrix = cm;
        result.ratemodel.confusion.order = ratemodel.classes;
        result.ratemodel.confusion.accuracy = trace(result.ratemodel.confusion.matrix) / sum(result.ratemodel.confusion.matrix(:));
        result.ratemodel.confusion.average_recall = mean(diag(cmn));
        result.ratemodel.class_val = ratemodel.model;
    end

% % for i = 1:numel(base)
% %     base(i).cluster = ratemodel.classes{ratemodel.model(i)};
% % end
% for i = 1:numel(base)
%     base(i).cluster = ratemodel.classes(ratemodel.model(i));
% end


function [ result] = tr_svr_train( base, config, info )

class_obs = vertcat(base.class_obs);
    class_val = arrayfun(@(x) repmat({x.class},size(x.class_obs,1),1), base, 'UniformOutput',false);
    class_val = vertcat(class_val{:});
    if ~ischar(class_val{1,1})
        class_val = cellfun(@(x) num2str(x),class_val, 'UniformOutput',false);
    end
    % Estimate best train parameters
    disp('Estimating best SVM parameters...');
    if config.classification.findbest
         
%   SVR training
        class_val = str2num(cell2mat(class_val));
        [~, ~, predict, command] = lib_svm.find_cost_gamma(class_obs, class_val, 'autoweight',config.classification.autoweight,...
                                                                                 'is_svr', 1);
%         [~, ~, predict, command] = lib_svm.find_cost_gamma(class_obs, class_val, 'autoweight',config.classification.autoweight,...
%                                                                                  'autoscale',config.classification.autoscale,...
%                                                                                  'fold',config.classification.fold_number,...
%                                                                                  'is_svr', 1);                                                                    
                                                                                                                                
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
%     result.model = lib_svm.train(class_obs, class_val, result.command);
    result.model = lib_svm.train(class_obs, class_val, [result.command, ' -s ',config.classification.svmType, ' -b ',config.classification.probabilityEnable] );

    % Rate final model performance
    if config.classification.ratemodel
        ratemodel = lib_svm.train(class_obs, class_val, [result.command ' -v 10']);  %for SVR
        class_ind = arrayfun(@(x) find(ismember(ratemodel.classes,x)), class_val);   % for SVR
        cm = confusionmat(class_ind, ratemodel.model, 'order',1:numel(ratemodel.classes));
        cmn = cm ./ repmat(sum(cm,2),1,size(cm,2));
        result.ratemodel.confusion.matrix = cm;
        result.ratemodel.confusion.order = ratemodel.classes;
        result.ratemodel.confusion.accuracy = trace(result.ratemodel.confusion.matrix) / sum(result.ratemodel.confusion.matrix(:));
        result.ratemodel.confusion.average_recall = mean(diag(cmn));
        result.ratemodel.class_val = ratemodel.model;
    end
