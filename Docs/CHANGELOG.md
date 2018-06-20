# Changelog

## [Unreleased]
- Added attribute enoughtPlotWekness to config.parameters.evaluation.frequencyDomainClassifier.Attributes in config.xml by @N.Kosmach.
- Added attribute enoughHistorySimilarity to config.parameters.evaluation.decisionMaker.decisionMakerHistory.Attributes in config.xml by @N.Kosmach.
- Added attributes filtrationType, framesThreshold, maxFrequencyBPF, minFrequencyBPF, minAnalysisFrequency, degreeThreshold, processingType, medianDeviation to config.parameters.evaluation.timeSynchronousAveraging.Attributes in config.xml by @N.Kosmach.
- Added attributes autoThresholdsEnable, intensivityThreshold, stablePeriodStatus to config.parameters.evaluation.history.timeSynchronousAveraging.Attributes in config.xml by @N.Kosmach.
- Removed attributes validGM, validShaftFreq from timeSynchronousAveraging.informativeTags.gearing(:).Attributes in status.xml by @N.Kosmach.
- Added attributes name, trainingPeriodMean, trainingPeriodStd to timeSynchronousAveraging.informativeTags.history.Attributes in status.xml by @N.Kosmach.
- Added field standardPartDeterminationEnable into parameters.evaluation.iso7919 to config.xml by @P.Riabtsev.
- Changed structure of iso7919 in config.xml by @P.Riabtsev.
- Added attribute firstDateProcessing in status.equipment.Attribites to status.xml by @N.Kosmach.
- Changed attribute firstSampleNumber by firstSampleTime in config.parameters.evaluation.metrics in config.xml by @P.Riabtsev.
- Removed attributes lowFreq and highFreq from config.parameters.evaluation.spectra.envSpectrum in config.xml by @P.Riabtsev.
- Added attribute accelerationEnvelopeRange to config.parameters.evaluation.spectra in config.xml by @P.Riabtsev.

## [3.4.1] - 2018-05-18
### Added
#### config.xml 
- added set of `logSpectrum` parameters to config.parameters.evaluation.timeFrequencyDomainClassifier in config.xml by @N.Kosmach.

