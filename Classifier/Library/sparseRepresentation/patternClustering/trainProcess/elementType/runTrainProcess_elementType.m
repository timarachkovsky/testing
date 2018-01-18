clc; clear all; close all;
startup;


% --------------------- Configuration ------------------------------- %
mode = 'create'; % load / create   BD of pattern to train SVM
config.dataset.baseroot = fullfile(pwd,'In');

config.observations.list = {
%                                 'structure';
                                'structure1'
%                                 'structure_full'
                                'waveform';
                                'T2T0';
                                'Hmax2Hrms';
                                'Hmax2Srms';
                                'kurtosis';
%                                 'pattern_types';
%                                 'resonantFrequency';
                            };

config.observations.combining = 'median';   % median/ all combinations;  
config.classification.findbest = 1;         % find best parameters C and gamma
config.classification.autoweight = 1;       % auweight classes for balance
config.classification.autoscale = 1;        % autoscale train data
config.classification.fold_number = 10;     % for cross-validation
config.classification.ratemodel = 1; 
config.classification.kernelType = '0';     %       0 -- linear: u'*v
                                            %       1 -- polynomial: (gamma*u'*v + coef0)^degree
                                            %       2 -- radial basis function: exp(-gamma*|u-v|^2)
                                            %       3 -- sigmoid: tanh(gamma*u'*v + coef0)
                                            %       4 -- precomputed kernel (kernel values in training_set_file)
                                            
config.classification.svmType = '0';        %       0 -- C-SVC
                                            %       1 -- nu-SVC
                                            %       2 -- one-class SVM
                                            %       3 -- epsilon-SVR
                                            %       4 -- nu-SVR
                                            
config.classification.probabilityEnable = '1';  %   0 -- disable
                                                %   1 -- enable
% --------------------------- Computation ---------------------------- %
                        
switch(mode)
    case 'load'
        load('bd_elementType.mat');
    case 'create'
        bd = tre_create_BD(config);
        save('bd_pattern.mat','bd','-v7.3');
    otherwise
end

% Fill BD struct with patterns parameters and add tags for each class
[bd_train, bd_test] = tre_fill_in_BD(bd, config);

% Train SVM classifier and build rated model
[elem_svm_classifier] = tr_train(bd_train,config);
elem_svm_classifier.observations = config.observations.list;
elem_svm_classifier.class_name = unique({bd_train.class_name})';
elem_svm_classifier.config.classification = config.classification;

bd_train = arrayfun(@(x,y) setfield(x, 'value', y), bd_train, elem_svm_classifier.ratemodel.class_val);


% Test Classification of the 10% of dataset
observations = elem_svm_classifier.observations;
base_obs = cell(numel(bd_test),1);
for bi = 1:1:numel(bd_test)
    base_obs{bi} = cellfun(@(x) bd_test(bi).(x),observations, 'UniformOutput', false)';
end
base_obs = cell2mat(cellfun(@(x) cell2mat(x),base_obs,'UniformOutput', false));
    
[result, prob_vec] = classify_libsvm(elem_svm_classifier.model, base_obs, config);

threshold = 0.5;
accuracy = nnz(max(prob_vec, [], 2) > threshold)/size(prob_vec,1);



