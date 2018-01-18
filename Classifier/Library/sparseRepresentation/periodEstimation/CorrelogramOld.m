% function [S_real, cor_vec_fin]= Correlogram(signal,Fs,S,step,delta,K_f_cut,printResult)

% Function version : v2.5a
% Last change : 04.04.2016
% Developer : ASLM

% modified : 11.07.2016
% developer : ASLM

function [freqReal, corrCoefVectorFinal]= Correlogram(file,config)

if nargin<2
   config = []; 
end

%% ___________________ Default Parameters _____________________________ %%
%    config = fill_struct(config, 'freqNominal',10);  % Nominal main signal
                                                    % frequency (1/period)
   config = fill_struct(config, 'cutCoef','1');   % Singnal length cut coef
   config = fill_struct(config, 'step','0.1');    % Frequency step
   config = fill_struct(config, 'range','10');    % Frequency range around
                                                % freqNominal to analize
   config = fill_struct(config, 'filterCutCoef','20');    % LPF cut frequency
                                                        % coefficient
   config = fill_struct(config, 'filterEnable','0');  % LPF enable
   config = fill_struct(config, 'envelopeEnable','1');  % Envelope enable
   config = fill_struct(config, 'Rp','1');    % Passband ripple, dB
   config = fill_struct(config, 'Rs','10');   % Stopband attenuation, dB
   config = fill_struct(config, 'plotEnable','1');    % Plotting enable
   
   config.cutCoef = str2num(config.cutCoef);
   if ischar(config.step)
       config.step = str2num(config.step);
   end
   if ischar(config.range)
       config.range = str2num(config.range);
   end
   config.filterCutCoef = str2num(config.filterCutCoef);
   config.filterEnable = str2num(config.filterEnable);
   config.envelopeEnable = str2num(config.envelopeEnable);
   config.Rp = str2num(config.Rp);
   config.Rs = str2num(config.Rs);
   if ischar(config.plotEnable)
       config.plotEnable = str2num(config.plotEnable);
   end
   
   % ! DebugMode ...
%     config.plotEnable = 0;
   % ! DebugMode ...
   
%% ---------------------- Signal Filtering ----------------------------%%
   
    signal = file.signal(1:round(length(file.signal)/config.cutCoef),1);
    Fs = file.Fs;
    signalLength = length(signal);
    freqNominal = file.freqNominal;

if ~config.filterEnable
    signalFilt = signal;
else
    cutFrequency = freqNominal*config.filterCutCoef;  % LPFilter cut-off frequency
    Wp = cutFrequency*2/Fs;
    Ws = (cutFrequency+100)*2/Fs;

    [n,Wn] = buttord(Wp,Ws,config.Rp,config.Rs);         
    [b,a] = butter(4,Wn);   
    signalFilt = filtfilt(b,a,signal);
end
%% ---------------- Hilbert Envelope & Spectrum ------------------- %%
if ~config.envelopeEnable
   signalEnvelope = abs(signalFilt)';
else
   signalEnvelope = envelope(signalFilt)';
end

%% ---------------- Correlogram ---------------------------%%
dS = freqNominal*config.step/100                                            
NS = 2*config.range/100/(config.step/100) + 1       % Number of S values
maxFrameLength = ((1/(freqNominal*(1-(config.range/100))))*Fs);      % Max frame length
NF = floor(signalLength/maxFrameLength)       					% Number of frames
corrCoefVector = 0;

currentFreq(1:1:NS,1) = freqNominal+((1:1:NS)-(NS-1)/2-1)*dS;       % current S ( frequency)
Len = floor((currentFreq.^-1) * Fs);
corrCoefVector = zeros (NF-1,NS);

for j = 1:1:NS
%     j
    for i = 1:1:NF-1
        base_vec = signalEnvelope(1,(1+Len(j)*(i-1):Len(j)*i));				% base frame 
        base_result = abs(fastcorr(base_vec,base_vec));
        result = zeros(NF-1-i,1);
         
        for idx = (i):1:NF-1
            curr_vec = signalEnvelope(1,Len(j)*idx+1:Len(j)* (idx+1));	% current frame
            result(idx,1) = abs(fastcorr(base_vec,curr_vec));
        end
        corrCoefVector(i,j) = sum(result,1)/base_result/(NF-(i));		% the table of average and normolize 
																	% values of cor_vec for current S
    end
end
corrCoefVectorFinal = sum(corrCoefVector,1)/(NF-1);			

[value index] = max(corrCoefVectorFinal) ;
freqReal =   freqNominal+(index-(NS-1)/2-1)*dS;           

%% ____________________________ PLOT_RESULTs __________________________ %%
     if config.plotEnable == 1
        dt=1/Fs;
        tmax=dt*(signalLength-1);
        t=0:dt:tmax;
        
        tS = (freqNominal-dS*(NS-1)/2):dS:(freqNominal+dS*(NS-1)/2);

        figure;
        subplot(3,1,1)
        plot(t,signal,'r-');
        ylabel('Signal');
        legend('Record_1.wav');grid;zoom xon;

        subplot(3,1,2)
        plot(t,signalEnvelope);
        ylabel('signal Envelope');
        xlabel('Time, s');

        subplot(3,1,3)
        plot(tS, corrCoefVectorFinal);
        ylabel('Correl Func');
        xlabel('Freq, Hz');
    end

end
