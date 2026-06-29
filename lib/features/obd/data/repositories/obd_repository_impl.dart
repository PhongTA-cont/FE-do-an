import '../../domain/obd_domain.dart';
import '../data_sources/obd_ble_datasource.dart';

class ObdRepositoryImpl implements ObdRepository {
  ObdRepositoryImpl(this._dataSource);

  final ObdBleDataSource _dataSource;

  @override
  Future<void> sendRequest(String command) => _dataSource.send(command);

  @override
  Stream<String> listenRawResponses() => _dataSource.responses;
}
