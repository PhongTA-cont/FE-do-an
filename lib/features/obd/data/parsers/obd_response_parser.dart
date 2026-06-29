import '../../../../core/core.dart';
import '../../domain/obd_domain.dart';

class ObdParsedResult {
  const ObdParsedResult({required this.key, required this.value});

  final String key;
  final String value;
}

class ObdResponseParser {
  String _vinBuffer = '';

  List<ObdParsedResult> parseFrame(CanFrame frame) {
    final data = frame.data;
    if (data.length < 2) return const [];

    final results = <ObdParsedResult>[];

    if (data.length >= 3 && data[1] == 0x41) {
      final pid = data[2];
      switch (pid) {
        case 0x00:
          if (data.length >= 7) {
            final bitmap = data.sublist(3, 7);
            final supported = _decodeSupportedPids(bitmap)
                .map(_supportedPidName)
                .where((name) => name.isNotEmpty)
                .join('\n');
            results.add(
              ObdParsedResult(
                key: 'supportedPids',
                value: supported.isEmpty ? 'Chưa nhận diện được PID hỗ trợ' : supported,
              ),
            );
          }
          break;
        case 0x04:
          if (data.length >= 4) results.add(ObdParsedResult(key: 'engineLoad', value: (data[3] * 100 / 255).toStringAsFixed(1)));
          break;
        case 0x05:
          if (data.length >= 4) results.add(ObdParsedResult(key: 'coolantTemp', value: '${data[3] - 40}'));
          break;
        case 0x0B:
          if (data.length >= 4) results.add(ObdParsedResult(key: 'intakePressure', value: '${data[3]}'));
          break;
        case 0x0C:
          if (data.length >= 5) results.add(ObdParsedResult(key: 'rpm', value: (((data[3] * 256) + data[4]) / 4).toStringAsFixed(0)));
          break;
        case 0x0D:
          if (data.length >= 4) results.add(ObdParsedResult(key: 'speed', value: '${data[3]}'));
          break;
        case 0x0F:
          if (data.length >= 4) results.add(ObdParsedResult(key: 'intakeAirTemp', value: '${data[3] - 40}'));
          break;
        case 0x10:
          if (data.length >= 5) results.add(ObdParsedResult(key: 'maf', value: (((data[3] * 256) + data[4]) / 100).toStringAsFixed(2)));
          break;
        case 0x11:
          if (data.length >= 4) results.add(ObdParsedResult(key: 'throttle', value: (data[3] * 100 / 255).toStringAsFixed(1)));
          break;
        case 0x33:
          if (data.length >= 4) results.add(ObdParsedResult(key: 'barometricPressure', value: '${data[3]}'));
          break;
      }
      return results;
    }

    final vin = _parseVinMultiFrame(data);
    if (vin != null) results.add(ObdParsedResult(key: 'vin', value: vin));
    return results;
  }

  String? _parseVinMultiFrame(List<int> data) {
    if (data.isEmpty) return null;

    if (data.length >= 5 && data[0] == 0x10 && data[2] == 0x49 && data[3] == 0x02) {
      _vinBuffer = '';
      _vinBuffer += _ascii(data.sublist(5));
      return _vinBuffer.length >= 17 ? _consumeVin() : 'Đang nhận... $_vinBuffer';
    }

    if ((data[0] & 0xF0) == 0x20) {
      _vinBuffer += _ascii(data.sublist(1));
      return _vinBuffer.length >= 17 ? _consumeVin() : 'Đang nhận... $_vinBuffer';
    }

    return null;
  }

  String _consumeVin() {
    final vin = _vinBuffer.substring(0, 17);
    _vinBuffer = '';
    return vin;
  }

  List<int> _decodeSupportedPids(List<int> bitmap) {
    final result = <int>[];
    for (var byteIndex = 0; byteIndex < bitmap.length; byteIndex++) {
      final byte = bitmap[byteIndex];
      for (var bit = 0; bit < 8; bit++) {
        if ((byte & (1 << (7 - bit))) != 0) result.add(byteIndex * 8 + bit + 1);
      }
    }
    return result;
  }

  String _supportedPidName(int pid) {
    switch (pid) {
      case 0x01:
        return 'Trạng thái giám sát sau khi xóa DTC';
      case 0x02:
        return 'Mã lỗi đóng băng DTC';
      case 0x03:
        return 'Trạng thái hệ thống nhiên liệu';
      case 0x04:
        return 'Tải động cơ';
      case 0x05:
        return 'Nhiệt độ nước làm mát';
      case 0x06:
        return 'Hiệu chỉnh nhiên liệu ngắn hạn - dãy 1';
      case 0x07:
        return 'Hiệu chỉnh nhiên liệu dài hạn - dãy 1';
      case 0x08:
        return 'Hiệu chỉnh nhiên liệu ngắn hạn - dãy 2';
      case 0x09:
        return 'Hiệu chỉnh nhiên liệu dài hạn - dãy 2';
      case 0x0A:
        return 'Áp suất nhiên liệu';
      case 0x0B:
        return 'Áp suất đường nạp';
      case 0x0C:
        return 'Vòng tua động cơ';
      case 0x0D:
        return 'Tốc độ xe';
      case 0x0E:
        return 'Góc đánh lửa sớm';
      case 0x0F:
        return 'Nhiệt độ khí nạp';
      case 0x10:
        return 'Lưu lượng khí nạp MAF';
      case 0x11:
        return 'Độ mở bướm ga';
      case 0x1F:
        return 'Thời gian chạy từ khi khởi động';
      default:
        return 'PID 0x${HexUtils.byteToHex(pid)}';
    }
  }

  String _ascii(List<int> bytes) {
    return bytes.where((byte) => byte >= 0x20 && byte <= 0x7E).map(String.fromCharCode).join();
  }
}
