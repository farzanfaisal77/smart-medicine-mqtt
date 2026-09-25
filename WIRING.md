# ESP32 1-Compartment Wiring Pinout

This document records the exact GPIO pin assignments for the single-compartment Smart Medicine Organizer setup.

| Component | ESP32 GPIO Pin | Notes |
| :--- | :--- | :--- |
| **RTC SDA** | `GPIO 19` | I2C Data for DS3231 RTC |
| **RTC SCL** | `GPIO 18` | I2C Clock for DS3231 RTC |
| **TFT SCK** | `GPIO 15` | SPI Clock for ST7735 TFT |
| **TFT SDA/MOSI** | `GPIO 2` | SPI Data for ST7735 TFT |
| **TFT A0/DC** | `GPIO 4` | Data/Command selector for TFT |
| **TFT RESET** | `GPIO 16` (`RX2`) | Reset pin for TFT |
| **TFT CS** | `GPIO 17` (`TX2`) | Chip Select pin for TFT |
| **Buzzer** | `GPIO 23` | Active/Passive Buzzer output |
| **LED** | `GPIO 21` | Compartment LED indicator output |
| **Reed Switch** | `GPIO 22` | Door sensor input (Active LOW with `INPUT_PULLUP`) |

## System Overview (Edge Architecture)

- **Raspberry Pi**: Central MQTT Broker (Mosquitto) + SQLite DB + Python HTTP/MQTT Server (Brain)
- **ESP32**: Lightweight MQTT client (Dumb Actuator & Sensor)
- **Flutter App**: REST UI connected directly to Pi IP (Dumb UI)
