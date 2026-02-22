function live_digital_twin()
% LIVE_DIGITAL_TWIN - Real-time digital twin loop reading ThingSpeak sensors.
%
% Syntax:
%   live_digital_twin()
%
% Description:
%   Continuously reads ESP32 sensor data from ThingSpeak (fields 1-3),
%   runs the Kalman-filter state estimator, makes irrigation decisions
%   via the digital twin controller, and publishes the relay command
%   back to ThingSpeak (field 4).
%
%   Press Ctrl+C to stop.
%
% ThingSpeak Field Mapping:
%   Field 1 — Soil moisture (raw ADC, 0–4095)
%   Field 2 — Temperature (deg C, from DHT22)
%   Field 3 — Humidity (%, from DHT22)
%   Field 4 — Irrigation command (0 = OFF, 1 = ON)  [written by this script]
%
% Environment Variables Required:
%   THINGSPEAK_CHANNEL_ID  — numeric channel ID
%   THINGSPEAK_READ_KEY    — channel Read API Key
%   THINGSPEAK_WRITE_KEY   — channel Write API Key
%
%   Set them before running:
%     setenv('THINGSPEAK_CHANNEL_ID', 'YOUR_CHANNEL_ID');
%     setenv('THINGSPEAK_READ_KEY',   'YOUR_READ_KEY');
%     setenv('THINGSPEAK_WRITE_KEY',  'YOUR_WRITE_KEY');
%
% Dependencies:
%   parameters.m, evapotranspiration_model.m, soil_moisture_model.m,
%   plant_stress_model.m, digital_twin_estimator.m,
%   digital_twin_controller.m, send_irrigation_cmd.m
%
% Author:  <Your Name>
% Date:    2026-02-20

clc; clear;

disp('===========================================');
disp('  LIVE DIGITAL TWIN STARTED');
disp('  Press Ctrl+C to stop');
disp('===========================================');

% ---- ThingSpeak configuration (from environment) -----------------------
channelID = str2double(getenv('THINGSPEAK_CHANNEL_ID'));
readKey   = getenv('THINGSPEAK_READ_KEY');

assert(~isnan(channelID), ...
    'Set THINGSPEAK_CHANNEL_ID environment variable before running.');
assert(~isempty(readKey), ...
    'Set THINGSPEAK_READ_KEY environment variable before running.');

% ---- Project path setup ------------------------------------------------
projectRoot = pwd;
addpath(genpath(projectRoot));

% ---- Load parameters ---------------------------------------------------
params = parameters();

% ---- Initial states -----------------------------------------------------
theta_hat = 0.25;       % initial soil moisture estimate [m^3/m^3]
PSI_hat   = 0;          % initial plant stress index [–]

% ---- Controller state ---------------------------------------------------
iteration_count  = 1;
last_irr_iter    = -inf;   % no previous irrigation

% ---- Last valid sensor cache (for graceful degradation) -----------------
lastSoil = NaN;
lastTemp = NaN;
lastHum  = NaN;

% =========================================================================
%  MAIN LOOP
% =========================================================================
while true
    try
        % ---- Read sensor data from ThingSpeak ---------------------------
        soil_raw = thingSpeakRead(channelID, ...
            'ReadKey', readKey, 'Fields', 1, 'NumPoints', 1);
        temp = thingSpeakRead(channelID, ...
            'ReadKey', readKey, 'Fields', 2, 'NumPoints', 1);
        hum = thingSpeakRead(channelID, ...
            'ReadKey', readKey, 'Fields', 3, 'NumPoints', 1);

        % ---- Data validation with cache fallback ------------------------
        if isnan(soil_raw) || isempty(soil_raw)
            disp('Waiting for valid data — using cached values...');
            soil_raw = lastSoil;
            temp     = lastTemp;
            hum      = lastHum;
        else
            % Update cache only on valid reads
            lastSoil = soil_raw;
            lastTemp = temp;
            lastHum  = hum;
        end

        % Hard fail: skip cycle if we have never received valid data
        if isnan(soil_raw) || isnan(temp)
            disp('No valid data yet. Skipping cycle...');
            pause(20);
            continue;
        end

        % ---- Normalize soil ADC to volumetric moisture ------------------
        %   ESP32 ADC returns 0–4095.  This linear mapping is a first
        %   approximation.  For production use, replace with a sensor-
        %   specific calibration curve.
        soil_raw   = double(soil_raw);
        theta_meas = soil_raw / 4095;
        theta_meas = max(0, min(1, theta_meas));

        % ---- Compute ET using Hargreaves-Samani -------------------------
        %   We have a single temperature reading from ThingSpeak (field 2).
        %   Approximate daily range: T_max ≈ T + 5, T_min ≈ T - 5.
        T_mean = double(temp);
        T_max  = T_mean + 5;
        T_min  = T_mean - 5;
        ET = evapotranspiration_model(T_mean, T_max, T_min, params);

        % ---- Controller decision (based on current estimates) -----------
        [I, last_irr_iter] = digital_twin_controller( ...
            theta_hat, PSI_hat, iteration_count, last_irr_iter, params);

        % ---- Kalman filter estimator (uses actual irrigation decision) --
        [theta_hat, PSI_hat] = digital_twin_estimator( ...
            theta_hat, theta_meas, PSI_hat, I, ET, 0, params);

        % ---- Advance iteration counter ----------------------------------
        iteration_count = iteration_count + 1;

        % ---- Console display --------------------------------------------
        fprintf('\n[Iter %d]  Soil(raw)=%.0f | theta_hat=%.3f | PSI=%.3f | ET=%.4f\n', ...
            iteration_count, soil_raw, theta_hat, PSI_hat, ET);

        if I > 0
            disp('>>> DECISION: IRRIGATE');
            cmd = 1;
        else
            disp('    DECISION: NO IRRIGATION');
            cmd = 0;
        end

        % ---- Send command to ThingSpeak field 4 -------------------------
        send_irrigation_cmd(cmd);

    catch ME
        fprintf('\n[ERROR] %s — skipping cycle\n', ME.message);
    end

    % ---- Rate-limit pause (ThingSpeak free tier ≥ 15 s) -----------------
    pause(20);
end

end
