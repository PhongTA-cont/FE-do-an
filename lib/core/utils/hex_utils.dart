class HexUtils {
  const HexUtils._();

  static String toHex(
    int value, {
    int width = 2,
    bool upperCase = true,
    bool withPrefix = false,
  }) {
    final hex = value.toRadixString(16).padLeft(width, '0');
    final result = upperCase ? hex.toUpperCase() : hex.toLowerCase();
    return withPrefix ? '0x$result' : result;
  }

  static String byteToHex(int value) => toHex(value & 0xFF, width: 2);

  static String canIdToHex(int id) => toHex(id, width: 3);

  static String bytesToHex(List<int> bytes, {String separator = ''}) {
    return bytes.map(byteToHex).join(separator);
  }

  static List<int> hexToBytes(String hex) {
    final clean = hex
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('0x', '')
        .replaceAll('0X', '');

    if (clean.isEmpty) return const [];
    if (clean.length.isOdd) {
      throw FormatException('Hex string length must be even: $hex');
    }

    final bytes = <int>[];
    for (var i = 0; i < clean.length; i += 2) {
      bytes.add(int.parse(clean.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }

  static bool isValidHex(String text) {
    final clean = text
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('0x', '')
        .replaceAll('0X', '');
    if (clean.isEmpty || clean.length.isOdd) return false;
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(clean);
  }

  static String normalizeCanText(String raw) {
    var text = raw.trim();
    if (text.startsWith('t') || text.startsWith('T')) {
      text = text.substring(1);
    }
    return text;
  }

  static String buildCanHashFrame({required int id, required List<int> data}) {
    return '${canIdToHex(id)}#${bytesToHex(data)}';
  }

  static String buildObdRequest({required int service, required int pid, int canId = 0x7DF}) {
    return buildCanHashFrame(
      id: canId,
      data: [0x02, service, pid, 0x00, 0x00, 0x00, 0x00, 0x00],
    );
  }

  static String buildService01Request(int pid) => buildObdRequest(service: 0x01, pid: pid);

  static String buildService09Request(int pid) => buildObdRequest(service: 0x09, pid: pid);
}
