import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine_model.dart';
import '../models/log_model.dart';
import '../models/device_state_model.dart';

class PiApiService {
  static const String _defaultIpKey = 'pi_ip_address';
  static const String defaultIp = '192.168.1.100:5000'; // Default Pi IP:Port

  String _currentIp = defaultIp;

  String get piIp => _currentIp;

  PiApiService() {
    _loadSavedIp();
  }

  Future<void> _loadSavedIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentIp = prefs.getString(_defaultIpKey) ?? defaultIp;
    } catch (e) {
      debugPrint('Error loading saved Pi IP: $e');
    }
  }

  Future<bool> setPiIp(String ip) async {
    String cleanIp = ip.trim().replaceAll('http://', '').replaceAll('/', '');
    if (!cleanIp.contains(':')) {
      cleanIp = '$cleanIp:5000'; // Append default port if omitted
    }
    _currentIp = cleanIp;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_defaultIpKey, cleanIp);
      return true;
    } catch (e) {
      debugPrint('Error saving Pi IP: $e');
      return false;
    }
  }

  String get _baseUrl => 'http://$_currentIp/api';

  // ------------------ HEALTH CHECK / CONNECTION ------------------
  Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Pi connection check failed: $e');
      return false;
    }
  }

  // ------------------ MEDICINES ------------------
  Future<List<MedicineModel>> getMedicines() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/medicines'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((jsonItem) => MedicineModel.fromJson(jsonItem)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching medicines from Pi: $e');
    }
    return [];
  }

  Future<bool> addMedicine(MedicineModel medicine) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/medicines'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(medicine.toJson()),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error adding medicine to Pi: $e');
      return false;
    }
  }

  Future<bool> updateMedicine(MedicineModel medicine) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/medicines/${medicine.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(medicine.toJson()),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating medicine on Pi: $e');
      return false;
    }
  }

  Future<bool> deleteMedicine(String id) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/medicines/$id'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting medicine on Pi: $e');
      return false;
    }
  }

  // ------------------ LOGS ------------------
  Future<List<LogModel>> getLogs() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/logs'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((jsonItem) => LogModel.fromJson(jsonItem)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching logs from Pi: $e');
    }
    return [];
  }

  // ------------------ DEVICE STATE ------------------
  Future<DeviceStateModel> getDeviceState() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/device/state'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return DeviceStateModel.fromJson(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching device state from Pi: $e');
    }
    return DeviceStateModel(
      deviceId: 'ESP32_001',
      isOnline: false,
      batteryLevel: 100,
      lastSeen: DateTime.now(),
      compartmentStatus: List.generate(
        6,
        (i) => CompartmentStatus(id: i + 1, isOpen: false, ledOn: false, ledColor: 'OFF'),
      ),
    );
  }

  Future<bool> triggerTestAlarm(int compartment) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/device/test-alarm'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'compartment': compartment}),
      ).timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error triggering test alarm: $e');
      return false;
    }
  }
}
