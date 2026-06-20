abstract class ObdBleDataSource {
  Future<void> send(String command);

  Stream<String> get responses;
}

class ObdBleDataSourceImpl implements ObdBleDataSource {
  ObdBleDataSourceImpl({
    required Future<void> Function(String command) sendCommand,
    required Stream<String> responseStream,
  })  : _sendCommand = sendCommand,
        _responseStream = responseStream;

  final Future<void> Function(String command) _sendCommand;
  final Stream<String> _responseStream;

  @override
  Future<void> send(String command) async {
    await _sendCommand('$command\r\n');
  }

  @override
  Stream<String> get responses => _responseStream;
}
