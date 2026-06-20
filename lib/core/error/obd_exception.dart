class ObdException implements Exception {
  const ObdException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'ObdException: $message';
    }
    return 'ObdException: $message, cause: $cause';
  }
}

class ObdConnectionException extends ObdException {
  const ObdConnectionException(super.message, {super.cause});
}

class ObdParseException extends ObdException {
  const ObdParseException(super.message, {super.cause, this.rawData});

  final String? rawData;

  @override
  String toString() {
    final raw = rawData == null ? '' : ', rawData: $rawData';
    if (cause == null) {
      return 'ObdParseException: $message$raw';
    }
    return 'ObdParseException: $message$raw, cause: $cause';
  }
}

class ObdUnsupportedPidException extends ObdException {
  const ObdUnsupportedPidException(super.message, {super.cause, this.service, this.pid});

  final int? service;
  final int? pid;
}

class ObdTimeoutException extends ObdException {
  const ObdTimeoutException(super.message, {super.cause, this.timeout});

  final Duration? timeout;
}
