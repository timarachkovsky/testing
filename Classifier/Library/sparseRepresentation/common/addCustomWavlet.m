
%% ================== ADDING CUSTOM WAVELET TO WAVELET_MANAGER (WAVEMNGR) ============ %%
clear; clc; format compact

[y,x] =  mexh_morl(1,96000);    % Create the pattern signal 
% [y,x] =  morl2(1,96000,1);    % Create the pattern signal 
% plot(X,Y);
[Y,X,nc] = pat2cwav(y, 'orthconst', 4, 'continuous') ;%  Create a orthconst fit of the pattern signal 

% plot(x,y,'-',X,nc*Y,'--'); % Plot the pattern compared to the polynomial fit 
% title('Original Pattern and Adapted Wavelet (dashed line)') 
save('mexh_morl.mat', 'Y', 'X');   % save pattern to *.mat file
% save('morl2.mat', 'Y', 'X');   % save pattern to *.mat file

% you don't need the nc value to be save as by convention all wavelets saved are of energy = 1 (the integral =1) and this variable is not used in cwt or wavemngr, it is only useful to pass from your pattern to the adapted pattern
% wavemngr('del','CosWave');   % Clean-up custom wavelet folder
% wavemngr('del','CustomWave');   % Clean-up custom wavelet folder
wavemngr('add','CustomWave','mexh_morl',4,'','mexh_morl.mat',[-1 1]); % Write custom wavelet pattern to wavelet manager
wavefun('mexh_morl',1,'plot');  % Check-in write operation

% wavemngr('add','CustomWave','morl2',4,'','morl2.mat',[-1 1]); % Write custom wavelet pattern to wavelet manager
% wavemngr('add','CustomWave1','morl2',4,'','morl2.mat',[-1 1]); % Write custom wavelet pattern to wavelet manager
% wavefun('morl2',1,'plot');  % Check-in write operation

%% ********************  END  ***********************
