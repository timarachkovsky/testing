function [ base_obs ] = createBase(data, config )
% Description: create base_obs structure and fill it with observations
% values
% 
% %% Load dataset list
% dlist = dir(config.dataset.baseroot);
% dlist = {dlist.name}';
% dlist(strcmp(dlist,'.')) = [];
% dlist(strcmp(dlist,'..')) = [];
disp('Creating base ...');

%% Create observations table
observations = config.observations.list;
switch ( config.dataset.type )
    % Extract dataset from the only one file
    case 'mono' 
%         data = load(fullfile(config.dataset.baseroot,dlist{1}));
%         rootField = fields(data);
%         data = data.(rootField{1,1});
             
        base_obs = cell(numel(data),1);
        for i = 1:1:numel(data)
            base_info.name = num2str(i);
            base_info.class = 'common';
%             base_info.signal = data(i).sparseSignal;
%             base_info.major = data(i).major;
            for j = 1:1:numel(observations)
               base_info.(observations{j}) = data(i).(observations{j}); 
            end
            base_obs{i} = base_info;
        end
        base_obs = cell2mat(base_obs);
        
    % Extract datasets from the several files and merge them
    case 'multi'
        base = cell(numel(dlist),1);
        for li = 1:numel(dlist)
%             data = load(fullfile(config.dataset.baseroot,dlist{li}));
%             rootField = fields(data);
%             data = data.(rootField{1,1});
            
            base_obs = cell(numel(data),1);
            class = ['class_',num2str(li)];
            for di = 1:1:numel(data)
                base_info.name = num2str(di);
                base_info.class = class;
                for j = 1:1:numel(observations)
                   base_info.(observations{j}) = data(di).(observations{j}); 
                end
                base_obs{di} = base_info;
            end
            base{li} = base_obs;
        end
        base_obs = cell2mat(cellfun(@vertcat,cellfun(@cell2mat,base, 'UniformOutput',false),'UniformOutput',false));
    otherwise
end

%% Create clustering observations
observations = config.clustering.observations.list;
switch config.observations.combining
	case 'all combinations'
		for bi = 1:numel(base_obs)
			curObs = base_obs(bi);

			obs_perm = cellfun(@(o) 1:size(curObs.(o),1), observations, 'UniformOutput',false);
			obs_ind = cell(size(obs_perm));
			[obs_ind{:}] = ndgrid(obs_perm{:});
			obs_ind = cell2mat(cellfun(@(x) x(:), obs_ind, 'UniformOutput',false));
			obs_ind = mat2cell(obs_ind, ones(size(obs_ind,1),1), size(obs_ind,2));

			class_obs = cell(size(obs_ind));
			for ii = 1:numel(obs_ind)
				class_obs{ii} = cell2mat(cellfun(@(o,ri) curObs.(o)(ri,:), observations, num2cell(obs_ind{ii}), 'UniformOutput',false));
			end
			base_obs(bi).class_obs = cell2mat(class_obs);
		end
		
	case 'median'
		for bi = 1:numel(base_obs)
			base_obs(bi).class_obs = cell2mat(cellfun(@(o) median(base_obs(bi).(o),1), observations, 'UniformOutput',false)');
		end

	otherwise
		error('vbr:obs:comb','Uniknown observations combining method.');
end
