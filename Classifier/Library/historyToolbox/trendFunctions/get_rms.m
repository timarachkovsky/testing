%function calculating rms deviation of piece-wise linear fit
%built using 'epoches' split
function [error_fit] = get_rms(xyArr, epoches)
   
    num_epoches = numel(epoches);
   
    error_fit = 0;
    for i=1:num_epoches-1
        curr_interval = epoches(i):epoches(i+1);
        p=polyfit(xyArr(curr_interval,1),xyArr(curr_interval,2),1);
        linearfit=polyval(p,xyArr(curr_interval,1));
        error_fit=error_fit + sum((xyArr(curr_interval,2)-linearfit).^2);
    end
    error_fit=sqrt(error_fit);   
end