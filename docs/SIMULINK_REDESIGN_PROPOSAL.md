# PROPOSED REDESIGN / FUTURE WORK: Simulink Native-Block Model Redesign

> [!IMPORTANT]
> This document outlines a proposed future redesign of the Simulink model using native blocks.
> **Note:** This redesigned model has NOT been implemented in the current repository codebase.
> The active `digital_twin_irrigation.slx` model continues to utilize the MATLAB Function block configuration.

---

# Simulink Model Rebuild Guide — `digital_twin_irrigation.slx`

This document provides step-by-step instructions for rebuilding the Simulink model so that it serves as a **closed-loop validation environment** distinct from the MATLAB script workflow.

> The MathWorks reviewer noted: *"The Simulink model largely mirrors the MATLAB workflow by wiring MATLAB Function blocks together rather than adding clear simulation/verification value."*  The redesigned model addresses this by using **native Simulink blocks** for the continuous dynamics and reserving MATLAB Function blocks only for discrete decision logic.

---

## Architecture Overview

```
┌───────────────────────────────────────────────────────────────┐
│                    Simulink Model                             │
│                                                               │
│  ┌──────────┐    ┌────────────┐    ┌──────────────────┐       │
│  │  Weather  │───►│  ET Model  │───►│                  │       │
│  │  (From WS)│    │ (Subsystem)│    │   Soil Moisture  │       │
│  └──────────┘    └────────────┘    │   Plant Model    │       │
│                                    │  (Integrator +   │◄──┐   │
│  ┌──────────┐    ┌────────────┐    │   Saturation)    │   │   │
│  │ Rainfall │───►│            │───►│                  │   │   │
│  │ (From WS)│    │            │    └───────┬──────────┘   │   │
│  └──────────┘    │            │            │              │   │
│                  │  Irrigation│        θ_true             │   │
│                  │  Controller│            │              │   │
│                  │ (MATLAB Fn)│     ┌──────▼──────┐       │   │
│                  │            │     │  Sensor +   │       │   │
│                  │            │◄────│  Noise      │       │   │
│                  └──────┬─────┘     └──────┬──────┘       │   │
│                         │                  │              │   │
│                     I_decision         y_meas             │   │
│                         │                  │              │   │
│                         │           ┌──────▼──────┐       │   │
│                         │           │  Kalman     │       │   │
│                         │           │  Estimator  │       │   │
│                         └──────────►│ (MATLAB Fn) │       │   │
│                                     └──────┬──────┘       │   │
│                                            │              │   │
│                                        θ_hat ─────────────┘   │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐      │
│  │  Scopes: θ_true vs θ_hat, PSI, I_decision, ET      │      │
│  └─────────────────────────────────────────────────────┘      │
└───────────────────────────────────────────────────────────────┘
```

---

## Subsystem Specifications

### 1. Weather Input (From Workspace)

| Property | Value |
|----------|-------|
| Block type | `From Workspace` |
| Variable name | `weather_ts` (timeseries with 3 columns: T_mean, T_max, T_min) |
| Sample time | `params.dt` |

**Pre-simulation setup (in Model Callbacks → InitFcn):**
```matlab
params = parameters();
N = 100;
rng(42);
T_mean = 28 + 3*randn(1,N);
T_max = T_mean + 5 + 1.5*randn(1,N);
T_min = T_mean - 5 + 1.5*randn(1,N);
T_max = max(T_max, T_min+1);
t = (0:N-1)' * params.dt;
weather_ts = timeseries([T_mean', T_max', T_min'], t);
```

---

### 2. ET Model Subsystem

| Property | Value |
|----------|-------|
| Block type | Subsystem |
| Inputs | `T_mean`, `T_max`, `T_min` (from Weather) |
| Output | `ET` (scalar) |

**Internal structure — use native Simulink blocks:**

| Block | Purpose |
|-------|---------|
| `Sum` | Compute `delta_T = T_max - T_min` |
| `MinMax (max)` | Clamp `delta_T ≥ 0` |
| `Sqrt` | Compute `sqrt(delta_T)` |
| `Sum` | Compute `T_mean + 17.8` |
| `Product` (×3) | Multiply `0.0023 * Ra * (T_mean+17.8) * sqrt(delta_T)` |
| `Gain` | Divide by `ET_scale` → `ET` |
| `Saturation` | Clamp `ET ≥ 0` |

**Key**: This subsystem uses **only native Simulink blocks** — no MATLAB Function block. This directly addresses the reviewer's concern.

---

### 3. Soil Moisture Plant Model Subsystem

This is the **continuous dynamics** representation — the key differentiator from the MATLAB script.

| Property | Value |
|----------|-------|
| Block type | Subsystem |
| Inputs | `I` (irrigation), `ET`, `R` (rainfall) |
| Output | `θ_true` (soil moisture) |

**Internal structure:**

| Block | Purpose |
|-------|---------|
| `Sum` | Net input: `I + R - ET - D` |
| `Discrete-Time Integrator` | Integrates net input: `θ(k+1) = θ(k) + dt*(I+R-ET-D)` |
| | Initial condition: `0.25`, Sample time: `params.dt` |
| `Saturation` | Clamps output to `[theta_wp, theta_fc]` |
| `Switch + Gain` | Drainage: if `θ > theta_fc`, then `D = kd*(θ-theta_fc)`, else `D = 0` |
| | Feed `D` back to the Sum block (negative) |

