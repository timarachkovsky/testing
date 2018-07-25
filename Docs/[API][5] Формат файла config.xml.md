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

developers: *Riabtsev P., Rachkovsky T.*

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

developers: *Aslamov Yu., Kechik D.*

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

| Name of the field                   | Description                                                                                                                                                                                                                                                                           |
|-------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| *signalGeneratorEnable*             | On/off the test signals generator (one- and two-channel).                                                                                                                                                                                                                             |
| *shortSignalEnable*                 | On/off cropping of the input signal length to the specified in the settings.                                                                                                                                                                                                          |
| *printAxonometryEnable*             | On/off saving and rendering of signals spectra in history.                                                                                                                                                                                                                            |
| *configMode*                        | Mode for selecting config.xml (*standard/input/merge*). "*standard*" - use only the config in the "In" folder, "*input*" - use only the config builted-in the framework, "*merge*" - use the config in the "In" folder, but add the missing fields.                                   |
| *informativeTagsMode*               | Mode for selecting informativeTags.xml (standard/input/merge). "*standard*" - use only the informativeTags in the "In" folder, "*input*" - use only the informativeTags builted-in the framework, "*merge*" - use the informativeTags in the "In" folder, but add the missing fields. |
| &nbsp;&nbsp;**\<signalGenerator/>** | The test signals generator (one- and two-channel).                                                                                                                                                                                                                                    |
| &nbsp;&nbsp;**\<shortSignal/>**     | Cropping the original signal to speed up the entire framework.                                                                                                                                                                                                                        |
| &nbsp;&nbsp;**\<printAxonometry/>** | Saving and rendering of signals spectra in history.                                                                                                                                                                                                                                   |

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

&nbsp;

## <a name="loger">3.2. loger</a>

developers: *Riabtsev P., Aslamov Yu.*

**loger** - class for storing service information in a text file and console or transferring via a tcpip connection.

```
<loger tcpipSocketEnable="1" logEnable="1" consoleEnable="1" localhost="localhost" localport="8888" outputBufferSize="4096" attempts="2" timeout="5" description=""/>           
```
Picture 3.2.1. - Writing format in config.xml of settings **\<loger/>**

&nbsp;

Table 3.2.1. - **\<loger/>** structure

| Name of the field   | Description |
|---------------------|-------------|
| *tcpipsocketEnable* | Enable/disable the information transfer about the calculations via the tcpip socket on the Web Part. |
| *logEnable*         | Enable/disable saving the calculation information to a text file (log.txt). |
| *consoleEnable*     | Enable/disable the information recording about calculations in the console. |
| *localhost*         | The name of the local host. |
| *localport*         | The name of the tcpip port. |
| *outputBufferSize*  | The amount of information storage buffer on the receiver side (in bytes). |
| *attempts*          | The number of attempts to connect to the tcpip socket. For all failed attempts to connect, the information transfer through the tcpip socket is disabled. |
| *timeout*           | The time between attempts to connect to the tcpip socket (in seconds). |

&nbsp;

## <a name="plots">3.3. plots</a>

developers: *Riabtsev P.*

**plots** - image settings.

```
<plots language="en" sizeUnits="pixels" imageSize="0, 0, 800, 600" fontSize="12" imageFormat="jpeg" imageQuality="91" imageResolution="0" description="Original size: sizeUnits='pixels', imageSize='0, 0, width, height', imageResolution='0'. Datatips font size is less than the main font in half"/>
```
Picture 3.3.1. - Writing format in config.xml of settings **\<plots/>**

&nbsp;

Table 3.3.1. - **\<plots/>** structure

| Name of the field | Description |
|-------------------|-------------|
| *language*        | Язык текста в изображениях. (`en`, `de`, `ru`) |
| *sizeUnits*       | Единицы измерения величин imageSize. (`points`, `pixels`) |
| *imageSize*       | Положение и размер изображения. Задано в виде вектора. `[left bottom width height]` |
| *fontSize*        | Размер шрифта. [точек] |
| *imageFormat*     | Формат сохраняемого изображения. (`jpeg`) |
| *imageQuality*    | Степень сжатия сохраняемого изображения [%]. (для формата jpeg) |
| *imageResolution* | Разрешение сохраняемого изображения. [DPI] |

&nbsp;

## <a name="spectra">3.4. spectra</a>

developers: *Aslamov Yu., Kosmach N., Riabtsev P.*

**spectra** - a set of algorithms for constructing spectra of vibrating signals and extracting informative features.

```
<spectra accelerationRange="0:3000" accelerationEnvelopeRange="500:3000" velocityRange="0:1000" displacementRange="0:500" interpolationEnable="0" decimationEnable="1" description="">
	<interpolation type="spline" criterion="df" factor="10" df="0.1" desctiption="criteria ='factor'/'df' (frequency resolution)"/>
	<envSpectrum plotEnable="1" filterType="BPF" Rp="1" Rs="10" averagingEnable="1" secPerFrame="60"/>
	<logSpectrum plotEnable="0" frameLength="20" stepLength="10" rmsFactor="2" cutoffLevel="0" minPeakDistance="0.2" minDeviationFrequency="0.2" maxDeviationFrequency="10" enableEnergyPeakFinder="1" pointsNumberFactor="2" amplitudeFactor="0.15" minLogLevel="9" minPeaksNumber="2" minPeaksNumberEnergy="5" df="0.05" percentOfPeaksOnPeak="30" saveEnergyPeak="1" description="min deviation frequency is  minDeviationFactor * df, need for creating levels number"/>
</spectra>
```
Picture 3.4.1. - Writing format in config.xml of settings **\<spectra/>**

&nbsp;

Table 3.4.1. - **\<spectra/>** structure

| Name of the field                 | Description |
|-----------------------------------|-------------|
| *accelerationRange*               | Диапазон частот спектра виброускорения в формате “lowFrequency:highFrequency”. [Гц] |
| *velocityRange*                   | Диапазон частот спектра вибрскорости в формате “lowFrequency:highFrequency”. [Гц] |
| *displacementRange*               | Диапазон частот спектра виброперемещения в формате “lowFrequency:highFrequency”. [Гц] |
| *interpolationEnable*             | Разрешить интерполяцию спектров сигнала. |
| &nbsp;&nbsp;**\<envSpectrum/>**   | Настройки для построения спектра огибающей виброускорения. |
| &nbsp;&nbsp;**\<logSpectrum/>**   | Настройки для расчета логарифмических спектров и выделения информативных признаков. |
| &nbsp;&nbsp;**\<interpolation/>** | Настройки алгоритма интерполяции спектров. |

&nbsp;

Table 3.4.2. - **\<envSpectrum/>** structure

| Name of the field | Description |
|-------------------|-------------|
| *plotEnable*      | Разрешить отрисовку изображений. |
| *filterType*      | Тип фильтра. (`LPF`, `BPF`, `HPF`) |
| *lowFreq*         | Нижняя частота фильтрации. [Гц] |
| *highFreq*        | Верхняя частота фильтрации. [Гц] |
| *Rp*              | Допустимый уровень пульсаций в полосе пропускания. [дБ] |
| *Rs*              | Требуемый уровень ослабления в полосе подавления. [дБ] |
| *averagingEnable* | Разрешить разбиение сигнала на фрагменты равной длины и построение усредненного спектра. |
| *secPerFrame*     | Длина фрагмента сигнала для построения спектра (при *averagingEnable*="`1`"). [сек.] |

&nbsp;

Table 3.4.3. - **\<logSpectrum/>** structure

