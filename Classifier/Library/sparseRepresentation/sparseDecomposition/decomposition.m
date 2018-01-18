    %Algorithm: 
    %   The implementation pre-computes cross-correlations between the 
    %   basis and y using FFT-based convolution and does not perform 
    %   convolutions in the main loop. It also uses a 3-level tree to 
    %   search for the current maximal correlation, making each iteration
    %   O(sqrt(m)) rather than the usual O(mp). 
    %   
    %   The implementation thus uses computational tricks similar to those used
    %   in MPTK. While according to Krstulovic and Gribonval (2006) MPTK 
    %   iterations are O(log(m)) << O(sqrt(m)), in practice at the 
    %   O(sqrt(m)) level things become memory bound rather than CPU-bound.
    %   Thus this implementation is about as efficient as one could
    %   expect out a pure m-code MP implementation based on our current 
    %   understanding of MP algorithms.
    %
    %History:
    %   08/08/2011: Added deadzone option
    %   04/08/2011: Tweaked performance for large signals/bases
    %   03/08/2011: Initial release
    %

    %Modification by ASLM
    %   14/07/2016: Speed-up and restructured function
    
    %Modification by ASLM
    %   10/03/2017: Measurement mode was added
   
function [restored,sparsePeaks,sparseModes,basis, measurementResult] = decomposition(file, config)

if nargin<2
   config = []; 
end
    
%% ____________________ Default Parameters ____________________________ %%

   config = fill_struct(config, 'plotEnable','0');    % Plotting enable   
   config = fill_struct(config, 'debugModeEnable','0');    % Plotting enable   
   config = fill_struct(config, 'plotVisible','on');    % Plotting enable   
   config = fill_struct(config, 'nonnegativeEnable', '0');  % Only oisitive residue
                                                        % usage enable
   config = fill_struct(config, 'maxIterationsNumber', '5000');   %Max decomposition
                                                                % iterations
                                                                % number
   config = fill_struct(config, 'minDelta', '0'); % 
   config = fill_struct(config, 'deadzone', '0'); % Zone around the decomposition
                                                % point free of the next
                                                % decomposition iterations
                                                
    config = fill_struct(config, 'measurementEnable','0');
    config = fill_struct(config, 'measurementPointsNumber', '50'); % use N points to calculate decomposition mentrics
    
    if ischar(config.plotEnable)
        config.plotEnable = str2double(config.plotEnable);
    end
    if ischar(config.debugModeEnable)
        config.debugModeEnable = str2double(config.debugModeEnable);
    end
    config.nonnegativeEnable = str2double(config.nonnegativeEnable);
    if ischar(config.maxIterationsNumber)
%         config.maxIterationsNumber = str2double(config.maxIterationsNumber);
        config.maxIterationsNumber = str2num(config.maxIterationsNumber);
    end
    config.minDelta = str2double(config.minDelta);
    config.deadzone = str2double(config.deadzone);
    config.measurementPointsNumber = str2double(config.measurementPointsNumber);
    config.measurementEnable = str2double(config.measurementEnable);
    
    % TEST ...
    measurementResult = [];
    iterationsVector = [];
    if config.measurementEnable == 1
        iterationsVector = quadraspace(1,config.maxIterationsNumber,config.measurementPointsNumber,1);
        index = 1;
        currentIteration = round(iterationsVector(index));
    end
    % ... TEST
                                                             
   y = file.signal(:)';     % Signal to decompose
   basis = file.basis;      % Basis to decompose in                     
   
%% ------------------------- Calculation ------------------------------- %%
    
    maxr2 = .9999;
    feedbackFrequency = 250;
    r2CheckFrequency  = 250;
    
    %Scale the basis to have sum(B.^2)
    scales = 1./sqrt(sum(basis.^2));
    basis = bsxfun(@times,basis,scales)';
    
    %Pad y with zeros to avoid edge issues
    padsize = size(basis,2);
    y = [zeros(1,padsize),y,zeros(1,padsize)];
    
    %Compute the convolution of y with each element in B
%     if size(B,1) > 100
        C = myconvnfft(basis(:,end:-1:1),y);