**Why this is better**: The Integrator + Saturation + feedback loop is a proper **block diagram** of the plant dynamics, not just a wrapped MATLAB function call. It shows the feedback structure visually.

---

### 4. Sensor + Noise Subsystem

| Property | Value |
|----------|-------|
| Block type | Subsystem |
| Input | `θ_true` |
| Output | `y_meas` |

**Internal structure:**

| Block | Purpose |
|-------|---------|
| `Band-Limited White Noise` | Noise power = `sigma_sensor^2 / dt` |
| `Sum` | `y_meas = θ_true + noise` |
| `Saturation` | Clamp `y_meas` to `[0, 1]` |

---

### 5. Kalman Estimator (MATLAB Function Block)

| Property | Value |
|----------|-------|
| Block type | MATLAB Function |
| Inputs | `y_meas` (measurement), `I` (irrigation), `ET`, `R` |
| Outputs | `theta_hat`, `PSI_hat` |

**Paste this code into the MATLAB Function block:**
```matlab
function [theta_hat, PSI_hat] = kalman_estimator(y_meas, I, ET, R)
%#codegen
    persistent P theta_prev PSI_prev initialized
    
    params = parameters();
    
    if isempty(initialized)
        P = 1;
        theta_prev = 0.25;
        PSI_prev = 0;
        initialized = true;
    end
    
    Q = params.Q;
    R_noise = params.R_noise;
    
    % PREDICT
    theta_pred = soil_moisture_model(theta_prev, I, ET, R, params);
    P_pred = P + Q;
    
    % UPDATE
    K = P_pred / (P_pred + R_noise);
    theta_hat = theta_pred + K * (y_meas - theta_pred);
    theta_hat = max(params.theta_wp, min(params.theta_fc, theta_hat));
    P = (1 - K) * P_pred;
    
    % STRESS
    PSI_hat = plant_stress_model(PSI_prev, theta_hat, params);
    
    % Store for next call
    theta_prev = theta_hat;
    PSI_prev = PSI_hat;
end
```

---

### 6. Irrigation Controller (MATLAB Function Block)

| Property | Value |
|----------|-------|
| Block type | MATLAB Function |
| Inputs | `theta_hat`, `PSI_hat` |
| Output | `I_decision` |

**Paste this code into the MATLAB Function block:**
```matlab
function I_decision = irrigation_controller(theta_hat, PSI_hat)
%#codegen
    persistent last_irr_iter iter_count

    params = parameters();

    if isempty(iter_count)
        iter_count = 1;
        last_irr_iter = -100;
    end

    theta_LB = theta_hat - 2 * params.sigma_sensor;
    need_water = (theta_LB < params.theta_min) || (PSI_hat > params.PSI_max);
    gap_ok = (iter_count - last_irr_iter) >= params.min_gap;

    if need_water && gap_ok
        I_decision = params.I_fixed;
        last_irr_iter = iter_count;
    else
        I_decision = 0;
    end

    iter_count = iter_count + 1;
end
```

---

### 7. Scope Blocks

Add the following Scope blocks to the model:

| Scope Name | Inputs | Purpose |
|------------|--------|---------|
| `Soil Moisture` | `θ_true`, `θ_hat` (on same axes) | Visualize estimation accuracy |
| `Plant Stress` | `PSI_hat` | Monitor stress trajectory |
| `Irrigation` | `I_decision` | Show irrigation event timing |
| `ET` | `ET` | Show dynamic ET variation |

---

### 8. Connection Diagram

```
Weather(FromWorkspace) ──► ET_Subsystem ──► ET ──┬──► Soil_Plant ──► θ_true
                                                 │                      │
Rainfall(FromWorkspace) ─────────────────────────┤                      │
                                                 │                 Sensor+Noise
                                                 │                      │
                                                 │                   y_meas
                                                 │                      │
                                                 ├──► Kalman_Est ◄──────┘
                                                 │       │
                                                 │   θ_hat, PSI_hat
                                                 │       │
                                                 │   Controller
                                                 │       │
                                                 │   I_decision
                                                 │       │
                                                 └───────┘ (feedback to Soil_Plant)
```

---

### 9. Model Configuration

| Setting | Value |
|---------|-------|
| Solver | Fixed-step, `ode1` (Euler) |
| Step size | `params.dt` (= 1) |
| Stop time | `99` (100 days) |
| Model Callbacks → InitFcn | Weather generation script (see Section 1) |
| Model Callbacks → InitFcn | Also add: `params = parameters();` |

---

### 10. Parameterization

All MATLAB Function blocks call `parameters()` internally. No hardcoded values inside Simulink. To change any parameter, edit `parameters.m` only.

For native Simulink blocks (Saturation limits, Gain values), use MATLAB expressions:
- Saturation upper limit: `params.theta_fc`
- Saturation lower limit: `params.theta_wp`
- Drainage gain: `params.kd`

These resolve automatically if `params` is in the base workspace (set by InitFcn).
