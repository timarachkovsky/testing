function [ result ] = patternClassification( base, config )

result = [];  
% switch( config.svmType)
%     case {'0','1','2'}
% %         load('elem_svm_classifier.mat'); 
%         load('elem_SVM_classifier_prob.mat'); 
%     case {'3','4'}
%         load('elem_SVR_classifier.mat'); 
%     otherwise
%         load('elem_svm_classifier.mat'); 
% end
resonantFrequency = base.resonantFrequency;
if resonantFrequency < 0.15
    load('elem_SVM_classifier_MF.mat'); 
else
    load('elem_SVM_classifier_HF.mat'); 
end

[base, info] = cl_elementType(base, elem_svm_classifier, config);
result.base = base;
result.info = info;

% -------------------------- Subfunctions ----------------------------- %
function [base, info] = cl_elementType(base, classifier, config)

    observations = classifier.observations;
    
    base_obs = cell(numel(base),1);
    for bi = 1:1:numel(base)
        base_obs{bi} = cellfun(@(x) base(bi).(x),observations, 'UniformOutput', false)';
    end
    
    base_obs = cell2mat(cellfun(@(x) cell2mat(x),base_obs,'UniformOutput', false));
    if ~isempty(base_obs)
%         result = cellfun(@(x) str2num(x), classify(classifier.model, base_obs));

%             [result, info ]= arrayfun(@classify_lib_svm,classifier.model, base_obs);
%             [result, info]= classify_lib_svm(classifier.model,base_obs);
            [result, prob_vector] = classify_libsvm(classifier.model, base_obs, classifier.config);
 
        elementType = [classifier.class_name];
        if ischar(result{1})
            result = cellfun(@(x) str2num(x), result);
        end
        base = arrayfun(@(x,y) setfield(x,'element_type',elementType{y}),base,result);
        
        threshold = 0.7;
        unknownPos = find(max(prob_vector,[],2)<=threshold);
        if ~isempty(unknownPos)
            base(unknownPos) = arrayfun(@(x) setfield(x,'element_type','unknown') ,base(unknownPos));
        end
        elementType{end+1} = 'unknown';
        
    % Calculate some statistics of the classification 
        elementTypeEnergy = zeros(size(elementType));
        elementTypeIntensity = zeros(size(elementType));
        for pi = 1:numel(elementType)
            temp = base(arrayfun(@(x) isequal(x.element_type, elementType{pi}), base));
            if ~isempty(temp)
                elementTypeEnergy(pi) = elementTypeEnergy(pi) + sum(arrayfun(@(y) sum(bsxfun(@times, y.signal,y.signal)), temp));
                elementTypeIntensity(pi) = elementTypeIntensity(pi) + numel(temp);
            end
        end
        info.element_type_energy = elementTypeEnergy'/sum(elementTypeEnergy);
        info.element_type_intensity = elementTypeIntensity'/sum(elementTypeIntensity);
        info.element_type = elementType;
        
        if config.plotEnable && config.debugModeEnable
            figure('color','w','Visible', config.plotVisible), bar(elementTypeEnergy);
            xlabel('type'); ylabel('Energy Contribution');
            title('Element Type');
            xticklabels(elementType); grid on;
            if config.printPlotsEnable
                print(fullfile(pwd,'Out',['patternElementTypes-TD-', num2str(config.id)]),'-djpeg91', '-r180');
            end
            if strcmpi(config.plotVisible, 'off')
                close
            end
        end
    end
 
%     function [cl_res, cl_info] = classify_lib_svm(obj, sample)
%         
%             sample = ( sample+repmat(obj.data_scale.shift,size(sample,1),1) ) .* repmat(obj.data_scale.factor,size(sample,1),1);
% 
% 			label_vector = zeros(size(sample, 1), 1); % just a stub for LIBSVMPREDICT
% % 			[cl_res_wrk, accuracy, decision_val] = libsvmpredict(label_vector, sample, obj.model,'-b 1');
% 			[cl_res_wrk, accuracy, decision_val] = libsvmpredict(label_vector, sample, obj.model);
%             
%             cl_info.cl_res_wrk = cl_res_wrk;
%             cl_info.accuracy = accuracy;
%             cl_info.decision_val = decision_val;
%             
% 			cl_res = obj.classes(cl_res_wrk);