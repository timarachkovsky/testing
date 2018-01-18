function [features_idx] = eq_feature_selection(train_data,class_vector, config)

    disp('Feature selection ...');
    
    class_names = unique(class_vector);
    
    idx_M = cell(numel(class_names));
    for i = 1:numel(idx_M)
        [rw,cl] = ind2sub(size(idx_M),i);
        idx_M{i} = [rw,cl];
    end
    
    idx_M = idx_M(logical(triu(ones(numel(class_names))) - diag(diag(ones(numel(class_names))))   ));
    
    features_idx = cell(size(idx_M));
    for i = 1:numel(idx_M)
        train_data1 = train_data(cellfun(@(x) strcmp(x,class_names(idx_M{i}(1))), class_vector),:);
        train_data2 = train_data(cellfun(@(x) strcmp(x,class_names(idx_M{i}(2))), class_vector),:);

        features_idx{i} = local_FS(train_data1, train_data2);
    end
    
    features_idx = sort(unique(cell2mat(features_idx')));
    
    
% %     % Test...
% %     class1 = '1'; class2 = '3';
% %     
% %     train_data1 = train_data(cellfun(@(x) strcmp(x,class1), class_vector),:);
% %     train_data2 = train_data(cellfun(@(x) strcmp(x,class2), class_vector),:);
% %     
% %     [features_idx] = local_FS(train_data1, train_data2);
% %     % ... Test


% ----------------------------- Subfunctions ------------------------ % 
function [features_idx] = local_FS(train_data1, train_data2, config)
% Local two-class feature selection procedure.
    
    % Make train_data1 and train_data2 more commensurate.
    if size(train_data1,1)==1 && size(train_data2,1)~=1
        train_data1 = repmat(train_data1,2,1);
    elseif size(train_data1,1)~=1 && size(train_data2,1)==1
        train_data2 = repmat(train_data2,2,1);
    end

    % Perform Student test
    [~,p,~,~] = ttest2(train_data1, train_data2,  'Vartype','unequal');
   
    % Sort the features and find the most informative ones.
    [~,featureIdxSortbyP] = sort(p,2); 
    p_threshold = 0.1;
    p_number = 10;
    if p_number > length(featureIdxSortbyP)
        featureIdxSortbyP1 = featureIdxSortbyP;
    else
        featureIdxSortbyP1 = featureIdxSortbyP(1:p_number);
    end
    features_idx = sort(featureIdxSortbyP1(p(featureIdxSortbyP1)<=p_threshold));
    
    
