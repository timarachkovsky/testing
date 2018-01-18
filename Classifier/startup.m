%% ******************** ADD PATH TO THE MAIN FUNCTIONs **************** %%
addpath(fullfile(pwd, 'In'));

%% ____________________ Classifier functions ___________________________ %%
addpath(fullfile(pwd, 'Library'));
addpath(fullfile(pwd, 'Library', 'Classes'));
addpath(fullfile(pwd, 'Library', 'Classes', 'schemeValidatorFunctions'));
addpath(fullfile(pwd, 'Library', 'Classes', 'defectEvaluatorFunctions'));
addpath(fullfile(pwd, 'Library', 'Classes', 'defectEvaluatorFunctions', 'bearingDefects'));
addpath(fullfile(pwd, 'Library', 'Classes', 'defectEvaluatorFunctions', 'connectionDefects'));
addpath(fullfile(pwd, 'Library', 'Classes', 'defectEvaluatorFunctions', 'motorDefects'));
addpath(fullfile(pwd, 'Library', 'Classes', 'defectEvaluatorFunctions', 'shaftDefects'));
addpath(fullfile(pwd, 'Library', 'Classes', 'defectEvaluatorFunctions', 'couplingDefects'));
addpath(fullfile(pwd, 'Library', 'Classes', 'defectEvaluatorFunctions', 'fanDefects'));
addpath(fullfile(pwd, 'Library', 'Classes', 'defectEvaluatorFunctions', 'common'));
addpath(fullfile(pwd, 'Library', 'Classes', 'elementEvaluatorFunctions'));
addpath(fullfile(pwd, 'Library', 'Classes', 'elementEvaluatorFunctions', 'commonFunction'));
addpath(fullfile(pwd, 'Library', 'frequencyCorrectionToolbox'));
addpath(fullfile(pwd, 'Library', 'frequencyCorrectionToolbox', 'DisplacementValidationFrames'));
addpath(fullfile(pwd, 'Library', 'historyToolbox'));
addpath(fullfile(pwd, 'Library', 'historyToolbox', 'trendFunctions'));
addpath(fullfile(pwd, 'Library', 'historyToolbox', 'commonFunctionHistory'));
addpath(genpath(fullfile(pwd, 'Library', 'historyToolbox', 'historyDefectEvaluatorFunctions')));
addpath(fullfile(pwd, 'Library', 'commonFunctions'));
addpath(fullfile(pwd, 'Library', 'commonFunctions','spectrumCalculation'));
addpath(fullfile(pwd, 'Library', 'commonFunctions','equipmentStateDetection'));
javaaddpath(fullfile(pwd, 'Library', 'commonFunctions', 'JSON.jar'));

%% ____________________ Monitoring Methods _____________________________ %%
addpath(fullfile(pwd, 'Library', 'metrics'));
addpath(fullfile(pwd, 'Library', 'metrics', 'spm'));
addpath(fullfile(pwd, 'Library', 'metrics', 'iso7919'));
addpath(fullfile(pwd, 'Library', 'metrics', 'iso15242'));
addpath(fullfile(pwd, 'Library', 'metrics', 'octaveSpectrum'));

%% ____________________ sparseRepresentation method fucntions __________ %%
addpath(fullfile(pwd, 'Library', 'sparseRepresentation'));
addpath(fullfile(pwd, 'Library', 'sparseRepresentation','common'));
addpath(fullfile(pwd, 'Library', 'sparseRepresentation','scalogram'));
addpath(fullfile(pwd, 'Library', 'sparseRepresentation','periodEstimation'));
addpath(fullfile(pwd, 'Library', 'sparseRepresentation','sparseDecomposition'));
addpath(fullfile(pwd, 'Library', 'sparseRepresentation','classification'));
addpath(fullfile(pwd, 'Library', 'sparseRepresentation','patternExtraction'));
addpath(fullfile(pwd, 'Library', 'sparseRepresentation','patternClustering'));
addpath(fullfile(pwd, 'Library', 'sparseRepresentation','wavelets'));
addpath(fullfile(pwd, 'Library', 'sparseRepresentation','wavelets','swdBasis'));

addpath(genpath(fullfile(pwd, 'Library', 'sparseRepresentation','patternClustering')));

%% ____________________ Support vector machine _________________________ %%
addpath(fullfile(pwd, 'Library', 'sparseRepresentation', 'classification', 'defectEvaluatorFunctions'));
addpath(fullfile(pwd, 'Library', 'sparseRepresentation', 'classification', 'defectEvaluatorFunctions', 'bearingDefects'));
addpath(fullfile(pwd, 'Library', 'sparseRepresentation', 'classification', 'defectEvaluatorFunctions', 'connectionDefects'));
addpath(fullfile(pwd, 'Library', 'sparseRepresentation', 'classification', 'defectEvaluatorFunctions', 'motorDefects'));
addpath(fullfile(pwd, 'Library', 'sparseRepresentation', 'classification', 'defectEvaluatorFunctions', 'shaftDefects'));

%% _____________________Frequency Tracking Toolbox _____________________ %%
addpath(genpath(fullfile(pwd, 'Library', 'frequencyTrackingToolbox')));

%% _____________________ Self test functions ___________________________ %%
addpath(fullfile(pwd, '..', 'FunctionalTesting', 'testsRun', 'commonFunctions'));

%% _____________________ Time Synchronous Averaging Toolbox ___________________________ %%
addpath(genpath(fullfile(pwd, 'Library', 'timeSynchronousAveragingToolbox')));

%% _____________________Frequency Tracking Toolbox _____________________ %%
addpath(genpath(fullfile(pwd, 'Library', 'frequencyTrackingToolbox')));