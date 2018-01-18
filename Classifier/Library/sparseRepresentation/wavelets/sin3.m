function [psi, xval] = sin3(scale, Fs, formFactor)
%SIN2 Sin2 wavelet.
%   [PSI,X] = SIN3(SCALE, FS) returns values of 
%   the SIN2 wavelet on an N point regular grid 
%   in the interval [LB,UB].
%   Output arguments are the wavelet function PSI
%   computed on the grid X, and the grid X.

% Modified by ASLM 15.03.17

if nargin <=1
   error('Incorrect input arguments'); 
end

lb = -0.03*scale;   % lowwer bound
ub = 0.03*scale;    % upper bound
N = round((ub-lb)*Fs);  % samples number

f0 = 1000/scale; % Shock (main) resonant frequency
k = 1/8/f0;

% % Compute values of the sin2 wavelet.
xval = linspace(lb,ub,N);        % wavelet support.
wt = 2*pi*f0*xval;

% % Compute rectange function with exp sides
rect = ones(1,N);
rectSide = round(Fs*formFactor*2/f0);
middlePos = round(N/2);

lrPos = middlePos - rectSide;
urPos = middlePos + rectSide;
z = exp(-xval(middlePos+1:end)/k); % regular exp function

rect(1,lrPos:urPos) = 1;
rect(1,urPos+1:end) = z(1:end-rectSide);
if length(rect(1,1:lrPos)) > length(z(end-rectSide:-1:1)) % dummy
    rect(1,1:lrPos-1) = z(end-rectSide:-1:1);
else
    rect(1,1:lrPos) = z(end-rectSide:-1:1);
end

% % Wavet coefficients
psi = rect.*sin(wt);
