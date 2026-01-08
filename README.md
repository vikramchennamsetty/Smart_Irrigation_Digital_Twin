# Smart Irrigation Digital Twin using MATLAB, Simulink, and IoT

## MathWorks MATLAB–Simulink Challenge

**Theme:** Sustainability and Renewable Energy
**Project Title:** Smart Watering System with Internet of Things

---

## 1. Project Overview

Water scarcity and inefficient irrigation practices are major challenges in modern agriculture. Conventional irrigation systems often rely on fixed schedules or simple threshold-based logic, which leads to overwatering, water wastage, and poor adaptability to environmental changes.

This project presents a **Smart Irrigation System based on a Digital Twin approach**, developed using **MATLAB, Simulink, IoT sensors, and the ThingSpeak cloud platform**. The system continuously monitors soil moisture and environmental conditions, estimates internal system states using a digital twin model, and performs intelligent irrigation control in real time.

The objective is to **reduce unnecessary water usage while maintaining soil and crop health**, using a control-oriented and scalable architecture suitable for real-world deployment.

---

## 2. Role of Simulink Model

The Simulink model included in this repository is used for:

* Verification of digital twin dynamics
* Visualization of internal system states (soil moisture, evapotranspiration, plant stress)
* Cross-validation of MATLAB-based estimation and control logic

The real-time control and decision-making logic is implemented in MATLAB scripts to enable direct integration with ThingSpeak and ESP32 hardware.

Simulink is therefore used as a **validation and analysis tool**, not as the primary real-time execution environment.

---

## 3. Objectives

The objectives of this project are:

* To design a digital twin model for soil moisture and plant stress
* To collect real-time environmental data using IoT sensors
* To estimate system states using MATLAB-based observers
* To implement intelligent irrigation control logic
* To validate system behavior using a closed-loop Simulink model
* To reduce unnecessary water usage while maintaining crop health

---

## 4. System Architecture

The system is divided into three layers.

### 4.1 Physical Layer (IoT)

* ESP32 microcontroller
* Soil moisture sensor (potentiometer used for simulation)
* DHT22 temperature and humidity sensor
* Relay module for irrigation valve control

### 4.2 Digital Twin Layer (MATLAB & Simulink)

* Soil moisture dynamic model
* Evapotranspiration model
* Plant stress model
* Digital twin state estimator
* Irrigation controller

### 4.3 Cloud Layer

* ThingSpeak IoT platform for data logging
* Bidirectional command exchange between MATLAB and ESP32 nodes

---

## 5. MATLAB Implementation 

The MATLAB implementation focuses on **digital twin modeling, state estimation, and real-time irrigation control**.

### MATLAB functionalities include:

* Soil moisture modeling with physical constraints
* Weather-dependent evapotranspiration modeling
* Plant Stress Index (PSI) computation
* Digital twin state estimation using sensor feedback
* Intelligent irrigation decision logic
* Real-time interaction with the ThingSpeak cloud

Live MATLAB scripts read sensor data from ThingSpeak, update the digital twin states, and send irrigation commands back to the cloud.

### MATLAB Outputs

The following results are included in the repository:

* Live ThingSpeak sensor data visualization
* MATLAB digital twin execution output
* Relay actuation confirmation (VALVE ON / OFF)

Folder:

```
results/matlab_outputs/
```

---

## 6. Simulink Implementation 

A complete **closed-loop digital twin irrigation system** is modeled in Simulink to validate system behavior.

### The Simulink model includes:

* Weather and evapotranspiration subsystem
* Soil–plant system dynamics
* Digital twin estimator
* Plant stress model
* Irrigation controller
* Feedback loops and state memory blocks

The model demonstrates realistic soil moisture depletion, smooth plant stress evolution, and stable irrigation control.

Folder:

```
simulink/digital_twin_irrigation.slx
```

### Simulink Outputs

Scope outputs showing system response are stored in:

```
results/simulink_outputs/
```

---

## 7. IoT Hardware Integration

Two ESP32 nodes are used.

### 7.1 Sensor Node

* Reads soil moisture, temperature, and humidity
* Uploads sensor data to ThingSpeak at fixed intervals

### 7.2 Relay Node

* Reads irrigation command from ThingSpeak
* Controls irrigation valve using a relay module

ESP32 source code is available in:

```
hardware_iot/esp32/
```

---

## 8. Repository Structure

```
Smart_Irrigation_Digital_Twin/
│
├── README.md
├── code/                     # MATLAB models, estimator, and controllers
├── simulink/                 # Simulink digital twin model
├── hardware_iot/             # ESP32 firmware and MATLAB real-time scripts
├── results/
│   ├── matlab_outputs/
│   └── simulink_outputs/
└── report/
    └── Smart_Irrigation_Digital_Twin_Report.pdf
```

---

## 9. Results and Observations

* The digital twin accurately tracks soil moisture behavior
* Irrigation is triggered only when required
* Water usage is reduced compared to baseline control strategies
* MATLAB, Simulink, and IoT results are consistent
* The system operates in real time using cloud-based communication

---

## 10. Advantages

* Efficient water usage
* Intelligent decision-making using a digital twin
* Low-cost and scalable architecture
* Cloud-based monitoring and control
* Suitable for smart agriculture applications

---

## 11. Limitations

* Weather model is simplified
* Soil type variations are not explicitly modeled
* Large-scale field deployment has not been tested

---

## 12. Future Scope

* Integration of weather forecast APIs
* Machine learning-based crop-specific irrigation strategies
* Multi-zone irrigation control
* Mobile or web-based dashboard
* Deployment and validation in real agricultural fields

---

## 13. How to Run

### 1. ThingSpeak Setup

* Create a ThingSpeak channel with 4 fields:

  * Field 1: Soil moisture
  * Field 2: Temperature
  * Field 3: Humidity
  * Field 4: Irrigation command
* Note the Channel ID and Read/Write API keys.

### 2. ESP32 Sensor Node

* Flash `hardware_iot/esp32/sensor_node.ino`
* Configure Wi-Fi and ThingSpeak credentials in `config.h`
* Sensors publish soil moisture, temperature, and humidity.

### 3. ESP32 Relay Node

* Flash `hardware_iot/esp32/relay_node.ino`
* Relay subscribes to Field 4 and actuates irrigation.

### 4. MATLAB Execution

* Open MATLAB
* Navigate to the project root directory
* Run:

  ```matlab
  live_digital_twin
  ```

### 5. Simulink (Optional)

* Open `simulink/digital_twin_irrigation.slx`
* Used for visualization and validation of system dynamics

---

## 14. Conclusion

This project successfully demonstrates a **Smart Irrigation System using a Digital Twin approach**. By integrating IoT sensors, MATLAB-based estimation and control, Simulink validation, and cloud communication, the system achieves efficient and automated irrigation control. The results show that digital twin-based irrigation can significantly improve water efficiency and sustainability in agriculture.

---

## 15. References

* MATLAB & Simulink Documentation
* ThingSpeak IoT Platform
* FAO Irrigation and Water Management Studies

---

### Student Note

This project was developed as part of the **MathWorks MATLAB–Simulink Challenge** under the **Sustainability and Renewable Energy** theme.
Both **MATLAB and Simulink implementations are fully completed, tested, and documented**.
