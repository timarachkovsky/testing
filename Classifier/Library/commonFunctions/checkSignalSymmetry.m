% Developer:              Kosmach N.
% Development date:       19-12-2017
% Modified by:            
% Modification date:  

% Function evaluate signal electromagnetic interference and correct
% place install
function states = checkSignalSymmetry(acceleration, threshold)
    
    % Evaluate first chanel
    signalStates = evaluateChanel(acceleration.signal, threshold);
    
    % Evaluate second chanel
    if isfield(acceleration, 'secondarySignal')
        
        signalStatesChanel2 = evaluateChanel(acceleration.secondarySignal, threshold);
        
        if signalStatesChanel2 && signalStates
            signalStates = true(1, 1);
        else
            signalStates = false(1, 1);
        end
    end
    
    % Get status
    if signalStates
        states = 'symmetrical';
    else
        states = 'dissymmetrical';
    end
end

function states = evaluateChanel(signal, threshold)

    % Find value std of signal up zero
    stdPlus = std(signal(signal > 0));
    % Find value std of signal down zero
    stdMinus = std(signal(signal < 0)); 

    % Evaluate status
    currentValue = abs(1 - stdPlus/stdMinus);
    if currentValue > threshold
        states = false(1, 1);
    else
        states = true(1, 1);
    end
end
