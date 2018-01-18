% VDI3834 function evaluates the vibration according to VDI 3834-1
% standard
% 
% status - the status of the vibration
% status = 'B' | 'C' | 'D' | empty
%    A - The vibration of newly commissioned wind turbines and components
%    operating in steady load and with low turbulence wind conditions
%    normally falls within this zone.
%    B - Wind turbines and components whose evaluation quantities fall
%    within this zone are regarded as suitable for running in long-term
%    operation with acceptable vibratory stresses.
%    C - Wind turbines and components whose vibration fall within this
%    zone are not normally regarded as being suitable for running in
%    long-term continuous operation. Investigation is recommended into
%    which excitations are responsible for the increased values and
%    whether the measured values are permissible for unlimited continuous
%    operation, taking into account the design and operating conditions of
%    the equipment in question.
%    D - Vibrations within this zone are potentially damaging to the wind
%    turbine and its components.
% 
%     A
%    ---
%     B    |
%    ---   | ALERT
%     C    |    |
%    ---        | ALARM
%     D         |
% 
% Developer:              P. Riabtsev
% Development date:       27-11-2017
% 
% Modified by:            
% Modification date:      
function [resultStatusStruct] = vdi3834(File, classifierStruct, equipmentGroupsList, equipmentClass)
    
    resultStatusStruct = [];
    
    for equipmentGroupNumber = 1 : 1 : length(equipmentGroupsList)
        
        % Get the equipment group name
        equipmentGroupName = equipmentGroupsList{equipmentGroupNumber};
        
        if strfind(equipmentGroupName, 'windTurbineRotor')
            
            if checkField(classifierStruct, 'bearingStruct', 'bearing')
                
                % Get the bearing class of the wind turbine rotor
                rotorBearingIndex = strcmp({classifierStruct.bearingStruct.bearing.group}, equipmentGroupName);
                rotorBearingClassType = unique({classifierStruct.bearingStruct.bearing(rotorBearingIndex).classType});
            else
                rotorBearingClassType = [];
            end
            
            if any(strcmp(rotorBearingClassType, 'rollingBearing')) || ...
                    isempty(rotorBearingClassType)
                
                % Evaluate the wind turbine rotor with rolling bearings
                rotorStatusStruct = getRotorStatus(File);
            else
                rotorStatusStruct = [];
            end
            
            resultStatusStruct.(equipmentGroupName) = rotorStatusStruct;
            
        elseif strfind(equipmentGroupName, 'windTurbineGearbox')
            
            if checkField(classifierStruct, 'bearingStruct', 'bearing')
                
                % Get the bearing class of the wind turbine gearbox
                gearboxBearingIndex = strcmp({classifierStruct.bearingStruct.bearing.group}, equipmentGroupName);
                gearboxBearingClassType = unique({classifierStruct.bearingStruct.bearing(gearboxBearingIndex).classType});
            else
                gearboxBearingClassType = [];
            end
            
            if any(strcmp(gearboxBearingClassType, 'rollingBearing')) || ...
                    isempty(gearboxBearingClassType)
                
                % Evaluate the wind turbine gearbox with rolling bearings
                gearboxStatusStruct = getGearboxStatus(File);
            else
                gearboxStatusStruct = [];
            end
            
            resultStatusStruct.(equipmentGroupName) = gearboxStatusStruct;
            
        elseif strfind(equipmentGroupName, 'windTurbineGenerator')
            
            if checkField(classifierStruct, 'bearingStruct', 'bearing')
                
                % Get the bearing class of the wind turbine generator
                generatorBearingIndex = strcmp({classifierStruct.bearingStruct.bearing.group}, equipmentGroupName);
                generatorBearingClassType = unique({classifierStruct.bearingStruct.bearing(generatorBearingIndex).classType});
            else
                generatorBearingClassType = [];
            end
            
            if any(strcmp(generatorBearingClassType, 'plainBearing')) || ...
                    (isempty(generatorBearingClassType) && strcmp(equipmentClass, '4'))
                
                if checkField(classifierStruct, 'motorStruct', 'motor')
                    
                    % Get the wind turbine generator speed
                    generatorMotorIndex = strcmp({classifierStruct.motorStruct.motor.group}, equipmentGroupName);
                    generatorMotorSpeed = {classifierStruct.motorStruct.motor(generatorMotorIndex).freq};
                    if isempty(generatorMotorSpeed)
                        generatorSpeed = [];
                    else
                        generatorSpeed = generatorMotorSpeed{1};
                    end
                else
                    generatorSpeed = [];
                end
                
                % Evaluate the wind turbine generator with plain bearings
                generatorStatusStruct = getPlainBearingGeneratorStatus(File, generatorSpeed);

            elseif any(strcmp(generatorBearingClassType, 'rollingBearing')) || ...
                    isempty(generatorBearingClassType)

                % Evaluate the wind turbine generator with rolling bearings
                generatorStatusStruct = getRollingBearingGeneratorStatus(File);
            else
                generatorStatusStruct = [];
            end
            
            resultStatusStruct.(equipmentGroupName) = generatorStatusStruct;
            
        end
    end
    
    if isempty(resultStatusStruct)
        
        constructionGroupName = 'windTurbineConstruction_001';
        
        % Evaluate the wind turbine nacelle and tower
        constructinStatusStruct = getConstructionStatus(File);
        
        resultStatusStruct.(constructionGroupName) = constructinStatusStruct;
    end
    
