function [ signalInterpolated, f1, df1 ] = cutAndInterpolate(file, shaftFreq,  highFreq)
%CUTANDINTERPOLATE Summary of this function goes here
%   Detailed explanation goes here

signalOriginal = file.signal;
Fs = file.Fs;

df = Fs/length(signalOriginal);
f = 0:df:Fs-df;

if(Fs> highFreq) 
    signal = signalOriginal(1, 1: floor(highFreq/df));
    f = 0:df:highFreq-df;
else
    signal =  signalOriginal;
    highFreq = Fs;
end

dfNominal = shaftFreq*0.0001;
kNominal = 1;

if (df > dfNominal)
    k = ceil(df/dfNominal)+1;
else
     k = kNominal;
end
df1 = df/k;
f1 = 0:df1:highFreq-df;
signalInterpolated = interp1(f(1:length(signal)),signal,f1,'spline');

end