| Name of the field        | Description |
|--------------------------|-------------|
| *plotEnable*             | Разрешить отрисовку изображений. |
| *frameLength*            | Длина кадров, на которые разбивается логарифмический спектр для расчета уровня rms (при вычисления адаптивного уровня шума). |
| *stepLength*             | Шаг кадров при вычислении адаптивного уровня шума. |
| *rmsFactor*              | Коэффициент, на который умножаются rms в каждом спектральном кадре, чтобы получить грубый уровень шума. |
| *cutoffLevel*            | Величина [дБ], которая прибавляется к грубому уровню шума, чтобы выделять информативные признаки (пики). |
| *minPeakDistance*        | Минимальная дистанция между пиками, при которой они считаются разными пиками [Гц]. |
| *enableEnergyPeakFinder* | Разрешить нахождение энергетических пиков. |
| *minDeviationFactor*     | Минимальное значение окна усреднения для поиска энергетических пиков (*minDeviationFactor × df*) |
| *maxDeviationFrequency*  | Максимальное значение усреднения для поиска энергетических пиков (Гц). |
| *pointsNumberFactor*     | Необходимо для выбора количества усредняемых значений между *minDeviationFactor × df* и  *maxDeviationFrequency*. |
| *amplitudeFactor*        | Коэффициент выше которого считается количество пиков на пике (*amplitudeFactor × (max(вектор всех амплитуд пиков на энергетическом пике))*). |
| *minLogLevel*            | Минимальный уровень в дБ для обнаружения энергетических пиков. |
| *minPeaksNumber*         | Минимальное количество пиков на пике для отнесения их к одному значению расплывчатой частоты. |
| *minPeaksNumberEnergy*   | Минимальное количество пиков на энергетическом пике для отнесения их к одному значению расплывчатой энергонесущей частоты. |

&nbsp;

Table 3.4.4. - **\<interpolation/>** structure

| Name of the field | Description |
|-------------------|-------------|
| *type*            | Тип интерполяции. (`spline`, `pchirp` и др.) |
| *criterion*       | Выбор критерия интерполяции: `factor` (коэффициент интерполяции) или `df` (требуемое разрешение по частоте). |
| *factor*          | Коэффициент интерполяции. (`factor`>1) |
| *df*              | Требуемое разрешение по частоте. [Гц] |

&nbsp;

## <a name="metrics">3.5. metrics</a>

developers: *Riabtsev P.*

**metrics** - a set of algorithms for calculating vibration metrics.

```
<metrics firstSampleTime="0.5" secPerFrame="0.1" secOverlapValue="0.01" description="Returns the main parameters of acceleration, velocity and displacement">
	<acceleration description="Calculate rms value of acceleration in the specific frequency range">
		<rms enable="1" frequencyRange="4:Fs" thresholds=""/>
		<peak enable="0" thresholds=""/>
		<peak2peak enable="0" thresholds=""/>
		<peakFactor enable="1" thresholds=""/>
		<crestFactor enable="1" thresholds=""/>
		<kurtosis enable="0" thresholds=""/>
		<excess enable="1" thresholds=""/>
		<noiseLog enable="1" thresholds=""/>
		<envelopeNoiseLog enable="1" thresholds=""/>
		<noiseLinear enable="1" thresholds=""/>
		<envelopeNoiseLinear enable="1" thresholds=""/>
		<unidentifiedPeaksNumbers enable="1" thresholds=""/>
		<unidentifiedPeaksNumbersEnvelope enable="1" thresholds=""/>
	</acceleration>
	<velocity description="Calculate rms value of velocity in the specific frequency range">
		<rms enable="1" frequencyRange="10:1000" thresholds=""/>
		<peak enable="1" thresholds=""/>
		<peak2peak enable="1" thresholds=""/>
		<peakFactor enable="1" thresholds=""/>
		<crestFactor enable="0" thresholds=""/>
		<kurtosis enable="0" thresholds=""/>
		<excess enable="0" thresholds=""/>
		<noiseLog enable="0" thresholds=""/>
		<noiseLinear enable="0" thresholds=""/>
		<unidentifiedPeaksNumbers enable="1" thresholds=""/>
	</velocity>
	<displacement description="Calculate rms value of displacement in the specific frequency range">
		<rms enable="1" frequencyRange="1:200" thresholds=""/>
		<peak enable="1" thresholds=""/>
		<peak2peak enable="1" thresholds=""/>
		<peakFactor enable="0" thresholds=""/>
		<crestFactor enable="0" thresholds=""/>
		<kurtosis enable="0" thresholds=""/>
		<excess enable="0" thresholds=""/>
		<noiseLog enable="0" thresholds=""/>
		<noiseLinear enable="0" thresholds=""/>
		<unidentifiedPeaksNumbers enable="1" thresholds=""/>
	</displacement>
</metrics>
```
Picture 3.5.1. - Writing format in config.xml of settings **\<metrics/>**

&nbsp;

Table 3.5.1. - **\<metrics/>** structure

| Name of the field                | Description |
|----------------------------------|-------------|
| *firstSampleNumber*              | Номер начального отсчета сигнала для вычисления метрик. Отсчеты сигнала до указанного обрезаются при вычислениях. |
| *secPerFrame*                    | Величина окна при расчете метрики КРЕСТ-ФАКТОР. [c] |
| *secOverlapValue*                | Величина наложения окон при расчете метрики КРЕСТ-ФАКТОР. [с] |
| &nbsp;&nbsp;**\<acceleration/>** | Параметры метрик сигнала виброускорения. |
| &nbsp;&nbsp;**\<velocity/>**     | Параметры метрик сигнала виброскорости. |
| &nbsp;&nbsp;**\<displacement/>** | Параметры метрик сигнала виброперемещения. |

&nbsp;

Table 3.5.2. - **\<acceleration/>**, **\<velocity/>**, **\<displacement/>** structures

| Name of the field            | Description |
|------------------------------|-------------|
| **\<rms/>**                  | Параметры метрики СКЗ. |
| &nbsp;&nbsp;*enable*         | Вкл/выкл заполнения метрики в status.xml. |
| &nbsp;&nbsp;*frequencyRange* | Диапазон частот, используемых для вычисления метрик СКЗ. |
| &nbsp;&nbsp;*thresholds*     | Ручная установка порогов метрики вибросигнала. |
| **\<peak/>**                 | Параметры метрики ПИК. |
| &nbsp;&nbsp;*enable*         | Вкл/выкл заполнения метрики в status.xml. |
| &nbsp;&nbsp;*thresholds*     | Ручная установка порогов метрики вибросигнала. |
| **\<peak2peak/>**            | Параметры метрики ПИК-ПИК. |
| **\<peakFactor/>**           | Параметры метрики ПИК-ФАКТОР. |
| **\<crestFactor/>**          | Параметры метрики КРЕСТ-ФАКТОР. |
| **\<kurtosis/>**             | Параметры метрики КУРТОЗ. |
| **\<excess/>**               | Параметры метрики ЭКСЦЕСС. |
| **\<noiseLog/>**             | Параметры логарифмического уровня шума. |
| **\<noiseLinear/>**          | Параметры абсолютного уровня шума. |

Теги **\<acceleration/>**, **\<velocity/>**, **\<displacement/>** имеют одинаковую структуру.  
Теги **\<peak2peak/>**, **\<peakFactor/>**, **\<crestFactor/>**, **\<kurtosis/>**, **\<excess/>**, **\<noiseLog/>**, **\<noiseLinear/>** имеют ту же структуру, что и тег <peak>.

&nbsp;

## <a name="equipmentStateDetection">3.6. equipmentStateDetection</a>

developers: *Riabtsev P.*

**equipmentStateDetection** - a set of algorithms for determining of the equipment operation mode.

