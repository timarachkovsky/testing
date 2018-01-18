function Save_files(FileData)
%Function computes and saves graphics with scalograms and marked peaks. It
%may be called from the Packet_processing with 1 the current file, with all
%files after loading from *.mat file, or with string parameter with name *.mat file with data.
if nargin==0 load('FileData.mat'); end %Load default data file.
    if ischar(FileData) %If FileData is name of *.mat file with data.
        load(FileData,'FileData'); %Load File_name in var.
        Save_files(FileData)
    else
		FullScalogramData = arrayfun(@(x)(x.getFullScalogramData), [FileData.myFinder]);
		
        for i=1:numel(FileData)
            FileData(i).myFinder.plotPeaksFound(FileData(i).myFinder);
            %{
			parameters = FileData(i).myFinder.getConfig;
            if strcmp(parameters.Attributes.peakValidationMethod, 'Coarse')
                FileData(i).myFinder.plotCoarsePeaksFound(FileData(i).myFinder);
            else
				 FileData(i).myFinder.plotPeaksFound(FileData(i).myFinder);
            end
			%}
			File_info=FileData(i).File_info;
            Full_path=fullfile(File_info(i).Root, File_info.Rel_Path);
            mkdir(Full_path);
            saveas(gcf,[Full_path  '.jpg'],'jpg');
            close all;

            findpeaks(FullScalogramData(i).coefficients,'Annotate','extents');
            saveas(gcf,[Full_path  ' PeakInfo.jpg'],'jpg');
            close all
        end
    end
end