function I = baseline_controller(theta_curr, params)
% NAIVE THRESHOLD CONTROLLER

if theta_curr < params.theta_min
    I = params.I_fixed;
else
    I = 0;
end

end
