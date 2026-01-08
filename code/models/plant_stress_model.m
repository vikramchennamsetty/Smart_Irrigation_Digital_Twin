function PSI_next = plant_stress_model(PSI_curr, theta_hat, params)

theta_min = params.theta_min;

if theta_hat < theta_min
    S = (theta_min - theta_hat) / theta_min;
else
    S = 0;
end

PSI_next = PSI_curr + S;

end
