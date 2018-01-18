%finction splits the interval to a set of linearly approximated
%number of subsegments 
function [epoches] = findepochs(xyArr, max_num_of_intervals)

    arrlength = numel(xyArr(:,1));
    epoches = [1; arrlength];
    nCount=0;
    %find splitting 
    while numel(epoches)<max_num_of_intervals + 1
        currEpochesNum = numel(epoches);
        newepoches = [];
        for i=1:currEpochesNum-1
            newepoches = findmaxmin(xyArr(epoches(i):epoches(i+1),:));
            if(i>1)
                newepoches = newepoches + epoches(i)-1;
            end
            epoches = vertcat(epoches,newepoches);
        end
        epoches = sort(epoches);
        nCount = nCount+1;
        if(nCount> 10)
            %disp('reached');
            break
        end
    end
end
