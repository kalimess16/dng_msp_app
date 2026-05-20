import 'dart:async';

import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/im/internal_message.dart';
import 'package:dngmsp/app/service/im/reply/list_internal_messages_service.dart';
import 'package:dngmsp/app/utility/utility.dart';
import 'package:flutter/material.dart';

class IotListInternalMessageStream extends ChangeNotifier {
  final List<IotInternalMessage> internalMessages = [];

  Future<List<IotInternalMessage>> initIotInternalMessages(
      BuildContext context, bool _hasInitiation) async {
    if (!_hasInitiation) {
      internalMessages.clear();
      await IotListInternalMessagesService()
          .fetchInternalMessages(DateTime.now().millisecondsSinceEpoch)
          .then((value) async {
        internalMessages.addAll(value);
      });
    }
    return internalMessages;
  }

  Future<int> loadMoreIotInternalMessages(
      BuildContext context, int startTime) async {
    if (!await IotUtility().checkInternetConnection(context)) return -1;

    return await IotListInternalMessagesService()
        .fetchInternalMessages(startTime)
        .then((value) async {
      internalMessages.addAll(value);
      notifyListeners();
      return (value.isEmpty ? 1 : 0);
    }).catchError((onError) {
      if (onError is IotException) if (onError.code == 101) return -2;
      return -9;
    });
  }

  void parseIotFirebaseMessage(Map<String, dynamic> message) async {
    final dynamic data = message['data'] ?? message;
      if (
      internalMessages.indexWhere((element) =>
      element.originalId == (int.tryParse(data['originalId']) ?? 0) &&
          element.originalCreator == data['originalCreator']) == -1 ||
      internalMessages.firstWhere((element) =>
      element.originalId == (int.tryParse(data['originalId']) ?? 0) &&
          element.originalCreator == data['originalCreator']).time < (int.tryParse(data['time']) ?? 0)) {
        internalMessages.removeWhere((element) =>
        element.originalId == (int.tryParse(data['originalId']) ?? 0) &&
            element.originalCreator == data['originalCreator']);

        internalMessages.add(IotInternalMessage(
            originalId: int.tryParse(data['originalId']) ?? 0,
            originalCreator: data['originalCreator'],
            id: int.tryParse(data['id']) ?? 0,
            creator: data['creator'],
            title: data['title'],
            time: int.tryParse(data['time']) ?? 0,
            status: int.tryParse(data['status']) ?? 0,
            creatorName: data['creatorName'],
            emotion: int.tryParse(data['emotion'] ?? '0') ?? 0,
            notificationId: int.tryParse(data['notificationId'] ?? '0') ?? 0,
            groupName: data['groupName'] ?? ' '));
        internalMessages.sort((a, b) => b.time.compareTo(a.time));
        notifyListeners();
      }
  }

  void updateIotFirebaseMessage(Map<String, dynamic> message) {
    final dynamic data = message['data'] ?? message;
    internalMessages
        .firstWhere((element) =>
            element.originalId == int.tryParse(data['originalId']) &&
            element.originalCreator == data['originalCreator'])
        .status = int.tryParse(data['status']) ?? 0;
    notifyListeners();
  }

  Future<bool> readInternalMessage(
      int originalId, String originalCreator) async {
    bool _isSuccess = await IotListInternalMessagesService()
        .readInternalMessage(originalId, originalCreator);
    if (_isSuccess) {
      internalMessages.forEach((element) {
        if (element.originalId == originalId &&
            element.originalCreator == originalCreator) element.status = 1;
      });
    }
    notifyListeners();
    return _isSuccess;
  }

  Future<int> countUnreadInternalMessage() async {
    return await IotListInternalMessagesService().countUnreadInternalMessage();
  }

  Future<void> updateListInternalMessage(IotInternalMessage im) async {
    internalMessages.removeWhere((element) =>
        element.originalCreator == im.originalCreator &&
        element.originalId == im.originalId);
    internalMessages.add(im);
    internalMessages.sort((a, b) => b.time.compareTo(a.time));
    notifyListeners();
  }
}
