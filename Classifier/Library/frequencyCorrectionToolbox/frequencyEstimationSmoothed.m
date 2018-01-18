function [frequencyResult,frequencyProbability,frequencyFramesTable] = frequencyEstimationSmoothed(file, config)
% FREQUENCYESTIMATIONSMOOTHED function description...
%   Developer:              Y. Aslamov
%   Development date:

%   Modified by:            Y. Aslamov
%   Modification date:      10-10-2016

if nargin<2
    config = [];
end

%% ______________________ Default parameters __________________________ %%

config.common = fill_struct(config.common, 'plotEnable', '0'); 
config.common = fill_struct(config.common, 'NPeaks', '5');
config.common = fill_struct(config.common, 'MinPeakHeight', '2.5');
config.common = fill_struct(config.common, 'MinPeakDistance', '5');
config.common = fill_struct(config.common, 'mainFramesNumber', '2');
config.common = fill_struct(config.common, 'additionalFramesNumber', '1');
config = fill_struct(config, 'delta', '10');
config = fill_struct(config, 'step', '0.5');

frequencyNominal = file.frequencyNominal;

plotEnable = str2num(config.common.plotEnable);
delta = str2num(config.delta);	%  frequency search range, [%]
step = str2num(config.step);      % frequency search step, [%]
mainFramesNumber = str2num(config.common.mainFramesNumber); 
additionalFramesNumber = str2num(config.common.additionalFramesNumber);
nPeaks = str2num(config.common.nPeaks);
minPeakHeight = str2num(config.common.minPeakHeight);
minPeakDistance = str2num(config.common.minPeakDistance);

%% ___________________________ Main Frames ____________________________ %%

 % Draw an interference pattern for the first frames and check possible
 % peaks on it. If there are a lot of 
 for i=1:1:mainFramesNumber
    frequencyFrame = getSmoothedSpectrumFrame(file, frequencyNominal*i, delta, step);
    frequencyFramesTable(i,:) = frequencyFrame/ max(frequencyFrame);
 end

% Get first interference frame from frequencyFrame1 & frequencyFrame2
frequencyFrameResult1 = prod(frequencyFramesTable,1);
f_rough = frequencyNominal*(1-delta/100):frequencyNominal*(step/100):frequencyNominal*(1+delta/100);
[frequencyMagnitude1, frequencyIndex1] = findpeaks(frequencyFrameResult1, 'SortStr','descend','NPeaks', nPeaks, 'MinPeakHeight', minPeakHeight*rms(frequencyFrameResult1),'MinPeakDistance',minPeakDistance);

frequenciesNumber = length(frequencyIndex1);
if frequenciesNumber == 1
    frequencyResult1 = f_rough(frequencyIndex1);
    frequencyProbability1 = 100;
elseif frequenciesNumber<=4 && frequenciesNumber>1
    baseProbability = 100/frequenciesNumber*ones(1,frequenciesNumber); % every peak has this probability
    probabilityCoef = baseProbability(1,1)/sum(frequencyMagnitude1,2);
    frequencyProbability1 = baseProbability + probabilityCoef*frequencyMagnitude1;
    frequencyResult1 = f_rough(frequencyIndex1);  
else
    frequencyResult1 = NaN(1);
    frequencyProbability1 = 0; 
end


%% ____________________________ Additional Frames _____________________ %%
% if there are first and second, then look for the third one
if additionalFramesNumber > 0 && nnz(~isnan(frequencyResult1))>0
    for i = mainFramesNumber+1:1:(mainFramesNumber + additionalFramesNumber)
        [~, frequencyFrame] = getSmoothedSpectrumFrame(file, i*frequencyNominal, delta, step);
        frequencyFramesTable(i,:) = frequencyFrame/ max(frequencyFrame);
    end
    frequencyFrameResult = prod(frequencyFramesTable);
    [frequencyMagnitude, frequencyIndex] = findpeaks(frequencyFrameResult,'SortStr','descend', 'NPeaks', nPeaks, 'MinPeakHeight', minPeakHeight*rms(frequencyFrameResult),'MinPeakDistance',minPeakDistance);

    frequenciesNumber = length(frequencyIndex);
    if frequenciesNumber == 1
        frequencyResult = f_rough(frequencyIndex1);
        frequencyProbability = 100;
    elseif frequenciesNumber<=4 && frequenciesNumber>1
        baseProbability = 100/frequenciesNumber*ones(1,frequenciesNumber); % every peak has this probability
        probabilityCoef = baseProbability(1,1)/sum(frequencyMagnitude,2);
        frequencyProbability = baseProbability + probabilityCoef*frequencyMagnitude;
        frequencyResult = f_rough(frequencyIndex);  
    else
        frequencyResult = frequencyResult1;
        frequencyMagnitude = frequencyMagnitude1; 
        frequencyFrameResult = frequencyFrameResult1;
        frequencyProbability = frequencyProbability1;
    end

