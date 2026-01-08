function theta_next = soil_moisture_model(theta_curr, I, ET, R, params)
% SOIL MOISTURE MODEL WITH HARD PHYSICAL CONSTRAINTS

theta_fc = params.theta_fc;
theta_wp = params.theta_wp;
kd       = params.kd;

% Drainage
if theta_curr > theta_fc
    D = kd * (theta_curr - theta_fc);
else
    D = 0;
end

% Water balance
theta_next = theta_curr + I + R - ET - D;

% HARD CLAMPS (CRITICAL)
theta_next = max(theta_wp, theta_next);
theta_next = min(theta_fc, theta_next);

end
