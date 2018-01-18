classdef (Sealed) loger < handle
% LOGER class defines a persistent variable and include logging methods
    
    properties (Access = private)
        
        % TCPIP socket parameters
        tcpipSocketEnable
        tcpipSocket
        localhost
        localport
        outputBufferSize
        attempts
        timeout
        
        % Log file parameters
        logEnable
        logId
        
        % Console parameters
        consoleEnable
        
        % Progress parameters
        % Total weight of framework functions, that are listed in config
        totalWeight
        % The weight of completed part of framework
        currentWeight
        
        % The Matlab process ID
        pid
    end
    
    methods (Access = private)
        
        % Constructor method
        function [myLoger] = loger()
            
            myLoger.tcpipSocketEnable = 0;
            myLoger.attempts = 2;
            myLoger.timeout = 5;
            myLoger.tcpipSocket = [];
            myLoger.localhost = 'localhost';
            myLoger.localport = 8888;
            myLoger.outputBufferSize = 4096;
            
            myLoger.logEnable = 1;
            myLoger.logId = [];
            
            myLoger.consoleEnable = 1;
            
            myLoger.totalWeight = 1;
            myLoger.currentWeight = 0;
            
            myLoger.pid = feature('getpid');
        end
        
        function socketMessage(myLoger, event, strData, numData)
            
            if nargin == 3
                message = ['{"pid": "', num2str(myLoger.pid), '", ', ...
                    '"event": "', event, '", ', ...
                    '"data": ', strData, '}<EOM>'];
                
                fwrite(myLoger.tcpipSocket, message);
            elseif nargin == 4
                startMessage = ['{"pid": "', num2str(myLoger.pid), '", ', ...
                    '"event": "', event, '", ', ...
                    '"data": "', data];
                endMessage = ['"}', '}<EOM>'];
                
                fwrite(myLoger.tcpipSocket, startMessage);
                fwrite(myLoger.tcpipSocket, numData, 'double');
                fwrite(myLoger.tcpipSocket, endMessage);
            end
        end
    end
    
    methods (Access = public)
        
        % Destructor
        function delete(myLoger)
            
            if ~isempty(myLoger.tcpipSocket)
                if myLoger.tcpipSocketEnable
                    % End-Of-File tag
                    fwrite(myLoger.tcpipSocket, '<EOF>');
                end
                % Close the TCPIP socket
                fclose(myLoger.tcpipSocket);
            end
            
            if ~isempty(myLoger.logId) && (myLoger.logId ~= -1)
                % Close the log file
                fclose(myLoger.logId);
            end
            
            % Delete loger
            delete(myLoger);
            disp('Loger object is deleted');
        end
        
        % Getters / Setters ...
        function [status] = isTcpipSocketEnable(myLoger)
            status = myLoger.tcpipSocketEnable;
        end
        function [myLoger] = setTcpipSocketEnable(myLoger, status)
            myLoger.tcpipSocketEnable = status;
        end
        
        function [myTcpipSocket] = getTcpipSocket(myLoger)
            myTcpipSocket = myLoger.tcpipSocket;
        end
        function [myLoger] = setTcpipSocket(myLoger, myTcpipSocket)
            myLoger.tcpipSocket = myTcpipSocket;
        end
        
        function [myLocalhost] = getLocalhost(myLoger)
            myLocalhost = myLoger.localhost;
        end
        function [myLoger] = setLocalhost(myLoger, myLocalhost)
            myLoger.localhost = myLocalhost;
        end
        
        function [myLocalport] = getLocalport(myLoger)
            myLocalport = myLoger.localport;
        end
        function [myLoger] = setLocalport(myLoger, myLocalport)
            myLoger.localport = myLocalport;
        end
        
        function [myOutputBufferSize] = getOutputBufferSize(myLoger)
            myOutputBufferSize = myLoger.outputBufferSize;
        end
        function [myLoger] = setOutputBufferSize(myLoger, myOutputBufferSize)
            myLoger.outputBufferSize = myOutputBufferSize;
        end
        
        function [myAttempts] = getAttempts(myLoger)
            myAttempts = myLoger.attempts;
        end
        function [myLoger] = setAttempts(myLoger, myAttempts)
            myLoger.attempts = myAttempts;
        end
        
        function [myTimeout] = getTimeout(myLoger)
            myTimeout = myLoger.timeout;
        end
        function [myLoger] = setTimeout(myLoger, myTimeout)
            myLoger.timeout = myTimeout;
        end
        
        function [myLoger] = setTcpipParameters(myLoger, myLocalhost, myLocalport, myOutputBufferSize)
            myLoger.localhost = myLocalhost;
            myLoger.localport = myLocalport;
            myLoger.outputBufferSize = myOutputBufferSize;
        end
        
        function [status] = isLogEnable(myLoger)
            status = myLoger.logEnable;
        end
        function [myLoger] = setLogEnable(myLoger, status)
            myLoger.logEnable = status;
        end
        
        function [myLogId] = getLogId(myLoger)
            myLogId = myLoger.logId;
        end
        function [myLoger] = setLogId(myLoger, myLogId)
            myLoger.logId = myLogId;
        end
        
        function [status] = isConsoleEnable(myLoger)
            status = myLoger.consoleEnable;
        end
        function [myLoger] = setConsoleEnable(myLoger, status)
            myLoger.consoleEnable = status;
        end
        
        function [myTotalWeight] = getTotalWeight(myLoger)
            myTotalWeight = myLoger.totalWeight;
        end
        function [myLoger] = setTotalWeight(myLoger, myTotalWeight)
            myLoger.totalWeight = myTotalWeight;
        end
        
        function [myCurrentWeight] = getCurrentWeight(myLoger)
            myCurrentWeight = myLoger.currentWeight;
        end
        function [myLoger] = setCurrentWeight(myLoger, myCurrentWeight)
            myLoger.currentWeight = myCurrentWeight;
        end
        
        function [myPid] = getPid(myLoger)
            myPid = myLoger.pid;
        end
        function [myLoger] = setPid(myLoger, myPid)
            myLoger.pid = myPid;
        end
        % ... Getters / Setters
        
        % INCREASEWEIGHT method increases currentWeight of loger on
        % addWeight
        function [myLoger] = increaseWeight(myLoger, addWeight)
            myCurrentWeight = myLoger.currentWeight;
            myLoger.currentWeight = myCurrentWeight + addWeight;
        end
        
        function [myLoger] = initWithParameters(myLoger, myTcpipSocketEnable, myLogEnable, myConsoleEnable)
            
            switch (nargin)
                case 4
                    myLoger.tcpipSocketEnable = myTcpipSocketEnable;
                    myLoger.logEnable = myLogEnable;
                    myLoger.consoleEnable = myConsoleEnable;
                case 3
                    myLoger.tcpipSocketEnable = myTcpipSocketEnable;
                    myLoger.logEnable = myLogEnable;
                    myLoger.consoleEnable = 1;
                case 2
                    myLoger.tcpipSocketEnable = myTcpipSocketEnable;
                    myLoger.logEnable = 1;
                    myLoger.consoleEnable = 1;
                otherwise
                    myLoger.tcpipSocketEnable = 0;
                    myLoger.logEnable = 1;
                    myLoger.consoleEnable = 1;
            end
            
            myLoger = init(myLoger);
        end
        
        function [myLoger] = init(myLoger)
            
            if myLoger.logEnable
                if isempty(myLoger.logId) || (myLoger.logId == -1)
                    % Create a log file
                    logFilePath = fullfile(pwd, 'Out', 'log.txt');
                    % Open the log file
                    myLoger.logId = fopen(logFilePath, 'w');
                end
            end
            
            if myLoger.tcpipSocketEnable == 1
                % Create a TCPIP object
                myLoger.tcpipSocket = tcpip(myLoger.localhost, myLoger.localport, 'NetworkRole', 'client');
                myLoger.tcpipSocket.OutputBufferSize = myLoger.outputBufferSize;
                
                for attemptNumber = 1 : 1 : myLoger.attempts
                    try
                        % Connect the TCPIP object
                        fopen(myLoger.tcpipSocket);
                    catch
                        if (attemptNumber < myLoger.attempts)
                            % Pause before reconnections
                            pause(myLoger.timeout);
                        end
                    end
                end
                
                if ~strcmp(get(myLoger.tcpipSocket, 'Status'), 'open')
                    % Disable the TCPIP socket
                    myLoger.tcpipSocketEnable = 0;
                    printWarning(myLoger, 'TCPIP socket connection failed!');
                end
            end
        end
        
        function printProgress(myLoger, progressStage)
            
            progressPercent = round(myLoger.currentWeight / myLoger.totalWeight * 100);
            
            if myLoger.consoleEnable
               message = ['[Framework] Processing Progress = ', num2str(progressPercent), '%%  ', ...
                   'Processing Stage : ', progressStage, '.\n\n'];
               fprintf(message);
            end
            
            if myLoger.logEnable
                message = ['[Framework] Processing Progress = ', num2str(progressPercent), '%%  ', ...
                    'Processing Stage : ', progressStage, '.\n\n'];
                fprintf(myLoger.logId, message);
            end
            
            if myLoger.tcpipSocketEnable
                data = ['{"progress": "', num2str(progressPercent), '", ', ...
                    '"stage": "', progressStage, '"}'];
                socketMessage(myLoger, 'progress', data);