end

% GETCONSTRUCTINSTATUS function evaluates a wind turbine nacelle and tower
function [statusStruct] = getConstructionStatus(File)
    
    % _________________ Evaluate the ACCELERATION area _________________ %
    
    % The acceleration RMS boundaries
    accBoundaries = [0.3, 0.5];
    % The acceleration fraquency band from 0.1 to 10 Hz
    accFreqBand = [0.1, 10];
    
    statusStruct.acceleration = areaEvaluation(File, 'acceleration', accBoundaries, accFreqBand);
    
    % ___________________ Evaluate the VELOCITY area ___________________ %
    
    % The velocity RMS boundaries
    velBoundaries = [60, 100];
    % The velocity fraquency band from 0.1 to 10 Hz
    velFreqBand = [0.1, 10];
    
    statusStruct.velocity = areaEvaluation(File, 'velocity', velBoundaries, velFreqBand);
    
end

% GETROTORSTATUS function evaluates a wind turbine rotor
function [statusStruct] = getRotorStatus(File)
    
    % _________________ Evaluate the ACCELERATION area _________________ %
    
    % The acceleration RMS boundaries
    accBoundaries = [0.3, 0.5];
    % The acceleration fraquency band 0.1 to 10 Hz
    accFreqBand = [0.1, 10];
    
    statusStruct.acceleration = areaEvaluation(File, 'acceleration', accBoundaries, accFreqBand);
    
    % ___________________ Evaluate the VELOCITY area ___________________ %
    
    % The velocity RMS boundaries
    velBoundaries = [2, 3.2];
    % The velocity fraquency band 10 to 1000 Hz
    velFreqBand = [10, 1000];
    
    statusStruct.velocity = areaEvaluation(File, 'velocity', velBoundaries, velFreqBand);
    
end

% GETGEARBOXSTATUS function evaluates a wind turbine gearbox
function [statusStruct] = getGearboxStatus(File)
    
    % _________________ Evaluate the ACCELERATION area _________________ %
    
    % The acceleration RMS boundaries
    accBoundaries(1, : ) = [0.3, 0.5];
    % The acceleration fraquency band 0.1 to 10 Hz
    accFreqBand(1, : ) = [0.1, 10];
    
    % The acceleration RMS boundaries
    accBoundaries(2, : ) = [7.5, 12];
    % The acceleration fraquency band 10 to 2000 Hz
    accFreqBand(2, : ) = [10, 2000];
    
    for bandNumber = 1 : 1 : size(accFreqBand, 1)
        
        statusStruct.acceleration(bandNumber) = areaEvaluation(File, 'acceleration', ...
            accBoundaries(bandNumber, : ), accFreqBand(bandNumber, : ));
    end
    
    % ___________________ Evaluate the VELOCITY area ___________________ %
    
    % The velocity RMS boundaries
    velBoundaries = [3.5, 5.6];
    % The velocity fraquency band 10 to 1000 Hz
    velFreqBand = [10, 1000];
    
    statusStruct.velocity = areaEvaluation(File, 'velocity', velBoundaries, velFreqBand);
    
