function fileListValid = ValidList(path,extent)    
	fileListValid   =[];
    dirData = dir(path);	% Get the data for the current directory
    dirIndex = [dirData.isdir];	% Find the index for directories
    fileList = {dirData(~dirIndex).name}';	% Get a list of the files
    
	if ~isempty(fileList)
		fileList = cellfun(@(x) fullfile(path,x),...	% Prepend path to files
					   fileList,'UniformOutput',false);

	   k=1;
		for i=1:1:numel(fileList)
			[pathstr,name,ext] = fileparts(fileList{i,1}) ;
			if strcmp(ext, extent)	% Cut file type
				fileListValid{k,1} = fileList{i,1}; 
				k = k+1;
			end
		end
	end
end