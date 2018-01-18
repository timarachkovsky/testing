% clc; clear all;
% close all;

% randn('state',0); 
% noise = randn(50000,1);  % Normalized white Gaussian noise
% x = filter(1,[1 1/2 1/3 1/4],noise);
% x = x(45904:50000);
% a = lpc(x,3);
% est_x = filter([0 -a(2:end)],1,x);  % Estimated signal
% e = x - est_x;                      % Prediction error
% [acs,lags] = xcorr(e,'coeff');      % ACS of prediction error
% 
% 
% 
% x = linspace(1,100,100);
% a = lpc(x,5);
% est_x = filter([0 -a(2:end)],1,x);

% 
% est_y = filter([0 -a(2:end)],1,[x,0]);
% y = [1, 1, 1, 1.1, 1.2, 1.3, 1.35, 1.3, 1.2, 1.11, 1, 1];
% 
% x0 = y(1:3);
% for i = 1:8
%     x = y(1:2+i);
%     a = lpc(x,3);
%     x_est = filter([0 -a(2:end)],1,[x,x(end),x(end)]);
%     e = y(1:2+i+2) - x_est; 
% end
% x;

