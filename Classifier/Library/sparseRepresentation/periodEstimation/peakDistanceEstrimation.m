function [ peakDistance ] = peakDistanceEstrimation( file, config )
%PEAKDISTANSEESTRIMATION Summary of this function goes here
%   Detailed explanation goes here

if nargin<2
    config = [];
end

%% _________________________ DEFAULT_PARAMETERs _______________________ %%
config = fill_struct(config,'peaksPerFrame','5');
config = fill_struct(config,'validationThreshold','0.1');

config.peaksPerFrame = str2num(config.peaksPerFrame);
config.validationThreshold = str2num(config.validationThreshold);

%% _________________________ MAIN_CALCULATIONs ________________________ %%
% file.signal is a vector of peaks locations;
signal = file.signal; % Signal shld be Nx1 samples
signalLength = length(signal);
if signalLength > config.peaksPerFrame
    framesNumber = floor(signalLength/config.peaksPerFrame);
else
    config.peaksPerFrame = signalLength;
    framesNumber = 1;
end
signal = signal(1:framesNumber*config.peaksPerFrame,1);
% Form distance matrix
diffDistanceMatrix = diff(reshape(signal,[],framesNumber)',1,2); % Any row is a signal frame
meanDistanceVector = mean(diffDistanceMatrix,2);
stdDistanceVector = std(diffDistanceMatrix,0,2);
validationVector = (bsxfun(@rdivide,stdDistanceVector,meanDistanceVector)<=config.validationThreshold);
validFrames = find(validationVector);

if isempty(validFrames)
    peakDistance = nan;
    return;
end

distanceVector = meanDistanceVector(validFrames,1);

% Find similar distances in distanceVector to detect true peaks period
file.signal = distanceVector;
[ peakDistance ] = getSimilars( file, config );

if isempty(peakDistance)
    disp('There no valid period in the signal');
    peakDistance = nan;
end

end


