classdef statusWriter < handle
    
    properties
        docNode
        docRootNode
        timeNode
        totalTimeNode
        config
    end
 
    methods (Static)
        function [singleObj] = getInstance
            persistent Obj
            if isempty(Obj) || ~isvalid(Obj)
                Obj = statusWriter;
            end
            singleObj = Obj;
        end
    end

    methods

        % Destructor method
        function delete(obj)
            delete(obj);
            disp('StatusWriter object is deleted');
        end
        
%%---------------------Base functions------------------------------------%%
        function [myStatusWriter] = addData (methodTag, varargin)
            
            switch(methodTag)
                case 'createBaseDocNode'
                    [myStatusWriter] = createBaseDocNode(varargin{1},varargin{2},varargin{3});
                case 'equipmentStateDetection'
                    [myStatusWriter] = equipmentStateDetection(varargin{1}, varargin{2}, varargin{3});
                case 'frequencyCorrector'
                    [myStatusWriter] = frequencyCorrector(varargin{1},varargin{2},varargin{3},varargin{4});
                case 'frequencyTracking'
                    [myStatusWriter] = frequencyTracking(varargin{1},varargin{2});
                case 'scalogram'
                    [myStatusWriter] = scalogram(varargin{1},varargin{2},varargin{3});
                case 'periodicity'
                    [myStatusWriter] = periodicity(varargin{1},varargin{2});
                case 'iso7919'
                    [myStatusWriter] = iso7919(varargin{1}, varargin{2});
                case 'vdi3834'
                    [myStatusWriter] = vdi3834(varargin{1}, varargin{2});
                case 'spmDBmDBc'
                    [myStatusWriter] = spmDBmDBc(varargin{1},varargin{2});
                case 'spmLRHR'
                    [myStatusWriter] = spmLRHR(varargin{1},varargin{2});
                case 'iso15242'
                    [myStatusWriter] = iso15242(varargin{1},varargin{2},varargin{3},varargin{4},varargin{5});
                case 'octaveSpectrum'
                    [myStatusWriter] = octaveSpectrum(varargin{1},varargin{2});
                case 'processingTime'
                    [myStatusWriter] = processingTime(varargin{1},varargin{2});
                case 'processingTimeHistory'
                    [myStatusWriter] = processingTimeHistory(varargin{1},varargin{2});
                case 'timeDomainClassifier'
                    [myStatusWriter] = processingTimeDomainClassifier(varargin{1},varargin{2});
                case 'BFSpectrum'
                    [myStatusWriter] = BFSpectrum(varargin{1},varargin{2});
                case 'shaftTrajectory'
                    [myStatusWriter] = shaftTrajectory(varargin{1},varargin{2});
                case 'timeSynchronousAveraging'
                    [myStatusWriter] = timeSynchronousAveraging(varargin{1},varargin{2});
                otherwise
                    error('StatusWriter:addData','Incorrect method tag!')
            end
        end
        
        function printStatus(myStatusWriter, mode)
            if nargin == 2
                if strcmp(mode, 'temp')
                    % Save temp.xml to the .../Out directory
                    fileName = [myStatusWriter.config.nameTempStatusFile '.xml'];
                    xmlFileName = fullfile(pwd,'Out', fileName);
                    xmlwrite(xmlFileName,myStatusWriter.docNode);
                else % mode is 'status'
                    
                    % To delete temp.xml from the .../Out directory
                    fileNameTemp = [myStatusWriter.config.nameTempStatusFile '.xml'];
                    pathTempFile = fullfile(pwd,'Out', fileNameTemp);
                    if exist(pathTempFile, 'file')
                        delete(pathTempFile);
                    end
                    
                    % Save status.xml to the .../Out directory
                    fileName = 'status.xml';
                    xmlFileName = fullfile(pwd,'Out', fileName);
                    xmlwrite(xmlFileName,myStatusWriter.docNode);
                end
            else
                % Save status.xml to the .../Out directory
                fileName = 'status.xml';
                xmlFileName = fullfile(pwd,'Out', fileName);
                xmlwrite(xmlFileName,myStatusWriter.docNode);
            end
        end    
