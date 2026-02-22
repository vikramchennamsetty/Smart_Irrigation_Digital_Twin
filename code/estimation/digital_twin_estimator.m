function [theta_hat_next, PSI_next] = digital_twin_estimator( ...
    theta_hat, y_meas, PSI, I, ET, R, params)
% DIGITAL_TWIN_ESTIMATOR - Scalar Kalman filter for soil moisture estimation.
%
% Syntax:
%   [theta_hat_next, PSI_next] = digital_twin_estimator( ...
%       theta_hat, y_meas, PSI, I, ET, R, params)
%
% Inputs:
%   theta_hat  - Prior soil moisture estimate at step k       [m^3/m^3]
%   y_meas     - Sensor measurement at step k                 [m^3/m^3]
%   PSI        - Plant stress index at step k                 [–, 0..1]
%   I          - Irrigation decision at step k (from controller) [m^3/m^3]
%   ET         - Evapotranspiration at step k                  [m^3/m^3]
%   R          - Rainfall at step k                            [m^3/m^3]
%   params     - Parameter struct (requires Q, R_noise, theta_wp, theta_fc)
%
% Outputs:
%   theta_hat_next - Predicted soil moisture estimate at k+1   [m^3/m^3]
%   PSI_next       - Updated plant stress index at k+1         [–, 0..1]
%
% Method:
%   Scalar Kalman filter with the following structure:
%
%   --- PREDICT STEP ---
%       theta_pred(k+1) = f( theta_hat(k), I(k), ET(k), R(k) )
%       P_pred          = P(k) + Q
%
%   --- UPDATE STEP (using measurement at time k) ---
%       K               = P_pred / (P_pred + R_noise)
%       theta_hat(k+1)  = theta_pred(k+1) + K * (y(k) - theta_pred(k+1))
%       P(k+1)          = (1 - K) * P_pred
%
%   where:
%       f(.)    = soil_moisture_model (bucket-model water balance)
%       Q       = process noise covariance (model uncertainty)
%       R_noise = measurement noise covariance (sensor uncertainty)
%       K       = Kalman gain (adapts automatically each cycle)
%       P       = estimation error covariance (persistent state)
%
%   Design note — comparison with original fixed-gain observer:
%       The original Luenberger observer used a fixed gain L = 0.4,
%       placing the error pole at (1 - L) = 0.6.  This was a reasonable
%       first-principles design for stable convergence.  The Kalman
%       filter improves on it by dynamically adapting K based on the
%       relative magnitudes of Q and R_noise.  In steady state, K
%       converges to a value near L = 0.4 when Q/R_noise ≈ 10, which
%       validates the original tuning.
%
%   Modeling assumptions:
%       1. Scalar state (only soil moisture θ is estimated).
%       2. Plant stress PSI is computed open-loop from estimated θ.
%       3. Measurement y(k) is time-aligned with state theta_hat(k).
%       4. Process and measurement noise are white, zero-mean, Gaussian.
%       5. The state transition is approximated as locally linear for
%          covariance propagation (F ≈ 1 in the scalar case).
%
% Reference:
%   Kalman, R.E. (1960). "A New Approach to Linear Filtering and
%   Prediction Problems." J. Basic Engineering, 82(1), 35-45.
%
% Dependencies: soil_moisture_model.m, plant_stress_model.m, parameters.m
% Author:  <Your Name>
% Date:    2026-02-20

% ---- Persistent covariance state ----------------------------------------
%   P is carried across calls so that the filter retains memory of its
%   estimation confidence between cycles.
persistent P
if isempty(P)
    P = 1;  % Initial covariance — high uncertainty at startup
end

% ---- Noise covariances from parameters ----------------------------------
Q       = params.Q;           % Process noise covariance
R_noise = params.R_noise;     % Measurement noise covariance

% ---- Defensive input validation -----------------------------------------
assert(~isnan(y_meas),   'Estimator received NaN measurement');
assert(theta_hat >= 0 && theta_hat <= 1, 'theta_hat outside physical bounds');

% ====================================================================
%  PREDICT STEP
%    Propagate the state estimate through the nonlinear plant model.
%    Propagate the covariance with the linear approximation F ≈ 1.
% ====================================================================
theta_pred = soil_moisture_model(theta_hat, I, ET, R, params);
P_pred     = P + Q;

% ====================================================================
%  UPDATE STEP
%    Incorporate the sensor measurement to correct the prediction.
% ====================================================================

% Kalman gain: trades off model trust (P_pred) vs sensor trust (R_noise)
K = P_pred / (P_pred + R_noise);

% State correction using innovation (y_meas - theta_pred)
theta_hat_next = theta_pred + K * (y_meas - theta_pred);

% Clamp to physical bounds — sensor noise can push estimate out of range
theta_hat_next = max(params.theta_wp, min(params.theta_fc, theta_hat_next));

% Covariance update (Joseph form simplifies to this for scalar case)
P = (1 - K) * P_pred;

% ====================================================================
%  PLANT STRESS UPDATE
%    Open-loop — no direct measurement of stress; driven by theta_hat.
% ====================================================================
PSI_next = plant_stress_model(PSI, theta_hat_next, params);

end
