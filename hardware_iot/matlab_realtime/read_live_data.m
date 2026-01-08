clc;
clear;

channelID = 3213225;
readKey = 'VG7AS1112AAD8B09';

disp("MATLAB Online Live Sensor Reader Started");

while true
    data = thingSpeakRead(channelID, ...
        'ReadKey', readKey, ...
        'NumPoints', 1);

    soil = data(1);
    temp = data(2);
    hum  = data(3);

    fprintf("Soil=%d | Temp=%.2f C | Humidity=%.2f %%\n", ...
        soil, temp, hum);

    pause(15); % ThingSpeak update interval
end
