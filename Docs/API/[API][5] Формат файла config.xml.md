Specification.  
config.xml file format
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
&nbsp;&nbsp;&nbsp;&nbsp;[3.11. scalogramHandler](#scalogramHandler)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.12. periodicityProcessing](#periodicityProcessing)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.13. timeDomainClassifier](#timeDomainClassifier)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.14. timeFrequencyDomainClassifier](#timeFrequencyDomainClassifier)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.15. spm](#spm)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.16. iso15242](#iso15242)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.17. octaveSpectrum](#octaveSpectrum)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.18. decisionMaker](#decisionMaker)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.19. history](#history)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.20. statusWriter](#statusWriter)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.21. frequencyTracking](#frequencyTracking)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.22. timeSynchronousAveraging](#timeSynchronousAveraging)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.23. checkSignalSymmetry](#checkSignalSymmetry)  
&nbsp;&nbsp;&nbsp;&nbsp;[3.24. bearingsParametersRefinement](#bearingsParametersRefinement)    
&nbsp;&nbsp;&nbsp;&nbsp;[3.25. preprocessing](#preprocessing)    
&nbsp;&nbsp;&nbsp;&nbsp;[3.26. packetWaveletTransform](#packetWaveletTransform) 
&nbsp;&nbsp;&nbsp;&nbsp;[3.27. cepstrogram](#cepstrogram)   
___
&emsp;config.xml is a configuration file for the computeFremework. The specification contains a brief information about the config.xml structure and parameters for customizing individual methods.

Table 1. - A brief config.xml structure

| Name of the field  | Description                                                                                                       |
|--------------------|-------------------------------------------------------------------------------------------------------------------|
| **\<sensor/>**     |                                                                                                                   |
| **\<common/>**     | intended for basic setting of the framework: switching on/off toolbars/methods, operating modes, etc.             |
| **\<evaluation/>** | intended for detailed configuration of the framework, contains parameters of each method involved in processing.  |

&nbsp;

## <a name="sensors">1. sensors</a>

```
<sensor type="BR" serialNo="M1071364749" equipmentDataPoint="1" resonantFrequency="10000" channelsNumber="1" primaryChannelNo="1" lowFrequency="4" highFrequency="8000" sensitivity="100" sensitivityCorrection="1" description="Basic sensor parameters"/>
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
	
	<equipmentStateDetectionEnable value="0" weight="1" description="Enable equipment state detection"/>
	<debugModeEnable value="0" logFileEnable="true" description="Enable developer features"/>
	
	<printPlotsEnable value="0" visible="off" title="off" description="Enable saving jpg-images of found defects for modules with attribute //plotEnable='1'//  "/>
	<parpoolEnable value="0" weight="1" description="Enable parallel calculations"/>
	
	<commonFunctions initializationWeight="1" fillFileStructWeight="1" hardwareProfileParserWeight="1" description="Contain the weght of functions which always run"/>
	
	<frequencyTrackingEnable value="0" weight="3" description="Enable signal frequencies tracking and further signal resampling (for equipment with various shaft rotational speed)"/>
	<frequencyCorrectionEnable value="0" weight="3" description="Enable shaft frequency estimation for further kinematics correction"/>
	<shaftTrajectoryDetectionEnable value="0" weight="3" description="Enable shaft displacement trajectory analysis"/>
	
	<bearingsParametersRefinement value="0" weight="2" description="Enable bearings parameters refinement"/>
	<frequencyDomainClassifierEnable value="0" weight="5" description="Enable defect detection based on frequency-domain analysis "/>
	
	<timeDomainClassifierEnable value="0" weight="10" scalogramWeight="0" description="Enable time-frequency domain analysis, i.m. scalogram analysis, wavelet-based filtration, search for periodicities, frequency analysis"/>
	<timeFrequencyDomainClassifierEnable value="0" weight="5" scalogramWeight="0" description="Enable time-domain analysis, i.m. scalogram analysis, search for periodicities, pattern extraction and classification" />

	<mallatScatteringEnable value="0" weight="1" description="CURRENTLY UNUSED! Enable Mallat Scattering Network (similar to octaveSpectrum)"/>
	<timeSynchronousAveragingEnable value="0" weight="3" description="Enable time synchronous averaging method for gearings"/>
	<metricsEnable value="0" weight="2" description="Enable metrics results print to status file"/>
	<spmEnable value="0" weight="1" description="Enable first shock-pulse method(SPM) calculations with dBc/dBm or LR/HR levels"/>
	<iso15242Enable value="0" weight="1" description="Enable calculations of mean vibration level in 3 ranges (L,M,H)"/>
	<iso10816Enable value="0" weight="1" description="Enable evaluation of rms vibration velocity according to ISO10816 standard"/>
	<iso7919Enable value="0" weight="1" description="Enable evaluation of peak2peak vibration displacement according to ISO7919 standards"/>
	<vdi3834Enable value="0" weight="1" description="Enable evaluation of vibration according to VDI3834 standard"/>
	<octaveSpectrumEnable value="0" weight="1" description="Enable calculations of 1{1/3,1/6}-octave spectrum for easy machine state control"/>
	<temperatureEnable value="0" weight="1" description="Enable temperature processing"/>
	
	<decisionMakerEnable value="0" weight="1" historyWeight="1" description="Enable decision maker based on several method. Frequency-,time- and time-frequency domains; iso 10816 and etc are used"/>
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
| **\<shaftTrajectoryDetectionEnable/>**      |                                                                                                                                                                                              |
| **\<bearingsParametersRefinement/>**        |                                                                                                                                                                                              |
| **\<frequencyDomainClassifierEnable/>**     | On/off classifier in the frequency domain. Requires a kinematic scheme.                                                                                                                      |
| **\<timeDomainClassifierEnable/>**          | On/off classifier in the time domain, which analyzes a scalogram, searches for periodicities, allocates and classifies shock process templates to determine the defective item of equipment. |
| **\<timeFrequencyDomainClassifierEnable/>** | On/off classifier in the time-frequency domain, which analyzes a scalogram, searches for periodicities and produces frequency domain processing after the optimal filtering.                 |
| **\<mallatScatteringEnable/>**              |                                                                                                                                                                                              |
| **\<timeSynchronousAveragingEnable/>**      |                                                                                                                                                                                              |
| **\<metricsEnable/>**                       | On/off calculation of basic metric values for vibration acceleration, vibration speed and vibration displacement.                                                                            |
| **\<spmEnable/>**                           | On/off processing by shock pulse monitoring.                                                                                                                                                 |
| **\<iso15242Enable/>**                      | On/off processing by iso15242.                                                                                                                                                               |
| **\<iso10816Enable/>**                      | On/off processing by iso10816.                                                                                                                                                               |
| **\<iso7919Enable/>**                       |                                                                                                                                                                                              |
| **\<vdi3834Enable/>**                       | On/off processing by vdi3834.                                                                                                                                                                |
| **\<octaveSpectrumEnable/>**                | On/off calculation of octave spectrum.                                                                                                                                                       |
| **\<temperatureEnable/>**                   | On/off temperature analysis.                                                                                                                                                                 |
| **\<decisionMakerEnable/>**                 | Enable/disable decision-making on defects and the extent of their development by a set of methods.                                                                                           |
| **\<historyEnable/>**                       | Enable/disable data processing for a certain period (history processing). Used to determine the state of equipment, training, adaptive thresholding, etc.                                    |

&nbsp;

## <a name="printPlotsEnable">2.1. printPlotsEnable</a>

developers: *Riabtsev P., Rachkovsky T.*

&emsp;**printPlotsEnable** - saving images.

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

&nbsp;

## <a name="evaluation">3. evaluation</a>

&emsp;The **\<evaluation/>** section contains information on the detailed configuration of the methods used.

&nbsp;

## <a name="debugMode">3.1. debugMode</a>

developers: *Aslamov Yu., Kechik D.*

&emsp;**debugMode** - developer mode.

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
| *signalGenerationEnable*            | On/off the test signals generator (one- and two-channel).                                                                                                                                                                                                                             |
| *shortSignalEnable*                 | On/off cropping of the input signal length to the specified in the settings.                                                                                                                                                                                                          |
| *plotWeakDamages*                   |                                                                                                                                                                                                                                                                                       |
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
| *lengthSeconds*                        |                                                                                                                                    |
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

&emsp;In **debugMode** mode, the machine locally runs server.exe to simulate the data transfer.

&nbsp;

## <a name="loger">3.2. loger</a>

developers: *Riabtsev P., Aslamov Yu.*

&emsp;**loger** - class for storing service information in a text file and console or transferring via a tcpip connection.

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

&emsp;**plots** - image settings.

```
<plots language="en" sizeUnits="pixels" imageSize="0, 0, 800, 600" fontSize="12" imageFormat="jpeg" imageQuality="91" imageResolution="0" jsonDataCompressionEnable="0" sampleQuantity="10000" description="Original size: sizeUnits='pixels', imageSize='0, 0, width, height', imageResolution='0'. Datatips font size is less than the main font in half"/>
```
Picture 3.3.1. - Writing format in config.xml of settings **\<plots/>**

&nbsp;

Table 3.3.1. - **\<plots/>** structure

| Name of the field           | Description |
|-----------------------------|-------------|
| *language*                  | Язык текста в изображениях. (`en`, `de`, `ru`) |
| *sizeUnits*                 | Единицы измерения величин imageSize. (`points`, `pixels`) |
| *imageSize*                 | Положение и размер изображения. Задано в виде вектора. `[left bottom width height]` |
| *fontSize*                  | Размер шрифта. [точек] |
| *imageFormat*               | Формат сохраняемого изображения. (`jpeg`, `json`, `jpeg+json`) |
| *imageQuality*              | Степень сжатия сохраняемого изображения [%]. (для формата jpeg) |
| *imageResolution*           | Разрешение сохраняемого изображения. [DPI] |
| *jsonDataCompressionEnable* | Enable compression of data when saving images' data to json. |
| *sampleQuantity*            | Target number of samples for plots' data. (used only for `json`(`jpeg+json`) and *jsonDataCompressionEnable*=`1`) |

&nbsp;

## <a name="spectra">3.4. spectra</a>

developers: *Aslamov Yu., Kosmach N., Riabtsev P.*

&emsp;**spectra** - a set of algorithms for constructing spectra of vibrating signals and extracting informative features.

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
| *accelerationEnvelopeRange*       | The frequency range of the acceleration envelope spectrum in the format “lowFrequency:highFrequency”. [Hz] |
| *velocityRange*                   | Диапазон частот спектра вибрскорости в формате “lowFrequency:highFrequency”. [Гц] |
| *displacementRange*               | Диапазон частот спектра виброперемещения в формате “lowFrequency:highFrequency”. [Гц] |
| *interpolationEnable*             | Разрешить интерполяцию спектров сигнала. |
| *decimationEnable*                | Enable of decimation for spectra calculation.  |
| &nbsp;&nbsp;**\<envSpectrum/>**   | Настройки для построения спектра огибающей виброускорения. |
| &nbsp;&nbsp;**\<logSpectrum/>**   | Настройки для расчета логарифмических спектров и выделения информативных признаков. |
| &nbsp;&nbsp;**\<interpolation/>** | Настройки алгоритма интерполяции спектров. |

&nbsp;

Table 3.4.2. - **\<envSpectrum/>** structure

| Name of the field | Description |
|-------------------|-------------|
| *plotEnable*      | Разрешить отрисовку изображений. |
| *filterType*      | Тип фильтра. (`LPF`, `BPF`, `HPF`) |
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
| *minDeviationFrequency*  |  |
| *maxDeviationFrequency*  | Максимальное значение усреднения для поиска энергетических пиков (Гц). |
| *enableEnergyPeakFinder* | Разрешить нахождение энергетических пиков. |
| *pointsNumberFactor*     | Необходимо для выбора количества усредняемых значений между *minDeviationFactor × df* и  *maxDeviationFrequency*. |
| *amplitudeFactor*        | Коэффициент выше которого считается количество пиков на пике (*amplitudeFactor × (max(вектор всех амплитуд пиков на энергетическом пике))*). |
| *minLogLevel*            | Минимальный уровень в дБ для обнаружения энергетических пиков. |
| *minPeaksNumber*         | Минимальное количество пиков на пике для отнесения их к одному значению расплывчатой частоты. |
| *minPeaksNumberEnergy*   | Минимальное количество пиков на энергетическом пике для отнесения их к одному значению расплывчатой энергонесущей частоты. |
| *df*                     | Minimum frequency resolution for finding peaks energy (Hz) |
| *percentOfPeaksOnPeak*   | Percent of valid peaks by all peaks on energy peaks. (Valid peakd is exceeding of treshold - max level amplitude emong all peaks × *amplitudeFactor*)|
| *saveEnergyPeak*         | Enable/disable. To save result finding peaks energy in acceleration domain and to apply them to displacement, velocity domains |

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

&emsp;**metrics** - a set of algorithms for calculating vibration metrics.

```
<metrics correctionEnable="1" firstSampleTime="0.5" secPerFrame="0.1" secOverlapValue="0.01" description="Returns the main parameters of acceleration, velocity and displacement">
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
| *correctionEnable*               | Enable/disable the metrics correction by the frequency deviation. |
| *firstSampleTime*                | The time point of the first sample for the metrics calculation. Samples below the specified one are not used. |
| *secPerFrame*                    | Frame length for CREST-FACTOR calculation. [sec] |
| *secOverlapValue*                | Freme overlapping value for CREST-FACTOR calculation. [sec] |
| &nbsp;&nbsp;**\<acceleration/>** | Parameters of acceleration metrics. |
| &nbsp;&nbsp;**\<velocity/>**     | Parameters of velocity metrics. |
| &nbsp;&nbsp;**\<displacement/>** | Parameters of displacement metrics. |

&nbsp;

Table 3.5.2. - **\<acceleration/>**, **\<velocity/>**, **\<displacement/>** structures

| Name of the field                        | Description |
|------------------------------------------|-------------|
| **\<rms/>**                              | Параметры метрики СКЗ. |
| &nbsp;&nbsp;*enable*                     | Вкл/выкл заполнения метрики в status.xml. |
| &nbsp;&nbsp;*frequencyRange*             | Диапазон частот, используемых для вычисления метрик СКЗ. |
| &nbsp;&nbsp;*thresholds*                 | Ручная установка порогов метрики вибросигнала. |
| **\<peak/>**                             | Параметры метрики ПИК. |
| &nbsp;&nbsp;*enable*                     | Вкл/выкл заполнения метрики в status.xml. |
| &nbsp;&nbsp;*thresholds*                 | Ручная установка порогов метрики вибросигнала. |
| **\<peak2peak/>**                        | Параметры метрики ПИК-ПИК. |
| **\<peakFactor/>**                       | Параметры метрики ПИК-ФАКТОР. |
| **\<crestFactor/>**                      | Параметры метрики КРЕСТ-ФАКТОР. |
| **\<kurtosis/>**                         | Параметры метрики КУРТОЗ. |
| **\<excess/>**                           | Параметры метрики ЭКСЦЕСС. |
| **\<noiseLog/>**                         | Параметры логарифмического уровня шума. |
| **\<envelopeNoiseLog/>**                 |  |
| **\<noiseLinear/>**                      | Параметры абсолютного уровня шума. |
| **\<envelopeNoiseLinear/>**              |  |
| **\<unidentifiedPeaksNumbers/>**         |  |
| **\<unidentifiedPeaksNumbersEnvelope/>** |  |

&emsp;Теги **\<acceleration/>**, **\<velocity/>**, **\<displacement/>** имеют одинаковую структуру.  
&emsp;Теги **\<peak2peak/>**, **\<peakFactor/>**, **\<crestFactor/>**, **\<kurtosis/>**, **\<excess/>**, **\<noiseLog/>**, **\<noiseLinear/>** имеют ту же структуру, что и тег <peak>.

&nbsp;

## <a name="equipmentStateDetection">3.6. equipmentStateDetection</a>

developers: *Riabtsev P.*

&emsp;**equipmentStateDetection** - a set of algorithms for determining of the equipment operation mode.

```
<equipmentStateDetection plotEnable="1" decisionMakerStates="on off" description="Method detects equipment state to turn on/off computeFramework">
	<metrics enable="1" description="">
		<trainingPeriod enable="1" trimmingEnable="0" trimmingFactor="0.5"
			trainingPeriodFormulaLower="/meanMain/*1 - /stdAdditional/*2"
			trainingPeriodFormulaUpper="/meanMain/*1 + /stdAdditional/*2"/>
		<thresholds>
			<acceleration_rms value="0.5 1"/>
			<velocity_rms value="0.2 0.8"/>
		</thresholds>
	</metrics>
	<octaveSpectrum enable="0"/>
	<psd enable="1" filterOrder="32" evaluationPointsNumber="1024" correlationThreshold="0.75" description="Linear prediction of filter coefficients for calculation the power spectral density"/>
</equipmentStateDetection>
```
Picture 3.6.1. - Writing format in config.xml of settings **\<equipmentStateDetection/>**

&nbsp;

Table 3.6.1. - **\<equipmentStateDetection/>** structure

| Name of the field                                                | Description |
|------------------------------------------------------------------|-------------|
| *plotEnable*                                                     |  |
| *decisionMakerStates*                                            | Возможные решения о режиме работы оборудования. (`on off`, `on idle off`). |
| &nbsp;&nbsp;**\<metrics/>**                                      | Содержит параметры для определения режима работы оборудования на основании метрик. |
| &nbsp;&nbsp;&nbsp;&nbsp;*enable*                                 | Включение/отключение метода. |
| &nbsp;&nbsp;&nbsp;&nbsp;**\<trainingPeriod/>**                   | Содержит параметры обучения для автоматического определения режима работы оборудования на основании метрик. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*enable*                     | Включение/отключение обучения. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*trimmingEnable*             | Включение/выключение обрезки выбивающихся данных. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*trimmingFactor*             | The factor of the additional training parameter for trimming outlayers. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*trainingPeriodFormulaLower* | The training formula for the lower threshold. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*trainingPeriodFormulaUpper* | The training formula for the upper threshold. |
| &nbsp;&nbsp;&nbsp;&nbsp;**\<thresholds/>**                       | Содержит поля метрик (например,  **\<acceleration_rms/>**) с указанными границами зон режимов работы оборудования. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**\<acceleration_rms/>**     | Содержит границы зон режимов работы оборудования метрики. |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*value*          | Граничные значения режимов работы оборудования. Одно значение соответствует границе зон режимов *ON OFF*. Два значение соответствует границам зон режимов *ON IDLE OF*: максимальное значение для границы режимов *ON IDLE*, минимальное значение для границы режимов *IDLE OFF*. |
| &nbsp;&nbsp;**\<octaveSpectrum/>**                               | Parameters for determining the equipment state by the octave spectrum. |
| &nbsp;&nbsp;&nbsp;&nbsp;*enable*                                 | Enable/disable determinning the equipment state by the octave spectrum. |
| &nbsp;&nbsp;**\<psd/>**                                          | Содержит параметры для определения режима работы оборудования на основании спектральной плотности мощности. |
| &nbsp;&nbsp;&nbsp;&nbsp;*enable*                                 | Включение/отключение метода. |
| &nbsp;&nbsp;&nbsp;&nbsp;*filterOrder*                            | Порядок фильтра линейного предсказания. |
| &nbsp;&nbsp;&nbsp;&nbsp;*evaluationPointsNumber*                 | Количество оцениваемых точек спектральной плотности мощности. |
| &nbsp;&nbsp;&nbsp;&nbsp;*correlationThreshold*                   | Порог корреляции спектральной плотности мощности для одинаковых режимов работы оборудования. |

&nbsp;

## <a name="frequencyCorrector">3.7. frequencyCorrector</a>

developers: *Kechik D., Aslamov Yu.*

&emsp;**frequencyCorrector** - class, combining a set of methods for specifying the shaft rotational speed.

```
<frequencyCorrector plotEnable="1" methodsEnbl="all" trustedInterval="0.7" goodThreshold="80" averageThreshold="35" conflictCloseness="0.2" plotAllShafts="1" shortWindow="1" crossValidationThresholds="40 70" description="Decision maker rules configs. Process using interference methods (methodsEnbl='interference'), interference and fuzzy (methodsEnbl='all'), all methods (methodsEnbl='all+hilbert'). The next fields are default config for all estimators." interpolationFactor="8" percentRange="1" percentStep="0.01" dfPercentAccuracy="0.01" nPeaks="5" minPeakHeight="6"  minPeakDistance="3" SortStr="descend" maxPeaksInResult="4" minOverMaximumThreshold="0.66" baseVal="0" minProbability = "33" minMagnitude="0.01">
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

| Name of the field                                     | Description |
|-------------------------------------------------------|-------------|
| *plotEnable*                                          |  |
| *methodsEnbl*                                         |  |
| *trustedInterval*                                     |  |
| *goodThreshold*                                       |  |
| *averageThreshold*                                    |  |
| *conflictCloseness*                                   |  |
| *crossValidationThresholds*                           |  |
| *shortWindow*                                         |  |
| *plotAllShafts*                                       |  |
| &nbsp;&nbsp;**\<displacementInterferenceEstimator/>** |  |
| &nbsp;&nbsp;**\<spectralBeamEstimator/>**             |  |
| &nbsp;&nbsp;**\<interferenceFrequencyEstimator/>**    |  |
| &nbsp;&nbsp;**\<fuzzyFrequencyEstimator/>**           |  |
| &nbsp;&nbsp;**\<hilbertFrequencyEstimator/>**         |  |

&nbsp;

## <a name="shaftTrajectoryDetection">3.8. shaftTrajectoryDetection</a>

developers: *Kechik D.*

&emsp;**shaftTrajectoryDetection** - class, designed to extract from a two-channel signal the shafts vibration in two planes, the construction, averaging and analysis of their trajectory.

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

&emsp;**iso7919** - algorithm for estimating the metrics values in accordance with ISO 7919.

```
<iso7919 standardPart="" standardPartDeterminationEnable="1"/>
```
Picture 3.9.1. - Writing format in config.xml of settings **\<iso7919/>**

&nbsp;

Table 3.9.1. - **\<iso7919/>** structure

| Name of the field                 | Description |
|-----------------------------------|-------------|
| *standardPart*                    | The part of ISO 7919. (`empty`, `2`, `3`, `4`, `5`) |
| *standardPartDeterminationEnable* | Enable/disable the determination of the part of ISO 7919 (`0`, `1`) |

&nbsp;

## <a name="frequencyDomainClassifier">3.10. frequencyDomainClassifier</a>

developers: *Aslamov Yu., Kosmach N., Riabtsev P.*

&emsp;**frequencyDomainClassifier** - classifier in the frequency domain.

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
| *enoughtPlotWekness*                              | Enough percent for display defects |
| &nbsp;&nbsp;**\<peakComparison/>**                | Выбор диапазона поиска пиков в частотной области. |
| &nbsp;&nbsp;&nbsp;&nbsp;*includeEnergyPeaks*      | Включать в анализ и энергетические пики. |
| &nbsp;&nbsp;&nbsp;&nbsp;*modeFunction*            | Включить режим в котором выбор диапазона определяется по формуле: *(0.03√(x/a))/x*, где x - частота искомого пика, a - коэффициент крутизны, задаваемый  *coefficientModeFunction*. |
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
| *harmonicsTwiceLineFreq* | !!!!В примере harmomicsTwiceLineFreq!!!!Вектор гармоник частот второй линейной частоты генератора. При указании вектора используется запись A:B:C, где A - начальное значение, B - шаг, C - конечное значение. |

&nbsp;

## <a name="scalogramHandler">3.11. scalogramHandler</a>

developers: *Aslamov Yu., Tsurko Al., Kechik D., Aslamov A.*

&emsp;**scalogramHandler** - class combining a set of methods for constructing and analyzing a sсalogram.

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
Picture 3.11.1. - Writing format in config.xml of settings **\<scalogramHandler/>**

&nbsp;

Table 3.11.1. - **\<scalogramHandler/>** structure

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

&nbsp;

Table 3.11.7. - **\<energyEstimation/>** structure for **\<swdScalogram/>** and **\<normalizedScalogram/>**

| Name of the field                                                | Description |
|------------------------------------------------------------------|-------------|
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

&emsp;**periodicityProcessing** - a set of algorithms for searching periodicity in the time domain with an estimate of the validity of their definition.

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

&emsp;**timeDomainClassifier** - a set of algorithms for the classification of shock processes templates in the time domain. Contains a set of algorithms for segmentation, clustering and classification.

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

&emsp;**timeFrequencyDomainClassifier** - a set of algorithms for detecting equipment defects. The operating principle: based on the scalogram the optimal filtering is performed then a frequency classifier (**\<frequencyDomainClassifier/>**) ​​is applied to the filtered signals.

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

&nbsp;

## <a name="spm">3.15. spm</a>

developers: *Aslamov Yu., Kosmach N.*

&emsp;**spm** - shock pulse method searches for two levels in the time domain of the vibration acceleration signal. The levels of the highest and average pulses, depending on the method, are determined in different ways.

```
<spm filterType="BPF" lowFreq="2500" highFreq="20000" Rp="1" Rs="10" description="" >
	<shortSignal  plotEnable="0" type='multi' description="Cut-off the original signal and form the shortened one from one @mono piece or several @multi pieces">
		<mono startSecond="0" lengthSeconds="5"/>
		<multi framesNumber="10" secondsPerFrame="0.5"/>
	</shortSignal>
	<spmDBmDBc processingEnable="1" plotEnable="1" warningLevel="20" damageLevel="30" peakCntPerSecondRequired="200" accurate="0.05" distance="20" numberThresh="12"/>
	<spmLRHR processingEnable="1" plotEnable="1" warningLevel="" damageLevel="" meanOfPeakCountLr="40" peakCntPerSecondRequiredHr="1000" distance="20" numberThresh="12" accurate="0.05"/>
</spm>
```
Picture 3.15.1. - Writing format in config.xml of settings **\<spm/>**

&nbsp;

Table 3.15.1. - **\<spm/>** structure

| Name of the field               | Description |
|---------------------------------|-------------|
| *filterType*                    | Тип фильтра, возможны варианты: `BPF`, `HPF`, `LPF`. В связи с особенностями метода используется `BPF`. |
| *lowFreq*                       | Нижняя частота пропускания фильтра. |
| *highFreq*                      | Верхняя частота пропускания фильтра. |
| *Rp*                            | Диапазон пульсации в полосе пропускания. [дБ] |
| *Rs*                            | Разница между полосой задержки и полосой пропускания. [дБ] |
| &nbsp;&nbsp;**\<shortSignal/>** |  |
| &nbsp;&nbsp;**\<spmDBmDBc/>**   | Метод, верхний уровень которого определяется как второй по величине импульс. Нижний определяется как уровень, на котором регистрируется 200 пиков в секунду. Полученные уровни переводятся в дБ относительно скз первого сигнала. |
| &nbsp;&nbsp;**\<spmLRHR/>**     | Метод, верхний уровень которого определяется как 40 наибольших импульсов в сигнале. Нижний определяется как уровень, на котором регистрируется 1000 пиков в секунду. |

&nbsp;

Table 3.15.2. - **\<spmDBmDBc/>** structure

| Name of the field          | Description |
|----------------------------|-------------|
| *processingEnable*         | Включить/отключить метод. |
| *plotEnable*               | Включить/отключить отрисовку метода. |
| *warningLevel*             | Ручное выставление порога для “коврового уровня”. |
| *damageLevel*              | Ручное выставление порога для “максимального уровня”. |
| *peakCntPerSecondRequired* | Требуемое количество пиков в секунду. |
| *accurate*                 | Точно для определения требуемого количества пиков в секунду. (Диапазон: от `0` до `1`). |
| *distance*                 | Минимальная дистанция между импульсами в сигнале. |
| *numberThresh*             | Количество уровней в сетке для поиска требуемых пиков. |

&nbsp;

Table 3.15.3. - **\<spmLRHR/>** structure

| Name of the field          | Description |
|----------------------------|-------------|
| *processingEnable*         | Включить/отключить метод. |
| *plotEnable*               | Включить/отключить отрисовку метода. |
| *warningLevel*             | Ручное выставление порога для “коврового уровня”. |
| *damageLevel*              | Ручное выставление порога для “максимального уровня”. |
| *meanOfPeakCountLr*        | Количество пиков для верхнего уровня. |
| *peakCntPerSecondRequired* | Требуемое количество пиков в секунду. |
| *accurate*                 | Точно для определения требуемого количества пиков в секунду. (Диапазон: от `0` до `1`). |
| *distance*                 | Минимальная дистанция между импульсами в сигнале. |
| *numberThresh*             | Количество уровней в сетке для поиска требуемых пиков. |

&nbsp;

## <a name="iso15242">3.16. iso15242</a>

developers: *Aslamov Yu., Kosmach N.*

&emsp;**iso15242** - method implemented according to the standard ISO15242. The vibration velocity signal is filtered by three bandpass filters in the specified ranges and for each signal the RMS is calculated. Further with respect to the nominal value, the received VHFs are translated into dB. The thresholds are set for the results obtained in dB.

```
<iso15242 plotEnable="1" sensitivity="0.016" damageLevel="" warningLevel="" timeInterval="5" Rp="0.1" Rs="20" F_Low="50" F_Med1="300" F_Med2="1800" F_High="10000" v_rms_nominal="0.05e-6"/>
```
Picture 3.16.1. - Writing format in config.xml of settings **\<iso15242/>**

&nbsp;

Table 3.16.1. - **\<iso15242/>** structure

| Name of the field | Description |
|-------------------|-------------|
| *plotEnable*      | Включить/отключить отрисовку метода. |
| *sensitivity*     | Коэффициент чувствительности сигнала. |
| *damageLevel*     | Порог для красного уровня опасности. [дБ] |
| *warningLevel*    | Порог для желтого уровня опасности. [дБ] |
| *timeInterval*    | Интервал для анализа сигнала. [сек] |
| *Rp*              | Диапазон пульсации в полосе пропускания. [дБ] |
| *Rs*              | Разница между полосой задержки и полосой пропускания. [дБ] |
| *F_Low*           | Нижняя граница полосы пропускания для первого фильтра.  |
| *F_Med1*          | Верхняя граница полосы пропускания для первого фильтра и нижняя граница пропускания для второго фильтра. |
| *F_Med2*          | Верхняя граница полосы пропускания для второго фильтра и нижняя граница пропускания для третьего фильтра. |
| *F_High*          | Верхняя граница полосы пропускания для третьего фильтра. |
| *v_rms_nominal*   | Номинальный уровень, относительно которого вычисляются дБ. Уровень в мм/с. |

&nbsp;

## <a name="octaveSpectrum">3.17. octaveSpectrum</a>

developers: *Aslamov Yu., Kosmach N., Riabtsev P.*

&emsp;**octaveSpectrum** - method allows to break up the spectrum into sets of bands and monitor the growth of each band.

```
<octaveSpectrum plotEnable="1" correctionEnable="1" lowFrequency="16" highFrequency="16000" filterMode="1/3 octave" roundingEnable="1" warningLevel="" damageLevel="" description=""/>
```
Picture 3.17.1. - Writing format in config.xml of settings **\<octaveSpectrum/>**

&nbsp;

Table 3.17.1. - **\<octaveSpectrum/>** structure

| Name of the field  | Description |
|--------------------|-------------|
| *plotEnable*       | Разрешить отрисовку изображений. |
| *correctionEnable* | Enable/disable the octave sjpectrum correction by the frequency deviation. |
| *lowFrequency*     | Нижняя (стартовая) частота. |
| *highFrequency*    | Верхняя (конечная) частота. |
| *filterMode*       | Тип октавного спектра (`1 octave`, `1/3 octave`, `1/6 octave`). |
| *roundingEnable*   | Разрешить округление частот до 2^n (по умолчанию `1`). |
| *warningLevel*     | Набор порогов среднего уровня. |
| *damageLevel*      | Набор порогов среднего уровня. |

&nbsp;

## <a name="decisionMaker">3.18. decisionMaker</a>

developers: *Aslamov Yu., Kosmach N.*

&emsp;**decisionMaker** - a decision-making device based on several methods. Works with history turned on and off.

```
<decisionMaker>
	<peakComparison modeFunction="1" coefficientModeFunction="0.09" percentRange="0" freqRange="0.3" description="for function modeFunction=1"/>
	<decisionMaker processingEnable="1" enoughFrequencyClassifiers="0.3" enoughPeriodicity="0.3" enoughIso7919="0.5" enoughShaftTrajectory="0.5" enoughWithClassifiers="0" enoughTimeDomain="0.5" contributionTimeDomain="0.4" description="contributionTimeDomain - contribution in status of timeDomain, range [0:1]; enoughPeriodicity, enoughFrequiencyDomain, enoughTimeDomain: include methods in status if more then this variables, range [0:1]"/>
	<decisionMakerHistory plotEnable="1" processingEnable="1" dangerThresholds="25 50 75" enoughFrequencyClassifiers="0.25" enoughHistorySimilarity="0.05" enoughWithClassifiers="0" enoughMetrics="0.5" enoughSpmLRHR="0.5" enoughOctaveSpectrum="0.5" enoughIso15242="0.5" enoughIso7919="0.5" enoughShaftTrajectory="0.5" enoughScalogram="2" enoughTimeDomain="0.5" contributionTimeDomain="0.2" contributionPeriodicity="0.1" description=" contridutionPeriodicity - contribution periodicity to unknown defect"/>
</decisionMaker> 
```
Picture 3.18.1. - Writing format in config.xml of settings **\<decisionMaker/>**

&nbsp;

&emsp;The **\<peakComparison/>** structure is described into the [frequencyDomainClassifier](#frequencyDomainClassifier) section.

Table 3.18.1. - **\<decisionMaker/>** structure

| Name of the field            | Description |
|------------------------------|-------------|
| *processingEnable*           | Включить/отключить устройство принятия решений по однократному измерению. |
| *enoughFrequencyClassifiers* | Процент достаточной валидности для метода *frequencyClassfier* и *timeFrequencyClassfier*. (Диапазон: от `0` до `1`). |
| *enoughPeriodicity*          | Процент валидности в *periodicity*, который достаточен для включения его в анализ дефектов. (Диапазон: от `0` до `1`). |
| *enoughIso7919*              | Порог для принятия решения по данному методу. Ниже этого значения статус метода не оценивается. |
| *enoughShaftTrajectory*      | Порог для принятия решения по данному методу. Ниже этого значения статус метода не оценивается. |
| *enoughWithClassifiers*      | Статус достаточной валидности дефектов после добавления всех дополнительных методов. (Диапазон: от `0` до `1`). |
| *enoughTimeDomain*           | Процент валидности в timeDomainClassifier, который достаточен для включения его в анализ дефектов. (Диапазон: от `0` до `1`). |
| *contributionTimeDomain*     | Процент влияния timeDomainClassifier на статус дефекта. |

&nbsp;

Table 3.18.2. - **\<decisionMakerHistory/>** structure

| Name of the field            | Description |
|------------------------------|-------------|
| *plotEnable*                 | Включить/отключить отображение статусов дефектов. |
| *processingEnable*           | Включить/отключить устройство принятия решений по многократным измерения. |
| *dangerThresholds*           | Пороги для отрисовки уровней опасности в истории. Рекомендуемые значения: `25 50 75`. |
| *enoughFrequencyClassifiers* | Процент достаточной валидности для метода *frequencyClassfier* и *timeFrequencyClassfier*. (Диапазон: от `0` до `1`). |
| *enoughHistorySimilarity*    | Enough history similarity for include defect to processing of decision maker (Range from 0 to 1) |
| *enoughWithClassifiers*      | Статус достаточной валидности дефектов после добавления всех дополнительных методов. (Диапазон: от `0` до `1`). |
| *enoughMetrics*              | Статус в единицах, который достаточен для включения метрики в анализ дефектов. (Диапазон: от `0` до `1`). |
| *enoughSpmLRHR*              | Статус в единицах, который достаточен для включения метода в анализ дефектов. (Диапазон: от `0` до `1`). |
| *enoughOctaveSpectrum*       | Статус в единицах, который достаточен для включения метода в анализ дефектов. (Диапазон: от `0` до `1`). |
| *enoughIso15242*             | Статус в единицах, который достаточен для включения метода в анализ дефектов. (Диапазон: от `0` до `1`). |
| *enoughIso7919*              |  |
| *enoughShaftTrajectory*      |  |
| *enoughScalogram*            | Статус в единицах, который достаточен для включения метода в анализ дефектов. (Диапазон: от `0` до `1`). |
| *enoughTimeDomain*           | Процент валидности в *timeDomainClassifier*, который достаточен для включения его в анализ дефектов. (Диапазон: от `0` до `1`). |
| *contributionTimeDomain*     | Процент влияния *timeDomainClassifier* на статус дефекта. |
| *contributionPeriodicity*    | Процент влияния *periodicity* для неизвестного дефекта. |

&nbsp;

## <a name="history">3.19. history</a>

developers: *Aslamov Yu., Kosmach N.*

&emsp;**history** - the history module is designed to evaluate defects on several files from one point of one equipment.

```
<history plotEnable="1" trainingPeriodEnable="1" trainingPeriod="5" minSampleNumber="3" trainingPeriodStartDate="13-10-2017" trainingPeriodLastDate="17-10-2017" compressionEnable="1" compressionPeriodTag="day" compressionPeriodNumber="1" compressionSkipPeriodNumber="2" percentOfLostHistoryFiles="3" stablePeriodStatus="3" percentStatusOfHistory="30" compressionLogEnable="1" dumpFileName="dumpFileHistory" versionMat="-v7"
		 trainingPeriodFormulaMin="abs(/medianMain/)*1.01 + abs(/stdAdditional/)*1.2" 
		 trainingPeriodFormulaAverage="abs(/medianMain/)*1.05 + abs(/stdAdditional/)*1.75" 
		 trainingPeriodFormulaMax="abs(/medianMain/)*1.1  + abs(/stdAdditional/)*2" 
		 description="to use functions for  formula: mean, std, median; coefficients are numeric; trainingPeriod >= (frameLength - frameOverlap)*2 + 1 , frameLength, frameOverlap - parameters intensivityHandler, compressionPeriodTag = day,hour,month">
	<intensivityHandler frameLength="3" frameOverlap="1"/>
	<trend enable="1" plotEnable="0" rmsAccuracyPrimary="15" rmsAccuracySecondary="25" slopesThreshold="3" meanDuration="4" signalVolatilityThreshold="30" approxVolatilityThreshold="20" segmentPeriod="6"/>
	<frequencyDomainHistoryHandler intensivityThreshold="0.3" notInitThresholdsCoeff="0.9" defaultTrainingPeriodMode="1" trainingPeriod="5" amplitudeModifierModeEnable="0" description="defaultTrainingPeriodMode - if set 0, to use trainingPeriod in frequencyDomainHistoryHandler"/>
	<periodicityHistoryHandler overlapPercent="0.7" percentageOfReange="0.25"  intensivityThreshold="0.3" percentRange="10"/>
	<timeFrequencyDomainHistoryHandler overlapPercent="0.7" percentageOfReange="0.25" discription="varibale overlapPercent, expansionPercent in value and range = [0 1]"/>
	<cepstrogramHistoryHandler percentRangeUnknownPeriods="1" frameLength="5" frameOverlap="1" intensivityThreshold="1"/>
	<timeSynchronousAveraging autoThresholdsEnable="0" intensivityThreshold="0.51" stablePeriodStatus="5"/>
</history>
```
Picture 3.19.1. - Writing format in config.xml of settings **\<history/>**

&nbsp;

Table 3.19.1. - **\<history/>** structure

| Name of the field                                     | Description |
|-------------------------------------------------------|-------------|
| *plotEnable*                                          | Включить/отключить отрисовку изображений истории. |
| *trainingPeriodEnable*                                | Включение/отключение самообучения по файлам истории. |
| *trainingPeriod*                                      | Количество отсчетов, в течении которых выставляются пороги (это значение не должно быть меньше чем *(frameLength - frameOverlap) × 2 + 1*, где *frameLength* и *frameOverlap* атрибуты поля **\<intensivityHandler/>** в config.xml). |
| *minSampleNumber*                                     | Минимальное количество отсчетов необходимое для работы истории. (Определяется минимальной длинной для работы тренда (значение `3`) меньше `3` ставить не рекомендуется)). |
| *trainingPeriodStartDate*                             | Время первого тренировочного отсчета. |
| *trainingPeriodLastDate*                              | Время последнего тренировочного отсчета. |
| *compressionEnable*                                   | Включение/отключение сжатия истории. |
| *compressionPeriodTag*                                | Метка для сжатия времени (есть 3 варианта: `day`, `hour`, `month`). |
| *compressionPeriodNumber*                             | Количество сжатых меток (Пример: 3 дня в один отсчет). |
| *compressionSkipPeriodNumber*                         | Количество отсчетов, которые можно пропустить без потери информации. |
| *percentOfLostHistoryFiles*                           | Процент потерянных отсчетов, которые можно аппроксимировать без существенной потери информации. Поля **\<file/>**, вложенные в поле **\<history/>** отвечают за имя файла (1.xml) и время записи файла wav – файла, с которого был создан *.xml. |
| *stablePeriodStatus*                                  | Количество стабильных отсчетов, после которых можно сказать, что текущий статус по порогу является проверенным. |
| *percentStatusOfHistory*                              | Процент статусов по порогам совпадающем с текущим статусом и позволяющий считать текущий статус проверенным. |
| *compressionLogEnable*                                | Включение/выключение записи в состояния в log. |
| *dumpFileName*                                        | Название дамп файла истории. (Нужен чтобы не держать в оперативной памяти все файлы истории). |
| *versionMat*                                          | Версия .mat файла для дамп файла. Рекомендованная версия 7 или 6. |
| *trainingPeriodFormulaMin*                            | Формула для определения нижнего порога после обучения. |
| *trainingPeriodFormulaAverage*                        | Формула для определения среднего порога после обучения. |
| *trainingPeriodFormulaMax*                            | Формула для определения верхнего порога после обучения. |
| &nbsp;&nbsp;**\<intensivityHandler/>**                | Класс для определения интенсивности величины. |
| &nbsp;&nbsp;**\<trend/>**                             | Класс для определения развития величины. |
| &nbsp;&nbsp;**\<frequencyDomainHistoryHandler/>**     | Класс для определения развития дефектов частотного классификатора. |
| &nbsp;&nbsp;**\<periodicityHistoryHandler/>**         | Класс для определения интенсивности появления в истории периодических составляющих. |
| &nbsp;&nbsp;**\<timeFrequencyDomainHistoryHandler/>** | Класс для определения развития дефектов частотного классификатора после оптимальной фильтрации. |
| &nbsp;&nbsp;**\<timeSynchronousAveraging/>**          | Класс для определения развития дефектов шестерней. |
| &nbsp;&nbsp;**\<cepstrogramHistoryHandler/>**         | Class to determine the intensity of spectral periodicities. |

&nbsp;

Table 3.19.2. - **\<intensivityHandler/>** structure

| Name of the field                                  | Description |
|----------------------------------------------------|-------------|
| <a name="frameLengthInterp"> *frameLength* </a>    | Длина анализируемого участка. |
| <a name="frameOverlapInterp">*frameOverlap* </a>   | Длина перекрытия между участками. |

&nbsp;

Table 3.19.3. - **\<trend/>** structure

| Name of the field           | Description |
|-----------------------------|-------------|
| *enable*                    | Включение/отключение анализа тренда. При выключенном состоянии результат тренда всегда равен 1.5 (соответствует состоянию “неизвестно”). |
| *plotEnable*                | Включить/выключить отрисовку класса. |
| *rmsAccuracyPrimary*        | Точность первичной аппроксимации отсчетов величины. |
| *rmsAccuracySecondary*      | Точность вторичной аппроксимации отсчетов величины. |
| *slopesThreshold*           | Пороговое количество линейных участков аппроксимации отсчетов величины. При превышении данного порога и *meanDuration* производится вычисление вторичной аппроксимации отсчетов величины. |
| *meanDuration*              | Пороговое значение средней длительности линейных участков аппроксимации, отсчетов. При превышении данного порога и *slopesThreshold* производится вычисление вторичной аппроксимации отсчетов величины. |
| *signalVolatilityThreshold* | Пороговое значение волатильности отсчетов величины. |
| *approxVolatilityThreshold* | Пороговое значение волатильности аппроксимации отсчетов величины. |
| *segmentPeriod*             | Длительность конечного сегмента величины, отсчетов. Волатильности сегмента и аппроксимации сегмента сравниваются с волатильностями всех отсчетов величины и аппроксимации отсчетов величины для принятия решения о вторичной аппроксимации. |

&nbsp;

Table 3.19.4. - **\<frequencyDomainHistoryHandler/>** structure

| Name of the field             | Description |
|-------------------------------|-------------|
| *intensivityThreshold*        | Порог для принятия решения об интенсивности появления пика. |
| *notInitThresholdsCoeff*      | Коэффициент регулирующий порог для пиков, которые появились не в обучающий период. |
| *trainingPeriod*              | Период обучения для пиков частотного классификатора. |
| *defaultTrainingPeriodMode*   | Включить/ отключить собственное выставление диапазона периода обучения (`1` - выставляется из общей истории, `0` - выставляется из **\<frequencyDomainHistoryHandler/>**.*trainingPeriod*) |
| *amplitudeModifierModeEnable* | Включить/отключить изменение амплитуды пиков во время периода обучения. |

&nbsp;

Table 3.19.5. - **\<periodicityHistoryHandler/>** structure

| Name of the field      | Description |
|------------------------|-------------|
| *intensivityThreshold* | Порог для принятия решения об интенсивности появления пика. |
| *percentRange*         | Максимальный процентное отклонение периодической частоты. Диапазон (от `0` до `100`). |
| *overlapPercent*       | Процент перекрытия пиков на скалограмме. |
| *percentageOfReange*   | Процент оставшейся части после вычета меньшего пика, должен не превышать значение *percentageOfReange*, в противном случае считаем диапазоны различными. |

&nbsp;

Table 3.19.6. - **\<timeFrequencyDomainHistoryHandler/>** structure

| Name of the field    | Description |
|----------------------|-------------|
| *overlapPercent*     | Процент перекрытия пиков на скалограмме. |
| *percentageOfReange* | Процент оставшейся части после вычета меньшего пика, должен не превышать значение *percentageOfReange*, в противном случае считаем диапазоны различными. |

&nbsp;

Table 3.19.7. - **\<timeSynchronousAveraging/>** structure

| Name of the field      | Description |
|------------------------|-------------|
| *autoThresholdsEnable* | Enable of auto determined of  thresholds. |
| *intensivityThreshold* | The threshold of the determination of stability ranges. |
| *stablePeriodStatus*   | The number of stable statuses in history for decision maker about the defect. |

&nbsp;

Table 3.19.8. - **\<cepstrogramHistoryHandler/>** structure

| Name of the field                      			| Description |
|---------------------------------------------------|-------------|
| *percentRangeUnknownPeriods*                      | Percent range for unknown spectral periods. |
| [*frameLength*](#frameLengthInterp)               |  |
| [*frameOverlap*](#frameOverlapInterp)             |  |
| *intensivityThreshold*                            | Intensivity threshold |

&nbsp;

## <a name="statusWriter">3.20. statusWriter</a>

developers: *Kosmach N.*

&emsp;**statusWriter** - module for writing data to the status.xml file and verifying the correctness of the written data.

```
<statusWriter nameTempStatusFile="temp"/>
```
Picture 3.20.1. - Writing format in config.xml of settings **\<statusWriter/>**

&nbsp;

Table 3.20.1. - **\<statusWriter/>** structure

| Name of the field    | Description |
|----------------------|-------------|
| *nameTempStatusFile* | Название временного статусного файла, после удачной обработки переименовывается в status.xml. |

&nbsp;

## <a name="frequencyTracking">3.21. frequencyTracking</a>

developers: *Aslamov Yu.*

&emsp;**frequencyTracking** - equipment frequencies tracking module, allows to resamble the signal according to the obtained law of frequency change. The oversampling provides the best quality of processing in the frequency domain.

```
<frequencyTracking plotEnable="1" trackTimeIntervalSec="0.1" typicalPercentDeviation="0.5" maxPercentDeviation="8" maxPercentDeviationPerSec="4" accuracyPercent="0.1" method="spectrogram" description="Implement frequency tracking in acceleration(type='acc'), acceleration envelope spectrum (type='env') or in both domains (type='acc+env') typicalPercentDeviation - [percents]">
	<spectrogramTracker type="acc+env" description="Frequency tracking method based on spectrogram with Logarithmic scale">
		<accTracker plotEnable="1" frequencyRange="4:16; 8:32; 16:64; 32:128; 256:1024" baseFramesNumber="3" maxInvalidPercent="40" frameLengthSample="5" frameOverlapSample="3"/>
		<envTracker plotEnable="1" frequencyRange="4:16; 8:32; 16:64; 32:128; 64:256" baseFramesNumber="3" maxInvalidPercent="40" frameLengthSample="5" frameOverlapSample="3"/>
		<logSpectrogram secPerFrame="5" secOverlap="4.5" secPerGrandFrame="32" />  
	</spectrogramTracker>
	<hilbertTracker type="acc+env" description="Frequency tracking method based on Hilbert Transform">
		<accTracker plotEnable="1" frequencies="" maxInvalidPercent="40"/>
		<envTracker plotEnable="1" frequencies="" maxInvalidPercent="40"/>
	</hilbertTracker>
	<resampling envelopeSpectrumRule="res+filt" resonantSpectrumRule="res+filt" scalogramRule="res+filt"/>
</frequencyTracking>
```
Picture 3.21.1. - Writing format in config.xml of settings **\<frequencyTracking/>**

&nbsp;

Table 3.21.1. - **\<frequencyTracking/>** structure

| Name of the field                              | Description |
|------------------------------------------------|-------------|
| *plotEnable*                                   | Разрешить отрисовку изображений. |
| *trackTimeIntervalSec*                         | Временнной шаг для трека частоты. [сек]  |
| *typicalPercentDeviation*                      | Стандартное отклонение частоты вала. [%] |
| *maxPercentDeviation*                          | Максимально возможное отклонение частоты. [%] |
| *maxPercentDeviationPerSec*                    | Максимально возможное отклонение частоты в секунду. [%] |
| *accuracyPercent*                              | Требуемая точность слежения за частотой. [%] |
| *method*                                       | Метод слежения за частотой (по умолчанию *method*=“`spectrogram`”). <br>`spectrogram` - метод слежения за частотой на основе логарифмической спектрограммы; <br>`hilbert` - метод слежения за частотой на основе оценки мгновенной частоты по Гильберту; <br>`spectrogram+hilbert` - комбинированный метод. |
| &nbsp;&nbsp;**\<spectrogramTracker/>**         | Метод слежения за частотой на основе логарифмической спектрограммы. |
| &nbsp;&nbsp;&nbsp;&nbsp;*type*                 | Тип алгоритма принятия решений (по умолчанию *type*="`acc+env`"): <br>`acc` - на основе спектрограммы виброускорения; <br>`env` - на основе спектрограммы огибающей виброускорения; <br>`acc+env` - совместный анализ `acc` и `env`. |
| &nbsp;&nbsp;&nbsp;&nbsp;**\<accTracker/>**     | Параметры метода слежения за частотой по спектру виброускорения. |
| &nbsp;&nbsp;&nbsp;&nbsp;**\<envTracker/>**     | Параметры метода слежения за частотой по спектру огибающей виброускорения. |
| &nbsp;&nbsp;&nbsp;&nbsp;**\<logSpectrogram/>** | Основные параметры построения спектрограммы (только для **\<spectrogramTracker/>**). |
| &nbsp;&nbsp;**\<hilbertTracker/>**             | Метод слежения за частотой на основе оценки мгновенной частоты по Гильберту. |
| &nbsp;&nbsp;&nbsp;&nbsp;**\<accTracker/>**     | Параметры метода слежения за частотой по спектру виброускорения. |
| &nbsp;&nbsp;&nbsp;&nbsp;**\<envTracker/>**     | Параметры метода слежения за частотой по спектру огибающей виброускорения. |

&nbsp;

Table 3.21.2. - **\<accTracker/>** **\<envTracker/>** structures for **\<spectrogramTracker/>**

| Name of the field    | Description |
|----------------------|-------------|
| *plotEnable*         | Разрешить отрисовку изображений. |
| *frequencyRange*     | Диапазоны частот для анализа в формате: `<Flow1>:<Fhigh1> ; … ; <FlowN>:<FhighN>`. Рекомендуется (по умолчанию) *frequencyRange*="`4:16; 8:32; 16:64; 32:128; 64:256`". |
| *baseFramesNumber*   | Количество кадров спектрограммы по которым производится оптимизация полученных законов изменения частоты (по умолчанию *baseFramesNumber*="`5`"). |
| *maxInvalidPercent*  | Максимально возможный процент интервалов времени, на которых слежение не возможно. |
| *frameLengthSample*  | Длина кадра траектории для оптимизации [отсчеты]. Рекомендуется *frameLengthSample* < 5. |
| *frameOverlapSample* | Длина перекрытия кадров траектории для оптимизации [отсчеты]. Рекомендуется: *frameOverlapSample > 0.5 × frameLengthSample*. |

&nbsp;

Table 3.21.3. - **\<logSpectrogram/>** structure for **\<spectrogramTracker/>**

| Name of the field  | Description |
|--------------------|-------------|
| *secPerFrame*      | Длина кадра, на которые разбивается сигнал при расчете спектрограммы. [сек] |
| *secOverlap*       | Длина перекрытия кадров для расчета спектрограммы [сек]. Рекомендуется :*secOverlap > ⅔ × secPerFrame*. |
| *secPerGrandFrame* | Длина “больших” кадров, на который разбивается сигнал при построении спектрограммы, для оптимизации использования оперативной памяти. |

&nbsp;

Table 3.21.4. - **\<accTracker/>** **\<envTracker/>** structures for **\<hilbertTracker/>**

| Name of the field   | Description |
|---------------------|-------------|
| *plotEnable*        | Разрешить отрисовку изображений. |
| *frequencies*       | Выраженные амплитудно частоты (точные) для трекинг частоты *frequencies*="`16.25; 32.5`". |
| *maxInvalidPercent* | Максимально возможный процент интервалов времени, на которых слежение не возможно (имеются значительные флуктуации). |

&nbsp;

## <a name="timeSynchronousAveraging">3.22. timeSynchronousAveraging</a>

developers: *Kosmach N.*

&emsp;**timeSynchronousAveraging** - the method allows to estimate the gearing based on the time averaging of the signal.

```
<timeSynchronousAveraging plotEnable="1" plotEnableAll="0" processingType="env+acc" numberMainPeaks="6" numberSideBandPeaks="3" limitSpectrumInShaftHarmonics="5" framesThreshold="104" degreeThreshold="3" deviationThresholdAcc="25" deviationThresholdEnv="50" lineCoef="150,25" maxFrequencyBPF="10" minFrequencyBPF="1" Rp="1" Rs="20" minAnalysisFrequency="1" filtrationType="cheby" medianDeviation="0.5" description="filtrationType = [cheby || peakTable]; degreeThreshold = [degree, radian range(0:3.14)]; framesThreshold - minimum frames number for averaging; processingType = [env || acc || env+acc]; minFrequencyBPF, maxFrequencyBPF, minAnalysisFrequency - [Hz] " >
	<peakComparison modeFunction="1" coefficientModeFunction="0.09" percentRange="6" freqRange="0" description="for function modeFunction=1"/>
	<logSpectrum plotEnable="0" enableEnergyPeakFinder="0"/>
</timeSynchronousAveraging>
```
Picture 3.22.1. - Writing format in config.xml of settings **\<timeSynchronousAveraging/>**

&nbsp;

Table 3.22.1. - **\<timeSynchronousAveraging/>** structure

| Name of the field                  | Description |
|------------------------------------|-------------|
| *plotEnable*                       | Разрешить отрисовку изображений. |
| *plotEnableAll*                    | Разрешить отрисовку изображений всех изображений. |
| *processingType*                   | Type of processing (”`env`”, ”`acc`”, ”`env+acc`”) |
| *numberMainPeaks*                  | Количество анализируемых гармоник зубчатой передачи. |
| *numberSideBandPeaks*              | Диапазон фильтрации около зубчатой гармоники (в количестве валовых компонент для одной стороны спектра относительно зубчатой частоты). |
| *limitSpectrumInShaftHarmonics*    | Диапазон отображения спектра огибающей (в количестве валовых компонент). |
| *framesThreshold*                  | Minimum number of frames for averaging |
| *deviationThresholdAcc*            | If mean(average signal)/mean(filtered signal) > *deviationThresholdAcc*, validation status  is true. |
| *deviationThresholdEnv*            | If (Difference between first samples and end samples of average signal)/mean(average signal) > *deviationThresholdEnv*, validation status  is true. |
| *lineCoef*                         | Коэффициенты уравнения прямой линии, по которой выставляется статус для диапазона (*lineCoef*=”`a,b`” *status = a × коэффициент модуляции + b* ). |
| *maxFrequencyBPF*                  | Minimum upper frequency of bandpass filtration. |
| *minFrequencyBPF*                  | Minimum lower frequency of bandpass filtration. |
| *Rp*                               | Допустимый уровень пульсаций в полосе пропускания. [дБ] |
| *Rs*                               | Требуемый уровень ослабления в полосе подавления. [дБ] |
| *minAnalysisFrequency*             | Minimum possible frequency of filtration for method processing. |
| *filtrationType*                   | Type of filtration (”`cheby`” or ”`peakTable`”) |
| *medianDeviation*                  | Deviation for validation of instantaneous phase. The recommended value is 0.5. |
| *meanMode*                  		 | Enable validation  GM mode (Exclude GM harmonic from processing, that below mean( all expressed harmonics (peakTable) )). |
| *degreeThreshold*           		 | Degree threshold for determining of strob-impulses.(rad) (range [0:pi]) |
| &nbsp;&nbsp;**\<peakComparison/>** | Поле описано в [frequencyDomainClassifier](#frequencyDomainClassifier). |
| &nbsp;&nbsp;**\<logSpectrum/>**    | Поле описано в [spectra](#spectra). |

&nbsp;

## <a name="checkSignalSymmetry">3.23. checkSignalSymmetry</a>

developers: *Kosmach N.*

&emsp;The result of the **checkSignalSymmetry** method is the detection of the signal state. Based on the results of the method, it is possible to determine the correctness of the removal point.

```
<checkSignalSymmetry threshold="0.06" description="Best value 0.05, more signal is dissymmetrical (experimental value)"/>
```
Picture 3.23.1. - Writing format in config.xml of settings **\<checkSignalSymmetry/>**

&nbsp;

Table 3.23.1. - **\<checkSignalSymmetry/>** structure

| Name of the field | Description |
|-------------------|-------------|
| *threshold*       | Порог выше которого сигнал считается несимметричным. Из этого следует, что нужно выбрать другую точку съема. |

&nbsp;

## <a name="bearingsParametersRefinement">3.24. bearingsParametersRefinement</a>

developers: *Kosmach N.*

&emsp;**bearingsParametersRefinement** - the method allows to adjust the bearing parameter from the envelope spectrum.

```
<bearingsParametersRefinement plotEnable="1" scalogramDataSource="wideBand" SSDThreshold="0.1" kurtosisThreshold="5" enoughBearingFrequenciesPercent="40" validLogLevel="3" autoPercentRangeEnable="1" coeffMinimumDeviation="6" deviationSumAmpl="0.7" positionBSF="1 2; 2 3; 2 4" positionOther="1 2; 1 3" accelerationEnable="1" accelerationStepFactor="4" roughPeaksNumbersThreshold="7" coefAutoPercentRange="3" confidenceDeviation="0.8" numberShaftPeaksFind="40" description="scalogramDataSource=(wideBand, scalogram, SSD, scalogram+resonance, SSD+resonance, resonance);  coefAutoPercentRange from 1 to 0.5, optimal was 0.55; coeffMinimumDeviation - minum ragne for peak comparison : coeffMinimumDeviation*df. confidenceDeviation - coeff, for check all peaks in refinement">
	<ballDiameter percentStep="0.05" deviationPercent="3.5" allowablePercentOfDeviation="0.3" nearestPercentEvaluation="0.3" description="nearestPercentEvaluation not less allowablePercentOfDeviation"/>
	<angle processingEnable="1" minAngleFactor="10" cosPercentStep="0.4" cosDeviationPercent="3" evaluateStepsNumberOfBd="2"/>
	<peakComparison includeEnergyPeaks="0" modeFunction="1" coefficientModeFunction="0.09" percentRange="0" freqRange="0" description="for function modeFunction=1"/>
	<filtering type="wavelet" description="type = 'bpf'(bandPass filtering) OR 'wavelet'(continuous wavelet transform)">
		<bpf Rp="1" Rs="10"/>
		<wavelet waveletName="swd_morl1" description="waveletName = 'swd_morl1'/'swd_morl2'/'swd_morl4'/'swd_morl8'"/>
	</filtering>
</bearingsParametersRefinement>
```
Picture 3.24.1. - Writing format in config.xml of settings **\<bearingsParametersRefinement/>**

&nbsp;

Table 3.24.1. - **\<bearingsParametersRefinement/>** structure

| Name of the field                         | Description |
|-------------------------------------------|-------------|
| *plotEnable*                              | Разрешить отрисовку изображений. |
| *enoughBearingFrequenciesPercent*         | Процент достаточного количества подшипниковых частот (не валовых) в спектре для возможности уточнения параметров. |
| *autoPercentRangeEnable*                  | Включить автоматическое выставления диапазона для поиска пиков в спектральном классификаторе. |
| *coefAutoPercentRange*                    | Включить коэффициент корректировки для автоматического выставления диапазонов. (Рекомендованное значение `0.55`) |
| *numberShaftPeaksFind*                    | Количество искомых гармоник для дефекта “бой вала”. В спектре возможно большое количества гармоник вала, и возможны наложения валовых гармоник подшипниковых. |
| *coeffMinimumDeviation*                   | Для выбора наименьшего диапазона поиска пиков, вычисляется как *allowableFrequencyDeviation × df*, где df - шаг частоты в спектре. |
| *confidenceDeviation*                     | Отклонения количества пиков от максимального, которое считается допустимым и пики выше порога обрабатываются в уточнение параметров подшипников. |
| *deviationSumAmpl*                        | A threshold of deviation sum amplitude for validation of sum amplitudes curve. |
| *positionBSF*                             | Искомые позиции для BSF гармоник. |
| *positionOther*                           | Искомые позиции для остальных подшипниковых гармоник. |
| *accelerationEnable*                      | Enable of accelerated processing. |
| *accelerationStepFactor*                  | Parameters for accelerated processing. Multiplier for *ballDiameter/percentStep* for rough search. |
| *roughPeaksNumbersThreshold*              | Parameters for accelerated processing. A threshold for finding a domain for accurate processing. |
| *scalogramDataSource*              		| Источник данных о частотных областнях. Возможные варианты: `scalogram` - данные получены на основе анализа выраженных областей скейлограммы, `SSD` - данные получены на основе разреженной декомпозиции скейлограммы, `wideBand` - данные установленные для широкополосного анализа, `resonance` - данные основанные на информации резонанса датчика,`SSD+resonance`, `scalogram+resonance`. |
| *SSDThreshold*              				| Порог валидности частотных областей по критерию энергетического вклада. (0<`SSDThreshold`<1) |
| *kurtosisThreshold*              			| A threshold of kurtosis value for evaluating bearing's domain. |
| *validLogLevel*              				| The threshold of peaks in spectrum for analysis of bearings parameters refinement. |
| &nbsp;&nbsp;**\<ballDiameter/>**          | Параметры для создания вектора различных диаметров шариков, для нахождения пиков. |
| &nbsp;&nbsp;**\<peakComparison/>**        | Поле описано в [frequencyDomainClassifier](#frequencyDomainClassifier). |
| &nbsp;&nbsp;**\<filtering/>**        		| Поле описано в [timeFrequencyDomainClassifier](#timeFrequencyDomainClassifier). |

&nbsp;

Table 3.24.2. - **\<ballDiameter/>** structure

| Name of the field             | Description |
|-------------------------------|-------------|
| *percentStep*                 | Процентный шаг для создания вектора диаметров шарика подшипника. |
| *deviationPercent*            | Максимальное процентное отклонение диаметра шарика. |
| *allowablePercentOfDeviation* | Максимально допустимое отклонение диаметра подшипника. Отклонения меньше данного значения, считается нормой для шарика. |
| *nearestPercentEvaluation*    | Процент в котором ищется максимально количества пиков в случае отсутствия выраженных пиков в искомом векторе. |

&nbsp;

Table 3.24.3. - **\<angle/>** structure

| Name of the field             | Description |
|-------------------------------|-------------|
| *processingEnable*            | Enabling of evaluation of ball diameter and angle. |
| *minAngleFactor*              | Factor of influence angle to deviation frequencies. |
| *cosPercentStep* 			    | Percent step for cos(alfa). |
| *cosDeviationPercent*    	    | Max deviation of cos(alfa). |
| *evaluateStepsNumberOfBd*     | Tolerance of creating surface of ball diameter and angle. |

&nbsp;

## <a name="preprocessing">3.25. preprocessing</a>

developers: *Aslamov Yu.*

&emsp;**preprocessing** - a set of methods for preliminary processing of vibration signals (filtration, decimation, phase cross-linking) to improve the stability and quality of post-processing.

```
<preprocessing description="">
	<decimation processingEnable="0" plotEnable="1" decimationFactor="2"/>
	<adaptiveNoiseFiltering processingEnable="0" plotEnable="1" filteringType="accurate" description=" filteringType = ACCURATE - noise cut-off curve is accurate match of the spectrum envelope curve; ROUGH - noise cut-off curve is close to the straight line"/>
	<piecewisePhaseAlignment processingEnable="1" plotEnable="1" framesNumber="" centralFrequency="" waveletName="swd_morl8" maxPercentDeviation="3" description="Enable phase alignment between fragments of piecewise-discontinuous signal (e.g. merged SKF signals)"/>
</preprocessing>
```
Picture 3.25.1. - Writing format in config.xml of settings **\<preprocessing/>**

&nbsp;

Table 3.25.1. - **\<preprocessing/>** structure

| Name of the field               | Description |
|---------------------------------|-------------|
| **\<decimation/>**              |  |
| &nbsp;&nbsp;*processingEnable*  |  |
| &nbsp;&nbsp;*plotEnable*        |  |
| &nbsp;&nbsp;*decimationFactor*  |  |
| **\<adaptiveNoiseFiltering/>**  |  |
| &nbsp;&nbsp;*processingEnable*  |  |
| &nbsp;&nbsp;*plotEnable*        |  |
| &nbsp;&nbsp;*filteringType*     |  |
| **\<piecewisePhaseAlignment/>** | Метод выравнивания фазы в пределах сигнала, составленного из фрагментов, снятых в различные моменты времени (с различным набегом фазы). |

&nbsp;

Table 3.25.2. - **\<piecewisePhaseAlignment/>** structure

| Name of the field     | Description |
|-----------------------|-------------|
| *processingEnable*    |  |
| *plotEnable*          | Разрешить отрисовку изображений. |
| *framesNumber*        | Количество равных(!) фрагментов, из которых состоит вибрационных сигнал. |
| *centralFrequency*    | Центральная частота, относительно которой производится выравнивание фазы (в большинстве случаев следует выбирать частоту вращения основного вала). |
| *waveletName*         | Тип вейвлета для узкополосной фильтрации (`swd_morl1`, `swd_morl2`, `swd_morl4`, `swd_morl8`, `swd_morl16`, `swd_morl32`). По умолчанию: `swd_morl8` |
| *maxPercentDeviation* | Максимально возможное отклонение *centralFrequency*, вследствие скачка фазы (по умолчанию *maxPercentDeviation*="`3`") |

&nbsp;

## <a name="packetWaveletTransform">3.26. packetWaveletTransform</a>

developers: *Rachkovsky T.*

&emsp;**packetWaveletTransform** - method decomposes the signal into nodes, from each of which a certain metric is calculated.

```
<pwt level="6" range="one" wname="dmey" entropy="sure" metricsNames="rms peak peak2peak peakFactor crestFactor kurtosis meanAbsoluteDeviation medianAbsoluteDeviation pearsonModeSkewness standardError power">
	<decimation decimationEnable="1"/>
	<crestFactor secPerFrame="0.05" secOverlapValue="0.02"/>
</pwt>
```
Picture 3.26.1. - Writing format in config.xml of settings **\<pwt/>**

&nbsp;

Table 3.26.1. - **\<pwt/>** structure

| Name of the field                         | Description |
|-------------------------------------------|-------------|
| *level*                                   | The number of the maximum decomposition level of PWT. |
| *range*                                   | Range of investigated decomposition levels: <br> `all`: from "0" to "level"; <br> `one`: only "level" |
| *wname*                                   | Name of mother wavelet for decomposition into nodes. Default: `dmey`. |
| *entropy*                                 | The type of entropy for decomposition processing. Default: `sure` |
| *metricsNames*                            | Names of all needed metrics. Available names: `rms`, `peak`, `peak2peak`, `peakFactor`, `crestFactor`, `kurtosis`, `mean`, `besselsCorrection`, `centralMoment2`, `centralMoment3`, `centralMoment4`, `centralMoment5`, `centralMoment6`, `centralMoment7`, `centralMoment8`, `meanAbsoluteDeviation`, `medianAbsoluteDeviation`, `skewness`, `mostFrequentValue`, `pearsonModeSkewness`, `rawMoments`, `relativeStandardDeviation`, `standardError`, `power`. |
| &nbsp;&nbsp;**\<decimation/>**            | Pre-decimation of the signal to twice the resonant frequency of the sensor. Look field *resonantFrequency* in [sensors](#sensors). |
| &nbsp;&nbsp;**\<crestFactor/>**           | Advanced settings for `crestFactor` metric. Shows the arithmetic average value between all calculated peak factor values ​​in each frames. |
| &nbsp;&nbsp;&nbsp;&nbsp;*secPerFrame*     | The frame length into which the signal is broken when calculating the peak factor. [sec] |
| &nbsp;&nbsp;&nbsp;&nbsp;*secOverlapValue* | Frame overlap length for peak factor calculation. [sec] |

&nbsp;

## <a name="cepstrogram">3.27. cepstrogram</a>

developers: *Kosmach N. ,Aslamov Yu.*

&emsp;**cepstrogram** - Spectral periodicities are evaluated by cepstrogram method.

```
<cepstrogram plotEnable="1" baseFrequency="1" waveletNumberOnOctave="8" maxAnalysisFrequency="256" percentWindowForSparsity="13" foundHarmonicNumber="6" percentRangeForScheme="20" evaluateHarmonics="1 2" spectrumRange="1 1000" percentErrorWindow="3"/>
```
Picture 3.27.1. - Writing format in config.xml of settings **\<preprocessing/>**

&nbsp;

Table 3.27.1. - **\<cepstrogram/>** structure

| Name of the field               | Description |
|---------------------------------|-------------|
|*plotEnable*                     | Enabling of plotting. |
|*baseFrequency*                  | First frequency for processing. |
|*waveletNumberOnOctave*          | Wavelet number on octave. |
|*maxAnalysisFrequency*           | Max analysis frequency in processing calculate how 2^(ceil(log2(maxAnalysisFrequency/baseFrequency))) (Need for right wavelet number on octave). |
|*percentWindowForSparsity*       | Percent window for finding similar peaks on cepstrogramm. |
|*foundHarmonicNumber*            | Peaks number  for subtraction of cepstrogramm. |
|*percentRangeForScheme*          | Percent range for comparison of found spectral periodicities and defects frequencies of equipment. |
|*evaluateHarmonics*              | Harmonics numbers for comparison of spectral periodicities and defects frequencies of equipment. |
|*spectrumRange*                  | Spectrum range for wavelet transform, can be written several ranges (ex: `spectrumRange` = "1 1000; 500 3000") |
|*percentErrorWindow*             | The frequency deviation of neighbouring peaks at subtraction of target peak. |

&nbsp;