%     else
%         C = conv2(B(:,end:-1:1),y);
%     end
    C = C(:,(size(basis,2)+1)/2 + (0:length(y)-1));
    
    %Precompute the convolution of each basis function with the other basis
    %functions
    P = zeros(size(basis,1),size(basis,2)*2-1,size(basis,1));
    for ii = 1:size(basis,1)
        P(:,:,ii) = myconvnfft(basis(:,end:-1:1),basis(ii,:));
    end
    
    %Don't add basis function within the padding
    Cmask = false(1,length(y));
    Cmask(1:size(basis,2)) = true;
    Cmask(end-size(basis,2)+1:end) = true;
    
    C(:,Cmask) = 0;
    
    %The max operation only needs to be performed once per time point
    %This is a big saving computationally when there are many basis
    %functions
    if config.nonnegativeEnable
        Cmax = max(C);
    else
        Cmax = max(abs(C));
    end
    
    %Similarly, it's wasteful to do a full search every iteration. Ideally
    %you would use a binary tree to do the search for the max. This is an
    %alternative adapted to Matlab's data structures
    nsqrt = ceil(sqrt(length(Cmax)));
    Cmaxpad = nsqrt^2-length(Cmax);
    Cmax2 = max(reshape([Cmax,zeros(1,Cmaxpad)],nsqrt,nsqrt));
    
    restored = zeros(1,length(y));
    sparsePeaks = zeros(size(basis,1),length(y));
    sparseModes = zeros(size(C));
    
    rgdelta  = (1:size(basis,2));
    rgdelta  = rgdelta - mean(rgdelta);
    
    rgdelta2 = (1:size(basis,2)*2-1);
    rgdelta2 = rgdelta2 - mean(rgdelta2);
    
    ii = 1;
    sy2 = sum(y.^2);
    
    while ii <= config.maxIterationsNumber        
        %Pick the best basis, displacement
        %Find the max of Cmax2
        [themax,maxsqrt] = max(Cmax2);
        
        if themax^2 < config.minDelta
            %Time to go
            fprintf('Best delta decreases SSE by less than mindelta, ending\n');
            break;
        end
        
        rg = nsqrt*(maxsqrt-1) + (1:nsqrt);
        if rg(end) > length(Cmax)
            rg = rg(rg <= length(Cmax));
        end
        
        %Find the max of the relevant subset of Cmax
        [~,maxoffset] = max(Cmax(rg));
        %Find the max temporal offset
        maxj = (maxsqrt-1)*nsqrt + maxoffset;
        
        if config.nonnegativeEnable
            [~,maxi] = max(C(:,maxj));
        else
            [~,maxi] = max(abs(C(:,maxj)));
        end
        
        %update ws
        sparsePeaks(maxi,maxj) = sparsePeaks(maxi,maxj) + C(maxi,maxj);
        
        %Update r incrementally
        rg = maxj + rgdelta;
        delta = C(maxi,maxj)*basis(maxi,:);
        
        restored(rg) = restored(rg) + delta;
        sparseModes(maxi,rg) = sparseModes(maxi,rg) + delta;
        
        %Update C so that it reflects the correlation of y-r and B
        rg2 = maxj + rgdelta2;
        D = C(:,rg2) - reshape(C(maxi,maxj)*P(:,:,maxi),size(P,1),size(P,2));
        
        
        %Update Cmax
        if config.nonnegativeEnable
            Cmax(rg2) = max(D);
        else
            Cmax(rg2) = max(abs(D));
        end
        
        C(:,rg2) = D;
        
        if config.deadzone > 0
            Cmask(maxj-config.deadzone+1:maxj+config.deadzone-1) = 1;
            C(:,rg2) = bsxfun(@times,C(:,rg2),(~Cmask(rg2)));
            Cmax(rg2) = Cmax(rg2).*(~Cmask(rg2));
        end
        
        if rg2(end) > length(y) - size(basis,2) -1 || ...
           rg2(1) < size(basis,2) +1
            C(:,Cmask) = 0;
            Cmax(Cmask) = 0;
        end
        
        %Update relevant parts of Cmax2
        lopos = ceil(rg2(1)/nsqrt);
        hipos = ceil(rg2(end)/nsqrt);
         
        %select relevant portion of Cmax
        if hipos*nsqrt <= length(Cmax)
            Cmax2(lopos:hipos) = max(reshape(Cmax( ((lopos-1)*nsqrt+1):(hipos*nsqrt)),nsqrt,hipos-lopos+1));
        else
            %Pad with zeros
            A = Cmax( ((lopos-1)*nsqrt+1):end);
            A = [A,zeros(1,(hipos-lopos+1)*nsqrt-length(A))];
            Cmax2(lopos:hipos) = max(reshape(A,nsqrt,hipos-lopos+1));
        end
        
        
        %Give some feedback
        if mod(ii,feedbackFrequency) == 0
            fprintf('Iteration %d\n',ii);
        end
        
        %Check if R^2 > maxr2
        if maxr2 < 1 && mod(ii,r2CheckFrequency) == 0
            r2 = 1-sum((y-restored).^2)/sy2;
            if r2 > maxr2
                fprintf('Max R^2 reached at iteration %d\n',ii);
                break;
            end
        end
        
        if config.measurementEnable == 1
            if ii == currentIteration
               swdSignal = restored(padsize+1:end-padsize)';
               if isempty(measurementResult)
                    measurementResult.table(1,:) = swdMetrics(file,swdSignal);
               else
                    measurementResult.table(end+1,:) = swdMetrics(file,swdSignal);
               end
               index = index + 1;
               if index <= length(iterationsVector)
                    currentIteration =  round(iterationsVector(index));
               end
            end
        end

        ii = ii + 1;
    end
    
    % Write measurements to @measurementResult struct
    if config.measurementEnable == 1
        measurementResult.iterationsVector = iterationsVector;
        measurementResult.restored.kurtosis = measurementResult.table(:,1);
        measurementResult.restored.rms = measurementResult.table(:,3);
        measurementResult.restored.peak = measurementResult.table(:,5);
        measurementResult.restored.peakFactor = measurementResult.table(:,7);
        measurementResult.restored.crestFactor = measurementResult.table(:,9);
        
        measurementResult.residue.kurtosis = measurementResult.table(:,2);
        measurementResult.residue.rms = measurementResult.table(:,4);
        measurementResult.residue.peak = measurementResult.table(:,6);
        measurementResult.residue.peakFactor = measurementResult.table(:,8);
        measurementResult.residue.crestFactor = measurementResult.table(:,10);
    end
    %Rescale ws to original scale and remove padding
    sparsePeaks = bsxfun(@times,sparsePeaks(:,padsize+1:end-padsize)',1./scales);
%     ws = ws(:,padsize+1:end-padsize)';
    restored = restored(padsize+1:end-padsize)';
    sparseModes = sparseModes(:,padsize+1:end-padsize)';
    
    
%% _______________________ Plot Results _______________________________ %%
    if config.plotEnable && config.debugModeEnable
        
        dt = 1/file.Fs;
        tmax = length(file.signal)*dt;
        t = 0:dt:tmax-dt;
        
        figure('Color','w','Visible',config.plotVisible);
        plot(t,[file.signal,restored]);
        xlabel('Time, s');
        ylabel('Signal');
        legend('Original signal','Sparse Representation');
        title( ['Sparse Wavelet Decomposition. Iterations Number = ',num2str(config.maxIterationsNumber) ]); grid on;
        
        % Close figure with visibility off
        if strcmpi(config.plotVisible, 'off')
            close
        end
        
    end
end

%Convolution of a vector and a matrix
%uses the same algo as Bruno Luong's convnfft
function R = myconvnfft(M,v)
    nsize = size(M,2)+length(v)-1;
    vf = fft(v,nsize);
    Mf = fft(M,nsize,2);
    %Add pad signals to the summary length. Get FFT across 2-nd dimention.
    R  = ifft(bsxfun(@times,vf,Mf),[],2);
end

% SWDMETRICS function returns table result, where every array has the
% specific structure:
% 1.swdKurtosis,2.resKurtosis,3.swdRms, 4.resRms,5.swdPeak,6.swdPeak,
% 7.swdPeakFactor,8.resPeakFactor,9.swdCrestFactor,10.swdCrestFactor
function [result] = swdMetrics(file,r)
    
    residue = file.signal - r;
    result(1) = kurtosis(r); 
    result(2) = kurtosis(residue); 

    result(3) = rms(r);
    result(4) = rms(residue);
    
    result(5) = max(abs(r));
    result(6) = max(abs(residue));
    
    result(7) = result(5)/result(3);
    result(8) = result(6)/result(4);
    
    file.signal = r;
    result(9) = crestFactor(file);

    file.signal = residue;
    result(10) = crestFactor(file);
            
end