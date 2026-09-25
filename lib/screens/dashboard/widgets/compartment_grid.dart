import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/medicine_model.dart';
import '../../../models/device_state_model.dart';
import '../../../providers/medicine_provider.dart';
import '../../../providers/device_provider.dart';
import '../../../theme/app_theme.dart';
import '../../medicine/add_edit_medicine_screen.dart';

class CompartmentGrid extends StatelessWidget {
  const CompartmentGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final medicineProvider = Provider.of<MedicineProvider>(context);
    final deviceProvider = Provider.of<DeviceProvider>(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 columns -> 2 rows for 6 compartments
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        final compartmentId = index + 1;
        final slotTag = 'S$compartmentId';
        final isHardwareActive = compartmentId == 1; // S1 is physical hardware active
        final medicine = medicineProvider.getMedicineForCompartment(compartmentId);

        final status = deviceProvider.deviceState?.compartmentStatus.firstWhere(
          (c) => c.id == compartmentId,
          orElse: () => CompartmentStatus(id: compartmentId, isOpen: false, ledOn: false),
        );

        final bool isOpen = status?.isOpen ?? false;
        final bool isOccupied = medicine != null;

        Color cardBorderColor = isHardwareActive
            ? AppTheme.primaryCyan.withOpacity(0.6)
            : Colors.white.withOpacity(0.1);

        if (isOpen) {
          cardBorderColor = AppTheme.successGreen;
        }

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddEditMedicineScreen(
                  existingMedicine: medicine,
                  defaultCompartment: compartmentId,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isHardwareActive
                  ? AppTheme.primaryCyan.withOpacity(0.08)
                  : AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorderColor, width: isHardwareActive ? 2 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Slot Badge & Hardware Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isHardwareActive
                            ? AppTheme.primaryCyan
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        slotTag,
                        style: TextStyle(
                          color: isHardwareActive ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (isHardwareActive)
                      const Tooltip(
                        message: 'ESP32 Hardware Connected',
                        child: Icon(Icons.bolt_rounded, color: AppTheme.warningAmber, size: 18),
                      ),
                  ],
                ),

                // Medicine Name / Empty State
                Expanded(
                  child: Center(
                    child: isOccupied
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                medicine.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                medicine.dosage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline_rounded,
                                color: Colors.white.withOpacity(0.3),
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Empty Slot',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                // Door Status / Test Action Button for S1
                if (isHardwareActive)
                  InkWell(
                    onTap: () {
                      deviceProvider.triggerTestAlarm(1);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test Alarm Command sent via MQTT!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryCyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.volume_up_rounded, size: 14, color: AppTheme.primaryCyan),
                          SizedBox(width: 4),
                          Text(
                            'Test Alarm',
                            style: TextStyle(
                              color: AppTheme.primaryCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Text(
                    isOpen ? 'Door: OPEN' : 'Door: CLOSED',
                    style: TextStyle(
                      color: isOpen ? AppTheme.successGreen : Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
