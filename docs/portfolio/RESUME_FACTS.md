# Smart Irrigation Digital Twin — Resume Action Bullets & Technical Facts

This document compiles high-impact, verified resume bullets and technical details for portfolios and job applications. The content highlights quantitative outcomes, algorithm design, system architecture, and trade-off analysis.

---

## 1. High-Impact Resume Action Bullets

* **Engineered a closed-loop Smart Irrigation Digital Twin** that achieved a **$20.0\%$ water savings** (MATLAB simulation) and **$17.5\%$ savings** (Python validation run) over a standard threshold-based bang-bang controller, while maintaining zero plant water-stress events over a 100-day cycle.
* **Formulated and implemented a discrete-time scalar Kalman filter state estimator** inside MATLAB, Python, and Simulink, reducing capacitive soil moisture sensor noise ($\sigma = 0.01$ $m^3/m^3$) to track ground-truth soil hydrology with a steady-state observer convergence within 5 time steps.
* **Designed an event-triggered controller** that incorporates a $2\sigma$ lower confidence boundary ($\theta_{LB} = \theta_{hat} - 2\sigma_{sensor}$) to buffer telemetry noise, reducing actuator relay wear by enforcing a minimum 3-day activation spacing (`min_gap = 3` days) to prevent controller chattering.
* **Architected a multi-layered IoT telemetry and actuation loop** utilizing dual ESP32 DevKit microcontrollers and the ThingSpeak cloud platform; integrated a 5-point moving average filter on the sensor node for raw ADC telemetry smoothing and implemented a safe-default actuator override (valve shutoff) on connection loss.
* **Modelled and verified system dynamics in Simulink** using discrete subsystems for weather, soil-plant dynamics, Kalman estimation, and control, validating closed-loop stability and tracking performance under simulated seasonal temperature variations.

---

## 2. Measurable Engineering Outcomes
* **Water Usage Efficiency:** Reduced total irrigation water applied from **4.80** to **3.84** volumetric units (MATLAB) and to **3.96** units (Python) — saving $0.96$ and $0.84$ units of water respectively.
* **Crop Dehydration Prevention:** Bounded the normalized Plant Stress Index (PSI) below **$0.15$** (where $1.0$ is wilting point), maintaining **0 high-stress days** (PSI > 0.5) across the entire 100-day semiarid growing season.
* **Observer Performance:** Estimated soil moisture with a measurement uncertainty covariance $R_{noise} = 10^{-4}$ and process noise covariance $Q = 10^{-3}$, converging the Kalman Gain dynamically to steady state $\approx 0.40$ within $5$ days of initialization.

---

## 3. Technology Stack & Tooling
* **Software Tools:** MATLAB, Simulink, Stateflow.
* **Programming Languages:** MATLAB Scripting, C++ (Arduino/ESP32), Python (NumPy, Pandas, Matplotlib).
* **IoT Protocols & Services:** HTTP (POST/GET), ThingSpeak cloud client.
* **Hardware Telemetry:** ESP32 microcontrollers, Capacitive Soil Moisture Sensors, DHT22 Temperature/Humidity sensors, Optocoupler Relay modules, Solenoid valves.

---

## 4. Key Algorithms & Mathematical Implementations
1. **Soil Hydrology (Bucket Model):**
   $$\theta(k+1) = \theta(k) + I(k) + R(k) - ET(k) - D(k)$$
   $$D(k) = k_d \max(0, \theta(k) - \theta_{fc})$$
2. **Atmospheric Evaporation (Hargreaves-Samani / FAO-56):**
   $$ET_0 = 0.0023 \cdot R_a \cdot (T_{mean} + 17.8) \cdot \sqrt{T_{max} - T_{min}}$$
3. **Discrete Kalman Filter Update Loop:**
   * **Predict:** $\theta_{pred} = f(\theta_{hat}, I, ET)$ and $P_{pred} = P + Q$
   * **Gain:** $K = P_{pred} / (P_{pred} + R_{noise})$
   * **Correct:** $\theta_{hat} = \theta_{pred} + K \cdot (y_{meas} - \theta_{pred})$ and $P = (1-K) \cdot P_{pred}$
4. **Normalized Plant Stress Accumulator:**
   * Stress: $S = \alpha_{stress} \frac{\theta_{min} - \theta_{hat}}{\theta_{min}}$ (if $\theta_{hat} < \theta_{min}$)
   * Recovery: $S = -\beta_{recover} \cdot PSI_{curr}$ (if $\theta_{hat} \geq \theta_{min}$)

---

## 5. Engineering Trade-Offs

| Decision | Selected Approach | Trade-Off Rationale |
| :--- | :--- | :--- |
| **State Estimation** | Scalar Kalman Filter | **Pros:** Low computational foot-print; executes easily in real-time on 8-bit/32-bit MCUs; guarantees minimum-variance state tracking. **Cons:** Ignores non-linear soil suction gradients (Richards equation). |
| **Cloud Telemetry** | ThingSpeak Broker | **Pros:** Out-of-the-box MATLAB support; free tier; standard HTTP integration. **Cons:** Free-tier rate limits write intervals to $\geq 15$ seconds, preventing high-frequency control. |
| **Actuator Control** | Event-Triggered (with min-gap) | **Pros:** Buffers sensor noise and prevents relay chattering; extends mechanical pump lifespan. **Cons:** Introduces a delay in watering response if a severe drought occurs immediately after irrigation. |
| **Plant Stress Modeling** | Open-Loop Estimation | **Pros:** Avoids expensive visual/leaf-sensor arrays by estimating stress analytically from estimated soil moisture. **Cons:** Relies heavily on model parameter accuracy ($\alpha_{stress}, \beta_{recover}$). |
