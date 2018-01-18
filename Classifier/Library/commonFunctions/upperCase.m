function [ upperCaseString ] = upperCase( str, mode )
%UPPERCASE Summary of this function goes here
%   Detailed explanation goes here

if nargin < 2
   mode = 'all';
end

if isempty(str)
%     warning('There is empty string in the input!');
    upperCaseString = str;
else
    if strcmp(mode, 'first')
        upperCaseString = lower(str);
        upperCaseString(1) = upper(str(1));
    elseif strcmp(mode, 'allFirst')
        upperCaseString = lower(str);
        idx=regexp([' ' str],'(?<=\s+)\S','start')-1;
        upperCaseString(idx)=upper(str(idx));
    elseif strcmp(mode, 'firstWithoutChanges')
        upperCaseString = str;
        upperCaseString(1) = upper(str(1));
    else
       upperCaseString = upper(str);
    end
end

end

