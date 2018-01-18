% Dat function 'crestFactor' calculates crest factor for signal divided 
% into windows with overlap and returns crest factor
% vector 'CFVector' with its mean value 'CFVector'

% created by Cuergo 
% 21.09.2016
% version 3.0

function [ CFMean, CFVector ] = crestFactor ( file, config )

if nargin < 2
   config = []; 
end

%% ___________________ DEFAULT_PARAMETERS _____________________________ %%
config = fill_struct(config, 'secPerFrame','0.1');
config = fill_struct(config, 'secOverlapValue','0.02');

config.secPerFrame = str2num(config.secPerFrame);
config.secOverlapValue = str2num(config.secOverlapValue);

%% ___________________ MAIN_CALCULATIONS ______________________________ %%

frame = round(config.secPerFrame*file.Fs);
overlap = config.secOverlapValue*file.Fs;
L = length ( file.signal );
increment = round(frame - overlap);      % distance beween start of window1 and start window2
position = 1;
i = 1;
CFVector = zeros ( 1, floor(L * ( frame + overlap) / frame^2 ));  % memory allocation
while position < L - frame
    CFVector ( i ) = peak2rms ( file.signal ( position : position + frame ) );
    position = position + increment;
    i = i + 1;
end

CFMean = mean ( CFVector ); % crest factor vector mean value 

end