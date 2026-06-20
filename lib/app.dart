import 'package:flutter/material.dart';
import 'utils/bluetooth_scan.dart';

class ObdSimulatorApp extends StatelessWidget {
  const ObdSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OBD-II Real Scan',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const BluetoothScanPage(),
    );
  }
}
