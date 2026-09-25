/*
 * Smart Medicine Organizer - Single Compartment (S1) Edge Hardware
 * Protocol: MQTT over Wi-Fi
 * Raspberry Pi Broker: port 1883
 * 
 * Hardware Pinout (from WIRING.md):
 * - RTC SDA      : GPIO 19
 * - RTC SCL      : GPIO 18
 * - TFT SCK      : GPIO 15
 * - TFT SDA/MOSI : GPIO 2
 * - TFT A0/DC    : GPIO 4
 * - TFT RESET    : GPIO 16 (RX2)
 * - TFT CS       : GPIO 17 (TX2)
 * - Buzzer       : GPIO 23
 * - LED (S1)     : GPIO 21
 * - Reed Switch  : GPIO 22 (INPUT_PULLUP)
 */

#include <Adafruit_GFX.h>
#include <Adafruit_ST7735.h>
#include <ArduinoJson.h>
#include <PubSubClient.h>
#include <RTClib.h>
#include <WiFi.h>
#include <Wire.h>

// =====================================================
// WI-FI & MQTT CONFIGURATION
// =====================================================
const char *WIFI_SSID = "Kiran";        // Update to your Wi-Fi SSID
const char *WIFI_PASSWORD = "[PASSWORD]"; // Update to your Wi-Fi Password

// Raspberry Pi IP Address (Mosquitto MQTT Broker)
const char *MQTT_BROKER_IP = "[IP_ADDRESS]";
const int MQTT_PORT = 1883;
const char *DEVICE_ID = "ESP32_001";

// MQTT Topics
const char *TOPIC_COMMANDS = "smart_medicine/commands";   // Pi -> ESP32
const char *TOPIC_SCHEDULE = "smart_medicine/schedule";   // Pi -> ESP32
const char *TOPIC_EVENTS = "smart_medicine/events";       // ESP32 -> Pi
const char *TOPIC_HEARTBEAT = "smart_medicine/heartbeat"; // ESP32 -> Pi

// =====================================================
// HARDWARE PIN ASSIGNMENTS
// =====================================================
#define RTC_SDA_PIN 19
#define RTC_SCL_PIN 18

#define TFT_SCK_PIN 15
#define TFT_MOSI_PIN 2
#define TFT_DC_PIN 4
#define TFT_RST_PIN 16
#define TFT_CS_PIN 17

#define BUZZER_PIN 23
#define LED_PIN 21
#define REED_PIN 22

// =====================================================
// HARDWARE PERIPHERALS
// =====================================================
Adafruit_ST7735 tft = Adafruit_ST7735(TFT_CS_PIN, TFT_DC_PIN, TFT_MOSI_PIN,
                                      TFT_SCK_PIN, TFT_RST_PIN);
RTC_DS3231 rtc;

WiFiClient espClient;
PubSubClient mqttClient(espClient);

// =====================================================
// STATE VARIABLES
// =====================================================
bool alarmActive = false;
bool standbyFrameDrawn = false;
bool lastReedState = HIGH;
unsigned long lastHeartbeatTime = 0;
unsigned long lastBuzzerToggle = 0;
bool buzzerState = false;

String currentMedicineName = "Aspirin";
String currentDosage = "1 Pill";
int currentCompartment = 1;

// Next Dose Display Variables
String nextMedName = "No Schedule";
String nextDoseTime = "--:--";
String nextDosage = "";
int nextCompartment = 1;
String piSyncedTime = "--:--:--";

// Change Tracking for Zero-Flicker Updates
String prevSyncedTime = "";
String prevMedName = "";
String prevDoseTime = "";
String prevDosage = "";

// =====================================================
// FLICKER-FREE DISPLAY FUNCTIONS
// =====================================================

// Draw static UI frame ONCE
void drawStandbyFrame() {
  tft.fillScreen(ST7735_BLACK);
  tft.drawRect(0, 0, 128, 160, ST7735_CYAN);

  // Header Banner
  tft.fillRect(2, 2, 124, 24, ST7735_BLUE);
  tft.setTextColor(ST7735_WHITE, ST7735_BLUE);
  tft.setTextSize(1);
  tft.setCursor(8, 9);
  tft.print("SMART MEDICINE HUB");

  // Status Info
  tft.setCursor(10, 34);
  tft.setTextColor(ST7735_GREEN, ST7735_BLACK);
  tft.print("Status: ONLINE");

  tft.setCursor(10, 48);
  tft.setTextColor(ST7735_YELLOW, ST7735_BLACK);
  tft.print("Time: ");

  // Active Slot Info
  tft.setCursor(10, 65);
  tft.setTextColor(ST7735_CYAN, ST7735_BLACK);
  tft.print("Active Box: Slot S1");

  // Divider Line
  tft.drawLine(5, 80, 123, 80, ST7735_WHITE);

  // Next Dose Card Section Header
  tft.setCursor(10, 88);
  tft.setTextColor(ST7735_MAGENTA, ST7735_BLACK);
  tft.setTextSize(1);
  tft.print("UPCOMING DOSE:");

  tft.setCursor(10, 132);
  tft.setTextColor(ST7735_YELLOW, ST7735_BLACK);
  tft.print("Time: ");

  tft.setCursor(10, 146);
  tft.setTextColor(ST7735_WHITE, ST7735_BLACK);
  tft.print("Dose: ");

  standbyFrameDrawn = true;
  
  // Reset change trackers so values draw cleanly
  prevSyncedTime = "";
  prevMedName = "";
  prevDoseTime = "";
  prevDosage = "";
}

