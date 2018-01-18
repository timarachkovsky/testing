%GETFRAMESFREQS Summary of this function goes here
%   Detailed explanation goes here

% Function version : v1.0
% Last change : 02.07.2016
% Developer : ASLM

function [lowFreqs, highFreqs] = getFramesFreqs( config )

%% ___________________ Default parameters _____________________________ %%
if nargin < 1
   config = []; 
end

config = fill_struct(config, 'lowFreq', 5); % [Hz]
config = fill_struct(config, 'framesNumber',10); 
config = fill_struct(config, 'frameOverlapValue',5); % [Hz]

%% ______________________ Calculations ________________________________ %%

log2space = 2.^linspace(0,config.framesNumber-1,config.framesNumber)';

lowFreqs = [0; config.lowFreq.*log2space(1:config.framesNumber-1,1)];
highFreqs = config.lowFreq.*log2space(1:config.framesNumber,1);

if config.frameOverlapValue
   highFreqs = highFreqs +  config.frameOverlapValue;
end


