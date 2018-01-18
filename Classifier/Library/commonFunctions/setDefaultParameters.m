function [ config ] = setDefaultParameters( config )
% SETDEFAULTPARAMETERS The function creates and sets the default parameters
% in the input structure
%   Developer:              P. Riabtsev
%   Development date:       15-07-2016

    config.config.parameters.common.printPlotsEn = struct('Text', '', 'Attributes', []);
    config.config.parameters.common.printPlotsEn.Attributes = struct('value', '0');
    
    config.config.parameters.evaluation.filter = struct('Text', '', 'Attributes', []);
    config.config.parameters.evaluation.filter.Attributes = struct('Rp', '1', 'Rs', '10', 'highFreq', '5000', 'lowFreq', '500', 'type', 'BPF');
    
    config.config.parameters.evaluation.peakComparison = struct('Text', '', 'Attributes', []);
    config.config.parameters.evaluation.peakComparison.Attributes = struct('percentRange', '1', 'freqRange', '0.005');
    
    config.config.parameters.evaluation.historyValidator = struct('Text', '', 'Attributes', []);
    config.config.parameters.evaluation.historyValidator.Attributes = struct('dayActualPeriod', '35', 'fullThreshold', '0.75', 'historyFilesCount', '10', 'lastHistoryFilesCount', '3', 'lastThreshold', '0.66', 'state', '1', 'valueSearchRange' , '0.5');
    
    config.config.parameters.evaluation.frequncyEstimationProcessing = struct('rough', [], 'accurate', [], 'Attributes', []);
    config.config.parameters.evaluation.frequncyEstimationProcessing.rough = struct('Text', '', 'Attributes', []);
    config.config.parameters.evaluation.frequncyEstimationProcessing.rough.Attributes = struct('delta', '10', 'step', '0.5');
    config.config.parameters.evaluation.frequncyEstimationProcessing.accurate = struct('Text', '', 'Attributes', []);
    config.config.parameters.evaluation.frequncyEstimationProcessing.accurate.Attributes = struct('delta', '1', 'step', '0.05');
    config.config.parameters.evaluation.frequncyEstimationProcessing.Attributes = struct('plotEn', '0');
    
    config.config.parameters.evaluation.SPM = struct('Text', '', 'Attributes', []);
    config.config.parameters.evaluation.SPM.Attributes = struct('numberThresh', '10', 'distance', '200', 'accurate', '0.05', 'peakCntRequired', '6000', 'cutCoeff', '4', 'plotEnable', '0', 'damegeLevel', '30', 'warningLevel', '20');
    
    config.config.parameters.evaluation.SPM = struct('Text', '', 'Attributes', []);
    config.config.parameters.evaluation.spectralMethod.Attributes = struct('plotEnable', '0', 'sensevity', '0.016', 'cutCoeff', '4', 'Rp', '0.1', 'Rs', '20', 'F_Low', '50', 'F_Med1', '300', 'F_Med2', '1800', 'F_High', '10000', 'v_rms_nominal', '0.05e-6');
    config.config.parameters.evaluation.dividedFindpeaks.Attributes = struct('plotEnable', '0', 'lowFrequency', '5', 'framesNumber', '10', 'frameOverlapValue', '0', 'minPeakProminenceCoef', '3.5', 'minPeaksDistance', '0');
end

