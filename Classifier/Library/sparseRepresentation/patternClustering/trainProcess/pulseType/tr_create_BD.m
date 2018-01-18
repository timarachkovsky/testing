function [ base_obs ] = tr_create_BD( config )

%% Load dataset list
dlist = dir(config.dataset.baseroot);
dlist = {dlist.name}';
dlist(strcmp(dlist,'.')) = [];
dlist(strcmp(dlist,'..')) = [];
disp('Creating base ...');

dlist = cellfun(@(x) fullfile(config.dataset.baseroot,x), dlist,'UniformOutput', false);

base = cell(size(dlist));
parfor i = 1:numel(dlist)
        data = load(dlist{i}); 
        rootField = fields(data);
        base{i} = data.(rootField{1,1});
end
base = cell2mat(base(cellfun(@(x) ~isempty(x),base))')';
[base] = tr_add_tags(base, config);
base = arrayfun(@(x) setfield(x,'class',0), base);

type4processing =   {
                        'elementary';
                        'composite';
                        'complex';
                    };
         
base_obs = cell(size(type4processing));
for ti = 1: numel(type4processing)
    base_obs{ti} = base(arrayfun(@(x) isequal(x.class_type,type4processing{ti}),base));
end



function [base] = tr_add_tags(base, config)

    cluster_type = arrayfun(@(x) tr_pattern_type(x.BFModesIntensity), base, 'UniformOutput', false);
    for bi = 1:numel(base)
        base(bi).class_type = cluster_type{bi};
    end
    
    
%     base = base(arrayfun(@(x) isequal(x.class_type,cluster_type),base));
    
    
function [type] = tr_pattern_type(base_vector)
% Simply sets cluster tags with respect of the number of basis functions 
% in use and their number


    bf_number = sum(base_vector);
    bf_types_number = nnz(base_vector);
    
    if bf_number == 1 && bf_types_number == 1
        type = 'elementary';
%         
%     elseif bf_number>1 && bf_number<4  && bf_types_number==1
%         type = 'simple';
        
    elseif     (bf_number>1 && bf_number<4 && bf_types_number>=1 && bf_types_number<4)...
%             || (bf_number>=4 && bf_types_number==1)
        type = 'composite';
    
    elseif     (bf_types_number>=4 && bf_types_number>1) ...
            || (bf_number>=4 && bf_types_number==2)...
            || (bf_number>=4 && bf_types_number==3)
        type = 'complex';
        
    else
        type = 'unknown';
    end