// Zero-Flicker Selective Overwrite: No fillRect blinking, text background overwrites seamlessly!
void updateStandbyValues() {
  if (alarmActive) return;

  if (!standbyFrameDrawn) {
    drawStandbyFrame();
  }

  // 1. Time Value (Only update if string changed)
  if (piSyncedTime != prevSyncedTime) {
    prevSyncedTime = piSyncedTime;
    tft.setCursor(46, 48);
    tft.setTextSize(1);
    tft.setTextColor(ST7735_YELLOW, ST7735_BLACK);
    tft.print(piSyncedTime);
    tft.print(" "); // Padding space to clear trailing char if shortened
  }

  // 2. Medicine Name (Only update if changed)
  String displayMed = (nextMedName.length() > 8) ? nextMedName.substring(0, 8) : nextMedName;
  if (displayMed != prevMedName) {
    prevMedName = displayMed;
    tft.setCursor(10, 104);
    tft.setTextSize(2);
    tft.setTextColor(ST7735_WHITE, ST7735_BLACK);
    tft.print(displayMed);
    tft.print(" "); // Padding
  }

  // 3. Dose Time (Only update if changed)
  if (nextDoseTime != prevDoseTime) {
    prevDoseTime = nextDoseTime;
    tft.setCursor(46, 132);
    tft.setTextSize(1);
    tft.setTextColor(ST7735_YELLOW, ST7735_BLACK);
    tft.print(nextDoseTime);
    tft.print(" ");
  }

  // 4. Dosage (Only update if changed)
  if (nextDosage != prevDosage) {
    prevDosage = nextDosage;
    tft.setCursor(46, 146);
    tft.setTextSize(1);
    tft.setTextColor(ST7735_WHITE, ST7735_BLACK);
    tft.print(nextDosage);
    tft.print(" ");
  }
}

void drawAlarmScreen(String name, String dosage, int slot) {
  standbyFrameDrawn = false;
  tft.fillScreen(ST7735_RED);
  tft.drawRect(0, 0, 128, 160, ST7735_WHITE);

  // Header Banner
  tft.fillRect(2, 2, 124, 28, ST7735_YELLOW);
  tft.setTextColor(ST7735_BLACK);
  tft.setTextSize(1);
  tft.setCursor(12, 12);
  tft.print("TAKE MEDICINE!");

  // Details
  tft.setTextColor(ST7735_WHITE);
  tft.setCursor(10, 45);
  tft.print("Compartment: S");
  tft.print(slot);

  tft.setTextSize(2);
  tft.setCursor(10, 65);
  if (name.length() > 8) {
    tft.print(name.substring(0, 8));
  } else {
    tft.print(name);
  }

  tft.setTextSize(1);
  tft.setCursor(10, 95);
  tft.print("Dose: ");
  tft.print(dosage);

  tft.setCursor(10, 120);
  tft.setTextColor(ST7735_YELLOW);
  tft.print("OPEN SLOT S1 NOW");
}

void drawTakenScreen() {
  standbyFrameDrawn = false;
  tft.fillScreen(ST7735_GREEN);
  tft.setTextColor(ST7735_BLACK);
  tft.setTextSize(2);
  tft.setCursor(15, 45);
  tft.print("MEDICINE");
  tft.setCursor(25, 75);
  tft.print("TAKEN!");
  tft.setTextSize(1);
  tft.setCursor(20, 110);
  tft.print("Log synced to Pi");
}

// =====================================================
// MQTT CALLBACK & RECONNECT
// =====================================================
void mqttCallback(char *topic, byte *payload, unsigned int length) {
  String message;
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }

  Serial.print("[MQTT] Received on ");
  Serial.print(topic);
  Serial.print(": ");
  Serial.println(message);

  StaticJsonDocument<512> doc;
  DeserializationError error = deserializeJson(doc, message);
  if (error) {
    Serial.print("[MQTT] JSON parse error: ");
    Serial.println(error.c_str());
    return;
  }

  String topicStr = String(topic);

  // 1. Alarm Commands
  if (topicStr == TOPIC_COMMANDS) {
    String action = doc["action"] | "";
    if (action == "START_ALARM" || action == "TEST_ALARM") {
      currentMedicineName = doc["medicine"] | "Aspirin";
      currentDosage = doc["dosage"] | "1 Pill";
      currentCompartment = doc["compartment"] | 1;

      alarmActive = true;
      digitalWrite(LED_PIN, HIGH);
      drawAlarmScreen(currentMedicineName, currentDosage, currentCompartment);
      Serial.println("[ALARM] Buzzer & LED Activated for Compartment S1");
    } else if (action == "STOP_ALARM") {
      alarmActive = false;
      digitalWrite(LED_PIN, LOW);
      noTone(BUZZER_PIN);
      standbyFrameDrawn = false;
      updateStandbyValues();
      Serial.println("[ALARM] Alarm Silenced");
    }
  }

  // 2. Schedule & Time Updates from Pi (Zero-Flicker Update)
  else if (topicStr == TOPIC_SCHEDULE) {
    nextMedName = doc["nextMedicine"] | "No Schedule";
    nextDoseTime = doc["nextTime"] | "--:--";
    nextDosage = doc["dosage"] | "";
    nextCompartment = doc["compartment"] | 1;
    piSyncedTime = doc["systemTime"] | "--:--:--";

    if (!alarmActive) {
      updateStandbyValues();
    }
  }
}

