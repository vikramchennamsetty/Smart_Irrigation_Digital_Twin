function send_irrigation_cmd(cmd)
% SEND_IRRIGATION_CMD - Publish irrigation relay command to ThingSpeak.
%
% Syntax:
%   send_irrigation_cmd(cmd)
%
% Inputs:
%   cmd - Relay command: 0 (OFF) or 1 (ON)  [integer]
%
% Description:
%   Writes the irrigation decision to ThingSpeak Field 4.  The relay
%   node (ESP32) polls this field and actuates the solenoid valve.
%
% Environment Variables Required:
%   THINGSPEAK_CHANNEL_ID — numeric channel ID
%   THINGSPEAK_WRITE_KEY  — channel Write API Key
%
%   Set them before running:
%     setenv('THINGSPEAK_WRITE_KEY', 'YOUR_WRITE_API_KEY');
%     setenv('THINGSPEAK_CHANNEL_ID', '3213225');
%
% Dependencies: ThingSpeak Support Toolbox
% Author:  <Your Name>
% Date:    2026-02-20

writeKey  = getenv('THINGSPEAK_WRITE_KEY');
channelID = str2double(getenv('THINGSPEAK_CHANNEL_ID'));

assert(~isempty(writeKey), ...
    'Set THINGSPEAK_WRITE_KEY as environment variable before running.');
assert(~isnan(channelID), ...
    'Set THINGSPEAK_CHANNEL_ID as environment variable before running.');

thingSpeakWrite(channelID, cmd, ...
    'WriteKey', writeKey, ...
    'Fields', 4);

end
