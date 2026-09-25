#!/usr/bin/env python3
"""
Smart Medicine Organizer - Raspberry Pi Central Edge Hub
Server Component: Flask HTTP REST API + Mosquitto MQTT Engine + SQLite DB
"""

import json
import sqlite3
import threading
import time
from datetime import datetime
from flask import Flask, request, jsonify
import paho.mqtt.client as mqtt

# =====================================================
# CONFIGURATION & CONSTANTS
# =====================================================
DB_FILE = "smart_medicine.db"
MQTT_BROKER = "localhost"
MQTT_PORT = 1883

TOPIC_COMMANDS  = "smart_medicine/commands"
TOPIC_SCHEDULE  = "smart_medicine/schedule"
TOPIC_EVENTS    = "smart_medicine/events"
TOPIC_HEARTBEAT = "smart_medicine/heartbeat"

app = Flask(__name__)

# =====================================================
# SQLITE DATABASE SETUP
# =====================================================
def init_db():
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    # Medicines Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS medicines (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            compartment INTEGER NOT NULL,
            dosage TEXT,
            instructions TEXT,
            times TEXT,
            days TEXT,
            active INTEGER DEFAULT 1,
            createdAt TEXT
        )
    ''')

    # Activity Logs Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            compartment INTEGER NOT NULL,
            timestamp TEXT NOT NULL,
            eventType TEXT NOT NULL,
            details TEXT
        )
    ''')

    # Device State Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS device_state (
            deviceId TEXT PRIMARY KEY,
            isOnline INTEGER DEFAULT 0,
            batteryLevel INTEGER DEFAULT 100,
            lastSeen TEXT,
            lastEvent TEXT
        )
    ''')

    conn.commit()
    conn.close()
    print("[DB] SQLite database initialized successfully.")

init_db()

# =====================================================
# MQTT CLIENT & EVENT LISTENERS
# =====================================================
mqtt_client = mqtt.Client(client_id="Pi_Edge_Hub")

def on_connect(client, userdata, flags, rc):
    print(f"[MQTT] Connected to Mosquitto Broker with code {rc}")
    client.subscribe(TOPIC_EVENTS)
    client.subscribe(TOPIC_HEARTBEAT)

def on_message(client, userdata, msg):
    try:
        payload = json.loads(msg.payload.decode('utf-8'))
        topic = msg.topic
        print(f"[MQTT] Message received on {topic}: {payload}")

        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()

        if topic == TOPIC_EVENTS:
            comp = payload.get("compartment", 1)
            event_type = payload.get("eventType", "TAKEN")
            details = payload.get("details", "Reed switch lid open")
            now_iso = datetime.now().isoformat()

            cursor.execute('''
                INSERT INTO logs (compartment, timestamp, eventType, details)
                VALUES (?, ?, ?, ?)
            ''', (comp, now_iso, event_type, details))
            conn.commit()
            print(f"[DB] Intake log recorded for Compartment S{comp}: {event_type}")

        elif topic == TOPIC_HEARTBEAT:
            dev_id = payload.get("deviceId", "ESP32_001")
            battery = payload.get("batteryLevel", 100)
            now_iso = datetime.now().isoformat()

            cursor.execute('''
                INSERT INTO device_state (deviceId, isOnline, batteryLevel, lastSeen)
                VALUES (?, 1, ?, ?)
                ON CONFLICT(deviceId) DO UPDATE SET
                    isOnline=1,
                    batteryLevel=excluded.batteryLevel,
                    lastSeen=excluded.lastSeen
            ''', (dev_id, battery, now_iso))
            conn.commit()

        conn.close()
    except Exception as e:
        print(f"[MQTT] Error processing message: {e}")

mqtt_client.on_connect = on_connect
mqtt_client.on_message = on_message

def start_mqtt():
    while True:
        try:
            mqtt_client.connect(MQTT_BROKER, MQTT_PORT, 60)
            mqtt_client.loop_forever()
        except Exception as e:
            print(f"[MQTT] Connection failed ({e}). Retrying in 5s...")
            time.sleep(5)

# =====================================================
# HELPER: FIND NEXT UPCOMING DOSE & BROADCAST TO ESP32
# =====================================================
def broadcast_next_dose():
    try:
        now = datetime.now()
        current_time_str = now.strftime("%H:%M:%S")

        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()
        cursor.execute("SELECT name, compartment, dosage, times FROM medicines WHERE active=1")
        rows = cursor.fetchall()
        conn.close()

        next_dose = None
        min_diff_seconds = 999999

        for name, comp, dosage, times_json in rows:
            try:
                times_list = json.loads(times_json) if times_json else []
            except:
                times_list = []

            for t_str in times_list:
                parts = t_str.split(':')
                if len(parts) != 2: continue
                h, m = int(parts[0]), int(parts[1])
                scheduled_dt = now.replace(hour=h, minute=m, second=0, microsecond=0)
                
                # If dose time passed today, look at tomorrow
                if scheduled_dt < now:
                    scheduled_dt = scheduled_dt.replace(day=now.day + 1) if now.day < 28 else scheduled_dt

                diff = (scheduled_dt - now).total_seconds()
                if 0 <= diff < min_diff_seconds:
                    min_diff_seconds = diff
                    next_dose = {
                        "nextMedicine": name,
                        "nextTime": t_str,
                        "dosage": dosage or "1 Dose",
                        "compartment": comp,
                        "systemTime": current_time_str
                    }

        if not next_dose:
            next_dose = {
                "nextMedicine": "No Schedule",
                "nextTime": "--:--",
                "dosage": "None",
                "compartment": 1,
                "systemTime": current_time_str
            }

        mqtt_client.publish(TOPIC_SCHEDULE, json.dumps(next_dose))
    except Exception as e:
        print(f"[SCHEDULE] Error broadcasting next dose: {e}")

# =====================================================
# PRECISION SCHEDULE CHECKER (1-Second Interval Loop)
# =====================================================
triggered_doses_today = set()

def schedule_checker_loop():
    while True:
        try:
            now = datetime.now()
            current_hhmm = now.strftime("%H:%M")
            current_day_str = now.strftime("%a")
            today_date_str = now.strftime("%Y-%m-%d")

            # Broadcast time/schedule to ESP32 every 1 second for instant precision
            broadcast_next_dose()

            conn = sqlite3.connect(DB_FILE)
            cursor = conn.cursor()
            cursor.execute("SELECT id, name, compartment, dosage, times, days FROM medicines WHERE active=1")
            rows = cursor.fetchall()
            conn.close()

            for row in rows:
                med_id, name, comp, dosage, times_json, days_json = row
                try:
                    times_list = json.loads(times_json) if times_json else []
                    days_list = json.loads(days_json) if days_json else []
                except:
                    times_list = []
                    days_list = []

                if days_list and (current_day_str not in days_list):
                    continue

                for time_str in times_list:
                    if time_str == current_hhmm:
                        trigger_key = f"{today_date_str}_{med_id}_{time_str}"
                        if trigger_key not in triggered_doses_today:
                            triggered_doses_today.add(trigger_key)
                            
                            command_payload = {
                                "action": "START_ALARM",
                                "compartment": comp,
                                "medicine": name,
                                "dosage": dosage or "1 Dose"
                            }
                            mqtt_client.publish(TOPIC_COMMANDS, json.dumps(command_payload))
                            print(f"[SCHEDULE] Instant Trigger Dose Alarm: {name} in S{comp} at {current_hhmm}:00")

        except Exception as e:
            print(f"[SCHEDULE] Loop error: {e}")

        # Precision 1-second sleep cycle so alarms trigger instantly at :00 seconds
        time.sleep(1)

# =====================================================
# FLASK HTTP REST API FOR FLUTTER APP
# =====================================================
@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "hub": "Raspberry Pi Edge Hub"}), 200

@app.route('/api/medicines', methods=['GET'])
def get_medicines():
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("SELECT id, name, compartment, dosage, instructions, times, days, active, createdAt FROM medicines")
    rows = cursor.fetchall()
    conn.close()

    result = []
    for r in rows:
        result.append({
            "id": r[0],
            "name": r[1],
            "compartment": r[2],
            "dosage": r[3],
            "instructions": r[4],
            "times": json.loads(r[5]) if r[5] else [],
            "days": json.loads(r[6]) if r[6] else [],
            "active": bool(r[7]),
            "createdAt": r[8]
        })
    return jsonify(result), 200

@app.route('/api/medicines', methods=['POST'])
def add_medicine():
    data = request.json or {}
    med_id = data.get("id") or str(int(time.time() * 1000))
    name = data.get("name", "Medicine")
    comp = data.get("compartment", 1)
    dosage = data.get("dosage", "")
    instructions = data.get("instructions", "")
    times_str = json.dumps(data.get("times", ["08:00"]))
    days_str = json.dumps(data.get("days", []))
    active = 1 if data.get("active", True) else 0
    created_at = data.get("createdAt") or datetime.now().isoformat()

    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute('''
        INSERT OR REPLACE INTO medicines (id, name, compartment, dosage, instructions, times, days, active, createdAt)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (med_id, name, comp, dosage, instructions, times_str, days_str, active, created_at))
    conn.commit()
    conn.close()

    broadcast_next_dose()
    return jsonify({"success": True, "id": med_id}), 201