void connectMQTT() {
  while (!mqttClient.connected()) {
    Serial.print("[MQTT] Connecting to Pi Broker at ");
    Serial.print(MQTT_BROKER_IP);
    Serial.print("...");
    if (mqttClient.connect(DEVICE_ID)) {
      Serial.println(" CONNECTED!");
      mqttClient.subscribe(TOPIC_COMMANDS);
      mqttClient.subscribe(TOPIC_SCHEDULE);
    } else {
      Serial.print(" Failed (rc=");
      Serial.print(mqttClient.state());
      Serial.println("). Retrying in 4 seconds...");
      delay(4000);
    }
  }
}

// =====================================================
// SETUP
// =====================================================
void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\n=== SMART MEDICINE ESP32 (S1 HARDWARE) ===");

  // Pin Modes
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(REED_PIN, INPUT_PULLUP);

  digitalWrite(LED_PIN, LOW);
  noTone(BUZZER_PIN);

  // Initialize I2C for RTC (SDA 19, SCL 18)
  Wire.begin(RTC_SDA_PIN, RTC_SCL_PIN);
  if (!rtc.begin()) {
    Serial.println("[RTC] Warning: DS3231 RTC not detected on I2C pins 19/18");
  }

  // Initialize TFT Display (ST7735)
  tft.initR(INITR_BLACKTAB);
  tft.setRotation(0);
  drawStandbyFrame();
  updateStandbyValues();

  // Connect to Wi-Fi
  Serial.print("[Wi-Fi] Connecting to ");
  Serial.println(WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n[Wi-Fi] Connected! IP: " + WiFi.localIP().toString());

  // Setup MQTT
  mqttClient.setServer(MQTT_BROKER_IP, MQTT_PORT);
  mqttClient.setCallback(mqttCallback);
}

// =====================================================
// MAIN LOOP
// =====================================================
void loop() {
  if (!mqttClient.connected()) {
    connectMQTT();
  }
  mqttClient.loop();

  // 1. Alarm Beeping Pattern
  if (alarmActive) {
    if (millis() - lastBuzzerToggle > 300) {
      lastBuzzerToggle = millis();
      buzzerState = !buzzerState;
      if (buzzerState) {
        tone(BUZZER_PIN, 1500);
      } else {
        noTone(BUZZER_PIN);
      }
    }
  }

  // 2. Reed Switch Sensor Monitoring (Active LOW with magnetic field / lid trigger)
  bool currentReedState = digitalRead(REED_PIN);

  if (lastReedState == HIGH && currentReedState == LOW) {
    Serial.println("[REED] Reed Switch Triggered on Compartment S1!");

    if (alarmActive) {
      alarmActive = false;
      digitalWrite(LED_PIN, LOW);
      noTone(BUZZER_PIN);

      drawTakenScreen();

      // Publish TAKEN event to Raspberry Pi via MQTT
      StaticJsonDocument<256> doc;
      doc["deviceId"] = DEVICE_ID;
      doc["compartment"] = 1;
      doc["event"] = "REED_OPEN";
      doc["eventType"] = "TAKEN";
      doc["details"] = "Medicine taken from Compartment S1";

      char buffer[256];
      serializeJson(doc, buffer);
      mqttClient.publish(TOPIC_EVENTS, buffer);

      Serial.println("[MQTT] TAKEN Event published to Raspberry Pi!");

      delay(3000);
      standbyFrameDrawn = false;
      updateStandbyValues();
    }
  }
  lastReedState = currentReedState;

  // 3. Heartbeat to Pi every 5 seconds
  if (millis() - lastHeartbeatTime > 5000) {
    lastHeartbeatTime = millis();
    StaticJsonDocument<128> hbDoc;
    hbDoc["deviceId"] = DEVICE_ID;
    hbDoc["isOnline"] = true;
    hbDoc["batteryLevel"] = 98;
    hbDoc["activeSlot"] = 1;

    char hbBuffer[128];
    serializeJson(hbDoc, hbBuffer);
    mqttClient.publish(TOPIC_HEARTBEAT, hbBuffer);
  }

  delay(10);
}