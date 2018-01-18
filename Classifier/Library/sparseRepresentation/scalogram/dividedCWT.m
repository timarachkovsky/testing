
% Developer:  ASLM 
% version: v1.1
% date: 07.08.16

% version: v1.2 - scales vector reshape for "parfor" - Ratgor, 2016-10-29

function cwtCoefs = dividedCWT(file, scales, config)

%% _______________________ Default Parameters __________________________ %%
    if nargin < 3 
        config = [];
    end
%     config = fill_struct(config, 'parpoolCWT','1');
    config = fill_struct(config, 'waveletName','mexh_morl');
    config = fill_struct(config, 'parpoolEnable','0');

%     config.parpoolCWT = str2double(config.parpoolCWT);
    config.parpoolEnable = str2double(config.parpoolEnable);
    waveletName = config.waveletName;

%% _______________________ Prep. calculations __________________________ %%
    signal = file.signal;

    if config.parpoolEnable    
    % reshaping scales vector (4example: 123456789 to 147,258,369)
        signalVectorLength = length(signal);
        scalesVectorLength = length(scales);
        localCluster = parcluster('local');
        numWorkers = localCluster.NumWorkers;
        reshapedScalesLength = floor(scalesVectorLength/numWorkers);
        reshapingScalesPattern = ( 0:numWorkers:(numWorkers*(reshapedScalesLength-1)) );
        missedScalesPattern = (reshapedScalesLength*numWorkers+1:scalesVectorLength);

        coefs = zeros(numWorkers, reshapedScalesLength, signalVectorLength);
        cwtCoefs = zeros(scalesVectorLength, signalVectorLength);
        reshapedScales = zeros(reshapedScalesLength, numWorkers);

%% _______________________ Main Calculations __________________________ %%

        % parfor cause an ERROR here ("Subscripted assignment dimension mismatch")
        %If we use parfor, reshapedScales fills by samples of scales on i position.
        for i = 1:1:numWorkers
            reshapedScales(:,i) = scales(reshapingScalesPattern+i);
        end % (1v2) it takes only 0.001 seconds for 4x74 double on 1 worker

        parfor i = 1:1:numWorkers
%         for i = 1:1:numWorkers
            coefs(i,:,:) = cwt(signal,reshapedScales(:,i),waveletName);
        end
        % (1v2) now it takes 112 seconds for 4x74x879999 double on 4 workers
        % (1v1) previously it took 150 seconds for 299x219999 double on 4 workers
        
        % parfor cause an ERROR here ("Subscripted assignment dimension mismatch")
        for i = 1:1:numWorkers
            cwtCoefs(reshapingScalesPattern+i,:) = coefs(i,:,:);
        end % (1v2) now it takes 2 seconds for 4x74x879999 double on 1 worker
        
        % some last coefficients may have been missed with scales resharping
        if ~isempty(missedScalesPattern)
            cwtCoefs(missedScalesPattern,:) = cwt(signal,scales(missedScalesPattern),waveletName);
        end
        % (1v2) it takes 0.1 seconds for 3x879999 double on 1 worker
    else
       cwtCoefs = cwt(signal,scales,waveletName); %If parpool is not enabled, we count all coefficients at a time. 
    end
  
end

