function [similarity, level, defectStruct] = gearing_MISALIGNMENT_SHAFTS(defectStruct, ~, initialPeakTable)
%GEARING_MISIALIGNMENT_SHAFTS 
% Discription: In defect is present 2 shaft harmonics(necessarily), 
% if shaft harmonics into velocity and displacement spectrum, 
% the defect is not dangerous.
%   
%   Developer:      Kosmach
%   Date:                 23.03.2017
%%   
%    main:
%               1) 1,2 *shaftFreq1
%               2)  Fz +(-) shaftFreq1, 2*Fz more remaining
%                   or
%               1) 1,2 *shaftFreq2
%               2)  Fz +(-) shaftFreq2, 2*Fz more remaining
%   

%% ______________ MISIALIGNMENT SHAFTS (defectID = 1) ________________ %%
    shaft1Tag = {17}; % shaftFreq1 tag
    shaft2Tag = {18}; % shaftFreq2 tag
    
    modWhithShaft1 = {[19 17]}; % [Fz +(-) shaftFreq1] tag
    modWhithShaft2 = {[19 18]}; % [Fz +(-) shaftFreq2] tag

    [statusShaft1,defectStruct] = ...
        defectEvaluationForOneShaft(defectStruct, shaft1Tag, modWhithShaft1, initialPeakTable);
    [statusShaft2,defectStruct] = ...
        defectEvaluationForOneShaft(defectStruct, shaft2Tag, modWhithShaft2, initialPeakTable);
    
    similarity = max([statusShaft1, statusShaft2]);
    
    level = 'NaN';
end

% DEFECTEVALUATIONFORONESHAFT function evaluate defect for one shaft
function [status,defectStruct] = defectEvaluationForOneShaft(defectStruct, shaftTag, modWhithShaft, initialPeakTable)   
    
    [gearMeshAccEnvStatus, defectStruct.accelerationEnvelopeSpectrum] = evaluateGearMeshFrequency(...
        defectStruct.accelerationEnvelopeSpectrum, shaftTag, modWhithShaft, ...
        initialPeakTable.accelerationEnvelopeSpectrum, defectStruct.basicFreqs);

    [gearMeshAccStatus, defectStruct.accelerationSpectrum] = evaluateGearMeshFrequency(...
        defectStruct.accelerationSpectrum, shaftTag, modWhithShaft, ...
        initialPeakTable.accelerationSpectrum, defectStruct.basicFreqs);

    status = max([gearMeshAccEnvStatus gearMeshAccStatus*1.2]);
    if status > 1
        status = 1;
    end
end

% DEFECTEVALUATIONFORONESHAFT function evaluate defect for one shaft
function [status,domain] = evaluateGearMeshFrequency(domain, shaftTag, modWhithShaft, initialPeakTable, basicFreqs)

    [shaftPositions, ~, ~, ~, weightsShaft] = getTagPositions(domain, shaftTag);
    
    [positionsMod, estimationsMod, magnitudesMod, ~, weights,domain] = getModulationEvaluationVector(...
                domain, modWhithShaft, initialPeakTable, basicFreqs);
    
    if ~isempty(shaftPositions)
        
        if nnz(estimationsMod)
            posPeakTrueMod = estimationsMod ~= 0;
            estimationsMod(estimationsMod == 0.5) = 0.8;

            posPeakTrueMod = logical(posPeakTrueMod);
            magnitudesMod = magnitudesMod(posPeakTrueMod);
            positionsMod = positionsMod(posPeakTrueMod);
            weights = weights(posPeakTrueMod);
            estimationsMod = estimationsMod(posPeakTrueMod);

            if nnz(positionsMod == 2)
                if nnz(magnitudesMod(positionsMod == 2) >= magnitudesMod) == length(magnitudesMod)
                    secondLargest = 1;
                else
                    secondLargest = 0;
                end
            else
                secondLargest = 0;
            end
        else
            secondLargest = 0;
            weights = 0;
            estimationsMod = 0;
        end
        status = sum(bsxfun(@times, weights, estimationsMod))*secondLargest + sum(weightsShaft);
    else
       status = 0; 
    end
end
