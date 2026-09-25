import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/pi_api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/medicine_provider.dart';
import 'providers/device_provider.dart';
import 'providers/log_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartMedicineApp());
}

class SmartMedicineApp extends StatelessWidget {
  const SmartMedicineApp({super.key});

  @override
  Widget build(BuildContext context) {
    final piApiService = PiApiService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(piApiService)),
        ChangeNotifierProvider(create: (_) => MedicineProvider(piApiService)),
        ChangeNotifierProvider(create: (_) => DeviceProvider(piApiService)),
        ChangeNotifierProvider(create: (_) => LogProvider(piApiService)),
      ],
      child: MaterialApp(
        title: 'Smart Medicine Edge Companion',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isConnected) {
      return const DashboardScreen();
    } else {
      return const AuthScreen();
    }
  }
}