```
<equipmentStateDetection plotEnable="1" decisionMakerStates="on/off" description="Method detects equipment state to turn on/off computeFramework">
	<metrics enable="1" description="">
		<trainingPeriod enable="1" stdFactor="2" trimmingEnable="0"/>
		<thresholds>
			<acceleration_rms value="0.5 1"/>
			<velocity_rms value="0.2 0.8"/>
		</thresholds>
	</metrics>
	<psd enable="1" filterOrder="32" evaluationPointsNumber="1024" correlationThreshold="0.75" description="Linear prediction of filter coefficients for calculation the power spectral density"/>
</equipmentStateDetection>
```
Picture 3.6.1. - Writing format in config.xml of settings **\<equipmentStateDetection/>**

&nbsp;

Table 3.6.1. - **\<equipmentStateDetection/>** structure

| Name of the field                                            | Description |
|--------------------------------------------------------------|-------------|
| *decisionMakerStates*                                        | Возможные решения о режиме работы оборудования. (`on/off`, `on/idle/off`). |
| &nbsp;&nbsp;**\<metrics/>**                                  | Содержит параметры для определения режима работы оборудования на основании метрик. |
| &nbsp;&nbsp;&nbsp;&nbsp;*enable*                             | Включение/отключение метода. |
| &nbsp;&nbsp;&nbsp;&nbsp;**\<trainingPeriod/>**               | Содержит параметры обучения для автоматического определения режима работы оборудования на основании метрик. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*enable*                 | Включение/отключение обучения. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*stdFactor*              | Коэффициент СКО данных для вычисления границ зон режима работы оборудования. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*trimmingEnable*         | Включение/выключение обрезки выбивающихся данных. |
| &nbsp;&nbsp;&nbsp;&nbsp;**\<thresholds/>**                   | Содержит поля метрик (например,  **\<acceleration_rms/>**) с указанными границами зон режимов работы оборудования. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**\<acceleration_rms/>** | Содержит границы зон режимов работы оборудования метрики. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*value*      | Граничные значения режимов работы оборудования. Одно значение соответствует границе зон режимов *ON/OFF*. Два значение соответствует границам зон режимов *ON/IDLE/OF*: максимальное значение для границы режимов *ON/IDLE*, минимальное значение для границы режимов *IDLE/OFF*. |
| &nbsp;&nbsp;**\<psd/>**                                      | Содержит параметры для определения режима работы оборудования на основании спектральной плотности мощности. |
| &nbsp;&nbsp;&nbsp;&nbsp;*enable*                             | Включение/отключение метода. |
| &nbsp;&nbsp;&nbsp;&nbsp;*filterOrder*                        | Порядок фильтра линейного предсказания. |
| &nbsp;&nbsp;&nbsp;&nbsp;*evaluationPointsNumber*             | Количество оцениваемых точек спектральной плотности мощности. |
| &nbsp;&nbsp;&nbsp;&nbsp;*correlationThreshold*               | Порог корреляции спектральной плотности мощности для одинаковых режимов работы оборудования. |

&nbsp;

## <a name="frequencyCorrector">3.7. frequencyCorrector</a>

developers: *Kechik D., Aslamov Yu.*

**frequencyCorrector** - class, combining a set of methods for specifying the shaft rotational speed.

```
<frequencyCorrector plotEnable="1" methodsEnbl="all" trustedInterval="0.7" goodThreshold="80" averageThreshold="35" conflictCloseness="0.2" crossValidationThresholds="40 70" shortWindow="1" plotAllShafts="1" description="Decision maker rules configs. Process using interference methods (methodsEnbl='interference'), interference and fuzzy (methodsEnbl='all'), all methods (methodsEnbl='all+hilbert'). The next fields are default config for all estimators." interpolationFactor="8" percentRange="1" percentStep="0.01" dfPercentAccuracy="0.01" nPeaks="5" minPeakHeight="6"  minPeakDistance="3" SortStr="descend" maxPeaksInResult="4" minOverMaximumThreshold="0.66" baseVal="0" minProbability = "33" minMagnitude="0.01">
	<displacementInterferenceEstimator plotEnable="0" validFrames = "1" fullSavingEnable="0">
		<rough processingEnable="1" plotEnable="0" percentRange="" percentStep="" dfPercentAccuracy="" nPeaks=""  minPeakDistance="" mainFramesNumber="2" additionalFramesNumber="4" SortStr="" maxPeaksInResult="" minOverMaximumThreshold="" baseVal=""/>
		<accurate processingEnable="0" plotEnable="0" percentRange="" percentStep="" dfPercentAccuracy="" nPeaks=""  minPeakDistance="" mainFramesNumber="2" additionalFramesNumber="3" SortStr="" maxPeaksInResult="" minOverMaximumThreshold="" baseVal=""/>
		<validationFrames plotEnable="0" minPeakHeight="" SortStr="" maxPeaksInResult="" minOverMaximumThreshold="" baseVal="" minProbability = "" minMagnitude=""/>
	</displacementInterferenceEstimator>
	<spectralBeamEstimator plotEnable="0" validFrames = "1" fullSavingEnable="0">
		<rough processingEnable="1" plotEnable="0" percentRange="" percentStep="" dfPercentAccuracy="" nPeaks=""  minPeakDistance="" mainFramesNumber="2" additionalFramesNumber="4" SortStr="" maxPeaksInResult="" minOverMaximumThreshold="" baseVal=""/>
		<accurate processingEnable="0" plotEnable="0" percentRange="" percentStep="" dfPercentAccuracy="" nPeaks=""  minPeakDistance="" mainFramesNumber="2" additionalFramesNumber="3" SortStr="" maxPeaksInResult="" minOverMaximumThreshold="" baseVal=""/>
		<validationFrames plotEnable="0" minPeakHeight="" SortStr="" maxPeaksInResult="" minOverMaximumThreshold="" baseVal="" minProbability = "" minMagnitude="" logRange="6 9 14"/>
	</spectralBeamEstimator>
	<interferenceFrequencyEstimator plotEnable="0" validFrames = "1" fullSavingEnable="0">
		<rough processingEnable="1" plotEnable="0" percentRange="" percentStep="" dfPercentAccuracy="" nPeaks=""  minPeakDistance="" mainFramesNumber="2" additionalFramesNumber="4" SortStr="" maxPeaksInResult="" minOverMaximumThreshold="" baseVal=""/>
		<accurate processingEnable="0" plotEnable="0" percentRange="" percentStep="" dfPercentAccuracy="" nPeaks=""  minPeakDistance="" mainFramesNumber="2" additionalFramesNumber="3" SortStr="" maxPeaksInResult="" minOverMaximumThreshold="" baseVal=""/>
		<validationFrames plotEnable="0" minPeakHeight="" SortStr="" maxPeaksInResult="" minOverMaximumThreshold="" baseVal="" minProbability = "" minMagnitude=""/>
	</interferenceFrequencyEstimator>
	<fuzzyFrequencyEstimator plotEnable="0" lowLevel="0" averageLevel="1" highLevel="2" lowNum="50" averageNum="20" highNum="10" minPeaksDistance="0" minPeakProminence="2.0" maxPeakFrequency="1000" wieghtDefFrames="1" fullSavingEnable="0">
		<rough processingEnable="1" plotEnable="0" peakComparisonPercentRange="0.3" peakComparisonFreqRange="0" peakComparisonModeFunction="0"  percentRange="3" percentStep="" dfPercentAccuracy="" nPeaks="" minRMSPeakHeight="1"  minPeakDistance="" SortStr="" maxPeaksInResult="" minOverMaximumThreshold="" baseVal=""/>
		<accurate processingEnable="0" plotEnable="0" peakComparisonPercentRange="0.2" peakComparisonFreqRange="0" peakComparisonModeFunction="0" percentRange="0.3" percentStep="0.02" dfPercentAccuracy="" nPeaks="" minRMSPeakHeight="1"  minPeakDistance="" SortStr="" maxPeaksInResult="" minOverMaximumThreshold="" baseVal=""/>
		<validationFrames plotEnable="0" minPeakHeight="" SortStr="" maxPeaksInResult="" minOverMaximumThreshold="" baseVal="" minProbability = "" minMagnitude=""/>
	</fuzzyFrequencyEstimator>
	<hilbertFrequencyEstimator plotEnable="0" validFrames="1"  centralFrequency="" fullSavingEnable="0">
		<rough processingEnable="1" plotEnable="0" framesNumber="5" waveletName="" maxPercentDeviation="3" stdThreshold="2" interfMeth="mult" percentRange="" rngsNum="5" percentStep="" dfPercentAccuracy="" nPeaks=""  minPeakDistance="" mainFramesNumber="2" additionalFramesNumber="4" SortStr="" maxPeaksInResult="" minOverMaximumThreshold="" baseVal=""/>
		<accurate processingEnable="0" plotEnable="0" framesNumber="5" waveletName="" maxPercentDeviation="3" stdThreshold="2" interfMeth="mult" percentRange="3" rngsNum="5" percentStep="" dfPercentAccuracy="" nPeaks=""  minPeakDistance="" mainFramesNumber="2" additionalFramesNumber="3" SortStr="" maxPeaksInResult="" minOverMaximumThreshold="" baseVal=""/>
		<validationFrames plotEnable="0" minPeakHeight="" SortStr="" maxPeaksInResult="" minOverMaximumThreshold="" baseVal="" minProbability = "" minMagnitude=""/>
	</hilbertFrequencyEstimator>
</frequencyCorrector>
```
Picture 3.7.1. - Writing format in config.xml of settings **\<frequencyCorrector/>**

