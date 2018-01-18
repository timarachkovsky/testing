
close all;clear all; clc

scale = 1;
Fs = 96000;
formFactor = 1;

% % waveletType = 'mexh_morl2';
% % waveletType = 'gabor';
% waveletType = 'swd_sin';
% % 
% [psi, xval] = feval(waveletType,scale, Fs, formFactor);
% figure, set(gcf, 'color','w');
% plot(xval,psi);
% xlabel('Time','FontSize',12)
% ylabel('Wavelet','FontSize',12);
% grid on

% dt = 1/Fs;
% waveletLength = length(psi);
% 
% df = Fs/waveletLength;
% f = 0:df:Fs-df;

% figure, plot(f,abs(fft(psi)));
% xlabel('Frequency,Hz');
% ylabel('Magnitude');


% waveletType = 'mexh_morl2';
% waveletType = 'gabor';
% waveletType = 'sin3';

% % waveletType = 'swd_sin';
% waveletType = 'swd_gabor';
% % waveletType = 'swd_mexh_morl';
% 
% lFactor = 0.25; hFactor = 160; nFactor = 320;
% % lFactor = 0.1; hFactor = 20; nFactor = 40;
% % lFactor = 0.1; hFactor = 2; nFactor = 20;
% % lFactor = 0.1; hFactor = 8; nFactor = 40;
% % lFactor = 0.1; hFactor = 40; nFactor = 80;
% formFactorVector = linspace(lFactor,hFactor,nFactor);
% supportLengthVector = zeros(size(formFactorVector));
% supportCenterVector = supportLengthVector;
% % 
% for i = 1:1:nFactor
%     [psi, xval] = feval(waveletType,scale, Fs, formFactorVector(i));
%     [supportLengthVector(i),supportCenterVector(i)] = compactSupportTimeLength(psi,scale,formFactorVector(i));
% end

%     [psi, xval] = feval('mexh_morl',1, 96000, 1);
%     delta_T = sum(abs(psi))/max(psi);
%     [supportLengthVector,supportCenterVector] = compactSupportTimeLength(psi,1,1);
    
    


% save([waveletType,'_support.mat'],'supportLengthVector','formFactorVector');
% sin2LengthVector = 272*[1,2,4,8];

% sinLengthVector = 272*[1,2,4,8,16];
sinLengthVector = 272*linspace(1,16,16);
[mexhMorlFactor,gaborFactor,sinFactor] = calculateWaveletFormFactor(sinLengthVector);

for i = 1:1:length(sinLengthVector)
    
%     waveletType = 'mexh_morl2';
    waveletType = 'swd_mexh_morl';
    [psi, xval] = feval(waveletType,scale, Fs, mexhMorlFactor(i));
    figure, set(gcf,'color','w');
    plot(xval,psi);
    xlabel('Form Factor');
    ylabel('Wavelet');
    title(['mexh\_morl2',' #',num2str(i),', when scale=',num2str(scale),', formFactor=',num2str(round(mexhMorlFactor(i),2))]);
    
%     waveletType = 'gabor';
    waveletType = 'swd_gabor';
    [psi, xval] = feval(waveletType,scale, Fs, gaborFactor(i));
    figure, set(gcf,'color','w');
    plot(xval,psi);
    xlabel('Form Factor');
    ylabel('Wavelet');
    title([waveletType,' #',num2str(i),', when scale=',num2str(scale),', formFactor=',num2str(round(gaborFactor(i),2))]);
    
%     waveletType = 'sin3';
    waveletType = 'swd_sin';
    [psi, xval] = feval(waveletType,scale, Fs, sinFactor(i));
    figure, set(gcf,'color','w');
    plot(xval,psi);
    xlabel('Form Factor');
    ylabel('Wavelet');
    title([waveletType,' #',num2str(i),', when scale=',num2str(scale),', formFactor=',num2str(round(sinFactor(i),2))]);
end

% figure, set(gcf,'color','w');
% plot(formFactorVector,supportLengthVector);
% xlabel('Form Factor');
% ylabel('Compact Support Length');
% title([waveletType,' compactSupportLength vs formFactor',', when scale=',num2str(scale)]);
% 
% figure, set(gcf,'color','w');
% plot(formFactorVector,supportCenterVector);
% xlabel('Form Factor');
% ylabel('Compact Support Center Point');
% title([waveletType,' compactSupportCenter vs formFactor',', when scale=',num2str(scale)]);


