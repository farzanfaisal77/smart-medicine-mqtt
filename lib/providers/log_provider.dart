import 'dart:async';
import 'package:flutter/material.dart';
import '../models/log_model.dart';
import '../services/pi_api_service.dart';

class LogProvider with ChangeNotifier {
  final PiApiService _apiService;
  List<LogModel> _logs = [];
  bool _isLoading = false;
  int? _compartmentFilter;
  EventType? _eventTypeFilter;
  Timer? _fetchTimer;

  LogProvider(this._apiService) {
    fetchLogs();
    _fetchTimer = Timer.periodic(const Duration(seconds: 5), (_) => fetchLogs());
  }

  @override
  void dispose() {
    _fetchTimer?.cancel();
    super.dispose();
  }

  List<LogModel> get logs => _logs;
  bool get isLoading => _isLoading;
  int? get compartmentFilter => _compartmentFilter;
  EventType? get eventTypeFilter => _eventTypeFilter;

  List<LogModel> get filteredLogs {
    return _logs.where((log) {
      if (_compartmentFilter != null && log.compartment != _compartmentFilter) {
        return false;
      }
      if (_eventTypeFilter != null && log.eventType != _eventTypeFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  void setCompartmentFilter(int? compartment) {
    _compartmentFilter = compartment;
    notifyListeners();
  }

  void setEventTypeFilter(EventType? type) {
    _eventTypeFilter = type;
    notifyListeners();
  }

  void clearFilters() {
    _compartmentFilter = null;
    _eventTypeFilter = null;
    notifyListeners();
  }

  Future<void> fetchLogs() async {
    final list = await _apiService.getLogs();
    _logs = list;
    _isLoading = false;
    notifyListeners();
  }
}