%% ----------------------- Subfunctions -------------------------------- %%        
        function [myStatusWriter] = createBaseDocNode(myStatusWriter,classifierStruct,config)
            
            % Create docNode element with Base parameters
            myStatusWriter.docNode = com.mathworks.xml.XMLUtils.createDocument('equipment');
            myStatusWriter.docRootNode = myStatusWriter.docNode.getDocumentElement;
            deviceName = classifierStruct.common.equipmentName;
            myStatusWriter.docRootNode.setAttribute('version',config.version);
            myStatusWriter.docRootNode.setAttribute('name',deviceName);       % get device name from equipmentProfile         
            myStatusWriter.docRootNode.setAttribute('equipmentState','unknown');	
            
            % Set id of equipmentProfile for validating in history
            if isfield(config.idEquipmentProfile, 'id')
                myStatusWriter.docRootNode.setAttribute('idEquipmentProfile', config.idEquipmentProfile.id); 
            else
                myStatusWriter.docRootNode.setAttribute('idEquipmentProfile', ''); 
            end
            
            myStatusWriter.docRootNode.setAttribute('signalStates', config.signalStates)
            
            % Set current calculation time to status file
            myStatusWriter.timeNode = myStatusWriter.docNode.createElement('processingTime');
            myStatusWriter.docRootNode.appendChild(myStatusWriter.timeNode);
            myStatusWriter.config = config;
        end
        
        function [myStatusWriter] = equipmentStateDetection(myStatusWriter, equipmentState, Data)
            
            % Update the equipmentState attribute
            myStatusWriter.docRootNode.setAttribute('equipmentState', equipmentState);
            
            % Create the equipmentState node
            equipmentStateNode = myStatusWriter.docNode.createElement('equipmentState');
            
            % Get metrics names
            metricsFieldsNames = fieldnames(Data);
            
            % Create the status node
            statusNode = myStatusWriter.docNode.createElement('status');
            % Create the informativeTags node
            informativeTagsNode = myStatusWriter.docNode.createElement('informativeTags');
            
            for metricNumber = 1 : 1 : length(metricsFieldsNames)
                metricName = metricsFieldsNames{metricNumber};
                
                % Create the status node of current metric
                metricStatusNode = myStatusWriter.docNode.createElement(metricName);
                % Set attributes of the node
                metricStatusNode.setAttribute('value', ...
                    Data.(metricName).state);
                % Set the node to the status node
                statusNode.appendChild(metricStatusNode);
                
                % Create the informativeTags node of current metric
                metricInformativeTagsNode = myStatusWriter.docNode.createElement(metricName);
                % Set attributes of the node
                metricInformativeTagsNode.setAttribute('value', ...
                    num2str(Data.(metricName).value));
                metricInformativeTagsNode.setAttribute('weight', ...
                    num2str(Data.(metricName).weight));
                metricInformativeTagsNode.setAttribute('onBoundaries', []);
                metricInformativeTagsNode.setAttribute('idleBoundaries', []);
                metricInformativeTagsNode.setAttribute('offBoundaries', []);
                % Set the node to the informativeTags node
                informativeTagsNode.appendChild(metricInformativeTagsNode);
            end
            
            % Set the status and informativeTags nodes to the
            % equipmentState node
            if hasChildNodes(statusNode) && hasChildNodes(informativeTagsNode)
                equipmentStateNode.appendChild(statusNode);
                equipmentStateNode.appendChild(informativeTagsNode);
            end
            
            % Set the equipmentState node to the docRoot node
            myStatusWriter.docRootNode.appendChild(equipmentStateNode);
        end
        
        function [myStatusWriter] = frequencyCorrector(myStatusWriter,origFreqVect,estimFreqVect,myResult)
            
            % Add frequencyCorrector data to docNode element
            frequencyCorrectorNode = myStatusWriter.docNode.createElement('frequencyCorrector');
            statusNode = myStatusWriter.docNode.createElement('status');
            frequencyCorrectorNode.appendChild(statusNode);
            informativeTagsNode = myStatusWriter.docNode.createElement('informativeTags');
            frequencyCorrectorNode.appendChild(informativeTagsNode);
            
            initialFrequencyNode = myStatusWriter.docNode.createElement('initialFrequency');
            informativeTagsNode.appendChild(initialFrequencyNode);
            estimatedFrequencyNode = myStatusWriter.docNode.createElement('estimatedFrequency');
            informativeTagsNode.appendChild(estimatedFrequencyNode);
            validityNode = myStatusWriter.docNode.createElement('validity');
            informativeTagsNode.appendChild(validityNode);
            
            initialFrequencyNode.setAttribute( 'value', vector2strStandardFormat(origFreqVect.freq(1)));
            estimatedFrequencyNode.setAttribute('value', vector2strStandardFormat(estimFreqVect.freq(1)));
            validityNode.setAttribute('value', vector2strStandardFormat(myResult.validity));
            
            if isempty(myResult.validity)
                myResult.validity = 0;
            end
            statusNode.setAttribute('value', vector2strStandardFormat(min([myResult.validity, 100])));
            
            myStatusWriter.docRootNode.appendChild(frequencyCorrectorNode);
        end
        
        function [myStatusWriter] = frequencyTracking(myStatusWriter,myResult)
            
            % Add frequencyCorrector data to docNode element
            frequencyCorrectorNode = myStatusWriter.docNode.createElement('frequencyTracking');
            statusNode = myStatusWriter.docNode.createElement('status');
            
            frequencyCorrectorNode.appendChild(statusNode);
            informativeTagsNode = myStatusWriter.docNode.createElement('informativeTags');
            frequencyCorrectorNode.appendChild(informativeTagsNode);
            
            validityNode = myStatusWriter.docNode.createElement('validity');
            informativeTagsNode.appendChild(validityNode);
            typeNode = myStatusWriter.docNode.createElement('type');
            informativeTagsNode.appendChild(typeNode);
            
            validityNode.setAttribute('value', vector2strStandardFormat(myResult.validity));
            typeNode.setAttribute('value', myResult.type);
            statusNode.setAttribute('value', vector2strStandardFormat(myResult.status));
            
            myStatusWriter.docRootNode.appendChild(frequencyCorrectorNode);
        end
        
        function [myStatusWriter] = scalogram(myStatusWriter,myScalogramHandler,octaveScalogram)
        
            % Add scalogram data to docNode element
            scalogramCommonNode = myStatusWriter.docNode.createElement('scalogram'); 
            scalogramCommonNode.setAttribute('waveletName', getWaveletName(myScalogramHandler)); 
            myStatusWriter.docRootNode.appendChild(scalogramCommonNode);

            statusNode = myStatusWriter.docNode.createElement('status');
            statusNode.setAttribute('value','1'); 

            informativeTagsNode = myStatusWriter.docNode.createElement('informativeTags');

            freqScalogramNode = myStatusWriter.docNode.createElement('frequencies');
            freqScalogramNode.setAttribute('value',vector2strStandardFormat(octaveScalogram.frequencies));
            coefficientsScalogramNode = myStatusWriter.docNode.createElement('coefficients');
            coefficientsScalogramNode.setAttribute('value',vector2strStandardFormat(octaveScalogram.coefficients));
            tagsScalogramNode = myStatusWriter.docNode.createElement('tags');
            tagsScalogramNode.setAttribute('value',[]);

            trainingPeriodMeanNode = myStatusWriter.docNode.createElement('trainingPeriodMean');
            trainingPeriodMeanNode.setAttribute('value',[]);
            trainingPeriodStdNode = myStatusWriter.docNode.createElement('trainingPeriodStd');
            trainingPeriodStdNode.setAttribute('value',[]);

            informativeTagsNode.appendChild(freqScalogramNode);
            informativeTagsNode.appendChild(coefficientsScalogramNode);
            informativeTagsNode.appendChild(tagsScalogramNode);
            informativeTagsNode.appendChild(trainingPeriodMeanNode);
            informativeTagsNode.appendChild(trainingPeriodStdNode);

            scalogramCommonNode.appendChild(statusNode);
            scalogramCommonNode.appendChild(informativeTagsNode);
        end
        
        function [myStatusWriter] = periodicity(myStatusWriter,resultForDocNode)
            
            % Add timeDomain data to docNode element
            periodicityNode = myStatusWriter.docNode.createElement('periodicity');
            myStatusWriter.docRootNode.appendChild(periodicityNode);
            
            statusNode = myStatusWriter.docNode.createElement('status');
            statusNode.setAttribute('value', ''); 
            
            informativeTagsNode = myStatusWriter.docNode.createElement('informativeTags');
            
            frequencyTimeDomainNode = myStatusWriter.docNode.createElement('frequency');
            frequencyTimeDomainNode.setAttribute('value',vector2strStandardFormat(resultForDocNode.frequency));
            energyContributionTimeDomainNode = myStatusWriter.docNode.createElement('energyContribution');
            energyContributionTimeDomainNode.setAttribute('value',vector2strStandardFormat(resultForDocNode.energyContribution));
            
            traningPeriodNode = myStatusWriter.docNode.createElement('traninPeriod');
            traningPeriodNode.setAttribute('mean',[]);
            traningPeriodNode.setAttribute('std',[]);
            traningPeriodNode.setAttribute('status',[]);
            traningPeriodNode.setAttribute('frequency',[]);
            
            validityTimeDomainNode = myStatusWriter.docNode.createElement('validity');
            validityTimeDomainNode.setAttribute('value',vector2strStandardFormat(resultForDocNode.validity));
            typePeriodicityNode = myStatusWriter.docNode.createElement('type');
            typePeriodicityNode.setAttribute('value',vector2strStandardFormat(resultForDocNode.type));
            resonantFrequencyTimeDomainNode = myStatusWriter.docNode.createElement('resonantFrequency');
            resonantFrequencyTimeDomainNode.setAttribute('value',vector2strStandardFormat(resultForDocNode.resonantFrequency));
            averageAmplTimeDomainNode = myStatusWriter.docNode.createElement('averageAmpl');
            averageAmplTimeDomainNode.setAttribute('value',vector2strStandardFormat(resultForDocNode.averageAmpl));
            filtrationRangeTimeDomainNode = myStatusWriter.docNode.createElement('filtrationRange');
            filtrationRangeTimeDomainNode.setAttribute('value',resultForDocNode.filtrationRange);
            % Add zero validity field 2 save the common format - it will be filled in history.
            historyValidityTimeDomainNode = myStatusWriter.docNode.createElement('historyValidity');
            numb = [];
            if ~isempty(resultForDocNode.validity)
                numb = str2num(resultForDocNode.validity);
            end
            numb = zeros(size(numb)); 
            str = num2str(numb);
            historyValidityTimeDomainNode.setAttribute( 'value', vector2strStandardFormat(str) );
            
            informativeTagsNode.appendChild(frequencyTimeDomainNode);
            informativeTagsNode.appendChild(energyContributionTimeDomainNode);
