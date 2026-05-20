import 'dart:async';

import 'dart:io';
import 'package:dngmsp/app/model/im/internal_message.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/service/im/compose/compose_message_service.dart';

class IotComposeMessageStream {
  Future<bool> uploadMessage(
      int originalId, String receivers, String content, List<File> files) async {
    String _wsToken = await IotSharedPreferences().get().then((prefs) => prefs[0]);
    return await IotComposeMessageService()
        .uploadMessage(_wsToken, originalId, receivers, content, files);
  }

  Future<List<IotInternalMessage>> uploadMessageInList(
      int originalId, String receivers, String content, List<File> files) async {
    String _wsToken = await IotSharedPreferences().get().then((prefs) => prefs[0]);
    return await IotComposeMessageService()
        .uploadMessageInList(_wsToken, originalId, receivers, content, files);
  }
}
