function ET = evapotranspiration_model(T, RH)
% EVAPOTRANSPIRATION_MODEL
% Simple weather-dependent evapotranspiration approximation
%
% Assumptions:
% - Linear dependence on temperature
% - Reduced ET at high relative humidity
% - Intended for control-oriented digital twin, not agronomic precision
%
% Inputs:
%   T  - Temperature (°C)
%   RH - Relative Humidity (0–1)
%
% Output:
%   ET - Normalized evapotranspiration rate

% Coefficients (tuned for qualitative realism)
k1 = 0.02;    % temperature contribution
k2 = 0.01;    % humidity suppression

ET = k1 * T + k2 * (1 - RH);

% Safety bounds
ET = max(0, ET);
end
