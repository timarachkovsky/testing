function [ base ] = tre_create_BD( config )


%% Load dataset list
dlist = dir(config.dataset.baseroot);
dlist = {dlist.name}';
dlist(strcmp(dlist,'.')) = [];
dlist(strcmp(dlist,'..')) = [];
disp('Creating base ...');

dlist = cellfun(@(x) fullfile(config.dataset.baseroot,x), dlist,'UniformOutput', false);

base = cell(size(dlist));
% parfor i = 1:numel(dlist)
for i = 1:numel(dlist)
        data = load(dlist{i}); 
        rootField = fields(data);
        base{i} = data.(rootField{1,1});
        [~,name,~] = fileparts(dlist{i});
        name = strtok(name,'_');
        name = strtok(name,'-');
        base{i} = arrayfun(@(x) setfield(x,'class_name', name), base{i});
end
% base = cell2mat(base(cellfun(@(x) ~isempty(x),base))')'; 
base = cell2mat(base(cellfun(@(x) ~isempty(x),base))); 
base = arrayfun(@(x) setfield(x, 'class', class2num(x.class_name)), base);


function [class_num] = class2num(class_name)

switch(class_name)
    
    case 'bearing'
        class_num = 1;
    case 'belting'
        class_num = 2;
    case 'gearing'
        class_num = 3;
    case 'generator'
        class_num = 4;
%     case 'shaft'
%         class_num = 5;
    otherwise
        error('cls:class_name','Incorrect class_name');
end

% switch(class_name)
%     
%     case 'bearing'
%         class_num = 1;
%     case 'bearing-res'
%         class_num = 2;
%     case 'belting'
%         class_num = 3;
%     case 'gearing'
%         class_num = 4;
%     case 'gearing-res'
%         class_num = 5;
%     case 'generator'
%         class_num = 6;
%     case 'generator-res'
%         class_num = 7;
% %     case 'unknown'
% %         class_num = 8;
%     otherwise
%         error('cls:class_name','Incorrect class_name');
% end

% switch(class_name)
%     
%     case 'shaft-bearing'
%         class_num = 1;
%     case 'bearing-res'
%         class_num = 2;
%     case 'gearing'
%         class_num = 3;
%     case 'gearing-res'
%         class_num = 4;
%     case 'belting-generator'
%         class_num = 5;
%     case 'belting-bearing'
%         class_num = 6;
%     case 'generator'
%         class_num = 6;    
%     case 'generator-res'
%         class_num = 7;    
%     otherwise
%         error('cls:class_name','Incorrect class_name');
% end


