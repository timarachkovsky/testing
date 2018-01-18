function [ base ] = find_cluster_pattern( base, config )
% FIND_CLUSTER_PATTERN implements clusters validation and search for 
% pattern in each valid cluster

if config.clustering.majorityEnable
    % Find clusters that were present at an early stage of SWD
    [ base_major, base_secondary ] = clustersEvaluation( base, config );
    base_major = base_major(cellfun(@(x) numel(x)>1, base_major));
else
    base_major = base;
end

% ..................... First stage of clustering ......................
disp('Clustering. The 1st stage ...'); 
% Find pattern for cluster 
prn_base_major = cell(numel(base_major),1);
prn_base_noise = cell(numel(base_major),1);

if config.parpoolEnable
    parfor bi = 1:numel(base_major)
        [prn_base_major{bi}, prn_base_noise{bi}] = ptn_find(base_major{bi},config);
    end
else
    for bi = 1:numel(base_major)
        [prn_base_major{bi}, prn_base_noise{bi}] = ptn_find(base_major{bi},config);
    end
end
prn_base_major = cell2mat(prn_base_major(cellfun(@(x) ~isempty(x), prn_base_major)));
prn_base_noise = cell2mat(prn_base_noise(cellfun(@(x) ~isempty(x), prn_base_noise)));
disp('Clustering. The 1st stage ... finished');

% ............. The second stage of clustering .........................
disp('Clustering. The 1st stage');
if ~isempty(prn_base_noise)
    [ ~, base_2 ] = clustering(prn_base_noise, config);
    prn_base_major_2 = cell(numel(base_2),1);
    prn_base_noise_2 = cell(numel(base_2),1);
    
    if config.parpoolEnable
        parfor bi = 1:numel(base_2)
            [prn_base_major_2{bi}, prn_base_noise_2{bi}] = ptn_find(base_2{bi},config);
        end
    else
        for bi = 1:numel(base_2)
            [prn_base_major_2{bi}, prn_base_noise_2{bi}] = ptn_find(base_2{bi},config);
        end
    end

    prn_base_major_2 = cell2mat(prn_base_major_2(cellfun(@(x) ~isempty(x), prn_base_major_2)));
    prn_base_noise_2 = cell2mat(prn_base_noise_2(cellfun(@(x) ~isempty(x), prn_base_noise_2)));
else
    prn_base_major_2 = struct([]);
end
disp('Clustering. The 2nd stage ... finished');

% ................. The 3d stage of clustering ........................
disp('Clustering. The 3rd stage ...');
if ~isempty(prn_base_noise)
    [ ~, base_3 ] = clustering(prn_base_noise_2, config);
    prn_base_major_3 = cell(numel(base_3),1);

    for bi = 1:numel(base_3)
        [prn_base_major_3{bi}] = ptn_find(base_3{bi},config);
    end
    prn_base_major_3 = cell2mat(prn_base_major_3(cellfun(@(x) ~isempty(x), prn_base_major_3)));
else
    prn_base_major_3 = struct([]);
end
disp('Clustering. The 3rd stage ... finished');

% .............. Merge results and prepate base ........................

base = vertcat(prn_base_major, prn_base_major_2, prn_base_major_3);
base = ptn_prepareBase(base, config);



% --------------------------- SubFunctions --------------------------- %

