function [ result ] = logX(arg, base )
%LOGX Summary of this function goes here
%   Detailed explanation goes here

if nargin < 2
   error('Not enough input arguments'); 
end


[result] = log2(arg)./log2(base);

