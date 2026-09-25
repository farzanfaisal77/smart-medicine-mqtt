import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/log_model.dart';
import '../../providers/log_provider.dart';
import '../../theme/app_theme.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logProvider = Provider.of<LogProvider>(context);
    final logs = logProvider.filteredLogs;

    return Column(
      children: [
        // App Bar & Title
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Real-Time Activity Logs',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Live Reed Switch adherence events from ESP32 via MQTT',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
              ),
              const SizedBox(height: 14),

              // Filter Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Filter by Event Type
                    DropdownButton<EventType?>(
                      dropdownColor: AppTheme.cardBackground,
                      value: logProvider.eventTypeFilter,
                      hint: const Text('All Event Types', style: TextStyle(fontSize: 13, color: Colors.white70)),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Events', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: EventType.taken, child: Text('✅ TAKEN', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: EventType.missed, child: Text('❌ MISSED', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                          value: EventType.wrongCompartment,
                          child: Text('⚠️ WRONG COMPARTMENT', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                      onChanged: (val) => logProvider.setEventTypeFilter(val),
                    ),
                    const SizedBox(width: 12),

                    // Filter by Compartment
                    DropdownButton<int?>(
                      dropdownColor: AppTheme.cardBackground,
                      value: logProvider.compartmentFilter,
                      hint: const Text('All Compartments', style: TextStyle(fontSize: 13, color: Colors.white70)),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Slots', style: TextStyle(color: Colors.white))),
                        ...List.generate(
                          6,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(i == 0 ? 'Slot 1 (Hardware Active)' : 'Slot ${i + 1}', style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                      onChanged: (val) => logProvider.setCompartmentFilter(val),
                    ),
                    const SizedBox(width: 12),

                    if (logProvider.compartmentFilter != null || logProvider.eventTypeFilter != null)
                      TextButton.icon(
                        onPressed: () => logProvider.clearFilters(),
                        icon: const Icon(Icons.clear_rounded, size: 16, color: AppTheme.primaryCyan),
                        label: const Text('Reset', style: TextStyle(color: AppTheme.primaryCyan)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(color: Colors.white10, height: 1),

        // Log Entries Feed
        Expanded(
          child: logProvider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryCyan))
              : logs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_toggle_off_rounded,
                              size: 48,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No activity logs found',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Reed Switch triggers from your ESP32 device will be recorded on the Pi and appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final timeStr = DateFormat('hh:mm a • MMM dd').format(log.timestamp);

                        Color statusColor;
                        IconData iconData;
                        String badgeText;

                        switch (log.eventType) {
                          case EventType.taken:
                            statusColor = AppTheme.successGreen;
                            iconData = Icons.check_circle_rounded;
                            badgeText = 'TAKEN';
                            break;
                          case EventType.missed:
                            statusColor = AppTheme.errorRed;
                            iconData = Icons.cancel_rounded;
                            badgeText = 'MISSED';
                            break;
                          case EventType.wrongCompartment:
                          default:
                            statusColor = AppTheme.warningAmber;
                            iconData = Icons.warning_amber_rounded;
                            badgeText = 'WRONG SLOT';
                            break;
                        }

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: statusColor.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor.withOpacity(0.15),
                                ),
                                child: Icon(iconData, color: statusColor, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Compartment S${log.compartment}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            badgeText,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      log.details.isNotEmpty ? log.details : 'Reed switch lid open event recorded',
                                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timeStr,
                                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
