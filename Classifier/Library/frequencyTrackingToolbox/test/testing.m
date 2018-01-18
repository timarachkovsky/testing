clc;
clear all; close all;


accuracy = 0.001;
freqMax = 500;

freqDeltaMin120 = 1/120;
freqDeltaMin60 = 1/60;
freqDeltaMin30 = 1/30;
freqDeltaMin10 = 1/10;

freqDeltaMinCollection = [1/120, 1/60, 1/30, 1/10];

a = linspace(2,200,19900);
b = a - 0.01;

% logBasisCollection = [1.1, 1.05, 1.01, 1.005, 1.001];
logBasisCollection = [1.01];
% logStepCollection = log2(accuracy/10+1)./log2(logBasisCollection);
logStepCollection = logX(accuracy/10+1, logBasisCollection);

figure('Color','w');
hold on;
for i = 1:numel(logBasisCollection)
   
    maxStep = floor(logX(freqMax,logBasisCollection(i))/logStepCollection(i));
    f = logBasisCollection(i).^(logStepCollection(i)*linspace(1, maxStep, maxStep));
    
    delta = [NaN, diff(f,1)];
    
    hp = plot(f, delta);
%     hp = plot(delta);
    color = hp.Color;
    
%     freqDeltaLine = ones(size(f))*freqDeltaMin;
%     hp = plot(f, freqDeltaLine, '--');
% %     hp = plot(freqDeltaLine, '--');
%     hp.Color = color;
    
%     delta = log2(a)/log2(logBasisCollection(i)) - log2(b)/log2(logBasisCollection(i));
%     hp = plot(b, delta);
%     color = hp.Color;
%     
%     stepLine = ones(size(b))*logStepCollection(i);
%     hp = plot(b, stepLine, '--');
%     hp.Color = color;

end

for j = 1:numel(freqDeltaMinCollection)
    
   freqDeltaLine = ones(size(f))*freqDeltaMinCollection(j);
    hp = plot(f, freqDeltaLine, '--');
%     hp = plot(freqDeltaLine, '--');
%     hp.Color = color; 
end

    xlabel('Frequency, Hz');
    ylabel('diff Frequency, Hz');
    grid on;
%     title(['LogBasis = ', num2str(logBasisCollection(i))]);
%     legend('1.1','1.1 step', '1.05', '1.05 step', '1.01', '1.01 step', '1.005', '1.005 step', '1.001' ,'1.001 step');
    legend('logBasis = 1.01', 'T=120 sec', 'T=60 sec', 'T=30 sec', 'T=10 sec');
    
    
    