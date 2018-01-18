function [psi, xval] = morl2(scale, Fs, formFactor)
%MORLET Morlet wavelet.
%   [PSI,X] = MORLET(LB,UB,N) returns values of 
%   the Morlet wavelet on an N point regular grid 
%   in the interval [LB,UB].
%   Output arguments are the wavelet function PSI
%   computed on the grid X, and the grid X.

% Developer: ASLM
% Date: 10.01.17

% Modified by ASLM 16.03.17

if nargin <=1
   error('Incorrect input arguments'); 
end

lb = -0.01*scale;   % lowwer bounds
ub = 0.01*scale;    % upper bound
N = round((ub-lb)*Fs);  % samples number

f0 = 200/scale; % Shock (main) resonance frequency

% % Compute values of the Morlet wavelet.
xval = linspace(lb,ub,N);        % wavelet support.
wt = 2*pi*f0*xval;
psi = exp(-(wt.^2)/2/formFactor).*cos(5*wt);