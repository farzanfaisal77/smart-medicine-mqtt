import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medicine_model.dart';
import '../models/log_model.dart';
import '../services/pi_api_service.dart';

class DoseScheduleItem {
  final MedicineModel medicine;
  final String time; // e.g. "13:00"
  final DateTime scheduledDateTime;
  final String status; // 'Pending', 'Taken', 'Missed'

  DoseScheduleItem({
    required this.medicine,
    required this.time,
    required this.scheduledDateTime,
    required this.status,
  });
}

class MedicineProvider with ChangeNotifier {
  final PiApiService _apiService;
  List<MedicineModel> _medicines = [];
  List<LogModel> _latestLogs = [];
  bool _isLoading = false;
  Timer? _fetchTimer;

  MedicineProvider(this._apiService) {
    fetchMedicines();
    _fetchTimer = Timer.periodic(const Duration(seconds: 5), (_) => fetchMedicines());
  }

  @override
  void dispose() {
    _fetchTimer?.cancel();
    super.dispose();
  }

  List<MedicineModel> get medicines => _medicines;
  List<MedicineModel> get activeMedicines =>
      _medicines.where((m) => m.active).toList();
  bool get isLoading => _isLoading;

  void setLogs(List<LogModel> logs) {
    _latestLogs = logs;
    notifyListeners();
  }

  Future<void> fetchMedicines() async {
    final list = await _apiService.getMedicines();
    _medicines = list;
    _isLoading = false;
    notifyListeners();
  }

  MedicineModel? getMedicineForCompartment(int compartmentId) {
    try {
      return activeMedicines.firstWhere((m) => m.compartment == compartmentId);
    } catch (_) {
      return null;
    }
  }

  List<DoseScheduleItem> getTodaySchedule() {
    final now = DateTime.now();
    final todayDayStr = DateFormat('E').format(now); // "Mon", "Tue"...
    final List<DoseScheduleItem> schedule = [];

    for (final med in activeMedicines) {
      bool isScheduledToday = med.days.contains(todayDayStr) ||
          med.days.contains(DateFormat('EEEE').format(now));
      
      // If no specific days selected, default to daily
      if (med.days.isEmpty) isScheduledToday = true;

      if (!isScheduledToday) continue;

      for (final timeStr in med.times) {
        final parts = timeStr.split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;

        final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

        String status = 'Pending';
        final hasLog = _latestLogs.any((l) =>
            l.compartment == med.compartment &&
            l.eventType == EventType.taken &&
            l.timestamp.year == now.year &&
            l.timestamp.month == now.month &&
            l.timestamp.day == now.day &&
            (l.timestamp.difference(scheduledTime).inMinutes.abs() < 120));

        if (hasLog) {
          status = 'Taken';
        } else if (now.isAfter(scheduledTime.add(const Duration(minutes: 30)))) {
          status = 'Missed';
        }

        schedule.add(DoseScheduleItem(
          medicine: med,
          time: timeStr,
          scheduledDateTime: scheduledTime,
          status: status,
        ));
      }
    }

    schedule.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
    return schedule;
  }

  Future<bool> addMedicine(MedicineModel medicine) async {
    _isLoading = true;
    notifyListeners();
    final success = await _apiService.addMedicine(medicine);
    if (success) {
      await fetchMedicines();
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateMedicine(MedicineModel medicine) async {
    _isLoading = true;
    notifyListeners();
    final success = await _apiService.updateMedicine(medicine);
    if (success) {
      await fetchMedicines();
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> deleteMedicine(String id) async {
    _isLoading = true;
    notifyListeners();
    final success = await _apiService.deleteMedicine(id);
    if (success) {
      await fetchMedicines();
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }
}
