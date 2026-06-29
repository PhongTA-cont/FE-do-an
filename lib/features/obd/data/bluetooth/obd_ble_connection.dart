import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ObdBleConnection {
  ObdBleConnection({required this.writeChar, required this.notifyChar}) {
    _initNotify();
  }

  final BluetoothCharacteristic? writeChar;
  final BluetoothCharacteristic? notifyChar;

  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  StreamSubscription<List<int>>? _notifySub;

  Stream<String> get responseStream => _controller.stream;

  Future<void> _initNotify() async {
    if (notifyChar == null) return;

    try {
      await notifyChar!.setNotifyValue(true);
      _notifySub = notifyChar!.onValueReceived.listen((value) {
        if (value.isEmpty) return;
        _controller.add(utf8.decode(value, allowMalformed: true));
      });
    } catch (e) {
      debugPrint('Lỗi nhận thông báo BLE: $e');
    }
  }

  Future<void> sendCommand(String command) async {
    if (writeChar == null) return;

    try {
      final bytes = utf8.encode('${command.trim()}\r');
      await writeChar!.write(
        bytes,
        withoutResponse: writeChar!.properties.writeWithoutResponse,
      );
    } catch (e) {
      debugPrint('Lỗi ghi dữ liệu BLE: $e');
    }
  }

  Future<void> dispose() async {
    await _notifySub?.cancel();
    await _controller.close();
  }
}
