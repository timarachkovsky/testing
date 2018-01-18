function [xyApprox,slopes,b_coeff] = getapproximation(xyArr, epoches)
    
    arrlength = numel(xyArr(:,1));
    currEpochesNum = numel(epoches);
    xyApprox = zeros(arrlength+currEpochesNum-2,2);
    slopes = zeros(currEpochesNum-1,1);
    b_coeff = zeros(currEpochesNum-1,1);
    
    for i=1:currEpochesNum-1
        curr_interval = epoches(i):epoches(i+1);
        p=polyfit(xyArr(curr_interval,1),xyArr(curr_interval,2),1);
        slopes(i)=p(1);
        b_coeff(i)=p(2);
        linearfit=polyval(p,xyArr(curr_interval,1));
        curr_approx_interval =(epoches(i)+i-1):(epoches(i+1)+i-1); 
        xyApprox(curr_approx_interval,:)=[xyArr(curr_interval,1) linearfit];
    end

end