Specification.  
Config.xml file format
====

*Editors: Aslamov Yu., Kechik D., Riabtsev P., Kosmach N.*  
*Date: 03-03-2018*  
*Version: 3.4.1*  
----

## Content

[1. sensors](#sensors)  
[2. common](#common)  
&nbsp;&nbsp;&nbsp;&nbsp;[2.1. printPlotsEnable](#printPlotsEnable)  
[3. evaluation](#evaluation)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.1. debugMode](#debugMode)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.2. loger](#loger)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.3. plots](#plots)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.4. spectra](#spectra)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.5. metrics](#metrics)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.6. equipmentStateDetection](#equipmentStateDetection)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.7. frequencyCorrector](#frequencyCorrector)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.8. shaftTrajectoryDetection](#shaftTrajectoryDetection)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.9. iso7919](#iso7919)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.10. frequencyDomainClassifier](#frequencyDomainClassifier)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.11. scalogramHadler](#scalogramHadler)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.12. periodicityProcessing](#periodicityProcessing)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.13. timeDomainClassifier](#timeDomainClassifier)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.14. timeFrequencyDomainClassifier](#timeFrequencyDomainClassifier)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.15. spm](#spm)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.16. iso15242](#iso15242)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.17. octaveSpetrum](#octaveSpetrum)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.18. decisionMaker](#decisionMaker)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.19. history](#history)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.20. statusWriter](#statusWriter)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.21. frequencyTracking](#frequencyTracking)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.22. timeSynchronousAveraging](#timeSynchronousAveraging)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.23. checkSignalSymmetry](#checkSignalSymmetry)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.24. bearingsParametersRefinement](#bearingsParametersRefinement)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.25. octaveSpectrum](#octaveSpectrum)  
___
config.xml is a configuration file for the computeFremework. The specification contains a brief information about the config.xml structure and parameters for customizing individual methods.

Table 1. - A brief config.xml structure

| Name of the field  | Description                                                                                                       |
|--------------------|-------------------------------------------------------------------------------------------------------------------|
| **\<common/>**     | intended for basic setting of the framework: switching on/off toolbars/methods, operating modes, etc.             |
| **\<evaluation/>** | intended for detailed configuration of the framework, contains parameters of each method involved in processing.  |

&nbsp;

## <a name="sensors">1. sensors</a>

```
<sensor type="BR" serialNo="M1071364749" equipmentDataPoint="1" resonantFrequency="10000" channelsNumber="1" primaryChannelNo="1" lowFrequency="4" highFrequency="10000" sensitivity="32" sensitivityCorrection="1" description="Basic sensor parameters"/>
```
Picture 1.1. - Writing format in config.xml of settings **\<sensor/>**

&nbsp;

Table 1.1. - **\<sensor/>** structure

| Name of the field       | Description                                                                                                                                                                                    |
|-------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| *type*                  | Sensor type                                                                                                                                                                                    |
| *serialNo*              | Sensor serial number (individual)                                                                                                                                                              |
| *channelsNumber*        | Number of channels (orthogonal) of data collection                                                                                                                                             |
| *primaryChannelNo*      | The number of the main channel for processing (usually radial direction). For sensors with 2 or more channels, this parameter is individual * (determined after installation on the equipment) |
| *lowFrequency*          | The lower limit frequency of the sensor's linear measuring range (determined by the parameters of the accelerometer and the "binding" of the sensor's ADC), [Hz]                               |
| *highFrequency*         | The upper limit frequency of the linear measuring range of the sensor (determined by the parameters of the accelerometer + type of sensor designs + used mount (magnet/thread)), [Hz]          |
| *sensitivity*           | The resulting sensitivity of the accelerometer + converter (same for all sensors of the same type), [mV/g]                                                                                     |
| *sensitivityCorrection* | The coefficient of sensitivity correction, determined by the results of metrological tests on vibration table (individual for each sensor)                                                     |
| *resonantFrequency*     | Own resonance frequency of the vibration sensor (the central frequency of the resonance region is indicated), [Hz]                                                                             |
| *equipmentDataPoint*    | Data collection point (from equipmentProfile.xml)                                                                                                                                              |

&nbsp;

## <a name="common">2. common</a>

```
<common discription="Common includes the main parameters of computeFramework such as turning on/off some methods and features">
            
	<equipmentStateDetectionEnable value="1" weight="1" description="Enable equipment state detection"/>
	<debugModeEnable value="0" logFileEnable="true" description="Enable developer features"/>
	
	<printPlotsEnable value="1" visible="off" title="off" description="Enable saving jpg-images of found defects for modules with attribute //plotEnable='1'//  "/>
	<parpoolEnable value="0" weight="1" description="Enable parallel calculations"/>
	
	<commonFunctions initializationWeight="1" fillFileStructWeight="1" hardwareProfileParserWeight="1" description="Contain the weght of functions which always run"/>
	
	<frequencyTrackingEnable value="1" weight="3" description="Enable signal frequencies tracking and further signal resampling (for equipment with various shaft rotational speed)"/>
	<frequencyCorrectionEnable value="1" weight="3" description="Enable shaft frequency estimation for further kinematics correction"/>
	<shaftTrajectoryDetectionEnable value="0" weight="3" description="Enable shaft displacement trajectory analysis"/>
	
	<bearingsParametersRefinement value="1" weight="2" description="Enable bearings parameters refinement"/>
	<frequencyDomainClassifierEnable value="1" weight="5" description="Enable defect detection based on frequency-domain analysis "/>
	
	<timeDomainClassifierEnable value="0" weight="10" scalogramWeight="0" description="Enable time-frequency domain analysis, i.m. scalogram analysis, wavelet-based filtration, search for periodicities, frequency analysis"/>
	<timeFrequencyDomainClassifierEnable value="1" weight="5" scalogramWeight="0" description="Enable time-domain analysis, i.m. scalogram analysis, search for periodicities, pattern extraction and classification" />
	<spectralKurtosisEnable value="0" weight="1" description="CURRENTLY UNUSED! Enable spectral kurtosis analysis, i.m. narrow band filtration, calculation kurtosis of filtered signals and building kurtosis function of frequency" />

	<timeSynchronousAveragingEnable value="1" weight="3" description="Enable time synchronous averaging method for gearings"/>
	<metricsEnable value="1" weight="2" description="Enable metrics results print to status file"/>
	<spmEnable value="1" weight="1" description="Enable first shock-pulse method(SPM) calculations with dBc/dBm or LR/HR levels"/>
	<iso15242Enable value="1" weight="1" description="Enable calculations of mean vibration level in 3 ranges (L,M,H)"/>
	<iso10816Enable value="1" weight="1" description="Enable evaluation of rms vibration velocity according to ISO10816 standard"/>
	<iso7919Enable value="1" weight="1" description="Enable evaluation of peak2peak vibration displacement according to ISO7919 standards"/>
	<vdi3834Enable value="1" weight="1" description="Enable evaluation of vibration according to VDI3834 standard"/>
	<octaveSpectrumEnable value="1" weight="1" description="Enable calculations of 1{1/3,1/6}-octave spectrum for easy machine state control"/>
	<temperatureEnable value="1" weight="1" description="Enable temperature processing"/>
	
	<decisionMakerEnable value="1" weight="1" historyWeight="1" description="Enable decision maker based on several method. Frequency-,time- and time-frequency domains; iso 10816 and etc are used"/>
	<historyEnable value="0" weight="1" description="Enable training period, thresholds autocalculations, trend analysis based on analysis of status files for a certain period of time  "/>            
	
</common>
```
Picture 2.1. - Writing format in config.xml of settings **\<common/>**

&nbsp;

Table 2.1. - **\<common/>** structure

| Name of the field                           | Description                                                                                                                                                                                  |
|---------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **\<equipmentStateDetectionEnable/>**       | On/off detection of equipment status (ON/OFF/IDLE). Requires to enable history processing.                                                                                                   |
| **\<debugModeEnable/>**                     | On/off the developer mode.                                                                                                                                                                   |
| **\<printPlotsEnable/>**                    | Enable/disable saving images in .jpg format. Image settings plots. Only method images with the attribute plotEnable="1" are saved.                                                           |
| **\<parpoolEnable/>**                       | Enable/disable parallel computing. Parallel computing increases performance, but requires more computer resources.                                                                           |
| **\<commonFunctions/>**                     | Always ON. Starts algorithms for initialization, pre-processing of the vibration signal, parsing of the kinematic scheme.                                                                    |
| **\<frequencyTrackingEnable/>**             | On/off methods for the frequency tracking and the signal oversampling.                                                                                                                       |
| **\<frequencyCorrectionEnable/>**           | On/off set of methods for specifying the shaft speed to correct the kinematic scheme.                                                                                                        |
| **\<frequencyDomainClassifierEnable/>**     | On/off classifier in the frequency domain. Requires a kinematic scheme.                                                                                                                      |
| **\<timeDomainClassifierEnable/>**          | On/off classifier in the time domain, which analyzes a scalogram, searches for periodicities, allocates and classifies shock process templates to determine the defective item of equipment. |
| **\<timeFrequencyDomainClassifierEnable/>** | On/off classifier in the time-frequency domain, which analyzes a scalogram, searches for periodicities and produces frequency domain processing after the optimal filtering.                 |
| **\<metricsEnable/>**                       | On/off calculation of basic metric values for vibration acceleration, vibration speed and vibration displacement.                                                                            |
| **\<spmEnable/>**                           | On/off processing by shock pulse monitoring.                                                                                                                                                 |
| **\<iso15242Enable/>**                      | On/off processing by iso15242.                                                                                                                                                               |
| **\<iso10816Enable/>**                      | On/off processing by iso10816.                                                                                                                                                               |
| **\<vdi3834Enable/>**                       | On/off processing by vdi3834.                                                                                                                                                                |
| **\<octaveSpectrumEnable/>**                | On/off calculation of octave spectrum.                                                                                                                                                       |
| **\<temperatureEnable/>**                   | On/off temperature analysis.                                                                                                                                                                 |
| **\<decisionMakerEnable/>**                 | Enable/disable decision-making on defects and the extent of their development by a set of methods.                                                                                           |
| **\<historyEnable/>**                       | Enable/disable data processing for a certain period (history processing). Used to determine the state of equipment, training, adaptive thresholding, etc.                                    |

&nbsp;

## <a name="printPlotsEnable">2.1. printPlotsEnable</a>

developers: Riabtsev P., Rachkovsky T.

**printPlotsEnable** - saving images.

```
<printPlotsEnable value="1" visible="off" title="off" description="Enable saving jpg-images of found defects for modules with attribute //plotEnable='1'//  "/>
```
Picture 2.1.1. - Writing format in config.xml of settings **\<printPlotsEnable/>**

&nbsp;

Table 2.1.1. - **\<printPlotsEnable/>** structure

| Name of the field | Description                                                          |
|-------------------|----------------------------------------------------------------------|
| *value*           | Enable/disable saving images in .jpg format.                         |
| *visible*         | On/off drawing of images on the user's desktop.                      |
| *title*           | On/off showing of the title for all images stored in the Out folder. |
| *description*     | Structure description.                                               |

&nbsp;

## <a name="evaluation">3. evaluation</a>

The **\<evaluation/>** section contains information on the detailed configuration of the methods used.

&nbsp;

## <a name="debugMode">3.1. debugMode</a>

developers: Aslamov Yu., Kechik D.

**debugMode** - developer mode.

```
<debugMode signalGenerationEnable="0" shortSignalEnable="1" plotWeakDamages="0" printAxonometryEnable="0" configMode="merge" informativeTagsMode="merge" description="Developer tools (i.m. siganl generation, signal cutting and etc). Attributes informativeTagsMode and configMode have value standard / input / merge">
	<signalGenerator mode="CH1" lengthSeconds="60" description=" 2 channels mode -> 'CH1+CH2'; 1 channel mode -> 'CH1'  ">
		<CH1 signalType="SIN" f01="10" F01="0" A01="1" SNR="20" D="0.1" f02="1000" A02="0.7" phasef01Dg="0" coefficients="0 2 2 1"/>
		<CH2 signalType="POLYH" f01="10" F01="1" A01="1" SNR="15" D="0.1" f02="1000" A02="0.7" phasef01Dg="90" coefficients="0 2 2 1"/>
	</signalGenerator>
	<shortSignal startSecond="0" lengthSeconds="120"/>
	<printAxonometry modeSaveData="0" range="5 5000"/>
</debugMode>
```
Picture 3.1.1. - Writing format in config.xml of settings **\<debugMode/>**

&nbsp;

Table 3.1.1. - **\<debugMode/>** structure

| Name of the field       | Description                                                                                                                                                                                                                                                                           |
|-------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **\<signalGenerator/>** | The test signals generator (one- and two-channel).                                                                                                                                                                                                                                    |
| **\<shortSignal/>**     | Cropping the original signal to speed up the entire framework.                                                                                                                                                                                                                        |
| **\<printAxonometry/>** | Saving and rendering of signals spectra in history.                                                                                                                                                                                                                                   |
| *signalGeneratorEnable* | On/off the test signals generator (one- and two-channel).                                                                                                                                                                                                                             |
| *shortSignalEnable*     | On/off cropping of the input signal length to the specified in the settings.                                                                                                                                                                                                          |
| *printAxonometryEnable* | On/off saving and rendering of signals spectra in history.                                                                                                                                                                                                                            |
| *configMode*            | Mode for selecting config.xml (*standard/input/merge*). "*standard*" - use only the config in the "In" folder, "*input*" - use only the config builted-in the framework, "*merge*" - use the config in the "In" folder, but add the missing fields.                                   |
| *informativeTagsMode*   | Mode for selecting informativeTags.xml (standard/input/merge). "*standard*" - use only the informativeTags in the "In" folder, "*input*" - use only the informativeTags builted-in the framework, "*merge*" - use the informativeTags in the "In" folder, but add the missing fields. |

&nbsp;

Table 3.1.2. - **\<signalGenerator/>** structure

| Name of the field                      | Description                                                                                                                        |
|----------------------------------------|------------------------------------------------------------------------------------------------------------------------------------|
| *mode*                                 | Selecting the generator operating mode: "*CH1*" - use 1st channel, "*CH2*" -  use 2nd channel, "*CH1+CH2*" - use two-channel mode. |
| &nbsp;&nbsp;**\<CH1 (2)/>**            | Signal parameters generated in the 1st (2nd) channel.                                                                              |
| &nbsp;&nbsp;&nbsp;&nbsp;*signalType*   | Generated signal type (*SIN/COS/TRIPULSE/GAUSPULSE/TRIPULSE+COS/GAUSPULSE+COS*).                                                   |
| &nbsp;&nbsp;&nbsp;&nbsp;*f01*          | Carrier frequency [Hz] of the main signal.                                                                                         |
| &nbsp;&nbsp;&nbsp;&nbsp;*F01*          | Modulating frequency [Hz] of the main signal (for pulse signals).                                                                  |
| &nbsp;&nbsp;&nbsp;&nbsp;*A01*          | Amplitude [m/s2] of the main signal.                                                                                               |
| &nbsp;&nbsp;&nbsp;&nbsp;*SNR*          | Signal to noise ratio [dB].                                                                                                        |
| &nbsp;&nbsp;&nbsp;&nbsp;*D*            | Duty ratio (for pulse signals).                                                                                                    |
| &nbsp;&nbsp;&nbsp;&nbsp;*f02*          | Carrier frequency [Hz] of the additional part (for composed signals *TRIPULSE+COS*, *GAUSPULSE+COS*).                              |
| &nbsp;&nbsp;&nbsp;&nbsp;*A02*          | Amplitude [m/s2] of the additional part (for composed signals).                                                                    |
| &nbsp;&nbsp;&nbsp;&nbsp;*coefficients* | Polynomial coefficients for generating a polyharmonic signal from the carrier wave with frequency *f01*.                           |
| &nbsp;&nbsp;&nbsp;&nbsp;*phasef01Dg*   | Phase shift of the carrier wave.                                                                                                   |

&nbsp;

Table 3.1.3. - **\<shortSignal/>** structure

| Name of the field | Description                                                                 |
|-------------------|-----------------------------------------------------------------------------|
| *startSecond*     | The second number with which the signal will be processed.                  |
| *lengthSeconds*   | The number of seconds processed in the signal, starting with *startSecond*. |

&nbsp;

Table 3.1.4. - **\<printAxonometry/>** structure

| Name of the field | Description                                                                                                   |
|-------------------|---------------------------------------------------------------------------------------------------------------|
| *modeSaveData*    | At a value of 0 - the signal spectra are saved, at a value of 1 - the signal spectra are saved and displayed. |
| *range*           | Range of stored spectra frequencies. [Hz]                                                                     |

In **debugMode** mode, the machine locally runs server.exe to simulate the data transfer.
