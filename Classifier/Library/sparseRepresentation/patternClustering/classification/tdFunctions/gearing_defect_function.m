function [ similarity, severity, tag ] = gearing_defect_function(base, config)
%BEARING_DEFECT_FUNCTION Summary of this function goes here
%   Detailed explanation goes here

    similarity = 0; % dummmy
    severity = 0;
    
    resonantTags = {base.resonantTag};
    MF_base = base(ismember('MF', resonantTags));
    HF_base = base(ismember('HF', resonantTags));
    
    if ~isempty(MF_base)
        similarityMF = zeros(size(MF_base));
        for i = 1:numel(MF_base)
            similarityMF(i) = probabilityEstimation(MF_base(i));
        end
    else
        similarityMF = 0;
    end
        
    if ~isempty(HF_base)
        similarityHF = zeros(size(HF_base));
        for j = 1:numel(HF_base)
            similarityHF(j) = probabilityEstimation(HF_base(j));
        end
    else
        similarityHF = 0;
    end
    
%     similarity = max(similarityMF)*0.8 + max(similarityHF)*0.2;
    similarity = max([similarityMF,similarityHF]);
    if similarityMF>0.7 && similarityMF>0.7
        tag = 'NaN';
    elseif similarityMF>0.7
        tag = 'gearing';
    elseif similarityHF>0.7
        tag = 'NaN';
    else
        tag = 'NaN';
    end
%     if similarity > 1
%        similarity = 1; 
%     end
    severity = base.energyContribution;
    
    
% ----------------------- Subfunction  -------------------------------- %
    function [total_probability] = probabilityEstimation(base)
        
        total_probability = 0;
        
        % Pattern type == 'gearing' -> 0.5 
        patternType_probability_base = 0.6;
        patternType_validity = base.ptrn_elementEnergy(ismember('gearing' , base.ptrn_elementVector));
        if patternType_validity > 0.5
            total_probability = total_probability + patternType_probability_base;
        else
            total_probability = total_probability + patternType_validity*patternType_probability_base;
        end
        
        % Signal type == 'continuous' -> 0.25
        signalType_probability_base = 0.4;
        switch (base.signalType{1})
            case 'PULSE'
                signalType_validity = 0;
            case 'PULSECONTINUOUS'
                signalType_validity = 0.25;
            case 'CONTINUOUS'
                signalType_validity = 1;
            case 'UNKNOWN'
                signalType_validity = 0;
            otherwise 
                signalType_validity = 0;
        end
        total_probability = total_probability + signalType_validity*signalType_probability_base;
        
        % Periodicity = 'true' -> 0.1
        periodicity_probability_base = 0.1;
        if ~isempty(base.prd_frequency)
            periodicity_validity = periodicity_probability_base*max(base.prd_validity); % <<<<< ---- Add periodicity type analysis
        else
            periodicity_validity = 0;
        end
        total_probability = total_probability + periodicity_validity;
        
        
        % Equipment type == 'gearing' -> 0.1;
        equipmentType_probability_base = 0.2;
        if strcmp(base.equip_elementType, 'gearing')
            equipType_validity = 1; 
        else
            equipType_validity = 0;
        end
        total_probability = total_probability + equipmentType_probability_base*equipType_validity;
        
        % Energy contribution  > 60% -> 0.15
        EC_probability_base = 0.15;
        if base.energyContribution >= 0.6
            EC_validity = 1; 
        else
            EC_validity = 0;
        end
        total_probability = total_probability + EC_probability_base*EC_validity;
        
        
        if total_probability > 1
           total_probability = 1; 
        end
    