function [supportLength, supportCenter] = compactSupportTimeLength(wavelet,scale,formFactor)
    
    energyFactor = 0.99;
    energyVector = bsxfun(@times,wavelet,wavelet);
    energy = sum(energyVector);
    waveletLength = length(wavelet);
    
    if mod(waveletLength,2)
        middlePoint = (waveletLength+1)/2;
    else 
        middlePoint = waveletLength/2;
    end
    
    
    % Estimation of compact support length of the RIGHT side of the wavelet
    rightPart = wavelet(middlePoint+1:end);
    rightEnergyVector = bsxfun(@times,rightPart,rightPart);
    rightEnergy = sum(rightEnergyVector);
    
    currentEnergy = 0;
    supportRightPoint = 0;
    energyThreshold = energyFactor*rightEnergy;

    for i = 1:1:length(rightPart)
        currentEnergy = currentEnergy + rightEnergyVector(i);
        if currentEnergy >= energyThreshold
            supportRightPoint = i;
            break;
        end
    end
    
     % Estimation of compact support length of the LEFT side of the wavelet
    leftPart = wavelet(middlePoint:-1:1);
    leftEnergyVector = bsxfun(@times,leftPart,leftPart);
    leftEnergy = sum(leftEnergyVector);
    
    currentEnergy = 0;
    supportLeftPoint = 0;
    energyThreshold = energyFactor*leftEnergy;
    
    for i = 1:1:length(leftPart)
        currentEnergy = currentEnergy + leftEnergyVector(i);
        if currentEnergy >= energyThreshold
            supportLeftPoint = i;
            break;
        end
    end
    
    supportLength = supportRightPoint + supportLeftPoint;
    
    supportRightPoint = middlePoint+supportRightPoint;
    supportLeftPoint = middlePoint - supportLeftPoint;
    
    % Estimate energy center of the wavelet 
    currentEnergy = 0;
    supportCenter = 0;
    energyThreshold = energyFactor/2*energy;
    
    for i = 1:1:waveletLength
        currentEnergy = currentEnergy + energyVector(i);
        if currentEnergy >= energyThreshold
            supportCenter = i;
            break;
        end
    end
    
    
    % Plot result
    figure, set(gcf,'color','w');
    plot(energyVector);
    points = zeros(size(energyVector));
    points(supportRightPoint) = 1;
    points(supportLeftPoint) = 1;
    centerPoints = zeros(size(wavelet));
    centerPoints(supportCenter) = 1;
    hold on, stairs(points,'r');
    hold on, stairs(centerPoints,'--');
    xlabel('points, [units]');
    ylabel('Wavelet Energy');
    legend('Energy Vector','Compact Support','Energy Center');
    title(['CompactSupportLength = ', num2str(supportLength),', when scale=',num2str(scale),' formFactor=',num2str(formFactor)]);
    
    figure, set(gcf,'color','w');
    plot(wavelet);
    hold on, stairs(points,'r');
    hold on, stairs(centerPoints,'--');
    xlabel('points, [units]');
    ylabel('Wavelet');
    legend('Wavelet','Compact Support','Energy Center');
    title(['CompactSupportLength = ', num2str(supportLength),', when scale=',num2str(scale),' formFactor=',num2str(formFactor)]);
    
end

function [mexhMorlFactor,gaborFactor,sin3Factor] = calculateWaveletFormFactor(sin2LengthVector)
    
    interpolationFactor = 100;
    
    % mexh_morl
%     load('mexh_morl2_support.mat');
    load('swd_mexh_morl_support.mat');
    originLength = length(formFactorVector);
    originVector = linspace(1,originLength,originLength);
    interVector = linspace(1,originLength,interpolationFactor*originLength);
    mexh_morlSupportLengthVector = interp1(originVector,supportLengthVector,interVector, 'spline');
    mexh_morlFormFactorVector = interp1(originVector,formFactorVector,interVector,'spline');
    
    % gabor
%     load('gabor_support.mat');
    load('swd_gabor_support.mat');
    originLength = length(formFactorVector);
    originVector = linspace(1,originLength,originLength);
    interVector = linspace(1,originLength,interpolationFactor*originLength);
    gaborSupportLengthVector = interp1(originVector,supportLengthVector,interVector, 'spline');
    gaborFormFactorVector = interp1(originVector,formFactorVector,interVector,'spline');
    
    % sin2
%     load('sin3_support.mat');
    load('swd_sin_support.mat');
    originLength = length(formFactorVector);
    originVector = linspace(1,originLength,originLength);
    interVector = linspace(1,originLength,interpolationFactor*originLength);
    sin3SupportLengthVector = interp1(originVector,supportLengthVector,interVector, 'spline');
    sin3FormFactorVector = interp1(originVector,formFactorVector,interVector,'spline');
    
    
    % Look for formFactor coefficients of the mexh_morl, gabor, sin2
    % wavelets
    positionsNumber = length(sin2LengthVector);
    
    mexhMorlFactor = zeros(size(sin2LengthVector));
    gaborFactor = mexhMorlFactor;
    sin3Factor = mexhMorlFactor;
    
    for i = 1:1:positionsNumber
        supportLength = sin2LengthVector(i);
        
        mexhMorlPosition = find(mexh_morlSupportLengthVector >=supportLength,1,'first');
        gaborPosition = find(gaborSupportLengthVector >=supportLength,1,'first');
        sin3Position = find(sin3SupportLengthVector >=supportLength,1,'first');
        
        mexhMorlFactor(i) = mexh_morlFormFactorVector(mexhMorlPosition);
        gaborFactor(i) = gaborFormFactorVector(gaborPosition);
        sin3Factor(i) = sin3FormFactorVector(sin3Position);
    end
    
    
    % Plot results
    onesVector = ones(size(gaborFormFactorVector));
    firstLine = sin2LengthVector(1)*onesVector;
    secondLine = sin2LengthVector(2)*onesVector;
    thirdLine = sin2LengthVector(3)*onesVector;
    fourthLine = sin2LengthVector(4)*onesVector;
    
    figure, set(gcf, 'color', 'w'),hold on;
    plot(mexh_morlFormFactorVector,mexh_morlSupportLengthVector)
    plot(gaborFormFactorVector,gaborSupportLengthVector)
    plot(sin3FormFactorVector,sin3SupportLengthVector);
    
    plot(gaborFormFactorVector,firstLine,'--');
    plot(gaborFormFactorVector,secondLine,'--');
    plot(gaborFormFactorVector,thirdLine,'--');
    plot(gaborFormFactorVector,fourthLine,'--');
    
    xlabel('Form Factor');
    ylabel('Compact Support Length');
    title('Basis CS length normalization');
    legend('mexh\_morl','gabor','sin3','legth1','legth2','legth4','legth8');
    
end

