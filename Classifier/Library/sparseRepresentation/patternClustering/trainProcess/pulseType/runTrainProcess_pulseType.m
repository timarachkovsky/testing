clc; clear all; close all;
startup;


% ---------------------- Configuration ------------------------------- %
% mode = 'create'; % load / create   BD of pattern to train SVM
mode = 'load'; % load / create   BD of pattern to train SVM
config.dataset.baseroot = fullfile(pwd,'In');

config.observations.list = {
%                             'sparseSignal';
%                             
%                             'length';
%                             'sparsePeaks';
%                             'sparseModes';
%                             'accuratePeaks';
%                             'accurateModes';
%                             
%                             'T2T0';
%                             'Ht2Hb';
%                             'Rt2Rb';
                            'Hmax2Hrms';
                            'Hmax2Srms';
%                             'R2Rs';
%                             'R';
                            'energyVector';
                            'shortEnergyVector';
                            'symmetryVector';
                            
%                             'BFModesEnergy';
%                             'BFModesIntensity';
                            'BFTypeEnergy';
                            'BFTypeIntensity';
%                             'BFDurationEnergy';
%                             'BFDurationIntensity';
                            };

config.observations.combining = 'median';   % median/ all combinations;  
config.classification.findbest = 1;         % find best parameters C and gamma
config.classification.autoweight = 1;       % auweight classes for balance
config.classification.autoscale = 1;        % autoscale train data
config.classification.fold_number = 10;     % for cross-validation
config.classification.ratemodel = 1; 
                        
                        
%% Load or Create data base of the extracted patterns

switch(mode)
    case 'load'
        load('bd.mat');
%         load('bd_new.mat');
    case 'create'
        bd = tr_create_BD(config);
        save('bd_new.mat','bd','-v7.3');
    otherwise
end

patternType = { 
                'complex';
                'composite';
                'elementary';
                };
            
pls_svm_classifier = cell(size(patternType));
for pi = 1:numel(patternType)
   
    bd_temp = bd{cellfun(@(x) isequal(x.class_type,patternType{pi}),bd)};
    [bd_train, bd_test] = tr_fill_in_BD(bd_temp, config);

    classifier = tr_train(bd_train,config);
    classifier.type = patternType{pi};
    classifier.observations = config.observations.list;

    [result_temp] = tr_classify(bd_test, classifier);
    pls_svm_classifier{pi} = classifier;
end

pls_svm_classifier = cell2mat(pls_svm_classifier);
