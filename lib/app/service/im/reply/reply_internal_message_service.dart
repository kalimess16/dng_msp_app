import 'dart:convert';
import 'dart:io';

import 'package:dngmsp/app/model/exception.dart';
import 'package:dngmsp/app/model/im/download_file.dart';
import 'package:dngmsp/app/model/im/emotion_user.dart';
import 'package:dngmsp/app/model/im/internal_message.dart';
import 'package:dngmsp/app/model/shared_preferences.dart';
import 'package:dngmsp/app/resource/string/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

List<IotInternalMessage> parseIotReplyInternalMessage(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed
      .whereType<Map>()
      .map(
        (json) => IotInternalMessage.fromJson(Map<String, dynamic>.from(json)),
      )
      .toList();
}

List<IotDownloadFile> parseIotDownloadFiles(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => IotDownloadFile.fromJson(json)).toList();
}

IotDownloadFile parseIotDownloadDataFile(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => IotDownloadFile.fromJson(json)).first;
}

List<IotInternalMessage> parseIncomingReplyInternalMessage(
  String responseBody,
) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed
      .whereType<Map>()
      .map(
        (json) => IotInternalMessage.fromJson(Map<String, dynamic>.from(json)),
      )
      .toList();
}

List<IotEmotionUser> parseEmotionUser(String responseBody) {
  final parsed = jsonDecode(responseBody) as List;
  return parsed.map((json) => IotEmotionUser.fromJson(json)).toList();
}

