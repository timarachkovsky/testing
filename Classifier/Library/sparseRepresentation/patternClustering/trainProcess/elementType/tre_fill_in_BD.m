function [ train_bd, test_bd ] = tre_fill_in_BD( bd, config, info )


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
		error('vbr:obs:comb','Uniknown observations combining method.');
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

% train_bd = cell2mat(bd_obs);

% test ...
bd_obs = cell2mat(bd_obs);
data = bd_obs(randperm(size(bd_obs,1)));
testPart = 0.1;

test_data = data(1:round(size(bd_obs,1)*testPart));
train_data = data(round(size(bd_obs,1)*testPart)+1:end);



% Sort TEST_DATA by classes values
classes = unique(arrayfun(@(x) x.class, test_data));
test_bd = cell(numel(classes),1);
for i = 1:numel(classes)
    test_bd{i} = test_data(arrayfun(@(x) isequal(x.class, classes(i)), test_data));
end
test_bd = cell2mat(test_bd);

% Sort TRAIN_DATA by classes values
classes = unique(arrayfun(@(x) x.class, train_data));
train_bd = cell(numel(classes),1);
for i = 1:numel(classes)
    train_bd{i} = train_data(arrayfun(@(x) isequal(x.class, classes(i)), train_data));
end
train_bd = cell2mat(train_bd);
% ... test