## [3.4.0] - 2018-05-16
### Added  
#### config.xml
- fields `spectralBeamEstimator` to config.parameters.evaluation.frequencyCorrector by @D.Kechik.
- fields `rough`, `accurate`, `validationFrames` to config.parameters.evaluation.frequencyCorrector.spectralBeamEstimator by @D.Kechik.
- attributes `processingEnable`, `plotEnable`, `percentRange`, `percentStep`, `dfPercentAccuracy`, `nPeaks`, `minPeakDistance`, `mainFramesNumber`, `additionalFramesNumber`, `SortStr`, `maxPeaksInResult`, `minOverMaximumThreshold`, `baseVal` to config.parameters.evaluation.frequencyCorrector.spectralBeamEstimator.rough by @D.Kechik.
- attributes `processingEnable`, `plotEnable`, `percentRange`, `percentStep`, `dfPercentAccuracy`, `nPeaks`, `minPeakDistance`, `mainFramesNumber`, `additionalFramesNumber`, `SortStr`, `maxPeaksInResult`, `minOverMaximumThreshold`, `baseVal` to config.parameters.evaluation.frequencyCorrector.spectralBeamEstimator.accurate by @D.Kechik.
- attributes `plotEnable`, `minPeakHeight`, `SortStr`, `maxPeaksInResult`, `minOverMaximumThreshold`, `baseVal`, `minProbability`, `minMagnitude` to config.parameters.evaluation.frequencyCorrector.spectralBeamEstimator.validationFrames by @D.Kechik.
- fields hilbertFrequencyEstimator to config.parameters.evaluation.frequencyCorrector by @D.Kechik.
- attributes `plotEnable`,`frequencies`,`maxInvalidPercent` to config.parameters.evaluation.frequencyCorrector.hilbertFrequencyEstimator by @D.Kechik.
- attributes `trackTimeIntervalSec`,`method` in config.parameters.evaluation.frequencyTracking by @Y.Aslamov.
- fields `spectrogramTracker` and `hilbertTracker` to config.parameters.evaluation.frequencyTracking by @Y.Aslamov.
- attribute `type` to config.parameters.evaluation.frequencyTracking.spectrogramTracker by @Y.Aslamov.
- attribute `type` to config.parameters.evaluation.frequencyTracking.hilbertTracker by @Y.Aslamov.
- fields `accTracker` and `envTracker` to config.parameters.evaluation.frequencyTracking.hilbertTracker by @Y.Aslamov.
- attributes `plotEnable`,`frequencies`,`maxInvalidPercent` to config.parameters.evaluation.frequencyTracking.hilbertTracker.accTracker by @Y.Aslamov.
- attributes `plotEnable`,`frequencies`,`maxInvalidPercent` to config.parameters.evaluation.frequencyTracking.hilbertTracker.envTracker by @Y.Aslamov.
- attributes `interpolationEnable` to config.parameters.evaluation.spectra by @Y.Aslamov.
- attributes `type`,`criterion`,`factor`,`df` to config.parameters.evaluation.spectra.interpolation by @Y.Aslamov.
- set of piecewisePhaseAlignment configuration parameters to config.parameters.evaluation.preprocessing.piecewisePhaseAlignment by @Y.Aslamov.
- attributes `processingEnable`,`plotEnable`,`framesNumber`,`centralFrequency`,`waveletName`,`maxPercentDeviation` to config.parameters.evaluation.preprocessing.piecewisePhaseAlignment by @Y.Aslamov.
- field `type` to config.parameters.evaluation.timeFrequencyClassifier.filtering.Attributes by @Y.Aslamov.
- fields `Rp` and `Rs` to config.parameters.evaluation.timeFrequencyClassifier.filtering.bpf.Attributes by @Y.Aslamov.
- field `waveletName` to config.parameters.evaluation.timeFrequencyClassifier.filtering.wavelet.Attributes by @Y.Aslamov.
- set of scalogramHandler configuration parameters to config.parameters.evaluation.scalogramHandler.SSD by @Y.Aslamov.
- fields `frequencyRefinementEnable`, `coefficientsRefinementEnable` to config.parameters.evaluation.scalogramHandler.SSD.Attributes by @Y.Aslamov.
- fields `accuracyPercent`, `percentRange` to config.parameters.evaluation.scalogramHandler.SSD.frequencyRefinement.Attributes by @Y.Aslamov.
- attributes dumpFileName and versionMat in config.parameters.evaluation.history by @N.Kosmach.
- attribute typicalPercentDeviation in config.parameters.evaluation.frequencyTracking by @N.Kosmach.
- attributes gearingClassifierMode and gearingAveragingMode in config.parameters.evaluation.frequencyDomainClassifier by @N.Kosmach.
- language to config.parameters.evaluation.plots.Attributes by @T.Rachkovsky.
- attributes notInitThresholdsCoeff in config.parameters.evaluation.history.frequencyDomainHistoryHandler by @N.Kosmach.
- confidenceDeviation, positionBSF, positionOther to config.parameters.evaluation.bearingsParametersRefinement.Attributes by @N.Kosmach.
- configMode, informativeTagsMode to config.parameters.evaluation.debugMode.Attributes by @N.Kosmach.
- includeEnergyPeaks to config.parameters.evaluation.bearingsParametersRefinement.peakComparison.Attributes by @N.Kosmach. 
- includeEnergyPeaks to config.parameters.evaluation.frequencyDomainClassifier.peakComparison.Attributes by @N.Kosmach. 
- trainingPeriod to config.parameters.evaluation.history.frequencyDomainHistoryHandler.Attributes by @N.Kosmach. 
- enableEnergyPeakFinder to config.parameters.evaluation.spectra.logSpectrum.Attributes by @N.Kosmach.
- minSampleNumber to config.parameters.evaluation.history.Attributes by @N.Kosmach.
- defaultTrainingPeriodMode to config.parameters.evaluation.history.frequencyDomainHistoryHandler.Attributes by @N.Kosmach. 
- enable to config.parameters.evaluation.history.trend.Attributes by @N.Kosmach. 
- amplitudeModifierModeEnable to config.parameters.evaluation.history.frequencyDomainHistoryHandler.Attributes by @N.Kosmach. 
#### informativeTags.xml
- amplitudeModifier to classStruct.*.*.defect.Attributes.amplitudeModifier to informativeTags.xml by @N.Kosmach. (fields are not required)
- defect SELF_EXCITED_VIBRATIONS into tag classStruct.shaftClassifier.shaft to informativeTags.xml by @P.Riabtsev
#### status.xml
- fields `mean`,`std`,`min`,`max`,`median`,`method` to status.frequencyTracking by @Y.Aslamov.
- correlation to equipmentState.informativeTags.psd by @P.Riabtsev.

### Changed
#### config.xml
- set of frequencyTracking configuration parameters in config.parameters.evaluation.frequencyTracking by @Y.Aslamov.
- set of timeFrequencyClassifier configuration parameters in config.parameters.evaluation.timeFrequencyClassifier by @Y.Aslamov.

