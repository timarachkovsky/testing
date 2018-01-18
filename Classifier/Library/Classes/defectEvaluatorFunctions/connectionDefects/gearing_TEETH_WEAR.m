function [similarity, level, defectStruct] = gearing_TEETH_WEAR(defectStruct, ~, initialPeakTable)
%GEARING_THEETH_WEAR

%   Developer:      Kosmach
%   Date:              23.03.2017
%%
% Defect requirements:
%    main:
%               1) 1,2 * shaftFreq1
%               2) 1* Fz +(-) n*shaftFreq1, n = 1,2..
%                    or
%               1) 1,2 * shaftFreq2
%               2) 1* Fz +(-) n*shaftFreq2, n = 1,2..


%% ______________ TEETH WEAR (defectID = 1) ________________ %%
    shaft1Tag = {17}; % shaftFreq1 tag
    shaft2Tag = {18}; % shaftFreq2 tag
    
    modWhithShaft1 = {[19 17]}; % [Fz +(-) shaftFreq1] tag
    modWhithShaft2 = {[19 18]}; % [Fz +(-) shaftFreq2] tag
    [statusShaft1,defectStruct] = defectEvaluationForOneShaft(defectStruct, shaft1Tag, modWhithShaft1, initialPeakTable);
    [statusShaft2,defectStruct] = defectEvaluationForOneShaft(defectStruct, shaft2Tag, modWhithShaft2, initialPeakTable);
    
    similarity = max([statusShaft1, statusShaft2]);

    level = 'NaN';
end

% DEFECTEVALUATIONFORONESHAFT function evaluate defect for one shaft
function [status,defectStruct] = defectEvaluationForOneShaft(defectStruct, shaftTag, modWhithShaft, initialPeakTable)
    
    [gearMeshAccEnvStatus,defectStruct.accelerationEnvelopeSpectrum] = evaluateGearMeshFrequency(...
        defectStruct.accelerationEnvelopeSpectrum, shaftTag, modWhithShaft, ...
        initialPeakTable.accelerationEnvelopeSpectrum, defectStruct.basicFreqs);

    [gearMeshAccStatus,defectStruct.accelerationSpectrum] = evaluateGearMeshFrequency(...
        defectStruct.accelerationSpectrum, shaftTag, modWhithShaft, ...
        initialPeakTable.accelerationSpectrum, defectStruct.basicFreqs);
%         gearMeshVelStatus = evaluateGearMeshFrequency(defectStruct.velocitySpectrum, modWhithSgaft);

    status = max([gearMeshAccEnvStatus gearMeshAccStatus*1.2]);
    if status > 1
        status = 1;
    end
end

% DEFECTEVALUATIONFORONESHAFT function evaluate defect for one shaft
function [status,domain] = evaluateGearMeshFrequency(domain, shaftTag, modWhithSgaft, initialPeakTable, basicFreqs)


    [shaftPositions, ~, ~, ~, weightsShaft] = getTagPositions(domain, shaftTag);

    [positionsMod, estimationsMod, magnitudesMod, ~, weights,domain] = getModulationEvaluationVector(...
                domain, modWhithSgaft, initialPeakTable, basicFreqs);
    
    if ~isempty(shaftPositions)
        
        if nnz(estimationsMod)
            posPeakTrueMod =  estimationsMod ~= 0;
            estimationsMod(estimationsMod == 0.5) = 0.8;

            posPeakTrueMod = logical(posPeakTrueMod);
            magnitudesMod = magnitudesMod(posPeakTrueMod);
            positionsMod = positionsMod(posPeakTrueMod);
            weights = weights(posPeakTrueMod);
            estimationsMod = estimationsMod(posPeakTrueMod);

            if nnz(positionsMod == 1)
                if nnz(magnitudesMod(positionsMod == 1) >= magnitudesMod) == length(magnitudesMod)
                    firstLargest = 1;
                else
                    firstLargest = 0;
                end
            else
                firstLargest = 0;
            end
        else
            firstLargest = 0;
            estimationsMod = 0;
        end
        status = sum(bsxfun(@times, weights, estimationsMod))*firstLargest + sum(weightsShaft);
    else
        status = 0;
    end
end