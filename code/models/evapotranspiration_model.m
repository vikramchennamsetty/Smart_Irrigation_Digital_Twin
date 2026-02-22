function ET = evapotranspiration_model(T_mean, T_max, T_min, params)
% EVAPOTRANSPIRATION_MODEL - Hargreaves-Samani reference evapotranspiration.
%
% Syntax:
%   ET = evapotranspiration_model(T_mean, T_max, T_min, params)
%
% Inputs:
%   T_mean - Mean daily air temperature                       [deg C]
%   T_max  - Maximum daily air temperature                    [deg C]
%   T_min  - Minimum daily air temperature                    [deg C]
%   params - Parameter struct from parameters.m (requires Ra, ET_scale)
%
% Outputs:
%   ET     - Reference evapotranspiration as volumetric fraction [m^3/m^3]
%
% Method:
%   Hargreaves-Samani equation (Hargreaves & Samani, 1985):
%
%       ET0 = 0.0023 * Ra * (T_mean + 17.8) * sqrt(T_max - T_min)
%
%   where:
%       Ra     = extraterrestrial radiation           [MJ/m^2/day]
%       ET0    = reference crop evapotranspiration     [mm/day]
%
%   The result is converted to a volumetric soil-moisture fraction by
%   dividing by params.ET_scale (effective root-zone depth scaling):
%
%       ET = ET0 / ET_scale
%
%   This allows the soil moisture model (which operates in [m^3/m^3])
%   to subtract ET directly from the moisture state.
%
% Reference:
%   Hargreaves, G.H. and Samani, Z.A. (1985). "Reference Crop
%   Evapotranspiration from Temperature." Applied Engineering in
%   Agriculture, 1(2), 96-99.
%
%   Allen, R.G. et al. (1998). "Crop evapotranspiration — Guidelines
%   for computing crop water requirements." FAO-56, Rome.
%
% Dependencies: parameters.m
% Author:  <Your Name>
% Date:    2026-02-20

% ---- Input guards -------------------------------------------------------
delta_T = T_max - T_min;

% Temperature range must be non-negative; guard against bad sensor data.
if delta_T < 0
    warning('evapotranspiration_model:negDeltaT', ...
        'T_max < T_min (%.2f < %.2f). Clamping delta_T to 0.', T_max, T_min);
    delta_T = 0;
end

% ---- Hargreaves-Samani equation -----------------------------------------
%   ET0 [mm/day] = 0.0023 * Ra * (T_mean + 17.8) * sqrt(delta_T)
Ra  = params.Ra;            % extraterrestrial radiation [MJ/m^2/day]
ET0 = 0.0023 * Ra * (T_mean + 17.8) * sqrt(delta_T);   % [mm/day]

% ---- Convert to volumetric fraction -------------------------------------
ET = ET0 / params.ET_scale;

% ET must be non-negative (physically, evaporation cannot add water).
ET = max(0, ET);

end
