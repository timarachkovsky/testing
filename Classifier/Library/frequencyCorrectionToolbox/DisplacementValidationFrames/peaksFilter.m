function Peaks = peaksFilter(file, config)
%Function returns parameters of found peaks according to config settings.
%It can select them by height and prominence (prelated to RMS level), min
%distance (all findpeak's params), validate peaks by pointed level of
%their minimum and maximum element and validate result by good peak number -
%if the one main peak is required but several were found.
	
	if nargin < 2
		config = [];
	end

	%=====Set default params.=====
	config = fill_struct(config, 'SortStr', 'none');
	config = fill_struct(config, 'nPeaks', num2str(intmax));
	%Height and prom levels are related to RMS level.
	config = fill_struct(config, 'minRMSPeakHeight', '0');
	config = fill_struct(config, 'minRMSPeakProminence', '0');
	%Hard thresholds.
	config = fill_struct(config, 'minPeakHeight', '0');
	config = fill_struct(config, 'minPeakProminence', '0');
	
	config = fill_struct(config, 'minPeakDistance', '0');
	%Throw out peaks that are less then pointed level of max peak. Include all def.
	config = fill_struct(config, 'minOverMaximumThreshold', '0');
	%Throw out peaks that are less then pointed prominence of max peak. Include all def.
	config = fill_struct(config, 'minOverMaxPromThreshold', '0');
	%Throw out peaks that are less then pointed level of min peak. Include all def.
	config = fill_struct(config, 'minOverMinimumThreshold', '0');
	%If number of resulted peaks more assigned threshold - result is not valid. Default it does not check.
	config = fill_struct(config, 'maxPeaksInResult', '0');
	%For result validation: set base validity to several found peaks to add them amplitude-depended validity.
	config = fill_struct(config, 'baseVal', '-1');  %Def - calculate it from peak number: divide 100% on them.
	%For result validation: amplitude-depended validity: coefficient of amplitudes to add to result validity.
	config = fill_struct(config, 'amplDep', '-1');  %Def - calculate it from relation to sum of peaks.
    
    %Process a raw data or a peak table.
	config = fill_struct(config, 'computePeaksTable', '1');
	
    if isstruct(file)
        %If file is a peak struct.
        Peaks = file;
        file = file.magnitudes;
    else
        Peaks = [];
    end
	RMS = rms(file);
	%=====Set findpeaks params.=====
	nPeaks = str2double(config.nPeaks);
	minRMSPeakHeight = str2double(config.minRMSPeakHeight)*RMS;
	minRMSPeakProminence = str2double(config.minRMSPeakProminence)*RMS;
	minPeakHeight = max([ minRMSPeakHeight str2double(config.minPeakHeight) ]);
	minPeakProminence = max([ minRMSPeakProminence str2double(config.minPeakProminence) ]);
	minPeakDistance = str2double(config.minPeakDistance);
	maxPeaksInResult = str2double(config.maxPeaksInResult);
	baseVal = str2double(config.baseVal);
	amplDep = str2double(config.amplDep);
    computePeaksTable = str2double(config.computePeaksTable);

    if computePeaksTable
        [Peaks.magnitudes, Peaks.indexes, Peaks.widths, Peaks.proms] = findpeaks(double(file),'SortStr',config.SortStr, 'NPeaks', ...
                nPeaks, 'MinPeakHeight', minPeakHeight, 'MinPeakProminence', minPeakProminence,'MinPeakDistance',minPeakDistance);
    else
        %If file is only a peak vector or a partial strust - select only acceptable peaks from computed priviously table.
        indexes = find(file > minPeakHeight); %gag: need to estimate by other params. Think about estimation like in findpeaks a ready peaks table. 
        if isfield(Peaks, 'proms')
            indexesProm = find(Peaks.proms > minPeakProminence); indexes = intersect(indexes, indexesProm);
        end
        %Put in all indexes and heights, then rest only chosen indexes in all existing fields.
        Peaks = fill_struct(Peaks, 'magnitudes', file);
        Peaks = fill_struct(Peaks, 'indexes', 1:numel(file));
        Peaks = trimFields(Peaks, indexes);
    end

	%=====Validate peaks by their level relate to their min and max element.=====
	minOverMaximumThreshold = str2double(config.minOverMaximumThreshold)*max([Peaks.magnitudes]);
	%Peaks = Peaks( ge([Peaks.magnitudes], minOverMaximumThreshold) );
    id = ge([Peaks.magnitudes], minOverMaximumThreshold);
	minOverMinimumThreshold = str2double(config.minOverMinimumThreshold)*min([Peaks.magnitudes]);
	%Peaks = Peaks( ge([Peaks.magnitudes], minOverMinimumThreshold) );
    %idx = ge([Peaks.magnitudes], minOverMinimumThreshold);
    %id = intersect( id,  find(idx) );
    id = bsxfun(@times, id,  ge([Peaks.magnitudes], minOverMinimumThreshold) );
    if isfield(Peaks, 'proms')
        minOverMaxPromThreshold = str2double(config.minOverMaxPromThreshold)*max([Peaks.proms]);
        id = bsxfun(@times, id,  ge([Peaks.proms], minOverMaxPromThreshold) );
    end
    Peaks = trimFields(Peaks, find(id));

	%=====Validate result by peaks number.=====
	if maxPeaksInResult
		if numel(Peaks.magnitudes) == 1
			Peaks.validities = 100;
		elseif (numel(Peaks.magnitudes) > 1) && (numel(Peaks.magnitudes) <= maxPeaksInResult)
			if baseVal == -1
				baseVal = 100/numel(Peaks.magnitudes);
                baseVal = baseVal/sum([Peaks.magnitudes]);
			end
			if amplDep == -1
				amplDep = 100/sum([Peaks.magnitudes]);
			end
			Peaks.validities = repmat(baseVal, size(Peaks.magnitudes)); %Set base validity to valid peaks.
			Peaks.validities = Peaks.validities + amplDep*Peaks.magnitudes;  %Up their vals depending on ampls.
		elseif ~numel(Peaks.magnitudes)
% 			warning('PeaksFilter: there is no any valid peaks!')
            Peaks.validities = 0;
		else
% 			warning('PeaksFilter: there is too many peaks - result is not valid!')
			Peaks.validities = zeros(size(Peaks.magnitudes));
		end
	end
end