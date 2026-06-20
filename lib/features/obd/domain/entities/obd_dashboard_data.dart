import 'package:equatable/equatable.dart';

import 'obd_metric.dart';
import 'obd_pid.dart';

class ObdDashboardData extends Equatable {
  const ObdDashboardData({required this.metrics, required this.pidCatalog, required this.logs});

  factory ObdDashboardData.initial() {
    return ObdDashboardData(metrics: _initialMetrics, pidCatalog: _pidCatalog, logs: const []);
  }

  final Map<String, ObdMetric> metrics;
  final List<ObdPid> pidCatalog;
  final List<String> logs;

  ObdDashboardData copyWith({Map<String, ObdMetric>? metrics, List<ObdPid>? pidCatalog, List<String>? logs}) {
    return ObdDashboardData(
      metrics: metrics ?? this.metrics,
      pidCatalog: pidCatalog ?? this.pidCatalog,
      logs: logs ?? this.logs,
    );
  }

  static const Map<String, ObdMetric> _initialMetrics = {
    'supportedPids': ObdMetric(key: 'supportedPids', title: 'PIDs supported [01-20]', value: '--', unit: '', request: '7DF#0201000000000000', isSupportedBySimulator: true),
    'engineLoad': ObdMetric(key: 'engineLoad', title: 'Engine Load', value: '--', unit: '%', request: '7DF#0201040000000000', isSupportedBySimulator: true),
    'coolantTemp': ObdMetric(key: 'coolantTemp', title: 'Coolant Temperature', value: '--', unit: '°C', request: '7DF#0201050000000000', isSupportedBySimulator: true),
    'intakePressure': ObdMetric(key: 'intakePressure', title: 'Intake Manifold Pressure', value: '--', unit: 'kPa', request: '7DF#02010B0000000000', isSupportedBySimulator: true),
    'rpm': ObdMetric(key: 'rpm', title: 'Engine RPM', value: '--', unit: 'rpm', request: '7DF#02010C0000000000', isSupportedBySimulator: true),
    'speed': ObdMetric(key: 'speed', title: 'Vehicle Speed', value: '--', unit: 'km/h', request: '7DF#02010D0000000000', isSupportedBySimulator: true),
    'intakeAirTemp': ObdMetric(key: 'intakeAirTemp', title: 'Intake Air Temperature', value: '--', unit: '°C', request: '7DF#02010F0000000000', isSupportedBySimulator: true),
    'maf': ObdMetric(key: 'maf', title: 'MAF Air Flow Rate', value: '--', unit: 'g/s', request: '7DF#0201100000000000', isSupportedBySimulator: true),
    'throttle': ObdMetric(key: 'throttle', title: 'Throttle Position', value: '--', unit: '%', request: '7DF#0201110000000000', isSupportedBySimulator: true),
    'barometricPressure': ObdMetric(key: 'barometricPressure', title: 'Barometric Pressure', value: '--', unit: 'kPa', request: '7DF#0201330000000000', isSupportedBySimulator: true),
    'vin': ObdMetric(key: 'vin', title: 'VIN', value: '--', unit: '', request: '7DF#0209020000000000', isSupportedBySimulator: true),
  };

  static const List<ObdPid> _pidCatalog = [
    ObdPid(service: 1, pid: 0x00, name: 'PIDs supported [01-20]', request: '7DF#0201000000000000', unit: 'n/a', status: ObdPidStatus.implemented),
    ObdPid(service: 1, pid: 0x01, name: 'Monitor status since DTCs cleared', request: '7DF#0201010000000000', unit: 'n/a', status: ObdPidStatus.declaredOnly),
    ObdPid(service: 1, pid: 0x02, name: 'Freeze DTC', request: '7DF#0201020000000000', unit: 'n/a', status: ObdPidStatus.declaredOnly),
    ObdPid(service: 1, pid: 0x03, name: 'Fuel system status', request: '7DF#0201030000000000', unit: 'n/a', status: ObdPidStatus.declaredOnly),
    ObdPid(service: 1, pid: 0x04, name: 'Calculated engine load', request: '7DF#0201040000000000', unit: '%', status: ObdPidStatus.implemented, min: 0, max: 100),
    ObdPid(service: 1, pid: 0x05, name: 'Engine coolant temperature', request: '7DF#0201050000000000', unit: '°C', status: ObdPidStatus.implemented, min: -40, max: 215),
    ObdPid(service: 1, pid: 0x06, name: 'Short term fuel trim-Bank 1', request: '7DF#0201060000000000', unit: '%', status: ObdPidStatus.declaredOnly),
    ObdPid(service: 1, pid: 0x07, name: 'Long term fuel trim-Bank 1', request: '7DF#0201070000000000', unit: '%', status: ObdPidStatus.declaredOnly),
    ObdPid(service: 1, pid: 0x08, name: 'Short term fuel trim-Bank 2', request: '7DF#0201080000000000', unit: '%', status: ObdPidStatus.declaredOnly),
    ObdPid(service: 1, pid: 0x09, name: 'Long term fuel trim-Bank 2', request: '7DF#0201090000000000', unit: '%', status: ObdPidStatus.declaredOnly),
    ObdPid(service: 1, pid: 0x0A, name: 'Fuel pressure', request: '7DF#02010A0000000000', unit: 'kPa', status: ObdPidStatus.declaredOnly),
    ObdPid(service: 1, pid: 0x0B, name: 'Intake manifold absolute pressure', request: '7DF#02010B0000000000', unit: 'kPa', status: ObdPidStatus.implemented),
    ObdPid(service: 1, pid: 0x0C, name: 'Engine RPM', request: '7DF#02010C0000000000', unit: 'rpm', status: ObdPidStatus.implemented),
    ObdPid(service: 1, pid: 0x0D, name: 'Vehicle speed', request: '7DF#02010D0000000000', unit: 'km/h', status: ObdPidStatus.implemented),
    ObdPid(service: 1, pid: 0x0E, name: 'Timing advance', request: '7DF#02010E0000000000', unit: '° before TDC', status: ObdPidStatus.declaredOnly),
    ObdPid(service: 1, pid: 0x0F, name: 'Intake air temperature', request: '7DF#02010F0000000000', unit: '°C', status: ObdPidStatus.implemented),
    ObdPid(service: 1, pid: 0x10, name: 'MAF air flow rate', request: '7DF#0201100000000000', unit: 'g/s', status: ObdPidStatus.implemented),
    ObdPid(service: 1, pid: 0x11, name: 'Throttle position', request: '7DF#0201110000000000', unit: '%', status: ObdPidStatus.implemented),
    ObdPid(service: 1, pid: 0x1F, name: 'Run time since engine start', request: '7DF#02011F0000000000', unit: 'seconds', status: ObdPidStatus.declaredOnly),
    ObdPid(service: 9, pid: 0x02, name: 'VIN code', request: '7DF#0209020000000000', unit: '', status: ObdPidStatus.implemented),
    ObdPid(service: 1, pid: 0x33, name: 'Absolute Barometric Pressure', request: '7DF#0201330000000000', unit: 'kPa', status: ObdPidStatus.implemented),
  ];

  @override
  List<Object?> get props => [metrics, pidCatalog, logs];
}
