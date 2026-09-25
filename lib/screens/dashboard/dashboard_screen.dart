import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/log_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/status_header.dart';
import 'widgets/timeline_widget.dart';
import 'widgets/compartment_grid.dart';
import '../medicine/add_edit_medicine_screen.dart';
import '../logs/logs_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _MainDashboardView(),
      const LogsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: AppTheme.cardBackground,
        indicatorColor: AppTheme.primaryCyan.withOpacity(0.2),
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_rounded),
            selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.primaryCyan),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_rounded),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: AppTheme.primaryCyan),
            label: 'Logs',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            selectedIcon: Icon(Icons.settings_rounded, color: AppTheme.primaryCyan),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddEditMedicineScreen(),
                  ),
                );
              },
              backgroundColor: AppTheme.primaryCyan,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Medicine',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}

class _MainDashboardView extends StatelessWidget {
  const _MainDashboardView();

  @override
  Widget build(BuildContext context) {
    final deviceProv = Provider.of<DeviceProvider>(context);

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<MedicineProvider>(context, listen: false).fetchMedicines();
        await Provider.of<LogProvider>(context, listen: false).fetchLogs();
        await Provider.of<DeviceProvider>(context, listen: false).fetchDeviceState();
      },
      color: AppTheme.primaryCyan,
      backgroundColor: AppTheme.cardBackground,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            const StatusHeader(),
            const SizedBox(height: 20),

            // S1 Hardware Notice Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hardware_rounded, color: AppTheme.primaryCyan),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Compartment 1 (S1) is active on ESP32 MQTT hardware.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6 Compartment Grid View
            Text(
              'Organizer Compartments (S1 - S6)',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 18,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 12),
            const CompartmentGrid(),
            const SizedBox(height: 24),

            // Today's Timeline
            Text(
              "Today's Dose Schedule",
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 18,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 12),
            const TimelineWidget(),
            const SizedBox(height: 80), // Padding for FAB
          ],
        ),
      ),
    );
  }
}
