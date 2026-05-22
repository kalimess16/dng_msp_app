import 'dart:async';
import 'dart:io';

class IotException {
  final int? code;
  final String? error;
  IotException({this.code, this.error});

  factory IotException.fromError(Object error) {
    if (error is IotException) return error;
    final message = error.toString().toLowerCase();

    if (error is TimeoutException ||
        message.startsWith('timeoutexception') ||
        message.contains('timed out')) {
      return IotException(code: 408);
    }

    if (error is SocketException ||
        error is HandshakeException ||
        error is HttpException ||
        message.contains('socketexception') ||
        message.contains('clientexception') ||
        message.contains('connection refused') ||
        message.contains('connection reset') ||
        message.contains('connection closed') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable') ||
        message.contains('no route to host') ||
        message.contains('errno = 101') ||
        message.contains('errno = 110') ||
        message.contains('errno = 111') ||
        message.contains('errno = 113') ||
        message.contains('errno = 10060') ||
        message.contains('errno = 10061')) {
      return IotException(code: 101);
    }

    return IotException(code: 0);
  }
}
