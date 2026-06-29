import '../../../../core/core.dart';
import '../../domain/obd_domain.dart';

class CanFrameParser {
  CanFrame? tryParse(String raw) {
    try {
      return parse(raw);
    } catch (_) {
      return null;
    }
  }

  CanFrame parse(String raw) {
    final text = HexUtils.normalizeCanText(raw);

    if (text.isEmpty) {
      throw const FormatException('Empty CAN frame');
    }

    if (text.contains('#')) {
      return _parseHashFormat(text);
    }

    return _parseSlcanLikeFormat(text);
  }

  CanFrame _parseHashFormat(String text) {
    final parts = text.split('#');
    if (parts.length != 2) {
      throw FormatException('Invalid CAN frame: $text');
    }
    return CanFrame(
      id: int.parse(parts[0], radix: 16),
      data: HexUtils.hexToBytes(parts[1]),
    );
  }

  CanFrame _parseSlcanLikeFormat(String text) {
    if (text.length < 4) {
      throw FormatException('Invalid SLCAN-like frame: $text');
    }

    final id = int.parse(text.substring(0, 3), radix: 16);
    final dlc = int.parse(text.substring(3, 4), radix: 16);
    final dataStart = 4;
    final dataEnd = dataStart + dlc * 2;

    if (text.length < dataEnd) {
      throw FormatException('Invalid data length: $text');
    }

    return CanFrame(
      id: id,
      data: HexUtils.hexToBytes(text.substring(dataStart, dataEnd)),
    );
  }
}