%                 message = ['{"pid": "', num2str(myLoger.pid), '", ', ...
%                     '"event": "progress", ', ...
%                     '"data": ', data, '}<EOM>'];
%                 fwrite(myLoger.tcpipSocket, message);
            end
        end
        
        function printException(myLoger, exceptionType, exceptionMessage, exceptionCode)
            
            if nargin == 3
                exceptionCode = '0000';
            end
            
            if myLoger.consoleEnable
                message = ['[Framework] Processing ', upper(exceptionType), '!\n\n', ...
                    'Code: ', exceptionCode, '.\n', ...
                    exceptionMessage, '\n\n'];
               fprintf(message);
            end
            
            if myLoger.logEnable
                message = ['[Framework] Processing ', upper(exceptionType), '!\n\n', ...
                    'Code: ', exceptionCode, '.\n', ...
                    exceptionMessage, '\n\n'];
                fprintf(myLoger.logId, message);
            end
            
            if myLoger.tcpipSocketEnable
                data = ['{"exception": "', exceptionType, '", ', ...
                    '"message": "', exceptionMessage, '", ', ...
                    '"code": "', exceptionCode, '"}'];
                socketMessage(myLoger, 'exception', data)
%                 message = ['{"pid": "', num2str(myLoger.pid), '", ', ...
%                     '"event": "exception", ', ...
%                     '"data": ', data, '}<EOM>'];
%                 fwrite(myLoger.tcpipSocket, message);
            end
        end
        
        function printWarning(myLoger, warningMessage)
            
            if myLoger.consoleEnable
               message = ['[Framework] Warning: ', ...
                   warningMessage, '\n\n'];
               fprintf(message);
            end
            
            if myLoger.logEnable
                message = ['[Framework] Warning: ', ...
                    warningMessage, '\n\n'];
                fprintf(myLoger.logId, message);
            end
            
            if myLoger.tcpipSocketEnable
                warningType = 'log';
                data = ['{"warning": "', warningType, '", ', ...
                    '"message": "', warningMessage, '"}'];
                socketMessage(myLoger, 'warning', data)
