function [statusStruct] = element_synchronousMotor(statusStruct)

    % To evaluate ECCENTRICITY_AIR_GAP and NON_LINEAR_DISTORTION_SUPPLY_VOLTAGE
    statusStruct = evaluateTwoDefect(statusStruct, 'ECCENTRICITY_AIR_GAP', 'NON_LINEAR_DISTORTION_SUPPLY_VOLTAGE');
end

