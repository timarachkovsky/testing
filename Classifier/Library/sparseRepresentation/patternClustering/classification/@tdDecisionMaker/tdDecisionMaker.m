classdef tdDecisionMaker < handle
    %TDDECISIONMAKER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        
        scalogramData       % Resonant frequencies and energy contribution
        periodicityData     % Resonant frequencies and periodities
        signalTypeData      % The whole signal type (pulse,cont. and etc)
        patternData         % Element type and probability
        equipmentData       % Equipment/element type
        
        elementsList        % List of possible elements 
        
        % Common
        plotEnable
        printPlotsEnable
        plotVisible
        parpoolEnable
        
    end
    
    properties (Access = protected)
        base
    end
    
    methods (Access = public)
        
        % Constructor method
        function [myDM] = tdDecisionMaker(data, config)
            
            % Common Parameters
            myDM.parpoolEnable = str2double(config.Attributes.parpoolEnable);
            myDM.plotEnable = str2double(config.Attributes.plotEnable);
            myDM.printPlotsEnable = str2double(config.Attributes.printPlotsEnable);
            myDM.plotVisible = config.Attributes.plotVisible;
            
            % Initialization
            myDM.scalogramData = data.scalogramData;
            myDM.periodicityData = data.periodicityData;
            myDM.signalTypeData = data.signalTypeData;
            myDM.patternData = data.patternData;
            myDM.equipmentData = data.equipmentData;
            
            myDM.elementsList = myDM.findElements(data.elementsList);
            
            % Prepate features for classification
            [myDM] = createBase(myDM);
            
        end
        
        function [myBase] = getBase(myDM)
           myBase = myDM.base; 
        end
        
        % CREATEBASE function forms features base for further decision
        % making
        function [myDM] = createBase(myDM)
            
            % Add scalogram data 
            myScalogramData = myDM.scalogramData;
            if ~isempty(myScalogramData)
                for i = 1:numel(myScalogramData)
                   myBase(i,1).resonantFrequency = myScalogramData(i).frequencies;
                   myBase(i,1).energyContribution = myScalogramData(i).energyContribution;
                   if myScalogramData(i).frequencies/20000 > 0.15
                       myBase(i,1).resonantTag = 'HF';
                   else
                       myBase(i,1).resonantTag = 'MF';
                   end
                end
            else
                myBase.resonantFrequency = [];
                myBase.energyContribution = [];
            end
            
            % Add signal type data
            mySignalTypeData = myDM.signalTypeData;
            for si = 1:numel(mySignalTypeData)
                myBase(si).signalType = mySignalTypeData(si);
            end
            
            % Add periodicity data 
            resonantFrequencies = unique([myBase.resonantFrequency]);
            myPeriodicityData = myDM.periodicityData;
            for ri = 1:numel(resonantFrequencies)
                if ~isempty(myPeriodicityData)
                    pos = ismember([myPeriodicityData.resonantFrequency],resonantFrequencies(ri));
                    myBase(ri).prd_frequency = [myPeriodicityData(pos).frequency];
                    myBase(ri).prd_validity = [myPeriodicityData(pos).validity];
                    myBase(ri).prd_type = [myPeriodicityData(pos).type];
                else
                    myBase(ri).prd_frequency = [];
                    myBase(ri).prd_validity = [];
                    myBase(ri).prd_type = [];
                end
            end

                
            % Add pattern data
            myPatternData = myDM.patternData;
            for pi = 1:numel(myPatternData)
                pos = pi; % <- here should be search for resonant frequency
                
                [val, position] = max(myPatternData(pos).info.element_type_energy);
                threshold = 0.5;
                if val > threshold
                    elementType = myPatternData(pos).info.element_type(position);
                else
                    elementType = 'unknown';
                end
                
                myBase(pi).ptrn_elementType = elementType;
                myBase(pi).ptrn_elementEnergy = myPatternData(pos).info.element_type_energy;
                myBase(pi).ptrn_elementVector = myPatternData(pos).info.element_type;
            end
            
            % Add equipment data
            myEquipmentData = myDM.equipmentData;
            for pi = 1:numel(myPatternData)
                pos = pi; % <- here should be search for resonant frequency
                myBase(pi).equip_elementType = myEquipmentData(pos).element_type;
            end
            
            myDM.base = myBase;
            
        end
        
        
        % Decision-making function
        function [result] = classification(myDM) 
            
            elements = myDM.elementsList;
%             elements = {
%                             'bearing';
%                             'gearing';
%                             'generator';
%                         };
                    
            similarity = zeros(size(elements));
            for i = 1:numel(elements)
%                 [similarity(i),severity(i),tag{i}] = myDM.(strcat(elements{i},'_defect_function'))(myDM.base);
                [similarity(i),severity(i),tag{i}] = feval(strcat(elements{i},'_defect_function'),myDM.base);
            end
            
            [val,idx] = max(similarity);
            if val<0.3
                result.element = {'unknown'};
            else
                result.element = elements(idx);
            end
            result.similarity = val*100;
            result.severity = severity(idx)*100;
            result.tag = tag{idx};
            result.status = -1; % unknown
            result.base = myDM.base;
           
            
            xticks = cellfun(@(x,y) strcat(x,'\_',y),elements,tag','UniformOutput',false);
            if myDM.plotEnable
                figure('Color','w','Visible',myDM.plotVisible), bar(similarity*100);
                xlabel('Elements');
                ylabel('Similarity, %');
                set(gca,'XTick',[1:1:numel(elements)]);
%                 set(gca,'XTickLabel',elements);
                set(gca,'XTickLabel',xticks);
                title('Time Domain. Possible defective Element'); grid on;
                if myDM.printPlotsEnable
                    imageNumber = '1';
                    print(fullfile(pwd,'Out',['elementType-TD','-',imageNumber]),'-djpeg91', '-r180');
                end
                if strcmpi(myDM.plotVisible, 'off')
                    close
                end
            end
        end
    end
%     
%     methods (Access = protected, Static = true)
%         
%         [similarity, severity, tag] = bearing_defect_function(base, config); % HF (+MF) - PULSE 
%         [similarity, severity, tag] = belting_defect_function(base, config); % HF () 
%         [similarity, severity, tag] = gearing_defect_function(base, config); % MF (+HF) - PULSECONTINUOUS/CONTINUOUS
%         [similarity, severity, tag] = generator_defect_function(base, config); % MF (+ HF smtimes)
%         [similarity, severity, tag] = shaft_defect_function(base, config); % MF (or LF) - currently unused...
%         
%     end
    
    methods (Static =true, Access = protected)
        
        % Find elements near the datapoint to help in element identification
        function [elementsClasses] = findElements(myElementsList)
            
            elementsClasses = cell(numel(myElementsList),1); 
            for i = 1:numel(myElementsList)
                switch(myElementsList{i})
                    case 'rollingBearing'
                        elementsClasses{i} = 'bearing';
                    case 'inductionMotor'
                        elementsClasses{i} = 'generator';
                    otherwise 
                        elementsClasses(i) = myElementsList(i);
                end
            end
            elementsClasses = unique(elementsClasses);
        end
        
    end
end

