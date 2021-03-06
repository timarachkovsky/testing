% RESTORE_SIGNAL function description ....
function [ signal ] = restore_signal( base, base_origin, config )

	signal = rts_restore(base,base_origin, config);
	
% 	[groupSet] = rts_findMajorGroupSet(base, config);
	
    
% Restore signal on the basis of extracted and validated patterns
function [group_set_signals] = rts_restore(base,base_origin, config)

    % Restore Signal
    signalLength = base_origin(end).stP + max([base.length])*2;
  
    pattern_signal = zeros(signalLength,1);
    for bi = 1:numel(base_origin)
       len = length(base_origin(bi).sparseSignal);
       pattern_signal( base_origin(bi).stP : base_origin(bi).stP + len-1,1) =...
                        pattern_signal( base_origin(bi).stP : base_origin(bi).stP + len-1,1) + base_origin(bi).sparseSignal;
    end
    
    % GROUPs ...
    group_names = unique([base.group]);
    group_signals_temp = zeros(signalLength,numel(base));
	for bi = 1:numel(base)
		for si = 1:numel(base(bi).class_member_signal)     
             group_signals_temp( base(bi).class_member_stP{si} : base(bi).class_member_stP{si} + base(bi).class_member_length{si}-1,bi) =...
                        group_signals_temp( base(bi).class_member_stP{si} : base(bi).class_member_stP{si} + base(bi).class_member_length{si}-1,bi) + base(bi).class_member_signal{si};
        end
    end
    
    group_signals = zeros(signalLength,numel(group_names));
    for i = 1:numel(group_names)
        group_signals(:,i) = sum(group_signals_temp(:,arrayfun(@(x) strcmp(x.group,group_names{i}),base)),2);
    end
    
    % Test ...
    Fs = 96000;
    % .... test
    dt = 1/Fs;
    t = 0:dt:dt*(signalLength-1);
    
    % --------------------- Plot Results  ------------------------- %
    if config.plotEnable 
        figure('color','w','Visible',config.plotVisible); 
        plot(t,pattern_signal);
        for i = 1:numel(group_names)
             hold on, plot(t,group_signals(:,i));
        end
        xlabel('Time, s'); ylabel('Magnitude, m/s^2');
        legend([{'Original Signal'}; group_names']);
        title(['Pattern GROUPs_scalNo', num2str(config.id)]), grid on;
        if strcmpi(config.plotVisible, 'off')
            close
        end
    end
     % ..................... Plot Results ........................... %
     
    
    % GROUP_SETs ...
    group_set_names = unique([base.group_set]);
    group_set_signals = zeros(signalLength, numel(group_set_names));
    for i = 1:numel(group_set_names)
        group_set_signals(:,i) = sum(group_signals_temp(:,arrayfun(@(x) strcmp(x.group_set,group_set_names{i}), base)),2);
    end
    
  % ----------------------- Plot Results -------------------------- %   
    
    if config.plotEnable
        figure('color','w','Visible',config.plotVisible), plot(t, pattern_signal);
        for i = 1:numel(group_set_names)
             hold on, plot(t, group_set_signals(:,i));
        end
        xlabel('Time, s'); ylabel('Magnitude, m/s^2');
        legend([{'Original Signal'}; group_set_names']);
        title(['Pattern GROUP SETs_scalNo', num2str(config.id)]'), grid on;
        if strcmpi(config.plotVisible, 'off')
            close
        end
    end
    % ..................... Plot Results ........................... %
    

        
        
        
        
        
        
        