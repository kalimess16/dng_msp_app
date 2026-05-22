import 'dart:async';
import 'dart:io';

import 'package:dngmsp/app/model/im/download_file.dart';
import 'package:dngmsp/app/model/im/emotion_user.dart';
import 'package:dngmsp/app/model/im/internal_message.dart';
import 'package:dngmsp/app/resource/font/app_fonts.dart';
import 'package:dngmsp/app/service/im/reply/reply_internal_message_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class IotReplyInternalMessageStream extends ChangeNotifier {
  final List<IotInternalMessage> internalMessages = [];
  final List<IotInternalMessage> incomingInternalMessages = [];

  Future<List<IotInternalMessage>> listReplyIotInternalMessages(
    int originalId,
    String originalCreator,
  ) async {
    internalMessages.clear();
    await IotReplyInternalMessagesService()
        .fetchInternalMessages(originalId, originalCreator)
        .then((value) {
          internalMessages.addAll(value);
        });
    return internalMessages;
  }

  Future<List<IotDownloadFile>> downloadFiles(
    int messageId,
    int originalId,
    String originalCreator,
  ) async {
    return await IotReplyInternalMessagesService().downloadFiles(
      messageId,
      originalId,
      originalCreator,
    );
  }

  Future<IotDownloadFile> downloadDataFiles(
    String creator,
    int messageId,
    String fileName,
    String fileType,
  ) async {
    return await IotReplyInternalMessagesService().downloadDataFiles(
      creator,
      messageId,
      fileName,
      fileType,
    );
  }

  Future<List<IotInternalMessage>> uploadReplyMessage(
    int originalId,
    String originalCreator,
    int messageId,
    String content,
    List<File> files,
  ) async {
    var _list = await IotReplyInternalMessagesService()
        .uploadReplyMessage(
          originalId,
          originalCreator,
          messageId,
          content,
          files,
        )
        .catchError((e, s) => <IotInternalMessage>[]);
    if (_list.isNotEmpty) {
      incomingInternalMessages.addAll(_list);
      incomingInternalMessages.sort((a, b) => b.time.compareTo(a.time));
      notifyListeners();
    }
    return _list;
  }

  Future<List<IotInternalMessage>> listIncomingReplyMessages(
    bool hasInitiation,
  ) async {
    if (!hasInitiation) incomingInternalMessages.clear();
    incomingInternalMessages.sort((a, b) => b.time.compareTo(a.time));
    return incomingInternalMessages;
  }

  Future<List<dynamic>> parseIotReplyFirebaseMessage(
    Map<String, dynamic> message,
  ) async {
    if (internalMessages.isEmpty) return [];
    final dynamic data = message['data'] ?? message;
    int originalId = int.tryParse(data['originalId']) ?? 0;
    String originalCreator = data['originalCreator'];
    int messageId = int.tryParse(data['id']) ?? 0;

    if (internalMessages.first.originalId != originalId ||
        internalMessages.first.originalCreator != originalCreator) {
      return [];
    }

    /* e
    incomingInternalMessages.add(IotInternalMessage(
        originalId: int.tryParse(data['originalId']) ?? 0,
        originalCreator: data['originalCreator'],
        id: int.tryParse(data['id']) ?? 0,
        creator: data['creator'],
        title: data['title'],
        time: int.tryParse(data['time']) ?? 0,
        status: int.tryParse(data['status']) ?? 0,
        creatorName: data['creatorName'],
        emotion: int.tryParse(data['emotion'] ?? '0') ?? 0,
        hasFile: data['hasFile'])); */
    incomingInternalMessages.addAll(
      await IotReplyInternalMessagesService().fetchIncomingReplyInternalMessage(
        originalId,
        originalCreator,
        messageId,
      ),
    );

    notifyListeners();
    return [originalId, originalCreator];
  }

  Future<int> updateEmotionNumInternalMessage(
    int originalId,
    String originalCreator,
    int messageId,
  ) async {
    if (await IotReplyInternalMessagesService().updateEmotionNumInternalMessage(
      originalId,
      originalCreator,
      messageId,
    )) {
      int _emotion = 0;
      internalMessages.forEach((element) {
        if (element.id == messageId) {
          element.emotion = 1;
          _emotion = 1;
          return;
        }
      });
      if (_emotion == 0) {
        incomingInternalMessages
                .firstWhere((element) => element.id == messageId)
                .emotion =
            1;
        _emotion = 1;
      }
      notifyListeners();
      return _emotion;
    }
    return 0;
  }

  Future<List<IotEmotionUser>> listEmotionUser(
    int originalId,
    String originalCreator,
    int messageId,
  ) async {
    return await IotReplyInternalMessagesService().fetchEmotionUsers(
      originalId,
      originalCreator,
      messageId,
    );
  }

  List<TextSpan> extractIotMessageTitle(
    BuildContext context,
    String title,
    String searchWords, {
    void Function(int)? onEofficeTitleTap,
  }) {
    List<TextSpan> textSpan = [];
    final fontSize = MediaQuery.of(context).orientation == Orientation.landscape
        ? 16.0
        : SP_COMMON_FONT_SIZE.sp;
    final urlRegExp = RegExp(
      r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?",
    );
    final eofficeTitleRegExp = RegExp(
      r'^\s*-?\s*VB[\s:]+',
      caseSensitive: false,
    );

    getLink(String linkString) {
      textSpan.add(
        TextSpan(
          text: linkString,
          style: TextStyle(color: Colors.blue, fontSize: fontSize),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final url = Uri.parse(
                linkString.startsWith(RegExp(r'https?://'))
                    ? linkString
                    : 'https://$linkString',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Không kết nối được với đường dẫn này'),
                  ),
                );
            },
        ),
      );
      return linkString;
    }

    getNormalText(String normalText) {
      textSpan.add(
        (searchWords.isEmpty
            ? TextSpan(
                text: normalText,
                style: TextStyle(color: Colors.black, fontSize: fontSize),
              )
            : TextSpan(
                children: highlightOccurrences(
                  normalText,
                  searchWords,
                  fontSize: fontSize,
                ),
                style: TextStyle(color: Colors.black, fontSize: fontSize),
              )),
      );
      return normalText;
    }

    int eofficeTitleIndex = 0;
    final lines = title.split(RegExp(r'\r\n|\n|\r'));
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (onEofficeTitleTap != null && eofficeTitleRegExp.hasMatch(line)) {
        final fileIndex = eofficeTitleIndex;
        eofficeTitleIndex++;
        textSpan.add(
          TextSpan(
            text: line,
            style: TextStyle(
              color: const Color.fromARGB(248, 0, 0, 0),
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              // decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => onEofficeTitleTap(fileIndex),
          ),
        );
      } else {
        line.splitMapJoin(
          urlRegExp,
          onMatch: (m) => getLink("${m.group(0)}"),
          onNonMatch: (n) => getNormalText("${n.substring(0)}"),
        );
      }
      if (i < lines.length - 1)
        textSpan.add(
          TextSpan(
            text: '\n',
            style: TextStyle(color: Colors.black, fontSize: fontSize),
          ),
        );
    }
    return textSpan;
  }

  List<TextSpan> highlightOccurrences(
    String source,
    String query, {
    double? fontSize,
  }) {
    final matches = query
        .toLowerCase()
        .allMatches(source.toLowerCase())
        .toList();
    if (matches.isEmpty) return [TextSpan(text: source)];
    int lastMatchEnd = 0;
    final List<TextSpan> children = [];
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];

      if (match.start != lastMatchEnd) {
        children.add(
          TextSpan(text: source.substring(lastMatchEnd, match.start)),
        );
      }

      children.add(
        TextSpan(
          text: source.substring(match.start, match.end),
          style: TextStyle(
            fontSize: fontSize ?? SP_COMMON_FONT_SIZE.sp,
            backgroundColor: Colors.yellowAccent,
          ),
        ),
      );

      if (i == matches.length - 1 && match.end != source.length) {
        children.add(
          TextSpan(text: source.substring(match.end, source.length)),
        );
      }

      lastMatchEnd = match.end;
    }
    return children;
  }
}
