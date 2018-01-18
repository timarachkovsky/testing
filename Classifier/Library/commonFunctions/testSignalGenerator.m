function [ signal ] = testSignalGenerator( config )
    if nargin == 0 
       error('Not enough input arguments!');
    end
    
    % CH1
    parameters = config.CH1.Attributes;
    parameters.lengthSeconds = config.Attributes.lengthSeconds;
    parameters.Fs = config.Fs;
    switch (parameters.signalType)
        case 'SIN'
            signal = sin_signal(parameters);
        case 'POLYH'
            signal = pol_signal(parameters);
        case 'COS'
            signal = cos_signal(parameters);
        case 'TRIPULSE'
            signal = tri_signal(parameters);
        case 'GAUSPULSE'
            signal = gaus_signal(parameters);
        case 'TRIPULSE+COS'
            signal = tricos_signal(parameters);
        case 'GAUSPULSE+COS'
            signal = gauscos_signal(parameters);
        otherwise
            signal = sin_signal(parameters);
    end
    
    % CH2
    if strcmp(config.Attributes.mode, 'CH1+CH2')
        
        parameters = config.CH2.Attributes;
        parameters.lengthSeconds = config.Attributes.lengthSeconds;
        parameters.Fs = config.Fs;
        switch (parameters.signalType)
            case 'SIN'
                signal2 = sin_signal(parameters);
            case 'POLYH'
                signal2 = pol_signal(parameters);
            case 'COS'
                signal2 = cos_signal(parameters);
            case 'TRIPULSE'
                signal2 = tri_signal(parameters);
            case 'GAUSPULSE'
                signal2 = gaus_signal(parameters);
            case 'TRIPULSE+COS'
                signal2 = tricos_signal(parameters);
            case 'GAUSPULSE+COS'
                signal2 = gauscos_signal(parameters);
            otherwise
                signal2 = cos_signal(parameters);
        end
        
        signal(:,2) = signal2;
    end

