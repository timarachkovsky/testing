classdef connectionClassifier < shaftClassifier
    % CONNECTIONCLASSIFIER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        connection
    end
    
    methods
        function myConnectionClassifier = connectionClassifier(myClassifierStruct, myClassifierType, myConnectionElement, frequencyTable)
            myConnectionClassifier = myConnectionClassifier@shaftClassifier(myClassifierStruct, myClassifierType, myConnectionElement, frequencyTable);
            myConnectionClassifier.connection = myConnectionElement;
        end
        
        function myConnection = getConnection(myConnectionClassifier)
            myConnection = myConnectionClassifier.connection;
        end
        
        function myConnectionClassifier = setConnection(myConnectionClassifier, myConnection)
            myConnectionClassifier.connection = myConnection;
        end
        
        function [statusStruct] = getDefectStatus(myClassifier, config)
            [statusStruct] = getDefectStatus@shaftClassifier(myClassifier, config);
        end
    end
    
    methods (Access = protected)
        function  [status] = defectDecisionMaker(defStatus, varargin)
            defStatus = cell2mat(varargin);
            status = defStatus;
%             status = [];
        end
    end
    
end

