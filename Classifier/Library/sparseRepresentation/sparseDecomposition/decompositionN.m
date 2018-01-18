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
    
    %Modification by ASLM 
    %   28/03/2017: Added N point decomposition
   
function [Result] = decompositionN(file, config)

if nargin<2
   config = []; 
end
Result = [];
%% ____________________ Default Parameters ____________________________ %%

    config = fill_struct(config, 'nonnegativeEnable', '0'); % Only oisitive residue
                                                            % usage enable
    config = fill_struct(config, 'signalsNumber','1');  % Number of signals to be restored
    config = fill_struct(config, 'iterationsVector', '100,250');    % Vector of the number of iterations for decomposition
                                                                   
    config = fill_struct(config, 'minDelta', '0');  % 
    config = fill_struct(config, 'deadzone', '0');  % Zone around the decompositin
                                                    % point free of the next
                                                    % decomposition iterations
                                                
    config.signalsNumber = str2double(config.signalsNumber);
    config.nonnegativeEnable = str2double(config.nonnegativeEnable);
    config.minDelta = str2double(config.minDelta);
    config.deadzone = str2double(config.deadzone);
   
    % N-point decomposition parameters ...
    iterationsVector = round(sort(str2num(config.iterationsVector),'ascend'));
    maxIteationsNumber = max(iterationsVector); 
    index = 1;
    currentIteration = iterationsVector(index);
    % ... N-point decomposition parameters
                                                             
   y = file.signal(:)';     % Signal to decompose
   B = file.basis;      % Basis to decompose in                     
   
%% ------------------------- Calculation ------------------------------- %%
    
    maxr2 = .9999;
    feedbackFrequency = 250;
    r2CheckFrequency  = 250;
    
    %Scale the basis to have sum(B.^2)
    scales = 1./sqrt(sum(B.^2));
    B = bsxfun(@times,B,scales)';
    
    %Pad y with zeros to avoid edge issues
    padsize = size(B,2);
    y = [zeros(1,padsize),y,zeros(1,padsize)];
    
    %Compute the convolution of y with each element in B
%     if size(B,1) > 100
        C = myconvnfft(B(:,end:-1:1),y);
%     else
%         C = conv2(B(:,end:-1:1),y);
%     end
    C = C(:,(size(B,2)+1)/2 + (0:length(y)-1));
    
    %Precompute the convolution of each basis function with the other basis
    %functions
    P = zeros(size(B,1),size(B,2)*2-1,size(B,1));
    for ii = 1:size(B,1)
        P(:,:,ii) = myconvnfft(B(:,end:-1:1),B(ii,:));
    end
    
    %Don't add basis function within the padding
    Cmask = false(1,length(y));
    Cmask(1:size(B,2)) = true;
    Cmask(end-size(B,2)+1:end) = true;
    
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
    
    r = zeros(1,length(y));
    ws = zeros(size(B,1),length(y));
    ss = zeros(size(C));
    
    rgdelta  = (1:size(B,2));
    rgdelta  = rgdelta - mean(rgdelta);
    
    rgdelta2 = (1:size(B,2)*2-1);
    rgdelta2 = rgdelta2 - mean(rgdelta2);
    
    ii = 1;
    sy2 = sum(y.^2);
    
    while ii <= maxIteationsNumber        
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
        ws(maxi,maxj) = ws(maxi,maxj) + C(maxi,maxj);
        
        %Update r incrementally
        rg = maxj + rgdelta;
        delta = C(maxi,maxj)*B(maxi,:);
        
        r(rg) = r(rg) + delta;
        ss(maxi,rg) = ss(maxi,rg) + delta;
        
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
        
        if rg2(end) > length(y) - size(B,2) -1 || ...
           rg2(1) < size(B,2) +1
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
            fprintf('Iteration %d\n',ii)
        end
        
        %Check if R^2 > maxr2
        if maxr2 < 1 && mod(ii,r2CheckFrequency) == 0
            r2 = 1-sum((y-r).^2)/sy2;
            if r2 > maxr2
                fprintf('Max R^2 reached at iteration %d\n',ii);
                break;
            end
        end
        
        if ii == currentIteration
            Result(index).sparseModes = ss(:,padsize+1:end-padsize)';
            Result(index).sparsePeaks = bsxfun(@times,ws(:,padsize+1:end-padsize)',1./scales);
            Result(index).iterationsNumber = iterationsVector(index);
            
            if config.signalsNumber == 1
                Result(index).sparseSignal = sum(Result(index).sparseModes,2);
            else
                subBasisLength = round(size(B,1)/config.signalsNumber);
                for i = 1:1:config.signalsNumber
                   subSparseModes = Result(index).sparseModes(:,(i-1)*subBasisLength+1:i*subBasisLength); 
                   Result(index).sparseSignal{i,1} = sum(subSparseModes,2);
                   Result(index).basis{i,1} = B((i-1)*subBasisLength+1:i*subBasisLength,:);
                end
                
            end
            
            index = index + 1;
            if index <= length(iterationsVector)
                currentIteration =  round(iterationsVector(index));
            end
        end

        ii = ii + 1;
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
