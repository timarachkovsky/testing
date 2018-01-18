function [ train_bd, test_bd ] = tr_fill_in_BD( bd, config, info )


observations = config.observations.list;
switch config.observations.combining
	case 'all combinations'
		for bi = 1:numel(bd)
			curObs = bd(bi);

			obs_perm = cellfun(@(o) 1:size(curObs.(o),1), observations, 'UniformOutput',false);
			obs_ind = cell(size(obs_perm));
			[obs_ind{:}] = ndgrid(obs_perm{:});
			obs_ind = cell2mat(cellfun(@(x) x(:), obs_ind, 'UniformOutput',false));
			obs_ind = mat2cell(obs_ind, ones(size(obs_ind,1),1), size(obs_ind,2));

			class_obs = cell(size(obs_ind));
			for ii = 1:numel(obs_ind)
				class_obs{ii} = cell2mat(cellfun(@(o,ri) curObs.(o)(ri,:), observations, num2cell(obs_ind{ii}), 'UniformOutput',false));
			end
			bd(bi).class_obs = cell2mat(class_obs);
		end
		
	case 'median'
		for bi = 1:numel(bd)
			bd(bi).class_obs = cell2mat(cellfun(@(o) median(bd(bi).(o),1), observations, 'UniformOutput',false)');
		end

	otherwise
		error('vbr:obs:comb','Unknown observations combining method.');
end

% Sort struct by classes values
classes = unique(arrayfun(@(x) x.class, bd));
% classes = classes(classes ~=0);
bd_obs = cell(numel(classes),1);

for i = 1:numel(classes)
    bd_obs{i} = bd(arrayfun(@(x) isequal(x.class, classes(i)), bd));
end


test_pos = find(classes==0, 1, 'first');
if isempty(test_pos)
    test_bd = [];
else
    test_bd = bd_obs{test_pos};
    bd_obs(test_pos) = [];
end

train_bd = cell2mat(bd_obs);

