% SUN_SHAFT_RUN_OUT function returns status of defect
%
% Defect requirements:
%%
%    main:
%               1) k * sunFreq, k > 1
%    
%    additional: 
%               1) k * [gearMeshFreqSun +- (sunFreq - carrierFreq)], k =
%               1,2 ...
%   
% 
% Developer:              Kosmach N.
% Development date:       04.10.2017
% Modified by:            
% Modification date:      

function [similarityHistory, historyDangerous] = history_planetaryStageGearbox_SUN_SHAFT_RUN_OUT(defectStruct, myFiles)

    sunFreqTag = 20; % sunFreq
    modTag = [24 23]; % [gearMeshFreqSun +- diffFreq] tag
    
    % To evaluate acceleration spectrum
    [statusAcc, dangerAcc] = spectrumEvaluation(defectStruct.accelerationSpectrum, sunFreqTag, modTag, myFiles);
    
    % To evaluate envelope acceleration spectrum
    [statusEnv, dangerEnv] = spectrumEvaluation(defectStruct.accelerationEnvelopeSpectrum, sunFreqTag, modTag, myFiles);
    
    similarityHistory = max([statusAcc*1.2 statusEnv]);
    similarityHistory(similarityHistory < 0) = 0;
    similarityHistory(similarityHistory > 1) = 1;
    
    historyDangerous = max([dangerAcc dangerEnv]);
end

% ACCENVSPECTRUMEVALUATION function calculate status to sprctrums domain
function [weightsStatus, dangerStatus] = spectrumEvaluation(domain, sunFreqTag, modTag, myFiles)
    
    % Get sunFreqTag data
    [positions, names, magnitudes, weights, positionValid] = getTagPositionsHistory(domain, sunFreqTag);
    % To get peaks evaluated of history 
    statusThresholdAndTrend = evaluatorThresholdTrend(domain.trendResult(positionValid), ...
        domain.statusCurrentThreshold(positionValid), domain.trainingPeriodInitialTagNames, names);
    % Validation rule
    if ~isempty(positions)
        % Preallocate defect peak index
        defectPeaksIndex = false(length(magnitudes), 1);
        % Evaluate the first harmonic
        firstHarmonicIndex = find(positions == 1);
        if ~isempty(firstHarmonicIndex)
            % Validate the first hatmonic
            defectPeaksIndex(firstHarmonicIndex) = magnitudes(firstHarmonicIndex) == max(magnitudes(positions ~= 2));
            % Evaluate higher harmonics
            for peakNumber = firstHarmonicIndex + 1 : 1 : length(magnitudes)
                % Check that current peak is less than 75% of previous peaks
                isLessHigherHarmonic = all(magnitudes(peakNumber) < (0.75 * magnitudes(defectPeaksIndex)));
                % Check that current peak is greater than 25% of previous peaks
                isGreaterHigherHarmonic = any(magnitudes(peakNumber) > (0.25 * magnitudes(defectPeaksIndex)));
                % Validate current peak
                defectPeaksIndex(peakNumber) = isLessHigherHarmonic & isGreaterHigherHarmonic;
            end
        end
        % Get valid history
        historyValid = statusThresholdAndTrend(defectPeaksIndex);
        % Get valid data
        defectWeights = weights(defectPeaksIndex)';
        % Evaluate weights
        weightsStatus = sum(bsxfun(@times, defectWeights, historyValid));
        
        dangerStatus = sum(bsxfun(@times, weights', statusThresholdAndTrend));
    else
        weightsStatus = 0;
        dangerStatus = 0;
    end
    
    % To get history informations about modulations
    resultStructMod = evaluationModulationHistory(domain, myFiles);
    
    % To find needed tag for modTag
    positionsheave1Needed = bsxfun(@and, resultStructMod.mainTag == modTag(1), ...
                                            resultStructMod.sideBandTag == modTag(2));
                                        
    % Evaluate weights for modTag
    modWeightsStatus = sum(bsxfun(@times, resultStructMod.status(positionsheave1Needed), ...
                                             resultStructMod.weightMainPeak(positionsheave1Needed)));
    if modWeightsStatus > 0.2
        modWeightsStatus = 0.2;
    end                                                                       
    
    % Combine weights statuses
    weightsStatus = weightsStatus + modWeightsStatus;
    
    dangerStatus = dangerStatus + modWeightsStatus;
end