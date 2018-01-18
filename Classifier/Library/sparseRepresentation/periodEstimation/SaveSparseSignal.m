function SaveSparseSignal(SparseRepresentation, file)
%Plot and save graphics with original signal and it's sparse component (according to scalogramm point).
%Default plot and save (optional) to Out/pic swith name according the scalogramm
%point (sparse component) number, in other case - file.name.

    params = file.config;
    if params.plotEnable == '1'
        Visible = 'on';
    else
        Visible = 'off';
    end
    PicName = fullfile(pwd, 'Out', 'scalogram-point-'); %, 'pics'
    if isfield(file,'name')
        PicName = file.name;
    end
    signal = file.signal;
    
    for i = 1:numel(SparseRepresentation) %Draw and save each sparse component.
        sparseSignal = SparseRepresentation(i).sparseSignal; %Get the sparse component.
        dt = 1/file.Fs;
        max_t = length(sparseSignal)*dt; %Maximum time = (number of samples) * (sample cost).
        t = dt:dt:max_t;
        t = t';
        mp = str2double(params.plotPeriodsNumber);
        if isempty(SparseRepresentation(i).data)
            SampleNumber = 700*mp; %Number of samples for output if there are no valid period (magic number).
            if ~params.PlotNotValidSparseComponents
                continue;
            end
        else
			%If there are a few periodicies in the sparse component, we use the bigger.
			period = max([SparseRepresentation(i).data.period]);
            SampleNumber = ceil(period/dt); %Samples per one period = period/(sample cost).
            SampleNumber = SampleNumber*mp; %Samples per specified number periods.
        end
        if SampleNumber>length(t)
            SampleNumber = length(t); %Draw full signals.
        end

        figure('units','points','Position',[0 ,0 ,800,600],'Visible', Visible);
        hold on
        plot(t(1:SampleNumber),signal(1:SampleNumber))
        plot(t(1:SampleNumber),sparseSignal(1:SampleNumber))
        xlabel('Time, s'); ylabel('Amplitude, m/s^2');
        title('Sparse wavelet decomposition');
        legend('Signal','Sparse Component');
        allignX = 0.05;
        allignY = 0.15;
        V = axis;
        x = V(2)*(allignX);
        y = V(4)*(1-allignY);
        str = SparseRepresentationToText (SparseRepresentation(i));
        text(x,y,str)

        if params.printPlotsEnable == '1'
            NameOutFile = sprintf('%s%d.jpg',PicName,i);
            print(NameOutFile,'-djpeg91', '-r180');
        end
    end
    
end