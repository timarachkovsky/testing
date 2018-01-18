function [ result ] = tr_classify( base, classifier )


    class_obs = vertcat(base.class_obs);
%     class_val = arrayfun(@(x) repmat({x.class},size(x.class_obs,1),1), base, 'UniformOutput',false);
%     class_val = vertcat(class_val{:});
    
    disp('Classification ... ');
    result = classify(classifier.model, class_obs);




