% Developer : ASLM
% Date : 01/11/16
% Version : v1.0

% DECIMATION function ...
function [ signalDecimated, FsDecimated ] = decimation( file, config )

    if nargin < 2
       config = []; 
    end
    config = fill_struct(config, 'decimationFactor', '2');
    config = fill_struct(config, 'plotEnable', '0');

    decimationFactor = str2double(config.decimationFactor);
    plotEnable = str2double(config.plotEnable);

    signalOrigin = file.signal;
    FsOrigin = file.Fs;

    for i = 1:size(signalOrigin,2)
        signalDecimated(:,i) =  decimate(signalOrigin(:,i), decimationFactor);
    end
    FsDecimated = FsOrigin/decimationFactor;

    if plotEnable 

        dtOrigin = 1/FsOrigin;
        tOrigin = 0:dtOrigin:dtOrigin*(length(signalOrigin)-1);

        dtDecimated = 1/FsDecimated;
        tDecimated = 0:dtDecimated:dtDecimated*(size(signalDecimated,1)-1);

        figure('Color','w'), hold on, grid on
        plot(tOrigin, signalOrigin(:,1));
        plot(tDecimated, signalDecimated(:,1));
        xlabel('Time, s'); ylabel('Signal, m/s^2');
        title('Signal Decimation');
        legend('Original','Decimated');
        hold off;
        
        if strcmpi(config.plotVisible, 'off')
            close
        end
    end

end

