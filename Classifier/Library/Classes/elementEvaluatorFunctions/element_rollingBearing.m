function statusStruct = element_rollingBearing(statusStruct)

    % To evaluate WEAR_OUTER_RING and GROOVES_CRACKS_OUTER_RING
    statusStruct = evaluateTwoDefect(statusStruct, 'WEAR_OUTER_RING', 'GROOVES_CRACKS_OUTER_RING');
    
    % To evaluate WEAR_INNER_RING and GROOVES_CRACKS_INNER_RING
    statusStruct = evaluateTwoDefect(statusStruct, 'WEAR_INNER_RING', 'GROOVES_CRACKS_INNER_RING');
    
    % To evaluate COCKED_OUTER_RING and COCKED_INNER_RING
    statusStruct = evaluateTwoDefect(statusStruct, 'COCKED_OUTER_RING', 'COCKED_INNER_RING');
end