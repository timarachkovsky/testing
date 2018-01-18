classdef signalTypeDetector
    %SIGNALTYPEDETECTOR estimates input signal type (pulse, continuous,
    %noisy or unknown) and calculates optimal iterations number for pattern
    %extraction
    
    % Developer : ASLM
    % Date : 01.03.2017
    
    properties(Access = private)
        
        % INPUT:
        scalogramMeasurements
        decompositionMeasurements
        id
        
        Config
        plotEnable
        plotVisible
        printPlotsEnable
        debugModeEnable
        saveDataEnable
        
        % Calculated:
        metrics
        
        % OUTPUT:
        signalType
        optimalIterationsNumber
        elementType
        
    end
    
    properties(Access = public)
       
        % Parameters
        interpolationFactor
%         plotEnable
        
    end
    
    methods (Access = public)
        
        % Constructor function
        function [myDetector] = signalTypeDetector(decompositionData, scalogramData, myConfig, myId)
            
            if nargin == 2
               myConfig = [];
               
            
            end
            
            if nargin == 3
                myDetector.id = ' ';
            else 
                myDetector.id = myId;
            end
            
            % Default Parameters
            myConfig = fill_struct(myConfig, 'interpolationFactor','10');
            myConfig = fill_struct(myConfig, 'plotEnable','0');
            myConfig = fill_struct(myConfig, 'plotVisible','on');
            myConfig = fill_struct(myConfig, 'printPlotsEnable','0');
            myConfig = fill_struct(myConfig, 'debugModeEnable','0');
            myConfig = fill_struct(myConfig, 'saveDataEnable','0');
            
            myDetector.plotEnable = str2double(myConfig.plotEnable);
            myDetector.plotVisible = myConfig.plotVisible;
            myDetector.printPlotsEnable = str2double(myConfig.printPlotsEnable);
            myDetector.interpolationFactor = str2double(myConfig.interpolationFactor);
            myDetector.debugModeEnable = str2double(myConfig.debugModeEnable);
            myDetector.saveDataEnable = str2double(myConfig.saveDataEnable);
            
            % Common Evaluations
            myDetector.Config = myConfig;
            myDetector.decompositionMeasurements = decompositionData;
            myDetector.scalogramMeasurements = scalogramData;
            
            myDetector.metrics = metricsEvaluation(myDetector);
            [myDetector] = identifySignalType(myDetector);