### Removed
#### config.xml
- removed attributes `interpolationEnable` in config.parameters.evaluation.spectra.envSpectrum by @Y.Aslamov.
- removed fields `Rp`,`Rs`,`typeOfFilter` in config.parameters.evaluation.timeFrequencyClassifier.Attributes by @Y.Aslamov.
- removed attribute `type` in config.parameters.evaluation.frequencyTracking by @Y.Aslamov.
#### status.xml
- fields validate and unvalidate in frequencyDomain method by @N.Kosmach.
- field imageData in all methods by @N.Kosmach.
#### translations.xml
- removed from /In folder by @T.Rachkovsky.

## [3.3.0] - 2018-04-04
### Added
#### config.xml
- trustedInterval to frequencyCorrector by @D.Kechik.
- plotAllShafts to frequencyCorrector by @D.Kechik.
- fuzzyEnable to frequencyCorrector by @D.Kechik.
- shortWindow to frequencyCorrector by @D.Kechik.
- validationFrames to fuzzyFrequencyEstimator by @D.Kechik.
- vdi3834Enable to common parameters by @P.Riabtsev.
- timeSynchronousAveraging to by @N.Kosmach.
- signalStates to by @N.Kosmach.
- psd parameters to equipmentStateDetection by @P.Riabtsev.
- new unidentifiedPeaksNumbers metrics for all spectra by @N.Kosmach.
- new bearingsParametersRefinement method by @N.Kosmach.
- plotWeakDamages to debugMode by @N.Kosmach.
- iso10816 parameters evaluation to by @P.Riabtsev.
- decisionMakerStates to equipmentStateDetection by @P.Riabtsev.
- trainingPeriodStartDate to history by @P.Riabtsev.
- serialNo, resonantFrequency fields to config.parameters.sensor by @@Yu.Aslamov.
- temperatureEnable to config.parameters.common by @N.Kosmach.
- resonogram method by @Yu.Aslamov.
#### status.xml
- vdi3834 by @P.Riabtsev.
- timeSynchronousAveraging by @N.Kosmach.
- signalStates by @N.Kosmach.
- psd results to equipmentStateDetection by @P.Riabtsev.
- new unidentifiedPeaksNumbers metrics for all spectra by @N.Kosmach.
- new bearingsParametersRefinement method by @N.Kosmach.
- trainingDate to equipmentStateDetection.psd.lpc by @P.Riabtsev.
- temperature by @N.Kosmach.
- resonogram method by @Yu.Aslamov.
#### equipmentProfile.xml
- group attribute by @P.Riabtsev.
- equipmentPower and equipmentSupport to equipment by @P.Riabtsev.
- group tag by @P.Riabtsev.
#### translations.xml
- added translations.xml by @T.Rachkovsky.
#### informativeTags.xml
- psd to equipmentStateDetection by @P.Riabtsev.

### Changed
#### config.xml
- frequencyDomainClassifier by @N.Kosmach.
- grouped metrics parameters of equipmentStateDetection by @P.Riabtsev.
- parameters of spectra/logSpectrum by @N.Kosmach.
- replaced attribute `sensevity` by `sensitivity` in iso15242 by @N.Kosmach.
- replaced attribute `traningPeriodFormula` by `status` in history by @N.Kosmach.
- replaced name attribute by type in config.parameters.sensor by @Yu.Aslamov.
- moved octaveSpectrum from config.parameters.evaluation.spectra to config.parameters.evaluation by @N.Kosmach.
#### status.xml
- replaced attribute `state` by `status` in equipmentStateDetection by @P.Riabtsev.
- moved from spmDBmDBc.status.Attributes.dBcTrend to spmDBmDBc.status.dBc.Attributes.trend by @N.Kosmach.
- moved from spmDBmDBc.status.Attributes.dBmTrend to spmDBmDBc.status.dBm.Attributes.trend by @N.Kosmach.
- moved from spmLRHR.status.Attributes.deltaTrend to spmLRHR.status.delta.Attributes.trend by @N.Kosmach.
- moved from spmLRHR.status.Attributes.hRTrend to spmLRHR.status.delta.Attributes.hR by @N.Kosmach.
- moved from spmLRHR.status.Attributes.lRTrend to spmLRHR.status.delta.Attributes.lR by @N.Kosmach.
- moved from spmLRHR.status.Attributes.statusOfHistoryDelta to spmLRHR.status.delta.Attributes.statusOfHistory by @N.Kosmach.
- moved from spmLRHR.status.Attributes.statusOfHistoryHR to spmLRHR.status.hR.Attributes.statusOfHistory by @N.Kosmach.
- moved from spmLRHR.status.Attributes.statusOfHistoryLR to spmLRHR.status.lR.Attributes.statusOfHistory by @N.Kosmach.
- moved from iso15242.status.Attributes.statusVRms1 to iso15242.status.vRms1Log.Attributes.statusOfHistory by @N.Kosmach.
- moved from iso15242.status.Attributes.statusVRms2 to iso15242.status.vRms2Log.Attributes.statusOfHistory by @N.Kosmach.
- moved from iso15242.status.Attributes.statusVRms3 to iso15242.status.vRms3Log.Attributes.statusOfHistory by @N.Kosmach.
- moved from iso15242.status.Attributes.vRms1LogTrend to iso15242.status.vRms1Log.Attributes.trend by @N.Kosmach.
- moved from iso15242.status.Attributes.vRms2LogTrend to iso15242.status.vRms2Log.Attributes.trend by @N.Kosmach.
- moved from iso15242.status.Attributes.vRms3LogTrend to iso15242.status.vRms3Log.Attributes.trend by @N.Kosmach.
- metrics results were inserted into tag <metrics/> in equipmentStateDetection by @P.Riabtsev.
#### equipmentProfile.xml
- equipmentClass in equipment by @P.Riabtsev.
#### informativeTags.xml
- tag shaft - FTF by @N.Kosmach.
- grouped metrics parameters of equipmentStateDetection by @P.Riabtsev.
- coupling was moved from couplingClassifier to connectionClassifier by @N.Kosmach.

