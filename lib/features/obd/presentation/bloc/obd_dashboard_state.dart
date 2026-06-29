import 'package:equatable/equatable.dart';

import '../../domain/obd_domain.dart';

enum ObdDashboardStatus { initial, ready, polling, error }

class ObdDashboardState extends Equatable {
  const ObdDashboardState({required this.status, required this.data, required this.isPolling, this.errorMessage});

  factory ObdDashboardState.initial() {
    return ObdDashboardState(status: ObdDashboardStatus.initial, data: ObdDashboardData.initial(), isPolling: false);
  }

  final ObdDashboardStatus status;
  final ObdDashboardData data;
  final bool isPolling;
  final String? errorMessage;

  ObdDashboardState copyWith({ObdDashboardStatus? status, ObdDashboardData? data, bool? isPolling, String? errorMessage}) {
    return ObdDashboardState(
      status: status ?? this.status,
      data: data ?? this.data,
      isPolling: isPolling ?? this.isPolling,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, isPolling, errorMessage];
}