function [ptn_base, noise_base] = ptn_find(base, config)

    [base, pattern_position, cross_corr, noise_base] = ptn_findCommonPattern(base);  
    
    if isempty(base)
        ptn_base = [];
    else
        
        % Form pattern base struct
        ptn_base = base(pattern_position);
        
        
        ptn_base.class_member_names = arrayfun(@(x) x.name, base, 'UniformOutput', false);
        ptn_base.class_member_signal = arrayfun(@(x) x.sparseSignal(1:x.length,1), base, 'UniformOutput', false);
        ptn_base.class_member_stP = arrayfun(@(x) x.stP, base, 'UniformOutput', false);
        ptn_base.class_member_length = arrayfun(@(x) x.length, base, 'UniformOutput', false);
        ptn_base.class_member_T2T0 = arrayfun(@(x) x.T2T0, base, 'UniformOutput', false);
        
        ptn_base.class_volume = numel(base);
        ptn_base.class = ptn_base.cluster;
        ptn_base.class_member_energy = sum(ptn_base.sparseSignal.^2);
        ptn_base.class_cross_corr = cross_corr;
        ptn_base.class_major = any([base.major]);
        
        bestBFModes = ptn_findBestBFModes(base);

        fields2write = fields(bestBFModes);
        for fi = 1:numel(fields2write)
            ptn_base.(fields2write{fi}) = bestBFModes.(fields2write{fi});
        end

        % load('PATTERNs_SVM_basis1.mat');
        % [patternStruct] = ptn_coarsening(ptn_base, myBasis );
        
        observations = config.cluster.observations.list;
        class_obs = cell(numel(base),1);
        for bi = 1:numel(base)
            class_obs{bi} = cell2mat(cellfun(@(o) median(base(bi).(o),1), observations, 'UniformOutput',false)');
        end
        ptn_base.class_obs_1 = cell2mat(class_obs);
             
        ptn_base = restruct(ptn_base);
    end
    
    
function [base] = ptn_prepareBase(base, config)

    observations = config.pattern.observations.list;
    for bi = 1:numel(base)
        base(bi).class_obs = cell2mat(cellfun(@(o) median(base(bi).(o),1), observations, 'UniformOutput',false)');
    end


function [matrix_reshape] = ptn_removeDiag(matrix)

    % Remove diag elements with zeros
    matrix(logical(eye(size(matrix)))) = 0;
    
    % Lower matrix part
    matrix_tril = tril(matrix); 
    matrix_tril = matrix_tril(2:end,:);
    
    % Upper matrix part
    matrix_triu = triu(matrix); 
    matrix_triu = matrix_triu(1:end-1,:);
    
    % Merge the matrices
    matrix_reshape = matrix_tril + matrix_triu;

function [result] = ptn_findBestBFModes(base, config)
    
    % BFModesEnergy Column - energy vector of components; rows - observations
    BFModesEnergy = cell2mat(cellfun(@(x) normVect(x), arrayfun(@(x) x(:).BFModesEnergy, base, 'UniformOutput', false), 'UniformOutput', false))';
    BFModesEnergy(isnan(BFModesEnergy)) = 0;
    BFModesEnergy_average = (sum(BFModesEnergy,2)/size(BFModesEnergy,2))';
    
    BFModesEnergy_intencity = cellfun(@(x) nnz(x)/numel(x), cellfun(@(y) logical(y),...
                            mat2cell(BFModesEnergy,ones(size(BFModesEnergy,1),1),size(BFModesEnergy,2)), 'UniformOutput', false))';
    threshold_intensity = 0.45;
    result.best_intensity = find(BFModesEnergy_intencity>threshold_intensity);
    
    threshold_energy = 0.2;
    result.best_average = find(BFModesEnergy_average>threshold_energy);
    
    result.average = BFModesEnergy_average;
    result.intensity = BFModesEnergy_intencity;


function [base_new, pattern_position, cluster_corCoeff, base_noise] = ptn_findCommonPattern(base)   
        
    base_noise = [];
    % Basw filtering over the length of the origin signal 
    sizeVector = arrayfun(@(x,o) size(x.sparseSignal,1),base);

    meanSize = mean(sizeVector);
    threshH = 1.5; threshL = 0.5;
    validMask = sizeVector/meanSize > threshL & sizeVector/meanSize < threshH;
    homogeneity = nnz(validMask)/numel(validMask);
    
    if homogeneity >= 0.5
    
        base_new = base(validMask);
        base_noise = base(~validMask);
        padSizeVector = max(sizeVector(validMask,1))-sizeVector(validMask,1);
        
        if numel(base_new)>1
            % Find the most common pattern
            signalMatrix = cell2mat(arrayfun(@(x,p) padarray(x.sparseSignal,[p,0],'post'), base_new, padSizeVector,'UniformOutput',false)');
            corrMatrix = ptn_removeDiag(corr(signalMatrix));

            distortionVector = sqrt(abs(1-var(corrMatrix,1)));
            rmsVector = rms(corrMatrix,1);
            [~, pattern_position] = max(bsxfun(@times,distortionVector/max(distortionVector),rmsVector/max(rmsVector)));
            cluster_corCoeff = rms(corrMatrix(:,pattern_position));
        else
            cluster_corCoeff = 1;
            pattern_position = 1;
        end
    else
        base_new = [];
        pattern_position = [];
        cluster_corCoeff = [];
        base_noise = base;
    end
     
%  ... Currently <UNUSED> ... 
function [patternStruct] = ptn_coarsening(ptn_base, basis )
% DUMMY ... currently unused
% Function to coarse the pattern
    pattern_origin = ptn_base.sparseSignal;
    significantBF_position = ptn_base.best_average;
    
    modes_rough = ptn_base.sparseModes(:,significantBF_position);
    pattern_rough = sum(modes_rough,2);
    
    peaks_accurate = ptn_base.accuratePeaks;
    modes_accurate = ptn_base.accurateModes(:,significantBF_position);
    pattern_accurate = sum(modes_accurate,2);
   
    
function [base] = restruct(base)

base.pattern = base.sparseSignal(1:base.length,1);
field2remove = {
                'sparseSignal';
                'sparsePeaks';
                'sparseModes';
                'accuratePeaks';
                'accurateModes';
                'rmsPart';
                'major';                     
                };
            
base = rmfield(base,field2remove);
        