@app.route('/api/medicines/<med_id>', methods=['PUT'])
def update_medicine(med_id):
    data = request.json or {}
    name = data.get("name", "Medicine")
    comp = data.get("compartment", 1)
    dosage = data.get("dosage", "")
    instructions = data.get("instructions", "")
    times_str = json.dumps(data.get("times", []))
    days_str = json.dumps(data.get("days", []))
    active = 1 if data.get("active", True) else 0

    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute('''
        UPDATE medicines
        SET name=?, compartment=?, dosage=?, instructions=?, times=?, days=?, active=?
        WHERE id=?
    ''', (name, comp, dosage, instructions, times_str, days_str, active, med_id))
    conn.commit()
    conn.close()

    broadcast_next_dose()
    return jsonify({"success": True}), 200

@app.route('/api/medicines/<med_id>', methods=['DELETE'])
def delete_medicine(med_id):
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("DELETE FROM medicines WHERE id=?", (med_id,))
    conn.commit()
    conn.close()

    broadcast_next_dose()
    return jsonify({"success": True}), 200

@app.route('/api/logs', methods=['GET'])
def get_logs():
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("SELECT id, compartment, timestamp, eventType, details FROM logs ORDER BY id DESC LIMIT 50")
    rows = cursor.fetchall()
    conn.close()

    result = []
    for r in rows:
        result.append({
            "id": str(r[0]),
            "compartment": r[1],
            "timestamp": r[2],
            "eventType": r[3],
            "details": r[4]
        })
    return jsonify(result), 200

