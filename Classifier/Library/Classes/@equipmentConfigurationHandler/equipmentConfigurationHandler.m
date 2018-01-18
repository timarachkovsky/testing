classdef equipmentConfigurationHandler
    %EQUIPMENTCONFIGURATIONHANDLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        % INPUT:
        componentsList      % The list of equipment components for analysis
        
        InformativeTags     % Struct containing info to assotiate 
                            % components set and configuration
        
        % OUTPUT:             
        configurationTag    % tagName of current configuration, e.g.
                            %'REDUCER_ROLLING_BEARING', 'FAN' and etc
    end
    
    methods (Access = public)
        
        % Constructor
        function [myHandler] = equipmentConfigurationHandler(myComponentsList, myInformativeTags)
                myHandler.componentsList = myComponentsList;
                myHandler.InformativeTags = myInformativeTags;
        end
        
        % Getters/Setters ...
        
        function [myComponentsList] = getComponentsList(myHandler)
            myComponentsList = myHandler.componentsList;
        end
        function [myHandler] = setComponentsList(myHandler,myComponentsList)
            myHandler.componentsList = myComponentsList;
        end
        
        function [myInformativeTags] = getInformativeTags(myHandler)
            myInformativeTags = myHandler.InformativeTags;
        end
        function [myHandler] = setInformativeTags(myHandler,myInformativeTags)
            myHandler.InformativeTags = myInformativeTags;
        end
        
        % ...Getters/Setters
        
  
        % Dummy ...
        % CREATECONFIGURATIONTABLE function transform InformativeTags info
        % to table format to simplify further configuration search
        function [configurationTable] = createConfigurationTable(myHandler)
            configurationTable = [];
        end
        
        % SEARCHCONFIGURATION function perform configuration search in
        % configurationTable 
        function [configurationTag] = searchConfiguration(myHandler,configurationTable)
            configurationTag = [];
        end
        
        % ... dummy
    end
    
    
end

