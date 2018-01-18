classdef equipmentProfileParser
    % HARDWAREPROFILEPARSER parses the kinematic scheme of the equipment
    % from the XML-file
    
    properties (Access = protected)
        
        profileStruct
        classifierStruct
        shaftMain
        shaftCorrespondenceTable
        fullCorrespondenceTable
        shaftVector
        
        % The place on kinematics where data is gotten
        equipmentDataPoint
        % The list of equipment components
        equipmentComponentsList
        % The list of equipment groups
        equipmentGroupsList
    end
    
    methods (Access = public)
        
        function [myParser] = equipmentProfileParser(myProfileStruct, myEquipmentDataPoint)
            if nargin > 0
                if nargin < 2
                    myParser.equipmentDataPoint = 0;
                else
                    myParser.equipmentDataPoint = myEquipmentDataPoint;
                end
                myParser.profileStruct = myProfileStruct;
                myParser.shaftMain = getShaftFreq(myParser);
                myParser.shaftCorrespondenceTable = createShaftCorrespondenceTable(myParser);
                myParser.shaftVector = createShaftVectorFreq(myParser);
                myParser.fullCorrespondenceTable = createFullCorrespondenceTable(myParser);
                myParser = createClassifierStruct(myParser);
            end
        end
        
        function [myParser] = setProfileStruct(myParser, myProfileStruct)
            if nargin == 2
                myParser.profileStruct = myProfileStruct;
            end
        end
        function [profileStruct] = getProfileStruct(myParser)
            profileStruct = myParser.profileStruct;
        end
        
        function [myParser] = setClassifierStruct(myParser, myClassifierStruct)
            if nargin == 2
                myParser.classifierStruct = myClassifierStruct;
            end
        end
        function [classifierStruct] = getClassifierStruct(myParser)
            classifierStruct = myParser.classifierStruct;
        end
        
        function [myParser] = setShaftFreq(myParser, shaftFreq)
            if nargin == 2
                myParser.shaftMain.freq = shaftFreq;
                myParser = correctShaftVectorWithFreq(myParser, shaftFreq);
                myParser = createClassifierStruct(myParser);
            end
        end
        function [shaftMain] = getShaftFreq(myParser)
            shaftArray = myParser.profileStruct.equipmentProfile.shaft;
            shaftNumber = length(shaftArray);
            for i = 1 : 1 : shaftNumber
                if shaftNumber > 1
                    if isfield(shaftArray{1, i}.Attributes, 'mainShaft')
                        shaftMain.freq = str2num(shaftArray{1, i}.Attributes.speedCollection) / 60;
                        shaftMain.freq = shaftMain.freq(1, 1);
                        shaftMain.name = shaftArray{1, i}.Attributes.schemeName;
                        break;
                    end
                elseif shaftNumber == 1
                    if isfield(shaftArray.Attributes, 'mainShaft')
                        shaftMain.freq = str2num(shaftArray.Attributes.speedCollection) / 60;
                        shaftMain.freq = shaftMain.freq(1, 1);
                        shaftMain.name = shaftArray.Attributes.schemeName;
                        break;
                    end
                end
            end
        end
        
        function [myParser] = setShaftCorrespondenceTable(myParser, myShaftCorrespondenceTable)
            if nargin == 2
                myParser.shaftCorrespondenceTable = myShaftCorrespondenceTable;
            end
        end
        function [myShaftCorrespondenceTable] = getShaftCorrespondenceTable(myParser)
            myShaftCorrespondenceTable = myParser.shaftCorrespondenceTable;
        end
        
        function [myParser] = setFullCorrespondenceTable(myParser, myFullCorrespondenceTable)
            if nargin == 2
                myParser.fullCorrespondenceTable = myFullCorrespondenceTable;
            end
        end
        function [myFullCorrespondenceTable] = getFullCorrespondenceTable(myParser)
            myFullCorrespondenceTable = myParser.fullCorrespondenceTable;
        end
        
        function [myParser] = setShaftVector(myParser, myShaftVector)
            if nargin == 2
                myParser.shaftVector = myShaftVector;
                myParser = createClassifierStruct(myParser);
            end
        end
        function [myShaftVectorFreq] = getShaftVector(myParser)
            myShaftVectorFreq = myParser.shaftVector;
        end
        
        function [myParser] = setEquipmentDataPoint(myParser, myEquipmentDataPoint)
            if nargin == 2
                myParser.equipmentDataPoint = myEquipmentDataPoint;
            end
        end
        function [myEquipmentDataPoint] = getEquipmentDataPoint(myParser)
            myEquipmentDataPoint = myParser.equipmentDataPoint;
        end
        
        function [myParser] = setEquipmentComponentsList(myParser, myEquipmentComponentsList)
            if nargin == 2
                myParser.equipmentComponentsList = myEquipmentComponentsList;
            end
        end
        function [myEquipmentComponentsList] = getEquipmentComponentsList(myParser)
            myEquipmentComponentsList = myParser.equipmentComponentsList;
        end
        
        function [myParser] = setEquipmentGroupsList(myParser, myEquipmentGroupsList)
            if nargin == 2
                myParser.equipmentGroupsList = myEquipmentGroupsList;
            end
        end
        function [myEquipmentGroupsList] = getEquipmentGroupsList(myParser)
            myEquipmentGroupsList = myParser.equipmentGroupsList;
        end
        
        function [equipmentName] = getEquipmentName(myParser)
            if isfield(myParser.classifierStruct.common, 'equipmentName')
                equipmentName = myParser.classifierStruct.common.equipmentName;
            else
                equipmentName = '';
            end
        end
        
        function [myParser] = correctShaftVectorWithFreq(myParser, shaftFreq)
            myShaftVector = bsxfun(@times, ...
                myParser.fullCorrespondenceTable.matrix(strcmp(myParser.fullCorrespondenceTable.name, myParser.shaftMain.name), : ), ...
                shaftFreq);
            myParser.shaftVector.freq = myShaftVector;
        end
    end
    
    methods (Access = protected)
        
        % SHAFTCORRESPONDENCETABLE function creates correspondence table
        % between frequencies of shafts, motors, fans via connection
        % elements
        function [shaftCorrespondenceTable] = createShaftCorrespondenceTable(myParser)
            
            deviceStruct = myParser.profileStruct.equipmentProfile;
            
            if isfield(deviceStruct, 'connection')
                % Get number of element in the scheme
                connectionNumber = length(deviceStruct.connection);
                elementCnt = connectionNumber+1;
             
                shaftCorrespondenceTable.name = cell(elementCnt,1);
                shaftCorrespondenceTable.matrix = zeros(elementCnt);
                
                elementNumber = 0;
                
                % Connection: shaft <-> shaft, shaft <-> motor,
                % shaft <-> fan, motor <-> fan
                for i=1:1:connectionNumber
                    % Get a description of the connection
                    if connectionNumber>1
                        deviceStruct_connection=deviceStruct.connection{1,i};
                    elseif connectionNumber==1
                        deviceStruct_connection=deviceStruct.connection;
                    end
                    
                    % Connection class is GEARING
                    if strfind(deviceStruct_connection.Attributes.classType, 'gearing')
                        
                        % The parameters for calculating connection
                        % coefficients (teeth number)
                        deviceStructTemp = myParser.getTempStruct(deviceStruct_connection, 'teethNumber');
                        
                        % To fill shaftCorrespondenceTable
                        [shaftCorrespondenceTable, elementNumber, modeContinue] = ...
                            myParser.addElementToTable(shaftCorrespondenceTable, elementNumber, elementCnt, deviceStructTemp);
                    
                    % Connection class is BEALTING
                    elseif strfind(deviceStruct_connection.Attributes.classType, 'Belt')
                        
                        % The parameters for calculating connection
                        % coefficients (sheaves diameters)
                        deviceStructTemp = myParser.getTempStruct(deviceStruct_connection, 'sheaveDiameter');
                        
                        % To fill shaftCorrespondenceTable
                        [shaftCorrespondenceTable, elementNumber, modeContinue] = ...
                            myParser.addElementToTable(shaftCorrespondenceTable, elementNumber, elementCnt, deviceStructTemp);
                        
                    % Connection class is PLANETARYSTAGEGEARBOX
                    elseif strfind(deviceStruct_connection.Attributes.classType, 'planetaryStageGearbox')
                        
                        % The parameters for calculating connection 
                        % coefficients  
                        deviceStructTemp = myParser.getTempStructPlanetary(deviceStruct_connection);

                        % To fill shaftCorrespondenceTable
                        [shaftCorrespondenceTable, elementNumber, modeContinue] = ...
                            myParser.addElementToTable(shaftCorrespondenceTable, elementNumber, elementCnt, deviceStructTemp);
                    end
                    
                    if ~modeContinue
                        break;
                    end
                end
            else
                shaftCorrespondenceTable.matrix = 1;
                shaftCorrespondenceTable.name{1,1} = myParser.shaftMain.name;
            end
        end
        
        % CREATESHAFTVECTORFREQ function calculates all shaft frequencies
        % from shaftCorrespondenceTable
        function [shaftVector] = createShaftVectorFreq(myParser)
            % create an empty frequency vector
            shaftVector.freq = zeros(length(myParser.shaftCorrespondenceTable.matrix(1,:)),1);
            % find the main shaft in the shaftCorrespondenceTable, enter 
            % the value the frequency of the main shaft in the frequency vector
            shaftVector.freq(strcmp(myParser.shaftCorrespondenceTable.name,myParser.shaftMain.name)==1) = myParser.shaftMain.freq;          
            tempMatrix = myParser.shaftCorrespondenceTable.matrix;
            prev = shaftVector.freq;
            % forming a vector of frequencies
            k = 0;
            while nnz(shaftVector.freq) ~= length(myParser.shaftCorrespondenceTable.matrix)   
                next = bsxfun(@times,tempMatrix(prev~=0,:),nonzeros(prev));
                tempMatrix(prev>0,:) = 0;
                tempMatrix(:,prev>0) = 0;
                prev = next;
                shaftVector.freq = shaftVector.freq + sum(next,1)';
                if k == length(myParser.shaftCorrespondenceTable.matrix)
                    error('Incorrect filled file equipmentProfile.xml');
                end
                k = k + 1;
            end
            shaftVector.name = myParser.shaftCorrespondenceTable.name;   
        end
        
        % CREATEFULLCORRESPONDENCETABLE function fills all zeros of
        % correspondences tables 
        function [fullCorrespondenceTable] = createFullCorrespondenceTable(myParser)
            % The number of elements in the device
            elementNumber = length(myParser.shaftVector.freq); 
            fullCorrespondenceTable.matrix = zeros(elementNumber);

            % creation of a full correspondences tables
            for i=1:1:elementNumber
                fullCorrespondenceTable.matrix(:,i) = ...
                    bsxfun(@rdivide,myParser.shaftVector.freq(i,1), myParser.shaftVector.freq);
            end
            % entry names, respectively     
            fullCorrespondenceTable.name = myParser.shaftVector.name;
        end
        
        % CREATECLASSIFIERSTRUCT function creates classifier structure of
        % element descriptions 
        function [myParser] = createClassifierStruct(myParser)
            
            % Get a description of the elements
            tempProfileStruct = getProfileStruct(myParser);
            deviceStruct = tempProfileStruct.equipmentProfile;
            
            myParser.classifierStruct.common.equipmentName = deviceStruct.Attributes.equipmentName;
            myParser.classifierStruct.common.equipmentClass = deviceStruct.Attributes.equipmentClass;
            
            % Create structures with a description of the elements
            shaftStruct = [];
            bearingStruct = [];
            connectionStruct = [];
            motorStruct = [];
            couplingStruct = [];
            fanStruct = [];
            
            %% ____________ Checking shafts in the scheme _____________ %%
            
            if isfield(deviceStruct, 'shaft')
                
                shaftNumber = length(deviceStruct.shaft);
                bearingNumber = 0;
                couplingNumber = 0;
                for i = 1 : 1 : shaftNumber
                    
                    % Get the description of the shaft
                    if shaftNumber > 1
                        shaftDeviceStruct = deviceStruct.shaft{1, i};
                    elseif shaftNumber == 1
                        shaftDeviceStruct = deviceStruct.shaft;
                    end
                    
                    % Add the shaft to the shaft structure
                    shaftStruct.shaft(i).name = shaftDeviceStruct.Attributes.schemeName;
                    shaftClassType = strsplit(shaftDeviceStruct.Attributes.classType, ':');
                    shaftStruct.shaft(i).classType = shaftClassType{1};
                    shaftStruct.shaft(i).elementType = 'shaft';
                    if isfield(shaftDeviceStruct.Attributes, 'group')
                        shaftGroup = shaftDeviceStruct.Attributes.group;
                    else
                        shaftGroup = '';
                    end
                    shaftStruct.shaft(i).group = shaftGroup;
                    shaftStruct.shaft(i).enable = str2num(shaftDeviceStruct.Attributes.elementProcessingEnable);
                    if nnz(str2num(shaftDeviceStruct.Attributes.equipmentDataPoint) == str2num(myParser.equipmentDataPoint))
                        shaftStruct.shaft(i).priority = 1;
                        myParser.equipmentComponentsList{end + 1} = shaftStruct.shaft(i).classType;
                        myParser.equipmentGroupsList = [myParser.equipmentGroupsList, strsplit(shaftGroup, ',')];
                    else
                        shaftStruct.shaft(i).priority = 0;
                    end
                    
                    % Find the shaft name in the shaftVector and add
                    % the corresponding frequency to the
                    % shaft structure
                    for j = 1 : 1 : length(myParser.shaftVector.name)
                        if strcmp(myParser.shaftVector.name{j, 1}, shaftStruct.shaft(i).name)
                            shaftStruct.shaft(i).freq = myParser.shaftVector.freq(j);
                            break;
                        end
                    end
                    
                    % The shaft have bearings
                    if isfield(shaftDeviceStruct, 'bearing')
                        
                        % The number of bearings on the shaft
                        shaftBearingNumber = length(shaftDeviceStruct.bearing);
                        
                        % Add the bearing to the bearing structure
                        for j = 1 : 1 : shaftBearingNumber
                            
                            bearingNumber  = bearingNumber + 1;
                            % Get a description of the bearing
                            if shaftBearingNumber > 1
                               bearingDeviceStruct = shaftDeviceStruct.bearing{1, j};
                            elseif shaftBearingNumber == 1
                               bearingDeviceStruct = shaftDeviceStruct.bearing;
                            end
                            
                            % Add common parameters of the bearing
                            bearingStruct.bearing(bearingNumber).name = bearingDeviceStruct.Attributes.schemeName;
                            bearingClassType = strsplit(bearingDeviceStruct.Attributes.classType, ':');
                            bearingStruct.bearing(bearingNumber).classType = bearingClassType{1};
                            bearingStruct.bearing(bearingNumber).elementType = 'bearing';
                            if isfield(bearingDeviceStruct.Attributes, 'group')
                                bearingGroup = bearingDeviceStruct.Attributes.group;
                            else
                                bearingGroup = '';
                            end
                            bearingStruct.bearing(bearingNumber).group = bearingGroup;
                            bearingStruct.bearing(bearingNumber).enable = str2num(bearingDeviceStruct.Attributes.elementProcessingEnable);
                            if nnz(str2num(bearingDeviceStruct.Attributes.equipmentDataPoint) == str2num(myParser.equipmentDataPoint))
                                bearingStruct.bearing(bearingNumber).priority = 1;
                                myParser.equipmentComponentsList{end + 1} = bearingStruct.bearing(bearingNumber).classType;
                                myParser.equipmentGroupsList = [myParser.equipmentGroupsList, strsplit(bearingGroup, ',')];
                            else
                                bearingStruct.bearing(bearingNumber).priority = 0;
                            end
                            bearingStruct.bearing(bearingNumber).model = bearingDeviceStruct.Attributes.model;
                            bearingStruct.bearing(bearingNumber).shaftFreq = shaftStruct.shaft(i).freq;
                            
                            % The bearing class is ROLLING bearing
                            if strcmp(bearingStruct.bearing(bearingNumber).classType, 'rollingBearing')
                                % Add parameters of the rolling bearing
                                bearingStruct.bearing(bearingNumber).Nb = str2double(bearingDeviceStruct.Attributes.Nb);
                                bearingStruct.bearing(bearingNumber).Bd = str2double(bearingDeviceStruct.Attributes.Bd);
                                bearingStruct.bearing(bearingNumber).Pd = str2double(bearingDeviceStruct.Attributes.Pd);
                                bearingStruct.bearing(bearingNumber).angle = str2double(bearingDeviceStruct.Attributes.angle);
                                
                            % The bearing class is PLAIN bearing
                            elseif strcmp(bearingStruct.bearing(bearingNumber).classType, 'plainBearing')
                                % Add parameters of the plain bearing
                                bearingStruct.bearing(bearingNumber).Nb = 0;
                                bearingStruct.bearing(bearingNumber).Bd = 0;
                                bearingStruct.bearing(bearingNumber).Pd = 0;
                                bearingStruct.bearing(bearingNumber).angle = 0;
                            end
                        end
                    end
                    
                    % The shaft have couplings
                    if isfield(shaftDeviceStruct, 'coupling')
                        
                        % The number of couplings on the shaft
                        shaftCouplingNumber = length(shaftDeviceStruct.coupling);
                        
                        % Add the coupling to the coupling structure
                        for j = 1 : 1 : shaftCouplingNumber
                            
                            couplingNumber = couplingNumber + 1;
                            % Get the description of the coupling
                            if shaftCouplingNumber > 1
                               couplingDeviceStruct = shaftDeviceStruct.coupling{1, j};
                            elseif shaftCouplingNumber == 1
                               couplingDeviceStruct = shaftDeviceStruct.coupling;
                            end
                            
                            % Add common parameters of the coupling
                            couplingStruct.coupling(couplingNumber).name = couplingDeviceStruct.Attributes.schemeName;
                            couplingClassType = strsplit(couplingDeviceStruct.Attributes.classType, ':');
                            couplingStruct.coupling(couplingNumber).classType = couplingClassType{1};
                            couplingStruct.coupling(couplingNumber).elementType = 'coupling';
                            if isfield(couplingDeviceStruct.Attributes, 'group')
                                couplingGroup = couplingDeviceStruct.Attributes.group;
                            else
                                couplingGroup = '';
                            end
                            couplingStruct.coupling(couplingNumber).group = couplingGroup;
                            couplingStruct.coupling(couplingNumber).enable = str2num(couplingDeviceStruct.Attributes.elementProcessingEnable);
                            if nnz(str2num(couplingDeviceStruct.Attributes.equipmentDataPoint) == str2num(myParser.equipmentDataPoint))
                                couplingStruct.coupling(couplingNumber).priority = 1;
                                myParser.equipmentComponentsList{end + 1} = couplingStruct.coupling(couplingNumber).classType;
                                myParser.equipmentGroupsList = [myParser.equipmentGroupsList, strsplit(couplingGroup, ',')];
                            else
                                couplingStruct.coupling(couplingNumber).priority = 0;
                            end
                            couplingStruct.coupling(couplingNumber).shaftFreq = shaftStruct.shaft(i).freq;
                        end
                    end
                end
            else
                error('There are no shafts in the scheme!')
            end
            
            %% ____________ Checking motors in the scheme _____________ %%
            
            if isfield(deviceStruct, 'motor')
                
                motorNumber = length(deviceStruct.motor);
                for i = 1 : 1 : motorNumber
                    
                    % Get the description of the motor
                    if motorNumber > 1
                        motorDeviceStruct = deviceStruct.motor{1, i};
                    elseif motorNumber == 1
                        motorDeviceStruct = deviceStruct.motor;
                    end
                    
                    % Add the motor to the motor structure
                    motorStruct.motor(i).name = motorDeviceStruct.Attributes.schemeName;
                    motorClassType = strsplit(motorDeviceStruct.Attributes.classType, ':');
                    motorStruct.motor(i).classType = motorClassType{1};
                    motorStruct.motor(i).elementType = 'motor';
                    if isfield(motorDeviceStruct.Attributes, 'group')
                        motorGroup = motorDeviceStruct.Attributes.group;
                    else
                        motorGroup = '';
                    end
                    motorStruct.motor(i).group = motorGroup;
                    motorStruct.motor(i).enable = str2num(motorDeviceStruct.Attributes.elementProcessingEnable);
                    if nnz(str2num(motorDeviceStruct.Attributes.equipmentDataPoint) == str2num(myParser.equipmentDataPoint))
                        motorStruct.motor(i).priority = 1;
                        myParser.equipmentComponentsList{end + 1} = motorStruct.motor(i).classType;
                        myParser.equipmentGroupsList = [myParser.equipmentGroupsList, strsplit(motorGroup, ',')];
                    else
                        motorStruct.motor(i).priority = 0;
                    end
                    motorStruct.motor(i).model = motorDeviceStruct.Attributes.model;
                    motorStruct.motor(i).lineFrequency = str2num(motorDeviceStruct.Attributes.lineFrequency);
                    if isempty(motorStruct.motor(i).lineFrequency)
                        motorStruct.motor(i).lineFrequency = nan(1);
                    else
                        motorStruct.motor(i).lineFrequency = motorStruct.motor(i).lineFrequency(1,1);
                    end
                    
                    % The motor class is INDUCTION motor
                    if strcmp(motorStruct.motor(i).classType, 'inductionMotor')
                        motorStruct.motor(i).barsNumber = str2double(motorDeviceStruct.Attributes.barsNumber);
                        motorStruct.motor(i).polePairsNumber = str2double(motorDeviceStruct.Attributes.polePairsNumber);
                        
                    % The motor class is SYNCHRONOUS motor
                    elseif strcmp(motorStruct.motor(i).classType, 'synchronousMotor')
                        motorStruct.motor(i).coilsNumber = str2double(motorDeviceStruct.Attributes.coilsNumber);
                        
                    % The motor class is DIRECTCURRENT motor
                    elseif strcmp(motorStruct.motor(i).classType, 'directCurrentMotor')
                        motorStruct.motor(i).polePairsNumber = str2double(motorDeviceStruct.Attributes.polePairsNumber);
                        motorStruct.motor(i).collectorPlatesNumber = str2double(motorDeviceStruct.Attributes.collectorPlatesNumber);
                        motorStruct.motor(i).armatureTeethNumber = str2double(motorDeviceStruct.Attributes.armatureTeethNumber);
                        
                        if isempty(motorDeviceStruct.Attributes.rectifierType)
                            motorStruct.motor(i).rectifierType = 'full-wave';
                        else
                            motorStruct.motor(i).rectifierType = motorDeviceStruct.Attributes.rectifierType;
                        end
                    end
                    motorStruct.motor(i).jointElementSchemeName = motorDeviceStruct.joint.Attributes.jointElementSchemeName;
                    % The motor is connected DIRECTLY to a shaft
                    if strfind(motorDeviceStruct.joint.Attributes.jointElementSchemeName, 'shaft')
                        for j = 1 : 1 : shaftNumber
                            if strcmp(shaftStruct.shaft(j).name, motorDeviceStruct.joint.Attributes.jointElementSchemeName)
                                motorStruct.motor(i).freq = shaftStruct.shaft(j).freq;
                                break;
                            end
                        end
                    else
                        % The motor is connected to a shaft via a GEAR
                        % Find the motor name in the shaftVector and
                        % add the corresponding frequency to the
                        % motor structure
                        for j = 1 : 1 : length(myParser.shaftVector.name)
                            if strcmp(myParser.shaftVector.name{j, 1}, motorStruct.motor(i).name)
                                motorStruct.motor(i).freq = myParser.shaftVector.freq(j);
                                break;
                            end
                        end
                    end
                end
            end
            
            %% ______________ Checking fan in the scheme ______________ %%
            
            if isfield(deviceStruct, 'fan')
                
                fanNumber = length(deviceStruct.fan);
                for i = 1 : 1 : fanNumber
                    
                    % Get the description of the fan
                    if fanNumber > 1
                        fanDeviceStruct = deviceStruct.fan{1, i};
                    elseif fanNumber == 1
                        fanDeviceStruct = deviceStruct.fan;
                    end
                    
                    % Add the fan to the fan structure
                    fanStruct.fan(i).name = fanDeviceStruct.Attributes.schemeName;
                    fanClassType = strsplit(fanDeviceStruct.Attributes.classType, ':');
                    fanStruct.fan(i).classType = fanClassType{1};
                    fanStruct.fan(i).elementType = 'fan';
                    if isfield(fanDeviceStruct.Attributes, 'group')
                        fanGroup = fanDeviceStruct.Attributes.group;
                    else
                        fanGroup = '';
                    end
                    fanStruct.fan(i).group = fanGroup;
                    fanStruct.fan(i).enable = str2double(fanDeviceStruct.Attributes.elementProcessingEnable);
                    if nnz(str2num(fanDeviceStruct.Attributes.equipmentDataPoint) == str2num(myParser.equipmentDataPoint))
                        fanStruct.fan(i).priority = 1;
                        myParser.equipmentComponentsList{end + 1} = fanStruct.fan(i).classType;
                        myParser.equipmentGroupsList = [myParser.equipmentGroupsList, strsplit(fanGroup, ',')];
                    else
                        fanStruct.fan(i).priority = 0;
                    end
                    fanStruct.fan(i).model = fanDeviceStruct.Attributes.model;
                    fanStruct.fan(i).bladesNumber = str2double(fanDeviceStruct.Attributes.bladesNumber);
                    fanStruct.fan(i).jointElementSchemeName = fanDeviceStruct.joint.Attributes.jointElementSchemeName;
                    % The fan is connected DIRECTLY to a shaft
                    if strfind(fanDeviceStruct.joint.Attributes.jointElementSchemeName, 'shaft')
                        for j = 1 : 1 : shaftNumber
                            if strcmp(shaftStruct.shaft(j).name, fanDeviceStruct.joint.Attributes.jointElementSchemeName)
                                fanStruct.fan(i).freq = shaftStruct.shaft(j).freq;
                                break;
                            end
                        end
                    else
                        % The fan is connected to a shaft via a GEAR
                        % Find the fan name in the shaftVector and
                        % add the corresponding frequency to the
                        % fan structure
                        for j = 1 : 1 : length(myParser.shaftVector.name)
                            if strcmp(myParser.shaftVector.name{j, 1}, fanStruct.fan(i).name)
                                fanStruct.fan(i).freq = myParser.shaftVector.freq(j);
                                break;
                            end
                        end
                    end
                end
            end
            
            %% __________ Checking connections in the scheme __________ %%
            
            if isfield(deviceStruct, 'connection')
                
                connectionNumber = length (deviceStruct.connection);
                for i = 1 : 1 : connectionNumber
                    
                    % Get the description of the connection
                    if connectionNumber > 1
                        connectionDeviceStruct = deviceStruct.connection{1, i};
                    elseif connectionNumber == 1
                        connectionDeviceStruct = deviceStruct.connection;
                    end
                    
                    % Add the connection to the connection structure
                    % Add common parameters of the connection
                    connectionStruct.connection(i).name = connectionDeviceStruct.Attributes.schemeName;
                    connectionClassType = strsplit(connectionDeviceStruct.Attributes.classType, ':');
                    connectionStruct.connection(i).classType = connectionClassType{1};
                    connectionStruct.connection(i).elementType = 'connection';
                    if isfield(connectionDeviceStruct.Attributes, 'group')
                        connectionGroup = connectionDeviceStruct.Attributes.group;
                    else
                        connectionGroup = '';
                    end
                    connectionStruct.connection(i).group = connectionGroup;
                    connectionStruct.connection(i).enable = str2num(connectionDeviceStruct.Attributes.elementProcessingEnable);
                    if nnz(str2num(connectionDeviceStruct.Attributes.equipmentDataPoint) == str2num(myParser.equipmentDataPoint))
                        connectionStruct.connection(i).priority = 1;
                        myParser.equipmentComponentsList{end + 1} = connectionStruct.connection(i).classType;
                        myParser.equipmentGroupsList = [myParser.equipmentGroupsList, strsplit(connectionGroup, ',')];
                    else
                       connectionStruct.connection(i).priority = 0;
                    end
                    
                    % The connection class is GEARING
                    if contains(lower(connectionStruct.connection(i).classType), 'gear')
                        
                        connectionStruct.connection(i).classType = connectionDeviceStruct.Attributes.classType;
                        connectionStruct = fillGearConnection(myParser, connectionStruct, i, connectionDeviceStruct);
                        
                    % The connection class is BELTING
                    elseif strfind(connectionStruct.connection(i).classType, 'Belt')
                        
                        connectionStruct.connection(i).classType = connectionDeviceStruct.Attributes.classType;
                        connectionStruct = fillBeltConnection(myParser, connectionStruct, i, connectionDeviceStruct);
                    end
                end
            end
            
            %% ____________ Fill the classifier structure _____________ %%
            
            % Create a classifier structure
            myParser.classifierStruct.shaftStruct = shaftStruct;
            myParser.classifierStruct.bearingStruct = bearingStruct;
            myParser.classifierStruct.connectionStruct = connectionStruct;
            myParser.classifierStruct.motorStruct = motorStruct;
            myParser.classifierStruct.couplingStruct = couplingStruct;
            myParser.classifierStruct.fanStruct = fanStruct;
            myParser.equipmentComponentsList = unique(myParser.equipmentComponentsList);
            myParser.equipmentGroupsList = unique(myParser.equipmentGroupsList);
            