@app.route('/api/device/state', methods=['GET'])
def get_device_state():
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("SELECT deviceId, isOnline, batteryLevel, lastSeen FROM device_state WHERE deviceId='ESP32_001'")
    row = cursor.fetchone()
    conn.close()

    if row:
        dev_id, is_online, battery, last_seen = row
        return jsonify({
            "deviceId": dev_id,
            "isOnline": bool(is_online),
            "batteryLevel": battery,
            "lastSeen": last_seen,
            "compartmentStatus": [
                {"id": 1, "isOpen": False, "ledOn": False, "ledColor": "OFF"},
                {"id": 2, "isOpen": False, "ledOn": False, "ledColor": "OFF"},
                {"id": 3, "isOpen": False, "ledOn": False, "ledColor": "OFF"},
                {"id": 4, "isOpen": False, "ledOn": False, "ledColor": "OFF"},
                {"id": 5, "isOpen": False, "ledOn": False, "ledColor": "OFF"},
                {"id": 6, "isOpen": False, "ledOn": False, "ledColor": "OFF"}
            ]
        }), 200

    return jsonify({
        "deviceId": "ESP32_001",
        "isOnline": False,
        "batteryLevel": 100,
        "lastSeen": datetime.now().isoformat(),
        "compartmentStatus": []
    }), 200

@app.route('/api/device/test-alarm', methods=['POST'])
def test_alarm():
    data = request.json or {}
    comp = data.get("compartment", 1)
    
    command_payload = {
        "action": "TEST_ALARM",
        "compartment": comp,
        "medicine": "Test Alarm",
        "dosage": "1 Pill"
    }
    mqtt_client.publish(TOPIC_COMMANDS, json.dumps(command_payload))
    print(f"[TEST] Sent instant TEST_ALARM to Compartment S{comp}")
    return jsonify({"success": True, "message": f"Test alarm sent to S{comp}"}), 200

# =====================================================
# MAIN ENTRY POINT
# =====================================================
if __name__ == '__main__':
    t_mqtt = threading.Thread(target=start_mqtt, daemon=True)
    t_mqtt.start()

    t_sched = threading.Thread(target=schedule_checker_loop, daemon=True)
    t_sched.start()

    print("[PI EDGE HUB] Server running on http://0.0.0.0:5000")
    app.run(host='0.0.0.0', port=5000, debug=False)
