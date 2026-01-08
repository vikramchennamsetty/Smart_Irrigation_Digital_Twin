function [theta_hat_next, PSI_next] = digital_twin_estimator( ...
    theta_hat, y_meas, PSI, I, ET, R, params)

L = 0.4;   % observer gain

% Predict
theta_pred = soil_moisture_model(theta_hat, I, ET, R, params);

% Correct
theta_hat_next = theta_pred + L*(y_meas - theta_pred);

% Stress update
PSI_next = plant_stress_model(PSI, theta_hat_next, params);

end
