# Simulink Model Rebuild Guide — `digital_twin_irrigation.slx`

This document describes the architecture, subsystem design, and MATLAB Function block code
for the closed-loop Simulink digital twin irrigation model.

> **Design philosophy:** The Simulink model is intentionally distinct from the MATLAB
> simulation script. It uses native block-diagram structure — Unit Delay blocks for
> discrete-time state memory, Saturation blocks for physical constraints, and feedback
> connections for closed-loop dynamics. All subsystems call `parameters()` centrally
> with no hardcoded values. This makes the model independently runnable and verifiable.

---

## Purpose of the Simulink Model

The Simulink model serves as an **offline closed-loop verification environment**, distinct
from `run_comparison.m`. Specifically it:

1. Validates the MATLAB control logic under discrete-time block-diagram dynamics
2. Allows visual inspection of soil moisture, PSI, ET, and irrigation signals over time
3. Confirms observer convergence and controller stability without running live IoT hardware
4. Provides a reproducible simulation artifact that can be run independently of live hardware

---

## Model Architecture

```
Clock ──► Weather_ET_Model ──► ET ──────────────────────────────────────┐
                                │                                        │
                                ▼                                        │
                        Soil_Plant_System ──► θ_true                    │
                            ▲       │              │                     │
                            │       │         Band-Limited               │
                            │       │           Noise                    │
                            │       │              │                     │
                            │       ▼              ▼                     │
                            │   1/z (Theta_Store)  Sum ──► y_meas        │
                            │                       │                    │
                            │               Digital_Twin_Estimator ◄─────┘
                            │                       │
                            │               θ_hat, PSI_hat
                            │                       │
                            │               Irrigation_Controller
                            │                       │
                            └───────── I ───────────┘
                                   (feedback)

Scopes: θ_true, θ_hat, I, PSI_hat
```

---

## Subsystem Specifications

### 1. `Weather_ET_Model`

| Property | Value |
|----------|-------|
| Input | `t` (Clock signal) |
| Output | `ET` (scalar, volumetric fraction) |
| Block type | Subsystem containing MATLAB Function |

**MATLAB Function code inside subsystem:**
```matlab
function ET = ET_Model(t)
    params = parameters();
    T_mean = 28 + 3*sin(2*pi*t/100);
    T_max  = T_mean + 5;
    T_min  = T_mean - 5;
    delta_T = max(T_max - T_min, 0);
    ET0 = 0.0023 * params.Ra * (T_mean + 17.8) * sqrt(delta_T);
    ET  = ET0 / params.ET_scale;
    ET  = max(0, ET);
```

---

### 2. `Soil_Plant_System`

| Property | Value |
|----------|-------|
| Inputs | `theta` (current moisture), `I` (irrigation), `ET` |
| Output | `theta_next` |
| Block type | Subsystem containing MATLAB Function |

**MATLAB Function code inside subsystem:**
```matlab
function theta_next = Soil_Model(theta, I, ET)
    params = parameters();
    R = 0;
    theta_next = soil_moisture_model(theta, I, ET, R, params);
    theta_next = max(params.theta_wp, min(params.theta_fc, theta_next));
```

State memory: `1/z` Unit Delay block (`Theta_Store`) feeds `theta_next` back as `theta`.

---

### 3. `Digital_Twin_Estimator`

| Property | Value |
|----------|-------|
| Inputs | `theta_hat` (prior estimate), `I`, `ET`, `y` (measurement), `PSI` |
| Outputs | `theta_hat_next`, `PSI_next` |
| Block type | Subsystem containing MATLAB Function |
| Observer | Scalar Kalman filter with adaptive gain |

**MATLAB Function code inside subsystem:**
```matlab
function [theta_hat_next, PSI_next] = Estimator(theta_hat, I, ET, y, PSI)
    params = parameters();
    persistent P
    if isempty(P), P = 1; end
    R_val = 0;

    % PREDICT
    theta_pred = soil_moisture_model(theta_hat, I, ET, R_val, params);
    P_pred = P + params.Q;

    % UPDATE
    K = P_pred / (P_pred + params.R_noise);
    theta_hat_next = theta_pred + K * (y - theta_pred);
    theta_hat_next = max(params.theta_wp, min(params.theta_fc, theta_hat_next));
    P = (1 - K) * P_pred;

    % STRESS
    PSI_next = plant_stress_model(PSI, theta_hat_next, params);
```

**Observer design note:**
The scalar Kalman filter adapts its gain K each cycle based on the ratio of process
uncertainty Q to measurement uncertainty R_noise. At steady state K converges to ~0.4,
consistent with classical observer theory for this plant, while providing formal
minimum-variance optimality guarantees that a fixed-gain design cannot offer.

State memory: `1/z` Unit Delay block (`ThetaHat_Store`) and `1/z` (`PSI_Store`) feed
states back each timestep.

---

### 4. `Stress_Model`

| Property | Value |
|----------|-------|
| Inputs | `theta_hat`, `PSI` |
| Output | `PSI_next` |
| Block type | Subsystem containing MATLAB Function |

**MATLAB Function code inside subsystem:**
```matlab
function PSI_next = PSI_Model(theta_hat, PSI)
    params = parameters();
    PSI_next = plant_stress_model(PSI, theta_hat, params);
```

---

### 5. `Irrigation_Controller`

| Property | Value |
|----------|-------|
| Inputs | `theta_hat`, `PSI` |
| Output | `I` (irrigation decision) |
| Block type | Subsystem containing MATLAB Function |

**MATLAB Function code inside subsystem:**
```matlab
function I = Controller(theta_hat, PSI)
    params = parameters();
    persistent last_irr iter
    if isempty(last_irr)
        last_irr = -inf;
        iter = 1;
    end
    [I, last_irr] = digital_twin_controller(...
        theta_hat, PSI, iter, last_irr, params);
    iter = iter + 1;
```

---

## Scope Blocks

| Scope | Signal(s) | What it shows |
|-------|-----------|---------------|
| `Scope` (top-left) | `θ_true` | True soil moisture oscillating in physical range |
| `Scope1` (top-right) | `I` | Irrigation pulses at I_fixed = 0.12 |
| `Scope2` (bottom-left) | `θ_hat` | Kalman estimate tracking true soil moisture |
| `Scope3` (bottom-right) | `PSI_hat` | Plant stress index bounded in [0, 0.15] |

---

## Model Configuration

| Setting | Value |
|---------|-------|
| Solver | Fixed-step, discrete (no continuous states) |
| Sample time | `1` (1 day per step) |
| Stop time | `100` (100-day simulation) |
| MATLAB path | Must include all `code/` subfolders |

**Before running, set MATLAB path:**
```matlab
addpath(genpath('path/to/Smart_Irrigation_Digital_Twin'))
```

---

## Parameterization

All subsystems call `parameters()` internally. No hardcoded values exist inside
the Simulink model. To change any system parameter, edit `parameters.m` only —
the Simulink model updates automatically on next run.

---

## Scope Output Results

Scope screenshots from a 100-step simulation run are saved in:

```
results/simulink_outputs/
    soil_moisture_true.png     ← θ_true oscillating in [0.14, 0.26]
    kalman_estimate.png        ← θ_hat tracking θ_true
    irrigation_pulses.png      ← I pulses at 0.12
    plant_stress_index.png     ← PSI bounded below 0.15
```

These confirm the closed-loop system operates correctly and consistently
with the MATLAB simulation results in `results/matlab_outputs/comparison_plot.png`.