function params = parameters()
% PARAMETERS - Central parameter configuration for Smart Irrigation Digital Twin.
%
% Syntax:
%   params = parameters()
%
% Outputs:
%   params - struct containing all system parameters with fields listed below
%
% Description:
%   Returns a single struct containing every tunable constant used by the
%   soil moisture model, evapotranspiration model, Kalman filter estimator,
%   irrigation controller, and plant stress model.  Centralising parameters
%   here guarantees consistency between offline simulation (run_comparison)
%   and real-time operation (live_digital_twin).
%
% Reference:
%   Allen, R.G. et al., "Crop evapotranspiration — Guidelines for computing
%   crop water requirements", FAO Irrigation and Drainage Paper 56, 1998.
%
% Dependencies: none
% Author:  Vikram Chennamsetty, Nikitha Sai Udatha
% Date:    2026-02-20

% ========================= TIME =========================================
params.dt = 1;                 % Discrete time step [days]

% ========================= SOIL MOISTURE ================================
params.theta_fc  = 0.35;      % Field capacity [m^3/m^3]
params.theta_wp  = 0.15;      % Permanent wilting point [m^3/m^3]
params.theta_min = 0.20;      % Irrigation trigger threshold [m^3/m^3]

% ========================= DRAINAGE =====================================
params.kd = 0.05;             % Drainage coefficient [1/day]

% ========================= IRRIGATION ===================================
params.I_fixed = 0.12;        % Fixed irrigation pulse magnitude [m^3/m^3]

% ========================= EVAPOTRANSPIRATION ===========================
params.Ra = 15.0;             % Extraterrestrial radiation [MJ/m^2/day]
params.ET_scale = 100;        % ET scaling divisor [–]
                               % Converts Hargreaves ET (mm/day) to
                               % volumetric fraction: ET_vol = ET_mm / ET_scale

% ========================= PLANT STRESS =================================
params.PSI_max = 0.9;         % Maximum stress threshold [–]
                               %   Controller triggers irrigation if PSI
                               %   exceeds this, regardless of soil moisture.

params.alpha_stress = 0.1;    % Stress accumulation rate [1/day]
                               %   PSI grows at this rate per unit normalised
                               %   deficit when theta < theta_min.

params.beta_recover = 0.3;    % Stress recovery rate [1/day]
                               %   PSI decays at this rate when theta >= theta_min.
                               %
                               %   DESIGN NOTE: beta_recover must be significantly
                               %   larger than alpha_stress so that one irrigation
                               %   event can reverse several days of stress
                               %   accumulation.  With alpha_stress = 0.1 and
                               %   beta_recover = 0.3, a single adequate watering
                               %   recovers 3x faster than stress accumulated —
                               %   physically consistent with crop recovery data.
                               %   Previous value of 0.05 caused PSI to accumulate
                               %   faster than it could recover, even under the
                               %   digital twin strategy.

% ========================= SENSOR NOISE =================================
params.sigma_sensor = 0.01;   % Sensor measurement std deviation [m^3/m^3]

% ========================= KALMAN FILTER ================================
%   The scalar Kalman filter replaces the fixed-gain Luenberger observer
%   (original L = 0.4, error pole at 0.6).
%
%   The Kalman filter improves on fixed-gain design by dynamically adapting
%   the gain based on relative process and measurement uncertainty.
%   In steady state the Kalman gain converges to ~0.4 with parameters below,
%   which validates the original Luenberger choice while providing formal
%   optimality guarantees.
%
%   Predict:  P_pred = P + Q
%   Update:   K = P_pred / (P_pred + R_noise)
%             theta_hat = theta_pred + K * (y - theta_pred)
%             P = (1 - K) * P_pred

params.Q = 0.001;             % Process noise covariance [(m^3/m^3)^2]
                               %   Represents unmodelled disturbances:
                               %   rainfall variance, soil heterogeneity.

params.R_noise = 0.0001;      % Measurement noise covariance [(m^3/m^3)^2]
                               %   Equal to sigma_sensor^2 = 0.01^2.

% ========================= CONTROLLER ===================================
params.min_gap = 3;           % Minimum iterations between irrigations [–]
                               %   Prevents rapid on/off cycling (chattering).

end