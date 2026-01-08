function I = digital_twin_controller(theta_hat, PSI_hat, params)
% FINAL DIGITAL TWIN CONTROLLER WITH EVENT SPACING

persistent last_irrigation_day
if isempty(last_irrigation_day)
    last_irrigation_day = -inf;
end

current_day = params.current_day;

theta_LB = theta_hat - 2*params.sigma_sensor;

min_gap = 3;   % minimum days between irrigations

if (theta_LB < params.theta_min || PSI_hat > params.PSI_max) && ...
        (current_day - last_irrigation_day >= min_gap)

    I = params.I_fixed;
    last_irrigation_day = current_day;

else
    I = 0;
end

end
