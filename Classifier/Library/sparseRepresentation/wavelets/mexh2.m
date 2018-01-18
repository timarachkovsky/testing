function [psi, xval] = mexh2(scale, Fs)
%MEXIHAT Mexican hat wavelet.

if nargin <=1
   error('Incorrect input arguments'); 
end

lb = -0.01*scale;   % lowwer bounds
ub = 0.01*scale;    % upper bound
N = round((ub-lb)*Fs);  % samples number

f0 = 1000/scale; % Shock (main) resonance frequency


xval = linspace(lb,ub,N);        % wavelet support.
wt = 2*pi*f0*xval;


% Compute values of the Mexican hat wavelet.

psi = wt.^2;
psi = (2/(sqrt(3)*pi^0.25)) * exp(-psi/2) .* (1-psi);