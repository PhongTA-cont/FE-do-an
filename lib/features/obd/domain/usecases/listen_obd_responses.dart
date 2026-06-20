import '../repositories/obd_repository.dart';

class ListenObdResponses {
  const ListenObdResponses(this._repository);

  final ObdRepository _repository;

  Stream<String> call() {
    return _repository.listenRawResponses();
  }
}