%             informativeTagsNode.appendChild(traningPeriodNode);
            informativeTagsNode.appendChild(validityTimeDomainNode);
            informativeTagsNode.appendChild(typePeriodicityNode);
            informativeTagsNode.appendChild(resonantFrequencyTimeDomainNode);
            informativeTagsNode.appendChild(averageAmplTimeDomainNode);
            informativeTagsNode.appendChild(filtrationRangeTimeDomainNode);
            informativeTagsNode.appendChild(historyValidityTimeDomainNode);
            
            periodicityNode.appendChild(statusNode);
            periodicityNode.appendChild(informativeTagsNode);
        end
        
        function [myStatusWriter] = iso7919(myStatusWriter, resultStruct)
        
            % Create the method node
            iso7919Node = myStatusWriter.docNode.createElement('iso7919');
            
            % Create status and informativeTags nodes
            statusNode = myStatusWriter.docNode.createElement('status');
            informativeTagsNode = myStatusWriter.docNode.createElement('informativeTags');
            
            for shaftNumber = 1 : 1 : length(resultStruct)
                % Create the shaft node for the status node
                statusShaftNode = myStatusWriter.docNode.createElement(resultStruct(shaftNumber).name);
                statusShaftNode.setAttribute('value', resultStruct(shaftNumber).status);
                % Set the shaft node to the status node
                statusNode.appendChild(statusShaftNode);
                
                % Create the shaft node for the informativeTags node
                infTagsShaftNode = myStatusWriter.docNode.createElement(resultStruct(shaftNumber).name);
                infTagsShaftNode.setAttribute('frequency', num2str(resultStruct(shaftNumber).freq));
                infTagsShaftNode.setAttribute('value', num2str(resultStruct(shaftNumber).value));
                infTagsShaftNode.setAttribute('thresholds', vector2strStandardFormat(resultStruct(shaftNumber).thresholds));
                % Set the shaft node to the informativeTags node
                informativeTagsNode.appendChild(infTagsShaftNode);
            end
            
            % Set status and informativeTags nodes to the method node
            iso7919Node.appendChild(statusNode);
            iso7919Node.appendChild(informativeTagsNode);
            
            % Set the method node to the root node
            myStatusWriter.docRootNode.appendChild(iso7919Node);
            
        end
        
        function [myStatusWriter] = vdi3834(myStatusWriter, resultStruct)
            
            % Create the method node
            vdi3834Node = myStatusWriter.docNode.createElement('vdi3834');
            
            % Create status and informativeTags nodes
            statusNode = myStatusWriter.docNode.createElement('status');
            informativeTagsNode = myStatusWriter.docNode.createElement('informativeTags');
            
			% Get component names
            componentNames = fieldnames(resultStruct);
            
            for componentNumber = 1 : 1 : length(componentNames)
                
                % Get the component name
                componentName = componentNames{componentNumber};
                
                if isempty(resultStruct.(componentName))
                    continue;
                end
                
                % Create the component node of the status node
                statusComponentNode = myStatusWriter.docNode.createElement(componentName);
                % Create the component node of the informativeTags node
                infTagsComponentNode = myStatusWriter.docNode.createElement(componentName);
                
                % Get area names of the component
                areaNames = fieldnames(resultStruct.(componentName));
                
                for areaNumber = 1 : 1 : length(areaNames)
                    
                    % Get the area name
                    areaName = areaNames{areaNumber};
                    
                    if isempty(resultStruct.(componentName).(areaName))
                        continue;
                    end
                    
                    % Create the area node of the component status node
                    statusAreaNode = myStatusWriter.docNode.createElement(areaName);
                    % Create the area node of the component informativeTags node
                    infTagsAreaNode = myStatusWriter.docNode.createElement(areaName);
                                            
                    % Get field names of the area
                    areaFieldNames = fieldnames(resultStruct.(componentName).(areaName));
                    
                    for fieldNumber = 1 : 1 : length(areaFieldNames)
                        
                        % Get the field name
                        fieldName = areaFieldNames{fieldNumber};
                        % Join data in the area field
                        areaJointStruct.(fieldName) = {resultStruct.(componentName).(areaName).(fieldName)};
                    end
                    
                    resultStruct.(componentName).(areaName) = areaJointStruct;
                    
                    % Fill the area node of the status node
                    statusAreaNode.setAttribute('value', ...
                        vector2strStandardFormat(resultStruct.(componentName).(areaName).status));
                    % Fill the area node of the informativeTags node
                    infTagsAreaNode.setAttribute('value', ...
                        vector2strStandardFormat(resultStruct.(componentName).(areaName).value));
                    infTagsAreaNode.setAttribute('band', ...
                        regexprep(strjoin(cellfun(@num2str, resultStruct.(componentName).(areaName).band, 'UniformOutput', false), ','), ' +', ' '));
                    
                    % Set the area node to the component status node
                    statusComponentNode.appendChild(statusAreaNode);
                    % Set the area node to the component informativeTags
                    % node
                    infTagsComponentNode.appendChild(infTagsAreaNode);
                end
                
                if hasChildNodes(statusComponentNode) && hasChildNodes(infTagsComponentNode)
                    
                    % Set the component node to the status node
                    statusNode.appendChild(statusComponentNode);
                    % Set the component node to the informativeTags node
                    informativeTagsNode.appendChild(infTagsComponentNode);
                end
            end
            
            if hasChildNodes(statusNode) && hasChildNodes(informativeTagsNode)
                
                % Set status and informativeTags nodes to the method node
                vdi3834Node.appendChild(statusNode);
                vdi3834Node.appendChild(informativeTagsNode);
            end
            
            % Set the method node to the root node
            myStatusWriter.docRootNode.appendChild(vdi3834Node);
            
        end
        
        function [myStatusWriter] = processingTimeDomainClassifier(myStatusWriter,resultForDocNode)
           
            % Add patternClassifier data to docNode element
            patternClassificationNode = myStatusWriter.docNode.createElement('timeDomainClassifier');
            myStatusWriter.docRootNode.appendChild(patternClassificationNode);
            
            % Status Node
            statusNode = myStatusWriter.docNode.createElement('status');
            statusNode.setAttribute('elementType',resultForDocNode.element); 
            statusNode.setAttribute('similarity',num2str(resultForDocNode.similarity)); 
            statusNode.setAttribute('similarityTrend',''); 
            statusNode.setAttribute('severity',num2str(resultForDocNode.severity)); 
            statusNode.setAttribute('tag',num2str(resultForDocNode.tag));
            statusNode.setAttribute('value',num2str(resultForDocNode.status)); 
            
            % InformativeTags Node
            informativeTagsNode = myStatusWriter.docNode.createElement('informativeTags');
            
            frequencynNode = myStatusWriter.docNode.createElement('frequency');
            frequencynNode.setAttribute('value',num2str([resultForDocNode.base.resonantFrequency]));
            
            frequencynNode.setAttribute('tag',strjoin({resultForDocNode.base.resonantTag},', '));
            
            if length(resultForDocNode.base) == 1
                if ischar(resultForDocNode.base.signalType)
                    resultForDocNode.base.signalType = {resultForDocNode.base.signalType};
                end
                if ischar(resultForDocNode.base.ptrn_elementType)
                    resultForDocNode.base.ptrn_elementType = {resultForDocNode.base.ptrn_elementType};
                end
            end
            
            signalTypeNode = myStatusWriter.docNode.createElement('signalType');
            signalTypeNode.setAttribute('value',strjoin([resultForDocNode.base.signalType],', '));
            
            periodicityNode = myStatusWriter.docNode.createElement('periodicity');
            periodicityNode.setAttribute('value', num2str(arrayfun(@(x) ~isempty(x.prd_frequency),resultForDocNode.base)'));
            
            patternTypeNode = myStatusWriter.docNode.createElement('patternType');
            if ischar([resultForDocNode.base.ptrn_elementType])
                patternTypeNode.setAttribute('value', strjoin({resultForDocNode.base.ptrn_elementType},', '));
            else
                patternTypeNode.setAttribute('value', strjoin([resultForDocNode.base.ptrn_elementType],', '));
            end
            
            equipmentTypeNode = myStatusWriter.docNode.createElement('equipmentType');
            equipmentTypeNode.setAttribute('value', strjoin({resultForDocNode.base.equip_elementType},', '));
            
            informativeTagsNode.appendChild(frequencynNode);
            informativeTagsNode.appendChild(signalTypeNode);
            informativeTagsNode.appendChild(periodicityNode);
            informativeTagsNode.appendChild(patternTypeNode);
            informativeTagsNode.appendChild(equipmentTypeNode);
            
            patternClassificationNode.appendChild(statusNode);
            patternClassificationNode.appendChild(informativeTagsNode);
            
        end
        
        function [myStatusWriter] = spmDBmDBc(myStatusWriter,structDBmDBc)
            
            iLoger = loger.getInstance;
            
            if exist('structDBmDBc','var')
                if isfield(structDBmDBc,'c') ...
                        && isfield(structDBmDBc,'m') ...
                        && isfield(structDBmDBc,'firstLevel') ...
                        && isfield(structDBmDBc,'status') ...
                        && isfield(structDBmDBc,'currentLowLevel') ...
                        && isfield(structDBmDBc,'currentHighLevel')
                    if (structDBmDBc.c > 0) ...
                            && (structDBmDBc.m > 0) ...
                            && (structDBmDBc.firstLevel > 0) ...
                            && isa(structDBmDBc.status,'numeric') ...
                            && isa(structDBmDBc.currentLowLevel,'char') ...
                            && isa(structDBmDBc.currentHighLevel,'char')
                        printComputeInfo(iLoger, 'SPM method', 'SPM: dBm/dBc method returned result exist.'); %RTG: Used for auto-testing
                    end
                end
            end
            
            % Set "SPM: dBc/dBm" levels to docNode element
            SPMNode = myStatusWriter.docNode.createElement('spmDBmDBc');
            myStatusWriter.docRootNode.appendChild(SPMNode);

            statusNode = myStatusWriter.docNode.createElement('status');
            
            dBcNodeStatus = myStatusWriter.docNode.createElement('dBc');
            
            dBcNodeStatus.setAttribute('trend', []);
            dBcNodeStatus.setAttribute('volatility', []);
            dBcNodeStatus.setAttribute('volatilityLevel', []);
            
            dBmNodeStatus = myStatusWriter.docNode.createElement('dBm');
            
            dBmNodeStatus.setAttribute('trend', []);
            dBmNodeStatus.setAttribute('volatility', []);
            dBmNodeStatus.setAttribute('volatilityLevel', []);
            
            statusNode.setAttribute('value',num2str(structDBmDBc.status)'); 

            statusNode.appendChild(dBcNodeStatus);
            statusNode.appendChild(dBmNodeStatus);
            
            informativeTagsNode = myStatusWriter.docNode.createElement('informativeTags');

            dBcNode = myStatusWriter.docNode.createElement('dBc');
            dBcNode.setAttribute('value',num2str(structDBmDBc.c));    
            dBcNode.setAttribute('status',structDBmDBc.currentLowLevel); % state level to the specified level      
            dBcNode.setAttribute('trainingPeriodMean',[]); 
            dBcNode.setAttribute('trainingPeriodStd',[]); 
            dBcNode.setAttribute('trainingPeriodStd',[]);
            dBcNode.setAttribute('durationStatus',[]);

            dBmNode = myStatusWriter.docNode.createElement('dBm');
            dBmNode.setAttribute('value',num2str(structDBmDBc.m));
            dBmNode.setAttribute('status',structDBmDBc.currentHighLevel); % state level to the specified level
            dBmNode.setAttribute('trainingPeriodMean',[]); 
            dBmNode.setAttribute('trainingPeriodStd',[]); 
            dBmNode.setAttribute('durationStatus',[]);

            zeroLevelNode = myStatusWriter.docNode.createElement('zeroLevel');
            zeroLevelNode.setAttribute('value',num2str(structDBmDBc.firstLevel));

            informativeTagsNode.appendChild(dBcNode);
            informativeTagsNode.appendChild(dBmNode);
            informativeTagsNode.appendChild(zeroLevelNode);

            SPMNode.appendChild(statusNode);
            SPMNode.appendChild(informativeTagsNode);
        end
        
        function [myStatusWriter] = spmLRHR(myStatusWriter,structLRHR)
            
            iLoger = loger.getInstance;
            
            if exist('structLRHR','var')
                if isfield(structLRHR,'hR') ...
                        && isfield(structLRHR,'lR') ...
                        && isfield(structLRHR,'status') ...
                        && isfield(structLRHR,'currentLowLevel')...
                        && isfield(structLRHR,'currentHighLevel')
                    if (structLRHR.hR > 0) ...
                            && (structLRHR.lR > 0) ...
                            && isa(structLRHR.status,'numeric') ...
                            && isa(structLRHR.currentLowLevel,'char') ...
                            && isa(structLRHR.currentHighLevel,'char')
                        printComputeInfo(iLoger, 'SPM method', 'SPM: LR/HR method returned result exist.'); %RTG: Used for auto-testing
                    end
                end
            end
            
            % Set "SPM: HR/LR" levels to docNode element
            SPMNode = myStatusWriter.docNode.createElement('spmLRHR');
            myStatusWriter.docRootNode.appendChild(SPMNode);

            statusNode = myStatusWriter.docNode.createElement('status');
            
            hRNodeStatus = myStatusWriter.docNode.createElement('hR');
            hRNodeStatus.setAttribute('trend', []);
            hRNodeStatus.setAttribute('volatility', []);
            hRNodeStatus.setAttribute('volatilityLevel', []);
            hRNodeStatus.setAttribute('statusOfHistory', []);
            
            lRNodeStatus = myStatusWriter.docNode.createElement('lR');
            lRNodeStatus.setAttribute('trend', []);
            lRNodeStatus.setAttribute('volatility', []);
            lRNodeStatus.setAttribute('volatilityLevel', []);
            lRNodeStatus.setAttribute('statusOfHistory', []);
            
            deltaNodeStatus = myStatusWriter.docNode.createElement('delta');
            deltaNodeStatus.setAttribute('trend', []);
            deltaNodeStatus.setAttribute('volatility', []);
            deltaNodeStatus.setAttribute('volatilityLevel', []);
            deltaNodeStatus.setAttribute('statusOfHistory', []);
            
            statusNode.appendChild(hRNodeStatus);
            statusNode.appendChild(lRNodeStatus);
            statusNode.appendChild(deltaNodeStatus);
            
            statusNode.setAttribute('value',num2str(structLRHR.status)); 

            informativeTagsNode = myStatusWriter.docNode.createElement('informativeTags');

            hRNode = myStatusWriter.docNode.createElement('hR');
            hRNode.setAttribute('value',num2str(structLRHR.hR));   
            hRNode.setAttribute('status',structLRHR.currentLowLevel); 
            hRNode.setAttribute('trainingPeriodMean',[]); 
            hRNode.setAttribute('trainingPeriodStd',[]); 
            hRNode.setAttribute('durationStatus',[]); 

            lRNode = myStatusWriter.docNode.createElement('lR');
            lRNode.setAttribute('value',num2str(structLRHR.lR));
            lRNode.setAttribute('status',structLRHR.currentHighLevel); 
            lRNode.setAttribute('trainingPeriodMean',[]); 
            lRNode.setAttribute('trainingPeriodStd',[]); 
            lRNode.setAttribute('durationStatus',[]); 
            
            deltaNode = myStatusWriter.docNode.createElement('delta');
            deltaNode.setAttribute('value',num2str(structLRHR.lR - structLRHR.hR));
            deltaNode.setAttribute('status',[]);
            deltaNode.setAttribute('trainingPeriodMean',[]);
            deltaNode.setAttribute('trainingPeriodStd',[]);
            deltaNode.setAttribute('durationStatus',[]);
            
            informativeTagsNode.appendChild(hRNode);
            informativeTagsNode.appendChild(lRNode);
            informativeTagsNode.appendChild(deltaNode);

            SPMNode.appendChild(statusNode);
            SPMNode.appendChild(informativeTagsNode);
        end
        
        function [myStatusWriter] = iso15242(myStatusWriter,vRms1Log,vRms2Log,vRms3Log,statusRmsLog)
            
            iLoger = loger.getInstance;
            
            if exist('vRms1Log','var') && exist('vRms2Log','var') && exist('vRms3Log','var') && exist('statusRmsLog','var')
                if (vRms1Log > 0) && (vRms2Log > 0) && (vRms3Log > 0)
                    printComputeInfo(iLoger, 'ISO15242 method', 'ISO15242 method returned result exist.'); %RTG: Used for auto-testing
                end
            end
            
            % Set spectral method levels to status file
            iso15242Node = myStatusWriter.docNode.createElement('iso15242');
            myStatusWriter.docRootNode.appendChild(iso15242Node);
            
            statusNode = myStatusWriter.docNode.createElement('status');
            
            vRms1LogNodeStatus = myStatusWriter.docNode.createElement('vRms1Log');
            vRms1LogNodeStatus.setAttribute('trend','');
            vRms1LogNodeStatus.setAttribute('statusOfHistory', '');
            vRms1LogNodeStatus.setAttribute('volatility', '');
            vRms1LogNodeStatus.setAttribute('volatilityLevel', '');
            
            vRms2LogNodeStatus = myStatusWriter.docNode.createElement('vRms2Log');
            vRms2LogNodeStatus.setAttribute('trend','');
            vRms2LogNodeStatus.setAttribute('statusOfHistory', '');
            vRms2LogNodeStatus.setAttribute('volatility', '');
            vRms2LogNodeStatus.setAttribute('volatilityLevel', '');
            
            vRms3LogNodeStatus = myStatusWriter.docNode.createElement('vRms3Log');
            vRms3LogNodeStatus.setAttribute('trend','');
            vRms3LogNodeStatus.setAttribute('statusOfHistory', '');
            vRms3LogNodeStatus.setAttribute('volatility', '');
            vRms3LogNodeStatus.setAttribute('volatilityLevel', '');
            
            statusNode.appendChild(vRms1LogNodeStatus);
            statusNode.appendChild(vRms2LogNodeStatus);
            statusNode.appendChild(vRms3LogNodeStatus);
            
            statusNode.setAttribute('value','1'); 
            
            informativeTagsNode = myStatusWriter.docNode.createElement('informativeTags');
            
            vRms1LogNode = myStatusWriter.docNode.createElement('vRms1Log');
            vRms1LogNode.setAttribute('value',num2str(vRms1Log));
            vRms1LogNode.setAttribute('trainingPeriodMean',[]); 
            vRms1LogNode.setAttribute('trainingPeriodStd',[]); 
            vRms1LogNode.setAttribute('durationStatus',[]); 
            
            vRms2LogNode = myStatusWriter.docNode.createElement('vRms2Log');
            vRms2LogNode.setAttribute('value',num2str(vRms2Log));
            vRms2LogNode.setAttribute('trainingPeriodMean',[]); 
            vRms2LogNode.setAttribute('trainingPeriodStd',[]); 
            vRms2LogNode.setAttribute('durationStatus',[]); 
            
            vRms3LogNode = myStatusWriter.docNode.createElement('vRms3Log');
            vRms3LogNode.setAttribute('value',num2str(vRms3Log));
            vRms3LogNode.setAttribute('trainingPeriodMean',[]); 
            vRms3LogNode.setAttribute('trainingPeriodStd',[]); 
            vRms3LogNode.setAttribute('durationStatus',[]); 
            
            vRms1LogNode.setAttribute('status',statusRmsLog(1)); 
            vRms2LogNode.setAttribute('status',statusRmsLog(2)); 
            vRms3LogNode.setAttribute('status',statusRmsLog(3)); 
            
            informativeTagsNode.appendChild(vRms1LogNode);
            informativeTagsNode.appendChild(vRms2LogNode);
            informativeTagsNode.appendChild(vRms3LogNode);
            
            iso15242Node.appendChild(statusNode);
            iso15242Node.appendChild(informativeTagsNode);
        end
        
        function [myStatusWriter] = octaveSpectrum(myStatusWriter,File)
            
            % Set octaveSpectrum levels to status file
            octaveSpectrumNode = myStatusWriter.docNode.createElement('octaveSpectrum');
            myStatusWriter.docRootNode.appendChild(octaveSpectrumNode);
            
            statusNode = myStatusWriter.docNode.createElement('status');
            statusNode.setAttribute('value','1'); 
            
            informativeTagsNode = myStatusWriter.docNode.createElement('informativeTags');
            
            freqOctaveSpectrumNode = myStatusWriter.docNode.createElement('frequencies');
            freqOctaveSpectrumNode.setAttribute('value', vector2strStandardFormat(File.acceleration.octaveSpectrum.frequencies));
            magnitudesOctaveSpectrumNode = myStatusWriter.docNode.createElement('magnitudes');
            magnitudesOctaveSpectrumNode.setAttribute('value',vector2strStandardFormat(File.acceleration.octaveSpectrum.amplitude));
            tagsOctaveSpectrumNode = myStatusWriter.docNode.createElement('tags');
            if isempty(File.acceleration.octaveSpectrum.status)
                tagsOctaveSpectrumNode.setAttribute('value',[]);
            else
                tagsOctaveSpectrumNode.setAttribute('value',vector2strStandardFormat(File.acceleration.octaveSpectrum.status));
            end
            
            trainingPeriodMeanNode = myStatusWriter.docNode.createElement('trainingPeriodMean');
            trainingPeriodMeanNode.setAttribute('value',[]);
            trainingPeriodStdNode = myStatusWriter.docNode.createElement('trainingPeriodStd');
            trainingPeriodStdNode.setAttribute('value',[]);
            durationStatusNode = myStatusWriter.docNode.createElement('durationStatus');
            durationStatusNode.setAttribute('value',[]);
            
            informativeTagsNode.appendChild(freqOctaveSpectrumNode);
            informativeTagsNode.appendChild(magnitudesOctaveSpectrumNode);
            informativeTagsNode.appendChild(tagsOctaveSpectrumNode);
            informativeTagsNode.appendChild(trainingPeriodMeanNode);
            informativeTagsNode.appendChild(trainingPeriodStdNode);
            informativeTagsNode.appendChild(durationStatusNode);
            
            octaveSpectrumNode.appendChild(statusNode);
            octaveSpectrumNode.appendChild(informativeTagsNode);
        end
        
        function [myStatusWriter] = processingTime(myStatusWriter,timeData)
            
            nodeNames = fieldnames(timeData);
            for i = 1:numel(nodeNames)
               myNode = myStatusWriter.docNode.createElement(nodeNames{i});
               myNode.setAttribute('value',num2str(round(timeData.(nodeNames{i})),2));
               myStatusWriter.timeNode.appendChild(myNode);
            end

        end
        
        function [myStatusWriter] = processingTimeHistory(myStatusWriter,timeData)
            
            % Add HISTORYTIME to docNode
            historyTimeNode = myStatusWriter.docNode.createElement('historyProcessing');
            historyTimeNode.setAttribute('value',num2str(timeData.historyProcessing));
            myStatusWriter.timeNode.appendChild(historyTimeNode);

%             myStatusWriter.timeNode.removeChild(myStatusWriter.totalTimeNode);
            myStatusWriter.totalTimeNode = myStatusWriter.docNode.createElement('totalTime');
            myStatusWriter.totalTimeNode.setAttribute('value',num2str(timeData.totalTime));
            myStatusWriter.timeNode.appendChild(myStatusWriter.totalTimeNode);
        end
        
        function [myStatusWriter] = shaftTrajectory(myStatusWriter, result)
            
            % Create the method node
            shaftTrajectoryNode = myStatusWriter.docNode.createElement('shaftTrajectory');
            
            % Create status and informativeTags nodes
            statusNode = myStatusWriter.docNode.createElement('status');
            informativeTagsNode = myStatusWriter.docNode.createElement('informativeTags');
            
            for shaftNumber = 1 : 1 : numel(result.status.shaftNumber)
                
                % Create the shaft node for the status node
                shaftStatusNode = myStatusWriter.docNode.createElement(result.status.shaftSchemeName{shaftNumber});
                shaftStatusNode.setAttribute('value', num2str(result.status.ellipticity(shaftNumber)));
                % Set the shaft node to the status node
                statusNode.appendChild(shaftStatusNode);
                
                % Create the shaft node for the informativeTags node
                shaftInfTagsNode = myStatusWriter.docNode.createElement(result.status.shaftSchemeName{shaftNumber});
                shaftInfTagsNode.setAttribute('ellipticity', num2str(result.status.ellipticity(shaftNumber)));
                shaftInfTagsNode.setAttribute('angle', num2str(result.status.elliptAngleDeg(shaftNumber)));
                % Set the shaft node to the informativeTags node
                informativeTagsNode.appendChild(shaftInfTagsNode);
            end
            
            % Set status and informativeTags nodes to the method node
            shaftTrajectoryNode.appendChild(statusNode);
            shaftTrajectoryNode.appendChild(informativeTagsNode);
            
            % Set the method node to the root node
            myStatusWriter.docRootNode.appendChild(shaftTrajectoryNode);
            
        end
        
        function [myStatusWriter] = timeSynchronousAveraging(myStatusWriter, result)
            
            % Create the method node
            tsaNode = myStatusWriter.docNode.createElement('timeSynchronousAveraging');
            
            % Create status and informativeTags nodes
            statusNode = myStatusWriter.docNode.createElement('status');
            informativeTagsNode = myStatusWriter.docNode.createElement('informativeTags');
            
            if ~isempty(result)
                
                status = round(max(cell2num({result.status})));
                if status > 100
                    status = 100;
                end
                
                statusNode.setAttribute('value', num2str(status));

                % Fill status
                allNameGearing = {result.gearingsNames};
                nameUniqGearind = unique(allNameGearing);

                for i = 1:1:length(nameUniqGearind)

                    tempTableGearing = result(strcmpi(allNameGearing, nameUniqGearind{i}));

                    statusGearing = round(max(cell2num({tempTableGearing.status})));
                    if statusGearing > 100
                        statusGearing = 100;
                    end
                    
                    % Create range node for the status node
                    gearingStatusNode = myStatusWriter.docNode.createElement('gearing');
                    gearingStatusNode.setAttribute('gearingName', nameUniqGearind{i});
                    gearingStatusNode.setAttribute('status', num2str(statusGearing));
                    gearingStatusNode.setAttribute('statusOfHistory', '');

                    % Set the shaft node to the status node
                    statusNode.appendChild(gearingStatusNode);
                end

                % Fill informativeTags
                for i = 1:1:length(result)

                    % Create range node for the status node
                    gearingInformativeNode = myStatusWriter.docNode.createElement('gearing');

                    gearingInformativeNode.setAttribute('name', [result(i).gearingsNames '-' ...
                                                                 result(i).shaftsNames '-' ...
                                                                 num2str(result(i).harmonicNumber)]);
                    gearingInformativeNode.setAttribute('validGM', num2str(result(i).validShaftFreq));
                    gearingInformativeNode.setAttribute('validShaftFreq', num2str(result(i).validShaftFreq));
                    gearingInformativeNode.setAttribute('status', num2str(round(result(i).status)));
                    gearingInformativeNode.setAttribute('modulationCoef', num2str(round(result(i).modulationCoef*10000)/10000));
                    gearingInformativeNode.setAttribute('statusOfHistory', '');
                    gearingInformativeNode.setAttribute('statusTag', '');
                    
                    % Set the shaft node to the status node
                    informativeTagsNode.appendChild(gearingInformativeNode);
                end

                % Set status and informativeTags nodes to the method node
                tsaNode.appendChild(statusNode);
                tsaNode.appendChild(informativeTagsNode);

                % Set the method node to the root node
                myStatusWriter.docRootNode.appendChild(tsaNode);
            else
                
                statusNode.setAttribute('value', '0');
                
                % Set status and informativeTags nodes to the method node
                tsaNode.appendChild(statusNode);
                tsaNode.appendChild(informativeTagsNode);

                % Set the method node to the root node
                myStatusWriter.docRootNode.appendChild(tsaNode);
            end
        end
        
        function [myStatusWriter] = BFSpectrum(myStatusWriter, myResult)
            disp('BFSpectrum:    NOP');
        end
    end 
end