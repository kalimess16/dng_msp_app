import 'package:dngmsp/app/view/im/reply/reply_internal_message_page.dart';

import 'list_internal_message_stream.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class IotNavigatorInternalMessage {
  Future<void> onTap(
      BuildContext context,
      int originalId,
      String originalCreator,
      String groupName,
      bool onBackground,
      String searchWords) async {
    context
        .read<IotListInternalMessageStream>()
        .readInternalMessage(originalId, originalCreator);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => IotReplyInternalMessagePage(
                originalId, originalCreator, groupName, onBackground, searchWords)));
  }
}
