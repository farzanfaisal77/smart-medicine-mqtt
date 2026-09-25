import 'dart:async';
import 'package:flutter/material.dart';
import '../models/device_state_model.dart';
import '../services/pi_api_service.dart';

class DeviceProvider with ChangeNotifier {
  final PiApiService _apiService;
  DeviceStateModel? _deviceState;
  bool _isLoading = false;
  Timer? _fetchTimer;

  DeviceProvider(this._apiService) {
    fetchDeviceState();
    _fetchTimer = Timer.periodic(const Duration(seconds: 3), (_) => fetchDeviceState());
  }

  @override
  void dispose() {
    _fetchTimer?.cancel();
    super.dispose();
  }

  DeviceStateModel? get deviceState => _deviceState;
  bool get isLoading => _isLoading;
  bool get isOnline => _deviceState?.isOnline ?? false;
  int get batteryLevel => _deviceState?.batteryLevel ?? 100;

  Future<void> fetchDeviceState() async {
    final state = await _apiService.getDeviceState();
    _deviceState = state;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> triggerTestAlarm(int compartment) async {
    return await _apiService.triggerTestAlarm(compartment);
  }
}
