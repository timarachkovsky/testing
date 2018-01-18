function [base_gp, base_info] = find_group_cluster(base, config, info)
    
    disp('Groups formation...');
    config.grouping.type = 'group';
    [base_gp, base_info] = gp_clusterGroups(base, config);
    disp('Groups formation...finished');
    
    disp('Group Sets formation...');
    config.grouping.type = 'groupSet';
    [base_gp] = gp_clusterGroupSets(base_gp, config);
    disp('Group Sets formation...finished');
    

% ---------------------- SubFunctions -------------------------------- %

% Divide patterns into 3 groups by their BF composition
function [base_obs, base_info] = gp_clusterGroups(base, config)

    cluster_type = arrayfun(@(x) gp_clusterType(x.BFModesIntensity), base, 'UniformOutput', false);
    for bi = 1:numel(base)
        base(bi).class_type = cluster_type{bi};
    end
    
    type4processing =  {
                        'elementary';
                        'composite';
                        'complex';
                        };
                    
    % Load configuration of the svm classifiers

    
    load('pls_svm_classifier.mat'); 
    classifier = cell(size(type4processing));
    for ti = 1:numel(type4processing)
        classifier{ti} = pls_svm_classifier(arrayfun(@(x) isequal(x.type, type4processing{ti}), pls_svm_classifier));
    end
    
    
    base_obs = cell(size(type4processing));
    base_info = cell(size(type4processing));
    
    if config.parpoolEnable
        parfor ti = 1: numel(type4processing)   
            % Get simple features of the clusters
            [base_obs{ti}, base_info{ti}] = gp_typeFeatures(base, type4processing{ti});

            % Detect cluster pattern type (l_pulse, r_pulse and etc)
            [base_obs{ti}, base_info{ti}]= gp_pulseType(base_obs{ti},base_info{ti}, classifier{ti});

            % Form groups from the set of clusters
            if ~isempty(base_obs{ti})
                [base_obs{ti}] = create_groups(base_obs{ti},config);
            end
        end 
    else
        for ti = 1: numel(type4processing)
    %     parfor ti = 1: numel(type4processing)   
            % Get simple features of the clusters
            [base_obs{ti}, base_info{ti}] = gp_typeFeatures(base, type4processing{ti});

            % Detect cluster pattern type (l_pulse, r_pulse and etc)
            [base_obs{ti}, base_info{ti}]= gp_pulseType(base_obs{ti},base_info{ti}, classifier{ti});

            % Form groups from the set of clusters
            if ~isempty(base_obs{ti})
                [base_obs{ti}] = create_groups(base_obs{ti},config);
            end
        end
    end
    base_obs = cell2mat(base_obs(cellfun(@(x) ~isempty(x),base_obs)));
    
% Detect        
function [type] = gp_clusterType(base_vector)
% Simply sets cluster tags with respect of the number of basis functions 
% in use and their number

%     bf_number = nnz(base_vector);
%     bf_types_number = numel(find(base_vector));


    bf_number = sum(base_vector);
    bf_types_number = nnz(base_vector);
    
    if bf_number == 1 && bf_types_number == 1
        type = 'elementary';
%         
%     elseif bf_number>1 && bf_number<4  && bf_types_number==1
%         type = 'simple';
        
    elseif     (bf_number>1 && bf_number<4 && bf_types_number>=1 && bf_types_number<4)...
            || (bf_number==1 && bf_types_number>1 && bf_types_number<4)
        type = 'composite';
    
%     elseif     (bf_types_number>=4 && bf_types_number>1) ...
%             || (bf_number>=4 && bf_types_number==2)...
%             || (bf_number>=4 && bf_types_number==3)
%             || (bf_number>=4 && bf_types_number > 1)
%         type = 'complex';
%         
%     else
%         type = 'unknown';
    elseif bf_number>=4 || bf_types_number>=4
        type = 'complex';
    else 
        type = 'unknown';
    end
    
function [base_obs, base_info] = gp_typeFeatures(base, cluster_type)

    base = base(arrayfun(@(x) isequal(x.class_type,cluster_type),base));
    [base_obs,base_info] = feval(strcat(cluster_type,'_features'),base);

% Calculate the basic metrics for the elementary pattern types
function [base, info] = elementary_features(base, config)

    % Noisy-to-Total Ratio
    corr_threshold = 0.75; %
%     noisyMask = arrayfun(@(x) isempty(x.best_intensity)|(x.class_cross_corr<corr_threshold)*x.class_volume,base);
    noisyMask = arrayfun(@(x) x.class_cross_corr<corr_threshold, base);
    noisy = sum(arrayfun(@(x) x.class_volume, base(noisyMask)));
    total = sum(arrayfun(@(x) x.class_volume, base));
    if total == 0
        info.NTR = 0;
    else
        info.NTR = noisy/total;
    end
    
    % elementary type parameters
    base = base(~noisyMask);
    info.type_intensity = sum(cell2mat(arrayfun(@(x) x.BFTypeIntensity*x.class_volume, base, 'UniformOutput',false)),1);
    info.type_intensity = info.type_intensity/max(info.type_intensity);
    
    info.duration_intensity = sum(cell2mat(arrayfun(@(x) x.BFDurationIntensity*x.class_volume, base, 'UniformOutput',false)),1);
    info.duration_intensity = info.duration_intensity/max(info.duration_intensity);
    
    info.type_energy = sum(cell2mat(arrayfun(@(x) x.BFTypeIntensity*x.class_volume*x.class_member_energy, base, 'UniformOutput',false)),1);
    info.type_energy = info.type_energy/max(info.type_energy);
    
    info.duration_energy = sum(cell2mat(arrayfun(@(x) x.BFDurationIntensity*x.class_volume*x.class_member_energy, base, 'UniformOutput',false)),1);
    info.duration_energy = info.duration_energy/max(info.duration_energy);  
