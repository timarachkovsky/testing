%Script that computes peak parameters from data taken from *.mat file. It's useful
%if PeaksFinder's rules were changed and it's need to compute peaks with new rules.
Root=fullfile(fileparts(mfilename('fullpath')),'..','..','..','..');
mat_path = fullfile(Root, 'Out','result');
if ~exist('FileData') load(fullfile(mat_path, 'FileData.mat'),'FileData'); end %Load default mat file.

FullCompute=false;
Packet_processing;
clear FullCompute
%{
for ci=1:numel(FileData)
    FullCompute=false;
    FileData(ci).File_info.Root=Root; %Rewrite root path for potability.
	save(fullfile(mat_path,'Recompute_buffer')); %Save workspace.
    FD = FileData(ci);
	save(fullfile(mat_path, 'FD.mat'),'FD','FullCompute'); %Save the current file data and not-compute flag.
    runProcessing
    clear all
    Root=fullfile(fileparts(mfilename('fullpath')),'..','..','..','..');
	load(fullfile(mat_path,'Recompute_buffer'));
	load(fullfile(mat_path,'data.mat'));  %Data from runProcessing.
	FileData(ci).myFinder = myPeaksFinder;
	FileData(ci).SparseRepresentation = SparseRepresentation; %Save data from runProcessing.
end
close all;
mat_name = fullfile(mat_path, 'FileData.mat');
save(mat_name,'FileData');
Save_files(mat_name);
mat_name = fullfile(mat_path,[ ' ' datestr(floor(now)) '_Recomputed.mat']);
save(mat_name,'FileData');
%}