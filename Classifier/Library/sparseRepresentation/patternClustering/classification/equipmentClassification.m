function [ base ] = equipmentClassification( base, config )


% Determine classifier type 
    resonantFrequency = base.resonantFrequency;
    if resonantFrequency < 0.15     % Middle-frequency range [0.25...3) Hz
        load('equip_SVM_classifier_MF.mat');
    else                            % High-frequency range [3...20] kHz
        load('equip_SVM_classifier_HF.mat');
    end
    
% Form features table
    observations = equip_svm_classifier.observations;
    base_obs = cell(numel(base),1);
    for bi = 1:1:numel(base)
        base_obs{bi} = cellfun(@(x) base(bi).(x),observations, 'UniformOutput', false)';
    end
    base_obs = cell2mat(cellfun(@(x) cell2mat(x),base_obs,'UniformOutput', false));
    
    
    if ~isempty(base_obs)
        
    % Determine equipment(element) type
        [result, prob_vector] = classify_libsvm(equip_svm_classifier.model, base_obs(:,equip_svm_classifier.features_idx), equip_svm_classifier.config);
 
        elementType = [equip_svm_classifier.class_name];
        if ischar(result{1})
            result = cellfun(@(x) str2num(x), result);
        end
        base = arrayfun(@(x,y) setfield(x,'element_type',elementType{y}),base,result);
        
    % Check is there any unclassified observation. 
    % Set 'Unknown' class for them
        threshold = 0.7;
        unknownPos = find(max(prob_vector,[],2)<=threshold);
        if ~isempty(unknownPos)
            base(unknownPos) = arrayfun(@(x) setfield(x,'element_type','unknown') ,base(unknownPos));
        end
        
    else
        warning('equip_class: The base is empty');
    end
    