// relay_node.ino — ESP32 Relay Node for Smart Irrigation Digital Twin
//
// PURPOSE:
//   Polls ThingSpeak Field 4 for the irrigation command published by
//   the MATLAB digital twin.  Actuates a relay (solenoid valve) based
//   on the received value:  1 = VALVE ON,  0 = VALVE OFF.
//
// THINGSPEAK FIELD MAPPING:
//   Field 4 — Irrigation command (0 = OFF, 1 = ON)  [read by this node]
//
// HARDWARE:
//   - ESP32 DevKit v1
//   - Relay module on GPIO 26 (active-HIGH)
//
// SAFETY:
//   Relay defaults to LOW (OFF) on boot and on any communication failure.
//
// CREDENTIALS:
//   WiFi and ThingSpeak keys are loaded from config.h.
//
// Author:  <Your Name>
// Date:    2026-02-20

#include <WiFi.h>
#include <HTTPClient.h>
#include "config.h"    // WIFI_SSID, WIFI_PASSWORD, THINGSPEAK_READ_KEY

// ========================= HARDWARE =====================================
#define RELAY_PIN 26       // Relay IN pin (active-HIGH)

// ========================= SETUP ========================================
void setup() {
    Serial.begin(115200);

    // Relay defaults to OFF (safe state)
    pinMode(RELAY_PIN, OUTPUT);
    digitalWrite(RELAY_PIN, LOW);

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
    if (WiFi.status() == WL_CONNECTED) {
        // ---- Build ThingSpeak read URL ---------------------------------
        String url = "http://api.thingspeak.com/channels/";
        url += String(THINGSPEAK_CHANNEL_ID);
        url += "/fields/4/last.json?api_key=";
        url += String(THINGSPEAK_READ_KEY);

        HTTPClient http;
        http.begin(url);
        int httpCode = http.GET();

        if (httpCode == 200) {
            String payload = http.getString();
            Serial.print("Response: ");
            Serial.println(payload);

            // Parse field4 value — look for "1" in the JSON response
            if (payload.indexOf("\"1\"") >= 0) {
                digitalWrite(RELAY_PIN, HIGH);
                Serial.println(">>> VALVE ON");
            } else {
                digitalWrite(RELAY_PIN, LOW);
                Serial.println("    VALVE OFF");
            }
        } else {
            // Communication failure → safe default: valve OFF
            Serial.printf("[WARN] HTTP %d — defaulting valve OFF\n", httpCode);
            digitalWrite(RELAY_PIN, LOW);
        }

        http.end();
    } else {
        // WiFi lost → safe default: valve OFF
        Serial.println("[WARN] WiFi disconnected — valve OFF");
        digitalWrite(RELAY_PIN, LOW);
    }

    // ---- Rate-limit delay (ThingSpeak free tier: >= 15 s) --------------
    delay(15000);
}
