function SaveSparseRepresentation(FileData)
%Draw and save sparse data from file data.
if nargin==0 load('FileData.mat'); end %Load default data file.
    if ischar(FileData) %If FileData is name of *.mat file with data.
        load(FileData,'FileData'); %Load File_name in var.
        SaveSparseRepresentation(FileData)
    else
        for j=1:numel(FileData) %Files counter.
            [file.signal, file.Fs] = audioread(FileData(j).File_info.audio_name);
            Full_path=fullfile(FileData(j).File_info.Root, FileData(j).File_info.Rel_Path);
            PicName = ' SparseInfo Component';
            PicName = [Full_path  PicName];
            file.config = FileData(j).Sparse_config.Attributes;
            file.config.plotEnable = '1';
            file.config.printPlotsEnable = '0';
            SparseRepresentation = FileData(j).SparseRepresentation;
            for i=1:numel(SparseRepresentation) %Sparse component counter in jth file.
                SaveSparseSignal(SparseRepresentation, file)
                NameOutFile = sprintf('%s%d.jpg',PicName,i);
                saveas(gcf,NameOutFile,'jpg');
                % Close figure with visibility off
                if strcmpi(Visible, 'off')
                    close
                end 
                close all % not desirable
            end
        end
    end
end