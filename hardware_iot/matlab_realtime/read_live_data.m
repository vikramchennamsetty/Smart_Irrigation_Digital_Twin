function data = read_live_data(channelID, readKey)
% READ_LIVE_DATA - Read latest sensor data from ThingSpeak (fields 1-3).
%
% Syntax:
%   data = read_live_data(channelID, readKey)
%
% Inputs:
%   channelID - ThingSpeak channel ID                     [numeric]
%   readKey   - ThingSpeak Read API Key                   [string]
%
% Outputs:
%   data      - struct with fields:
%                 .soil     — raw soil moisture ADC value  [0–4095]
%                 .temp     — air temperature              [deg C]
%                 .humidity — relative humidity             [%]
%                 .valid    — true if all reads succeeded   [logical]
%
% Description:
%   Reads the most recent data point from each ThingSpeak field.
%   If any read returns NaN, the valid flag is set to false so the
%   caller can decide how to handle missing data.
%
% Dependencies: ThingSpeak Support Toolbox
% Author:  <Your Name>
% Date:    2026-02-20

data.soil     = NaN;
data.temp     = NaN;
data.humidity = NaN;
data.valid    = false;

try
    data.soil = thingSpeakRead(channelID, ...
        'ReadKey', readKey, 'Fields', 1, 'NumPoints', 1);
    data.temp = thingSpeakRead(channelID, ...
        'ReadKey', readKey, 'Fields', 2, 'NumPoints', 1);
    data.humidity = thingSpeakRead(channelID, ...
        'ReadKey', readKey, 'Fields', 3, 'NumPoints', 1);

    if ~isnan(data.soil) && ~isnan(data.temp) && ~isnan(data.humidity)
        data.valid = true;
    end
catch ME
    warning('read_live_data:readFailed', ...
        'ThingSpeak read failed: %s', ME.message);
end

end
