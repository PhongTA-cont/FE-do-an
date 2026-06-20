import 'package:equatable/equatable.dart';

enum ObdPidStatus { implemented, declaredOnly }

class ObdPid extends Equatable {
  const ObdPid({
    required this.service,
    required this.pid,
    required this.name,
    required this.request,
    required this.unit,
    required this.status,
    this.min,
    this.max,
  });

  final int service;
  final int pid;
  final String name;
  final String request;
  final String unit;
  final ObdPidStatus status;
  final num? min;
  final num? max;

  @override
  List<Object?> get props => [service, pid, name, request, unit, status, min, max];
}
