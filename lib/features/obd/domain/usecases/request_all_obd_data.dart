import '../entities/obd_dashboard_data.dart';
import '../repositories/obd_repository.dart';

class RequestAllObdData {
  const RequestAllObdData(this._repository);

  final ObdRepository _repository;

  Future<void> call() async {
    final data = ObdDashboardData.initial();

    for (final metric in data.metrics.values) {
      if (!metric.isSupportedBySimulator) continue;
      await _repository.sendRequest(metric.request);
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }
}
