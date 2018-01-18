function [ File1 , ShiftData] = test_preresempling( File, config )
%TEST_PRERESEMPLING Summary of this function goes here
%   Detailed explanation goes here

if nargin == 1
   config = []; 
end
File1 = File; 
ShiftData = [];

    config = fill_struct(config, 'secPerFrame', '1');
    config = fill_struct(config, 'secOverlap', '0.5');
%     config = fill_struct(config, 'maxPercentDeviation', '2');

    Fs = File.Fs;
    signal = File.acceleration.signal;
    signalLength = length(signal);
    
    secPerFrame = str2double(config.secPerFrame);
    secOverlap = str2double(config.secOverlap);
%     maxPercentDeviation = str2double(config.maxPercentDeviation);
    maxPercentDeviation = 1;
    frameLength = Fs*(secPerFrame - secOverlap)/10;
    
    % Frequency Trace function
    
%     Fs_law = Fs/100;
%     f_law = 1/(signalLength/Fs);
%     dt_law = 1/Fs_law;
%     t_law = 0:dt_law:signalLength/Fs-dt_law;
    
    Fs_law = signalLength/frameLength;
    f_law = 1/(signalLength/Fs)/2;
    dt_law = frameLength/Fs;
    t_law = 0:dt_law:signalLength/Fs-dt_law;
    shift = maxPercentDeviation*sin(2*pi*f_law*t_law)';
    
    figure('Color','w');
    plot(t_law, shift)
    grid on;
    xlabel('Time, sec');
    ylabel('Shift, %');
    title('Generated Frequency Trace');
    
    
    shift = 1+(shift/100);
%% __________________ Signal Resampling _______________________________ %%

    [P,Q] = rat(shift);

    frameNumber = floor(signalLength/frameLength);
    
    % Resampling of signal parts
    signal = signal(1:frameLength*frameNumber,1);
    frameTable = reshape(signal, frameLength, [])';
    frameTable = frameTable(1:length(shift),:);
    frameCellTable = mat2cell(frameTable, ones(size(frameTable,1),1), size(frameTable,2));
    
    frameTableResampled = arrayfun(@(x,y,z) resample(x{:},y,z), frameCellTable, Q, P, 'UniformOutput', false);
    signalResampled = cell2mat(frameTableResampled')';
      
% OUTPUT :
    File1.acceleration.signal = signalResampled;    
    
    ShiftData.shift = shift;
    ShiftData.time = t_law;
% 
%     dt = 1/Fs;
%     t = 0:dt:dt*(signalLength-1);
%     figure('Color','w'), plot(t, signal);
%     hold on; grid on;
%     t_new = 0:dt:dt*(length(signalResampled)-1);
%     plot(t_new, signalResampled);
%     
    
    df = Fs/length(signal);
    df_new = Fs/length(signalResampled);
    f = 0:df:Fs-df;
    f_new = 0:df_new:Fs-df_new;
    figure('Color','w'), hold on, grid on;
    spectrum = abs(fft(signal));
    spectrum = spectrum/length(signal);
    plot(f, spectrum);

    spectrumResampled = abs(fft(signalResampled));
    spectrumResampled = spectrumResampled/length(signalResampled);
    plot(f_new, spectrumResampled);
    xlabel('Frequency, Hz');
    ylabel('Magnitude, m/s^2');
    title('Spectra of original and resempled signals');
    legend('original' , 'resampled');
    xlim([0; 25]);