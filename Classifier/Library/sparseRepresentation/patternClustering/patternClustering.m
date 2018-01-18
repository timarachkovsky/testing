function [result] = patternClustering(patternData, config)


%% Configuration of the SVM
config.dataset.type = 'mono'; % mono / multi
% config.dataset.baseroot = fullfile(pwd,'In');

config.id = str2double(config.id);
config.plotEnable = str2double(config.Attributes.plotEnable);
config.parpoolEnable = str2double(config.Attributes.parpoolEnable);
config.printPlotsEnable = str2double(config.Attributes.printPlotsEnable);
config.plotVisible = config.Attributes.plotVisible;
config.plotTitle = config.Attributes.plotTitle;
config.debugModeEnable = str2double(config.Attributes.debugModeEnable);

config.observations.list = {
                            'sparseSignal';
                            'stP';
                            'length';
                            'sparsePeaks';
                            'sparseModes';
                            'accuratePeaks';
                            'accurateModes';
                            'rmsPart';
                            'major';
                            'T2T0';
                            'Ht2Hb';
                            'Rt2Rb';
                            'Hmax2Hrms';
                            'Hmax2Srms';
                            'R2Rs';
                            'R';
                            'energyVector';
                            'shortEnergyVector';
                            'symmetryVector';
                            
                            'BFModesEnergy';
                            'BFModesIntensity';
                            'BFTypeEnergy';
                            'BFTypeIntensity';
                            'BFDurationEnergy';
                            'BFDurationIntensity';
                            
                            'resonantFrequency';
                            };
                        
config.clustering.observations.list = {
                        % Wave form observations
%                             'length';
                            'T2T0';                 
                            'Ht2Hb';
                            'Rt2Rb';
                            'Hmax2Hrms';
                            'Hmax2Srms';
                            'R2Rs';
                            'energyVector';
                            'shortEnergyVector';
                            'symmetryVector';
                            };
                        
config.pattern.observations.list = {
%                                     'average';
                                    'T2T0';
                                    'Ht2Hb';
                                    'Rt2Rb';
                                    'Hmax2Hrms';
                                    'Hmax2Srms';
                                    'R2Rs';
                                    
                                    'BFTypeEnergy';
%                                     'BFTypeIntensity';
                                    'BFDurationEnergy';
%                                     'BFDurationIntensity';
                                    'class_member_energy';
%                                     'class_type';
                                    };
                                
config.cluster.observations.list = {
                                    'T2T0';
                                    'Ht2Hb';
                                    'Rt2Rb';
                                    'Hmax2Hrms';
                                    'Hmax2Srms';
                                    'R2Rs';
                                    'energyVector';
                                    'shortEnergyVector';
                                    'symmetryVector';
                                    'BFTypeEnergy';
                                    };


config.observations.combining = 'median';   % median/ all combinations;  
config.classification.findbest = 1;         % find best parameters C and gamma
config.classification.autoweight = 1;       % auweight classes for balance
config.classification.autoscale = 1;        % autoscale train data
config.classification.fold_number = 10;     % for cross-validation
config.classification.ratemodel = 1; 
config.svmType = '0';      % 0)C-SVC, 1)nu-SVC, 2)one-class SVM, 3)epsilon-SVR, 4)nu-SVR 

config.clustering.type = 'k-means';     % svm / k-means

config.clustering.mixclasses = 'generate'; % generate / one / off
config.clustering.cluster.number = 10;

class_list = mat2cell(linspace(1,config.clustering.cluster.number,config.clustering.cluster.number)',ones(config.clustering.cluster.number,1),1);
config.clustering.cluster.list = cellfun(@(x) strcat('cl',num2str(x)), class_list,'UniformOutput',false);

config.clustering.kmeans.bestClustersNumber.replicates = 10;
config.clustering.kmeans.bestClustersNumber.threshold = 0.98;
config.clustering.kmeans.bestClustersNumber.maxNumber = 250;
config.clustering.kmeans.crossValidation = 'zeros+std'; % zeros / std / zeros+std

config.clustering.majorityEnable = 0;

%% Classification evaluation 
% Create obseravations base
[ base_origin ] = createBase(patternData, config);

% Build and train classifier / perform k-means clustering
[ ~, base ] = clustering(base_origin, config);
 
% Find common patter for each cluster
[ base ] = find_cluster_pattern(base, config);

% Find groups of cluster and implement processing over the groups
[ base, base_info ] = find_group_cluster(base, config);

% % Find the major patterns (for the major groupSet)
if config.debugModeEnable
    restore_signal(base, base_origin, config);
end

[~, base_patterns] = prepareFeatures(base, base_origin, base_info, config);
% save(fullfile(pwd,'Out','result.mat'),'base_patterns');

[result] = patternClassification(base_patterns, config);
% save(fullfile(pwd,'Out','result_clas.mat'),'result');

