%function calculating normalized rms deviation of piece-wise linear fit
%built using 'epoches' split
%normalization happens with regard of plane linear fit error
%according to Zalyapin paper/ see code
function [error_fit] = get_norm_error(xyArr, epoches)
   
    num_epoches = numel(epoches);
    p=polyfit(xyArr(:,1),xyArr(:,2),1);
    linearfit=polyval(p,xyArr(:,1));
    error_zero= sqrt(sum((xyArr(:,2)-linearfit).^2));

    error_fit = 0;
    for i=1:num_epoches-1
        curr_interval = epoches(i):epoches(i+1);
        p=polyfit(xyArr(curr_interval,1),xyArr(curr_interval,2),1);
        linearfit=polyval(p,xyArr(curr_interval,1));
        error_fit=error_fit + sum((xyArr(curr_interval,2)-linearfit).^2);
    end
    error_fit=sqrt(error_fit);
    error_fit = -log(error_fit/error_zero)/(num_epoches-2);
end