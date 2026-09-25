import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _ipController;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _ipController = TextEditingController(text: auth.serverIp);
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _savePiIp() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.updatePiIp(_ipController.text);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connected to Raspberry Pi Hub!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not reach Raspberry Pi at specified IP.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final device = Provider.of<DeviceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edge Hub & Hardware Settings'),
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Edge Hub Network Configuration Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.dns_rounded, color: AppTheme.primaryCyan),
                      SizedBox(width: 10),
                      Text(
                        'Raspberry Pi IP Address',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ipController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g. 192.168.1.100:5000',
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: auth.isLoading ? null : _savePiIp,
                      icon: const Icon(Icons.sync_rounded),
                      label: const Text('Save & Test Connection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryCyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ESP32 Hardware Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.memory_rounded, color: AppTheme.primaryTeal),
                      SizedBox(width: 10),
                      Text(
                        'ESP32 Hardware Configuration',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active Compartment', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Compartment 1 (S1) mapped to direct GPIOs', style: TextStyle(color: Colors.white54)),
                    trailing: const Chip(
                      label: Text('GPIO 21, 22, 23', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      backgroundColor: AppTheme.primaryCyan,
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Test S1 Alarm', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Sends MQTT START_ALARM to ESP32', style: TextStyle(color: Colors.white54)),
                    trailing: ElevatedButton(
                      onPressed: () {
                        device.triggerTestAlarm(1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Test Alarm MQTT command sent!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningAmber, foregroundColor: Colors.black),
                      child: const Text('Trigger'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Disconnect / Reconfigure
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  auth.disconnect();
                },
                icon: const Icon(Icons.link_off_rounded, color: AppTheme.errorRed),
                label: const Text('Reconfigure Network Connection', style: TextStyle(color: AppTheme.errorRed)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorRed),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
