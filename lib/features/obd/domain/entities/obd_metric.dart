import 'package:equatable/equatable.dart';

class ObdMetric extends Equatable {
  const ObdMetric({
    required this.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.request,
    required this.isSupportedBySimulator,
  });

  final String key;
  final String title;
  final String value;
  final String unit;
  final String request;
  final bool isSupportedBySimulator;

  ObdMetric copyWith({String? value}) {
    return ObdMetric(
      key: key,
      title: title,
      value: value ?? this.value,
      unit: unit,
      request: request,
      isSupportedBySimulator: isSupportedBySimulator,
    );
  }

  @override
  List<Object?> get props => [key, title, value, unit, request, isSupportedBySimulator];
}