class IotReplyInternalMessagesService {
  Future<List<IotInternalMessage>> fetchInternalMessages(
    int originalId,
    String originalCreator,
  ) async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(
            Uri.parse(IOT_REQUEST_URL + 'listReplyInternalMessages'),
            headers: {
              "Authorization": "Bearer " + wsToken,
              "Vendor": codec.encode(IOT_APP_VERSION),
            },
            body: jsonEncode({
              'originalId': '$originalId',
              'originalCreator': originalCreator,
            }),
          )
          .timeout(Duration(seconds: 45));
      if (response.statusCode != 200)
        throw IotException(
          code: response.statusCode,
          error: response.headers['iot-upgrade'] ?? 'N',
        );
      if (response.body == 'null') return [];
      return compute(parseIotReplyInternalMessage, response.body);
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }

  Future<List<IotDownloadFile>> downloadFiles(
    int messageId,
    int originalId,
    String originalCreator,
  ) async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client().post(
        Uri.parse(IOT_REQUEST_URL + 'listReplyDownloadFiles'),
        headers: {
          "Authorization": "Bearer " + wsToken,
          "Vendor": codec.encode(IOT_APP_VERSION),
        },
        body: jsonEncode({
          'messageId': '$messageId',
          'originalId': '$originalId',
          'originalCreator': originalCreator,
        }),
      );
      if (response.statusCode != 200)
        throw IotException(
          code: response.statusCode,
          error: response.headers['iot-upgrade'] ?? 'N',
        );
      if (response.body == 'null') return [];
      return compute(parseIotDownloadFiles, response.body);
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }

  Future<IotDownloadFile> downloadDataFiles(
    String creator,
    int messageId,
    String fileName,
    String fileType,
  ) async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client().post(
        Uri.parse(IOT_REQUEST_URL + 'listReplyDownloadDataFile'),
        headers: {
          "Authorization": "Bearer " + wsToken,
          "Vendor": codec.encode(IOT_APP_VERSION),
        },
        body: jsonEncode({
          'creator': creator,
          'messageId': '$messageId',
          'fileName': fileName,
          'fileType': fileType,
        }),
      );
      if (response.statusCode != 200)
        throw IotException(
          code: response.statusCode,
          error: response.headers['iot-upgrade'] ?? 'N',
        );
      return compute(parseIotDownloadDataFile, response.body);
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }

  Future<List<IotInternalMessage>> uploadReplyMessage(
    int originalId,
    String originalCreator,
    int messageId,
    String content,
    List<File> files,
  ) async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(IOT_REQUEST_URL + 'uploadReplyDocumentFiles'),
      );
      request.headers.addAll({
        "Authorization": "Bearer " + wsToken,
        "Vendor": codec.encode(IOT_APP_VERSION),
      });
      request.fields.addAll({
        'originalId': '$originalId',
        'originalCreator': originalCreator,
        'messageId': '$messageId',
        'content': content,
      });
      files.forEach((element) async {
        String _mimeType = lookupMimeType(element.path) ?? '';
        if (_mimeType.isNotEmpty) {
          var _types = _mimeType.split('/');
          request.files.add(
            await http.MultipartFile.fromPath(
              'files',
              element.path,
              contentType: MediaType(_types[0], _types[1]),
            ),
          );
        } else
          request.files.add(
            await http.MultipartFile.fromPath('files', element.path),
          );
      });
      var response = await http.Response.fromStream(await request.send());
      if (response.statusCode != 200)
        throw IotException(
          error: response.headers['iot-upgrade'] ?? 'N',
          code: response.statusCode,
        );
      return compute(parseIncomingReplyInternalMessage, response.body);
    } on IotException catch (e, s) {
      print(s);
      throw e;
    } catch (e, s) {
      print(s);
      throw IotException.fromError(e);
    }
  }

  Future<List<IotInternalMessage>> fetchIncomingReplyInternalMessage(
    int originalId,
    String originalCreator,
    int messageId,
  ) async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(
            Uri.parse(IOT_REQUEST_URL + 'incomingReplyInternalMessages'),
            headers: {
              "Authorization": "Bearer " + wsToken,
              "Vendor": codec.encode(IOT_APP_VERSION),
            },
            body: jsonEncode({
              'originalId': '$originalId',
              'originalCreator': originalCreator,
              'messageId': '$messageId',
            }),
          )
          .timeout(Duration(seconds: 35));
      if (response.statusCode != 200)
        throw IotException(
          code: response.statusCode,
          error: response.headers['iot-upgrade'] ?? 'N',
        );
      if (response.body == 'null') return [];
      return compute(parseIncomingReplyInternalMessage, response.body);
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }

  Future<bool> updateEmotionNumInternalMessage(
    int originalId,
    String originalCreator,
    int messageId,
  ) async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(
            Uri.parse(IOT_REQUEST_URL + 'emotionInternalMessage'),
            headers: {
              "Authorization": "Bearer " + wsToken,
              "Vendor": codec.encode(IOT_APP_VERSION),
            },
            body: jsonEncode({
              'originalId': '$originalId',
              'originalCreator': originalCreator,
              'messageId': '$messageId',
            }),
          )
          .timeout(Duration(seconds: 25));
      if (response.statusCode != 200)
        throw IotException(
          code: response.statusCode,
          error: response.headers['iot-upgrade'] ?? 'N',
        );
      return (response.body == 'SUCCESS');
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }

  Future<List<IotEmotionUser>> fetchEmotionUsers(
    int originalId,
    String originalCreator,
    int messageId,
  ) async {
    try {
      late String wsToken;
      Codec<String, String> codec = utf8.fuse(base64);
      await IotSharedPreferences().get().then((prefs) => wsToken = prefs[0]);
      final response = await http.Client()
          .post(
            Uri.parse(IOT_REQUEST_URL + 'listEmotionUsers'),
            headers: {
              "Authorization": "Bearer " + wsToken,
              "Vendor": codec.encode(IOT_APP_VERSION),
            },
            body: jsonEncode({
              'originalId': '$originalId',
              'originalCreator': originalCreator,
              'messageId': '$messageId',
            }),
          )
          .timeout(Duration(seconds: 35));
      if (response.statusCode != 200)
        throw IotException(
          code: response.statusCode,
          error: response.headers['iot-upgrade'] ?? 'N',
        );
      if (response.body == 'null') return [];
      return compute(parseEmotionUser, response.body);
    } on IotException catch (e) {
      throw e;
    } catch (e) {
      throw IotException.fromError(e);
    }
  }
}
