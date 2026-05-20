import 'dart:async';

import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/im/internal_message.dart';
import 'package:dngmsp/app/service/im/search/search_internal_message_service.dart';
import 'package:dngmsp/app/utility/utility.dart';
import 'package:flutter/material.dart';

class IotSearchInternalMessageStream extends ChangeNotifier {
  final List<IotInternalMessage> internalMessages = [];

  Future<List<IotInternalMessage>> initIotInternalMessages(BuildContext context, String fromDate,
      String toDate, String senders, String messageContent, bool _hasInitiation) async {
    if (!_hasInitiation) {
      internalMessages.clear();
      await IotSearchInternalMessagesService()
          .fetchInternalMessages(
              fromDate, toDate, senders, messageContent, DateTime.now().millisecondsSinceEpoch)
          .then((value) async {
        internalMessages.addAll(value);
      });
    }
    return internalMessages;
  }

  Future<int> loadMoreIotInternalMessages(BuildContext context, String fromDate, String toDate,
      String senders, String messageContent, int startTime) async {
    if (!await IotUtility().checkInternetConnection(context)) return -1;

    return await IotSearchInternalMessagesService()
        .fetchInternalMessages(fromDate, toDate, senders, messageContent, startTime)
        .then((value) {
      internalMessages.addAll(value);
      notifyListeners();
      return (value.isEmpty ? 1 : 0);
    }).catchError((onError) {
      if (onError is IotException) if (onError.code == 101) return -2;
      return -9;
    });
  }
}
