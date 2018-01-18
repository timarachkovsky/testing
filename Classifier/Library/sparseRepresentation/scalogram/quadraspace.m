% Developer: ASLM
% version 1.2
% QUADRASPACE function creates log2-scale vector from @d1 to @d2 values
% with @pointsPerOctave per 1 octave. If @roundingEnable mode enable, all
% values in the vector are rounded to the closest 2^x, i.m. y = [2,4,8,...]

% Modified by ASLM
% Date :  20.10.2016

% Example:

% 
function y = quadraspace(d1, d2, pointsPerOctave, roundingEnable, mode)

% if nargin >= 4
%     mode = 'pointsPerOctave';
% else
%     mode = 'numberOfPoints';
% end

if nargin == 4
   mode = 'numberOfPoints';
end

if nargin == 3
    roundingEnable = 0;
    mode = 'numberOfPoints';
end

switch (mode)
    case 'pointsPerOctave'
        
        if roundingEnable == 1

            if(d1 < 2)
                d1 =  ceil(log2(d1));
            else
                d1 = ceil(log2(d1));
            end

            if(d2 < 2)
                d2 =  ceil(log2(d2));
            else
                d2 = floor(log2(d2));
            end

            y = 2 .^ linspace(d1, d2, (d2-d1+1)*pointsPerOctave);
        else

            d1 = log2(d1); d2 = log2(d2);
            y = 2 .^ linspace(d1, d2, ceil(d2-d1)*pointsPerOctave);
        end
        
    case 'numberOfPoints'
        
        numberOfPoints = pointsPerOctave;
        d1 = log2(d1); d2 = log2(d2);
        y = 2 .^ linspace(d1, d2, numberOfPoints);
        
        if roundingEnable ==1
            y = unique(round(y));
        end
end