### Removed
#### config.xml
- trainingPeriod.lastData from equipmentStateDetection by @P.Riabtsev.
- trainingPeriod.period from equipmentStateDetection by @P.Riabtsev.
- decisionMaker tag from equipmentStateDetection by @P.Riabtsev.
- printAxonometry from config.parameters.common by @N.Kosmach.
- spmDBmDBc.status.Attributes.dBcVolatility by @N.Kosmach.
- spmDBmDBc.status.Attributes.dBcVolatilityLevel by @N.Kosmach.
- spmDBmDBc.status.Attributes.dBmVolatility by @N.Kosmach.
- spmDBmDBc.status.Attributes.dBmVolatilityLevel by @N.Kosmach.
- spmDBmDBc.status.Attributes.deltaVolatility by @N.Kosmach.
- spmDBmDBc.status.Attributes.deltaTrend by @N.Kosmach.
- spmDBmDBc.status.Attributes.deltaVolatility by @N.Kosmach.
- spmDBmDBc.status.Attributes.deltaVolatilityLevel by @N.Kosmach.
- spmLRHR.status.Attributes.deltaVolatility by @N.Kosmach.
- spmLRHR.status.Attributes.deltaVolatilityLevel by @N.Kosmach.
- spmLRHR.status.Attributes.hRVolatility by @N.Kosmach.
- spmLRHR.status.Attributes.hRVolatilityLevel by @N.Kosmach.
- spmLRHR.status.Attributes.lRVolatility by @N.Kosmach.
- spmLRHR.status.Attributes.lRVolatilityLevel by @N.Kosmach.
- iso15242.status.Attributes.vRms1LogVolatility by @N.Kosmach.
- iso15242.status.Attributes.vRms1LogVolatilityLevel by @N.Kosmach.
- iso15242.status.Attributes.vRms2LogVolatility by @N.Kosmach.
- iso15242.status.Attributes.vRms2LogVolatilityLevel by @N.Kosmach.
- iso15242.status.Attributes.vRms3LogVolatility by @N.Kosmach.
- iso15242.status.Attributes.vRms3LogVolatilityLevel by @N.Kosmach.
- frequencyDomainClassifier.schemeValidator.dispSpecValidator by @N.Kosmach.
- frequencyDomainClassifier.schemeValidator.velSpecValidator by @N.Kosmach.
- frequencyDomainClassifier.schemeValidator.accSpecValidator by @N.Kosmach.
- frequencyDomainClassifier.schemeValidator.accEnvSpecValidator by @N.Kosmach.
#### status.xml
- attribute `volatility` from iso15242, spmDBmDBc, spmLRHRfrom, metrics by @N.Kosmach.
- attribute `volatilityLevel` from iso15242, spmDBmDBc, spmLRHRfrom, metrics by @N.Kosmach.

[Unreleased]:
[3.4.1]: https://github.com/VibroBox/ComputeFramework/commit/
[3.4.0]: https://github.com/VibroBox/ComputeFramework/commit/be28666e4ffba18496e54529da4c252f1264ae45
[3.3.0]: https://github.com/VibroBox/ComputeFramework/commit/49361221c01325557019d1977fbf8b7168133900