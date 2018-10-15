Specification.  
Elements
====

*Editors: Riabtsev P., Kosmach N.*  
*Date: 06-03-2018*  
*Version: 3.4.1*  
----
___

&emsp;Каждый элемент кинематической схемы оборудования в **XML формате** описывается определенным **XML тегом**. Каждому XML тегу ставится в соответствие конкретный узел оборудования: вал (**\<shaft/>**), подшипник (**\<bearing/>**), соединение (**\<connection/>**), электродвигатель (**\<motor/>**)  и т.п. (см. [таблицу 1. Теги элементов](#table_1)).  
&emsp;Элементы различных *классов* имеют принципиальные различия в конструкции, но выполняют одну и ту же функцию, например, класс «подшипники качения» (*rollingBearing*) и класс «подшипники скольжения» (*plainBearing*) относятся к одному элементу (XML тегу) – подшипник (**\<bearing/>**). Каждый класс имеет свои дефекты, которые в большинстве случаев не пересекаются с дефектами смежных классов.  
&emsp;**Типы элемента** – подмножества класса, которые не имеют принципиальных конструктивных различий, вследствие чего имеют одинаковый набор дефектов, например, цилиндрические роликоподшипники (*cylindricalRollerBearing*) и радиальные шарикоподшипники (*deepGrooveBallBearing*), относящиеся к классу *rollingBearing*.  
&emsp;**Группы элементов** – объединения элементов в конструктивные группы, выполняющие определенную задачу и имеющие отличия при диагностике (см. [[SPEC][11] Виды и классы устройств. Группы элементов](http://example.com/)). Каждый элемент может входить в состав только одной группы.  
&emsp;Структура записи тега элемента кинематической схемы оборудования (**\<@elementTag/>**), класса, типа и группы (`@elementGroup`) элемента в файле описания кинематической схемы оборудования (**equipmentProfile.xml**) имеет вид:  

```
<@elementTag … classType = ”@elementClass : @elementType” group = ”@elementGroup”>
    …
</@elementTag>
```

&emsp;Класс (`@elementClass`) и тип элемента (`@elementType`) указываются в атрибуте *classType* XML тега элемента (**\<@elementTag/>**) в следующем формате (см. [таблицу 2. Связь тегов, классов и типов элементов](#table_2)):  
***<класс элемента>[:<тип элемента>]***       ([] - необязательный параметр)  
&emsp;Примеры значений атрибута *classType*:  
● `shaft`  
● `rollingBearing:deepGrooveBallBearing`  

&emsp;Группа элемента указывается в атрибуте *group* XML тега элемента (см. [[SPEC][11] Устройства](http://example.com/)).
&emsp;Примеры значений атрибута *group*:  
● `windTurbineRotor_001`  

&emsp;Пример описания элементов кинематической схемы оборудования представлен на рисунке 1:

```
<shaft mainShaft="true" speedCollection="28.7" schemeName="shaft001" elementProcessingEnable="1" classType="shaft" group="windTurbineRotor_001" equipmentDataPoint="1,2,3,5" imagePositionIndex="2" imageX="302" imageY="554" imageWidth="429" imageHeight="35" imageSlopeDegree="0">
    <bearing supporting="true" schemeName="bearing001" elementProcessingEnable="0" classType="rollingBearing:sphericalRollerBearing" group="windTurbineRotor_001" equipmentDataPoint="1" model="22332 CC/W33" Nb="15" Bd="45.009" Pd="252.527" angle="12.833" imagePositionIndex="3" imageX="274" imageY="554" imageWidth="117" imageHeight="78" imageSlopeDegree="0"/>
    <bearing supporting="true" schemeName="bearing002" elementProcessingEnable="0" classType="rollingBearing:sphericalRollerBearing" group="windTurbineRotor_001" equipmentDataPoint="2" model="22332 CC/W33" Nb="15" Bd="45.009" Pd="252.527" angle="12.833" imagePositionIndex="4" imageX="418" imageY="554" imageWidth="117" imageHeight="78" imageSlopeDegree="0"/> 
</shaft>
```
Рисунок 1 – Пример записи тега, класса, типа и группы элемента

&nbsp;

<a name="table_1">Таблица 1. Теги элементов</a>

| Тег элемента       | Название <br> [en] | Название <br> [ru] |
|--------------------|--------------------|--------------------|
| **\<shaft/>**      | Shaft              | Вал                |
| **\<bearing/>**    | Bearing            | Подшипник          |
| **\<connection/>** | Connection         | Соединение         |
| **\<motor/>**      | Motor              | Электродвигатель   |
| **\<fan/>**        | Fan                | Вентилятор         |
| **\<equipment/>**  | Equipment          | Оборудование       |

&nbsp;

<a name="table_2">Таблица 2. Связь XML тегов, классов и типов элементов</a>

<table>
    <thead>
        <tr>
            <th>Tag</th>
            <th>elementClass</th>
            <th>elementType</th>
        </tr>
    </thead>
    <tbody>
        <tr>
          <td><b>  &lt;shaft/&gt; </b></td>
          <td><em> shaft          </em></td>
          <td><em> -              </em></td>
        </tr>
        <tr>
          <td rowspan=6><b>  &lt;bearing/&gt;      </b></td>
          <td rowspan=5><em> rollingBearing        </em></td>
          <td><em>           deepGrooveBallBearing </em></td>
        </tr>
        <tr>
          <td><em>       angularContactBallBearing </em></td>
        </tr>
        <tr>
          <td><em>        cylindricalRollerBearing </em></td>
        </tr>
        <tr>
          <td><em>          sphericalRollerBearing </em></td>
        </tr>
        <tr>
          <td><em>            taperedRollerBearing </em></td>
        </tr>
        <tr>
          <td><em> plainBearing </em></td>
          <td><em> -              </em></td>
        </tr>
        <tr>
          <td rowspan=6><b> &lt;connection/&gt;   </b></td>
          <td><em>          gearing                </em></td>
          <td><em>          -                     </em></td>
        </tr>
        <tr>
          <td><em>          smoothBelt            </em></td>
          <td><em>          -                     </em></td>
        </tr>
        <tr>
          <td><em>          toothedBelt           </em></td>
          <td><em>          -                     </em></td>
        </tr>
        <tr>
          <td><em>          planetaryStageGearbox </em></td>
          <td><em>          -                     </em></td>
        </tr>
        <tr>
          <td><em>          coupling              </em></td>
          <td><em>          -                     </em></td>
        </tr>
        <tr>
          <td><em>          hidden               </em></td>
          <td><em>          -                     </em></td>
        </tr>
        <tr>
          <td rowspan=3><b> &lt;motor/&gt;     </b></td>
          <td><em>          inductionMotor     </em></td>
          <td><em>          -                  </em></td>
        </tr>
        <tr>
          <td><em>          synchronousMotor   </em></td>
          <td><em>          -                  </em></td>
        </tr>
        <tr>
          <td><em>          directCurrentMotor </em></td>
          <td><em>          -                  </em></td>
        </tr>
        <tr>
          <td><b>  &lt;fan/&gt; </b></td>
          <td><em> fan          </em></td>
          <td><em> -            </em></td>
        </tr>
    </tbody>
</table>

&nbsp;

1. Тег элемента: **\<shaft/>** (shaft – «вал»)

Таблица 3. Классы элементов тега **\<shaft/>**

| Класс элемента | Название <br> [en] | Название <br> [ru] |
|----------------|--------------------|--------------------|
| *shaft*        | Shaft              | Вал                |

&nbsp;

2. Тег элемента: **\<bearing/>** (bearing – «подшипник»)

Таблица 4. Классы элементов тега **\<bearing/>**

| Класс элемента   | Название <br> [en] | Название <br> [ru]   |
|------------------|--------------------|----------------------|
| *rollingBearing* | Rolling bearing    | Подшипник качения    |
| *plainBearing*   | Plain bearing      | Подшипник скольжения |

&nbsp;

Таблица 4.1 Классы элементов класса *rollingBearing*

| Тип элемента                | Название <br> [en]           | Название <br> [ru]                 |
|-----------------------------|------------------------------|------------------------------------|
| *rollingBearing*            | Rolling bearing              | Подшипник качения                  |
| *plainBearing*              | Plain bearing                | Подшипник скольжения               |
| *deepGrooveBallBearing*     | Deep groove ball bearing     | Радиальные шарикоподшипники        |
| *angularContactBallBearing* | Angular contact ball bearing | Радиально-упорные шарикоподшипники |
| *cylindricalRollerBearing*  | Cylindrical roller bearing   | Цилиндрические роликоподшипники    |
| *sphericalRollerBearing*    | Spherical roller bearing     | Сферические роликоподшипники       |
| *taperedRollerBearing*      | Tapered roller bearing       | Конические роликоподшипники        |

Класс *plainBearing* не имеет типов.

&nbsp;

3. Тег элемента: **\<connection/>** (connection – «соединение»)

Таблица 5. Классы элементов тега **\<connection/>**

| Класс элемента          | Название <br> [en]      | Название <br> [ru]   |
|-------------------------|-------------------------|----------------------|
| *gearing*               | Gearing                 | Зубчатая передача    |
| *smoothBelt*            | Smooth belt             | Гладкий ремень       |
| *toothedBelt*           | Toothed belt            | Зубчатый ремень      |
| *planetaryStageGearbox* | Planetary stage gearbox | Планетарный редуктор |
| *coupling*              | Coupling                | Муфта                |
| *hidden*                | Hidden connection       | Скрытое соединение   |

Класс *gearing* не имеет типов.
Класс *smoothBelt* не имеет типов.
Класс *toothedBelt* не имеет типов.
Класс *planetaryStageGearbox* не имеет типов.
Класс *coupling* не имеет типов.
Класс *hidden* не имеет типов.

&nbsp;

4. Тег элемента: **\<motor/>** (motor – «электродвигатель»)

Таблица 6. Классы элементов тега **\<motor/>**

| Класс элемента       | Название <br> [en]   | Название <br> [ru]                |
|----------------------|----------------------|-----------------------------------|
| *inductionMotor*     | Induction motor      | Асинхронный электродвигатель      |
| *synchronousMotor*   | Synchronous motor    | Синхронный электродвигатель       |
| *directCurrentMotor* | Direct current motor | Электродвигатель постоянного тока |

Класс *inductionMotor* не имеет типов.  
Класс *synchronousMotor* не имеет типов.  
Класс *directCurrentMotor* не имеет типов.  

&nbsp;

5. Тег элемента: **\<fan/>** (motor – «вентилятор»)

Таблица 7. Классы элементов тега **\<fan/>**

| Класс элемента | Название <br> [en] | Название <br> [ru] |
|----------------|--------------------|--------------------|
| *fan*          | Fan                | Вентилятор         |

Класс *fan* не имеет типов.  

&nbsp;

6. Тег элемента: **\<equipment/>** (equipment – «оборудование»)

Таблица 8. Классы элементов тега **\<equipment/>**

| Класс элемента | Название <br> [en] | Название <br> [ru] |
|----------------|--------------------|--------------------|
| *equipment*    | Equipment          | Оборудование       |

Класс *equipment* не имеет типов.