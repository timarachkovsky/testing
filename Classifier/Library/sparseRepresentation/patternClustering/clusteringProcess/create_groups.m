function [ base ] = create_groups( base, config )
    
    base_origin = base;
    switch(config.grouping.type)
        case 'group'
            % Group clusters with similar type by thier length and other indirect
            % indications
            [base] = length_grouping(base, config);

            % Group clusters by thierindirect indications (even unsimilar types)
            [base] = type_grouping(base, config);
        
        case 'groupSet'
            % Group clusters by thierindirect indications (even unsimilar types)
            [base] = type_grouping(base, config);
    end
    
    
% ---------------------- Subfunction --------------------------------- %    
    
% Find clusters with close length value and group them by the waveform and
% BF modes 
function [base_obs] = length_grouping(base, config)
    
    base_obs = [];
    length_obs = arrayfun(@(x) x.length, base);
    config.clustering.kmeans.bestClustersNumber.threshold = 0.90;

    % Find optimal number of clusters...
    [ clust_num ] = best_kmeans(length_obs, config);
    if isempty(clust_num)
        clust_num = 1;
        warning('There is only ONE feature for clustering!');
    end

    disp('K-mean clustering...by @length parameter');
    if config.parpoolEnable
        opts = statset('UseParallel',true,'MaxIter',100); % options
    else
        opts = statset('MaxIter',100); % options
    end
    [ model ] = kmeans(length_obs, clust_num,'EmptyAction','drop','Replicates',10,'Options',opts);
    disp('K-mean clustering...finished');

    base = arrayfun(@(x,y) setfield(x, 'length_group',y), base, model);
    length_type = unique(model);
    
    groups = cell(size(length_type));
    if config.parpoolEnable
        parfor gi = 1:numel(groups)
                disp('Groups compression ... by correlation');
            groups{gi} = crg_compressByCorr(base(model==length_type(gi)));
                disp('Groups compression ... by type');
            groups{gi} = crg_compressByType(groups{gi});
        end
    else
        for gi = 1:numel(groups)
                disp('Groups compression ... by correlation');
            groups{gi} = crg_compressByCorr(base(model==length_type(gi)));
                disp('Groups compression ... by type');
            groups{gi} = crg_compressByType(groups{gi});
        end
    end
    disp('Groups compression ... finished');
    
% base = cell2mat(cellfun(@(x) x,groups, 'UniformOutput',false));
base_obs = cell2mat(groups);

% Find clusters that are parts of other clusters and group them
function [base_gp] = type_grouping(base, config)

    base_gp = [];
    switch (config.grouping.type)
        case 'group'
            groupFieldName = 'group';
            threshold = 0.875;
        case 'groupSet'
            groupFieldName = 'group_set';
            threshold = 0.95;
        otherwise
            groupFieldName = 'group';
            threshold = 0.875;
    end
    
    
    if numel(base)>1
  
        signal4processing = ones(1, numel(base));
