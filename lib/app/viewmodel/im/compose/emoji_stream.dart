import 'dart:async';

class IotEmojiStream {
  bool offstage = false;
  var _emojiController = StreamController<bool>.broadcast();
  Stream<bool> get emojiStream => _emojiController.stream;

  void dispose() => _emojiController.close();

  Future<void> showEmojis() async {
    offstage = !offstage;
    _emojiController.sink.add(offstage);
  }

  void hideEmojis() {
    offstage = false;
    _emojiController.sink.add(offstage);
  }
}