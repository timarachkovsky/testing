function [finalepoches,rms_error] = findapproximation(xyArr, max_num_of_intervals)

    epochs = findepochs(xyArr, max_num_of_intervals);
    numepoch = numel(epochs)-2;
    %get all possible combinations
    combin_list = cell((numepoch)^2-1,1);    
    combin_list{1,1} = epochs;
    for i=2:numepoch+1
        combin_list{i,1} = [epochs(1); epochs(i); epochs(numepoch+2)];
    end
    nCount = numepoch+2;
    for i=2:numepoch-1
        combis = combnk(epochs(2:numepoch+1),i);
        [sizer sizec] = size(combis);
        for j=1:sizer
          combin_list{nCount,1} = [epochs(1);combis(j,:)'; epochs(numepoch+2)]; 
          nCount = nCount +1;
        end
    end
    numepoch = length(combin_list);
    error_list = zeros(numepoch,1);
    for i=1:numepoch
        error_list(i) = get_norm_error(xyArr,combin_list{i,1});    
    end
    [~,indMax] = max(error_list);
    finalepoches = combin_list{indMax,1};
    rms_error = get_rms(xyArr,finalepoches);
end
