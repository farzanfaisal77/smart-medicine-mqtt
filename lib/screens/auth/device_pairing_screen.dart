import 'package:flutter/material.dart';

class DevicePairingScreen extends StatelessWidget {
  const DevicePairingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Status')),
      body: const Center(
        child: Text('ESP32 device S1 is managed automatically via Pi Edge Hub.'),
      ),
    );
  }
}