&nbsp;

Table 3.7.1. - **\<frequencyCorrector/>** structure

| Name of the field   | Description |
|---------------------|-------------|
|                     |  |
|                     |  |
|                     |  |
|                     |  |
|                     |  |
|                     |  |
|                     |  |
|                     |  |

&nbsp;

## <a name="shaftTrajectoryDetection">3.8. shaftTrajectoryDetection</a>

developers: *Kechik D.*

**shaftTrajectoryDetection** - class, designed to extract from a two-channel signal the shafts vibration in two planes, the construction, averaging and analysis of their trajectory.

```
<shaftTrajectoryDetection windowLenMin="5maxPer" windows="1:48000;48001:96000;96001:144000" filtMeth="fft" fullSavingEnable="0"/>
```
Picture 3.8.1. - Writing format in config.xml of settings **\<shaftTrajectoryDetection/>**

&nbsp;

Table 3.8.1. - **\<shaftTrajectoryDetection/>** structure

| Name of the field  | Description |
|--------------------|-------------|
| *windowLenMin*     | Минимальная длина выделенного окна со стабильной фазой. |
| *windows*          | Временные окна для вывода части траектории, в отсчетах. |
| *filtMeth*         | Метод выделения узкополосных составляющих: при помощи прямого и обратного БПФ (`fft`) или цифровой фильтрации с предварительной децимацией (`decim`). |
| *fullSavingEnable* | Разрешает сохранение всех изображений при включенном debugMode. |

&nbsp;

## <a name="iso7919">3.9. iso7919</a>

**iso7919** - algorithm for estimating the metrics values in accordance with ISO 7919.

```
<iso7919 standardPart="" standardPartDeterminationEnable="1"/>
```
Picture 3.9.1. - Writing format in config.xml of settings **\<iso7919/>**

&nbsp;

Table 3.9.1. - **\<iso7919/>** structure

| Name of the field                 | Description |
|-----------------------------------|-------------|
| *standardPart*                    | Номер части стандарта ISO 7919. (`2`, `3`, `4`, `5`) |
| *standardPartDeterminationEnable* |  |

&nbsp;

## <a name="frequencyDomainClassifier">3.10. frequencyDomainClassifier</a>

developers: *Aslamov Yu., Kosmach N., Riabtsev P.*

**frequencyDomainClassifier** - classifier in the frequency domain.

```
<frequencyDomainClassifier plotEnable="1" gearingClassifierMode="1" gearingAveragingMode="peakTableRange" enoughtPlotWekness="1" description="gearingClassifierMode(true/flase) - determine gearings with special parameters, gearingAveragingMode = allRange/peakTableRange; enoughtPlotWekness - %" >
	<peakComparison includeEnergyPeaks="0" modeFunction="1" coefficientModeFunction="0.09" percentRange="0" freqRange="0" description="for function modeFunction=1"/>
	<schemeValidator validLogLevel="1.5" enableFindLineFreq="1" freqRangeTwiceLineFreq="0.02; 0.1; 0.2" harmomicsTwiceLineFreq="0.5; 1:0.5:3.5; 4:0.5:5" description="log level into validator = validLogLevel + cutoffLevel(function logSpectrum)"/>
</frequencyDomainClassifier>
```
Picture 3.10.1. - Writing format in config.xml of settings **\<frequencyDomainClassifier/>**

&nbsp;

Table 3.10.1. - **\<frequencyDomainClassifier/>** structure

| Name of the field                                 | Description |
|---------------------------------------------------|-------------|
| *plotEnable*                                      | Включение/отключение отрисовки найденных дефектов в спектрах. |
| *gearingClassifierMode*                           | Включить режим анализа главных гармоник зацепления. (Усредние амплитуды и расширение диапазона поиска) |
| *gearingAveragingMode*                            | Выбрать режим усреднения (`peakTableRange` - режим усреднение всех пиков попадающий под один в таблице пиков. `allRange` - усреднение пика в окне (окно выбирается как процент от главного пика и усредняется вся область в спектре)). |
| *enoughtPlotWekness*                              |  |
| &nbsp;&nbsp;**\<peakComparison/>**                | Выбор диапазона поиска пиков в частотной области. |
| &nbsp;&nbsp;&nbsp;&nbsp;*includeEnergyPeaks*      | Включать в анализ и энергетические пики. |
| &nbsp;&nbsp;&nbsp;&nbsp;*modeFunction*            | Включить режим в котором выбор диапазона определяется по формуле: (0.03√(x/a))/x, где x - частота искомого пика, a - коэффициент крутизны, задаваемый  *coefficientModeFunction*. |
| &nbsp;&nbsp;&nbsp;&nbsp;*coefficientModeFunction* | Коэффициент крутизны. |
| &nbsp;&nbsp;&nbsp;&nbsp;*percentRange*            | При отключенном *modeFunction* и *freqRang*. Процентный диапазон, относительно частоты искомого пика. |
| &nbsp;&nbsp;&nbsp;&nbsp;*freqRange*               | При отключенном *modeFunction*, процентный диапазон, относительно частоты искомого пика. |
| &nbsp;&nbsp;**\<schemeValidator/>**               | Настройка валидирования найденных пиков на основе fuzzy правил. |

&nbsp;

Table 3.10.2. - **\<schemeValidator/>** structure

| Name of the field        | Description |
|--------------------------|-------------|
| *validLogLevel*          | Уровень логарифмической выраженности суммирующийся с уровнем в logSpectrum. Позволяет производить более гибкую настройку работы фреймворка. [дБ] |
| *enableFindLineFreq*     | Включить/отключить нахождение сетевых гармоник генератора по фиксированному диапазону. |
| *freqRangeTwiceLineFreq* | Диапазон поиска в Гц. Выставляется для вектора частот. |
| *harmonicsTwiceLineFreq* | Вектор гармоник частот второй линейной частоты генератора. При указании вектора используется запись A:B:C, где A - начальное значение, B - шаг, C - конечное значение. |

