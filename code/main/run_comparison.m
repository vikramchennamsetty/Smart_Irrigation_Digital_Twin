% RUN_COMPARISON - Offline simulation comparing baseline vs digital-twin control.
%
% Description:
%   Simulates N=100 days of soil moisture dynamics with synthetic weather.
%   Compares a naive threshold controller (baseline) against the Kalman-
%   filter-based digital twin controller.  Produces three plots and
%   prints water-usage metrics to the console.
%
% Outputs:
%   - Figure saved to results/matlab_outputs/comparison_plot.png
%   - Console printout of total water used by each strategy
%
% Dependencies:
%   parameters.m, evapotranspiration_model.m, soil_moisture_model.m,
%   plant_stress_model.m, digital_twin_estimator.m,
%   digital_twin_controller.m, baseline_controller.m
%
% Author:  Vikram Chennamsetty, Nikitha Sai Udatha
% Date:    2026-02-20

clc; clear; close all;

% =========================================================================
%  PARAMETERS
% =========================================================================
params = parameters();
N = 100;   % simulation horizon [days]
R = 0;     % rainfall (set to 0 for controlled comparison)

% =========================================================================
%  SYNTHETIC WEATHER GENERATION
% =========================================================================
rng(42);  % fix seed for reproducibility

T_mean_base = 28;
T_range     = 10;

T_mean = T_mean_base + 3 * randn(1, N);
T_max  = T_mean + T_range/2 + 1.5 * randn(1, N);
T_min  = T_mean - T_range/2 + 1.5 * randn(1, N);
T_max  = max(T_max, T_min + 1);   % ensure T_max > T_min

% =========================================================================
%  PRE-ALLOCATE STATE ARRAYS
% =========================================================================
theta_b   = zeros(1, N);
theta_adv = zeros(1, N);
theta_hat = zeros(1, N);
PSI_b     = zeros(1, N);
PSI_adv   = zeros(1, N);
I_b       = zeros(1, N);
I_adv     = zeros(1, N);

% Initial conditions
theta_b(1)   = 0.25;
theta_adv(1) = 0.25;
theta_hat(1) = 0.24;
PSI_b(1)     = 0;
PSI_adv(1)   = 0;

last_irr_iter = -inf;

% =========================================================================
%  SIMULATION LOOP
% =========================================================================
for k = 1:N-1

    ET = evapotranspiration_model(T_mean(k), T_max(k), T_min(k), params);

    % ---- BASELINE -------------------------------------------------------
    I_b(k)       = baseline_controller(theta_b(k), params);
    theta_b(k+1) = soil_moisture_model(theta_b(k), I_b(k), ET, R, params);
    % FIX: correct argument order — (PSI_curr, theta_hat, params)
    PSI_b(k+1)   = plant_stress_model(PSI_b(k), theta_b(k+1), params);

    % ---- ADVANCED (DIGITAL TWIN) ----------------------------------------
    y = theta_adv(k) + params.sigma_sensor * randn;
    y = max(0, min(1, y));

    [I_adv(k), last_irr_iter] = digital_twin_controller( ...
        theta_hat(k), PSI_adv(k), k, last_irr_iter, params);

    % Kalman estimator — pass actual irrigation decision (not 0)
    [theta_hat(k+1), PSI_adv(k+1)] = digital_twin_estimator( ...
        theta_hat(k), y, PSI_adv(k), I_adv(k), ET, R, params);

    theta_adv(k+1) = soil_moisture_model( ...
        theta_adv(k), I_adv(k), ET, R, params);
end

% =========================================================================
%  METRICS
% =========================================================================
Water_baseline = sum(I_b);
Water_advanced = sum(I_adv);
Savings_pct    = (1 - Water_advanced / max(Water_baseline, eps)) * 100;

StressDays_b   = sum(PSI_b   > 0.5);
StressDays_adv = sum(PSI_adv > 0.5);

fprintf('\n========== WATER USAGE SUMMARY ==========\n');
fprintf('  Baseline total irrigation : %.4f\n', Water_baseline);
fprintf('  Digital Twin total        : %.4f\n', Water_advanced);
fprintf('  Water savings             : %.1f %%\n', Savings_pct);
fprintf('==========================================\n');
fprintf('\n========== PLANT STRESS SUMMARY ==========\n');
fprintf('  Baseline high-stress days : %d / %d\n', StressDays_b,   N);
fprintf('  Digital Twin stress days  : %d / %d\n', StressDays_adv, N);
fprintf('==========================================\n\n');

% =========================================================================
%  PLOTS
% =========================================================================
fig = figure('Position', [100, 100, 900, 750]);

% ---- Subplot 1: Soil Moisture -------------------------------------------
subplot(3, 1, 1);
plot(1:N, theta_b,   'r-',  'LineWidth', 1.8); hold on;
plot(1:N, theta_adv, 'b-',  'LineWidth', 1.8);
plot(1:N, theta_hat, 'b--', 'LineWidth', 1.2);
yline(params.theta_min, 'k--', 'LineWidth', 1.0);
yline(params.theta_wp,  'k:',  'LineWidth', 0.8);
ylabel('\theta [m^3/m^3]');
title('Soil Moisture Comparison');
legend('Baseline (true)', 'Digital Twin (true)', ...
       'Kalman Estimate', '\theta_{min}', '\theta_{wp}', ...
       'Location', 'best');
grid on;

% ---- Subplot 2: Plant Stress Index — BOTH strategies -------------------
% Expected result:
%   Baseline PSI (red)  — rises and stays elevated (naive control lets
%                         soil drop below theta_min frequently).
%   Digital Twin PSI (blue) — stays low because Kalman estimator
%                         triggers irrigation before stress onset.
subplot(3, 1, 2);
plot(1:N, PSI_b,   'r-', 'LineWidth', 1.8); hold on;
plot(1:N, PSI_adv, 'b-', 'LineWidth', 1.8);
yline(params.PSI_max, 'r--', 'LineWidth', 1.0);
hold off;
ylabel('\Psi [–]');
title('Plant Stress Index Comparison');
legend('\Psi_{baseline}', '\Psi_{digital twin}', '\Psi_{max}', ...
       'Location', 'best');
grid on;

% ---- Subplot 3: Irrigation Events --------------------------------------
subplot(3, 1, 3);
stem(1:N, I_b,   'r', 'LineWidth', 1.2, 'Marker', 'none'); hold on;
stem(1:N, I_adv, 'b', 'LineWidth', 1.2, 'Marker', 'none');
ylabel('I [m^3/m^3]');
xlabel('Day');
title(sprintf('Irrigation Events  |  Baseline: %.3f  |  DT: %.3f  |  Saved: %.0f%%', ...
    Water_baseline, Water_advanced, Savings_pct));
legend('Baseline', 'Digital Twin', 'Location', 'best');
grid on;

% ---- Save ---------------------------------------------------------------
outputDir = fullfile(pwd, 'results', 'matlab_outputs');
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
saveas(fig, fullfile(outputDir, 'comparison_plot.png'));
fprintf('Plot saved to: %s\n', fullfile(outputDir, 'comparison_plot.png'));