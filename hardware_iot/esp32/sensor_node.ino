// sensor_node.ino — ESP32 Sensor Node for Smart Irrigation Digital Twin
//
// PURPOSE:
//   Reads soil moisture (capacitive ADC), temperature, and humidity
//   (DHT22) and publishes them to ThingSpeak fields 1–3 every 15 seconds.
//
// THINGSPEAK FIELD MAPPING:
//   Field 1 — Soil moisture (raw ADC, 0–4095)
//   Field 2 — Temperature  (deg C)
//   Field 3 — Humidity     (%)
//
// HARDWARE:
//   - ESP32 DevKit v1
//   - Capacitive soil moisture sensor on GPIO 34 (ADC)
//   - DHT22 temperature/humidity sensor on GPIO 4
//
// CREDENTIALS:
//   WiFi and ThingSpeak keys are loaded from config.h.
//   Fill in config.h before compiling.
//
// Author:  <Your Name>
// Date:    2026-02-20

#include <WiFi.h>
#include <HTTPClient.h>
#include "DHT.h"
#include "config.h"    // WIFI_SSID, WIFI_PASSWORD, THINGSPEAK_WRITE_KEY

// ========================= SENSOR PINS ==================================
#define SOIL_PIN  34       // Capacitive soil moisture sensor (ADC input)
#define DHTPIN    4        // DHT22 data pin
#define DHTTYPE   DHT22

DHT dht(DHTPIN, DHTTYPE);

// ========================= MOVING AVERAGE FILTER ========================
//   Simple window-based filter to smooth noisy ADC readings.
const int FILTER_SIZE = 5;
int soilBuffer[FILTER_SIZE];
int bufferIndex = 0;

int readSoilFiltered() {
    soilBuffer[bufferIndex] = analogRead(SOIL_PIN);
    bufferIndex = (bufferIndex + 1) % FILTER_SIZE;

    long sum = 0;
    for (int i = 0; i < FILTER_SIZE; i++) {
        sum += soilBuffer[i];
    }
    return (int)(sum / FILTER_SIZE);
}

// ========================= SETUP ========================================
void setup() {
    Serial.begin(115200);
    dht.begin();

    // Pre-fill the filter buffer with initial readings
    for (int i = 0; i < FILTER_SIZE; i++) {
        soilBuffer[i] = analogRead(SOIL_PIN);
        delay(50);
    }

    // Connect to WiFi
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    Serial.print("Connecting to WiFi");
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\nWiFi Connected");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
}

// ========================= MAIN LOOP ====================================
void loop() {
    // ---- Read sensors --------------------------------------------------
    int   soil = readSoilFiltered();
    float temp = dht.readTemperature();
    float hum  = dht.readHumidity();

    // ---- Validate DHT22 readings ---------------------------------------
    if (isnan(temp) || isnan(hum)) {
        Serial.println("[WARN] DHT22 read failed — retrying next cycle");
        delay(5000);
        return;
    }

    // ---- Debug output --------------------------------------------------
    Serial.printf("Soil=%d | Temp=%.1f C | Hum=%.1f %%\n", soil, temp, hum);

    // ---- POST to ThingSpeak --------------------------------------------
    if (WiFi.status() == WL_CONNECTED) {
        HTTPClient http;
        http.begin("http://api.thingspeak.com/update");
        http.addHeader("Content-Type", "application/x-www-form-urlencoded");

        // Build payload: field1=soil, field2=temp, field3=hum
        String payload = "api_key=" + String(THINGSPEAK_WRITE_KEY) +
                         "&field1=" + String(soil) +
                         "&field2=" + String(temp, 2) +
                         "&field3=" + String(hum, 2);

        int httpCode = http.POST(payload);

        if (httpCode > 0) {
            Serial.printf("ThingSpeak POST → HTTP %d\n", httpCode);
        } else {
            Serial.printf("[ERROR] ThingSpeak POST failed: %s\n",
                          http.errorToString(httpCode).c_str());
        }

        http.end();
    } else {
        Serial.println("[WARN] WiFi disconnected — skipping POST");
    }

    // ---- Rate-limit delay (ThingSpeak free tier: >= 15 s) --------------
    delay(15000);
}
