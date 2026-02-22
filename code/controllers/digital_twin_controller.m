function [I, last_irr_iter] = digital_twin_controller( ...
    theta_hat, PSI_hat, iter_count, last_irr_iter, params)
% DIGITAL_TWIN_CONTROLLER - Event-triggered irrigation controller.
%
% Syntax:
%   [I, last_irr_iter] = digital_twin_controller( ...
%       theta_hat, PSI_hat, iter_count, last_irr_iter, params)
%
% Inputs:
%   theta_hat      - Estimated soil moisture (from Kalman filter) [m^3/m^3]
%   PSI_hat        - Estimated plant stress index                 [–, 0..1]
%   iter_count     - Current iteration number                     [–]
%   last_irr_iter  - Iteration at which last irrigation occurred  [–]
%   params         - Parameter struct (requires theta_min, PSI_max,
%                    I_fixed, sigma_sensor, min_gap)
%
% Outputs:
%   I              - Irrigation decision: 0 or I_fixed            [m^3/m^3]
%   last_irr_iter  - Updated last-irrigation iteration            [–]
%
% Method:
%   The controller triggers irrigation when EITHER:
%     (a) The lower confidence bound of theta is below theta_min:
%             theta_hat - 2*sigma_sensor < theta_min
%     (b) The plant stress index exceeds PSI_max.
%
%   To prevent chattering (rapid on/off switching), irrigation is only
%   allowed if at least min_gap iterations have elapsed since the last
%   irrigation event.
%
%   Design note:
%       Using theta_LB = theta_hat - 2*sigma adds a ~95 % confidence
%       margin, making the controller robust to sensor noise.
%
% Dependencies: parameters.m
% Author:  <Your Name>
% Date:    2026-02-20

% ---- Compute lower confidence bound on moisture ------------------------
theta_LB = theta_hat - 2 * params.sigma_sensor;

% ---- Minimum spacing between irrigations --------------------------------
min_gap = params.min_gap;

% ---- Decision logic -----------------------------------------------------
need_water = (theta_LB < params.theta_min) || (PSI_hat > params.PSI_max);
gap_ok     = (iter_count - last_irr_iter) >= min_gap;

if need_water && gap_ok
    I = params.I_fixed;
    last_irr_iter = iter_count;   % record this event
else
    I = 0;
end

end
