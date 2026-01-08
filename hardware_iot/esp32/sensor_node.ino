#include <WiFi.h>
#include <HTTPClient.h>
#include "DHT.h"

// ------------------ USER CONFIG ------------------
const char* WIFI_SSID = "YOUR_WIFI_NAME";
const char* WIFI_PASS = "YOUR_WIFI_PASSWORD";

// MATLAB server IP (PC running MATLAB)
const char* MATLAB_SERVER = "http://192.168.1.100:8080/sensor";

// ------------------------------------------------

#define SOIL_PIN 34
#define DHTPIN 4
#define DHTTYPE DHT22

DHT dht(DHTPIN, DHTTYPE);

// Moving average filter
const int N = 10;
int soilBuf[N];
int idx = 0;

int readSoilFiltered() {
  soilBuf[idx] = analogRead(SOIL_PIN);
  idx = (idx + 1) % N;

  long sum = 0;
  for (int i = 0; i < N; i++) sum += soilBuf[i];
  return sum / N;
}

void setup() {
  Serial.begin(115200);
  dht.begin();

  for (int i = 0; i < N; i++) {
    soilBuf[i] = analogRead(SOIL_PIN);
  }

  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("Connecting WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Connected");
}

void loop() {
  int soil = readSoilFiltered();
  float temp = dht.readTemperature();
  float hum  = dht.readHumidity();

  if (isnan(temp) || isnan(hum)) {
    Serial.println("Sensor read failed");
    delay(5000);
    return;
  }

  Serial.printf("Soil=%d Temp=%.2f Hum=%.2f\n", soil, temp, hum);

  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(MATLAB_SERVER);
    http.addHeader("Content-Type", "application/json");

    String payload = "{";
    payload += "\"soil\":" + String(soil) + ",";
    payload += "\"temp\":" + String(temp) + ",";
    payload += "\"hum\":"  + String(hum);
    payload += "}";

    int code = http.POST(payload);
    Serial.println("POST status: " + String(code));
    http.end();
  }

  delay(10000); // every 10 seconds
}