%             [myDetector] = calculateIterationsNumber(myDetector); %Unused

        end
        
        % Getters / Setters ...
        function [mySignalType] = getSignalType(myDetector)
           mySignalType = myDetector.signalType; 
        end
        function [myDetector] = setSignalType(myDetector,mySignalType)
           myDetector.signalType = mySignalType;
        end
        
        function [myOptimalIterationsNumber] = getOptimalIterationsNumber(myDetector)
           myOptimalIterationsNumber = myDetector.optimalIterationsNumber; 
        end
        function [myDetector] = setOptimalIterationsNumber(myDetector,myOptimalIterationsNumber)
           myDetector.optimalIterationsNumber = myOptimalIterationsNumber;
        end
        
        function [myMetrics] = getMetrics(myDetector)
           myMetrics = myDetector.metrics; 
        end
        % ... Getters / Setters
        
    end
    
    methods (Access = private)
        
        % IDENTIFYSIGNALTYPE function identify signal type:
        % @PULSE,@CONTINUOUS,@NOISY,@UNKNOWN
        function [myDetector] = identifySignalTypeOld(myDetector)
           
            metricsResult = myDetector.metrics;
            [fuzzyContainer] = myDetector.createSignalTypeContainer;
            
        % Prepare input arguments for fuzzy container
            
            % RMS parameters
            if nnz(metricsResult.rms.r2residue.total)
                rmsFirstPoint = metricsResult.rms.r2residue.total(1,1);
            else
                rmsFirstPoint = 0;
            end
            if nnz(metricsResult.rms.diff2residue.total)
                rmsSecondPoint = 1;
            else
                rmsSecondPoint = 0;
            end
            
            % KURTOSIS parameters
            if nnz(metricsResult.kurtosis.diff2residue.total)
                kurtosisPoint = 1;
            else
                kurtosisPoint = 0;
            end
            
            % PEAK parameters
            if nnz(metricsResult.peak.diff2residue.total)
                diffPeakPoint = metricsResult.peak.diff2residue.total(1,1);
            else
                diffPeakPoint = 0;
            end
            if nnz(metricsResult.peak.r2residue.total)
                peakPoint = metricsResult.peak.r2residue.total(1,1);
            else
                peakPoint = 0;
            end
            
            % PEAKFACTOR parameters
            if (metricsResult.peakFactor.lastDiffValue > metricsResult.peakFactor.lastResidueValue) && ...
               (metricsResult.peakFactor.lastDiffValue < metricsResult.peakFactor.lastValue)
                    peakFactorLastDiffValue = 1; % between the restored and residue curves
            else
                    peakFactorLastDiffValue = 0; % below the residue curve
            end

            % FUZZY calculations
            inputArgs = [rmsFirstPoint, rmsSecondPoint,kurtosisPoint,diffPeakPoint,peakFactorLastDiffValue,peakPoint];
            [result] = evalfis(inputArgs,fuzzyContainer);
            result = round(result);
            
            switch(result)
                case 1 
                    myDetector.signalType = 'UNKNOWN';
                case 2 
                    myDetector.signalType = 'CONTINUOUS';
                case 3
                    myDetector.signalType = 'PULSE';
                case 4
                    myDetector.signalType = 'NOISY';
                otherwise
                    myDetector.signalType = 'UNKNOWN';
            end
            
        end
        
        function [myDetector] = identifySignalType(myDetector)
           
            metricsResult = myDetector.metrics;
            [fuzzyContainer] = myDetector.createSignalTypeContainer;
            
        % Prepare input arguments for fuzzy container
            
            % RMS Intersection Points
            if nnz(metricsResult.rms.rt2rdPoint.total)
                rmsFirstPoint = metricsResult.rms.rt2rdPoint.total(1,1);
            else
                rmsFirstPoint = 0;
            end
            if nnz(metricsResult.rms.diff2rdPoint.total)
                rmsSecondPoint = 1;
            else
                rmsSecondPoint = 0;
            end
            
            % KURTOSIS Configuration
            if (metricsResult.kurtosis.lastDiffValue > metricsResult.kurtosis.lastRdValue) && (metricsResult.kurtosis.lastDiffValue < metricsResult.kurtosis.lastRtValue)
                kurtosisConfiguration = 2; % Pulse
            elseif (metricsResult.kurtosis.lastRtValue > metricsResult.kurtosis.lastDiffValue) && (metricsResult.kurtosis.lastRtValue < metricsResult.kurtosis.lastRdValue)
                if (metricsResult.kurtosis.lastRtValue <= 3)
                    kurtosisConfiguration = 1; % Continuous
                else
                    kurtosisConfiguration = 4; % Unknown
                end
            elseif (metricsResult.kurtosis.lastRdValue > metricsResult.kurtosis.lastDiffValue) && (metricsResult.kurtosis.lastRdValue < metricsResult.kurtosis.lastRtValue)
                kurtosisConfiguration = 3; % Common
            else
                kurtosisConfiguration = 4; % Unknown
            end
            
            % *********************************************************** %
            % PEAK Configuration     << -------------YOU STOPPED HERE !!! %
            % *********************************************************** %
            if (metricsResult.peak.lastRdValue > metricsResult.peak.lastDiffValue) && (metricsResult.peak.lastRdValue < metricsResult.peak.lastRtValue)
                if ~isempty(metricsResult.peak.rt2rdPoint.total)
                    if metricsResult.peak.rt2rdPoint.total(1,1) < 3000
                        peakConfiguration = 1; % Continuous
                    else
                        peakConfiguration = 3; % Common
                    end
                else
                    peakConfiguration = 1;
                end
            elseif (metricsResult.peak.lastDiffValue > metricsResult.peak.lastRdValue) && (metricsResult.peak.lastDiffValue < metricsResult.peak.lastRtValue)
                peakConfiguration = 2; % Pulse
            elseif (metricsResult.peak.lastRtValue > metricsResult.peak.lastDiffValue) && (metricsResult.peak.lastRtValue < metricsResult.peak.lastRdValue)
                peakConfiguration = 3; % Common
            else
                peakConfiguration = 4; % Unknown
            end
            
            % PEAKFACTOR Configuration
            if (metricsResult.peakFactor.lastRtValue > metricsResult.peakFactor.lastDiffValue) && (metricsResult.peakFactor.lastRtValue < metricsResult.peakFactor.lastRdValue)
                peakFactorConfiguration = 1; % Continuous
            elseif (metricsResult.peakFactor.lastDiffValue > metricsResult.peakFactor.lastRdValue) && (metricsResult.peakFactor.lastDiffValue < metricsResult.peakFactor.lastRtValue)
                peakFactorConfiguration = 2; % Pulse
            elseif (metricsResult.peakFactor.lastRdValue > metricsResult.peakFactor.lastDiffValue) && (metricsResult.peakFactor.lastRdValue < metricsResult.peakFactor.lastRtValue)
                peakFactorConfiguration = 3; % Common
            else
                peakFactorConfiguration = 4; % Unknown
            end
            

            % FUZZY calculations
            inputArgs = [rmsFirstPoint, kurtosisConfiguration,peakConfiguration,peakFactorConfiguration];
            [result] = evalfis(inputArgs,fuzzyContainer);
            result = round(result);

            switch(result)
                case 1 
                    myDetector.signalType = 'UNKNOWN';
                case 2 
                    myDetector.signalType = 'CONTINUOUS';
                case 3
                    myDetector.signalType = 'PULSE';
                case 4
                    myDetector.signalType = 'PULSECONTINUOUS';
                otherwise
                    myDetector.signalType = 'UNKNOWN';
            end
            
            if myDetector.debugModeEnable && myDetector.saveDataEnable
                filepath = fullfile(pwd,'Out',['inputArgs_',myDetector.id,'.mat']);
                save(filepath,'inputArgs','result');
            end
        end
        
        % METRICSEVALUATION function find the main metrics of the 
        % decomposition process
        function [result] = metricsEvaluation(myDetector)
            
            [result.kurtosis] = kurtosisEvaluation(myDetector);
            [result.rms] = rmsEvaluation(myDetector);
            [result.peak] = peakEvaluation(myDetector);
            [result.peakFactor] = peakFactorEvaluation(myDetector);
            [result.crestFactor] = crestFactorEvaluation(myDetector);
            
        end
        