&nbsp;

## <a name="scalogramHadler">3.11. scalogramHadler</a>

developers: *Aslamov Yu., Tsurko Al., Kechik D., Aslamov A.*

**scalogramHadler** - class combining a set of methods for constructing and analyzing a sсalogram.

```
<scalogramHandler processingEnable="1" plotEnable="1" shortSignalEnable="1" scalogramType="swd+norm">
	<shortSignal  plotEnable="0" type='multi' description="Cut-off the original signal and form the shortened one from one @mono piece or several @multi pieces">
		<mono startSecond="2" lengthSeconds="10"/>
		<multi framesNumber="10" secondsPerFrame="1"/>
	</shortSignal>
	<scalogram plotEnable="1" scaleType="log2" waveletName="swd_morl1" waveletFormFactor="1" secondsPerFrame="30" varianceEnable="1" interpolationEnable="0" interpolationFactor="8">
		<log2 lowFrequency="250" highFrequency="8000" frequenciesPerOctave="8" roundingEnable="0"/>
		<linear lowFrequency="250" highFrequency="8000" frequencyStep="100"/>
	</scalogram>
	<SSD frequencyRefinementEnable="1" coefficientsRefinementEnable="1" energyContributionThreshold="0.01" desctiption="Sparse Scalegram Decomposition for narrow-band frequency domain and time-frequency domain processing">
		<frequencyRefinement accuracyPercent="1" percentRange="12.5"/>
	</SSD>
	<octaveScalogram lowFrequency="360" highFrequency="10000" filterMode="1/3 octave" roundingEnable="1" warningLevel="" damageLevel="" description=""/>
	<peaksFinder> 
		<swdScalogram plotEnable="1" heightThresholds="0.85;1.15;10" widthThresholds="1;2;10" prominenceThresholds="0.08;0.25;10" stepsNumberThreshold="2" interpolationEnable="0" interpolationFactor="25" validityThresholds="0.55, 0.65, 0.75" mbValidPeaksEnable="1" excludeClosePeaksEnable="0" maxValidPeaksNumber="3" minValidPeaksDistance="50" peakValidationMethod="Coarse" energyThresholdMethod='2' energyThresholds="0.35;0.15;1.0;1.0;1.0;1.0;" coarseEnergyValodationThreshold="0.05" description="" >
			<energyEstimation plotEnable="1" scalogramEnergyEstimation="1" scalogramEnergyForceRecast="0" energyEstimationMethod="minScalHillHeight_upperValleyWidth" energyEstimationThresholds="0.15, 0.075, 0.01" energyEstimationLabels="High, Medium, Low, Insign" plotKeepAdditionalData="0"/>
		</swdScalogram>
		<normalizedScalogram plotEnable="1" heightThresholds="0.85;1.15;10" widthThresholds="1;2;10" prominenceThresholds="0.08;0.25;10" stepsNumberThreshold="2" interpolationEnable="0" interpolationFactor="25" validityThresholds="0.55, 0.65, 0.75" mbValidPeaksEnable="1" excludeClosePeaksEnable="0" maxValidPeaksNumber="3" minValidPeaksDistance="50" peakValidationMethod="Coarse" energyThresholdMethod='2' energyThresholds="0.35;0.15;1.0;1.0;1.0;1.0;" coarseEnergyValodationThreshold="0.05" description="" >
			<energyEstimation plotEnable="1" scalogramEnergyEstimation="1" scalogramEnergyForceRecast="0" energyEstimationMethod="minScalHillHeight_upperValleyWidth" energyEstimationThresholds="0.15, 0.075, 0.01" energyEstimationLabels="High, Medium, Low, Insign" plotKeepAdditionalData="0"/>
		</normalizedScalogram>
	</peaksFinder>
</scalogramHandler>
```
Picture 3.11.1. - Writing format in config.xml of settings **\<scalogramHadler/>**

&nbsp;

Table 3.11.1. - **\<scalogramHadler/>** structure

| Name of the field                   | Description |
|-------------------------------------|-------------|
| *processingEnable*                  | Разрешить расчет метода. |
| *plotEnable*                        | Разрешить отрисовку изображений метода. |
| *shortSignalEnable*                 | Расчет скалограммы по укороченному сигналу. |
| *scalogramType*                     | Тип скалограммы для построения. (`swd`, `norm`, `swd+norm`) |
| &nbsp;&nbsp;**\<shortSignal/>**     | Настройки укороченного сигнала. |
| &nbsp;&nbsp;**\<scalogram/>**       | Настройки построения скалограммы. |
| &nbsp;&nbsp;**\<SSD/>**             |  |
| &nbsp;&nbsp;**\<octaveScalogram/>** | Настройки построения октавной скалограммы. |
| &nbsp;&nbsp;**\<peaksFinder/>**     | Анализ скалограммы (поиск резонансных частот). |

&nbsp;

Table 3.11.2. - **\<shortSignal/>** structure

| Name of the field                         | Description |
|-------------------------------------------|-------------|
| *plotEnable*                              | Разрешить отрисовку изображений метода. |
| *type*                                    | Тип короткого сигнала. (`multi`, `mono`) |
| &nbsp;&nbsp;**\<mono/>**                  | Расчет скалограммы по 1 фрагменту сигнала. |
| &nbsp;&nbsp;&nbsp;&nbsp;*startSecond*     | Стартовая секунда фрагмента. |
| &nbsp;&nbsp;&nbsp;&nbsp;*lengthSeconds*   | Длина фрагмента. [сек] |
| &nbsp;&nbsp;**\<multi/>**                 | Расчет скалограммы по нескольким  фрагментам сигнала. |
| &nbsp;&nbsp;&nbsp;&nbsp;*framesNumber*    | Количество фрагментов сигнала. |
| &nbsp;&nbsp;&nbsp;&nbsp;*secondsPerFrame* | Длительность каждого фрагмента. [сек] |

&nbsp;

Table 3.11.3. - **\<scalogram/>** structure

| Name of the field                              | Description |
|------------------------------------------------|-------------|
| *plotEnable*                                   | Разрешить отрисовку изображений метода. |
| *scaleType*                                    | Тип сетки частот. (`log2`, `linear`) |
| *waveletName*                                  | Вейвет для построения скалограммы. (`mexh_morl`, `morl`) |
| *waveletFormFactor*                            | Коэффициент формы вейвлета (увеличение приводит к удлинению вейвлета => увеличению частотного разрешения). |
| *secondsPerFrame*                              | Длина фрагмента при разбиении сигнала на фрагменты для распараллеливания вычислений. [сек] |
| *varianceEnable*                               | Расчет скалограммы на основе std (при `1`) или max (при `0`). |
| *interpolationEnable*                          | Разрешить интерполяцию полученной скалограммы для лучшего поиска резонансных частот. |
| *interpolationFactor*                          | Коэффициент интерполяции. |
| &nbsp;&nbsp;**\<log2/>**                       | Логарифмический масштаб по основанию 2. |
| &nbsp;&nbsp;&nbsp;&nbsp;*lowFrequency*         | Нижняя (стартовая) частота. |
| &nbsp;&nbsp;&nbsp;&nbsp;*highFrequency*        | Верхняя (конечная) частота. |
| &nbsp;&nbsp;&nbsp;&nbsp;*frequenciesPerOctave* | Количество частот (точек) на октаву (по умолчанию `8`). |
| &nbsp;&nbsp;&nbsp;&nbsp;*roundingEnable*       | Разрешить округление частот до 2^n (по умолчанию `0`). |
| &nbsp;&nbsp;**\<linear/>**                     | Линейный масштаб частот. |
| &nbsp;&nbsp;&nbsp;&nbsp;*lowFrequency*         | Нижняя (стартовая) частота. |
| &nbsp;&nbsp;&nbsp;&nbsp;*highFrequency*        | Верхняя (конечная) частота. |
| &nbsp;&nbsp;&nbsp;&nbsp;*frequencyStep*        | Шаг частот. |

