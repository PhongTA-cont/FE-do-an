import '../repositories/obd_repository.dart';

class SendObdRequest {
  const SendObdRequest(this._repository);

  final ObdRepository _repository;

  Future<void> call(String command) {
    return _repository.sendRequest(command);
  }
}
