
import 'dart:async';

class IotTappedReplyDownloadFileStream {
  var _downloadFileController = StreamController<String>.broadcast();

  Stream<String> get downloadFileStream => _downloadFileController.stream;

  void dispose() => _downloadFileController.close();

  void tappedChild() {
    _downloadFileController.sink.add('TAPPED');
  }
}