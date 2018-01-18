
% Version : v1_0
% Developer: ASLM
% Date: 22.08.2016

% DESCRIPTION:
% Find the nearest nonzero distance (if there is any) before(after) current tag
% zero distance may take the place when the modulation is observed 
% (ex. 2*F1, 2*F1-1*FTF, 2*F1+1*FTF --> distance = [0, 0], because
% numColumn = [ 2, 2, 2];

function [ distToLatestTruePos, distToLatestPotPos, distAfter ] = tagDistance( numColumn, positions, currentRow, maskColumn)

    currentPosition = find(positions == currentRow);
    pureNumColumn = numColumn(positions,1);
    pureMaskColumn = maskColumn(positions,1);
    diffDistances = diff(pureNumColumn);        %vector with distances between numColumn elements

    latestPotentialPosition = find(times(pureMaskColumn(1:currentPosition,:) >= 25, pureMaskColumn(1:currentPosition,:) < 75), 1, 'last' );
    latestTruePosition = find(times(pureMaskColumn(1:currentPosition,:) >= 75, pureMaskColumn(1:currentPosition,:) < 125), 1, 'last' );

    if isempty (latestPotentialPosition)
        latestPotentialPosition = 0;
    end
    if isempty (latestTruePosition)
        latestTruePosition = 0;
    end


    if isempty(diffDistances)
        distToLatestTruePos = 0;                
        distToLatestPotPos = 0;
        distAfter = 0;
    elseif currentRow == positions(end,1) %_____End position
        if latestTruePosition             % if latestTruePosition exist we calculate distance to it
             distToLatestTruePos = tagDistToLatestTruePos(pureNumColumn, currentPosition, latestTruePosition);
        else
            distToLatestTruePos = 0;     %if not we leave it zero
        end

        if latestPotentialPosition         % if latestPotentialPosition exist we calculate distance to it
             distToLatestPotPos = tagDistToLatestPotentialPos ( pureNumColumn, currentPosition, latestPotentialPosition);
        else
            distToLatestPotPos = 0;      % if not we leave it zero
        end

        distAfter = 0;

    elseif currentRow == positions(1,1)     %____Start position
        distToLatestTruePos = 0;                
        distToLatestPotPos = 0;
        distAfter = tagDistanceAfter(diffDistances,currentPosition);
    else                                    %____Mid position
        if latestTruePosition          % if latestTruePosition exist we calculate distance to it
             distToLatestTruePos = tagDistToLatestTruePos ( pureNumColumn, currentPosition, latestTruePosition);
        else
            distToLatestTruePos = 0;  % if not we leave it zero
        end

        if latestPotentialPosition     % if latestPotentialPosition exist we calculate distance to it
             distToLatestPotPos = tagDistToLatestPotentialPos ( pureNumColumn, currentPosition, latestPotentialPosition);
        else
            distToLatestPotPos = 0;  % if not we leave it zero
        end

        distAfter = tagDistanceAfter(diffDistances,currentPosition);
    end
    
end
% Find the nearest nonzero distance before the current tag
% function distBefore = tagDistanceBefore ( diffDistances, currentPosition )
%     distBefore = diffDistances(currentPosition-1,1);
%     
%     if distBefore == 0
%         diffDistances = nonzeros(diffDistances(1:currentPosition-1,1));
%         if ~isempty(diffDistances)
%             distBefore = diffDistances(end,1);
%         else
%             distBefore = 0;
%         end
%     end


% Find the distance to the latest true tag before the current tag
 function distToLatestTruePos = tagDistToLatestTruePos (pureNumColumn, currentPosition, latestTruePosition)
    if latestTruePosition == 0
        distToLatestTruePos = 0;
    else
        distToLatestTruePos = abs(pureNumColumn(currentPosition) - pureNumColumn(latestTruePosition));
    end
end
    

% Find the distance to the latest potential tag before the current tag
function distToLatestPotPos = tagDistToLatestPotentialPos ( pureNumColumn, currentPosition, latestPotentialPosition)
    if latestPotentialPosition == 0
        distToLatestPotPos = 0;
    else
        distToLatestPotPos = abs ( pureNumColumn ( currentPosition ) - pureNumColumn ( latestPotentialPosition ));
    end
end
    
% Find the nearest nonzero distance after the current tag
function distAfter = tagDistanceAfter ( diffDistances, currentPosition )
    distAfter = abs ( diffDistances(currentPosition,1));
    
    if distAfter == 0
        diffDistances = nonzeros(diffDistances(currentPosition:end,1));
        if ~isempty(diffDistances)
            distAfter = diffDistances(1,1);
        else
            distAfter = 0;
        end
    end
end