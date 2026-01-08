function [theta_hat_next, PSI_next] = digital_twin_estimator( ...
    theta_hat, y_meas, PSI, I, ET, R, params)
% DESIGN NOTE:
% A fixed-gain observer is used instead of a Kalman Filter to keep the
% digital twin computationally lightweight and suitable for real-time
% embedded deployment.
%
% The focus of this implementation is control-oriented state estimation
% rather than optimal stochastic filtering.
%
% Kalman filtering and adaptive estimation are considered as future
% extensions once sufficient real-world noise statistics are available.

L = 0.4;   % observer gain

% Prediction step
theta_pred = soil_moisture_model(theta_hat, I, ET, R, params);

% Correct
theta_hat_next = theta_pred + L*(y_meas - theta_pred);

% Stress update
PSI_next = plant_stress_model(PSI, theta_hat_next, params);

end