else
    frequencyFrameResult = frequencyFrameResult1;
    frequencyMagnitude = frequencyMagnitude1;
    frequencyIndex = frequencyIndex1;
    frequencyResult = frequencyResult1;
    frequencyProbability = frequencyProbability1;
end

%% _________________________ PLOT RESULTS _____________________________ %%

if plotEnable == 1
    subplotsNumber = length(frequencyFramesTable(:,1));
    figure
    for i = 1:1:subplotsNumber
        subplot(subplotsNumber+1,1,i),plot(f_rough,frequencyFramesTable(i,:));
        xlabel('Frequency, Hz'); title(['Normolized ',num2str(i),' frame']);
    end
    subplot(subplotsNumber+1,1,subplotsNumber+1),plot(f_rough,frequencyFrameResult);
    xlabel('Frequency, Hz'); title('Normolized Interference');
    
    hold on;
    stem(f_rough(frequencyIndex),frequencyMagnitude)
    hold off;
end
  
end
    
function [peakEnergyVector, maxFrequecy] = getSmoothedSpectrumFrame(file, centralFrequency, percentRange, percentRangeStep)
       
    highFreq = max(centralFrequency(:))*1.3;          % high freq of the cut-off inner signal

    [ signal, f, df ] = cutAndInterpolate(file, centralFrequency, highFreq );    % cut and interpolate inner using spline
   
    pointRange = round((percentRange/100)*(centralFrequency/df));

    centralPoint = pointRange;              % the center of the subframe to analyze
    frameLength = 2*centralPoint;           % frame length 

    subFramesNumber = floor(percentRange/percentRangeStep);        % one-side windows count to analize pulse (total amount = 2*winCnt+1)

    frameStep = ceil(frameLength/(2*subFramesNumber+1))-1;
    tempStep = 1; 
    peakRange = [];

    for i = 1:1:(2*subFramesNumber+1)
        peakRange(i,:) =  tempStep : (i*frameStep)+1;
        tempStep = (i*frameStep)+1;
    end        

%% --------------   INITIALS ----------------------%%
    defectFreqLocations = round(centralFrequency/df);        % shaft freq locations vector ( freq ---> position)
    frameTable = zeros(1, frameLength);     % peaks table  
    peakEnergyVector = zeros(1, subFramesNumber*2+1);
    max_pos = zeros(1, 4);
    peakEnergyMax = zeros(1,length(peakRange(1,:)));

%% ---------------------  MAIN BODY ------------------- %%

    frameTable(1, 1:frameLength) = signal((defectFreqLocations(1)-(centralPoint)):(defectFreqLocations(1)+(centralPoint)-1)); % copy signal part to frameTable

    for j = 1:1:subFramesNumber*2+1
            peakEnergyVector(1,j) = sum(frameTable(1,peakRange(j,:)));                
    end

    [~,originalpos] = sort( peakEnergyVector(1,:), 'descend' );
    max_pos(1,:)=originalpos(1:4); % find positions of windows with hggh energy 

          peakEnergyMax(1,:) = frameTable(1,peakRange(max_pos(1,1),:)); % get largest energy window to approximate a given frequency
           [~, idx(1)]= max(smooth(peakEnergyMax(1,:),3));  
           maxFrequecy = f((defectFreqLocations(1)-(centralPoint)+peakRange(max_pos(1,1),idx(1))));
end