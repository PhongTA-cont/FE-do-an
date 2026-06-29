import 'package:flutter/material.dart';

import 'core/core.dart';
import 'features/obd/obd.dart';

class ObdSimulatorApp extends StatelessWidget {
  const ObdSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quét OBD-II',
      theme: AppTheme.light(),
      home: const BluetoothScanPage(),
    );
  }
}
