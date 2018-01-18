function [ signal ] = reconstructSignal( sparseSignal, baseFunc, originalSignal )
%RECONSTRUCTSIGNAL Summary of this function goes here
%   Detailed explanation goes here

signalLength = length(originalSignal);
baseFuncLength = length(baseFunc);
signal = zeros(signalLength+2*baseFuncLength,1);

pos = find(sparseSignal);
num = numel(pos);
figure
for i=1:1:num
    
    signal(pos(i):pos(i)+baseFuncLength-1,1) = signal(pos(i):pos(i)+baseFuncLength-1,1)+ baseFunc.*sparseSignal(pos(i));
    plot(signal);
end

% signal = signal(baseFuncLength:end-baseFuncLength-1,1);
signal = signal(round(baseFuncLength/2):round(baseFuncLength/2)+signalLength-1)';
% clear signal pos num baseFuncLength