%% ------------------- Subfunction -----------------------------%

    %% Signal: SIN
    function [ signal ] = sin_signal(config)
        
        if nargin < 1
           config = [];
        end
        
        % Default Parameters
        config = fill_struct(config, 'Fs','96000');
        config = fill_struct(config, 'f01','1000');
        config = fill_struct(config, 'A01','1');
        config = fill_struct(config, 'SNR','15'); % signal-to-noise ration
        config = fill_struct(config, 'lengthSeconds','5');
        config = fill_struct(config, 'phasef01',num2str(str2double(config.phasef01Dg)/180*pi)); % carrier frequency's radian phase.
        
        Fs = str2double(config.Fs);
        f01 = str2double(config.f01);
        A01 = str2double(config.A01);
        len = str2double(config.lengthSeconds)*Fs;
        phasef01 = str2double(config.phasef01);
        SNR = str2double(config.SNR);

        % Singal
        dt = 1/Fs;
        t = 0:dt:dt*(len - 1);
        
        signal = awgn(A01*sin(2*pi*f01*t+phasef01), SNR)';

    %% Signal: polyharmonical
    function [ signal ] = pol_signal(config)
        
        if nargin < 1
           config = [];
        end
        
        % Default Parameters
        config = fill_struct(config, 'Fs','96000');
        config = fill_struct(config, 'f01','1000');
        config = fill_struct(config, 'A01','1');
        config = fill_struct(config, 'SNR','15'); % signal-to-noise ration
        config = fill_struct(config, 'lengthSeconds','5');
        config = fill_struct(config, 'phasef01Dg','0'); % carrier frequency's degree phase.
        config = fill_struct(config, 'phasef01',num2str(str2double(config.phasef01Dg)/180*pi)); % carrier frequency's radian phase.
        config = fill_struct(config, 'phaseVarf01Dg','0'); % carrier frequency's degree phase variation.
        config = fill_struct(config, 'phaseVarf01',num2str(str2double(config.phaseVarf01Dg)/180*pi)); % carrier frequency's radian phase variation.
        config = fill_struct(config, 'A01Var','0');  % amplitude variation.
        config = fill_struct(config, 'coefficients','0,1');  % harmonics coeffs.
        
        Fs = str2double(config.Fs);
        f01 = str2double(config.f01);
        A01 = str2double(config.A01);
        len = str2double(config.lengthSeconds)*Fs;
        SNR = str2double(config.SNR);
        phasef01 = str2double(config.phasef01);
        phaseVarf01 = str2double(config.phaseVarf01);
        A01Var = str2double(config.A01Var);
        coefficients = str2num(config.coefficients);

        % Singal
        dt = 1/Fs;
        t = 0:dt:dt*(len - 1);
        
        addpath('D:\Dan_Kechik\Phase\Phase_methods');
        if phaseVarf01
            if ~phasef01
                phasef01 = 2*pi;
            end
            mySignalObj = signalObj(Fs, phasef01, t);
            mySignalObj = mySignalObj.compSlowlyChangedComp('maxFreq', 0.5, phaseVarf01);
            phasef01 = mySignalObj.getSignalVector;
        end
        if A01Var
            mySignalObj = signalObj(Fs, A01, t);
            mySignalObj = mySignalObj.compSlowlyChangedComp('maxFreq', 0.5, A01Var);
            A01 = mySignalObj.getSignalVector;
        end
        rmpath('D:\Dan_Kechik\Phase\Phase_methods');
        
        %Build polyharmonical signal by it' coefficients
        signal = zeros(size(t));
        for i = 0:numel(coefficients)-1
            fullPhase = i*(2*pi*f01*t+phasef01);
            signalSin = A01*sin(fullPhase);
            signal = signal + coefficients(i+1)*signalSin;
        end
        signal = awgn(signal, SNR)';
        
        
    %% Signal: COS
    function [ signal ] = cos_signal(config)
        
        if nargin < 1
           config = [];
        end
        
        % Default Parameters
        config = fill_struct(config, 'Fs','96000');
        config = fill_struct(config, 'f01','1000');
        config = fill_struct(config, 'A01','1');
        config = fill_struct(config, 'SNR','15'); % signal-to-noise ration
        config = fill_struct(config, 'lengthSeconds','5');
        config = fill_struct(config, 'phasef01Dg','0'); % carrier frequency's degree phase.
        
        Fs = str2double(config.Fs);
        f01 = str2double(config.f01);
        A01 = str2double(config.A01);
        len = str2double(config.lengthSeconds)*Fs;
        SNR = str2double(config.SNR);

        % Singal
        dt = 1/Fs;
        t = 0:dt:dt*(len - 1);
        
        signal = awgn(A01*cos(2*pi*f01*t), SNR)';

    
    %% Signal: TRIPULSE
    function [signal] = tri_signal(config)
    
        if nargin < 1
           config = [];
        end
        
        % Default Parameters
        config = fill_struct(config, 'Fs','96000'); % sample frequency
        config = fill_struct(config, 'lengthSeconds','5'); % length [sec]
        config = fill_struct(config, 'f01','5000'); % carrier frequency
        config = fill_struct(config, 'F01','10'); % modulation frequency
        config = fill_struct(config, 'A01','1');  % amplitude
        config = fill_struct(config, 'SNR','15'); % signal-to-noise ration
        config = fill_struct(config, 'D', '0.1'); % duty ratio
        config = fill_struct(config, 'phasef01Dg','0'); % carrier frequency's degree phase.
        config = fill_struct(config, 'phasef01',num2str(str2double(config.phasef01Dg)/180*pi)); % carrier frequency's radian phase.
        config = fill_struct(config, 'phaseVarf01Dg','0'); % carrier frequency's degree phase variation.
        config = fill_struct(config, 'phaseVarf01',num2str(str2double(config.phaseVarf01Dg)/180*pi)); % carrier frequency's radian phase variation.
        config = fill_struct(config, 'A01Var','0');  % amplitude variation.
        
        Fs = str2double(config.Fs);
        len = str2double(config.lengthSeconds)*Fs;
        f01 = str2double(config.f01);
        F01 = str2double(config.F01);
        A01 = str2double(config.A01);
        SNR = str2double(config.SNR);
        D = str2double(config.D);
        phasef01 = str2double(config.phasef01);
        phaseVarf01 = str2double(config.phaseVarf01);
        A01Var = str2double(config.A01Var);
        
        % Signal
        dt = 1/Fs;
        t = 0:dt:dt*(len-1);
        d = 0:1/F01:dt*(len-1);
        
        addpath('D:\Dan_Kechik\Phase\Phase_methods');
        if phaseVarf01
            if ~phasef01
                phasef01 = 2*pi;
            end
            mySignalObj = signalObj(Fs, phasef01, t);
            mySignalObj = mySignalObj.compSlowlyChangedComp('maxFreq', 0.5, phaseVarf01);
            phasef01 = mySignalObj.getSignalVector;
        end
        if A01Var
            mySignalObj = signalObj(Fs, A01, t);
            mySignalObj = mySignalObj.compSlowlyChangedComp('maxFreq', 0.5, A01Var);
            A01 = mySignalObj.getSignalVector;
        end
        rmpath('D:\Dan_Kechik\Phase\Phase_methods');
        
        signal = awgn(pulstran(t,d,'tripuls',D,-1).*A01.*sin(2*pi*f01*t + phasef01),SNR)';
     
    %% Signal: GAUSPULSE
    function [signal] = gaus_signal(config)
        
        if nargin < 1
           config = [];
        end
        
        % Default Parameters
        config = fill_struct(config, 'Fs','96000');
        config = fill_struct(config, 'lengthSeconds','5');
        config = fill_struct(config, 'f01','10000');
        config = fill_struct(config, 'F01','100');
        config = fill_struct(config, 'A01','1');
        config = fill_struct(config, 'SNR','15');
        config = fill_struct(config, 'D', '0.1'); % duty ratio
        
        Fs = str2double(config.Fs);
        len = str2double(config.lengthSeconds)*Fs;
        f01 = str2double(config.f01);
        F01 = str2double(config.F01);
        A01 = str2double(config.A01);
        SNR = str2double(config.SNR);        
        D = str2double(config.D);
            
        % Signal
        dt = 1/Fs;
        t = 0 : dt : dt*(len-1);
        d = [0 : 1/F01 : dt*(len-1); 1.^(1:ceil(dt*(len-1)*F01))]';
        
        signal = awgn(A01*pulstran(t,d,'gauspuls',f01,D),SNR)';

        
    %% Signal: TRIPULSE+COS
    function [signal] = tricos_signal(config)
            
        if nargin < 1
           config = [];
        end
        
        % Default Parameters
        config = fill_struct(config, 'Fs','96000'); % sample frequency
        config = fill_struct(config, 'lengthSeconds','5'); % length [sec]
        config = fill_struct(config, 'f01','5000'); % carrier frequency
        config = fill_struct(config, 'F01','10'); % modulation frequency
        config = fill_struct(config, 'A01','1');  % amplitude
        config = fill_struct(config, 'SNR','15'); % signal-to-noise ration
        config = fill_struct(config, 'D', '0.1'); % duty ratio
        config = fill_struct(config, 'f02','5000'); % carrier frequency
        config = fill_struct(config, 'A02','0.7');  % amplitude
        
        
        Fs = str2double(config.Fs);
        len = str2double(config.lengthSeconds)*Fs;
        f01 = str2double(config.f01);
        F01 = str2double(config.F01);
        A01 = str2double(config.A01);
        SNR = str2double(config.SNR);   
        D = str2double(config.D);
        f02 = str2double(config.f02);
        A02 = str2double(config.A02);
      
        % Signal    
        dt = 1/Fs;
        t = 0:dt:dt*(len-1);
        d = 0:1/F01:dt*(len-1);
        
        signal = awgn(pulstran(t,d,'tripuls',D,-1).*A01*sin(2*pi*f01*t),SNR)' + A02*cos(2*pi*f02*t)';


        %% Signal: GAUSPULSE+COS
    function [signal] = gauscos_signal(config)
        
        if nargin < 1
           config = [];
        end
        
        % Default Parameters
        config = fill_struct(config, 'Fs','96000'); % sample frequency
        config = fill_struct(config, 'lengthSeconds','5'); % length [sec]
        config = fill_struct(config, 'f01','10000'); % carrier frequency
        config = fill_struct(config, 'F01','100'); % modulation frequency
        config = fill_struct(config, 'A01','1');  % amplitude
        config = fill_struct(config, 'SNR','15'); % signal-to-noise ration
        config = fill_struct(config, 'D', '0.5'); % duty ratio
        config = fill_struct(config, 'f02','5000'); % carrier frequency
        config = fill_struct(config, 'A02','0.7');  % amplitude
        
        
        Fs = str2double(config.Fs);
        len = str2double(config.lengthSeconds)*Fs;
        f01 = str2double(config.f01);
        F01 = str2double(config.F01);
        A01 = str2double(config.A01);
        SNR = str2double(config.SNR);   
        D = str2double(config.D);
        f02 = str2double(config.f02);
        A02 = str2double(config.A02);

        % Signal    
        dt = 1/Fs;
        t = 0 : dt : dt*(len-1);
        d = [0 : 1/F01 : dt*(len-1); 1.^(1:ceil(dt*(len-1)*F01))]';
        
        signal = awgn(A01*pulstran(t,d,'gauspuls',f01,D),SNR)' + A02*cos(2*pi*f02*t)';