%                 message = ['{"pid": "', num2str(myLoger.pid), '", ', ...
%                     '"event": "warning", ', ...
%                     '"data": ', data, '}<EOM>'];
%                 fwrite(myLoger.tcpipSocket, message);
            end
        end
        
        function printComputeInfo(myLoger, computationStage, computationMessage, dataArray)
            
            if nargin == 3
                
                if myLoger.consoleEnable
                   message = ['[Framework] ', computationStage, ' processing.\n', ...
                       computationMessage, '\n\n'];
                   fprintf(message);
                end
                
                if myLoger.logEnable
                    message = ['[Framework] ', computationStage, ' processing.\n', ...
                        computationMessage, '\n\n'];
                    fprintf(myLoger.logId, message);
                end
                
                if myLoger.tcpipSocketEnable
                    computeInfoType = 'log';
                    data = ['{"computeInfo": "', computeInfoType, '", ', ...
                        '"stage": "', computationStage, '", ', ...
                        '"message": "', computationMessage, '"}'];
                    socketMessage(myLoger, 'computeInfo', data);
%                     message = ['{"pid": "', num2str(myLoger.pid), '", ', ...
%                         '"event": "computeInfo", ', ...
%                         '"data": ', data, '}<EOM>'];
%                     fwrite(myLoger.tcpipSocket, message);
                end
            elseif nargin == 4
                
                if myLoger.consoleEnable
                   message = ['[Framework] ', computationStage, ' processing.\n', ...
                       computationMessage, '\n'];
                   fprintf(message);
                   fprintf('%10.4f\n', dataArray);
                   fprintf('\n');
                end
                
                if myLoger.logEnable
                    message = ['[Framework] ', computationStage, ' processing.\n', ...
                        computationMessage, '\n'];
                    fprintf(myLoger.logId, message);
                    fprintf(myLoger.logId, '%10.4f\n', dataArray);
                    fprintf(myLoger.logId, '\n');
                end
                
                if myLoger.tcpipSocketEnable
                    computeInfoType = 'log';
                    data = ['{"computeInfo": "', computeInfoType, '", ', ...
                        '"stage": "', computationStage, '", ', ...
                        '"message": "', computationMessage, ': '];
                    socketMessage(myLoger, 'computeInfo', data, dataArray);
%                     startMessage = ['{"pid": "', num2str(myLoger.pid), '", ', ...
%                         '"event": "computeInfo", ', ...
%                         '"data": "', data];
%                     endMessage = ['"}', '}<EOM>'];
%                     fwrite(myLoger.tcpipSocket, startMessage);
%                     fwrite(myLoger.tcpipSocket, dataArray, 'double');
%                     fwrite(myLoger.tcpipSocket, endMessage);
                end
            end
        end
    end
    
    methods (Static)
        
        function [singleObj] = getInstance
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = loger;
            end
            singleObj = localObj;
        end
    end
end

