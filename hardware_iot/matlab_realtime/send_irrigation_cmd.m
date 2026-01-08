function send_irrigation_cmd(cmd)
% cmd = 0 (OFF) or 1 (ON)

writeKey = 'YTK1QPQFUHM75T5G';
channelID = 3213225;

thingSpeakWrite(channelID, cmd, ...
    'WriteKey', writeKey, ...
    'Fields', 4);

end
