import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/medicine_model.dart';
import '../../providers/medicine_provider.dart';
import '../../theme/app_theme.dart';

class DiscontinueMedicineDialog extends StatefulWidget {
  final MedicineModel medicine;

  const DiscontinueMedicineDialog({
    super.key,
    required this.medicine,
  });

  @override
  State<DiscontinueMedicineDialog> createState() => _DiscontinueMedicineDialogState();
}

class _DiscontinueMedicineDialogState extends State<DiscontinueMedicineDialog> {
  bool _isProcessing = false;

  void _confirmDiscontinue() async {
    setState(() {
      _isProcessing = true;
    });

    final medProv = Provider.of<MedicineProvider>(context, listen: false);
    final success = await medProv.deleteMedicine(widget.medicine.id);

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Medicine discontinued. Compartment S${widget.medicine.compartment} cleared.',
          ),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to discontinue medicine. Check Pi connection.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.warningAmber, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Discontinue Medicine',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningAmber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.warningAmber.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cleaning_services_rounded, color: AppTheme.warningAmber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Please clear physical Compartment S${widget.medicine.compartment} before confirming.',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Discontinuing "${widget.medicine.name}" will remove its schedule from Raspberry Pi Edge Hub and silence future alarms.',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _confirmDiscontinue,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
          child: _isProcessing
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Confirm Discontinue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
