abstract class ObdRepository {
  Future<void> sendRequest(String command);

  Stream<String> listenRawResponses();
}
