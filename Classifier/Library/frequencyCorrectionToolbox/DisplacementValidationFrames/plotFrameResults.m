function plotFrameResults(myResult, nominFreq, str, fold, config)
%D:\Ratgor\GitRepo\ComputeFramework\Classifier\Library\frequencyCorrectionToolbox\DisplacementValidationFrames
    Root = fullfile(fileparts(mfilename('fullpath')),'..','..','..');
    Root = repathDirUps(Root);
    if ~exist('str', 'var') str = ''; end
    if ~exist('fold', 'var') fold = ''; end
	if isempty(fold) fold = 'interfResults'; end
    PicPath = fullfile(Root, 'Out', fold);
    if ~exist(PicPath, 'dir')
        mkdir(PicPath);
    end
	
	config = fill_struct(config, 'minRMSPeakHeight', '0');
	config = fill_struct(config, 'minOverMaximumThreshold', '0');
	RMSlev = str2double(config.minRMSPeakHeight);
	LeadLev = str2double(config.minOverMaximumThreshold);
	
    for i=1:numel(myResult)
        CPSam = myResult(i).original.centralPoint;
        SPSam = myResult(i).original.startFramePoint;
        EPSam = myResult(i).original.endPoint;

        figure('units','points','Position',[0 ,0 ,700,600],'Visible', 'off');
        plot(myResult(i).result.origF, myResult(i).result.origEnvelopeSpectrumFrame)
        hold on
		RMS = repmat( rms(myResult(i).result.origEnvelopeSpectrumFrame), size(myResult(i).result.origF) );
		plot(myResult(i).result.origF, RMS, ':')
		plot(myResult(i).result.origF, RMS*RMSlev)
		Lead = repmat( max(myResult(i).result.origEnvelopeSpectrumFrame), size(myResult(i).result.origF) );
		plot(myResult(i).result.origF, Lead, ':')
		plot(myResult(i).result.origF, Lead*LeadLev)
        legend('Spectrum', 'RMSlevel', 'RMSthreshold', 'LeaderLevel', 'LeaderThreshold')
        hold off
        PicName = sprintf('%10.5f_%s%d 1 %s.jpg', nominFreq, str, i, 'frameOrig');
        NameOutFile = fullfile(PicPath, PicName);
        print(NameOutFile,'-djpeg81', '-r150');
        close

        figure('units','points','Position',[0 ,0 ,700,600],'Visible', 'off');
        plot(myResult(i).result.f, myResult(i).result.spectrumFrame)
        hold on
        stem(myResult(i).result.f(CPSam), myResult(i).result.spectrumFrame(CPSam), 'og')
        stem(myResult(i).result.f([SPSam EPSam]), myResult(i).result.spectrumFrame([SPSam EPSam]), '*r')
		RMS = repmat( rms(myResult(i).result.spectrumFrame), size(myResult(i).result.f) );
		plot(myResult(i).result.f, RMS, ':')
		plot(myResult(i).result.f, RMS*RMSlev)
		Lead = repmat( max(myResult(i).result.spectrumFrame), size(myResult(i).result.f) );
		plot(myResult(i).result.f, Lead, ':')
		plot(myResult(i).result.f, Lead*LeadLev)
        legend('Spectrum', 'The central frame frequency', 'The border frequencies', 'RMSlevel', 'RMSthreshold', 'LeaderLevel', 'LeaderThreshold')
        hold off
        PicName = sprintf('%10.5f_%s%d 2 %s.jpg', nominFreq, str, i, 'frameInterpolated');
        NameOutFile = fullfile(PicPath, PicName);
        print(NameOutFile,'-djpeg81', '-r150');
        close

        figure('units','points','Position',[0 ,0 ,700,600],'Visible', 'off');
        plot(myResult(i).original.f, myResult(i).original.spectrumFrame)
        hold on
		RMS = repmat( rms(myResult(i).original.spectrumFrame), size(myResult(i).original.f) );
		plot(myResult(i).original.f, RMS, ':')
		plot(myResult(i).original.f, RMS*RMSlev)
		Lead = repmat( max(myResult(i).original.spectrumFrame), size(myResult(i).original.f) );
		plot(myResult(i).original.f, Lead, ':')
		plot(myResult(i).original.f, Lead*LeadLev)
        legend('Spectrum', 'RMSlevel', 'RMSthreshold', 'LeaderLevel', 'LeaderThreshold')
        hold off
        PicName = sprintf('%10.5f_%s%d 3 %s.jpg', nominFreq, str, i, 'frameSmoothed');
        NameOutFile = fullfile(Root, 'Out', fold, PicName);
        print(NameOutFile,'-djpeg81', '-r150');
        close

        figure('units','points','Position',[0 ,0 ,700,600],'Visible', 'off');
        plot(myResult(i).f, myResult(i).spectrumFrame)
        hold on
		RMS = repmat( rms(myResult(i).spectrumFrame), size(myResult(i).f) );
		plot(myResult(i).f, RMS, ':')
		plot(myResult(i).f, RMS*RMSlev)
		Lead = repmat( max(myResult(i).spectrumFrame), size(myResult(i).f) );
		plot(myResult(i).f, Lead, ':')
		plot(myResult(i).f, Lead*LeadLev)
        legend('Spectrum', 'RMSlevel', 'RMSthreshold', 'LeaderLevel', 'LeaderThreshold')
        hold off
        PicName = sprintf('%10.5f_%s%d 4 %s.jpg', nominFreq, str, i, 'frameSmoothedInterpolated');
        NameOutFile = fullfile(PicPath, PicName);
        print(NameOutFile,'-djpeg81', '-r150');
        close
    end
end