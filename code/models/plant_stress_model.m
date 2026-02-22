function PSI_next = plant_stress_model(PSI_curr, theta_hat, params)
% PLANT_STRESS_MODEL - Normalized plant water-stress index.
%
% Syntax:
%   PSI_next = plant_stress_model(PSI_curr, theta_hat, params)
%
% Inputs:
%   PSI_curr  - Current plant stress index                [–, 0..1]
%   theta_hat - Estimated soil moisture (from observer)   [m^3/m^3]
%   params    - Parameter struct (requires theta_min, alpha_stress,
%               beta_recover)
%
% Outputs:
%   PSI_next  - Updated plant stress index                [–, 0..1]
%
% Method:
%   When soil moisture is below the stress threshold (theta_min), stress
%   accumulates proportionally to the deficit:
%
%       S = alpha_stress * (theta_min - theta) / theta_min     (stress)
%
%   When soil moisture is adequate (theta >= theta_min), stress recovers:
%
%       S = -beta_recover * PSI_curr                           (recovery)
%
%   The stress index is then updated and clamped to [0, 1]:
%
%       PSI(k+1) = clamp( PSI(k) + S,  0,  1 )
%
%   A value of 0 means no stress; 1 means maximum stress.
%
% Dependencies: parameters.m
% Author:  <Your Name>
% Date:    2026-02-20

theta_min     = params.theta_min;
alpha_stress  = params.alpha_stress;
beta_recover  = params.beta_recover;

% ---- Stress / recovery logic -------------------------------------------
if theta_hat < theta_min
    % Stress accumulates — severity proportional to normalised deficit.
    S = alpha_stress * (theta_min - theta_hat) / theta_min;
else
    % Recovery — stress decays exponentially toward zero.
    S = -beta_recover * PSI_curr;
end

% ---- Update and clamp to [0, 1] ----------------------------------------
PSI_next = PSI_curr + S;
PSI_next = max(0, min(1, PSI_next));

end
