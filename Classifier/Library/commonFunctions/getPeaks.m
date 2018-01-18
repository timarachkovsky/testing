% function [ validMag2i ,validMag20i ] = getValidPeaks( innerSignal, Fs, shaftFreq, defectFreq)
function [ validMagi,  validPeaksi] = getPeaks(file, shaftFreq, defectFreq, accuracy, peakThreshold)
%CLASSIFIER Summary of this function goes here
%   Detailed explanation goes here
%   Developer:   ASLM
%   Version:         v1_3
%   Date               11/04/2016
%___________________________________________________________________________
% valid_peaks2[] -  valid peaks vector with 0.2%-accuracy window (for narrow
%                   peaks)  range of analysis - 2% shaftFreq;
% valid_peaks20[] - valid peaks vector with 2%-accuracy window (for
%                   wide peaks)  range of analysis - 20% shaftFreq.
%____________________________________________________________________________
%% 

FigAccuracy = accuracy/100; % Figures accuracy
defectFreq(defectFreq(:,:)>90000) = 0;
highFreq = max(defectFreq(:))*1.3;          % high freq of the cut-off inner signal
[ signal, f, df ] = cutAndInterpolate(file, shaftFreq, highFreq );    % cut and interpolate inner using spline
signalRms = rms(signal);    % root-mean-square value of the interpolated signal
%                                                                                                 s                                                % vector to rich direct accuracy
% figure
% plot(f, signal)
% grid on;
                                                                                                              
%%
% recalculate freq step to points count


locDelta = round((FigAccuracy/2)*(shaftFreq/df));
locDelta01 = round(locDelta/10);



centerLoc = locDelta;             % the center of the subframe to analyze
lengthFrame = 2*centerLoc;       % frame length 
%peakThreshold = 1.4;    % peak severity Threshold: severity = <averageMaxPeakValue>/<averageNonePeakValue>
winCnt = 5;        % one-side windows count to analize pulse (total amount = 2*winCnt+1)

frameStep = ceil(lengthFrame/(2*winCnt+1))-1;

    tempStep = 1; 
    peakRange = [];
    for i = 1:1:(2*winCnt+1)
        
        peakRange(i,:) =  tempStep : (i*frameStep)+1;
        tempStep = (i*frameStep)+1;
        
    end
    peak_locRange = centerLoc-2*locDelta01 :centerLoc+2*locDelta01; % range that falls peak
    nopeak_locRange = [1:(centerLoc-(5*locDelta01)), (centerLoc+(5*locDelta01)): lengthFrame ]; % range that falls noise         


%% --------------   INITIALS ----------------------%%

    [m,n] = size(defectFreq);
    validMagi = zeros(m,n);
    validPeaksi = zeros(m,n);

    for k=1:1:m
        peakCnt = sum(defectFreq(k,:)>0);   % count of the peaks to look for
        defectFreqLocations = round(defectFreq(k,1:peakCnt)/df);        % shaft freq locations vector ( freq ---> position)
        frameTable = zeros(peakCnt, lengthFrame);     % peaks table

        E = zeros(peakCnt, 1);      % total energy
        E_peak = zeros(peakCnt, 1); % peak area enrgy
        peakSeverity = zeros(peakCnt, 1);    
        peakEnergyVector = zeros(peakCnt, winCnt*2+1);
        max_pos = zeros(peakCnt, 3);
        validPeaks = zeros(peakCnt,1);
        validMag =  zeros(peakCnt,1);
        peakEnergyMax = zeros(peakCnt,length(peakRange(1,:)));
        
        % ---------------------  MAIN BODY --------------------------------
        
        for i=1:1:peakCnt

            frameTable(i, 1:lengthFrame) = signal((defectFreqLocations(i)-(centerLoc)):(defectFreqLocations(i)+(centerLoc)-1)); % copy signal part to frameTable

            E(i) = sum(frameTable(i,nopeak_locRange));
            E_peak(i) = sum(frameTable(i,peak_locRange));
            peakSeverity(i) = (E_peak(i)/length(peak_locRange))/(E(i)/length(nopeak_locRange));

            for j = 1:1:winCnt*2+1

                    peakEnergyVector(i,j) = sum(frameTable(i,peakRange(j,:)));                
            end

            [temp,originalpos] = sort( peakEnergyVector(i,:), 'descend' );

            max_pos(i,:)=originalpos(1:3); % find positions of windows with hggh energy 


            if( ((max_pos(i,1) == winCnt+1) ||(max_pos(i,1) == winCnt) ||(max_pos(i,1) == winCnt+2) ||(max_pos(i,2) == winCnt+1) ||(max_pos(i,2) == winCnt)|| (max_pos(i,2) == winCnt+2)|| (max_pos(i,3) == winCnt+1)||(max_pos(i,3) == winCnt)||(max_pos(i,3) == winCnt+2)) &&( peakSeverity(i)>peakThreshold))
                peakEnergyMax(i,:) = frameTable(i,peakRange(max_pos(i,1),:)); % get largest energy window to approximate a given frequency
                validMag(i) = max(smooth(peakEnergyMax(i,:),3));              % flatten the signal within the window and find max
                validPeaks(i) = peakSeverity(i);
                %validMag(i) = E_peak(i)/length(peak_locRange);
            else
                validPeaks(i) = 0;
                validMag(i) = 0;
            end
        end
        
%         fprintf('Inner defect frequencies: %5.3f\n', defectFreq);
%         fprintf('Valid peaks: %5.3f\n', validPeaks);
        
        validMagi(k,1:length(validMag(:,1))) = validMag(:,:)'; 
        validPeaksi(k,1:length(validPeaks(:,1))) = validPeaks(:,:)';
    end         % for i=1:1:m end
end

