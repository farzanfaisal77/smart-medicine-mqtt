# Smart Medicine Organizer (MQTT Edge Hub)

A privacy-focused, zero-cloud local edge computing architecture for a smart medicine organizer. 

This repository replaces third-party cloud backends (e.g. Firebase) with a self-hosted **Raspberry Pi Central Edge Hub** communicating over local Wi-Fi via **MQTT** (`Mosquitto`) and **HTTP REST API**.

---

## Architecture Overview

See [ARCHITECTURE.md](ARCHITECTURE.md) for full architectural specifications, Mermaid sequence diagrams, and MQTT topic payloads.

```
 ┌──────────────────────────┐                 ┌──────────────────────────┐
 │    Flutter Mobile App    │                 │   ESP32 Microcontroller  │
 │   (Local UI / Display)   │                 │ (Dumb Hardware / Sensor) │
 └─────────────┬────────────┘                 └─────────────▲────────────┘
               │                                            │
        HTTP REST API                                MQTT Topics
    (http://<PI_IP>:5000/api)                   (port 1883 over Wi-Fi)
               │                                            │
               └────────────────────┬───────────────────────┘
                                    │
                                    ▼
 ┌───────────────────────────────────────────────────────────────────────┐
 │                   RASPBERRY PI (The Central Brain)                    │
 │                                                                       │
 │  1. Mosquitto MQTT Broker (port 1883)                                │
 │  2. SQLite Local Database (`smart_medicine.db`)                      │
 │  3. Python Central Backend Server (`pi_server.py`)                    │
 └───────────────────────────────────────────────────────────────────────┘
```

---

## Hardware Wiring Pinout (ESP32)

See [WIRING.md](WIRING.md) for complete hardware pin assignments for the 1-compartment hardware prototype.

| Component | ESP32 GPIO Pin | Function |
| :--- | :--- | :--- |
| **RTC SDA** | `GPIO 19` | I2C Data for DS3231 RTC |
| **RTC SCL** | `GPIO 18` | I2C Clock for DS3231 RTC |
| **TFT SCK** | `GPIO 15` | SPI Clock for ST7735 TFT Screen |
| **TFT SDA/MOSI** | `GPIO 2` | SPI Data for ST7735 TFT Screen |
| **TFT A0/DC** | `GPIO 4` | Data/Command pin |
| **TFT RESET** | `GPIO 16` (`RX2`) | Reset pin |
| **TFT CS** | `GPIO 17` (`TX2`) | Chip Select pin |
| **Buzzer** | `GPIO 23` | Active/Passive Alarm Buzzer |
| **LED** | `GPIO 21` | Compartment S1 LED Indicator |
| **Reed Switch** | `GPIO 22` | Box Lid Open Sensor (`INPUT_PULLUP`) |

---

## Repository Structure

```
├── lib/                     # Flutter Mobile App source code
│   ├── models/              # JSON Data Models (Medicine, Log, Device State)
│   ├── providers/           # State Management & Pi HTTP API hooks
│   ├── screens/             # Dashboard, Logs, Settings, Schedule management
│   └── services/            # PiApiService HTTP REST Client
├── espcode_sketch/          # ESP32 Arduino Sketch
│   └── espcode_sample.ino   # Public ESP32 sketch template (safe credentials)
├── pi_server.py             # Raspberry Pi Central Edge Server (Flask + SQLite + MQTT)
├── ARCHITECTURE.md          # Comprehensive System Architecture Specification
├── WIRING.md                # Dedicated hardware pinout documentation
└── pubspec.yaml             # Flutter dependencies
```

---

## Quick Setup Instructions

### 1. Raspberry Pi Setup
1. Install Mosquitto MQTT broker and Python dependencies:
   ```bash
   sudo apt update
   sudo apt install -y mosquitto mosquitto-clients python3-flask python3-paho-mqtt
   ```
2. Enable local network access for Mosquitto:
   ```bash
   sudo bash -c 'cat <<EOF > /etc/mosquitto/conf.d/default.conf
   listener 1883
   allow_anonymous true
   EOF'
   sudo systemctl restart mosquitto
   ```
3. Run the Central Edge Server:
   ```bash
   python3 pi_server.py
   ```

### 2. ESP32 Microcontroller
1. Open `espcode_sketch/espcode_sample.ino`.
2. Update `WIFI_SSID`, `WIFI_PASSWORD`, and `MQTT_BROKER_IP` with your Raspberry Pi's local IP address (`hostname -I`).
3. Compile and flash using `arduino-cli` or Arduino IDE:
   ```bash
   arduino-cli compile --fqbn esp32:esp32:esp32 espcode_sketch/espcode_sample.ino
   arduino-cli upload -p /dev/ttyUSB0 --fqbn esp32:esp32:esp32 espcode_sketch/espcode_sample.ino
   ```

### 3. Flutter Mobile App
1. Build and install the app on your mobile device:
   ```bash
   flutter pub get
   flutter run
   ```
2. On startup, enter your Raspberry Pi's IP address and tap **Connect to Hub**.