% % % % %         % Currently UNUSED
% % % % %         function [myDetector] = calculateIterationsNumber(myDetector)
% % % % %             
% % % % %             switch(myDetector.signalType)
% % % % % %                 case 'UNKNOWN' 
% % % % % %                     [iterationsNumber] = iterationsUnknown(myDetector);
% % % % %                 case 'CONTINUOUS'
% % % % %                     [iterationsNumber] = iterationsContinuous(myDetector);
% % % % %                 case 'PULSE'
% % % % %                     [iterationsNumber] = iterationsPulse(myDetector);
% % % % %                 case 'NOISY'
% % % % %                     [iterationsNumber] = iterationsNoisy(myDetector);
% % % % %                 otherwise
% % % % %                     iterationsNumber = 500; % Magic Number :)
% % % % %             end
% % % % % 
% % % % %             myDetector.optimalIterationsNumber = iterationsNumber;
% % % % %         end
% % % % %         
% % % % %         % InterationsNumber calculation methods
% % % % %         function [iterationsNumber] = iterationsUnknown(myDetector)
% % % % %             warning('Dummy Iterations Number "UNKNOWN"');
% % % % %             iterationsNumber = 1000;  % Magic Number :)
% % % % %         end
% % % % %         function [iterationsNumber] = iterationsContinuous(myDetector)
% % % % %             
% % % % %             % Parameters
% % % % %             metricsResult = myDetector.metrics;
% % % % %             if nnz(metricsResult.peakFactor.r2residue.total)
% % % % %                 peakFactorPoint = metricsResult.peakFactor.r2residue.total(1,1);
% % % % %                 if peakFactorPoint > 5000 
% % % % %                     peakFactorPoint = 0;
% % % % %                 end
% % % % %             else
% % % % %                 peakFactorPoint = 0;
% % % % %             end
% % % % %             if nnz(metricsResult.crestFactor.r2residue.total)
% % % % %                 crestFactorPoint = metricsResult.crestFactor.r2residue.total(1,1);
% % % % %                 if peakFactorPoint > 5000 
% % % % %                     peakFactorPoint = 0;
% % % % %                 end
% % % % %             else
% % % % %                 crestFactorPoint = 0;
% % % % %             end
% % % % %             if nnz(metricsResult.kurtosis.diff2residue.total)
% % % % %                 kurtosisPoint = metricsResult.kurtosis.diff2residue.total(1,1);
% % % % %                 if peakFactorPoint > 5000 
% % % % %                     kurtosisPoint = 0;
% % % % %                 end
% % % % %             else
% % % % %                 kurtosisPoint = 0;
% % % % %             end
% % % % %             rmsPoint = metricsResult.rms.r2residue.total(1,1);
% % % % %             rmsPoint2 = 2*metricsResult.rms.r2residue.total(1,1);
% % % % %             if rmsPoint2 > 5000 
% % % % %                 kurtosisPoint = 0;
% % % % %             end
% % % % %             
% % % % % %             % TEST ...
% % % % % %             iterationsNumber = 100;
% % % % % %             iterationsNumber = rmsPoint;
% % % % % %             iterationsNumber = metricsResult.rms.diff2residue.total(1,1);
% % % % % 
% % % % % %             iterationsNumber = 3000;
% % % % % %             iterationsNumber = 9000;
% % % % %             % ... TEST
% % % % %             
% % % % %             
% % % % %             %ORIGINAL ... 
% % % % %             % Iterations Number calculation
% % % % %             % There are 2 rms intersect points
% % % % %             if nnz(metricsResult.rms.diff2residue.total)
% % % % %                 
% % % % %                 if  metricsResult.rms.diff2residue.total(1,1) > 5000
% % % % %                     iterationsNumber = max([rmsPoint,rmsPoint2,peakFactorPoint,crestFactorPoint,kurtosisPoint]);
% % % % %                 else
% % % % %                     iterationsNumber = metricsResult.rms.diff2residue.total(1,1);
% % % % %                 end
% % % % %             
% % % % %              % There is only 1 rms intersect point
% % % % %             elseif ~nnz(metricsResult.rms.diff2residue.total)
% % % % %                 
% % % % %                 iterationsNumber = max([rmsPoint,rmsPoint2,peakFactorPoint,crestFactorPoint,kurtosisPoint]);
% % % % %             
% % % % %             % There is no rms intersect points
% % % % %             else 
% % % % %                 
% % % % %                 warning('There is no valid intersect point to calculte optimal iteration number for SWD!');
% % % % %                 iterationsNumber = 1000;
% % % % %             end
% % % % %             
% % % % %         end    
% % % % %         function [iterationsNumber] = iterationsPulse(myDetector)
% % % % %             
% % % % % %             % TEST ...
% % % % % %             iterationsNumber = 100;
% % % % % %             iterationsNumber = myDetector.metrics.rms.r2residue.total(1,1);
% % % % % %             iterationsNumber = myDetector.metrics.rms.diff2residue.total(1,1);
% % % % % 
% % % % % %             iterationsNumber = 9000;
% % % % % %             % ... TEST
% % % % %             
% % % % %             
% % % % %             %ORIGINAL ...
% % % % %             metricsResult = myDetector.metrics;
% % % % %             if nnz(metricsResult.rms.r2residue.total)
% % % % %                 iterationsNumber = metricsResult.rms.r2residue.total(1,1);
% % % % %             else
% % % % %                 warning('There is no valid intersect point to calculte optimal iteration number for SWD!');
% % % % %                 iterationsNumber = 500;
% % % % %             end
% % % % %         end    
% % % % %         function [iterationsNumber] = iterationsNoisy(myDetector)
% % % % %             
% % % % %             metricsResult = myDetector.metrics;
% % % % %             
% % % % %             if nnz(metricsResult.kurtosis.diff2residue.total)
% % % % %                 kurtosisPoint = metricsResult.kurtosis.diff2residue.total(1,1);
% % % % %             else
% % % % %                 kurtosisPoint = inf;
% % % % %             end
% % % % %             
% % % % %             if nnz(metricsResult.peakFactor.diff2residue.total)
% % % % %                 peakFactorPoint = metricsResult.peakFactor.diff2residue.total(1,1);
% % % % %             else
% % % % %                 peakFactorPoint = inf;
% % % % %             end
% % % % %             
% % % % %             if nnz(metricsResult.crestFactor.diff2residue.total)
% % % % %                 crestFactorPoint = metricsResult.crestFactor.diff2residue.total(1,1);
% % % % %             else
% % % % %                 crestFactorPoint = inf;
% % % % %             end
% % % % %                
% % % % % %             % TEST ...
% % % % % %             iterationsNumber = 100;
% % % % % %             iterationsNumber = myDetector.metrics.rms.r2residue.total(1,1);
% % % % % %             iterationsNumber = myDetector.metrics.rms.diff2residue.total(1,1);
% % % % % 
% % % % % %                 iterationsNumber = 500;
% % % % % %                 iterationsNumber = 3000;
% % % % % %             iterationsNumber = 9000;
% % % % % %             % ... TEST
% % % % %             
% % % % %             
% % % % %             % ORIGINAL ...
% % % % %             iterationsNumber = min([kurtosisPoint,peakFactorPoint,crestFactorPoint]);
% % % % %                    
% % % % %         end
        
        % Main methods
        function [result] = kurtosisEvaluation(myDetector) 
            
            myInterpolationFactor = myDetector.interpolationFactor;
            
            % interpolation ...
            kurtosisVector = myDetector.decompositionMeasurements.restored.kurtosis;
            kurtosisVector = myDetector.interpolate(kurtosisVector,myInterpolationFactor);
            
            residueKurtosisVector = myDetector.decompositionMeasurements.residue.kurtosis;
            residueKurtosisVector = myDetector.interpolate(residueKurtosisVector,myInterpolationFactor);
            
            diffKurtosisVector = kurtosisVector - residueKurtosisVector;

            iterationsVector = myDetector.decompositionMeasurements.iterationsVector;
            iterationsVector = myDetector.interpolate(iterationsVector,myInterpolationFactor);
            % ... interpolation
            
            [result.diff2rdPoint] = myDetector.findIntersection(diffKurtosisVector, residueKurtosisVector, iterationsVector);
            
            % Another measurements...
            result.lastRtValue = kurtosisVector(end,1);
            result.lastRdValue = residueKurtosisVector(end,1);
            result.lastDiffValue = diffKurtosisVector(end,1);
            % ... another measurements
            
            % Plot Results
            if myDetector.plotEnable==1 && myDetector.debugModeEnable==1
                
                figure, set(gcf,'color','w','Visible',myDetector.plotVisible);
                plot(iterationsVector,kurtosisVector);
                hold on, plot(iterationsVector,residueKurtosisVector);
                hold on, plot(iterationsVector,diffKurtosisVector);
                grid on;
                xlabel('Iterations Number');
                ylabel('Kurtosis');
                legend('restored','residue','difference');
                title(['SWD Kurtosis Curve, scalNo = ',myDetector.id]);
                
                % Save image to the @Out directory
                if myDetector.printPlotsEnable
                    fileName = ['SWD_Kurtosis_Curve','_scalNo',myDetector.id];
                    fullFilePath = fullfile(pwd,'Out');
                    fullFileName = fullfile(fullFilePath,fileName);
                    print(fullFileName,'-djpeg91', '-r180');
                end
                
                % Close figure with visibility off
                if strcmpi(myDetector.plotVisible, 'off')
                    close
                end
            end
            
        end
        function [result] = rmsEvaluation(myDetector)
            
            myInterpolationFactor = myDetector.interpolationFactor;
            
            % interpolation ...
            rmsVector = myDetector.decompositionMeasurements.restored.rms;
            rmsVector = myDetector.interpolate(rmsVector,myInterpolationFactor);
            
            residueRmsVector = myDetector.decompositionMeasurements.residue.rms;
            residueRmsVector = myDetector.interpolate(residueRmsVector,myInterpolationFactor);
            
            diffRmsVector = rmsVector - residueRmsVector;
            dRmsVector = rmsVector*3; % 0.25 rms
            
            iterationsVector = myDetector.decompositionMeasurements.iterationsVector;
            iterationsVector = myDetector.interpolate(iterationsVector,myInterpolationFactor);
            % ... interpolation
            
            [result.diff2rdPoint] = myDetector.findIntersection(diffRmsVector, residueRmsVector, iterationsVector);
            [result.rt2rdPoint] = myDetector.findIntersection(rmsVector, residueRmsVector, iterationsVector);
 
            
            % Plot Results
            if myDetector.plotEnable==1 && myDetector.debugModeEnable==1
                
                figure, set(gcf,'color','w','Visible',myDetector.plotVisible);
                plot(iterationsVector,rmsVector);
                hold on, plot(iterationsVector,residueRmsVector);
                hold on, plot(iterationsVector,diffRmsVector);
                grid on;
                xlabel('Iterations Number');
                ylabel('Rms');
                legend('restored','residue','difference');
                title(['SWD RMS Curves, scalNo = ',myDetector.id]);
                
                % Save image to the @Out directory
                if myDetector.printPlotsEnable
                    fileName = ['SWD_RMS_Curve','_scalNo',myDetector.id];
                    fullFilePath = fullfile(pwd,'Out');
                    fullFileName = fullfile(fullFilePath,fileName);
                    print(fullFileName,'-djpeg91', '-r180');
                end
                
                % Close figure with visibility off
                if strcmpi(myDetector.plotVisible, 'off')
                    close
                end
            end

        end
        function [result] = peakEvaluation(myDetector)
            
            myInterpolationFactor = myDetector.interpolationFactor;
            
            % interpolation ...
            peakVector = myDetector.decompositionMeasurements.restored.peak;
            peakVector = myDetector.interpolate(peakVector,myInterpolationFactor);
            
            residuePeakVector = myDetector.decompositionMeasurements.residue.peak;
            residuePeakVector = myDetector.interpolate(residuePeakVector,myInterpolationFactor);
            
            diffPeakVector = peakVector - residuePeakVector;

            iterationsVector = myDetector.decompositionMeasurements.iterationsVector;
            iterationsVector = myDetector.interpolate(iterationsVector,myInterpolationFactor);
            % ... interpolation
            
            [result.diff2rdPoint] = myDetector.findIntersection(diffPeakVector, residuePeakVector, iterationsVector);
            [result.rt2rdPoint] = myDetector.findIntersection(peakVector, residuePeakVector, iterationsVector); %% << last view
            result.lastDiffValue = diffPeakVector(end,1);
            result.lastRtValue = peakVector(end,1);
            result.lastRdValue = residuePeakVector(end,1);
            
            % Another measurements...
            if nnz(bsxfun(@gt,diffPeakVector,residuePeakVector))>0
                result.diffPosition = 0; % noise signal
            elseif nnz(diffPeakVector>0)>0
                result.diffPosition = 1; % pulse signal
            elseif nnz(result.diff2rdPoint.total)
                result.diffPosition = 0.5; % continuous/pulse
            else
                result.diffPosition = -1; % unknown
            end
            result.lastDiffValue = diffPeakVector(end,1);
            % ... another measurements
            
            % Plot Results
            if myDetector.plotEnable==1 && myDetector.debugModeEnable==1
                figure, set(gcf,'color','w','Visible',myDetector.plotVisible);
                plot(iterationsVector,peakVector);
                hold on, plot(iterationsVector,residuePeakVector);
                hold on, plot(iterationsVector,diffPeakVector);
                grid on;
                xlabel('Iterations Number');
                ylabel('Peak');
                legend('restored','residue','difference');
                title(['SWD Peak Curve, scalNo = ',myDetector.id]);
                
                % Save image to the @Out directory
                if myDetector.printPlotsEnable
                    fileName = ['SWD_Peak_Curve','_scalNo',myDetector.id];
                    fullFilePath = fullfile(pwd,'Out');
                    fullFileName = fullfile(fullFilePath,fileName);
                    print(fullFileName,'-djpeg91', '-r180');
                end
                
                % Close figure with visibility off
                if strcmpi(myDetector.plotVisible, 'off')
                    close
                end
            end
        end
        function [result] = peakFactorEvaluation(myDetector)
            
            myInterpolationFactor = myDetector.interpolationFactor;
            
            % interpolation ...
            peakFactorVector = myDetector.decompositionMeasurements.restored.peakFactor;
            peakFactorVector = myDetector.interpolate(peakFactorVector,myInterpolationFactor);
            
            residuePeakFactorVector = myDetector.decompositionMeasurements.residue.peakFactor;
            residuePeakFactorVector = myDetector.interpolate(residuePeakFactorVector,myInterpolationFactor);
            
            diffPeakFactorVector = peakFactorVector - residuePeakFactorVector;

            iterationsVector = myDetector.decompositionMeasurements.iterationsVector;
            iterationsVector = myDetector.interpolate(iterationsVector,myInterpolationFactor);
            % ... interpolation
            
            [result.rt2rdPoint] = myDetector.findIntersection(peakFactorVector, residuePeakFactorVector, iterationsVector);
            [result.diff2rdPoint] = myDetector.findIntersection(diffPeakFactorVector, residuePeakFactorVector, iterationsVector);
                        
            % Another measurements...
            result.lastDiffValue = diffPeakFactorVector(end,1);
            result.lastRtValue = peakFactorVector(end,1);
            result.lastRdValue = residuePeakFactorVector(end,1);
            % ... another measurements
            
            % Plot Results
            if myDetector.plotEnable==1 && myDetector.debugModeEnable==1
                figure, set(gcf,'color','w','Visible',myDetector.plotVisible);
                plot(iterationsVector,peakFactorVector);
                hold on, plot(iterationsVector,residuePeakFactorVector);
                hold on, plot(iterationsVector,diffPeakFactorVector);
                grid on;
                xlabel('Iterations Number');
                ylabel('PeakFactor');
                legend('restored','residue','difference');
                title(['SWD PeakFactor Curve, scalNo = ',myDetector.id]);
                
                % Save image to the @Out directory
                if myDetector.printPlotsEnable
                    fileName = ['SWD_PeakFactor_Curve','_scalNo',myDetector.id];
                    fullFilePath = fullfile(pwd,'Out');
                    fullFileName = fullfile(fullFilePath,fileName);
                    print(fullFileName,'-djpeg91', '-r180');
                end
                
                % Close figure with visibility off
                if strcmpi(myDetector.plotVisible, 'off')
                    close
                end
            end
            
        end
        
        % Additional methods
        function [result] = crestFactorEvaluation(myDetector)
            
            myInterpolationFactor = myDetector.interpolationFactor;
            
            % interpolation ...
            crestFactorVector = myDetector.decompositionMeasurements.restored.crestFactor;
            maskVector = ~isnan(crestFactorVector);
            crestFactorVector = crestFactorVector(maskVector,1);
            crestFactorVector = myDetector.interpolate(crestFactorVector,myInterpolationFactor);
            
            residueCrestFactorVector = myDetector.decompositionMeasurements.residue.peakFactor;
            residueCrestFactorVector = residueCrestFactorVector(maskVector,1);
            residueCrestFactorVector = myDetector.interpolate(residueCrestFactorVector,myInterpolationFactor);
            
            diffCrestFactorVector = crestFactorVector - residueCrestFactorVector;

            iterationsVector = myDetector.decompositionMeasurements.iterationsVector';
            iterationsVector = iterationsVector(maskVector,1);
            iterationsVector = myDetector.interpolate(iterationsVector,myInterpolationFactor);
            % ... interpolation
            
            [result.rt2rdPoint] = myDetector.findIntersection(crestFactorVector, residueCrestFactorVector, iterationsVector);
            [result.diff2rdPoint] = myDetector.findIntersection(diffCrestFactorVector, residueCrestFactorVector, iterationsVector);
            
            % Another measurements...
            result.lastDiffValue = diffCrestFactorVector(end,1);
            result.lastValue = crestFactorVector(end,1);
            result.lastResidueValue = residueCrestFactorVector(end,1);
            % ... another measurements
            
            % Plot Results
