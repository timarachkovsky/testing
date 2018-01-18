function [level] = find_optimal_level(x,y)
%approximate line by points at boundary
arrlength=numel(y);
rms_array = zeros(arrlength-2,1);
for i=2:arrlength-1
    %slope = (y(i)-y(1))/(x(i)-x(1));
    %b = y(1)-slope*x(1); 
    %p1=[slope b];
    p1=polyfit(x(1:i),y(1:i),1);
    %slope = (y(arrlength)-y(i))/(x(arrlength)-x(i));
    %b = y(arrlength)-slope*x(arrlength); 
    %p2=[slope b];
    p2=polyfit(x(i:arrlength),y(i:arrlength),1);
    linearfit=polyval(p1,x(1:i));    
    diff=y(1:i)-linearfit;
    rms = sum(diff.^2);
    linearfit=polyval(p2,x(i:arrlength));    
    diff=y(i:arrlength)-linearfit;
    rms = rms + sum(diff.^2);
    rms_array(i-1) = sqrt(rms);
end

[~,indmin] = min(rms_array);
level = indmin+1;

end