% function [IDX,C,SUMD,K]=best_kmeans(X)
function [K] = best_kmeans(base_obs, config)

% [IDX,C,SUMD,K] = best_kmeans(X) partitions the points in the N-by-P data matrix X
% into K clusters. Rows of X correspond to points, columns correspond to variables. 
% IDX containing the cluster indices of each point.
% C is the K cluster centroids locations in the K-by-P matrix C.
% SUMD are sums of point-to-centroid distances in the 1-by-K vector.
% K is the number of cluster centriods determined using ELBOW method.
% ELBOW method: computing the destortions under different cluster number counting from
% 1 to n, and K is the cluster number corresponding 90% percentage of
% variance expained, which is the ratio of the between-group variance to
% the total variance. see <http://en.wikipedia.org/wiki/Determining_the_number_of_clusters_in_a_data_set>
% After find the best K clusters, IDX,C,SUMD are determined using kmeans
% function in matlab.

% dim=size(base_obs);
% default number of test to get minimun under differnent random centriods
obs_num = size(base_obs,1);
if obs_num > config.clustering.kmeans.bestClustersNumber.maxNumber
    obs_num = config.clustering.kmeans.bestClustersNumber.maxNumber;
end

replicates = config.clustering.kmeans.bestClustersNumber.replicates;
distortion_threshold = config.clustering.kmeans.bestClustersNumber.threshold;

disp('Searching for the best number of clusters ...');
distortion=zeros(obs_num,1);
if config.parpoolEnable
    
    parfor k_temp = 1:numel(distortion)
        [~,~,sumd]=kmeans(base_obs,k_temp,'emptyaction','drop');
        destortion_temp=sum(sumd);
        % try differnet tests to find minimun distortion under k_temp clusters
        for i = 2:replicates
            [~,~,sumd]=kmeans(base_obs,k_temp,'emptyaction','drop');
            destortion_temp=min(destortion_temp,sum(sumd));
        end
        distortion(k_temp,1)=destortion_temp;
    end
else
    
    for k_temp = 1:numel(distortion)
        [~,~,sumd]=kmeans(base_obs,k_temp,'emptyaction','drop');
        destortion_temp=sum(sumd);
        % try differnet tests to find minimun distortion under k_temp clusters
        for i = 2:replicates
            [~,~,sumd]=kmeans(base_obs,k_temp,'emptyaction','drop');
            destortion_temp=min(destortion_temp,sum(sumd));
        end
        distortion(k_temp,1)=destortion_temp;
    end
end


variance=distortion(1:end-1)-distortion(2:end);
if size(distortion,1)>1
    distortion_percent=cumsum(variance)/(distortion(1)-distortion(end));
else
    distortion_percent = [];
end

if config.plotEnable && config.debugModeEnable
    figure('color','w','Visible',config.plotVisible),
    plot(distortion_percent,'b*--');
    ylabel('Distortion,%'); xlabel('Cluster Number');
    title('Number of clusters estimation');
    grid on;
    if strcmpi(config.plotVisible, 'off')
        close
    end
end

K = find(distortion_percent>distortion_threshold,1,'first')+1;