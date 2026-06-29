import 'package:equatable/equatable.dart';

import 'obd_metric.dart';

class ObdDashboardData extends Equatable {
  const ObdDashboardData({required this.metrics, required this.logs});

  factory ObdDashboardData.initial() {
    return ObdDashboardData(metrics: _initialMetrics, logs: const []);
  }

  final Map<String, ObdMetric> metrics;
  final List<String> logs;

  ObdDashboardData copyWith({Map<String, ObdMetric>? metrics, List<String>? logs}) {
    return ObdDashboardData(
      metrics: metrics ?? this.metrics,
      logs: logs ?? this.logs,
    );
  }

  static const Map<String, ObdMetric> _initialMetrics = {
    'supportedPids': ObdMetric(key: 'supportedPids', title: 'Thông số xe hỗ trợ', value: '--', unit: '', request: '7DF#0201000000000000', isSupportedBySimulator: true),
    'engineLoad': ObdMetric(key: 'engineLoad', title: 'Tải động cơ', value: '--', unit: '%', request: '7DF#0201040000000000', isSupportedBySimulator: true),
    'coolantTemp': ObdMetric(key: 'coolantTemp', title: 'Nhiệt độ nước làm mát', value: '--', unit: '°C', request: '7DF#0201050000000000', isSupportedBySimulator: true),
    'intakePressure': ObdMetric(key: 'intakePressure', title: 'Áp suất đường nạp', value: '--', unit: 'kPa', request: '7DF#02010B0000000000', isSupportedBySimulator: true),
    'rpm': ObdMetric(key: 'rpm', title: 'Vòng tua động cơ', value: '--', unit: 'vòng/phút', request: '7DF#02010C0000000000', isSupportedBySimulator: true),
    'speed': ObdMetric(key: 'speed', title: 'Tốc độ xe', value: '--', unit: 'km/h', request: '7DF#02010D0000000000', isSupportedBySimulator: true),
    'intakeAirTemp': ObdMetric(key: 'intakeAirTemp', title: 'Nhiệt độ khí nạp', value: '--', unit: '°C', request: '7DF#02010F0000000000', isSupportedBySimulator: true),
    'maf': ObdMetric(key: 'maf', title: 'Lưu lượng khí nạp MAF', value: '--', unit: 'g/s', request: '7DF#0201100000000000', isSupportedBySimulator: true),
    'throttle': ObdMetric(key: 'throttle', title: 'Độ mở bướm ga', value: '--', unit: '%', request: '7DF#0201110000000000', isSupportedBySimulator: true),
    'barometricPressure': ObdMetric(key: 'barometricPressure', title: 'Áp suất khí quyển', value: '--', unit: 'kPa', request: '7DF#0201330000000000', isSupportedBySimulator: true),
    'vin': ObdMetric(key: 'vin', title: 'Số VIN', value: '--', unit: '', request: '7DF#0209020000000000', isSupportedBySimulator: true),
  };

  @override
  List<Object?> get props => [metrics, logs];
}
