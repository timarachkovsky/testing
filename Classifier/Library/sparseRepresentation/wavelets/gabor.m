function [psi, xval] = gabor(scale, Fs, formFactor)
%GABOR Morlet wavelet.
%   [PSI,X] = GABOR(SCALE, FS) returns values of 
%   the Morlet wavelet on an N point regular grid 
%   in the interval [LB,UB].
%   Output arguments are the wavelet function PSI
%   computed on the grid X, and the grid X.

% Developer: ASLM
% Date: 15.03.17

if nargin <=1
   error('Incorrect input arguments'); 
end

lb = -0.03*scale;   % lowwer bounds
ub = 0.03*scale;    % upper bound
N = round((ub-lb)*Fs);  % samples number

f0 = 200/scale; % Shock (main) resonance frequency

% % Compute values of the Gabor wavelet.
xval = linspace(lb,ub,N);        % wavelet support.
wt = 2*pi*f0*xval;
psi = exp(-(wt.^2)/4/formFactor).*cos(5*wt);