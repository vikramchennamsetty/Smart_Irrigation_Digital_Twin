function theta_next = soil_moisture_model(theta_curr, I, ET, R, params)
% SOIL_MOISTURE_MODEL - Single-layer bucket model for soil moisture dynamics.
%
% Syntax:
%   theta_next = soil_moisture_model(theta_curr, I, ET, R, params)
%
% Inputs:
%   theta_curr - Current volumetric soil moisture         [m^3/m^3]
%   I          - Irrigation applied this time step        [m^3/m^3]
%   ET         - Evapotranspiration this time step        [m^3/m^3]
%   R          - Rainfall this time step                  [m^3/m^3]
%   params     - Parameter struct (requires theta_fc, theta_wp, kd)
%
% Outputs:
%   theta_next - Soil moisture at next time step          [m^3/m^3]
%
% Method:
%   Water balance equation (bucket model):
%
%       theta(k+1) = theta(k) + I + R - ET - D
%
%   where drainage D is proportional to excess above field capacity:
%
%       D = kd * max(0, theta(k) - theta_fc)
%
%   After the balance step, the result is clamped to the physical range
%   [theta_wp, theta_fc] to prevent non-physical states.
%
% Reference:
%   Hillel, D. (1998). "Environmental Soil Physics." Academic Press.
%
% Dependencies: parameters.m
% Author:  <Your Name>
% Date:    2026-02-20

theta_fc = params.theta_fc;
theta_wp = params.theta_wp;
kd       = params.kd;

% ---- Gravity-driven drainage -------------------------------------------
%   Only occurs when moisture exceeds field capacity.
if theta_curr > theta_fc
    D = kd * (theta_curr - theta_fc);
else
    D = 0;
end

% ---- Water balance equation ---------------------------------------------
theta_next = theta_curr + I + R - ET - D;

% ---- Physical clamping --------------------------------------------------
%   Soil moisture cannot fall below wilting point (capillary retention)
%   and cannot exceed field capacity (excess drains immediately).
theta_next = max(theta_wp, theta_next);
theta_next = min(theta_fc, theta_next);

end