&nbsp;

Table 3.11.4. - **\<SSD/>** structure

| Name of the field                         | Description |
|-------------------------------------------|-------------|
| *frequencyRefinementEnable*               |  |
| *coefficientsRefinementEnable*            |  |
| *energyContributionThreshold*             |  |
| &nbsp;&nbsp;**\<frequencyRefinement/>**   |  |
| &nbsp;&nbsp;&nbsp;&nbsp;*accuracyPercent* |  |
| &nbsp;&nbsp;&nbsp;&nbsp;*percentRange*    |  |

&nbsp;

Table 3.11.5. - **\<octaveScalogram/>** structure

| Name of the field | Description |
|-------------------|-------------|
| *lowFrequency*    | Нижняя (стартовая) частота. |
| *highFrequency*   | Верхняя (конечная) частота. |
| *filterMode*      | Тип октавной скалограммы. (`1 octave`, `1/3 octave`, `1/6 octave`) |
| *roundingEnable*  | Разрешить округление частот до 2^n (по умолчанию `1`). |
| *warningLevel*    | Набор порогов среднего уровня. |
| *damageLevel*     | Набор порогов среднего уровня. |

&nbsp;

Table 3.11.6. - **\<peaksFinder/>** structure

| Name of the field                                                | Description |
|------------------------------------------------------------------|-------------|
| **\<swdScalogram/>**                                             | Нормализованная скалограмма с коррекцией (поднятием на НЧ). |
| **\<normalizedScalogram/>**                                      | Нормализованная скалограмма без коррекции. |
| &nbsp;&nbsp;*coarseEnergyValodationThreshold*                    | Минимальная оценка энергии сигнала в максимуме скалограммы, чтобы признать результат действительным. |
| &nbsp;&nbsp;*energyThresholdMethod*                              | Метод установление энергетического порога валидации пиков. |
| &nbsp;&nbsp;*energyThresholds*                                   | Параметры расчёта энергетического порога. |
| &nbsp;&nbsp;*excludeClosePeaksEnable*                            | Разрешает исключение близких пиков, в пределах *minValidPeaksDistance*. |
| &nbsp;&nbsp;*heightThresholds*                                   | Пороги высоты пика для fuzzy-контейнера. |
| &nbsp;&nbsp;*interpolationEnable*                                | Разрешает интерполяцию скалограммы. |
| &nbsp;&nbsp;*interpolationFactor*                                | Число точек интерполяции. |
| &nbsp;&nbsp;*maxValidPeaksNumber*                                | Ограничивает число пиков в результате для предотвращения ложных срабатываний. |
| &nbsp;&nbsp;*mbValidPeaksEnable*                                 | Допускает включение в результат пиков со средней валидностью. |
| &nbsp;&nbsp;*minValidPeaksDistance*                              | Минимальное расстояние между пиками,пределах которого выбирается единственный с наибольшей валидностью. |
| &nbsp;&nbsp;*peakValidationMethod*                               | Определяет метод отбора пиков. `Coarse` наиболее оптимальный. |
| &nbsp;&nbsp;*plotEnable*                                         | Разрешает вывод изображений. |
| &nbsp;&nbsp;*prominenceThresholds*                               | Пороги выраженности пика для fuzzy-контейнера. |
| &nbsp;&nbsp;*stepsNumberThreshold*                               | Не используется. |
| &nbsp;&nbsp;*validityThresholds*                                 | Не используется. |
| &nbsp;&nbsp;*widthThresholds*                                    | Не используется. |
| &nbsp;&nbsp;&nbsp;&nbsp;**\<energyEstimation/>**                 | Настройка метода оценки энергии пика скалограммы. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*energyEstimationLabels*     | Метки энергетической выраженности. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*energyEstimationMethod*     | Метод оценки энергии. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*energyEstimationThresholds* | Пороги, по которым присваиваются метки. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*plotEnable*                 | Разрешает вывод изображений. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*plotKeepAdditionalData*     | Не используется. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*scalogramEnergyEstimation*  | Не используется. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*scalogramEnergyForceRecast* | Включает пересчет оценки энергии. |

&nbsp;

## <a name="periodicityProcessing">3.12. periodicityProcessing</a>

developers: *Kechik D., Aslamov Yu.*

**periodicityProcessing** - a set of algorithms for searching periodicity in the time domain with an estimate of the validity of their definition.

```
<periodicityProcessing description="Search for periodicities in the time-domain signal" plotEnable="1" processingEnable="1">
	<correlationHandler comparePercentRange="5" detrendEnable="2" maxFrequency="1000" minFrequency="4" periodsTableComparisonEnable="1" fullSavingEnable="0" logEnable="3" preProcessingEnable="1" slowNoiseRemoveEnable="1" typeDetectionEnable="1">
	   <peaksDistanceEstimation peaksOverlap="2" peaksPerFrame="3" validationThreshold="0.25" peaksTableCorrection="0" peaksTableTrustedInterval="adapt">
		  <ThresholdLin average="0.1" high="0.2" low="0.05" zero="0.001"/>
		  <ThresholdLog average="2" high="3" low="1" zero="0"/>
		  <cutNoiseAndRescaling linearProcessingEnable="1" linearWindWidth="2" logProcessingEnable="1" logWindWidth="0, 2:4" originalProcessingEnable="1"/>
		  <absoleteThresholdFinding processingEnable="0"/>
	   </peaksDistanceEstimation>
	   <periodsValidation freqRangeLimit="1" lowFalseDelete="1" lowFalseMem="1" resonantPeriodsEnable="1" sideLeafDelete="1" sideLeafMem="1" validationEnable="1" peaksNumTresholds="5,3" trashPeaksTableDeleteWeights=""/>
	   <interfPeriodEstimation interfValidityWeight="0.3" processingEnable="1" peaksTableCorrection="0" correctPeaksTablesBiases="0" validityCorrection="1"/>
	   <interfPeriodFinding baseSamplesNum="3" falsePeriodsDelete="0" deNoiseWindow="" averWindow="0.5width" validationWindowWidth="peakWidth" findingWindowWidth="0.2dist" interfNumbDistPeaksValidWeights="0.65/3; 0.65/3; 0.35; 0.65/3"  processingEnable="1"/>
	   <smoothedACFprocessing logProcessingEnable="1" originalProcessingEnable="1" smoothMethods="windowAveraging" span="1width" slowEnable="1" diffEnable="1" peaksTableCorrection="1" fullTablesCorrection="0"/>
	   <correlation envelopeEnable="1" maxFreq="1000" minFreqPeriods="10" normalizationEnable="1"/>
	</correlationHandler>
	<periodicityHandler	minPercentDeviation="1" maxPercentDeviation="10" frequencyTrackingTypicalPercentError="0.1" shaftSpeedRefinementTypicalPercentError="0.5" bearingParametersRefinementTypicalPercentError="1" periodicityEstimationTypicalPercentError="0.5"/>
</periodicityProcessing>
```
Picture 3.12.1. - Writing format in config.xml of settings **\<periodicityProcessing/>**

&nbsp;

Table 3.12.1. - **\<periodicityProcessing/>** structure

