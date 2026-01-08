function params = parameters()

% ================= TIME =================
params.dt = 1;                 % discrete time step (days / cycles)

% ================= SOIL MOISTURE =================
params.theta_fc   = 0.30;      % field capacity
params.theta_wp   = 0.08;      % wilting point (lower for demo)
params.theta_min  = 0.22;      % irrigation trigger threshold
params.theta_warn = 0.25;      % early warning (ADV logic)

% ================= DRAINAGE =================
params.kd = 0.35;              % moderate drainage

% ================= IRRIGATION =================
params.I_fixed = 0.05;         % stronger visible irrigation pulse

% ================= PLANT STRESS =================
params.PSI_max = 0.9;          % LOWER → trigger earlier (demo-safe)

% ================= SENSOR NOISE =================
params.sigma_sensor = 0.02;    % realistic IoT noise

end
