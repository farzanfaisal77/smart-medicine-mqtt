import 'package:flutter/material.dart';
import '../services/pi_api_service.dart';

class AuthProvider with ChangeNotifier {
  final PiApiService _apiService;

  bool _isConnected = false;
  bool _isLoading = false;
  String _serverIp = PiApiService.defaultIp;

  AuthProvider(this._apiService) {
    _serverIp = _apiService.piIp;
    checkPiConnection();
  }

  bool get isAuthenticated => _isConnected; // Connected to local Pi Edge Hub
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String get serverIp => _serverIp;
  String get userEmail => 'Raspberry Pi Local Hub';
  String get deviceId => 'ESP32_001 (S1 Active)';

  Future<bool> checkPiConnection() async {
    _isLoading = true;
    notifyListeners();

    _isConnected = await _apiService.checkConnection();

    _isLoading = false;
    notifyListeners();
    return _isConnected;
  }

  Future<bool> updatePiIp(String newIp) async {
    _isLoading = true;
    notifyListeners();

    await _apiService.setPiIp(newIp);
    _serverIp = _apiService.piIp;
    _isConnected = await _apiService.checkConnection();

    _isLoading = false;
    notifyListeners();
    return _isConnected;
  }

  void skipConnection() {
    _isConnected = true;
    notifyListeners();
  }

  void disconnect() {
    _isConnected = false;
    notifyListeners();
  }
}
