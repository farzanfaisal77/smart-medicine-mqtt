import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/medicine_model.dart';
import '../../providers/medicine_provider.dart';
import '../../theme/app_theme.dart';

class AddEditMedicineScreen extends StatefulWidget {
  final MedicineModel? existingMedicine;
  final int? defaultCompartment;

  const AddEditMedicineScreen({
    super.key,
    this.existingMedicine,
    this.defaultCompartment,
  });

  @override
  State<AddEditMedicineScreen> createState() => _AddEditMedicineScreenState();
}

class _AddEditMedicineScreenState extends State<AddEditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _instructionsController;

  int _selectedCompartment = 1;
  List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];
  List<String> _selectedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  bool _isSaving = false;
  final List<String> _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final med = widget.existingMedicine;
    if (med != null) {
      _nameController = TextEditingController(text: med.name);
      _dosageController = TextEditingController(text: med.dosage);
      _instructionsController = TextEditingController(text: med.instructions);
      _selectedCompartment = med.compartment;
      _selectedDays = List.from(med.days);
      _selectedTimes = med.times.map((t) {
        final parts = t.split(':');
        return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }).toList();
    } else {
      _nameController = TextEditingController();
      _dosageController = TextEditingController();
      _instructionsController = TextEditingController();
      _selectedCompartment = widget.defaultCompartment ?? 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      setState(() {
        if (!_selectedTimes.any((t) => t.hour == picked.hour && t.minute == picked.minute)) {
          _selectedTimes.add(picked);
          _selectedTimes.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
        }
      });
    }
  }

  void _removeTime(int index) {
    if (_selectedTimes.length > 1) {
      setState(() {
        _selectedTimes.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one dose time is required.')),
      );
    }
  }

  void _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one dose time.')),
      );
      return;
    }

    final medicineProv = Provider.of<MedicineProvider>(context, listen: false);

    setState(() {
      _isSaving = true;
    });

    final timesFormatted = _selectedTimes.map((t) {
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }).toList();

    final isEdit = widget.existingMedicine != null;
    final medicine = MedicineModel(
      id: widget.existingMedicine?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      compartment: _selectedCompartment,
      dosage: _dosageController.text.trim(),
      instructions: _instructionsController.text.trim(),
      times: timesFormatted,
      days: _selectedDays,
      active: true,
      createdAt: widget.existingMedicine?.createdAt ?? DateTime.now(),
    );

    bool success;
    if (isEdit) {
      success = await medicineProv.updateMedicine(medicine);
    } else {
      success = await medicineProv.addMedicine(medicine);
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Medicine schedule updated!' : 'Medicine added to Compartment S$_selectedCompartment!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save schedule. Please check Pi Hub connection.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingMedicine != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Schedule' : 'Add Medicine Schedule'),
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Compartment Selection
              Text(
                'Assign Compartment',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(6, (index) {
                  final compId = index + 1;
                  final isSelected = _selectedCompartment == compId;
                  final isHardware = compId == 1;

                  return ChoiceChip(
                    label: Text(
                      isHardware ? 'S$compId (ESP32)' : 'S$compId',
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: isHardware ? AppTheme.primaryCyan : AppTheme.primaryTeal,
                    backgroundColor: AppTheme.cardBackground,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCompartment = compId;
                        });
                      }
                    },
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Medicine Name Input
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Medicine Name',
                  prefixIcon: const Icon(Icons.medication_rounded, color: AppTheme.primaryCyan),
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter medicine name' : null,
              ),
              const SizedBox(height: 16),

              // Dosage Input
              TextFormField(
                controller: _dosageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Dosage (e.g. 1 Tablet, 5ml)',
                  prefixIcon: const Icon(Icons.scale_rounded, color: AppTheme.primaryTeal),
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter dosage' : null,
              ),
              const SizedBox(height: 16),

              // Instructions Input
              TextFormField(
                controller: _instructionsController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Instructions (e.g. After meals)',
                  prefixIcon: const Icon(Icons.notes_rounded, color: AppTheme.primaryTeal),
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Scheduled Times Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dose Times',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: _addTime,
                    icon: const Icon(Icons.add_alarm_rounded, color: AppTheme.primaryCyan),
                    label: const Text('Add Time', style: TextStyle(color: AppTheme.primaryCyan)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _selectedTimes.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final time = entry.value;
                  final hh = time.hour.toString().padLeft(2, '0');
                  final mm = time.minute.toString().padLeft(2, '0');
                  return Chip(
                    label: Text('$hh:$mm', style: const TextStyle(color: Colors.white)),
                    backgroundColor: AppTheme.cardBackground,
                    deleteIcon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.errorRed),
                    onDeleted: () => _removeTime(idx),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveMedicine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        isEdit ? 'Update Schedule' : 'Save Schedule',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
