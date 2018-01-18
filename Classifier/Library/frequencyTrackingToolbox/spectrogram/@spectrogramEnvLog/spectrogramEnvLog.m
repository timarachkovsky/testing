classdef spectrogramEnvLog < spectrogramEnv 
    %SPECTROGRAMENVLOG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        logBasis
        dfLog
        
    end
    
    methods
        
        function [mySpectrogram] = spectrogramEnvLog( config )
            if nargin == 0
               warning('There is no config structure for spectrogram initialization!')
               config = [];
            end
            
            mySpectrogram = mySpectrogram@spectrogramEnv( config );
            mySpectrogram.tag = 'LOG-env';
            
            config = fill_struct(config, 'logBasis', '1.01');
            config = fill_struct(config, 'dfLog', '0.01');
            
            mySpectrogram.logBasis = str2double(config.logBasis);
            mySpectrogram.dfLog = str2double(config.dfLog);
            
        end
        
        
        function [mySpectrogram] = create(mySpectrogram, file)
            
            [mySpectrogram] = create@spectrogramEnv(mySpectrogram, file);
            [mySpectrogram] = linear2log(mySpectrogram);
            
        end
        
        
        function [mySpectrogram] = linear2log(mySpectrogram)
            
            % INPUT:
            
            myLogBasis = mySpectrogram.logBasis;
            dfLog = mySpectrogram.dfLog;
            
            myInterpolationFactor = mySpectrogram.interpolationFactor;
            
            frequenciesOrigin = mySpectrogram.frequencies;
            coefficientsOrigin = mySpectrogram.coefficients;
            
            
            % CALCULATION:
      
            fLog = log2(frequenciesOrigin)/log2(myLogBasis);
            
            % Gets orignal scalogram properties and form original and
            % interpolated arrays for further interpolation
            frequenciesLogOrigin = fLog(fLog>=0);

            arrayLength = length(frequenciesLogOrigin);
            arrayOrigin = 1:arrayLength;
            arrayInterp = 1:1/myInterpolationFactor:arrayLength;

            % Main properties spline interpolation
            fLogInterp = interp1( arrayOrigin, frequenciesLogOrigin, arrayInterp, 'spline')';
            fLogInterp = round(fLogInterp,2);

            fLogLinearSrt = ceil(fLogInterp(1)/dfLog)*dfLog;
            fLogLinearEnd = floor(fLogInterp(end)/dfLog)*dfLog;
            fLogLinearLen = (fLogLinearEnd-fLogLinearSrt)/dfLog + 1;

            frequenciesLogLinear = linspace(fLogLinearSrt,fLogLinearEnd, fLogLinearLen);
            frequenciesLogLinear = round(frequenciesLogLinear,2);
            
            [~,pos,~] = intersect(fLogInterp,frequenciesLogLinear);
            
            myCoefficients = cell(size(coefficientsOrigin,2),1);
            for i = 1:size(coefficientsOrigin,2)
                a = interp1( arrayOrigin, coefficientsOrigin(:,i), arrayInterp, 'spline');
                myCoefficients{i} = a(pos);
            end
            myCoefficients = cell2mat(myCoefficients)';   
            
            
            % Output:
            mySpectrogram.coefficients = myCoefficients;
            mySpectrogram.frequencies = frequenciesLogLinear;
            
        end
        
    end
    
end

