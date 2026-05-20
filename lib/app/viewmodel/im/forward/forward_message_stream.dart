import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/service/im/forward/forward_message_service.dart';

class IotForwardMessageStream {
  Future<bool> uploadForwardMessage(int originalId, String originalCreator, int messageId,
      String messageCreator, String receivers, String forwardContent) async {
    String _wsToken = await IotSharedPreferences().get().then((prefs) => prefs[0]);
    return await IotForwardMessageService().uploadForwardMessage(_wsToken, originalId,
        originalCreator, messageId, messageCreator, receivers, forwardContent);
  }
}