function [base, info] = composite_features(base, config)

    % Noisy-to-Total Ratio
    corr_threshold = 0.35; %
%     noisyMask = arrayfun(@(x) isempty(x.best_intensity)|(x.class_cross_corr<corr_threshold)*x.class_volume,base);
    noisyMask = arrayfun(@(x) x.class_cross_corr<corr_threshold, base);
    noisy = sum(arrayfun(@(x) x.class_volume, base(noisyMask)));
    total = sum(arrayfun(@(x) x.class_volume, base));
    if total == 0
        info.NTR = 0;
    else
        info.NTR = noisy/total;
    end
    
    % composite type parameters
    base = base(~noisyMask);
function [base, info] = complex_features(base, config)

    % Noisy-to-Total Ratio
    corr_threshold = 0.25; %
%     noisyMask = arrayfun(@(x) isempty(x.best_intensity)|(x.class_cross_corr<corr_threshold)*x.class_volume,base);
    noisyMask = arrayfun(@(x) x.class_cross_corr<corr_threshold, base);
    noisy = sum(arrayfun(@(x) x.class_volume, base(noisyMask)));
    total = sum(arrayfun(@(x) x.class_volume, base));
    if total == 0
        info.NTR = 0;
    else
        info.NTR = noisy/total;
    end    
    
    % composite type parameters
    base = base(~noisyMask);

% DIMDECT decrease dimention of the observer data
% It is a DUMMY function 
function [y] = dimDecr(x)
        y = x(1:end-1);
        y(1) = y(1)+x(end);
         
function [base, info] = gp_pulseType(base, info, classifier)

    observations = classifier.observations;
    
% Test...
    fields2change = {
                        'BFTypeEnergy';
                        'BFTypeIntensity';
                    };
    base_temp = base;
    for i = 1:1:numel(fields2change)
        base_temp = arrayfun(@(x) setfield(x, fields2change{i},dimDecr(x.(fields2change{i}))),base_temp);
    end
    base_obs = cell(size(base_temp));
    for bi = 1:1:numel(base)
        base_obs{bi} = cellfun(@(x) base_temp(bi).(x),observations, 'UniformOutput', false)';
    end

% ... Test
    
%     base_obs = cell(size(base));
%     for bi = 1:1:numel(base)
%         base_obs{bi} = cellfun(@(x) base(bi).(x),observations, 'UniformOutput', false)';
%     end
    
    
    base_obs = cell2mat(cellfun(@(x) cell2mat(x),base_obs,'UniformOutput', false));
    if ~isempty(base_obs)
        result = cellfun(@(x) str2num(x), classify(classifier.model, base_obs));
        pulseType = {
                     'left';
                     'centrum';
                     'right';
                     'continuous';
                     'two-humped';
                    };
        base = arrayfun(@(x,y) setfield(x,'pulse_type',pulseType{y}),base,result);
        
        pulseTypeEnergy = zeros(size(pulseType));
        pulseTypeIntensity = zeros(size(pulseType));
        for pi = 1:numel(pulseType)
            temp = base(arrayfun(@(x) isequal(x.pulse_type, pulseType{pi}), base));
            if ~isempty(temp)
                pulseTypeEnergy(pi) = pulseTypeEnergy(pi) + sum(arrayfun(@(y) y.class_member_energy*y.class_volume, temp));
                pulseTypeIntensity(pi) = pulseTypeIntensity(pi) + sum(arrayfun(@(y) y.class_volume, temp));
            end
        end
        info.pulse_type_energy = pulseTypeEnergy'/sum(pulseTypeEnergy);
        info.pulse_type_intensity = pulseTypeIntensity'/sum(pulseTypeIntensity);
    end
    
% --------------------------------------------------------------------- %   
% Merge groups into the groupSet by the shifted cross-correlation function
% between the group representatives
function [base_st] = gp_clusterGroupSets(base, config)
    
    % Refresh cluster parameters
    [ base_st ] = arrayfun(@(x) gp_refreshCluster(x, config), base);
    
    % Create group sets 
    [base_st] = create_groups(base_st,config);
    

function [ base_new ] = gp_refreshCluster(base, config)
    
    base_new = base;
    patterns = base.class_member_signal;

    % Base filtering over the length of the original signal 
    sizeVector = cellfun(@(x,o) size(x,1),patterns);

    meanSize = mean(sizeVector);
    
    threshH = 1.2; threshL = 0.8;
    validMask = sizeVector/meanSize > threshL & sizeVector/meanSize < threshH;
    homogeneity = nnz(validMask)/numel(validMask);
    
    
    padSizeVector = mat2cell(max(sizeVector)-sizeVector, ones(size(sizeVector,1),1),1);

    % Find the most common pattern
    signalMatrix = cell2mat(cellfun(@(x,p) padarray(x,[p,0],'post'), patterns, padSizeVector,'UniformOutput',false)');
    corrMatrix = removeDiag(corr(signalMatrix));

    distortionVector = sqrt(abs(1-var(corrMatrix,1)));
    rmsVector = rms(corrMatrix,1);
    [~, pattern_position] = max(bsxfun(@times,distortionVector/max(distortionVector),rmsVector/max(rmsVector)));
    cluster_corCoeff = rms(corrMatrix(:,pattern_position));
    base_new.pattern = base_new.class_member_signal{pattern_position};
    base_new.length = base_new.class_member_length{pattern_position};

    % dummy ...
    
    % .... dummy 
   





