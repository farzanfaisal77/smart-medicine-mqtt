import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/device_provider.dart';
import '../../../theme/app_theme.dart';

class StatusHeader extends StatelessWidget {
  const StatusHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final device = Provider.of<DeviceProvider>(context);

    final isConnected = auth.isConnected;
    final serverIp = auth.serverIp;
    final isOnline = device.isOnline;
    final battery = device.batteryLevel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Edge Hub Server Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.dns_rounded, size: 18, color: AppTheme.primaryCyan),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Pi Hub: $serverIp',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hardware: ESP32 MQTT (S1)',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Battery / Connection Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isOnline
                      ? AppTheme.successGreen.withOpacity(0.15)
                      : AppTheme.warningAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOnline
                        ? AppTheme.successGreen.withOpacity(0.4)
                        : AppTheme.warningAmber.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOnline ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                      size: 16,
                      color: isOnline ? AppTheme.successGreen : AppTheme.warningAmber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? 'ESP32 Online' : 'ESP32 Standby',
                      style: TextStyle(
                        color: isOnline ? AppTheme.successGreen : AppTheme.warningAmber,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),

          // Status Badges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Pi Connection Badge
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected ? AppTheme.successGreen : AppTheme.errorRed,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? 'Pi Hub Connected' : 'Pi Disconnected',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Battery Status
              Row(
                children: [
                  const Icon(Icons.battery_5_bar_rounded, size: 18, color: AppTheme.primaryTeal),
                  const SizedBox(width: 4),
                  Text(
                    '$battery%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
