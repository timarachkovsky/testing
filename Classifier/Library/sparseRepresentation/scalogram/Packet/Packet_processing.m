%Packet signal processing
dbstop error
Root=fullfile(fileparts(mfilename('fullpath')),'..','..','..','..');
cd(Root);
%FileData - the common struct with info about audio file (File_info);
%myFinder - PeaksFinder class, that contains all confugurations, scalogram data
%and full peaks table; SparseRepresentation - result of sparse decomposition.
%*_buffer - file with saving workspace. FileData - default file with full
%computed data for all files. FD - data of the current file for processing. FileData with
%date - data for all files, computed in this day.
%clear FullCompute; %Full computing.
if ~exist('FullCompute','var') FullCompute=true; end  %Default - full computing.
% Save command window in 'log.txt'
diary(fullfile(pwd, 'Out', 'log.txt'));

path_audio=fullfile(pwd,'In');
arch_root=fullfile(path_audio,'Archive');
path_to_files=Get_pathes(arch_root);

%Clear In directory.
audioListValid = ValidList(path_audio,'.wav') ; %Audio files, that are rested form previous processing.
for i=1:1:numel(audioListValid)
        if exist(audioListValid{i,1})
            delete(audioListValid{i,1}); 
        end
end

WR=sprintf('<HTML>\n<BODY>\n');
nf=0; %Number of processed files.
datestr(now)
for i=1:numel(path_to_files)
    arch_path=fullfile(arch_root,path_to_files{i});
    archListValid = ValidList(arch_path,'.bz2') ;

    if (~isempty(archListValid))
        for j=1:numel(archListValid)
           nf=nf+1;
           command=['"C:\Program Files (x86)\WinRAR\WinRar.exe" x -ibck -or -ilog -inul "' archListValid{j} '" "' path_audio '\"']
           % command=['"C:\Program Files\WinRAR\WinRar.exe" x -ibck -or -ilog -inul "' archListValid{j} '" "' path_audio '\"']
           % Why we use WinRar, wich requires licensing 
           % and it's 32-bit version under 64-bit systems? 
           % By the way, under Win7
           % it requires "Russian for non-unicode language programs"
           % for extracting archives with cyrilic in pathes
            [status,cmdout] = system(command,'-echo');
            if status ~=0
               disp(archListValid{j})
               disp('status = ')
               disp(status)
            end
			%=====Fill in file info struct=====
            audioListValid = ValidList(path_audio,'.wav') ; %Extracted audio file.
            file_params=strrep(archListValid{j},arch_root,'');  % Files divided in subfolders. Path used like parameters.
            %Archive name and extracted file names, parameters of the current (j) file.
            File_info.arch_name=archListValid{j}; %j - number of the current archive file in archive list;
            File_info.audio_name=audioListValid{1,1}; %nf - number of the current audio file and according
            File_info.file_params=file_params; %record in File_info array.  {nf}
			%Add pathes to struct.
			[pathstr,name,ext] = fileparts(audioListValid{1,1}) ; %Name of picture is equal to audio file name.
			Rel_Path=fullfile('Out', 'result', 'pics',sprintf('%d %s', nf, name)); %In html-doc we use a relative addresses.
            File_info.Rel_Path=Rel_Path; %Relative path to a pictures - so we can compute graphics on any PC.
			File_info.Root=Root; %Base root for output.
			%Put current file info in common struct.
			FileData(nf).File_info = File_info;
            %Add filenames.
            nameCopy = name;
            WR=[WR sprintf('<big>File number %d number in folder %d</big><br>\n',nf,j)];
            name=['Archive: ' archListValid{j} '; Audio: ' audioListValid{1,1} sprintf('\n')];
            WR=[WR name];
            
			%=====Process file=====
            FD=FileData(nf);
            save(fullfile(pwd,'Out','result','FD'),'FD','FullCompute'); %Save the current file data and full-computation flag.
			save(fullfile(pwd,'Out','result','Packet_buffer')); %Save workspace.
            runProcessing
            clear all
			load(fullfile(pwd,'Out','result','Packet_buffer'));
			load(fullfile(pwd,'Out','result','data.mat'));
			FileData(nf).myFinder = myPeaksFinder;
			FileData(nf).SparseRepresentation = SparseRepresentation; %Save data from runProcessing.
            FileData(nf).Sparse_config = Sparse_config;
			
            %=====Graphics=====
            %Add peak params.
			result = FileData(nf).myFinder.getResult;
            param_peaks=result_to_string(result,1);
            WR=[WR sprintf('<br>\n%s<br>\n%s',file_params,param_peaks)];
            %Add graphics.
            Save_files(FileData(nf));
            SaveSparseRepresentation(FileData(nf));
            WR=[WR '<img src = "' ['..\pics\'  '.jpg'] sprintf('"><br>\n')];
            WR=[WR '<img src = "' ['..\pics\'  ' PeakInfo.jpg'] sprintf('"><br><br><br>\n')];
            
            %=====Clearing=====
            %Delete extracted file.
            command=['DEL /Q ' '"' audioListValid{1,1}  '"'];
            [status,cmdout] = system(command,'-echo');
            dirFileName = nameCopy; % change to current wav file name
            robocopyDestination = fullfile('D:\', 'Classifier Out Backups', dirFileName);
            robocopySource = fullfile(pwd, filesep, 'Out');
            robocopyConfig = '/Z';
            system(['robocopy "', robocopySource, '" "', robocopyDestination, '" "', robocopyConfig, '"'], '-echo');
        end
    end
    datestr(now)
end
WR=[WR sprintf('\n</BODY>\n</HTML>\n')];
FID = fopen([fullfile(pwd,'Out','result','FileData ') datestr(floor(now)) '.html'],'w');
fwrite(FID, WR, 'char'); 
fclose(FID);
save(fullfile(pwd,'Out','result','FileData'),'FileData');  %Save data to default mat file.
save(fullfile(pwd,'Out','result',['FileData ' datestr(floor(now))]),'FileData');
clear FullCompute;
delete(fullfile(pwd,'Out','result','Packet_buffer.mat'));

diary off;