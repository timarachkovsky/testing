Исходные документы:  
[*[SPEC][1] Элементы*](http://example.com/)  
[*[SPEC][2] Дефекты*](http://example.com/)  
[*[API][1] Дефекты*](equipment%20Profile.xml.md)  

Specification.  
informativeTags.xml file format
====

*Editors: Aslamov Yu., Riabtsev P., Kosmach N.*  
*Date: 02-03-2018*  
*Version: 3.4.1*  
----
___

&emsp;Файл informativeTags.xml содержит информативные признаки дефектов оборудования и предназначен для настройки фреймворка.  
&emsp;Тег **\<equipmentStateDetection/>** содержит информативные признаки для определения режима работы оборудования. Содержит теги **\<metrics/>**, **\<octaveSpectrum/>**, **\<psd/>**.  
&emsp;Атрибут *weight* тегов **\<metrics/>**, **\<octaveSpectrum/>** и **\<psd/>** содержит весовой коэффициент соответствующего метода для принятия решения о состоянии оборудования.  
&emsp;Тег **\<data/>**, вложенный в тег **\<metrics/>**, содержит атрибуты *name*, *weight*. Атрибут *name* содержит названия метрик для вычислений. Атрибут *value* содержит весовые коэффициенты для принятия решения о состоянии оборудования, соответствующие приведенным названиям метрик.  

```
<equipmentStateDetection>
	<metrics weight="0.4">
		<data name="acceleration_rms acceleration_peak acceleration_peak2peak acceleration_noiseLog acceleration_envelopeNoiseLog acceleration_noiseLinear acceleration_envelopeNoiseLinear 
			  velocity_rms velocity_peak velocity_peak2peak velocity_noiseLog velocity_noiseLinear 
			  displacement_rms displacement_peak displacement_peak2peak displacement_noiseLog displacement_noiseLinear 
			  calculate_NPeaksSpec" weight="1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1"/>
	</metrics>
	<octaveSpectrum weight="0.5"/>
	<psd weight="0.6"/>
</equipmentStateDetection>
```

&nbsp;

&emsp;Каждый классификатор имеет свои классы элементов и каждый класс элемента имеет свои дефекты (см [*[SPEC][2] Дефекты*](http://example.com/)). Структура для всех классификаторов одинаковая. Взаимосвязь приведена в таблице 3. Для примера приведена структура **\<shaftClassifier/>**.  
&emsp;Тег **\<shaftClassifier/>**, содержит информативные признаки дефектов вала для настройки классификатора. Содержит тег **\<shaft/>**.  
&emsp;Тег **\<defect/>** содержит информативные признаки дефекта. Может содержит теги **\<periodicity/>**, **\<metrics/>**, **\<shaftTrajectory/>**, **\<iso7919/>**, **\<accelerationEnvelopeSpectrum/>**, **\<accelerationSpectrum/>**, **\<velocitySpectrum/>**, **\<displacementSpectrum/>**. При отсутствии какого-либо тега считаем, что данные метод обнаружения не используется при детектировании дефекта.  
&emsp;Значения атрибута *name* тега **\<defect/>** (название дефекта на jpg-изображений) изменяются в соответствии с текущим языком. На рисунке ниже приведен пример английской локализации.  

```
<shaftClassifier id="1">
	<shaft id="1">
		
		<defect id="1_1" name="Shaft Run-Out" tagName="SHAFT_RUN_OUT" enable="1">
			<periodicity>
				<data name="data" d="1"/>
				<weight name="weight" w="0.1"/>
				<tag name="tag" t="1 0"/>
				<mod name="modulation" m="0"/>
			</periodicity>
			
			<accelerationEnvelopeSpectrum weight="1" amplitudeModifier="1">
				<dataM name="main_data" d="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20"/>
				<weightM name="main_weight" w="0.3347 0.2367 0.1674 0.1183 0.0837 0.0592 0 0 0 0 0 0 0 0 0 0 0 0 0 0"/>
				<tagM name="main_tag" t="1 0"/>
				<modM name="main_modulation" m="0"/>
				<dataA name="additional_data" d="1 2 3 4 5 6"/>
				<weightA name="additional_weight" w="0.3347 0.2367 0.1674 0.1183 0.0837 0.0592"/>
				<tagA name="additional_tag" t="1 0"/>
				<modA name="additional_modulation" m="0"/>
			</accelerationEnvelopeSpectrum>
			
			<accelerationSpectrum weight="1" amplitudeModifier="1">
				<dataM name="main_data" d="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20"/>
				<weightM name="main_weight" w="0.3347 0.2367 0.1674 0.1183 0.0837 0.0592 0 0 0 0 0 0 0 0 0 0 0 0 0 0"/>
				<tagM name="main_tag" t="1 0"/>
				<modM name="main_modulation" m="0"/>
				<dataA name="additional_data" d="1 2 3 4 5 6"/>
				<weightA name="additional_weight" w="0.3347 0.2367 0.1674 0.1183 0.0837 0.0592"/>
				<tagA name="additional_tag" t="1 0"/>
				<modA name="additional_modulation" m="0"/>
			</accelerationSpectrum>
			
			<velocitySpectrum weight="1" amplitudeModifier="1" seriesBase="0.75" seriesDeviation="0.25">
				<dataM name="main_data" d="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20"/>
				<weightM name="main_weight" w="0.3347 0.2367 0.1674 0.1183 0.0837 0.0592 0 0 0 0 0 0 0 0 0 0 0 0 0 0"/>
				<tagM name="main_tag" t="1 0"/>
				<modM name="main_modulation" m="0"/>
				<dataA name="additional_data" d="1 2 3 4 5 6"/>
				<weightA name="additional_weight" w="0.3347 0.2367 0.1674 0.1183 0.0837 0.0592"/>
				<tagA name="additional_tag" t="1 0"/>
				<modA name="additional_modulation" m="0"/>
			</velocitySpectrum>
			
			<displacementSpectrum weight="1" amplitudeModifier="1" seriesBase="0.75" seriesDeviation="0.25">
				<dataM name="main_data" d="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20"/>
				<weightM name="main_weight" w="0.3347 0.2367 0.1674 0.1183 0.0837 0.0592 0 0 0 0 0 0 0 0 0 0 0 0 0 0"/>
				<tagM name="main_tag" t="1 0"/>
				<modM name="main_modulation" m="0"/>
				<dataA name="additional_data" d="1 2 3 4 5 6"/>
				<weightA name="additional_weight" w="0.3347 0.2367 0.1674 0.1183 0.0837 0.0592"/>
				<tagA name="additional_tag" t="1 0"/>
				<modA name="additional_modulation" m="0"/>
			</displacementSpectrum>
		</defect>
```

&nbsp;

&emsp;Тег **\<periodicity/>** содержит информативные признаки дефекта для настройки классификатора на основе поиска периодичностей в сигнале виброускорения. Пример структуры приведет ниже.  

```
<periodicity>
	<data name="data" d="1"/>
	<weight name="weight" w="0.1"/>
	<tag name="tag" t="1 0"/>
	<mod name="modulation" m="0"/>
</periodicity>
```

&nbsp;

Table 1. - **\<periodicity/>** structure

| Name of the field  | Description |
|--------------------|-------------|
| **\<data/>**       | Информация о множителях частот. |
| &nbsp;&nbsp;*name* | Полное название. |
| &nbsp;&nbsp;*d*    | Цифра множителя (В примере означает, что вектор искомых частот состоит только из первой гармоники). |
| **\<weight/>**     | Информация о вес искомых частот. |
| &nbsp;&nbsp;*name* | Полное название. |
| &nbsp;&nbsp;*w*    | Вес гармоник. [%] |
| **\<tag/>**        | Информация о метке частоты. |
| &nbsp;&nbsp;*name* | Полное название. |
| &nbsp;&nbsp;*t*    | Номер метки частоты (метки индивидуальны для каждой частоты). Содержит два числа для каждого вектора частот. Первое число указывает на главную гармоники, второе на модуляции. |
| **\<mod/>**        | Информация о модуляциях. |
| &nbsp;&nbsp;*name* | Полное название. |
| &nbsp;&nbsp;*m*    | Количество искомых модуляционных гармоник. |

&nbsp;

&emsp;Тег **\<accelerationEnvelopeSpectrum/>**, **\<accelerationSpectrum/>**, **\<velocitySpectrum/>**, **\<displacementSpectrum/>**  содержит информативные признаки дефекта в различных областях для настройки классификатора на основе спектров. Пример структуры приведет ниже.  

```
<accelerationEnvelopeSpectrum weight="1" amplitudeModifier="1">
	<dataM name="main_data" d="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20"/>
	<weightM name="main_weight" w="0.3347 0.2367 0.1674 0.1183 0.0837 0.0592 0 0 0 0 0 0 0 0 0 0 0 0 0 0"/>
	<tagM name="main_tag" t="1 0"/>
	<modM name="main_modulation" m="0"/>
	<dataA name="additional_data" d="1 2 3 4 5 6"/>
	<weightA name="additional_weight" w="0.3347 0.2367 0.1674 0.1183 0.0837 0.0592"/>
	<tagA name="additional_tag" t="1 0"/>
	<modA name="additional_modulation" m="0"/>
</accelerationEnvelopeSpectrum>

<accelerationSpectrum weight="1" amplitudeModifier="1">
	<dataM name="main_data" d="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20"/>
	<weightM name="main_weight" w="0.3347 0.2367 0.1674 0.1183 0.0837 0.0592 0 0 0 0 0 0 0 0 0 0 0 0 0 0"/>
	<tagM name="main_tag" t="1 0"/>
	<modM name="main_modulation" m="0"/>
	<dataA name="additional_data" d="1 2 3 4 5 6"/>
	<weightA name="additional_weight" w="0.3347 0.2367 0.1674 0.1183 0.0837 0.0592"/>
	<tagA name="additional_tag" t="1 0"/>
	<modA name="additional_modulation" m="0"/>
</accelerationSpectrum>

<velocitySpectrum weight="1" amplitudeModifier="1" seriesBase="0.75" seriesDeviation="0.25">
	<dataM name="main_data" d="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20"/>
	<weightM name="main_weight" w="0.3347 0.2367 0.1674 0.1183 0.0837 0.0592 0 0 0 0 0 0 0 0 0 0 0 0 0 0"/>
	<tagM name="main_tag" t="1 0"/>
	<modM name="main_modulation" m="0"/>
	<dataA name="additional_data" d="1 2 3 4 5 6"/>
	<weightA name="additional_weight" w="0.3347 0.2367 0.1674 0.1183 0.0837 0.0592"/>
	<tagA name="additional_tag" t="1 0"/>
	<modA name="additional_modulation" m="0"/>
</velocitySpectrum>

<displacementSpectrum weight="1" amplitudeModifier="1" seriesBase="0.75" seriesDeviation="0.25">
	<dataM name="main_data" d="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20"/>
	<weightM name="main_weight" w="0.3347 0.2367 0.1674 0.1183 0.0837 0.0592 0 0 0 0 0 0 0 0 0 0 0 0 0 0"/>
	<tagM name="main_tag" t="1 0"/>
	<modM name="main_modulation" m="0"/>
	<dataA name="additional_data" d="1 2 3 4 5 6"/>
	<weightA name="additional_weight" w="0.3347 0.2367 0.1674 0.1183 0.0837 0.0592"/>
	<tagA name="additional_tag" t="1 0"/>
	<modA name="additional_modulation" m="0"/>
</displacementSpectrum>
```

&nbsp;

Table 2. - **\<accelerationEnvelopeSpectrum/>** structure

| Name of the field   | Description |
|---------------------|-------------|
| *amplitudeModifier* | Поля для коэффициент амплитуды в период обучения для всей области. |
| *weight*            | Вес для обнаружения дефекта в области. |
| **\<dataM/>**       | Информация о множителях частот для классификатора по однократному измерению. |
| &nbsp;&nbsp;*name*  | Полное название. |
| &nbsp;&nbsp;*d*     | Цифра множителя (В примере означает, что вектор искомых частот состоит только из первой гармоники). |
| **\<weightM/>**     | Информация о вес искомых частот для классификатора по однократному измерению. |
| &nbsp;&nbsp;*name*  | Полное название. |
| &nbsp;&nbsp;*w*     | Вес гармоник. [%] |
| **\<tagM/>**        | Информация о метке частоты для классификатора по однократному измерению. |
| &nbsp;&nbsp;*name*  | Полное название. |
| &nbsp;&nbsp;*t*     | Номер метки частоты (метки индивидуальны для каждой частоты). Содержит два числа для каждого вектора частот. Первое число указывает на главную гармоники, второе на модуляции. |
| **\<modM/>**        | Информация о модуляциях для классификатора по однократному измерению. |
| &nbsp;&nbsp;*name*  | Полное название. |
| &nbsp;&nbsp;*m*     | Количество искомых модуляционных гармоник. |
| **\<dataA/>**       | Информация о множителях частот для классификатора по многократным измерения. |
| &nbsp;&nbsp;*name*  | Полное название. |
| &nbsp;&nbsp;*d*     | Цифра множителя (В примере означает, что вектор искомых частот состоит только из первой гармоники). |
| **\<weightA/>**     | Информация о вес искомых частот для классификатора по многократным измерения. |
| &nbsp;&nbsp;*name*  | Полное название. |
| &nbsp;&nbsp;*w*     | Вес гармоник. [%] |
| **\<tagA/>**        | Информация о метке частоты для классификатора по многократным измерения. |
| &nbsp;&nbsp;*name*  | Полное название. |
| &nbsp;&nbsp;*t*     | Номер метки частоты (метки индивидуальны для каждой частоты). Содержит два числа для каждого вектора частот. Первое число указывает на главную гармоники, второе на модуляции. |
| **\<modA/>**        | Информация о модуляциях для классификатора по многократным измерения. |
| &nbsp;&nbsp;*name*  | Полное название. |
| &nbsp;&nbsp;*m*     | Количество искомых модуляционных гармоник. |

\* *Теги **\<accelerationEnvelopeSpectrum/>**, **\<accelerationSpectrum/>**, **\<velocitySpectrum/>**, **\<displacementSpectrum/>** имеют идентичную структуру.*

&nbsp;

&emsp;Тег **\<shaftTrajectory/>** содержит информативные признаки дефекта для настройки классификатора на основе анализа траектории движения вала. Содержит тег **\<data/>**. Атрибут *weight* тега **\<data/>** содержит весовой коэффициент метода для принятия решения о степени дефекта.

```
<shaftTrajectory>
	<data name="shaftTrajectory" weight="0.5"/>
</shaftTrajectory>
```

&nbsp;

&emsp;Тег **\<iso7919/>** содержит информативные признаки дефекта для настройки классификатора на основе анализа метрик по ISO 7919. Содержит тег **\<data/>**. Атрибут *weight* тега **\<data/>** содержит весовой коэффициент метода для принятия решения о степени дефекта.

```
<iso7919>
	<data name="iso7919" weight="0.5"/>
</iso7919>
```

&nbsp;

&emsp;Тег **\<metrics/>** содержит набор метрик относящихся к дефекту. Содержит тег **\<data/>**.  
&emsp;Атрибут *name* тега **\<data/>** содержит названия метрик для вычислений. Атрибут *weight* тега **\<data/>** содержит весовые коэффициенты для добавления вероятности дефекта, соответствующие приведенным названиям метрик.

```
<metrics description="Examples of names(names of metrics to config.xml): metrics_acceleration_peak2peak, spmLRHR, iso15242 (if need special, iso15242_vRms1), octaveSpectrum(if need special octaveSpectrum_1000:2000), scalogram(if need special scalogram_0:end)">
	<data name="metrics_acceleration_envelopeNoiseLog" weight="-0.1"/>
</metrics>
```

&nbsp;

Table 3. - Отношения классификаторов к классам элементов

<table>
    <thead>
        <tr>
            <th>Name of the classifier</th>
            <th>Element classes <br> <em>(@elementClass)</em></th>
        </tr>
    </thead>
    <tbody>
        <tr>
          <td><b><em>shaftClassifier</em></b></td>
          <td><b><em>shaft</em></b></td>
        </tr>
        <tr>
          <td rowspan=2><b><em>bearingClassifier</em></b></td>
          <td><b><em>rollingBearing</em></b></td>
        </tr>
        <tr>
          <td><b><em>plainBearing</em></b></td>
        </tr>
		<tr>
          <td rowspan=5><b><em>connectionClassifier</em></b></td>
          <td><b><em>gearing</em></b></td>
        </tr>
		<tr>
          <td><b><em>planetaryStageGearbox</em></b></td>
        </tr>
		<tr>
          <td><b><em>smoothBelt</em></b></td>
        </tr>
		<tr>
          <td><b><em>toothedBelt</em></b></td>
        </tr>
		<tr>
          <td><b><em>coupling</em></b></td>
        </tr>
		<tr>
          <td rowspan=2><b><em>motorClassifier</em></b></td>
          <td><b><em>inductionMotor</em></b></td>
        </tr>
        <tr>
          <td><b><em>synchronousMotor</em></b></td>
        </tr>
		<tr>
          <td><b><em>fanClassifier</em></b></td>
          <td><b><em>fan</em></b></td>
        </tr>
    </tbody>
</table>

&nbsp;

Table 4. - Соотношение номера частоты к названию

| Frequency label | Abbreviation           | Denotation |
|:---------------:|------------------------|------------|
| 1               | shaftFreq              | Частота вращения вала. |
| 2               |                        | Энергонесущая. |
| 3               | twiceLineFreq          | Вторая линейная частота генератора. |
| 4               | barFreq                | Частота прохождения стержней ротора. |
| 5               | polePassFreq           | Частота прохождения пар полюсов. |
| 6               | collectorFrequency     | Частота прохождения пластин коллектора. |
| 7               | teethFrequencyArmature | Частота прохождения якоря. |
| 8               | brushFrequency         | Щеточная частота. |
| 9               | SCR                    | Собственная частота выпрямителя. |
| 10              | coilFreq               | Частота прохождения обмоток статора. |
| 11              | FTF                    | Частота вращения сепаратора. |
| 12              | BSF                    | Частота вращения тел качения. |
| 13              | BPFO                   | Частота прохождения тел качений по наружному кольцу. |
| 14              | BPFI                   | Частота прохождения тел качений по внутреннему кольцу. |
| 15              | BEF                    | Резонансная частота тел качений. |
| 16              | shaftFreq046           | Частота прецессии. |
| 17              | shaftFreq1             | Частота вращения первого вала при соединении зубчатой передачи. |
| 18              | shaftFreq2             | Частота вращения второго вала при соединении зубчатой передачи. |
| 19              | teethFreq              | Частота зацепления зубьев. |
| 20              | sunFreq                | Частота вращения солнца. |
| 21              | carrierFreq            | Частота вращения водилы. |
| 22              | satellitesFreq         | Частота вращения сателлитов. |
| 23              | diffFreq               | Разница между частотой солнца и водилы. |
| 24              | gearMeshFreqSun        | Частота зацепления солнца. |
| 25              | gearMeshFreqSatellites | Частота зацепления сателлитов. |
| 26              | SPFS                   | Частота перекатывания сателлитов по солнцу. |
| 27              | SPFG                   | Частота перекатывания сателлитов по короне. |
| 28              | beltFreq               | Частота вращения ремня. |
| 29              | sheaveFreq1            | Частота вращения первого шкива. |
| 30              | sheaveFreq2            | Частота вращения второго шкива. |
| 31              | meshingFreq            | Частота зацепления ремня. |
| 32              | bladePass              | Частота вращения лопастей. |
| 33              | (shaft-FTF)            | Разностная гармоника частоты вала и вращения сепаратора. |
| 34              | halfShaftFreq          | Половина частоты вала. |


