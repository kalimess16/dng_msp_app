import 'dart:async';

class IotEmotionStream {
  int _countEmotions = 0;
  var _emotionController = StreamController<int>.broadcast();
  Stream<int> get emotionStream => _emotionController.stream;

  void dispose() => _emotionController.close();

  void setEmotion(int emotion) {
    _countEmotions = _countEmotions + emotion;
    _emotionController.sink.add(_countEmotions);
  }
}