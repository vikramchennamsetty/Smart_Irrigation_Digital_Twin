function live_digital_twin
clc;
clear;

disp("LIVE DIGITAL TWIN STARTED");
disp("Press Ctrl+C to stop");

% ThingSpeak configuration
channelID = 3213225;
readKey   = 'VG7AS1112AAD8B09';   % Read API Key
writeKey  = 'YTK1QPQFUHM75T5G';   % Write API Key (Field 4)

% Project path
projectRoot = pwd;
addpath(genpath(projectRoot));

% Load parameters
params = parameters();
params.current_day = 1;

% Initial states
theta_hat = 0.25;   % estimated soil moisture
PSI_hat   = 0;      % plant stress index

% Last valid cache
lastSoil = NaN;
lastTemp = NaN;
lastHum  = NaN;

% Main loop
while true
    try
        % Read sensor data
        soil_raw = thingSpeakRead(channelID, ...
            'ReadKey', readKey, ...
            'Fields', 1, ...
            'NumPoints', 1);

        temp = thingSpeakRead(channelID, ...
            'ReadKey', readKey, ...
            'Fields', 2, ...
            'NumPoints', 1);

        hum = thingSpeakRead(channelID, ...
            'ReadKey', readKey, ...
            'Fields', 3, ...
            'NumPoints', 1);

        % Data validation
        if isnan(soil_raw) || isempty(soil_raw)
            disp("Waiting for valid data...");
            soil_raw = lastSoil;
            temp     = lastTemp;
            hum      = lastHum;
        else
            lastSoil = soil_raw;
            lastTemp = temp;
            lastHum  = hum;
        end

        % Hard fail protection
        if isnan(soil_raw)
            disp("No valid data yet. Skipping cycle...");
            pause(20);
            continue;
        end

        % Normalize soil (ESP32 ADC)
        soil_raw  = double(soil_raw);
        theta_meas = soil_raw / 4095;
        theta_meas = max(0, min(1, theta_meas));

        % Environment model
        ET = evapotranspiration_model();

        % Digital twin estimator
        [theta_hat, PSI_hat] = digital_twin_estimator( ...
            theta_hat, ...
            theta_meas, ...
            PSI_hat, ...
            0, ...
            ET, ...
            0, ...
            params);

        % Safety reset
        if isnan(theta_hat) || isnan(PSI_hat)
            warning("Estimator unstable — resetting states");
            theta_hat = 0.25;
            PSI_hat   = 0;
        end

        % Control decision
        I = digital_twin_controller(theta_hat, PSI_hat, params);

        % Display
        fprintf("\nSoil(raw)=%.0f | θ_hat=%.3f | PSI=%.3f\n", ...
            soil_raw, theta_hat, PSI_hat);

        if I > 0
            disp("DECISION: IRRIGATE");
            cmd = 1;
        else
            disp("DECISION: NO IRRIGATION");
            cmd = 0;
        end

        % Send command to ThingSpeak (Field 4)
        thingSpeakWrite(channelID, cmd, ...
            'WriteKey', writeKey, ...
            'Fields', 4);

    catch ME
        disp("ERROR OCCURRED — SKIPPING CYCLE");
        disp(ME.message);
    end
    params.current_day = params.current_day + 1;
    pause(20);
end
end
