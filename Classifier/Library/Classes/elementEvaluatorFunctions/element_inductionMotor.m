function [ statusStruct ] = element_inductionMotor( statusStruct )

    % To evaluate NON_LINEAR_DISTORTION_SUPPLY_VOLTAGE and ROTOR_ECCENTRICITY
    statusStruct = evaluateTwoDefect(statusStruct, 'NON_LINEAR_DISTORTION_SUPPLY_VOLTAGE', 'ROTOR_ECCENTRICITY');
    
    % To evaluate CRACKED_BROKEN_ROTOR_BARS and DEFECT_STATOR_WINDINGS
    statusStruct = evaluateTwoDefect(statusStruct, 'CRACKED_BROKEN_ROTOR_BARS', 'DEFECT_STATOR_WINDINGS');
end