%         threshold = 0.875;
        
        tic
        % Build treu correlation matrix of the all clusters and find the similar 
        corrMatrix = cell(numel(base),1);
        if config.parpoolEnable
            parfor i = 1:numel(base)
                corrMatrix{i} = arrayfun(@(x) crg_subcorr(x.pattern, base(i).pattern), base);
            end
        else
            for i = 1:numel(base)
                corrMatrix{i} = arrayfun(@(x) crg_subcorr(x.pattern, base(i).pattern), base);
            end
        end
        corrMatrix = cell2mat(corrMatrix');
        corrMatrix = abs(corrMatrix - tril(corrMatrix));
        toc
        
        [value, idx] = max(corrMatrix(:));
        [cl1 cl2] = ind2sub(size(corrMatrix),idx);
        
        while ~isempty(cl1) && value>threshold
            if numel(base_gp)==0
                base_gp{1} = base([cl1,cl2]);
                corrMatrix(cl1,cl2) = 0;
            else     
                temp = zeros(size(base_gp));
                for i = 1:numel(base_gp)
                     temp(i) = any(arrayfun(@(x) ismember({x.name}', {base(cl2).name}'), base_gp{i})) ...
                         || any(arrayfun(@(x) ismember({x.name}', {base(cl1).name}'), base_gp{i}));
                end 
                if any(temp)
                    base_gp{find(temp,1,'first')}(end+1) = base(cl1);
                    base_gp{find(temp,1,'first')}(end+1) = base(cl2);
                    if nnz(temp)>1
                        data = base_gp(find(temp));
                        data = cell2mat(data');
%                         data = cell2mat(base_gp(find(temp))');
                        pos = find(temp,1,'first');
                        base_gp{pos} = data;
                        temp(pos) = 0;
                        base_gp(find(temp)) = [];
%                         temp(temp) = [];
                    end
                else
                    base_gp{end+1} = base([cl1,cl2]);
                end
                corrMatrix(cl1,cl2) = 0;
            end
            signal4processing(cl1) = 0;
            signal4processing(cl2) = 0;

            [value, idx] = max(corrMatrix(:));
            [cl1 cl2] = ind2sub(size(corrMatrix),idx);

        end

        % Add unmerged clusters to the merged ones
        if any(signal4processing)
            positions = find(signal4processing);
            if numel(base_gp)==0
                st_idx = 1;
            else
                st_idx = nnz(signal4processing)+1;
            end

            for i = 1:numel(positions)
                base_gp{st_idx+i-1} = base(positions(i));
            end
        end
        
        
        % Remove the identical clusters from the same group
        for i = 1:numel(base_gp)
           for j = 1:numel(base_gp{i})
                similarPatternPositions = find(ismember({base_gp{i}(:).name}',{base_gp{i}(j).name}'));
                if nnz(similarPatternPositions)>1
                    similarPatternPositions(1) = [];
                    base_gp{i}(similarPatternPositions) = [];
                end
               if numel(base_gp{i})<=j
                  break; 
               end
           end

           if numel(base_gp)<=i
              break; 
           end
        end

        % Mark the linked groups
        base_gp = base_gp(cellfun(@(x) ~isempty(x),base_gp));
        for i = 1:numel(base_gp)
            if strcmp(groupFieldName,'group')
                base_gp{i} = arrayfun(@(x) setfield(x,groupFieldName,{strcat(x.class_type,'_',num2str(i))}),base_gp{i}); 
            else
                base_gp{i} = arrayfun(@(x) setfield(x,groupFieldName,{strcat('groupSet_',num2str(i))}),base_gp{i}); 
            end
        end
        base_gp = cell2mat(base_gp');
        
    else
        base_gp = base;
        for i = 1:numel(base_gp)
            if strcmp(groupFieldName,'group')
                base_gp(i).(groupFieldName) = {strcat(base_gp(i).class_type,'_',num2str(i))};
            else
                base_gp(i).(groupFieldName) = {strcat('groupSet_',num2str(i))};
            end
        end
    end
    

% Find common pattern into the neibour clusters by corr coeffs and compress
% base structure     
function [base_gp] = crg_compressByCorr(base)
    
    % Set the threshold levels with respect of the pattern type and
    % prepare data for further processing
    base_gp = [];
    switch(base(1).class_type)
        case 'elementary'
            threshold = 0.75;
        case 'composite'
            threshold = 0.5;
        case 'complex'
            threshold = 0.4;
    end

    sizeVector = arrayfun(@(x,o) size(x.pattern,1),base);
    padSizeVector = max(sizeVector)-sizeVector;
    signalMatrix = cell2mat(arrayfun(@(x,p) padarray(x.pattern,[p,0],'post'), base, padSizeVector,'UniformOutput',false)');
    signal4processing = ones(1, numel(base));
    
    % Build treu correlation matrix of the all clusters and find the similar 
    corrMatrix = corr(signalMatrix);
    corrMatrix = abs(corrMatrix - tril(corrMatrix));
    
    [value, idx] = max(corrMatrix(:));
    [cl1 cl2] = ind2sub(size(corrMatrix),idx);
    
    while ~isempty(cl1) && value>threshold
        if numel(base_gp)==0
            base_gp{1} = base([cl1,cl2]);
            corrMatrix(cl1,cl2) = 0;
        else    
            temp = zeros(size(base_gp));
            for i = 1:numel(base_gp)
                 temp(i) = any(arrayfun(@(x) ismember({x.name}', {base(cl2).name}'), base_gp{i})) || any(arrayfun(@(x) ismember({x.name}', {base(cl1).name}'), base_gp{i}));
            end 
            
            if any(temp)
                base_gp{find(temp,1,'first')}(end+1) = base(cl1);
                base_gp{find(temp,1,'first')}(end+1) = base(cl2);
                if nnz(temp)>1
                    data = base_gp(find(temp));
                    data = cell2mat(data');
                    pos = find(temp,1,'first');
                    base_gp{pos} = data;
                    temp(pos) = 0;
                    base_gp(find(temp)) = [];
%                         temp(temp) = [];
                end
            else
                base_gp{end+1} = base([cl1,cl2]);
            end
            
            corrMatrix(cl1,cl2) = 0;
        end
        signal4processing(cl1) = 0;
        signal4processing(cl2) = 0;
        
        [value, idx] = max(corrMatrix(:));
        [cl1 cl2] = ind2sub(size(corrMatrix),idx);

    end
    
    % Add unmerged clusters to the merged ones
    if any(signal4processing)
        positions = find(signal4processing);
        if numel(base_gp)==0
            st_idx = 1;
        else
            st_idx = nnz(signal4processing)+1;
        end
        
        for i = 1:numel(positions)
            base_gp{st_idx+i-1} = base(positions(i));
        end
    end
    
    base_gp = cellfun(@(x) crg_mergeCluster(x), base_gp(cellfun(@(x) ~isempty(x),base_gp)));
    base_gp;
% --------------------------------------------------------------------- %
    
% Find common pattern into the neibour clusters by pulse type and other
% fetures and compress base structure
function [base_gp] = crg_compressByType(base,config)
        
    base_gp = [];
    
    pulseTypes = unique(arrayfun(@(x) x.pulse_type,base,'UniformOutput',false))';
    base_gp = cell(size(pulseTypes));
    
    
    for ti = 1:numel(pulseTypes)
       base_gp{ti} = crg_findSimilarAverageBF(base(arrayfun(@(x) isequal(x.pulse_type,pulseTypes{ti}),base)));
       base_gp{ti} = crg_findSimilarBF(base_gp{ti});
    end
    
    % Convert to structure ....
    base_gp = cell2mat(base_gp);
    
    % .... convert to structure

% Function description --write me, please :/    
function [base_gp] = crg_findSimilarAverageBF(base)

    base = base';
    if numel(base) > 1
                
        bestAverages = unique(cell2mat(arrayfun(@(x) x.best_average, base,'UniformOutput',false)'));
        averageMatrix = cell2mat(arrayfun(@(x) ismember(bestAverages, x.best_average),base,'UniformOutput',false));


        % Groups check-in ...
        base_gp = cell(size(averageMatrix,2),1);
        for i = 1:size(averageMatrix,2)
            base_gp{i} =  crg_groupValidation(base(averageMatrix(:,i)));
        end

        % If some clusters have been removed while @crg_groupValidation is 
        % being performed, they will be restored and pushed to the new separate
        % cluster

        clusters = {base.name}';    
        clusters_removed = arrayfun(@(x) x(:), base(find(~sum(cell2mat(cellfun(@(x) ismember(clusters,{x.name}'),base_gp,'UniformOutput',false)'),2))),'UniformOutput',false);
        if ~isempty(clusters_removed)
            base_gp = [base_gp;clusters_removed];
        end
        % ....


        % Compress the base_gp structure by merging of the similar patterns
        for i = 1:numel(base_gp)
           similarGroupPositions = find(cellfun(@(x) any(ismember({x.name},{base_gp{i}.name})), base_gp));
           if nnz(similarGroupPositions)>1
              temp = cell2mat(base_gp(similarGroupPositions)); 
              base_gp{similarGroupPositions(1)} = temp;
              similarGroupPositions(1) = [];
              base_gp(similarGroupPositions) = [];
           end
           
            if numel(base_gp)<i
                k = numel(base_gp);
            else 
                k = i;
            end 
           
%            base_gp = base_gp(find(cellfun(@(x) ~isempty(x), base_gp)));
           % Remove the similar patterns in the groups
           for j = 1:numel(base_gp{k})
                similarPatternPositions = find(ismember({base_gp{k}(:).name}',{base_gp{k}(j).name}'));
                if nnz(similarPatternPositions)>1
                    similarPatternPositions(1) = [];
                    base_gp{k}(similarPatternPositions) = [];
                end
               if numel(base_gp{k})<=j
                  break; 
               end
           end

           if numel(base_gp)<=i
              break; 
           end
        end

        % Merge information into the groups
        base_gp = cellfun(@(x) crg_mergeCluster(x), base_gp(cellfun(@(x) ~isempty(x),base_gp)), 'UniformOutput',false);
        base_gp = cell2mat(base_gp(cellfun(@(x) ~isempty(x), base_gp)));
    
    else
        base_gp = base;
    end
    
% Check if the within-group parameters are the same or not     
function [group_valid] = crg_groupValidation(group)
        
    validVector = zeros(size(group));
    if numel(group) > 1
        for gi = 1:numel(group)
             intensityValid = nnz(cellfun(@(x) any(x),arrayfun(@(x) ismember(x.best_intensity,group(gi).best_intensity),group,'UniformOutput',false)))>1;
             bfValid =     nnz(arrayfun(@(x) isequal(x.BFTypeEnergy,group(gi).BFTypeEnergy),group))>1 ...
                        && nnz(arrayfun(@(x) isequal(x.BFDurationEnergy,group(gi).BFDurationEnergy),group))>1;
             validVector(gi) = intensityValid || bfValid;
         end
         group_valid = group(find(validVector));
    else
        group_valid = group;
    end


% Compare two clusters by their indirect indications
function [valid_flag] = isSimilarByBF(base_1, base_2)
    
    BFTypeEnergy_valid = corrcoef(base_1.BFTypeEnergy, base_2.BFTypeEnergy);
    BFTypeEnergy_valid = max(sum(abs(BFTypeEnergy_valid - tril(BFTypeEnergy_valid)),1))> 0.9;
              
    BFDurationEnergy_valid = corrcoef(base_1.BFDurationEnergy, base_2.BFDurationEnergy);
    BFDurationEnergy_valid = max(sum(abs(BFDurationEnergy_valid - tril(BFDurationEnergy_valid)),1))> 0.9;
    
    Hmax2Srms_valid = abs(base_1.Hmax2Srms - base_2.Hmax2Srms)/mean([base_1.Hmax2Srms, base_2.Hmax2Srms]) < 0.15;
    T2T0_valid = abs(base_1.T2T0 - base_2.T2T0)/mean([base_1.T2T0, base_2.T2T0]) < 0.15;
    HmaxHSrms_valid = abs(base_1.Hmax2Hrms - base_2.Hmax2Hrms)/mean([base_1.Hmax2Hrms, base_2.Hmax2Hrms]) < 0.15;
    
    best_average_valid = any(ismember(base_1.best_average,base_2.best_average));
    best_intensity_valid = any(ismember(base_1.best_intensity,base_2.best_intensity));
    
valid_flag = nnz([  BFTypeEnergy_valid, BFDurationEnergy_valid, Hmax2Srms_valid, ...
                    T2T0_valid,HmaxHSrms_valid, best_average_valid, best_intensity_valid ])>2;


function [base_gp] = crg_findSimilarBF(base, config)
    
    if numel(base) >1
        
        base_gp = [];
        
        similarityMatrix = cell(size(base));
        signal4processing = ones(1, numel(base));
        for i = 1:numel(base)
            similarityMatrix{i} = arrayfun(@(x) isSimilarByBF(x,base(i)),base);
        end
        similarityMatrix = abs(cell2mat(similarityMatrix'));
        similarityMatrix = similarityMatrix - tril(similarityMatrix);

        [idx] = find(similarityMatrix(:)>0,1,'first');
        [cl1 cl2] = ind2sub(size(similarityMatrix),idx);

        while ~isempty(cl1)
            if numel(base_gp)==0
                base_gp{1} = base([cl1,cl2]);
                similarityMatrix(cl1,cl2) = 0;
            else     
                temp = zeros(size(base_gp));
                for i = 1:numel(base_gp)
                     temp(i) = any(arrayfun(@(x) ismember({x.name}', {base(cl2).name}'), base_gp{i})) ...
                         || any(arrayfun(@(x) ismember({x.name}', {base(cl1).name}'), base_gp{i}));
                end 
                
                if any(temp)
                    base_gp{find(temp,1,'first')}(end+1) = base(cl1);
                    base_gp{find(temp,1,'first')}(end+1) = base(cl2);
                    if nnz(temp)>1
                        data = base_gp(find(temp));
                        data = cell2mat(data');
%                         data = cell2mat(base_gp(find(temp))');
                        pos = find(temp,1,'first');
                        base_gp{pos} = data;
                        temp(pos) = 0;
                        base_gp(find(temp)) = [];
%                         temp(temp) = [];
                    end
                else
                    base_gp{end+1} = base([cl1,cl2]);
                end
                similarityMatrix(cl1,cl2) = 0;
            end
            signal4processing(cl1) = 0;
            signal4processing(cl2) = 0;

            [idx] = find(similarityMatrix(:)>0,1,'first');
            [cl1 cl2] = ind2sub(size(similarityMatrix),idx);

        end

        % Add unmerged clusters to the merged ones
        if any(signal4processing)
            positions = find(signal4processing);
            if numel(base_gp)==0
                st_idx = 1;
            else
                st_idx = nnz(signal4processing)+1;
            end

            for i = 1:numel(positions)
                base_gp{st_idx+i-1} = base(positions(i));
            end
        end

        base_gp = cellfun(@(x) crg_mergeCluster(x), base_gp(cellfun(@(x) ~isempty(x),base_gp)))';
    else
        base_gp = base;
    end
    % ... dummy
% -------------------------------------------------------------------- %

function [base_compact] = crg_mergeCluster(base)

    if numel(base)>1
        
        % Remove duplicates from the base struct
        names = unique(arrayfun(@(x) x.name, base, 'UniformOutput',false));
        temp = cell(size(names));
        for i = 1:numel(names)
           temp{i} = base(find(arrayfun(@(x) isequal(x.name,names{i}),base),1,'first')); 
        end
        base = cell2mat(temp);
        
        % Merge data of the certain fields
        observations4merge = {
                                'class_member_names';
                                'class_member_signal';
                                'class_member_stP';
                                'class_member_length';
                                'class_member_T2T0';
                             };
        
        base_compact = base(1); % use as primary cluster
        for oi = 1:numel(observations4merge)
            base_compact.(observations4merge{oi}) = vertcat(base.(observations4merge{oi}));
        end
        base_compact.class_volume = numel(base_compact.class_member_signal);
        
        % Recalculate best_intensivity and best_average for merged data
        volume = {base.class_volume}';
        
        average_threshold = 0.2;
        base_compact.best_average = find(sum(cell2mat(cellfun(@(x,y) x*y, {base.average}',volume, 'UniformOutput',false)),1)/sum(cell2mat(volume),1)>average_threshold);

        intensity_threshold = 0.40;
        base_compact.best_intensity = find(sum(cell2mat(cellfun(@(x,y) x*y, {base.intensity}',volume, 'UniformOutput',false)),1)/sum(cell2mat(volume),1)>intensity_threshold);
        
        pulseTypes = unique({base.pulse_type}');
        if numel(pulseTypes)>1
            val = zeros(numel(pulseTypes),1);
            for pi = 1:numel(pulseTypes)
                val(pi) = sum(cell2mat(arrayfun(@(x) x.class_member_energy*x.class_volume, base(find(arrayfun(@(x) ismember(x.pulse_type, pulseTypes(pi)),base))),'UniformOutput',false)));
            end
            [~,idx] = max(val);
            base_compact.pulse_type = pulseTypes{idx}; 
        end
    else
        base_compact = base;
    end


function [matrix_reshape] = crg_removeDiag(matrix)

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
    
% Estimate corr_coef for the signals with different lengths
function [corrCoef] = crg_subcorr(X,Y)
    
    % Swipe data arrays is the 1st one is shorter than the 2nd
    if size(X,1) <size(Y,1)
        Z = X;
        X = Y;
        Y = Z;
    end
    
    lengthX = length(X);
    lengthY = length(Y);
    lengthDelta = (lengthX-lengthY);
    
    % Create shifted correlation function and find it max corr_coefficient
    corrCoefVector = zeros(lengthDelta,1);
    step = 2*round(log2(lengthDelta));
    for i = 0:step:(lengthDelta)
        corrCoefVector(i+1) = xcorr(X(i+1:i+lengthY) - mean(X(i+1:i+lengthY)), Y - mean(Y),0,'coeff');
    end
    
    corrCoef = max(corrCoefVector);

    
    
    
    
    
