# Specification. 
## Config.xml file format

### Content

- [1. sensors](#sensors)
- [2. common](#common)
	- [2.1. printPlotsEnable](#printPlotsEnable)
- [3. evaluation](#evaluation)
	- [debugMode](#debugMode)
	- [loger](#loger)
	- [plots](#plots)
	- [spectra](#spectra)
	- [metrics](#metrics)
	- [equipmentStateDetection](#equipmentStateDetection)
	- [frequencyCorrector](#frequencyCorrector)
	- [shaftTrajectoryDetection](#shaftTrajectoryDetection)
	- [iso7919](#iso7919)
	- [frequencyDomainClassifier](#frequencyDomainClassifier)
	- [scalogramHadler](#scalogramHadler)
	- [periodicityProcessing](#periodicityProcessing)
	- [timeDomainClassifier](#timeDomainClassifier)
	- [timeFrequencyDomainClassifier](#timeFrequencyDomainClassifier)
	- [spm](#spm)
	- [iso15242](#iso15242)
	- [octaveSpetrum](#octaveSpetrum)
	- [decisionMaker](#decisionMaker)
	- [history](#history)
	- [statusWriter](#statusWriter)
	- [frequencyTracking](#frequencyTracking)
	- [timeSynchronousAveraging](#timeSynchronousAveraging)
	- [checkSignalSymmetry](#checkSignalSymmetry)
	- [bearingsParametersRefinement](#bearingsParametersRefinement)
	- [octaveSpectrum](#octaveSpectrum)
	
>config.xml is a configuration file for the computeFremework. The specification contains a brief information about the config.xml structure and parameters for customizing individual methods.

Table 1. - A brief config.xml structure

| Name of the field  | Description                                                                                                       |
|--------------------|-------------------------------------------------------------------------------------------------------------------|
| **\<common/>**     | intended for basic setting of the framework: switching on/off toolbars/methods, operating modes, etc.             |
| **\<evaluation/>** | intended for detailed configuration of the framework, contains parameters of each method involved in processing.  |

&nbsp;

## <a name="sensors">1. sensors</a>

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

Table 2.1. - ***\<common>*** structure

| Name of the field                         | Description                                                                                                                                                                                  |
|-------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ***equipmentStateDetectionEnable***       | On/off detection of equipment status (ON/OFF/IDLE). Requires to enable history processing.                                                                                                   |
| ***debugModeEnable***                     | On/off the developer mode.                                                                                                                                                                   |
| ***printPlotsEnable***                    | Enable/disable saving images in .jpg format. Image settings plots. Only method images with the attribute plotEnable="1" are saved.                                                           |
| ***parpoolEnable***                       | Enable/disable parallel computing. Parallel computing increases performance, but requires more computer resources.                                                                           |
| ***commonFunctions***                     | Always ON. Starts algorithms for initialization, pre-processing of the vibration signal, parsing of the kinematic scheme.                                                                    |
| ***frequencyTrackingEnable***             | On/off methods for the frequency tracking and the signal oversampling.                                                                                                                       |
| ***frequencyCorrectionEnable***           | On/off set of methods for specifying the shaft speed to correct the kinematic scheme.                                                                                                        |
| ***frequencyDomainClassifierEnable***     | On/off classifier in the frequency domain. Requires a kinematic scheme.                                                                                                                      |
| ***timeDomainClassifierEnable***          | On/off classifier in the time domain, which analyzes a scalogram, searches for periodicities, allocates and classifies shock process templates to determine the defective item of equipment. |
| ***timeFrequencyDomainClassifierEnable*** | On/off classifier in the time-frequency domain, which analyzes a scalogram, searches for periodicities and produces frequency domain processing after the optimal filtering.                 |
| ***metricsEnable***                       | On/off calculation of basic metric values for vibration acceleration, vibration speed and vibration displacement.                                                                            |
| ***spmEnable***                           | On/off processing by shock pulse monitoring.                                                                                                                                                 |
| ***iso15242Enable***                      | On/off processing by iso15242.                                                                                                                                                               |
| ***iso10816Enable***                      | On/off processing by iso10816.                                                                                                                                                               |
| ***vdi3834Enable***                       | On/off processing by vdi3834.                                                                                                                                                                |
| ***octaveSpectrumEnable***                | On/off calculation of octave spectrum.                                                                                                                                                       |
| ***temperatureEnable***                   | On/off temperature analysis.                                                                                                                                                                 |
| ***decisionMakerEnable***                 | Enable/disable decision-making on defects and the extent of their development by a set of methods.                                                                                           |
| ***historyEnable***                       | Enable/disable data processing for a certain period (history processing). Used to determine the state of equipment, training, adaptive thresholding, etc.                                    |

&nbsp;

## <a name="printPlotsEnable">2.1. printPlotsEnable</a>

developers: Riabtsev P., Rachkovsky T.

**printPlotsEnable** - saving images.

```
<printPlotsEnable value="1" visible="off" title="off" description="Enable saving jpg-images of found defects for modules with attribute //plotEnable='1'//  "/>
```

![123](src/123.jpg)