| Name of the field                           | Description |
|---------------------------------------------|-------------|
| **\<correlationHandler/>**                  | Задает режимы предобработки сигнала и сохранения вывода. |
| &nbsp;&nbsp;**\<peaksDistanceEstimation/>** | Задает параметры базового алгоритма поиска периодов по таблице пиков. |
| &nbsp;&nbsp;**\<periodsValidation/>**       | Задает пороги, по которым валидируются найденные периодичности, включает/отключает методы валидации. |
| &nbsp;&nbsp;**\<interfPeriodEstimation/>**  | Параметры метода интерференционного уточнения и валидации: включение/отключение метода (*processingEnable*) и вес интерференционной валидности (*interfValidityWeight*). |
| &nbsp;&nbsp;**\<interfPeriodFinding/>**     | Параметры поиска периодов интерференционным методом. |
| &nbsp;&nbsp;**\<smoothedACFprocessing/>**   | Параметры поиска периодов по сглаженному сигналу. |
| &nbsp;&nbsp;**\<correlation/>**             |  |
| **\<periodicityHandler/>**                  |  |

&nbsp;

Table 3.12.2. - **\<correlationHandler/>** attributes

| Name of the field              | Description |
|--------------------------------|-------------|
| *comparePercentRange*          |  |
| *detrendEnable*                | Задает необходимость предварительного удаления тренда из сигнала (*detrendEnable*), что актуально для АМ-сигналов. Принимает значения `0`, `1` (откл/вкл), `2` – устанавливать необходимость удаления тренда по его размаху. |
| *maxFrequency*                 | Задает ограничение в поиске максимальной частоты. |
| *minFrequency*                 | Задает ограничение в поиске минимальной частоты. |
| *periodsTableComparisonEnable* | Разрешает/запрещает поиск периодичностей в объединённых таблицах. |
| *fullSavingEnable*             | Включает вывод и сохранение всей информации при включенных debugMode и общих разрешениях на вывод изображений. |
| *logEnable*                    | Отвечает за вывод в лог результатов. Для вывода только сообщений в отчёт (в лог) устанавливается значение `3`, для полного вывода в командную строку - `1`. |
| *preProcessingEnable*          | Разрешает предварительную обработку АКФ: удаление выбросов в нулевой момент времени, удаление тренда, медленных компонентов. Рекомендуемое значение - `1`. |
| *slowNoiseRemoveEnable*        | Разрешает удаление медленно меняющихся компонентов. |
| *typeDetectionEnable*          | Разрешает определение типа сигнала: АМ/импульсный. |

&nbsp;

Table 3.12.3. - **\<peaksDistanceEstimation/>** attributes

| Name of the field              | Description |
|--------------------------------|-------------|
| *peaksOverlap*                 | Перекрытие окон, на которые разбивается последовательность пиков. |
| *peaksPerFrame*                | Их число на одно окно, в течение которого сохраняется средняя дистанция. |
| *periodsTableComparisonEnable* | Разрешает/запрещает поиск периодичностей в объединённых таблицах. |
| *validationThreshold*          | Порог валидации. |
| *peaksTableCorrection*         | Разрешает коррекцию таблицы пиков по максимуму в окне на этапе создания пороговых таблиц. |
| *peaksTableTrustedInterval*    | Разрешает коррекцию таблицы пиков: метод оставляет больший из двух в некотором доверительном интервале. Значение рекомендуется выбирать порядка 10% среднего расстояния или `adapt` - по ширине окна предварительного сглаживания. |

&nbsp;

Table 3.12.4. - **\<peaksDistanceEstimation/>** structure

| Name of the field                | Description |
|----------------------------------|-------------|
| **\<ThresholdLin/>**             | Задает пороги отбора «глобальных» пиков для линейного масштаба. |
| **\<ThresholdLog/>**             | Задает пороги отбора «глобальных» пиков для логарифмического масштаба. |
| **\<cutNoiseAndRescaling/>**     | Задает параметры масштабирования и вырезания уровня шума. |
| **\<absoleteThresholdFinding/>** |  |
| &nbsp;&nbsp;*processingEnable*   |  |

&nbsp;

Table 3.12.5. - **\<cutNoiseAndRescaling/>** structure

| Name of the field          | Description |
|----------------------------|-------------|
| *linearProcessingEnable*   |  |
| *linearWindWidth*          |  |
| *logProcessingEnable*      |  |
| *logWindWidth*             |  |
| *originalProcessingEnable* |  |

&nbsp;

Table 3.12.6. - **\<periodsValidation/>** structure

| Name of the field              | Description |
|--------------------------------|-------------|
| *freqRangeLimit*               |  |
| *lowFalseDelete*               |  |
| *lowFalseMem*                  |  |
| *resonantPeriodsEnable*        |  |
| *sideLeafDelete*               |  |
| *sideLeafMem*                  |  |
| *validationEnable*             |  |
| *peaksNumTresholds*            |  |
| *trashPeaksTableDeleteWeights* |  |

&nbsp;

Table 3.12.7. - **\<interfPeriodEstimation/>** structure

| Name of the field          | Description |
|----------------------------|-------------|
| *interfValidityWeight*     | Вес “интерференционной” валидности при усреднении. |
| *processingEnable*         | Разрешает/запрещает интерференционное уточнение. |
| *peaksTableCorrection*     | Разрешает коррекцию таблицы пиков по максимуму в окне с разбиением пиков по порогам и пересчетом таблицы периодов. |
| *correctPeaksTablesBiases* | Разрешает устранение смещения таблицы по положению интерференционного максимума. |
| *validityCorrection*       | Разрешает пересчёт валидности по интерференционной картине. |

&nbsp;

Table 3.12.8. - **\<interfPeriodFinding/>** structure

| Name of the field                 | Description |
|-----------------------------------|-------------|
| *baseSamplesNum*                  | Число глобальных пиков, от которых ставятся интерференционные окна. |
| *falsePeriodsDelete*              | Разрешает/запрещает удаление ложных периодов, у которых выпадает из середины множество окон. |
| *deNoiseWindow*                   | Окно предварительного вырезания уровня шума. |
| *averWindow*                      | Окно предварительного сглаживания. |
| *validationWindowWidth*           | Адаптивное окно для интерференционной валидации. |
| *findingWindowWidth*              | Адаптивное окно для интерференционного поиска. |
| *interfNumbDistPeaksValidWeights* | Веса критериев валидности: интерференционной валидности, числа пиков, постоянства расстояния, валидности пиковой таблицы. |
| *processingEnable*                |  |

&nbsp;

Table 3.12.9. - **\<smoothedACFprocessing/>** structure

| Name of the field          | Description |
|----------------------------|-------------|
| *logProcessingEnable*      | Разрешает обработку всеми методами в логарифмическом масштабе. |
| *originalProcessingEnable* | Разрешает обработку в линейном масштабе. |
| *smoothMethods*            | Устанавливает методы сглаживания: `windowAveraging`, `slideAveraging`, `centralSlideAveraging`, те же с постфиксом *diff* (вычитать сглаженный сигнал и исследовать ВЧ пульсации - разностная обработка) и/или *log* (тем же методом в логарифмическом масштабе). |
| *span*                     | Окно сглаживания. Может задаваться в отсчетах или адаптивно: `1width`, `1dist` - в средних ширинах наиболее выраженных пиков или расстояниях между ними. |
| *slowEnable*               | Разрешает поиск периодов в выделенной предварительным сглаживанием НЧ компоненте. |
| *diffEnable*               | Разрешает разностную обработку. |
| *peaksTableCorrection*     | Разрешает коррекцию таблицы пиков по максимуму в окне на этапе создания пороговых таблиц. |
| *fullTablesCorrection*     | Разрешает коррекцию таблицы пиков по максимуму в окне с разбиением пиков по порогам и пересчетом таблицы периодов. |

&nbsp;

Table 3.12.10. - **\<correlation/>** structure

| Name of the field     | Description |
|-----------------------|-------------|
| *envelopeEnable*      |  |
| *maxFreq*             |  |
| *minFreqPeriods*      |  |
| *normalizationEnable* |  |

