function [psi, xval] = mexh_morl2(scale, Fs, formFactor)
% MEXH_MORL - DAVYDOV WAVELET(C)
% FUNCTION FORMS MEXH_MORL-WAVELET 
% SCALE - scale coefficient 
% FS - sample frequency

% Developer: ASLM
% Date: 10.06.16

% Modified by ASLM 29.06.16
% Modified by ASLM 16.03.17

if nargin <=1
   error('Incorrect input arguments'); 
end

lb = -0.03*scale;   % lowwer bounds
ub = 0.03*scale;    % upper bound

% lb = -0.1*scale;   % lowwer bounds
% ub = 0.1*scale;    % upper bound

N = round((ub-lb)*Fs);  % samples number
f0 = 1000/scale; % Shock (main) resonance frequency
% k = 1/f0; % exp(-x) tilt coefficient
k = formFactor/f0; % exp(-x) tilt coefficient

xval = linspace(lb,ub,N);       % x-coordinate values 
middlePos = round(N/2)+ round(Fs/f0/4);       % Center position + [cos()=0]position  
                                              % to eliminate breaking point
psi = zeros(1,N);               %

%%=============== WAVELET BEHAVIOR ===========%%
wt1 = 2*pi*f0*xval(1:middlePos);      % @mexical_hat time samples 
wt2 = 2*pi*f0*xval(middlePos+1:end);  % @morlet time samples

psi(1:middlePos) = (4/pi^2)*(pi^2/4 - wt1.^2).*exp(-2*wt1.^2/pi^2); % @mexh_morl left part
psi(middlePos+1:end) = cos(wt2).*exp(-xval(middlePos+1:end)/k);     % @mexh_morl right part


