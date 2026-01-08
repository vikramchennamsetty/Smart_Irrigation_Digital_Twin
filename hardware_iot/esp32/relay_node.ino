#include <WiFi.h>
#include <HTTPClient.h>

// ================= WIFI =================
const char* WIFI_SSID = "Wokwi-GUEST";
const char* WIFI_PASS = "";

// ================= THINGSPEAK =================
const int CHANNEL_ID = 3213225;
const char* READ_KEY = "VG7AS1112AAD8B09";

// ================= HARDWARE =================
#define RELAY_PIN 26   // Relay IN pin

void setup() {
  Serial.begin(115200);

  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);  // SAFE DEFAULT

  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("Connecting WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Connected");
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {

    String url = "http://api.thingspeak.com/channels/";
    url += CHANNEL_ID;
    url += "/fields/4/last.json?api_key=";
    url += READ_KEY;

    HTTPClient http;
    http.begin(url);
    int code = http.GET();

    if (code == 200) {
      String payload = http.getString();

      if (payload.indexOf("1") >= 0) {
        digitalWrite(RELAY_PIN, HIGH);
        Serial.println("VALVE ON");
      } else {
        digitalWrite(RELAY_PIN, LOW);
        Serial.println("VALVE OFF");
      }
    }

    http.end();
  }

  delay(15000);  // ThingSpeak rate
}