&nbsp;

Table 3.12.11. - **\<periodicityHandler/>** structure

| Name of the field                                | Description |
|--------------------------------------------------|-------------|
| *minPercentDeviation*                            |  |
| *maxPercentDeviation*                            |  |
| *frequencyTrackingTypicalPercentError*           |  |
| *shaftSpeedRefinementTypicalPercentError*        |  |
| *bearingParametersRefinementTypicalPercentError* |  |
| *periodicityEstimationTypicalPercentError*       |  |

&nbsp;

## <a name="timeDomainClassifier">3.13. timeDomainClassifier</a>

developers: *Aslamov Yu.*

**timeDomainClassifier** - a set of algorithms for the classification of shock processes templates in the time domain. Contains a set of algorithms for segmentation, clustering and classification.

```
<timeDomainClassifier description="Toolbox for time-domain classification" plotEnable="1" shortSignalEnable="1">
	<shortSignal  plotEnable="0" type='mono' description="Cut-off the original signal and form the shortened one from one @mono piece or several @multi pieces">
		<mono startSecond="0" lengthSeconds="5"/>
		<multi framesNumber="5" secondsPerFrame="1"/>
	</shortSignal>
	<SWD plotEnable="1" maxr2="0.5" r2CheckFrequency="1" cr="1" efficiencyThreshold="0.5" saturationThreshold="0.25" feedbackFrequency="250" nonnegativeEnable="0" minDelta="0" deadzone="0"/>
	<elementRecognition recallThreshold = "0.75" thresholdL="0.6" thresholdH="0.85"/>
</timeDomainClassifier>
```
Picture 3.13.1. - Writing format in config.xml of settings **\<timeDomainClassifier/>**

&nbsp;

Table 3.13.1. - **\<timeDomainClassifier/>** structure

| Name of the field          | Description |
|----------------------------|-------------|
| **\<shortSignal/>**        | Выделяет из сигнала отрезок меньшей длины для увеличения скорости обработки. |
| **\<SWD/>**                |  |
| **\<elementRecognition/>** |  |

&nbsp;

Table 3.13.2. - **\<shortSignal/>** structure

| Name of the field                         | Description |
|-------------------------------------------|-------------|
| *plotEnable*                              | Разрешить/запретить отрисовку результатов работы. |
| *type*                                    | Тип короткого сигнала: `mono` - сигнал из одного фрагмента, `multi` - сигнал, составленный из нескольких коротких фрагментов. Для **\<timeDomainClassifier/>** рекомендуется использовать `mono`. |
| &nbsp;&nbsp;**\<mono/>**                  | Параметры  короткого сигнала, состоящего из одного фрагмента. |
| &nbsp;&nbsp;&nbsp;&nbsp;*startSecond*     | Начало сигнала. [сек] |
| &nbsp;&nbsp;&nbsp;&nbsp;*lengthSeconds*   | Длительность сигнала. [сек] |
| &nbsp;&nbsp;**\<multi/>**                 | Параметры  короткого сигнала, состоящего из нескольких фрагментов из разных частей оригинального сигнала. |
| &nbsp;&nbsp;&nbsp;&nbsp;*framesNumber*    | Количество коротких фрагментов. |
| &nbsp;&nbsp;&nbsp;&nbsp;*secondsPerFrame* | Длительность каждого фрагмента. [сек] |

&nbsp;

Table 3.13.3. - **\<SWD/>** structure

| Name of the field     | Description |
|-----------------------|-------------|
| *plotEnable*          |  |
| *maxr2*               |  |
| *r2CheckFrequency*    |  |
| *cr*                  |  |
| *efficiencyThreshold* |  |
| *saturationThreshold* |  |
| *feedbackFrequency*   |  |
| *nonnegativeEnable*   |  |
| *minDelta*            |  |
| *deadzone*            |  |

&nbsp;

Table 3.13.4. - **\<elementRecognition/>** structure

| Name of the field | Description |
|-------------------|-------------|
| *recallThreshold* |  |
| *thresholdL*      |  |
| *thresholdH*      |  |

&nbsp;

## <a name="timeFrequencyDomainClassifier">3.14. timeFrequencyDomainClassifier</a>

developers: *Aslamov Yu., Kosmach N.*

**timeFrequencyDomainClassifier** - a set of algorithms for detecting equipment defects. The operating principle: based on the scalogram the optimal filtering is performed then a frequency classifier (**\<frequencyDomainClassifier/>**) ​​is applied to the filtered signals.

```
<timeFrequencyDomainClassifier plotEnable="1" scalogramDataSource="SSD" SSDThreshold="0.05" discription="frequencyMapType='scalogram'/'SSD' (sparse scalegram decomposition)">
	<filtering type="bpf" description="type = 'bpf'(bandPass filtering) OR 'wavelet'(continuous wavelet transform)">
		<bpf Rp="1" Rs="10"/>
		<wavelet waveletName="swd_morl1" description="waveletName = 'swd_morl1'/'swd_morl2'/'swd_morl4'/'swd_morl8'"/>
	</filtering>
	<logSpectrum enableEnergyPeakFinder="0"/>
</timeFrequencyDomainClassifier>
```
Picture 3.14.1. - Writing format in config.xml of settings **\<timeFrequencyDomainClassifier/>**

&nbsp;

Table 3.14.1. - **\<timeFrequencyDomainClassifier/>** structure

| Name of the field               | Description |
|---------------------------------|-------------|
| *plotEnable*                    | Включить/отключить отрисовку метода. |
| *scalogramDataSource*           | Источник данных о частотных областнях. Возможные варианты: `scalogram` - данные получены на основе анализа выраженных областей скейлограммы, `SSD` - данные получены на основе разреженной декомпозиции скейлограммы. |
| *SSDThreshold*                  | Порог валидности частотных областей по критерию энергетического вклада. (0<`SSDThreshold`<1)  |
| &nbsp;&nbsp;**\<filtering/>**   | Настройки способа фильтрации сигналов в окрестности найденных частотных областей. |
| &nbsp;&nbsp;**\<logSpectrum/>** | Поле описано в [spectra](#spectra).  |

&nbsp;

Table 3.14.2. - **\<filtering/>** structure

| Name of the field                     | Description |
|---------------------------------------|-------------|
| *type*                                | Тип способа фильтрации. Возможные варианты: `bpf` - полосовая фильтрация; `wavelet` - фильтрация при помощи нормированного Фурье-образа вейвлета. |
| &nbsp;&nbsp;**\<bpf/>**               | Полосовая фильтрация при помощи фильтра Баттерворта. |
| &nbsp;&nbsp;&nbsp;&nbsp;*Rp*          | Допустимый уровень пульсаций в полосе пропускания. [дБ] |
| &nbsp;&nbsp;&nbsp;&nbsp;*Rs*          | Требуемый уровень ослабления в полосе подавления. [дБ] |
| &nbsp;&nbsp;**\<wavelet/>**           | Фильтрация при помощи нормированного Фурье-образа вейвлета. |
| &nbsp;&nbsp;&nbsp;&nbsp;*waveletName* | Имя используемого вейвлета. Возможные варианты: `swd_morl1`, `swd_morl2`, `swd_morl4`, `swd_morl8`. |


| Name of the field   | Description |
|---------------------|-------------|
| **                    |  |
| **                    |  |
| **                    |  |
| **                    |  |
| **                    |  |
| **                    |  |
| **                    |  |
| **                    |  |




| Name of the field   | Description |
|---------------------|-------------|
|                     |  |
|                     |  |
|                     |  |
|                     |  |
|                     |  |
|                     |  |
|                     |  |
|                     |  |