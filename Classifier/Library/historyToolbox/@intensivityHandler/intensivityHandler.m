classdef intensivityHandler
    %INTENSIVITYCALCULATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        % Input ptoperties
        signal
        intensivitySignal
        
        config
        
        % Output property
        result
        posStablePeak
    end
    
    
    methods (Access = public)
        
        function [myIntensivityHandler] = intensivityHandler(mySignal,myConfig)
            
            if nargin < 2 || isempty(myConfig)
                myConfig = [];
            end
            myConfig = fill_struct(myConfig, 'frameLength', '3');
            myConfig = fill_struct(myConfig, 'frameOverlap', '1');
            myConfig = fill_struct(myConfig, 'intensivityThreshold', '0.3');
            
            myIntensivityHandler.signal = mySignal;
            myIntensivityHandler.config = myConfig;
            
            myIntensivityHandler = createSumIntensivitySignal(myIntensivityHandler);
            myIntensivityHandler = intensivityProcessing(myIntensivityHandler);
            myIntensivityHandler = createPosStablePeak(myIntensivityHandler);
        end
        
        % Getters/Setters ...
        
        function [mySignal] = getSignal(myIntensivityHandler)
            mySignal = myIntensivityHandler.signal; 
        end
        function [myIntensivityHandler] = setSignal(myIntensivityHandler,mySignal)
            myIntensivityHandler.signal = mySignal;
        end
        
        function [myIntensivitySignal] = getIntensivitySignal(myIntensivityHandler)
            myIntensivitySignal = myIntensivityHandler.intensivitySignal; 
        end
        
        function [myResult] = getResult(myIntensivityHandler)
            myResult = myIntensivityHandler.result; 
        end
        
         function [posStablePeak] = getPosStablePeak(myIntensivityHandler)
            posStablePeak = myIntensivityHandler.posStablePeak; 
        end
        % ... Getters/Setters
        
        % RECALCULATEINTENSIVITY function sets new signal to the
        % intensivityHandler object and recalculate its intensivity
        function [myIntensivityHandler] = recalculateIntensivity(myIntensivityHandler,mySignal)
            
            if nargin == 2
                myIntensivityHandler = setSignal(myIntensivityHandler,mySignal);
            end
            
            myIntensivityHandler = createSumIntensivitySignal(myIntensivityHandler,myConfig);
            myIntensivityHandler = intensivityProcessing(myIntensivityHandler,myConfig);
            
        end
        
    end
    
    methods (Access = protected)
        
        % CREATEFUZZYCONTAINER function calculates intesivity of the input
        % signal based on the fuzzy logic
        function [myIntensivityHandler] = intensivityProcessing(myIntensivityHandler)
            
            myIntensivitySignal = getIntensivitySignal(myIntensivityHandler);
            actualPeriod = length(myIntensivitySignal);
            
            % FuzzyContainer creation 
            [fuzzyContainer] = createFuzzyContainer(myIntensivityHandler);
            % Input parameters for fuzzy container
            if actualPeriod >= 1
                currentIntensivity = myIntensivitySignal(1,1);
            else
                currentIntensivity = 0;
            end
            
            if actualPeriod >=2
                previousIntensivity = myIntensivitySignal(1,2);
            else
                previousIntensivity = 0;
            end
            
            if actualPeriod >=3
                meanPreviousIntensivity = mean(myIntensivitySignal(1,3:end));
            else
                meanPreviousIntensivity = 0;
            end
            % Form input arguments for created fuzzyContainer and create
            % the result @stable/unstable/unknown
            inputArgs = [currentIntensivity,previousIntensivity,...
                meanPreviousIntensivity];
            myIntensivityHandler.result = evalfis(inputArgs,fuzzyContainer);
        end
        
        % CREATEFUZZYCONTAINER function forms fuzzy container for decision
        % making on the problem
        function [container] = createFuzzyContainer(myIntensivityHandler)
            container = newfis('optipaper');
            
            % Init 4-state @currentIntensivity variable
            container = addvar(container,'input','currentIntensivity',[-0.25 1.25]);
            container = addmf(container,'input',1,'low','dsigmf',[20.5 0.1 20.5 0.4]);
            container = addmf(container,'input',1,'medium','dsigmf',[20.5 0.4 20.5 0.75]);
            container = addmf(container,'input',1,'high','dsigmf',[20.5 0.75 20.5 1.25]);
            container = addmf(container,'input',1,'no','dsigmf',[20.5 -0.25 20.5 0.1]);
            
            % Init 3-state @previousIntensivity variable
            container = addvar(container,'input','previousIntensivity',[-0.25 1.25]);
            container = addmf(container,'input',2,'low','dsigmf',[20.5 0.1 20.5 0.4]);
            container = addmf(container,'input',2,'medium','dsigmf',[20.5 0.4 20.5 0.75]);
            container = addmf(container,'input',2,'high','dsigmf',[20.5 0.75 20.5 1.25]);
            container = addmf(container,'input',2,'no','dsigmf',[20.5 -0.25 20.5 0.1]);
            
            % Init 3-state @meanPreviousIntensivity variable
            container = addvar(container,'input','meanPreviousIntensivity',[-0.5 20.5]);
            container = addmf(container,'input',3,'low','dsigmf',[20.5 0.1 20.5 0.4]);
            container = addmf(container,'input',3,'medium','dsigmf',[20.5 0.4 20.5 0.75]);
            container = addmf(container,'input',3,'high','dsigmf',[20.5 0.75 20.5 1.25]);
            container = addmf(container,'input',3,'no','dsigmf',[20.5 -0.25 20.5 0.1]);
            
            % OUTPUT:
            % Init 3-state @result variable
            container = addvar(container,'output','result',[-0.25 1.25]);
            container = addmf(container,'output',1,'nonstable','trimf',[-0.25 0 0.25]);
            container = addmf(container,'output',1,'mb_stable','trimf',[0.25 0.5 0.75]);
            container = addmf(container,'output',1,'stable','trimf',[0.75 1 1.25]);
            
            
            
            %RULEs:
            % actualPeriod; currentIntensivity, previousIntensivity,meanPreviousIntensivity 
            % ---->>>>  result and etc]

            %start position
            ruleList = [ 4  4  4  1  1  1;
                         4  0  0  1  1  1;   
                
                         1  4  4  1  1  1;
                         2  4  4  1  1  1;
                         3  4  4  3  1  1;
                        
                         1  4  4  1  1  1;
                         1  1  4  1  1  1;
                         1  2  4  2  1  1;
                         1  3  4  3  1  1;
                        
                         2  4  4  1  1  1;
                         2  1  4  2  1  1;
                         2  2  4  3  1  1;
                         2  3  4  3  1  1;
                         3  0  4  3  1  1;
                        
                         3  0  0  3  1  1;
                         2  4  4  1  1  1;
                         2  1 -4  2  1  1;
                         2  2  0  3  1  1;
                        
                         1  1  3  2  1  1;
                         1  1  2  2  1  1;
                         1  1  1  1  1  1;
                         1  1  4  1  1  1;
                        
                         1  4  3  2  1  1;
                         1  4 -3  1  1  1;
                        
                         1  2  3  3  1  1;
                         1  2 -3  2  1  1;
                         1  3  0  3  1  1;
                        
                         ];
                    
            container = addrule(container,ruleList);
        end
        
        % CREATESUMINTENSIVITYSIGNAL function forms intensivitySignal by
        % counting nonzeors per frame with overlap
        function [myIntensivityHandler] = createSumIntensivitySignal(myIntensivityHandler)
            mySignal = reshape(getSignal(myIntensivityHandler), 1, []);
            signalLength = length(mySignal);
            if signalLength==0
                myIntensivityHandler.intensivitySignal = 0;
                return
            end
            
            frameLength = str2double(myIntensivityHandler.config.frameLength);
            frameOverlap = str2double(myIntensivityHandler.config.frameOverlap);
             
            %Create sum signal (number of nnz per frame with overlap)
            sumSignalLength = signalLength-(frameLength-frameOverlap);
            sumSignal = zeros(sumSignalLength,1);
            for i = 1:1:sumSignalLength
               sumSignal(i,1) = nnz(mySignal(1,i:i+frameLength-1));
            end
            
            framesNumber = floor(sumSignalLength/frameLength);
            if framesNumber >=1
                % Create table of the original signal frames, transform it
                % to cell array and use cellfun's nonzeros count function
                ceilSignal = sumSignal(1:framesNumber*frameLength,1);
                framesTable = num2cell(reshape(ceilSignal,frameLength,[]),1);
                mySumIntensivitySignal = cellfun(@sum,framesTable)/frameLength^2;
                
                % If original signal has an residue after cutting process
                % and its length not equal to 1 and less then frame length
                % also calculate it intensivity
                if sumSignalLength > length(ceilSignal) 
                    residueSignal = sumSignal(framesNumber*frameLength+1:end,1);
                    if length(residueSignal)>1 && length(residueSignal)<frameLength
                        mySumIntensivitySignal(1,end+1) = sum(residueSignal)/frameLength/length(residueSignal);
                    end
                end
            else
                mySumIntensivitySignal = 0;
            end
            myIntensivityHandler.intensivitySignal = mySumIntensivitySignal;
        end
       
        % CREATEPOSSTABLEPEAK function finding  position history peak with stable intensity
        function [myIntensivityHandler] = createPosStablePeak(myIntensivityHandler)
            intensivityThreshold = str2double(myIntensivityHandler.config.intensivityThreshold);
            reducedSignal = myIntensivityHandler.signal;
            if myIntensivityHandler.result > intensivityThreshold
    
                reducedSignalResult = myIntensivityHandler.result;
                frameLength = str2double(myIntensivityHandler.config.frameLength);
                frameOverlap = str2double(myIntensivityHandler.config.frameOverlap);
                skipLength = frameLength - frameOverlap+1;
                temporaryObject =  myIntensivityHandler;
                
                while length(reducedSignal) > skipLength && reducedSignalResult > intensivityThreshold
                    reducedSignal = reducedSignal(skipLength:end);
                    
                    temporaryObject.signal = reducedSignal;
                    temporaryObject = createSumIntensivitySignal(temporaryObject);
                    temporaryObject = intensivityProcessing(temporaryObject);
                    reducedSignalResult = temporaryObject.result;
                end
                
                if frameLength <= length(reducedSignal)
                    reducedSignal = [];
                end
                myIntensivityHandler.posStablePeak = length(myIntensivityHandler.signal) - ...
                    length(reducedSignal);
            else
                myIntensivityHandler.posStablePeak = length(reducedSignal);
            end
        end
        
    end
    
end

