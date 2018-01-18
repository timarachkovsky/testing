function [pattern, residue] = getPattern( file,config )
%AVERAGEPERIOD Summary of this function goes here
%   Detailed explanation goes here
if nargin<2
   config = [];
end

%% -------------------- Default Parameters ------------------- %%
    config = fill_struct(config,'plotEnable',1);
    config = fill_struct(config,'period',100);
    config = fill_struct(config,'negativeResidueEnable',0);
    config = fill_struct(config,'subframeCount',4);

    signal = file.signal;
    frameLength = config.period;
%% ------------------------ Calculations ---------------------- %%
    signalLength = length(signal);
    if signalLength < frameLength
       warning('Period is greater then signal lenght!'); 
    end
    
% Divide signal into the set of frames to find periodic part
    frameCount = floor(signalLength/frameLength); 
%     startPos = 1:frameLength:(frameLength-1)*frameCount+1;
    startPos = 1:frameLength:(frameLength)*frameCount-1;
    endPos = frameLength:frameLength:frameLength*frameCount+1;
    baseSignal = zeros(frameCount,frameLength);
    for i = 1:1:frameCount
        baseSignal(i,:) = signal(startPos(1,i):1:endPos(1,i));
    end
    
% Find periodic signal part
    megaframeCount = floor(frameCount/config.subframeCount);
    baseMatrix = zeros(config.subframeCount, megaframeCount*frameLength);
    % Form baseMatrix with 4 rows. Each column is a 4 near standing frames;
    % Number of colums is a megaframeCount
    for i = 1:1:megaframeCount
        for j = 1:1:config.subframeCount
            baseMatrix(j,(i-1)*frameLength+1:i*frameLength) = baseSignal((i-1)*config.subframeCount+j,:);
        end
    end
    
    % Multiply 2 pairs of near standing frames and sum the results
    average1 = bsxfun(@times,baseMatrix(1:config.subframeCount/2,:),baseMatrix(config.subframeCount/2+1:end,:));
    average2 = bsxfun(@plus,average1(1:config.subframeCount/4,:),average1(config.subframeCount/4+1:end,:));
    temp = reshape(average2,frameLength,[])';
   
    % Normolize average2 
    average3 = bsxfun(@rdivide,temp,max(temp,[],2))';
    % Calculate the column wich consists of the max values of the signal frames 
    maxSignalVector = max(reshape(signal(1:length(baseMatrix)*4,1),frameLength,[]),[],1)'; 
    average4 = reshape(bsxfun(@times,reshape(repmat(average3,[config.subframeCount,1]),frameLength,[])',maxSignalVector)',1,[]).*2;
    pattern = [average4, zeros(1,max(size(signal))-length(average4))]';
    residue = zeros(size(signal));
    residue(1:length(average4),1) = signal(1:length(average4),1) - average4';
    residue(isnan(residue))=0;
    pattern(isnan(pattern))=0;
    if config.negativeResidueEnable == 0
       residue(residue(:,:)<0) = 0;
    end
    

%% --------------------- Plot resulst ------------------------------ %%
    if config.plotEnable == 1
        dt = 1/file.Fs;
 
        tmax = dt*signalLength;
        t = 0:dt:tmax-dt;
        figure
     
        subplot(2,1,1);
        hold on
        plot(t, signal, 'b');
        plot(t, pattern, 'r');
        ylabel('Singal & Average Signal');
        xlabel('Time, s');
        legend('sparse signal','pattern');
        hold off
        
        subplot(2,1,2);
        hold on
        plot(t, signal, 'b');
        plot(t, residue, 'r');
        ylabel('Singal & Residue Signal');
        xlabel('Time, s');
        legend('sparse signal','residue');
        hold off
    end


end

