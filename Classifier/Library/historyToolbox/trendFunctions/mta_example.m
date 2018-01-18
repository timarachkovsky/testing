  % example showing the usage of multi-scale trend analysis;
  % first it generates noisy series consisting of 
  % combination of multiple linear trends (in this case equally spaced
  % for simplicity, but in general it will work with any)
    
  % parameters of noisy multi-trend series
    
  nNumberOfTrends = 3;  %number of trends
  nTrendLengthMin = 3;  %minimum trend length (in points)
  nTrendLengthMax = 5; %maximum trend length (in points)
  %range of slopes
  dSlopeMin = 0.8; %minimum slope of the trend 
  dSlopeMax = 1.8; %maximum slope of the trend 
  %can slope be negative?
  bNegativeSlope = true;
  nNoiseSD = 5; %SD of normally distributed noise
  
    %% now let's generate some artificial series
  % {
  %signal array with noise
  xyArr = [];
  %signal array without noise
  xyArrNoNoise = [];
  %if you want to compare slopes outcome
  dSlopesGroundTruth = zeros(nNumberOfTrends,1);
  for i=1:nNumberOfTrends 
    nTrendLength = randi(nTrendLengthMax-nTrendLengthMin,1)+nTrendLengthMin;
    xyTrend = zeros(nTrendLength,3);
    xyTrend(:,1) =(0:(nTrendLength-1))';
    dSlope = dSlopeMin + (dSlopeMax-dSlopeMin)*rand(1);
    if(bNegativeSlope)
        dSlope = dSlope*2*(randi(2,1)-1.5);
    end
    dSlopesGroundTruth(i)=dSlope;
    %generate line
    xyTrend(:,2) = xyTrend(:,1)*dSlope;
    %add noise
    xyTrend(:,3)=xyTrend(:,2)+normrnd(0,nNoiseSD,nTrendLength,1);
    if(i==1)
        xyArr = xyTrend(:,3);
        xyArrNoNoise = xyTrend(:,2);
    else
        xyTrend(:,3) = xyTrend(:,3)+xyArrNoNoise(end); 
        xyArr = vertcat(xyArr, xyTrend(:,3));
        xyTrend(:,2) = xyTrend(:,2)+xyArrNoNoise(end); 
        xyArrNoNoise = vertcat(xyArrNoNoise, xyTrend(:,2));

    end
  end
  xyArr = horzcat((0:size(xyArr,1)-1)',xyArr);
  xyArrNoNoise = horzcat((0:size(xyArrNoNoise,1)-1)',xyArrNoNoise);
  % }
  
  %ok, done. let's do MTA
%   [optimal_epoches, slopes, xyApprox] = mta_analysis(xyArr);
% % save('data.mat','xyArr');
% load('data.mat');
  [optimal_epoches, slopes, xyApprox] = mta_analysis(xyArr,15);
  
  % }
    
    
  %let's build plots
  %noisy signal
  plot(xyArr(:,1),xyArr(:,2),'b');
  hold all
  %signal without noise
  plot(xyArrNoNoise(:,1),xyArrNoNoise(:,2),':r','LineWidth',2);
  hold all
  %approximation
  nSlopesFound = length(slopes);
  for i=1:nSlopesFound
      rangeApprox = ((optimal_epoches(i)+i-1):(optimal_epoches(i+1)+i-1))';      
      %plot(xyArrNoNoise(rangeApprox,1),xyArrNoNoise(rangeApprox,2),':r','LineWidth',2);
       
      plot(xyApprox(rangeApprox,1),xyApprox(rangeApprox,2),'Color',[0 0.5 0],'LineWidth',2);
      hold all
  end
  hold off
  
  
    
    
    