clc; clear; close all;

% =========================
% PARAMETERS
% =========================
params = parameters();
params.current_day = 1;

N = 60;
R = 0;   % no rainfall

% =========================
% INITIAL CONDITIONS
% =========================
theta_b   = zeros(1,N);
theta_adv = zeros(1,N);
theta_hat = zeros(1,N);
PSI_adv   = zeros(1,N);

theta_b(1)   = 0.25;
theta_adv(1) = 0.25;
theta_hat(1) = 0.24;
PSI_adv(1)   = 0;

I_b   = zeros(1,N);
I_adv = zeros(1,N);

% =========================
% SIMULATION LOOP
% =========================
for k = 1:N-1
    params.current_day = k;

    ET = evapotranspiration_model();

    % -------- BASELINE --------
    I_b(k) = baseline_controller(theta_b(k), params);
    theta_b(k+1) = soil_moisture_model( ...
        theta_b(k), I_b(k), ET, R, params);

    % -------- ADVANCED --------
    % Measurement
    y = theta_adv(k) + params.sigma_sensor * randn;

    % Controller decision FIRST (KEY FIX)
    I_adv(k) = digital_twin_controller(theta_hat(k), PSI_adv(k), params);

    % Digital twin update
    [theta_hat(k+1), PSI_adv(k+1)] = digital_twin_estimator( ...
        theta_hat(k), y, PSI_adv(k), I_adv(k), ET, R, params);

    % True soil update
    theta_adv(k+1) = soil_moisture_model( ...
        theta_adv(k), I_adv(k), ET, R, params);
end

% =========================
% METRICS
% =========================
Water_baseline = sum(I_b);
Water_advanced = sum(I_adv);

disp(['Water_baseline = ', num2str(Water_baseline)]);
disp(['Water_advanced = ', num2str(Water_advanced)]);

% =========================
% PLOTS
% =========================
figure;

subplot(3,1,1)
plot(theta_b,'r','LineWidth',2); hold on;
plot(theta_adv,'b','LineWidth',2);
yline(params.theta_min,'k--');
title('Soil Moisture Comparison');
legend('Baseline','Advanced');
grid on;

subplot(3,1,2)
plot(PSI_adv,'b','LineWidth',2);
title('Plant Stress Index (Advanced)');
grid on;

subplot(3,1,3)
bar([Water_baseline Water_advanced]);
set(gca,'XTickLabel',{'Baseline','Advanced'});
title('Total Water Usage');
grid on;