%             if myDetector.plotEnable
            if 0 && myDetector.plotEnable==1 && myDetector.debugModeEnable==1
                figure, set(gcf,'color','w','Visible',myDetector.plotVisible);
                plot(iterationsVector,crestFactorVector);
                hold on, plot(iterationsVector,residueCrestFactorVector);
                hold on, plot(iterationsVector,diffCrestFactorVector);
                grid on;
                xlabel('Iterations Number');
                ylabel('CrestFactor');
                legend('restored','residue','difference');
                title(['SWD CrestFactor Curve, scalNo = ',myDetector.id]);
                
                % Save image to the @Out directory
                if myDetector.printPlotsEnable
                    fileName = ['SWD_CrestFactor_Curve','_scalNo',myDetector.id];
                    fullFilePath = fullfile(pwd,'Out');
                    fullFileName = fullfile(fullFilePath,fileName);
                    print(fullFileName,'-djpeg91', '-r180');
                end
                
                % Close figure with visibility off
                if strcmpi(myDetector.plotVisible, 'off')
                    close
                end
            end
        end
        function [result] = scalogramEvaluation(myDetector)
            result = [];
        end
        
    end
    
    methods (Access = private, Static = true)
       
        % FINDINTERSECTION function returns positions of the intersect
        % points between @vector1 and @vector2
        function [result] = findIntersection(vector1, vector2, iterationVector)
            
            differenceVector = vector1 - vector2;
            differenceVector(differenceVector > 0) = 1;
            differenceVector(differenceVector < 0) = -1;
            
            strobeVector = diff(differenceVector);
            
            result.total = iterationVector(strobeVector ~= 0);
            result.positive = iterationVector(strobeVector > 0);
            result.negative = iterationVector(strobeVector < 0);
            
        end
        
        function [vectorInterp] = interpolate(vectorOrigin,interpolationFactor)
            
            vectorLength = length(vectorOrigin);
            arrayOrigin = 1:vectorLength;
            arrayInterp = 1:1/interpolationFactor:vectorLength;
            
            % Main properties spline interpolation
            vectorInterp = interp1( arrayOrigin, vectorOrigin, arrayInterp, 'spline')';
            
        end
        
        %CREATESIGNALTYPECONTAINER function returns the container with
        %fuzzy rules to make decision about the signal type
        function [container] = createSignalTypeContainerOld()
            
            % ------------------- Fuzzy variables ---------------------- %
            container = newfis('optipaper'); 

            % INPUT:
            % Init 4-state @rmsFirstPoint variable
            container = addvar(container,'input','rmsFirstPoint',[-0.5 10000]);
            container = addmf(container,'input',1,'no','dsigmf',[10000 -0.5 10000 0.5]);
            container = addmf(container,'input',1,'low','dsigmf',[10000 0.5 10000 1500]);
            container = addmf(container,'input',1,'average','dsigmf',[10000 1500 10000 5000]);
            container = addmf(container,'input',1,'high','dsigmf',[10000 5000 10000 10000]);
            
            % Init 2-state @rmsSecondPoint variable
            container = addvar(container,'input','rmsSecondPoint',[-0.5 10.5]);
            container = addmf(container,'input',2,'no','dsigmf',[10.5 -0.5 10.5 0.5]);
            container = addmf(container,'input',2,'yes','dsigmf',[10.5 0.5 10.5 1.5]);
            
            % Init 2-state @kurtosisPoint variable
            container = addvar(container,'input','kurtosisPoint',[-0.5 10.5]);
            container = addmf(container,'input',3,'no','dsigmf',[10.5 -0.5 10.5 0.5]);
            container = addmf(container,'input',3,'yes','dsigmf',[10.5 0.5 10.5 1.5]);

            % Init 4-state @diffPeakPoint variable
            container = addvar(container,'input','diffPeakPoint',[-0.5 10000]);
            container = addmf(container,'input',4,'no','dsigmf',[10000 -0.5 10000 0.5]);
            container = addmf(container,'input',4,'low','dsigmf',[10000 0.5 10000 1500]);
            container = addmf(container,'input',4,'average','dsigmf',[10000 1500 10000 5000]);
            container = addmf(container,'input',4,'high','dsigmf',[10000 5000 10000 10000]);
            
            % Init 2-state @peakFactorLastDiffValue variable
            container = addvar(container,'input','peakFactorLastDiffValue',[-0.5 10.5]);
            container = addmf(container,'input',5,'below','dsigmf',[10.5 -0.5 10.5 0.5]);
            container = addmf(container,'input',5,'between','dsigmf',[10.5 0.5 10.5 1.5]);
            
            % Init 2-state @peakPoint variable
            container = addvar(container,'input','peakPoint',[-0.5 10000]);
            container = addmf(container,'input',6,'no','dsigmf',[10000 -0.5 10000 0.5]);
            container = addmf(container,'input',6,'low','dsigmf',[10000 0.5 10000 1500]);
            container = addmf(container,'input',6,'average','dsigmf',[10000 1500 10000 5000]);
            container = addmf(container,'input',6,'high','dsigmf',[10000 5000 10000 10000]);
            
            % OUTPUT:
            % Init 3-state @result variable
            container = addvar(container,'output','result',[0.5 4.5]);
            container = addmf(container,'output',1,'unknown','trimf',[0.5 1 1.5]);
            container = addmf(container,'output',1,'continuous','trimf',[1.5 2 2.5]);
            container = addmf(container,'output',1,'pulse','trimf',[2.5 3 3.5]);
            container = addmf(container,'output',1,'noisy','trimf',[3.5 4 4.5]);

            % VARIABLES:
            % rmsFirstPoint,rmsSecondPoint,kurtosisPoint,peakPoint,peakFactorLastDiffValue

            % RESULT: 3--> pulse; 2-->continuous; 1-->noise

   % ........................DUMMY RULES ............................... %
            ruleList = [ 
            % unknown 
                      %r1 r2 kP dpP pfP pP |Res|
                        2  0  1  1  1  4    1  1  1; 
                        3  0  1  1  1  4    1  1  1;
                        4  1  1 -1  1  4    1  1  1;
                    
            % continuous
                      %r1 r2 kP dpP pfP pP |Res|
                      % Strong
                        2  2  2 -1  1 -4    2  1  1;
                        2  2  2 -1  1 -4    2  1  1;
                        2  1  2 -1  1 -4    2  1  1;
                        2  1  2 -1  1 -4    2  1  1;
                        
                      % Weak
                        3  1  2 -1  1 -4    2  1  1;
                        3  2  2 -1  1 -4    2  1  1;
                        
            % pulse
                      %r1 r2 kP dpP pfP pP |Res|
                        % Strong Pulses
                        2  2  1  2  2 -4    3  1  1;
                        2  2  1  3  2 -4    3  1  1;
                        2  1  1  2  2 -4    3  1  1;
                        2  1  1  3  2 -4    3  1  1;
                        
                        % Weak Pulses
                        2  1  2  2  2 -4    3  1  1;
                        3  2  1  2  2 -4    3  1  1;
                        3  1  1  2  2 -4    3  1  1;
                        3  1  2  2  2 -4    3  1  1;

             % noisy
                       %r1 r2 kP dpP pfP pP |Res|
                         1  1  2  1  1  0   4  1  1;                         

                       ];
    % .................... DUMMY RULES ................................ %
    
            container=addrule(container,ruleList);

        end
        
        function [container] = createSignalTypeContainer()
            
            % ------------------- Fuzzy variables ---------------------- %
            container = newfis('optipaper'); 

            % INPUT:
            % Init 3-state @rmsIntersectionPoint variable
            container = addvar(container,'input','rmsIntersectionPoint',[-0.5 10000]);
            container = addmf(container,'input',1,'no','dsigmf',[10000 -0.5 10000 0.5]);
            container = addmf(container,'input',1,'low','dsigmf',[10000 0.5 10000 5000]);
            container = addmf(container,'input',1,'high','dsigmf',[10000 5000 10000 10000]);
            
            % Init 4-state @kurtosisConfiguration variable
            container = addvar(container,'input','kurtosisConfiguration',[0.5 4.5]);
            container = addmf(container,'input',2,'continuous','dsigmf',[10.5 0.5 10.5 1.5]);
            container = addmf(container,'input',2,'pulse','dsigmf',[10.5 1.5 10.5 2.5]);
            container = addmf(container,'input',2,'common','dsigmf',[10.5 2.5 10.5 3.5]);
            container = addmf(container,'input',2,'unknown','dsigmf',[10.5 3.5 10.5 4.5]);
            
            % Init 4-state @peakConfiguration variable
            container = addvar(container,'input','peakConfiguration',[0.5 3.5]);
            container = addmf(container,'input',3,'continuous','dsigmf',[10.5 0.5 10.5 1.5]);
            container = addmf(container,'input',3,'pulse','dsigmf',[10.5 1.5 10.5 2.5]);
            container = addmf(container,'input',3,'common','dsigmf',[10.5 2.5 10.5 3.5]);
            container = addmf(container,'input',3,'unknown','dsigmf',[10.5 3.5 10.5 4.5]);
            
            % Init 4-state @peakFactorConfiguration variable
            container = addvar(container,'input','peakFactorConfiguration',[0.5 3.5]);
            container = addmf(container,'input',4,'continuous','dsigmf',[10.5 0.5 10.5 1.5]);
            container = addmf(container,'input',4,'pulse','dsigmf',[10.5 1.5 10.5 2.5]);
            container = addmf(container,'input',4,'common','dsigmf',[10.5 2.5 10.5 3.5]);
            container = addmf(container,'input',4,'unknown','dsigmf',[10.5 3.5 10.5 4.5]);
            
            % OUTPUT:
            % Init 3-state @result variable
            container = addvar(container,'output','result',[0.5 4.5]);
            container = addmf(container,'output',1,'unknown','trimf',[0.5 1 1.5]);
            container = addmf(container,'output',1,'continuous','trimf',[1.5 2 2.5]);
            container = addmf(container,'output',1,'pulse','trimf',[2.5 3 3.5]);
            container = addmf(container,'output',1,'pulseContinuous','trimf',[3.5 4 4.5]);

            % VARIABLES:
            % rmsFirstPoint,rmsSecondPoint,kurtosisPoint,peakPoint,peakFactorLastDiffValue

            % RESULT: 4--> pulseContinuous; 3--> pulse; 2-->continuous; 1-->unknown

   % ........................DUMMY RULES ............................... %
            ruleList = [ 
            % unknown 
                     % r1  k  p  pF  |Res|
                        2  1  1  3     1  1  1;
                        2  1  1  2     1  1  1;
                        0  3  3  3     1  1  1;
                        1  3  2  3     1  1  1;
                        1  3  1  3     1  1  1;
                        0  4  3  1     1  1  1;
                        0  4  4  4     1  2  1; 
                        
            % continuous
                     % r1  k  p  pF  |Res|
                       -1  1  0  1     2  1  1;
%                         0  1  1  1     2  1  1;
%                         0  1  3  1     2  1  1;
%                         0  1  2  1     2  1  1;
%                         0  1  1  1     2  1  1;
            % pulse
                     % r1  k  p  pF  |Res|
%                         2  2  2  2     3  1  1;
%                         0  2  2  2     3  1  1;
%                         2  2  2  1     3  1  1;
%                        -2  2  2  2     3  1  1;
                          0  2  0  0     3  1  1;

             % pulseContinuous
                     % r1  k  p  pF  |Res|   
                       -1  3  2  3     4  1  1;         
                       -1  3  1  3     4  1  1; 
                       -1  4  2  3     4  1  1;
%                         2  2  1  3     4  1  1; % << Mb PULSECONTINUOUS
                        
                       ];
    % .................... DUMMY RULES ................................ %
    
            container=addrule(container,ruleList);

        end
        
        % <UNUSED>
        function [container] = createElementTypeContainer()
            container = [];
        end
        
    end
end

