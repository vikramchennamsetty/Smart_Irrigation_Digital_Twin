function I = baseline_controller(theta_curr, params)
% BASELINE_CONTROLLER - Naive threshold-based irrigation controller.
%
% Syntax:
%   I = baseline_controller(theta_curr, params)
%
% Inputs:
%   theta_curr - Current (measured) soil moisture         [m^3/m^3]
%   params     - Parameter struct (requires theta_min, I_fixed)
%
% Outputs:
%   I          - Irrigation decision: 0 or I_fixed        [m^3/m^3]
%
% Method:
%   Simple bang-bang control — irrigate when moisture drops below
%   theta_min, otherwise do nothing.  No debouncing, no stress
%   awareness, no estimation.  Used as the comparison benchmark
%   in run_comparison.m.
%
% Dependencies: parameters.m
% Author:  <Your Name>
% Date:    2026-02-20

if theta_curr < params.theta_min
    I = params.I_fixed;
else
    I = 0;
end

end
