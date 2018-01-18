
% function finds max and min value at the interval
% after substracting linear fit.
% if max or min point turns out to be boundary point, it is omitted.
% if both max and min points are at boundary,instead of linear fit,
% the line across boundary points is subtracted. see code for details.
function [epoch] = findmaxmin(xyArr)
    p=polyfit(xyArr(:,1),xyArr(:,2),1);
    arrlength = numel(xyArr(:,2));
    linearfit=polyval(p,xyArr(:,1));
    diff=xyArr(:,2)-linearfit;
    %find min and max
    [~,indmin] = min(diff);
    [~,indmax] = max(diff);
    epoch=[];
    %let's check it is not a border points
    if(indmin > 2 && indmin < arrlength-1)
        epoch=vertcat(epoch, indmin);
    end
    if(indmax > 2 && indmax < arrlength-1)
        epoch=vertcat(epoch, indmax);
    end

    %special case
    if(numel(epoch)==0)
     %let's approximate line with points at the ends
     %line parameters
     slope = (xyArr(arrlength,2)-xyArr(1,2))/(xyArr(arrlength,1)-xyArr(1,1));
     b= xyArr(1,2)-slope*xyArr(1,1);
     p=[slope b];
     %okey, now let's repeat the whole procedure 
     linearfit=polyval(p,xyArr(:,1));
     diff=xyArr(:,2)-linearfit;
     %find min and max
     [~,indmin] = min(diff);
     [~,indmax] = max(diff);
     epoch=[];
     %let's check it is not a border points
     if(indmin >2 && indmin < arrlength-1)
        epoch=vertcat(epoch, indmin);
     end
     if(indmax > 2 && indmax < arrlength-1)
        epoch=vertcat(epoch, indmax);
     end
     %okay, very special case. reached the line
     %gonna return nothing!
     %but display warning
     if(numel(epoch)==0)
        %error('Full line approximation is reached!');
     end
    end
end
