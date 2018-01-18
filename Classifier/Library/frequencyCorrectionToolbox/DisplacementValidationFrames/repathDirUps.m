% repathDirUps.m function for getting out of DirUps ('\..\') in pathes

function path = repathDirUps (path)

    while true
        iDirUp = strfind(path, [filesep,'..']);
        if isempty(iDirUp)
            break
        end
        iFilesep = strfind(path, filesep);
        stop = iFilesep(find((iFilesep < iDirUp(1)), 1, 'last'));
        start = iFilesep(find((iFilesep > iDirUp(1)), 1, 'first'));
        path = fullfile(path(1:stop-1),path(start+1:length(path)));
    end
    
end % function repathDirUps