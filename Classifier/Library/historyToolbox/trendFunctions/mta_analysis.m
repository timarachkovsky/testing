    %% this function is performing multiscale trend analysis of discrete series y(x)
    % according to paper I.Zaliapin et al. Fractals 12. N3 (2004)
    % realization is written by Eugene Katrukha / katpyxa @ gmail.com
    % feel free to write for any comments/mistakes/etc
    % version 1.0.1

    %as an input requires 
    % 1) two column (x and y) array containing function series (required)
    % 2) (optional) relative rms improvement (percentage).
    % In short, this parameter is in control of how precise the fit is
    % going to be. 
    % If adding new trend improves rms difference by less than this percentage
    % from rms of current approximation, decomposition will stop (default value is 5%). 
    % 3) (optional) maximum depth of hierarchical tree (default value is 10)
    % this one characterized 'how deep' approximation gonna go. 
    % 4) (optional) maximum number of secondary trends Nh (default value is 5)

    %output
    % 1)optimal_epoches - array containing indexes of original array,
    % corresponding to optimal 'corner point' (see Zalyapin et al. Biophysical J. 2005)
    % 2) slopes of linear approximation at those segments
    % 3) two column array containing approximation
    
    %example calls:
    %[optimal_epoches, slopes, xyApprox] = mta_analysis(xyseries)
    %[optimal_epoches, slopes, xyApprox] = mta_analysis(xyseries, rel_rms_improvement)
    %[optimal_epoches, slopes, xyApprox] = mta_analysis(xyseries, rel_rms_improvement, max_depth_of_tree, max_num_of_intervals)
    
    %also see mta_example.mat

    %if you want to extract the whole tree or anything intermediate,
    %check the code and feel free to do so

    %%
function [optimal_epoches, slopes, xyApprox] = mta_analysis(varargin)


    if (nargin > 0)
        xyArr= varargin{1};
        if(size(xyArr,2)>size(xyArr,1))
           xyArr = xyArr';
        end
        if(size(xyArr,2)~=2)
            error ('Two dimentional array is required!');
        end    
    else
        error ('No input arguments!');
    end

    %when 
    if (nargin > 1)
        rel_rms_improvement = varargin{2}*0.01;
    else
        rel_rms_improvement = 0.05;
    end
    
    %how deep we want to go for aprroximation
    if (nargin > 2)
        max_depth_of_tree = varargin{3};
    else
        max_depth_of_tree = 10;
    end
    %critical numeric parameters
    if (nargin >3)
        max_num_of_intervals = varargin{4};
    else
        max_num_of_intervals = 5;
    end

    approx_tree=cell(max_depth_of_tree,1);
    rms_tree=zeros(max_depth_of_tree,1);
    segments_number = zeros(max_depth_of_tree,1);
    arrlength = numel(xyArr(:,1));
    epoches=[1; arrlength];
    approx_tree{1,1} = epoches;
    %number of segments
    segments_number(1) = 1;
    rms_tree(1) = get_rms(xyArr,epoches);
    %diving down
    for i=2:max_depth_of_tree
        %previous approximation
        previous_level_epoch = approx_tree{i-1,1};
        currEpochesNum = numel(previous_level_epoch);
        rms_segments = zeros(currEpochesNum-1,1);
        new_epoches=cell(currEpochesNum-1,1);
        %go and split every new segment
        for j=1:currEpochesNum-1
            if(previous_level_epoch(j+1)-previous_level_epoch(j)>2)
                [epoches,rms_segments(j)]=findapproximation(xyArr(previous_level_epoch(j):previous_level_epoch(j+1),:), max_num_of_intervals);
                epoches=epoches+previous_level_epoch(j)-1;
                new_num = numel(epoches);    
                epoches = sort(vertcat(previous_level_epoch,epoches(2:new_num-1)));
                rms_segments(j) = get_rms(xyArr,epoches);
                new_epoches{j,1} = epoches;            
            %cannot split further
            else
                new_epoches{j,1} = previous_level_epoch;
                rms_segments(j) = rms_tree(i-1);
            end
        end
        [~,indMin]=min(rms_segments);
        approx_tree{i,1}=new_epoches{indMin,1};   
        segments_number(i)=numel(new_epoches{indMin,1})-1;   
        rms_tree(i) = rms_segments(indMin);
    end

    rms_plot = rms_tree*(1/rms_tree(1));
   
    %opt_level= find_optimal_level(log(segments_number), log(rms_plot));
    
    %new percentage 10% criteria
    opt_level = 0;
    i=1;
    while opt_level<1
        if(rms_plot(i)-rms_plot(i+1)<rel_rms_improvement)
           opt_level = i; 
        end
        i = i+1;
        if i == length(rms_plot) && opt_level == 0
            opt_level = 1;
            break;
        end
    end   
    
    %disp('optimal segments number:');
    %disp(segments_number(opt_level));
    optimal_epoches = approx_tree{opt_level,1};
    [xyApprox,slopes, b_coeff] = getapproximation(xyArr, optimal_epoches);

    %uncomment following three lines to plot rms vs segments number plot
    %plot(log(segments_number), log(rms_plot), '-o');
    %figure
    %plot(segments_number, rms_plot, '-o');

end