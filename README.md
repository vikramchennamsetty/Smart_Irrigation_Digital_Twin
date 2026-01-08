
# Smart Irrigation Digital Twin using MATLAB, Simulink, and IoT

## MathWorks MATLAB–Simulink Challenge

**Theme:** Sustainability and Renewable Energy
**Project Title:** Smart Watering System with Internet of Things



## 1. Project Overview

Water scarcity and inefficient irrigation practices are major challenges in modern agriculture. Traditional irrigation systems operate using fixed schedules or basic threshold logic, which often results in overwatering and wastage of water. To address this issue, this project presents a **Smart Irrigation System based on a Digital Twin approach** using **MATLAB, Simulink, IoT sensors, and the ThingSpeak cloud platform**.

The proposed system continuously monitors soil moisture, temperature, and humidity using low-cost IoT hardware. A digital twin model developed in MATLAB estimates soil moisture and plant stress in real time and makes intelligent irrigation decisions. The system is further validated using a closed-loop Simulink model.

Both **MATLAB and Simulink implementations are completed** as part of this project.



## 2. Objectives

The objectives of this project are:

* To design a digital twin model for soil moisture and plant stress
* To collect real-time environmental data using IoT sensors
* To analyze and estimate system states using MATLAB
* To implement irrigation control logic based on estimated states
* To model and validate the system behavior using Simulink
* To reduce unnecessary water usage while maintaining crop health


## 3. System Architecture

The system is divided into three layers:

### 3.1 Physical Layer (IoT)

* ESP32 microcontroller
* Soil moisture sensor (potentiometer used for simulation)
* DHT22 temperature and humidity sensor
* Relay module for irrigation valve control

### 3.2 Digital Twin Layer (MATLAB & Simulink)

* Soil moisture dynamic model
* Evapotranspiration model
* Plant stress model
* Digital twin state estimator
* Irrigation controller

### 3.3 Cloud Layer

* ThingSpeak IoT platform for data logging
* Command exchange between MATLAB and ESP32



## 4. MATLAB Implementation (Completed)

The MATLAB part of the project focuses on **digital twin modeling, estimation, and real-time control**.

### MATLAB functionalities include:

* Soil moisture model with physical constraints
* Evapotranspiration-based water loss modeling
* Plant Stress Index (PSI) computation
* Digital twin state estimation using sensor data
* Intelligent irrigation decision logic
* Real-time interaction with ThingSpeak

Live MATLAB scripts read sensor data from ThingSpeak, update the digital twin, and send irrigation commands back to the cloud.

### MATLAB Outputs

The following results are included in the repository:

* Live ThingSpeak sensor data visualization
* MATLAB digital twin execution output
* Relay actuation (VALVE ON / OFF) confirmation

Folder:

results/matlab_outputs/


## 5. Simulink Implementation (Completed)

A complete **closed-loop digital twin irrigation system** is modeled in Simulink to validate system behavior.

### The Simulink model includes:

* Weather and evapotranspiration subsystem
* Soil–plant system model
* Digital twin estimator
* Plant stress model
* Irrigation controller
* Feedback loops and state memory blocks

The model demonstrates realistic soil moisture depletion, smooth plant stress evolution, and stable irrigation control.

Folder:

simulink/digital_twin_irrigation.slx

### Simulink Outputs

Scope outputs showing system response are stored in:

results/simulink_outputs/


## 6. IoT Hardware Integration

Two ESP32 nodes are used:

1. **Sensor Node**

   * Reads soil moisture, temperature, and humidity
   * Uploads data to ThingSpeak at fixed intervals

2. **Relay Node**

   * Reads irrigation command from ThingSpeak
   * Controls irrigation valve using a relay module

ESP32 source codes are available in:


hardware_iot/esp32/




## 7. Repository Structure


Smart_Irrigation_Digital_Twin/
│
├── README.md
├── code/                    # MATLAB models and controllers
├── simulink/                # Simulink digital twin model
├── hardware_iot/             # ESP32 and MATLAB real-time scripts
├── results/
│   ├── matlab_outputs/
│   └── simulink_outputs/
└── report/
    └── report.docx



## 8. Results and Observations

* The digital twin accurately tracks soil moisture behavior
* Irrigation is triggered only when required
* Water usage is reduced compared to baseline control
* MATLAB, Simulink, and IoT results are consistent
* The system operates in real time using cloud communication

## 9. Advantages

* Efficient water usage
* Intelligent decision-making using digital twin
* Low-cost and scalable system
* Cloud-based monitoring and control
* Suitable for smart agriculture applications


## 10. Limitations

* Weather model is simplified
* Soil type variations are not included
* Large-scale field deployment not tested


## 11. Future Scope

* Integration of weather forecast APIs
* Machine learning-based crop-specific irrigation
* Multi-zone irrigation control
* Mobile or web-based dashboard
* Deployment in real agricultural fields


## 12. Conclusion

This project successfully demonstrates a **Smart Irrigation System using a Digital Twin approach**. By integrating IoT sensors, MATLAB analytics, Simulink modeling, and cloud communication, the system achieves efficient and automated irrigation control. The results show that digital twin-based irrigation can significantly improve water efficiency and sustainability in agriculture.


## 13. References

* MATLAB & Simulink Documentation
* ThingSpeak IoT Platform
* FAO Irrigation and Water Management Studies

### ✅ Student Note

This project was developed as part of the **MathWorks MATLAB–Simulink Challenge** under the **Sustainability and Renewable Energy** theme.
Both **MATLAB and Simulink parts are fully completed, tested, and documented**.
