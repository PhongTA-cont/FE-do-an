import '../../domain/repositories/obd_repository.dart';
import '../datasources/obd_ble_datasource.dart';

class ObdRepositoryImpl implements ObdRepository {
  ObdRepositoryImpl(this._dataSource);

  final ObdBleDataSource _dataSource;

  @override
  Future<void> sendRequest(String command) => _dataSource.send(command);

  @override
  Stream<String> listenRawResponses() => _dataSource.responses;
}