end

% GETPLAINBEARINGGENERATORSTATUS function evaluates a wind turbine
% generator with plain bearings
function [statusStruct] = getPlainBearingGeneratorStatus(File, generatorSpeed)
    
    if isempty(generatorSpeed)
        statusStruct = [];
        return;
    end
    
    % _________________ Evaluate the DISPLACEMENT area _________________ %
    
    % The displacement peak-to-peak boundaries
    dispBoundaries = [9000 / sqrt(generatorSpeed), 13200 / sqrt(generatorSpeed)];
    
    statusStruct.displacement = areaEvaluation(File, 'displacement', dispBoundaries);
    
end

% GETROLLINGBEARINGGENERATORSTATUS function evaluates a wind turbine
% generator with rolling bearings
function [statusStruct] = getRollingBearingGeneratorStatus(File)
    
    % _________________ Evaluate the ACCELERATION area _________________ %
    
    % The acceleration RMS boundaries
    accBoundaries = [10, 16];
    % The acceleration fraquency band 10 to 5000 Hz
    accFreqBand = [10, 5000];
    
    statusStruct.acceleration = areaEvaluation(File, 'acceleration', accBoundaries, accFreqBand);
    
    % ___________________ Evaluate the VELOCITY area ___________________ %
    
    % The velocity RMS boundaries
    velBoundaries = [6, 10];
    % The velocity fraquency band 10 to 1000 Hz
    velFreqBand = [10, 1000];
    
    statusStruct.velocity = areaEvaluation(File, 'velocity', velBoundaries, velFreqBand);
    
end

% AREAEVALUATION function evaluates a specified area and writes results in
% the area status structure
function [areaStatusStruct] = areaEvaluation(File, area, boundaries, freqBand)
    
    if nargin == 3
        freqBand = [];
    end
    
    if strcmp(area, 'displacement')
        % Calculate the peak-to-peak value
        value = max(File.(area).signal) - min(File.(area).signal);
    else
        % Calculate the RMS value in the fraquency band
        value = bandRms(File.(area).signal, File.(area).df, freqBand(1), freqBand(2));
    end
    
    % Evaluate the value
    status = getStatus(value, boundaries);
    
    % Fill the status structure
    areaStatusStruct.value = value;
    areaStatusStruct.status = status;
    areaStatusStruct.thresholds = boundaries;
    areaStatusStruct.band = freqBand;
    
end

% BANDRMS function calculates a band RMS value of a signal in a given
% frequency band
function [bandRmsValue] = bandRms(signal, df, lowFreq, highFreq)
    
    % Find low and high frequency samples
    lowFreqSample = round(lowFreq / df) + 1;
    highFreqSample = round(highFreq / df) + 1;
    
    % Calculate the spectrum
    spectrum = fft(signal);
    % Cut the spectrum
    spectrum(1 : (lowFreqSample - 1), : ) = 0;
    spectrum((end - lowFreqSample + 1) : end, : ) = 0;
    spectrum((highFreqSample + 1) : (end - highFreqSample - 1), : ) = 0;
    
    % Calculate the band RMS value
    bandRmsValue = rms(ifft(spectrum, 'symmetric'));
    
end

% GETSTATUS function evaluates a value by boundaries
function [status] = getStatus(value, boundaries)
    
    if value < boundaries(1)
        % Zone B
        status = 'B';
    elseif (value >= boundaries(1)) && (value < boundaries(2))
        % Zone C
        status = 'C';
    elseif value >= boundaries(2)
        % Zone D
        status = 'D';
    else
        % Unknown
        status = [];
    end
    
end

