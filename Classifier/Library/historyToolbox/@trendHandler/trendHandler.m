classdef trendHandler
    %TRENDHANDLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        % Inner properties
        % Input signal to look for trend
        signal
        % Input struct with nessesary configuration
        config
        % Trend class to calculate main trend parameters
        trend
        
        % Outer properties
        % RESULT (struct) property contains the main parameters of the 
        % trend: slope, duration, status
        result
    end
    
    methods (Access = public)
        
        % Constructor function 
        function [myTrendHandler] = trendHandler(mySignal,config,myDate)
            
            if ~exist('config', 'var') || isempty(config)
                config = [];
            end
%             config = fill_struct(config, 'actualPeriod', '1');
            
            if ~exist('myDate', 'var') || isempty(myDate)
                myDate = num2cell(linspace(1, length(mySignal), length(mySignal)));
            end
            
            % Fill zero gaps in the input signal and find the main trend
            % parameters
            
            myTrendHandler.config = config;

            myHistoryCompression = historyCompression(mySignal, myDate, config);
            compression = getCompressedHistory(myHistoryCompression);
            mySignal = compression.data';
            myDate = compression.date';

            % History approximation 
            if nnz(isnan(mySignal)) && length(mySignal) > 1 
               mySignal = inpaint_nans(mySignal);
            end
            myTrendHandler.signal = mySignal;
            myTrendHandler.trend = trend(mySignal,config,myDate);
            myTrendHandler = trendProcessing(myTrendHandler);
        end

        % Getters/Setters...
        function [mySignal] = getSignal(myTrendHandler)
            mySignal = myTrendHandler.signal; 
        end
        function [myTrendHandler] = setSignal(myTrendHandler,mySignal)
            myTrendHandler.signal = mySignal;
        end
        
        function [myConfig] = getConfig(myTrendHandler)
            myConfig = myTrendHandler.config; 
        end
        function [myTrendHandler] = setConfig(myTrendHandler,myConfig)
            myTrendHandler.config = myConfig;
        end
        
        function [myTrend] = getTrend(myTrendHandler)
            myTrend = myTrendHandler.trend; 
        end
        
        function [myResult] = getResult(myTrendHandler)
            myResult = myTrendHandler.result;
        end
        % ...Getters/Setters
        
        function [myTrendHandler] = trendRecalculation(myTrendHandler)
            myTrendHandler = trendProcessing(myTrendHandler);
        end
        
    end
    
    methods(Access = private)
        
        function [container] = createFuzzyContainer(myTrendHandler)
            maxPeriod = str2double(myTrendHandler.config.actualPeriod);
            
            container = newfis('optipaper');
            
            % INPUT:
            % Init 4-state @actualPeriod variable
            container = addvar(container,'input','actualPeriod',[-0.75 (maxPeriod + 0.75)]);
            container = addmf(container,'input',1,'short','gauss2mf',[0.25 1 0.25 2]);
            container = addmf(container,'input',1,'average','gauss2mf',[0.25 3 0.25 6]);
            container = addmf(container,'input',1,'long','gauss2mf',[0.25 7 0.25 maxPeriod]);
            container = addmf(container,'input',1,'no','gaussmf',[0.25 0]);
            
            % Init 4-state @slopesNumber variable
            container = addvar(container,'input','slopesNumber',[-0.75 (maxPeriod + 0.75)]);
            container = addmf(container,'input',2,'one','gaussmf',[0.25 1]);
            container = addmf(container,'input',2,'two','gaussmf',[0.25 2]);
            container = addmf(container,'input',2,'many','gauss2mf',[0.25 3 0.25 maxPeriod]);
            container = addmf(container,'input',2,'no','gaussmf',[0.25 0]);
            
            % Init 5-state @currentSlope variable
            container = addvar(container,'input','currentSlope',[-100.75 100.75]);
            container = addmf(container,'input',3,'stronglyDeclining','gauss2mf',[0.25 -100 0.25 -6]);
            container = addmf(container,'input',3,'declining','gauss2mf',[0.25 -5 0.25 -2]);
            container = addmf(container,'input',3,'stable','gauss2mf',[0.25 -1 0.25 1]);
            container = addmf(container,'input',3,'growing','gauss2mf',[0.25 2 0.25 5]);
            container = addmf(container,'input',3,'stronglyGrowing','gauss2mf',[0.25 6 0.25 100]);
            
            % Init 4-state @currentDuration variable
            container = addvar(container,'input','currentDuration',[-0.75 (maxPeriod + 0.75)]);
            container = addmf(container,'input',4,'short','gauss2mf',[0.25 1 0.25 2]);
            container = addmf(container,'input',4,'average','gauss2mf',[0.25 3 0.25 6]);
            container = addmf(container,'input',4,'long','gauss2mf',[0.25 7 0.25 maxPeriod]);
            container = addmf(container,'input',4,'no','gaussmf',[0.25 0]);
            
            % Init 5-state @previousSlope variable
            container = addvar(container,'input','previousSlope',[-100.75 100.75]);
            container = addmf(container,'input',5,'stronglyDeclining','gauss2mf',[0.25 -100 0.25 -6]);
            container = addmf(container,'input',5,'declining','gauss2mf',[0.25 -5 0.25 -2]);
            container = addmf(container,'input',5,'stable','gauss2mf',[0.25 -1 0.25 1]);
            container = addmf(container,'input',5,'growing','gauss2mf',[0.25 2 0.25 5]);
            container = addmf(container,'input',5,'stronglyGrowing','gauss2mf',[0.25 6 0.25 100]);
            
            % Init 4-state @previousDuration variable
            container = addvar(container,'input','previousDuration',[-0.75 (maxPeriod + 0.75)]);
            container = addmf(container,'input',6,'short','gauss2mf',[0.25 1 0.25 2]);
            container = addmf(container,'input',6,'average','gauss2mf',[0.25 3 0.25 6]);
            container = addmf(container,'input',6,'long','gauss2mf',[0.25 7 0.25 maxPeriod]);
            container = addmf(container,'input',6,'no','gaussmf',[0.25 0]);
            
            % OUTPUT:
            % Init 6-state @result variable
            container = addvar(container,'output','result',[-1.375 1.875]);
            container = addmf(container,'output',1,'declining','gaussmf',[0.125 -1]);
            container = addmf(container,'output',1,'mb_declining','gaussmf',[0.125 -0.5]);
            container = addmf(container,'output',1,'stable','gaussmf',[0.125 0]);
            container = addmf(container,'output',1,'mb_growing','gaussmf',[0.125 0.5]);
            container = addmf(container,'output',1,'growing','gaussmf',[0.125 1]);
            container = addmf(container,'output',1,'unknown','gaussmf',[0.125 1.5]);
            
            % RULES:
            % actualPeriod, slopesNumber, currentSlope, currentDuration, previousSlope,
            % previousDuration, result and etc
            
            % start position
            ruleList = [
                        % actualPeriod = short && slopesNumber ~= ONE
                        1 -1  0  0  0  0  6  1  1;
                        
                        % slopesNumber = ONE
                        %    currentSlope: strDeclining --> strGrowing
                        
                              % strDeclining
                        1  1  1  0  0  0  2  1  1;
                        2  1  1  0  0  0  1  1  1;
                        3  1  1  0  0  0  1  1  1;
                              % declining
                        1  1  2  0  0  0  2  1  1;
                        2  1  2  0  0  0  1  1  1;
                        3  1  2  0  0  0  1  1  1;
                              % stable
                        1  1  3  0  0  0  3  1  1;
                        2  1  3  0  0  0  3  1  1;
                        3  1  3  0  0  0  3  1  1;
                              % growing
                        1  1  4  0  0  0  4  1  1;
                        2  1  4  0  0  0  5  1  1;
                        3  1  4  0  0  0  5  1  1;
                              % strGrowing
                        1  1  5  0  0  0  4  1  1;
                        2  1  5  0  0  0  5  1  1;
                        3  1  5  0  0  0  5  1  1;
                        
                        % slopesNumber = TWO
                        %   currentSlope: strDeclining --> strGrowing
                        %     actualPeriod: average --> long
                        %       previousSlope: strDeclining --> strGrowing
                        %         currentDuration: short --> long
                        %           previousDuration: short --> long
                        
                              % strDeclining
						% average   % (str)declining
                        2  2  1  0  1  0  1  1  1;
                        2  2  1  0  2  0  1  1  1;
						            % stable
                        2  2  1  1  3  0  2  1  1;
                        2  2  1  2  3  0  1  1  1;
						            % growing
                        2  2  1  1  4  1  2  1  1;
                        2  2  1  1  4  2  2  1  1;
                        2  2  1  2  4  0  1  1  1;
						            % strGrowing
                        2  2  1  1  5  1  6  1  1;
                        2  2  1  1  5  2  2  1  1;
                        2  2  1  2  5  0  1  1  1;
                        % long      % (str)declining
                        3  2  1  0  1  0  1  1  1;
                        3  2  1  0  2  0  1  1  1;
                                    % stable
                        3  2  1  1  3  2  2  1  1;
                        3  2  1  1  3  3  3  1  1;
                        3  2  1  2  3  0  1  1  1;
                        3  2  1  3  3  0  1  1  1;
                                    % growing
                        3  2  1  1  4  2  2  1  1;
                        3  2  1  1  4  3  4  1  1;
                        3  2  1  2  4  0  1  1  1;
                        3  2  1  3  4  0  1  1  1;
                                    % strGrowing
                        3  2  1  1  5  2  2  1  1;
                        3  2  1  1  5  3  4  1  1;
                        3  2  1  2  5  0  1  1  1;
                        3  2  1  3  5  0  1  1  1;
                        
                              % declining
						% average   % (str)declining
                        2  2  2  0  1  0  1  1  1;
                        2  2  2  0  2  0  1  1  1;
						            % stable
                        2  2  2  1  3  0  2  1  1;
                        2  2  2  2  3  0  1  1  1;
						            % growing
                        2  2  2  1  4  1  6  1  1;
                        2  2  2  1  4  2  2  1  1;
                        2  2  2  2  4  0  1  1  1;
						            % strGrowing
                        2  2  2  1  5  1  2  1  1;
                        2  2  2  1  5  2  4  1  1;
                        2  2  2  2  5  0  1  1  1;
                        % long      % (str)Declining
                        3  2  2  0  1  0  1  1  1;
                        3  2  2  0  2  0  1  1  1;
                                    % stable
                        3  2  2  1  3  2  3  1  1;
                        3  2  2  1  3  3  3  1  1;
                        3  2  2  2  3  0  1  1  1;
                        3  2  2  3  3  0  1  1  1;
                                    % growing
                        3  2  2  1  4  2  2  1  1;
                        3  2  2  1  4  3  4  1  1;
                        3  2  2  2  4  0  1  1  1;
                        3  2  2  3  4  0  1  1  1;
                                    % strGrowing
                        3  2  2  1  5  2  2  1  1;
                        3  2  2  1  5  3  4  1  1;
                        3  2  2  2  5  0  1  1  1;
                        3  2  2  3  5  0  1  1  1;
                        
                              % stable
						% average   % strDeclining
                        2  2  3  1  1  1  2  1  1;
                        2  2  3  1  1  2  2  1  1;
                        2  2  3  2  1  0  3  1  1;
						            % declining
                        2  2  3  1  2  1  3  1  1;
                        2  2  3  1  2  2  2  1  1;
                        2  2  3  2  2  0  3  1  1;
						            % stable
                        2  2  3  0  3  0  3  1  1;
						            % growing
                        2  2  3  1  4  1  3  1  1;
                        2  2  3  1  4  2  4  1  1;
                        2  2  3  2  4  0  3  1  1;
						            % strGrowing
                        2  2  3  1  5  1  4  1  1;
                        2  2  3  1  5  2  4  1  1;
                        2  2  3  2  5  0  3  1  1;
                        % long      % strDeclining
                        3  2  3  1  1  2  2  1  1;
                        3  2  3  1  1  3  1  1  1;
                        3  2  3  2  1  0  3  1  1;
                        3  2  3  3  1  0  3  1  1;
                                    % declinning
                        3  2  3  1  2  2  2  1  1;
                        3  2  3  1  2  3  2  1  1;
                        3  2  3  2  2  0  3  1  1;
                        3  2  3  3  2  0  3  1  1;
                                    % stable
                        3  2  3  0  3  0  3  1  1;
                                    % growing
                        3  2  3  1  4  2  4  1  1;
                        3  2  3  1  4  3  4  1  1;
                        3  2  3  2  4  0  3  1  1;
                        3  2  3  3  4  0  3  1  1;
                                    % strGrowing
                        3  2  3  1  5  2  4  1  1;
                        3  2  3  1  5  3  5  1  1;
                        3  2  3  2  5  0  3  1  1;
                        3  2  3  3  5  0  3  1  1;
                        
                              % growing
						% average   % strDeclining
                        2  2  4  1  1  1  4  1  1;
                        2  2  4  1  1  2  2  1  1;
                        2  2  4  2  1  0  5  1  1;
						            % declining
                        2  2  4  1  2  1  6  1  1;
                        2  2  4  1  2  2  4  1  1;
                        2  2  4  2  2  0  5  1  1;
						            % stable
                        2  2  4  1  3  0  4  1  1;
                        2  2  4  2  3  0  5  1  1;
						            % (str)growing
                        2  2  4  0  4  0  5  1  1;
                        2  2  4  0  5  0  5  1  1;
                        % long      % strDeclining
                        3  2  4  1  1  2  4  1  1;
                        3  2  4  1  1  3  2  1  1;
                        3  2  4  2  1  0  5  1  1;
                        3  2  4  3  1  0  5  1  1;
                                    % declinning
                        3  2  4  1  2  2  4  1  1;
                        3  2  4  1  2  3  2  1  1;
                        3  2  4  2  2  0  5  1  1;
                        3  2  4  3  2  0  5  1  1;
                                    % stable
                        3  2  4  1  3  2  3  1  1;
                        3  2  4  1  3  3  3  1  1;
                        3  2  4  2  3  0  5  1  1;
                        3  2  4  3  3  0  5  1  1;
                                    % (str)growing
                        3  2  4  0  4  0  5  1  1;
                        3  2  4  0  5  0  5  1  1;
                        
                              % strGrowing
						% average   % strDeclining
                        2  2  5  1  1  1  6  1  1;
                        2  2  5  1  1  2  4  1  1;
                        2  2  5  2  1  0  5  1  1;
						            % declining
                        2  2  5  1  2  1  4  1  1;
                        2  2  5  1  2  2  4  1  1;
                        2  2  5  2  2  0  5  1  1;
						            % stable
                        2  2  5  1  3  0  4  1  1;
                        2  2  5  2  3  0  5  1  1;
						            % (str)growing
                        2  2  5  0  4  0  5  1  1;
                        2  2  5  0  5  0  5  1  1;
                        % long      % strDeclining
                        3  2  5  1  1  2  4  1  1;
                        3  2  5  1  1  3  2  1  1;
                        3  2  5  2  1  0  5  1  1;
                        3  2  5  3  1  0  5  1  1;
                                    % declinning
                        3  2  5  1  2  2  4  1  1;
                        3  2  5  1  2  3  2  1  1;
                        3  2  5  2  2  0  5  1  1;
                        3  2  5  3  2  0  5  1  1;
                                    % stable
                        3  2  5  1  3  2  4  1  1;
                        3  2  5  1  3  3  3  1  1;
                        3  2  5  2  3  0  5  1  1;
                        3  2  5  3  3  0  5  1  1;
                                    % (str)growing
                        3  2  5  0  4  0  5  1  1;
                        3  2  5  0  5  0  5  1  1;
                        
                        % slopesNumber = MANY
                        %   currentSlope: strDeclining --> strGrowing
                        %     actualPeriod: average --> long
                        %       previousSlope: strDeclining --> strGrowing
                        %         currentDuration: short --> long
                        %           previousDuration: short --> long
                        
                              % strDeclining
                        % average   % (str)declining
                        2  3  1  0  1  0  1  1  1;
                        2  3  1  0  2  0  1  1  1;
                                    % stable
                        2  3  1  1  3  1  2  1  1;
                        2  3  1  1  3  2  2  1  1;
                        2  3  1  2  3  0  1  1  1;
                                    % growing
                        2  3  1  1  4  1  2  1  1;
                        2  3  1  1  4  2  2  1  1;
                        2  3  1  2  4  0  1  1  1;
                                    % strGrowing
                        2  3  1  1  5  1  6  1  1;
                        2  3  1  1  5  2  2  1  1;
                        2  3  1  2  5  0  1  1  1;
                        % long      % (str)declining
                        3  3  1  0  1  0  1  1  1;
                        3  3  1  0  2  0  1  1  1;
                                    % stable
                        3  3  1  1  3  1  2  1  1;
                        3  3  1  1  3  2  2  1  1;
                        3  3  1  1  3  3  3  1  1;
                        3  3  1  2  3  0  1  1  1;
                        3  3  1  3  3  0  1  1  1;
                                    % growing
                        3  3  1  1  4  1  2  1  1;
                        3  3  1  1  4  2  2  1  1;
                        3  3  1  1  4  3  4  1  1;
                        3  3  1  2  4  0  1  1  1;
                        3  3  1  3  4  0  1  1  1;
                                    % strGrowing
                        3  3  1  1  5  1  6  1  1;
                        3  3  1  1  5  2  2  1  1;
                        3  3  1  1  5  3  4  1  1;
                        3  3  1  2  5  0  1  1  1;
                        3  3  1  3  5  0  1  1  1;
                        
                              % declining
                        % average   % (str)declining
                        2  3  2  0  1  0  1  1  1;
                        2  3  2  0  2  0  1  1  1;
                                    % stable
                        2  3  2  1  3  1  2  1  1;
                        2  3  2  1  3  2  3  1  1;
                        2  3  2  2  3  0  1  1  1;
                                    % growing
                        2  3  2  1  4  1  6  1  1;
                        2  3  2  1  4  2  2  1  1;
                        2  3  2  2  4  0  1  1  1;
                                    % strGrowing
                        2  3  2  1  5  1  2  1  1;
                        2  3  2  1  5  2  4  1  1;
                        2  3  2  2  5  0  1  1  1;
                        % long      % (str)declining
                        3  3  2  0  1  0  1  1  1;
                        3  3  2  0  2  0  1  1  1;
                                    % stable
                        3  3  2  1  3  1  2  1  1;
                        3  2  2  1  3  2  3  1  1;
                        3  3  2  1  3  3  3  1  1;
                        3  3  2  2  3  0  1  1  1;
                        3  3  2  3  3  0  1  1  1;
                                    % growing
                        3  3  2  1  4  1  6  1  1;
                        3  3  2  1  4  2  2  1  1;
                        3  3  2  1  4  3  4  1  1;
                        3  3  2  2  4  0  1  1  1;
                        3  3  2  3  4  0  1  1  1;
                                    % strGrowing
                        3  3  2  1  5  1  2  1  1;
                        3  3  2  1  5  2  2  1  1;
                        3  3  2  1  5  3  4  1  1;
                        3  3  2  2  5  0  1  1  1;
                        3  3  2  3  5  0  1  1  1;
                        
                              % stable
						% average   % strDeclining
                        2  3  3  1  1  1  2  1  1;
                        2  3  3  1  1  2  2  1  1;
                        2  3  3  2  1  0  3  1  1;
                                    % declining
                        2  3  3  1  2  1  3  1  1;
                        2  3  3  1  2  2  2  1  1;
                        2  3  3  2  2  0  3  1  1;
                                    % stable
                        2  3  3  0  3  0  3  1  1;
                                    % growing
                        2  3  3  1  4  1  3  1  1;
                        2  3  3  1  4  2  4  1  1;
                        2  3  3  2  4  0  3  1  1;
                                    % strGrowing
                        2  3  3  1  5  1  4  1  1;
                        2  3  3  1  5  2  4  1  1;
                        2  3  3  2  5  0  3  1  1;
                        % long      % strDeclining
                        3  3  3  1  1  1  2  1  1;
                        3  3  3  1  1  2  2  1  1;
                        3  3  3  1  1  3  1  1  1;
                        3  3  3  2  1  0  3  1  1;
                        3  3  3  3  1  0  3  1  1;
                                    % declinning
                        3  3  3  1  2  1  3  1  1;
                        3  3  3  1  2  2  2  1  1;
                        3  3  3  1  2  3  2  1  1;
                        3  3  3  2  2  0  3  1  1;
                        3  3  3  3  2  0  3  1  1;
                                    % stable
                        3  3  3  0  3  0  3  1  1;
                                    % growing
                        3  3  3  1  4  1  3  1  1;
                        3  3  3  1  4  2  4  1  1;
                        3  3  3  1  4  3  4  1  1;
                        3  3  3  2  4  0  3  1  1;
                        3  3  3  3  4  0  3  1  1;
                                    % strGrowing
                        3  3  3  1  5  1  4  1  1;
                        3  3  3  1  5  2  4  1  1;
                        3  3  3  1  5  3  5  1  1;
                        3  3  3  2  5  0  3  1  1;
                        3  3  3  3  5  0  3  1  1;
                        
                              % growing
						% average   % strDeclining
                        2  3  4  1  1  1  4  1  1;
                        2  3  4  1  1  2  2  1  1;
                        2  3  4  2  1  0  5  1  1;
                                    % declining
                        2  3  4  1  2  1  6  1  1;
                        2  3  4  1  2  2  4  1  1;
                        2  3  4  2  2  0  5  1  1;
                                    % stable
                        2  3  4  1  3  1  4  1  1;
                        2  3  4  1  3  2  3  1  1;
                        2  3  4  2  3  0  5  1  1;
                                    % (str)growing
                        2  3  4  0  4  0  5  1  1;
                        2  3  4  0  5  0  5  1  1;
                        % long      % strDeclining
                        3  3  4  1  1  1  4  1  1;
                        3  3  4  1  1  2  4  1  1;
                        3  3  4  1  1  3  2  1  1;
                        3  3  4  2  1  0  5  1  1;
                        3  3  4  3  1  0  5  1  1;
                                    % declinning
                        3  3  4  1  2  1  6  1  1;
                        3  3  4  1  2  2  4  1  1;
                        3  3  4  1  2  3  2  1  1;
                        3  3  4  2  2  0  5  1  1;
                        3  3  4  3  2  0  5  1  1;
                                    % stable
                        3  3  4  1  3  1  4  1  1;
                        3  3  4  1  3  2  3  1  1;
                        3  3  4  1  3  3  3  1  1;
                        3  3  4  2  3  0  5  1  1;
                        3  3  4  3  3  0  5  1  1;
                                    % (str)growing
                        3  3  4  0  4  0  5  1  1;
                        3  3  4  0  5  0  5  1  1;
                        
                              % strGrowing
						% average   % strDeclining
                        2  3  5  1  1  1  6  1  1;
                        2  3  5  1  1  2  4  1  1;
                        2  3  5  2  1  0  5  1  1;
                                    % declining
                        2  3  5  1  2  1  4  1  1;
                        2  3  5  1  2  2  4  1  1;
                        2  3  5  2  2  0  5  1  1;
                                    % stable
                        2  3  5  1  3  1  4  1  1;
                        2  3  5  1  3  2  4  1  1;
                        2  3  5  2  3  0  5  1  1;
                                    % (str)growing
                        2  3  5  0  4  0  5  1  1;
                        2  3  5  0  5  0  5  1  1;
                        % long      % strDeclining
                        3  3  5  1  1  1  6  1  1;
                        3  3  5  1  1  2  4  1  1;
                        3  3  5  1  1  3  2  1  1;
                        3  3  5  2  1  0  5  1  1;
                        3  3  5  3  1  0  5  1  1;
                                    % declinning
                        3  3  5  1  2  1  4  1  1;
                        3  3  5  1  2  2  4  1  1;
                        3  3  5  1  2  3  2  1  1;
                        3  3  5  2  2  0  5  1  1;
                        3  3  5  3  2  0  5  1  1;
                                    % stable
                        3  3  5  1  3  1  4  1  1;
                        3  3  5  1  3  2  4  1  1;
                        3  3  5  1  3  3  3  1  1;
                        3  3  5  2  3  0  5  1  1;
                        3  3  5  3  3  0  5  1  1;
                                    % (str)growing
                        3  3  5  0  4  0  5  1  1;
                        3  3  5  0  5  0  5  1  1;
                        
                        % actualPeriod = no || slopesNumber = no
                        4  4  0  0  0  0  6  1  2;
                        ];
                    
            container = addrule(container,ruleList);
        end
        
        % FUZZYPROCESSING function evaluates fuzzyContainer creation and
        % fuzzy processing
        function [myTrendHandler] = trendProcessing(myTrendHandler)
            % FuzzyContainer creation 
            [fuzzyContainer] = createFuzzyContainer(myTrendHandler);
            
            myTrend = getTrend(myTrendHandler);
            
            % Input parameters for fuzzy container
            myDurations = getDurations(myTrend);
            mySlopes = getSlopes(myTrend);
            
            actualPeriod = sum(myDurations);
            slopesNumber = length(mySlopes);
            if slopesNumber
                % Set a maximum slope of 100 percent
                mySlopes(mySlopes > 100) = 100;
                mySlopes(mySlopes < -100) = -100;
                
                currentSlope = mySlopes(end);
                currentDuration = myDurations(end);
                
                if slopesNumber>1
                    previousSlope = mySlopes(end-1);
                    previousDuration = myDurations(end-1);
                else
                    previousSlope = 0;
                    previousDuration = 0;
                end
            else
                slopesNumber = 0;
                currentSlope = 0;
                currentDuration = 0;
                previousSlope = 0;
                previousDuration = 0;
            end
            
            currentSlope = round(currentSlope);
            previousSlope = round(previousSlope);
            % Form input arguments for created fuzzyContainer and create
            % the result struct containing trend status
            % (growing,downward,alternating or no)
            inputArgs = [actualPeriod,slopesNumber,currentSlope,...
                currentDuration,previousSlope,previousDuration];
            myTrendHandler.result = evalfis(inputArgs,fuzzyContainer);
        end
    end
end