%             printComputeInfo(iLoger, 'Equipment parser', 'Classifier structure is made.');
        end
        
        % FILLBELTCONNECTION function fills the connection struct of the
        % gearing type
        function [connectionStruct] = fillBeltConnection(myParser, connectionStruct, connectionNumber, connectionDeviceStruct)
            
            % Get fields names of elements
            nameElement = fieldnames(connectionDeviceStruct);
            nameElement = nameElement(~strcmpi(nameElement, 'Attributes'));
            
            if length(nameElement) == 1
                tempDeviceStruct{1} = connectionDeviceStruct.(nameElement{1}){1};
                tempDeviceStruct{2} = connectionDeviceStruct.(nameElement{1}){2};
            else
                tempDeviceStruct{1} = connectionDeviceStruct.(nameElement{1});
                tempDeviceStruct{2} = connectionDeviceStruct.(nameElement{2});
            end
            
            % Add the parameters of the belting
            connectionStruct.connection(connectionNumber).beltLength = str2double(connectionDeviceStruct.Attributes.beltLength);
            connectionStruct.connection(connectionNumber).sheaveDiameter1 = str2double(tempDeviceStruct{1}.Attributes.sheaveDiameter);
            connectionStruct.connection(connectionNumber).sheaveDiameter2 = str2double(tempDeviceStruct{2}.Attributes.sheaveDiameter);
            
            % Add the teeth number of the toothed belt
            if strfind(connectionStruct.connection(connectionNumber).classType, 'toothedBelt')
                connectionStruct.connection(connectionNumber).z1 = str2double(connectionDeviceStruct.Attributes.teethNumber);
            end
            
            connectionStruct.connection(connectionNumber).shaftName1 = tempDeviceStruct{1}.Attributes.schemeName;
            connectionStruct.connection(connectionNumber).shaftName2 = tempDeviceStruct{2}.Attributes.schemeName;
            
            % Add the frequency (freq1) from the first shaft
            posElement1 = strcmpi(myParser.shaftVector.name, tempDeviceStruct{1}.Attributes.schemeName);
            connectionStruct.connection(connectionNumber).freq1 = myParser.shaftVector.freq(posElement1);
            
            % Add the frequency (freq2) from the second shaft
            posElement2 = strcmpi(myParser.shaftVector.name, tempDeviceStruct{2}.Attributes.schemeName);
            connectionStruct.connection(connectionNumber).freq2 = myParser.shaftVector.freq(posElement2);
        end
        
        % FILLGEARCONNECTION function fills the connection struct of the
        % belting type
        function [connectionStruct] = fillGearConnection(myParser, connectionStruct, connectionNumber, connectionDeviceStruct)
            
            % Get fields names of elements
            nameElement = fieldnames(connectionDeviceStruct);
            nameElement = nameElement(~strcmpi(nameElement, 'Attributes'));
            
            if length(nameElement) == 1
                tempDeviceStruct{1} = connectionDeviceStruct.(nameElement{1}){1};
                tempDeviceStruct{2} = connectionDeviceStruct.(nameElement{1}){2};
            else
                tempDeviceStruct{1} = connectionDeviceStruct.(nameElement{1});
                tempDeviceStruct{2} = connectionDeviceStruct.(nameElement{2});
            end
            
            % Add the parameters of the gearing
            connectionStruct.connection(connectionNumber).z1 = str2double(tempDeviceStruct{1}.Attributes.teethNumber);
            connectionStruct.connection(connectionNumber).z2 = str2double(tempDeviceStruct{2}.Attributes.teethNumber);
            
            if strfind(connectionStruct.connection(connectionNumber).classType, 'planetaryStageGearbox')
                
                if isfield(tempDeviceStruct{1}.Attributes, 'planetWheelNumber')
                    connectionStruct.connection(connectionNumber).planetWheelNumber = str2double(tempDeviceStruct{1}.Attributes.planetWheelNumber);
                    connectionStruct.connection(connectionNumber).positionPlanetWheel = 1;
                else
                    connectionStruct.connection(connectionNumber).planetWheelNumber = str2double(tempDeviceStruct{2}.Attributes.planetWheelNumber);
                    connectionStruct.connection(connectionNumber).positionPlanetWheel = 2;
                end
                connectionStruct.connection(connectionNumber).teethNumberRingGear = str2double(connectionDeviceStruct.Attributes.teethNumberRingGear);
            end
            
            connectionStruct.connection(connectionNumber).shaftName1 = tempDeviceStruct{1}.Attributes.schemeName;
            connectionStruct.connection(connectionNumber).shaftName2 = tempDeviceStruct{2}.Attributes.schemeName;
            
            % Add the frequency (freq1) from the first shaft
            posElement1 = strcmpi(myParser.shaftVector.name, tempDeviceStruct{1}.Attributes.schemeName);
            connectionStruct.connection(connectionNumber).freq1 = myParser.shaftVector.freq(posElement1);
            
            % Add the frequency (freq2) from the second shaft
            posElement2 = strcmpi(myParser.shaftVector.name, tempDeviceStruct{2}.Attributes.schemeName);
            connectionStruct.connection(connectionNumber).freq2 = myParser.shaftVector.freq(posElement2);
        end
    end
    
    methods (Static)
        
        % GETTEMPSTRUCT function fills deviceStructTemp for further
        % processing
        function [deviceStructTemp] = getTempStruct(deviceStruct, nameTeeth)
            
            % To get fields names of elements
            nameElement = fieldnames(deviceStruct);
            nameElement = nameElement(~strcmpi(nameElement, 'Attributes'));
            
            if length(nameElement) == 1
                tempDeviceStruct{1} = deviceStruct.(nameElement{1}){1};
                tempDeviceStruct{2} = deviceStruct.(nameElement{1}){2};
            else
                tempDeviceStruct{1} = deviceStruct.(nameElement{1});
                tempDeviceStruct{2} = deviceStruct.(nameElement{2});
            end
            
            % To set schemeName
            deviceStructTemp.schemeName{1,1} = tempDeviceStruct{1}.Attributes.schemeName;
            deviceStructTemp.schemeName{2,1} = tempDeviceStruct{2}.Attributes.schemeName;
            
            % To set gear ratio
            deviceStructTemp.gearRatio{1,1} = str2double(tempDeviceStruct{1}.Attributes.(nameTeeth));
            deviceStructTemp.gearRatio{2,1} = str2double(tempDeviceStruct{2}.Attributes.(nameTeeth));
        end
        
        % ADDELEMENTTOTABLE function adds connection element to
        % shaftCorrespondenceTable
        function [shaftCorrespondenceTable, elementNumber, modeContinue] = ...
                    addElementToTable(shaftCorrespondenceTable, elementNumber, elementCnt, deviceStruct)
            
            % modeContinue = 0 - break of the loop
            modeContinue = 1;
            
            % If the table is empty, stores connection
            % coefficients
            if isempty(shaftCorrespondenceTable.name{1,1})
                elementNumber = 1; % item number in shaftCorrespondenceTable
                shaftCorrespondenceTable.name{1,1} = deviceStruct.schemeName{1,1};
                elementNumber = elementNumber + 1;
                shaftCorrespondenceTable.name{2,1} = deviceStruct.schemeName{2,1};
                elementNumber = elementNumber + 1;
                shaftCorrespondenceTable.matrix(1,2) = deviceStruct.gearRatio{1,1}/deviceStruct.gearRatio{2,1};
                shaftCorrespondenceTable.matrix(2,1) = deviceStruct.gearRatio{2,1}/deviceStruct.gearRatio{1,1};
            else
                % If the table has a field, check for the 
                % presence of the same shafts in the table, 
                % and stores the connection coefficients in 
                % the table
                if elementNumber ~= elementCnt+1
                    if find(strcmp(shaftCorrespondenceTable.name, deviceStruct.schemeName{1,1})==1)
                        posShaft = strcmp(shaftCorrespondenceTable.name, deviceStruct.schemeName{1,1});
                        shaftCorrespondenceTable.name{elementNumber,1} = deviceStruct.schemeName{2,1};
                        shaftCorrespondenceTable.matrix(posShaft,elementNumber) = deviceStruct.gearRatio{1,1}/deviceStruct.gearRatio{2,1};
                        shaftCorrespondenceTable.matrix(elementNumber,posShaft) = deviceStruct.gearRatio{2,1}/deviceStruct.gearRatio{1,1};
                        elementNumber = elementNumber + 1;
                    elseif find(strcmp(shaftCorrespondenceTable.name, deviceStruct.schemeName{2,1})==1)
                        posShaft = strcmp(shaftCorrespondenceTable.name, deviceStruct.schemeName{2,1});
                        shaftCorrespondenceTable.name{elementNumber,1} = deviceStruct.schemeName{1,1};
                        shaftCorrespondenceTable.matrix(elementNumber,posShaft) = deviceStruct.gearRatio{1,1}/deviceStruct.gearRatio{2,1};
                        shaftCorrespondenceTable.matrix(posShaft,elementNumber) = deviceStruct.gearRatio{2,1}/deviceStruct.gearRatio{1,1};
                        elementNumber = elementNumber + 1;
                    else
                        shaftCorrespondenceTable.name{elementNumber,1} = deviceStruct.schemeName{1,1};
                        shaftCorrespondenceTable.name{elementNumber+1,1} = deviceStruct.schemeName{2,1};
                        shaftCorrespondenceTable.matrix(elementNumber,elementNumber+1) = deviceStruct.gearRatio{1,1}/deviceStruct.gearRatio{2,1};
                        shaftCorrespondenceTable.matrix(elementNumber+1,elementNumber) = deviceStruct.gearRatio{2,1}/deviceStruct.gearRatio{1,1};
                        elementNumber = elementNumber + 2;
                    end
                else
                    posShaft1 = strcmp(shaftCorrespondenceTable.name, deviceStruct.schemeName{1,1});
                    posShaft2 = strcmp(shaftCorrespondenceTable.name, deviceStruct.schemeName{2,1});
                    shaftCorrespondenceTable.matrix(posShaft1,posShaft2) = deviceStruct.gearRatio{1,1}/deviceStruct.gearRatio{2,1};
                    shaftCorrespondenceTable.matrix(posShaft2,posShaft1) = deviceStruct.gearRatio{2,1}/deviceStruct.gearRatio{1,1};
                    modeContinue = 0;
                end    
            end
        end
        
        % GETTEMPSTRUCTPLANETARY function creates deviceStructTemp for
        % planetary stage gearbox for further processing
        function [deviceStructTemp] = getTempStructPlanetary(deviceStruct)
            
            % To get fields names of elements
            nameElement = fieldnames(deviceStruct);
            nameElement = nameElement(~strcmpi(nameElement, 'Attributes'));
            
            if length(nameElement) == 1
                tempDeviceStruct{1} = deviceStruct.(nameElement{1}){1};
                tempDeviceStruct{2} = deviceStruct.(nameElement{1}){2};
            else
                tempDeviceStruct{1} = deviceStruct.(nameElement{1});
                tempDeviceStruct{2} = deviceStruct.(nameElement{2});
            end
            
            % To set schemeName
            deviceStructTemp.schemeName{1,1} = tempDeviceStruct{1}.Attributes.schemeName;
            deviceStructTemp.schemeName{2,1} = tempDeviceStruct{2}.Attributes.schemeName;
            
            teethNumberRingGear = str2double(deviceStruct.Attributes.teethNumberRingGear);
            
            % z2 - teeth number of satellites
            % z1 - teeth number of sun ring
            % To chosen location of planet wheela and set gear ratio
            if isfield(tempDeviceStruct{1}.Attributes, 'planetWheelNumber')
                
                z2 = str2double(tempDeviceStruct{1}.Attributes.teethNumber);
                z1 = str2double(tempDeviceStruct{2}.Attributes.teethNumber);
                
                deviceStructTemp.gearRatio{1,1} = 1;
                deviceStructTemp.gearRatio{2,1} = ...
                    equipmentProfileParser.calculateGearRatioPlanetary(z1, z2, teethNumberRingGear);
            else
                z2 = str2double(tempDeviceStruct{2}.Attributes.teethNumber);
                z1 = str2double(tempDeviceStruct{1}.Attributes.teethNumber);
                
                deviceStructTemp.gearRatio{1,1} = ...
                    equipmentProfileParser.calculateGearRatioPlanetary(z1, z2, teethNumberRingGear);
                deviceStructTemp.gearRatio{2,1} = 1;
                    
            end 
        end
        
        % CALCULATEGEARRATIONPLANETARY function calculates for planetary
        % stage gearbox of gear ratio
        function [value] = calculateGearRatioPlanetary(z1, z2, teethNumberRingGear)
            % z2 - teeth number of satellites
            % z1 - teeth number of sun ring
            
            % If not enough input arguments
            if z1 == 0
                z1 = teethNumberRingGear - 2*z2;
            elseif z2 == 0
                z2 = round((teethNumberRingGear - z1)/2);
            end
            
            value = z1/(2*(z1 + z2));
        end
    end
end

